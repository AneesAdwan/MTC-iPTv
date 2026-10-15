// ADM-A2 المهام والطوابير (§9.3): المهمة الجارية الآن، آخر التشغيلات (task_runs)، والمهام المجدولة.
// المُجدوِل الذي يشغّل المهام الدورية تلقائيًا يأتي مع ADM-H2 (المرحلة 6)؛ الفحوص اليدوية تُسجَّل هنا.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/health_service.dart';
import 'widgets/admin_widgets.dart';

final _runsProvider = FutureProvider.autoDispose<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return (const <Map<String, dynamic>>[], const <Map<String, dynamic>>[]);
  return (await repo.taskRuns(), await repo.scheduledTasks());
});

String taskLabel(L10n t, String k) => switch (k) {
      'health_published' => t.tkHealthPublished,
      'health_all' => t.tkHealthAll,
      'playback_sample' => t.tkPlaybackSample,
      'logos' => t.tkLogos,
      'epg' => t.tkEpg,
      'sources' => t.tkSources,
      'backup' => t.tkBackup,
      'telemetry_rollup' => t.tkTelemetryRollup,
      'alerts' => t.tkAlerts,
      _ => k,
    };

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  Color _statusColor(String s) => switch (s) {
        'ok' => healthColor('playable'),
        'failed' => healthColor('unavailable'),
        'running' => healthColor('reachable'),
        _ => healthColor('inconclusive'),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final job = ref.watch(healthJobProvider);
    final data = ref.watch(_runsProvider);
    final runs = data.value?.$1 ?? const <Map<String, dynamic>>[];
    final tasks = data.value?.$2 ?? const <Map<String, dynamic>>[];
    ref.listen(healthJobProvider, (prev, next) {
      if (prev?.running != next.running) ref.invalidate(_runsProvider);
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(_runsProvider.future),
      child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
        SectionCard(
          title: t.jobsRunning,
          trailing: IconButton(onPressed: () => ref.invalidate(_runsProvider), icon: const Icon(Icons.refresh_rounded)),
          child: job.running
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text('${t.tkHealthAll} · ${t.checkRunning(job.done, job.total)}', style: TextStyle(color: c.text))),
                    TextButton(onPressed: ref.read(healthJobProvider.notifier).cancel, child: Text(t.stop)),
                  ]),
                  LinearProgressIndicator(value: job.progress),
                  const SizedBox(height: Space.xs),
                  Wrap(spacing: Space.xs, children: [for (final e in job.results.entries) Pill('${healthLabel(t, e.key)} ${e.value}', healthColor(e.key))]),
                ])
              : Text(t.statusIdle, style: TextStyle(color: c.textMuted)),
        ),
        const SizedBox(height: Space.lg),
        SectionCard(
          title: t.jobsHistory,
          child: runs.isEmpty
              ? Text(data.hasError ? '${data.error}' : t.noRuns, style: TextStyle(color: c.textMuted))
              : Column(children: [
                  for (final r in runs)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: Pill('${r['status']}', _statusColor('${r['status']}')),
                      title: Text(taskLabel(t, '${r['task_key']}'), style: TextStyle(color: c.text)),
                      subtitle: Text(
                        [
                          shortTime(DateTime.parse('${r['started_at']}').toLocal()),
                          if (r['finished_at'] != null)
                            '${DateTime.parse('${r['finished_at']}').difference(DateTime.parse('${r['started_at']}')).inSeconds}s',
                          '${r['device'] ?? ''}',
                        ].join(' · '),
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              [const JsonEncoder.withIndent('  ').convert(r['summary']), if (r['error'] != null) 'error: ${r['error']}'].join('\n'),
                              style: TextStyle(color: c.textMuted, fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ]),
        ),
        const SizedBox(height: Space.lg),
        SectionCard(
          title: t.jobsScheduled,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.schedulerNote, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            const SizedBox(height: Space.sm),
            for (final k in tasks)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(k['enabled'] == true ? Icons.schedule_rounded : Icons.pause_circle_outline_rounded, color: c.textMuted),
                title: Text(taskLabel(t, '${k['key']}'), style: TextStyle(color: c.text)),
                subtitle: Text(
                  [
                    t.taskEvery((k['interval_min'] as num?)?.toInt() ?? 0),
                    if (k['last_run_at'] != null) t.taskLast(shortTime(DateTime.parse('${k['last_run_at']}').toLocal())),
                  ].join(' · '),
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                trailing: k['last_status'] == null ? null : Pill('${k['last_status']}', _statusColor('${k['last_status']}')),
              ),
          ]),
        ),
      ]),
    );
  }
}
