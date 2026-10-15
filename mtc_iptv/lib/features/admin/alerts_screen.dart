// ADM-A3 التنبيهات (§9.3): فشل الدليل، تعطّل مصدر، فشل استيراد، انخفاض نسبة النجاح، النسخ الاحتياطي،
// بلاغات متكررة، توقف موصل. الحالة: جديد ← تمّت رؤيته ← تمّ الحل، مع ربط بالعنصر.
// الفحص يجري على الخادم (admin_alerts_scan) كل ساعة من المُجدوِل، أو الآن من هنا. الحل قرار المدير دائمًا.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'dashboard_screen.dart';
import 'epg_screens.dart' show migrationAware;
import 'jobs_screen.dart' show taskLabel;
import 'widgets/admin_widgets.dart';

final alertsFilterProvider = NotifierProvider<_Filter, String>(_Filter.new);

class _Filter extends Notifier<String> {
  @override
  String build() => 'open'; // open = جديد + تمّت رؤيته
  void set(String v) => state = v;
}

final alertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return const [];
  final f = ref.watch(alertsFilterProvider);
  final rows = await repo.alerts(status: f == 'open' || f == 'all' ? null : f);
  return f == 'open' ? rows.where((r) => r['status'] != 'resolved').toList() : rows;
});

String alertKindLabel(L10n t, String k) => switch (k) {
      'epg_failed' => t.alEpgFailed,
      'epg_stale' => t.alEpgStale,
      'source_failed' => t.alSourceFailed,
      'import_failed' => t.alImportFailed,
      'success_drop' => t.alSuccessDrop,
      'backup_failed' => t.alBackupFailed,
      'backup_stale' => t.alBackupStale,
      'repeated_reports' => t.alRepeatedReports,
      'connector_stopped' => t.alConnectorStopped,
      _ => t.alTaskFailed,
    };

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});
  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool scanning = false;

  void _reload() {
    ref.invalidate(alertsProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<void> _scan() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    setState(() => scanning = true);
    try {
      await repo.alertsScan();
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => scanning = false);
      _reload();
    }
  }

  Future<void> _set(List<int> ids, String status) async {
    if (ids.isEmpty) return;
    try {
      await ref.read(adminRepoProvider)?.setAlertStatus(ids, status);
    } catch (e) {
      // إعادة فتح تنبيه محلول بينما نفس الحالة مفتوحة بتنبيه أحدث (مفتاح فريد للمفتوح)
      if (mounted) toast(context, L10n.of(context).alAlreadyOpen);
    }
    _reload();
  }

  /// النص الظاهر: نوع التنبيه + العنصر (اسم المهمة مترجمًا، أو اسم القناة/المصدر).
  String _subject(L10n t, Map<String, dynamic> a) {
    final title = '${a['title'] ?? ''}';
    if (a['ref_type'] == 'task' || a['kind'] == 'backup_stale' || a['kind'] == 'epg_stale') return taskLabel(t, title == 'epg' ? 'epg' : title);
    if (a['kind'] == 'success_drop') {
      final d = (a['detail'] as Map?) ?? const {};
      final rate = (d['rate'] as num?)?.toDouble(), prev = (d['previous'] as num?)?.toDouble();
      return t.alSuccessDetail('${((rate ?? 0) * 100).round()}%', prev == null ? '—' : '${(prev * 100).round()}%', '${d['attempts'] ?? ''}');
    }
    if (a['kind'] == 'repeated_reports') return t.alReportsDetail(title, '${(a['detail'] as Map?)?['count'] ?? ''}');
    return title;
  }

  String? _link(Map<String, dynamic> a) => switch (a['ref_type']) {
        'channel' => '/admin/channel/${a['ref_id']}',
        'epg_source' => '/admin/epg-sources',
        'source' => '/admin/sources',
        'connector' => '/admin/connectors',
        'task' => a['ref_id'] == 'backup' ? '/admin/backups' : '/admin/scheduler',
        _ => switch (a['kind']) {
            'backup_stale' || 'backup_failed' => '/admin/backups',
            'epg_stale' || 'epg_failed' => '/admin/epg-sources',
            'success_drop' => '/admin/analytics',
            _ => null,
          },
      };

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final f = ref.watch(alertsFilterProvider);
    final async = ref.watch(alertsProvider);
    final list = async.value ?? const <Map<String, dynamic>>[];
    final newIds = [for (final a in list) if (a['status'] == 'new') (a['id'] as num).toInt()];

    final header = Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'open', label: Text(t.alOpen)),
          ButtonSegment(value: 'new', label: Text(t.alNew)),
          ButtonSegment(value: 'resolved', label: Text(t.alResolved)),
          ButtonSegment(value: 'all', label: Text(t.alAll)),
        ],
        selected: {f},
        onSelectionChanged: (s) => ref.read(alertsFilterProvider.notifier).set(s.first),
      ),
      FilledButton.tonalIcon(
        onPressed: scanning ? null : _scan,
        icon: scanning ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.radar_rounded),
        label: Text(t.alScanNow),
      ),
      if (newIds.isNotEmpty) OutlinedButton.icon(onPressed: () => _set(newIds, 'seen'), icon: const Icon(Icons.done_all_rounded), label: Text(t.alMarkAllSeen)),
    ]);

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      header,
      const SizedBox(height: Space.sm),
      Text(t.alHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
      const SizedBox(height: Space.md),
      if (async.hasError)
        SizedBox(height: 300, child: migrationAware(context, async.error!))
      else if (async.isLoading && list.isEmpty)
        const Padding(padding: EdgeInsets.all(Space.xl), child: Center(child: CircularProgressIndicator()))
      else if (list.isEmpty)
        SizedBox(height: 300, child: EmptyState(icon: Icons.verified_rounded, title: t.alNone))
      else
        for (final a in list) _tile(context, t, c, a),
    ]);
  }

  Widget _tile(BuildContext context, L10n t, MtcColors c, Map<String, dynamic> a) {
    final id = (a['id'] as num).toInt();
    final sev = '${a['severity']}';
    final color = switch (sev) { 'critical' => healthColor('unavailable'), 'warning' => healthColor('degraded'), _ => healthColor('reachable') };
    final status = '${a['status']}';
    final link = _link(a);
    final last = DateTime.tryParse('${a['last_at']}')?.toLocal();
    final first = DateTime.tryParse('${a['first_at']}')?.toLocal();
    final n = (a['occurrences'] as num?)?.toInt() ?? 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: status == 'new' ? color : c.line, width: status == 'new' ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(sev == 'critical' ? Icons.error_rounded : Icons.warning_amber_rounded, color: color),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(alertKindLabel(t, '${a['kind']}'), style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                  Pill(switch (status) { 'new' => t.alNew, 'seen' => t.alSeen, _ => t.alResolved }, status == 'new' ? color : c.textMuted),
                  if (n > 1) Pill(t.alTimes(n), c.textMuted),
                ]),
                const SizedBox(height: 2),
                Text(_subject(t, a), style: TextStyle(color: c.text)),
                Text(
                  [if (first != null) t.alFirst(shortTime(first)), if (last != null && n > 1) t.alLast(shortTime(last))].join(' · '),
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              ]),
            ),
            Wrap(spacing: 4, children: [
              if (link != null) IconButton(tooltip: t.alOpenItem, onPressed: () => context.go(link), icon: const Icon(Icons.open_in_new_rounded, size: 18)),
              if (status == 'new') IconButton(tooltip: t.alSeen, onPressed: () => _set([id], 'seen'), icon: const Icon(Icons.visibility_rounded, size: 18)),
              if (status != 'resolved')
                IconButton(tooltip: t.aResolve, onPressed: () => _set([id], 'resolved'), icon: const Icon(Icons.task_alt_rounded, size: 18))
              else
                IconButton(tooltip: t.alReopen, onPressed: () => _set([id], 'seen'), icon: const Icon(Icons.undo_rounded, size: 18)),
            ]),
          ]),
        ),
      ),
    );
  }
}
