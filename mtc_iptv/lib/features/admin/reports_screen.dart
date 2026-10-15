// ADM-D6 بلاغات المشاهدين (§9.6): مجمّعة حسب القناة مع التشخيص، «فحص الآن»، «جرّب»، «تمّ الحل»، إخفاء القناة.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/health_service.dart';
import '../viewer/guide_screen.dart' show textDirOf;
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'dashboard_screen.dart';
import 'widgets/admin_widgets.dart';

final reportsProvider = FutureProvider.autoDispose<List<ReportGroup>>((ref) async => await ref.watch(adminRepoProvider)?.openReports() ?? const []);

class ReportsAdminScreen extends ConsumerWidget {
  const ReportsAdminScreen({super.key});

  String _reason(L10n t, String r) => switch (r) {
        'not_working' => t.reasonNotWorking,
        'wrong_info' => t.reasonWrongInfo,
        'bad_quality' => t.reasonBadQuality,
        _ => t.reasonOther,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(reportsProvider);
    final groups = async.value ?? const <ReportGroup>[];
    final job = ref.watch(healthJobProvider);
    final repo = ref.read(adminRepoProvider);
    void reload() {
      ref.invalidate(reportsProvider);
      ref.invalidate(dashboardProvider);
    }

    if (async.isLoading && groups.isEmpty) return const Center(child: CircularProgressIndicator());
    if (groups.isEmpty) return EmptyState(icon: Icons.task_alt_rounded, title: t.noOpenReports);

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      if (job.running) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: LinearProgressIndicator(value: job.progress)),
      for (final g in groups)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: SectionCard(
            title: '${g.number ?? '—'} · ${g.channelName}',
            trailing: Pill(t.reportsCount(g.reports.length), g.reports.length >= 3 ? healthColor('unavailable') : healthColor('degraded'), icon: Icons.flag_rounded),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final r in g.reports.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 130, child: Text(shortTime(DateTime.parse(r['created_at'] as String).toLocal()), style: TextStyle(color: c.textMuted, fontSize: 12))),
                    SizedBox(width: 120, child: Text(_reason(t, '${r['reason']}'), style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 13))),
                    Expanded(
                      child: Text('${r['note'] ?? ''}', textDirection: textDirOf('${r['note'] ?? ''}'), style: TextStyle(color: c.text, fontSize: 13)),
                    ),
                  ]),
                ),
              const SizedBox(height: Space.sm),
              Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                OutlinedButton.icon(onPressed: () => context.push('/watch/${g.channelId}'), icon: const Icon(Icons.play_arrow_rounded, size: 18), label: Text(t.aTry)),
                OutlinedButton.icon(
                  onPressed: job.running || repo == null ? null : () async => ref.read(healthJobProvider.notifier).run(await repo.streamsOf(g.channelId)),
                  icon: const Icon(Icons.monitor_heart_rounded, size: 18),
                  label: Text(t.aCheckStreams),
                ),
                OutlinedButton.icon(onPressed: () => context.go('/admin/channel/${g.channelId}'), icon: const Icon(Icons.open_in_new_rounded, size: 18), label: Text(t.aOpenChannel)),
                OutlinedButton(
                  onPressed: repo == null
                      ? null
                      : () async {
                          await repo.updateChannels([g.channelId], {'publish_state': 'hidden', 'hidden_reason': 'reported'});
                          if (context.mounted) toast(context, t.saved);
                        },
                  child: Text(t.aHideChannel),
                ),
                FilledButton.icon(
                  onPressed: repo == null
                      ? null
                      : () async {
                          await repo.resolveReports(g.channelId);
                          reload();
                        },
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: Text(t.aResolve),
                ),
              ]),
            ]),
          ),
        ),
    ]);
  }
}
