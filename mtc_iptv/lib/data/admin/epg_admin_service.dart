// مزامنة الدليل من برنامج المدير (ADM-E1، D-13): نفس منطق supabase/epg_sync.mjs —
// المصادر بالأولوية، كل مصدر يُكمّل القنوات الناقصة، نافذة من قبل 36 ساعة إلى بعد 3 أيام،
// الكتابة عبر admin_epg_upsert (تحقق بخطوتين)، والسجل في epg_runs وtask_runs.
// (grabber مشروع iptv-org/epg يحتاج Node فيبقى في GitHub Actions حاليًا؛ الاثنان يكتبان نفس المفتاح دون تعارض.)
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/logging/log.dart';
import 'admin_repository.dart';

class EpgJob {
  final bool running;
  final String? current;
  final int done, total, channels, programmes;
  final List<String> errors;
  const EpgJob({this.running = false, this.current, this.done = 0, this.total = 0, this.channels = 0, this.programmes = 0, this.errors = const []});
}

/// ناتج تحليل مصدر في Isolate: لكل قناة عندنا (uid) صفوف البرامج الجاهزة للرفع.
Future<Map<String, List<Map<String, dynamic>>>> _parseSource(List<int> bytes, List<(String, String?, List<String>, int)> targets, String source) =>
    Isolate.run(() {
      final now = DateTime.now().toUtc();
      final data = parseXmltv(decodeImport(bytes).text, from: now.subtract(const Duration(hours: 36)), to: now.add(const Duration(days: 3)));
      final map = matchEpgChannels(data, [for (final t in targets) EpgTarget(t.$1, t.$2, t.$3)]);
      final offsets = {for (final t in targets) t.$1: t.$4};
      return {
        for (final e in map.entries)
          e.key: [
            for (final p in data.byChannel[e.value] ?? const <XmltvProgramme>[])
              {
                'channel_uid': e.key,
                // إزاحة القناة (ADM-E3) تُطبّق عند الكتابة فيراها كل المشاهدين صحيحة
                'start_at': p.start.add(Duration(minutes: offsets[e.key] ?? 0)).toIso8601String(),
                'end_at': p.end.add(Duration(minutes: offsets[e.key] ?? 0)).toIso8601String(),
                'title': p.title,
                'description': p.description,
                'category': p.category,
                'icon_url': p.icon,
                'source': source,
              },
          ],
      };
    });

/// قائمة قنوات مصدر (للاقتراحات في ADM-E2) دون البرامج.
Future<Map<String, List<String>>> epgSourceChannels(String url) async {
  final r = await SafeFetcher(policy: const SafeFetchPolicy(anyPort: true, maxBytes: maxImportBytes, timeout: Duration(seconds: 120))).get(Uri.parse(url));
  if (r.statusCode >= 400) throw StateError('HTTP ${r.statusCode}');
  return Isolate.run(() => parseXmltv(decodeImport(r.body).text, channelsOnly: true).channelNames);
}

class EpgAdminService extends Notifier<EpgJob> {
  @override
  EpgJob build() => const EpgJob();

  Future<void> run({String? onlySource}) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null || state.running) return;
    final sources = [for (final s in await repo.epgSources()) if (s['enabled'] == true && (onlySource == null || s['id'] == onlySource)) s];
    final targets = [
      for (final c in await repo.epgTargets())
        (
          c['uid'] as String,
          c['epg_id'] as String?,
          [c['name'], c['name_ar'], c['name_en'], ...((c['alt_names'] as List?) ?? const [])].whereType<String>().toList(),
          (c['epg_offset_minutes'] as num?)?.toInt() ?? 0,
        ),
    ];
    state = EpgJob(running: true, total: sources.length);
    int? runId;
    try {
      runId = await repo.startRun('epg', Platform.localHostname);
    } catch (_) {}

    final covered = <String>{};
    var programmes = 0;
    final errors = <String>[];
    for (final s in sources) {
      final pending = [for (final t in targets) if (!covered.contains(t.$1)) t];
      state = EpgJob(running: true, current: '${s['name']}', done: state.done, total: sources.length, channels: covered.length, programmes: programmes, errors: errors);
      if (pending.isEmpty) break;
      var srcChannels = 0, srcProgs = 0;
      String? err;
      try {
        final r = await SafeFetcher(policy: const SafeFetchPolicy(anyPort: true, maxBytes: maxImportBytes, timeout: Duration(seconds: 180)))
            .get(Uri.parse('${s['url']}'), headers: const {'User-Agent': 'MTC-iPTv-EPG/3'});
        if (r.statusCode >= 400) throw StateError('HTTP ${r.statusCode}');
        final byUid = await _parseSource(r.body, pending, '${s['name']}');
        final rows = [for (final l in byUid.values) ...l];
        srcProgs = rows.isEmpty ? 0 : await repo.epgUpsert(rows);
        srcChannels = byUid.values.where((l) => l.isNotEmpty).length;
        covered.addAll(byUid.entries.where((e) => e.value.isNotEmpty).map((e) => e.key));
        programmes += srcProgs;
      } catch (e) {
        err = '$e';
        errors.add('${s['name']}: $e');
        log.warning('epg source ${s['name']} failed', e);
      }
      try {
        await repo.epgFinish(s['id'] as String, status: err == null ? 'ok' : 'failed', channels: srcChannels, programmes: srcProgs, error: err);
      } catch (e) {
        log.warning('epg finish failed', e);
      }
      state = EpgJob(running: true, current: '${s['name']}', done: state.done + 1, total: sources.length, channels: covered.length, programmes: programmes, errors: errors);
    }
    if (runId != null) {
      try {
        await repo.finishRun(runId,
            status: errors.isEmpty ? 'ok' : (covered.isEmpty ? 'failed' : 'ok'),
            summary: {'channels': covered.length, 'targets': targets.length, 'programmes': programmes, 'errors': errors});
      } catch (_) {}
    }
    log.info('epg sync channels=${covered.length}/${targets.length} programmes=$programmes errors=${errors.length}');
    state = EpgJob(done: sources.length, total: sources.length, channels: covered.length, programmes: programmes, errors: errors);
  }
}

final epgAdminProvider = NotifierProvider<EpgAdminService, EpgJob>(EpgAdminService.new);
