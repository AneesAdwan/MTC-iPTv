// مهمة فحص الروابط (ADM-D4، §12): الطبقة 1 (الوصول) لكل رابط، ثم الطبقة 2 (التشغيل في mpv) لما وصل.
//  • يُفحص رابط مرجعي أولًا: إن كان الإنترنت عند المدير مقطوعًا يتوقف الفحص ولا يُسجَّل شيء على الروابط (§12.2).
//  • التزامن: 8 للطبقة 1 (و4 لكل نطاق)، 2 للطبقة 2 (§12.3).
//  • الروابط المعطّلة يدويًا لا تُفحص ولا تتغير (D-14).
//  • النتيجة تُكتب على الرابط فقط؛ لا إخفاء ولا حذف تلقائي — القرار للمدير.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/logging/log.dart';
import '../../player/play_probe.dart';
import 'admin_repository.dart';

class HealthJob {
  final int total, done;
  final Map<String, int> results;
  final bool running;
  final String? error;
  const HealthJob({this.total = 0, this.done = 0, this.results = const {}, this.running = false, this.error});
  double get progress => total == 0 ? 0 : done / total;
}

/// نتيجة موحّدة للطبقتين مع درجة الصحة (§12.5، تقديرية حتى يتوفر قياس المشاهدين).
(String, String, int?) combine(ProbeResult l1, PlayResult? l2) {
  if (!l1.ok) return (l1.state, 'L1: ${l1.reason}', 0);
  if (l2 == null) return ('reachable', 'L1: ${l1.reason}', 60);
  return switch (l2.state) {
    'playable' => ('playable', 'L2: ${l2.reason}', (100 - (((l2.firstFrameMs ?? 0) - 1000) ~/ 200)).clamp(70, 100)),
    'degraded' => ('degraded', 'L2: ${l2.reason}', 50),
    // وصل لكن لم يُثبت التشغيل: يبقى reachable مع السبب (عند الشك لا نحكم بالفشل)
    'inconclusive' => ('reachable', 'L1 ok · L2: ${l2.reason}', 40),
    _ => (l2.state, 'L2: ${l2.reason}', 10),
  };
}

class HealthService extends Notifier<HealthJob> {
  bool _cancel = false;

  @override
  HealthJob build() => const HealthJob();

  void cancel() => _cancel = true;

  Future<void> run(List<AdminStream> streams, {bool playCheck = true}) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null || state.running) return;
    final todo = streams.where((s) => s.healthState != 'disabled').toList();
    _cancel = false;
    state = HealthJob(total: todo.length, running: true);

    // رابط مرجعي: انقطاع الإنترنت عند المدير لا يُسجَّل على الروابط
    try {
      final ref0 = await SafeFetcher(policy: const SafeFetchPolicy(timeout: Duration(seconds: 8))).get(Uri.parse('https://www.gstatic.com/generate_204'));
      if (ref0.statusCode >= 400) throw StateError('HTTP ${ref0.statusCode}');
    } catch (e) {
      state = HealthJob(total: todo.length, error: 'offline: $e');
      return;
    }

    final probe = StreamProbe();
    final play = PlayProbe();
    final results = <String, int>{};
    var done = 0;
    final perHost = <String, int>{};
    var l2Running = 0;

    Future<void> one(AdminStream s) async {
      final host = Uri.tryParse(s.url)?.host ?? '';
      while ((perHost[host] ?? 0) >= 4) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      perHost[host] = (perHost[host] ?? 0) + 1;
      ProbeResult l1;
      try {
        l1 = await probe.check(s.url, headers: s.requestHeaders, hasCredentials: s.hasCredentials);
      } finally {
        perHost[host] = perHost[host]! - 1;
      }
      PlayResult? l2;
      if (l1.ok && playCheck && !_cancel) {
        while (l2Running >= 2) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        l2Running++;
        try {
          l2 = await play.check(s.url, headers: s.requestHeaders);
        } catch (e) {
          l2 = PlayResult('inconclusive', '$e');
        } finally {
          l2Running--;
        }
      }
      final (st, reason, score) = combine(l1, l2);
      try {
        await repo.recordHealth(s.id, state: st, reason: reason, http: l1.httpStatus, ms: l2?.firstFrameMs ?? l1.ms, score: score);
      } catch (e) {
        log.warning('health write failed ${s.id}', e);
      }
      results[st] = (results[st] ?? 0) + 1;
      done++;
      state = HealthJob(total: todo.length, done: done, results: Map.of(results), running: true);
    }

    // تجمّع بسيط: 8 فحوص متزامنة
    final queue = [...todo];
    Future<void> worker() async {
      while (queue.isNotEmpty && !_cancel) {
        await one(queue.removeAt(0));
      }
    }

    await Future.wait([for (var i = 0; i < 8; i++) worker()]);
    log.info('health check done $done/${todo.length} $results${_cancel ? ' (cancelled)' : ''}');
    state = HealthJob(total: todo.length, done: done, results: results);
  }
}

final healthJobProvider = NotifierProvider<HealthService, HealthJob>(HealthService.new);
