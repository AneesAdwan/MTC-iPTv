// المُجدوِل (ADM-H2، §17، D-13): كل المهام الدورية تعمل من برنامج المدير.
//  • كل دقيقة: المهام المفعّلة المستحقة ضمن ساعات العمل المسموحة ← قفل على الخادم (admin_task_acquire)
//    فلا تعمل مهمة على جهازين ← التشغيل ← admin_task_finish (يضبط التشغيل التالي).
//  • التعويض: ما فات (الجهاز مطفأ) يُشغَّل عند أول فتح، مع إظهار ما فات للمدير.
//  • حدود الموارد: الفحص الثقيل ينتظر إن كان المدير يشاهد قناة.
//  • يعمل فقط: سطح المكتب + مدير بجلسة تحقق بخطوتين + المُجدوِل مفعّل على هذا الجهاز.
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/shell/sidebar.dart' show isAdminProvider;
import '../../core/logging/log.dart';
import '../../player/playback_controller.dart';
import 'admin_device.dart';
import 'admin_repository.dart';
import 'backup_service.dart';
import 'epg_admin_service.dart';
import 'health_service.dart';
import 'import_service.dart';

class SchedulerState {
  final String? running; // مفتاح المهمة الجارية
  final List<String> missedOnStart; // مهام فاتت أثناء إطفاء الجهاز
  final DateTime? lastTick;
  final String? lastError;
  const SchedulerState({this.running, this.missedOnStart = const [], this.lastTick, this.lastError});
  SchedulerState copyWith({String? running, bool clearRunning = false, List<String>? missedOnStart, DateTime? lastTick, String? lastError}) => SchedulerState(
        running: clearRunning ? null : (running ?? this.running),
        missedOnStart: missedOnStart ?? this.missedOnStart,
        lastTick: lastTick ?? this.lastTick,
        lastError: lastError ?? this.lastError,
      );
}

/// ساعات العمل المسموحة: int4range مثل "[1,6)" (null = أي وقت).
bool hourAllowed(String? range, int hour) {
  if (range == null || range.isEmpty || range == 'empty') return range != 'empty';
  final m = RegExp(r'^([\[(])(\d*),(\d*)([\])])$').firstMatch(range.trim());
  if (m == null) return true;
  final lo = m[2]!.isEmpty ? 0 : int.parse(m[2]!) + (m[1] == '(' ? 1 : 0);
  final hi = m[3]!.isEmpty ? 24 : int.parse(m[3]!) - (m[4] == ')' ? 1 : 0);
  return lo <= hi ? (hour >= lo && hour <= hi) : (hour >= lo || hour <= hi); // نطاق يعبر منتصف الليل
}

const heavyTasks = {'health_published', 'health_all', 'playback_sample'};

class SchedulerService extends Notifier<SchedulerState> {
  Timer? _timer;
  bool _busy = false, _first = true;
  String get _device => Platform.localHostname;

  @override
  SchedulerState build() {
    ref.onDispose(() => _timer?.cancel());
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // أول فحص بعد استقرار البرنامج، ثم كل دقيقة
      _timer = Timer(const Duration(seconds: 20), () {
        tick();
        _timer = Timer.periodic(const Duration(minutes: 1), (_) => tick());
      });
    }
    return const SchedulerState();
  }

  Future<bool> _active() async {
    if (!ref.read(isAdminProvider) || ref.read(adminRepoProvider) == null) return false;
    try {
      return (await ref.read(adminDeviceProvider.future)).schedulerEnabled;
    } catch (_) {
      return false;
    }
  }

  /// فحص المهام المستحقة وتشغيلها واحدة تلو الأخرى. [force]: «شغّل الآن» لمهمة محددة.
  Future<void> tick({String? force}) async {
    if (_busy || !await _active()) return;
    final repo = ref.read(adminRepoProvider)!;
    _busy = true;
    try {
      final now = DateTime.now();
      final tasks = await repo.scheduledTasks();
      if (_first) {
        _first = false;
        // ما فات أكثر من دورة كاملة (الجهاز كان مطفأ)
        final missed = [
          for (final t in tasks)
            if (t['enabled'] == true && t['next_run_at'] != null && now.difference(DateTime.parse('${t['next_run_at']}').toLocal()).inMinutes > ((t['interval_min'] as num?) ?? 0)) '${t['key']}',
        ];
        state = state.copyWith(missedOnStart: missed);
        if (missed.isNotEmpty) log.info('scheduler catch-up: $missed');
      }
      for (final t in tasks) {
        final key = '${t['key']}';
        if (force != null && key != force) continue;
        if (t['enabled'] != true && force == null) continue;
        final due = t['next_run_at'] == null || !DateTime.parse('${t['next_run_at']}').isAfter(DateTime.now().toUtc());
        if (force == null && (!due || !hourAllowed(t['allowed_hours'] as String?, now.hour))) continue;
        // المدير يشاهد قناة: الفحص الثقيل ينتظر (§9.10)
        if (heavyTasks.contains(key) && ref.read(playbackProvider).phase == PlayPhase.playing && force == null) continue;
        if (force != null) await repo.updateTask(key, {'next_run_at': null}); // «شغّل الآن»
        if (!await repo.acquireTask(key, _device)) continue;
        state = state.copyWith(running: key, lastTick: DateTime.now());
        var status = 'ok';
        try {
          status = await _run(key, repo);
        } catch (e, s) {
          status = 'failed';
          log.warning('scheduled task $key failed', e, s);
          state = state.copyWith(lastError: '$key: $e');
        }
        await repo.finishTask(key, _device, status);
        state = state.copyWith(clearRunning: true);
      }
      state = state.copyWith(lastTick: DateTime.now());
    } catch (e) {
      log.warning('scheduler tick failed', e);
      state = state.copyWith(lastError: '$e', clearRunning: true);
    } finally {
      _busy = false;
    }
  }

  Future<String> _run(String key, AdminRepository repo) async {
    final health = ref.read(healthJobProvider.notifier);
    switch (key) {
      case 'health_published':
        if (ref.read(healthJobProvider).running) return 'skipped';
        await health.run(await repo.publishedStreams(), playCheck: false, taskKey: key);
      case 'health_all':
        if (ref.read(healthJobProvider).running) return 'skipped';
        await health.run(await repo.allStreams(), playCheck: false, taskKey: key);
      case 'playback_sample':
        if (ref.read(healthJobProvider).running) return 'skipped';
        await health.run(await repo.playbackSample(), playCheck: true, taskKey: key);
      case 'logos':
        await _logos(repo);
      case 'epg':
        await ref.read(epgAdminProvider.notifier).run();
      case 'sources':
        for (final s in await repo.sources()) {
          if (s['is_active'] != true) continue;
          try {
            await syncSourceHeadless(repo, s);
          } catch (e) {
            await repo.updateSource('${s['id']}', {'status': 'failed', 'last_error': '$e'.substring(0, '$e'.length.clamp(0, 300))});
          }
        }
      case 'backup':
        final dev = await ref.read(adminDeviceProvider.future);
        if (dev.backupDir == null || await readBackupPassphrase() == null) return 'skipped';
        final runId = await repo.startRun('backup', _device);
        try {
          final r = await backupNow(ref, kind: 'daily');
          await repo.finishRun(runId!, status: 'ok', summary: {'file': r.path.split(Platform.pathSeparator).last, 'bytes': r.bytes, 'counts': r.counts, 'pruned': r.pruned.length});
        } catch (e) {
          await repo.finishRun(runId!, status: 'failed', error: '$e');
          rethrow;
        }
    }
    return 'ok';
  }

  Future<void> _logos(AdminRepository repo) async {
    final runId = await repo.startRun('logos', _device);
    final probe = LogoProbe();
    final queue = [...await repo.channelsWithLogos()];
    final results = <(String, bool)>[];
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final c = queue.removeAt(0);
        final (ok, _) = await probe.check('${c['logo_url']}');
        if (ok != null) results.add(('${c['id']}', ok));
      }
    }

    await Future.wait([for (var i = 0; i < 8; i++) worker()]);
    for (var i = 0; i < results.length; i += 200) {
      await repo.recordLogos(results.sublist(i, (i + 200).clamp(0, results.length)));
    }
    await repo.finishRun(runId!, status: 'ok', summary: {'checked': results.length, 'broken': results.where((r) => !r.$2).length});
  }
}

final schedulerProvider = NotifierProvider<SchedulerService, SchedulerState>(SchedulerService.new);
