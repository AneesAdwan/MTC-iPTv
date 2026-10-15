// ADM-A1 لوحة المعلومات (§9.3): مؤشرات حقيقية فقط من قاعدة البيانات، كل بطاقة تأخذك للقائمة المفلترة.
// (نسبة نجاح التشغيل والأجهزة النشطة تحتاج قياس المشاهدين — المرحلة 6.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'widgets/admin_widgets.dart';

final dashboardProvider = FutureProvider.autoDispose<Dashboard?>((ref) async => ref.watch(adminRepoProvider)?.dashboard());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(dashboardProvider);
    final d = async.value;
    if (d == null) {
      return async.hasError
          ? EmptyState(icon: Icons.cloud_off_rounded, title: '${async.error}')
          : const Center(child: CircularProgressIndicator());
    }
    final working = workingStates.fold<int>(0, (a, s) => a + (d.streamsByHealth[s] ?? 0));
    final failing = ['auth_failed', 'unsupported', 'network_error', 'unavailable'].fold<int>(0, (a, s) => a + (d.streamsByHealth[s] ?? 0));
    final uncertain = (d.streamsByHealth['inconclusive'] ?? 0) + (d.streamsByHealth['geo_restricted'] ?? 0);
    final published = d.channelsByState['published'] ?? 0;
    final pct = published == 0 ? 0 : (d.epgChannels * 100 / published).round();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
        Row(children: [
          const Spacer(),
          TextButton.icon(onPressed: () => ref.invalidate(dashboardProvider), icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(t.refresh)),
        ]),
        Wrap(spacing: Space.md, runSpacing: Space.md, children: [
          StatCard(label: t.kpiChannels, value: '${d.channels}', icon: Icons.tv_rounded, hint: '${t.psPublished} $published', onTap: () => context.go('/admin/channels')),
          StatCard(
              label: t.psPending,
              value: '${d.channelsByState['pending'] ?? 0}',
              icon: Icons.hourglass_top_rounded,
              color: publishColor('pending'),
              onTap: () => context.go('/admin/channels?state=pending')),
          StatCard(
              label: t.psHidden,
              value: '${d.channelsByState['hidden'] ?? 0}',
              icon: Icons.visibility_off_rounded,
              color: publishColor('hidden'),
              onTap: () => context.go('/admin/channels?state=hidden')),
          StatCard(label: t.kpiStreams, value: '${d.streams}', icon: Icons.dns_rounded, onTap: () => context.go('/admin/health')),
          StatCard(label: t.kpiWorking, value: '$working', icon: Icons.check_circle_rounded, color: healthColor('playable'), onTap: () => context.go('/admin/health?state=playable')),
          StatCard(label: t.kpiFailing, value: '$failing', icon: Icons.error_rounded, color: healthColor('unavailable'), onTap: () => context.go('/admin/health?state=unavailable')),
          StatCard(label: t.kpiUncertain, value: '$uncertain', icon: Icons.help_rounded, color: healthColor('inconclusive'), onTap: () => context.go('/admin/health?state=inconclusive')),
          StatCard(label: t.kpiOpenReports, value: '${d.openReports}', icon: Icons.flag_rounded, color: d.openReports > 0 ? healthColor('degraded') : null, onTap: () => context.go('/admin/reports')),
          StatCard(label: t.kpiEpgCoverage, value: '$pct%', icon: Icons.view_timeline_rounded, hint: t.kpiEpgHint(d.epgChannels, published)),
        ]),
        const SizedBox(height: Space.lg),
        SectionCard(
          title: t.streamHealth,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // شريط التوزيع
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: Row(children: [
                  for (final s in healthStates)
                    if ((d.streamsByHealth[s] ?? 0) > 0) Expanded(flex: d.streamsByHealth[s]!, child: ColoredBox(color: healthColor(s))),
                ]),
              ),
            ),
            const SizedBox(height: Space.md),
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (final s in healthStates)
                if ((d.streamsByHealth[s] ?? 0) > 0)
                  ActionChip(
                    avatar: Icon(healthIcon(s), size: 16, color: healthColor(s)),
                    label: Text('${healthLabel(t, s)}  ${d.streamsByHealth[s]}'),
                    onPressed: () => context.go('/admin/health?state=$s'),
                  ),
            ]),
          ]),
        ),
        const SizedBox(height: Space.lg),
        SectionCard(
          title: t.quickActions,
          child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            FilledButton.tonalIcon(onPressed: () => context.go('/admin/channels?state=pending'), icon: const Icon(Icons.fact_check_rounded), label: Text(t.qaReviewPending)),
            FilledButton.tonalIcon(onPressed: () => context.go('/admin/health?state=unavailable'), icon: const Icon(Icons.monitor_heart_rounded), label: Text(t.qaCheckFailing)),
            FilledButton.tonalIcon(onPressed: () => context.go('/admin/reports'), icon: const Icon(Icons.flag_rounded), label: Text(t.qaReports)),
            FilledButton.tonalIcon(onPressed: () => context.go('/admin/channels?add=1'), icon: const Icon(Icons.add_rounded), label: Text(t.addChannel)),
          ]),
        ),
        const SizedBox(height: Space.lg),
        SectionCard(
          title: t.recentChanges,
          child: d.recent.isEmpty
              ? Text(t.noChanges, style: TextStyle(color: c.textMuted))
              : Column(children: [for (final e in d.recent) AuditTile(entry: e)]),
        ),
      ]),
    );
  }
}

/// سطر سجل تدقيق: العملية، الجدول، الحقول المتغيرة.
class AuditTile extends StatelessWidget {
  final AuditEntry entry;
  const AuditTile({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = entry;
    final name = '${e.after?['name_ar'] ?? e.after?['name'] ?? e.before?['name_ar'] ?? e.before?['name'] ?? e.after?['url'] ?? ''}';
    final changes = e.action == 'UPDATE' ? e.changes.map((x) => x.$1).take(6).join('، ') : '';
    final icon = switch (e.action) { 'INSERT' => Icons.add_circle_rounded, 'DELETE' => Icons.remove_circle_rounded, _ => Icons.edit_rounded };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: c.textMuted),
      title: Text('${e.table} · $name', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text)),
      subtitle: Text([shortTime(e.at), ?e.reason, if (changes.isNotEmpty) changes].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted)),
    );
  }
}
