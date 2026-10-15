// ADM-I1 التحليلات (§9.11): نسبة نجاح التشغيل حسب القناة والنطاق والمنصّة والدولة، الأكثر مشاهدة (≥ 30 ث)،
// زمن البدء (الوسيط وP90)، الأجهزة والإصدارات، البلاغات، ونشاط المهام — مع تصدير CSV (يفتحه Excel).
// المشاهدات من أحداث تشغيل حقيقية فقط (playback_stats_daily)، لا من الفحص.
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/text/bidi.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/analytics.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'dashboard_screen.dart';
import 'epg_screens.dart' show migrationAware;
import 'jobs_screen.dart' show taskLabel;
import 'widgets/admin_widgets.dart';

final analyticsDaysProvider = NotifierProvider<_Days, int>(_Days.new);

class _Days extends Notifier<int> {
  @override
  int build() => 7;
  void set(int v) => state = v;
}

class AnalyticsData {
  final int days;
  final PlaybackAnalytics play;
  final DeviceStats devices;
  final Map<String, Map<String, dynamic>> channels; // id ← {number, name…}
  final List<Map<String, dynamic>> reports, runs;
  AnalyticsData(this.days, this.play, this.devices, this.channels, this.reports, this.runs);
}

final analyticsProvider = FutureProvider.autoDispose<AnalyticsData?>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return null;
  final days = ref.watch(analyticsDaysProvider);
  final now = DateTime.now().toUtc();
  final from = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  final rows = await repo.playbackStats(from);
  final hosts = await repo.streamHosts({for (final r in rows) '${r['stream_id']}'});
  final play = PlaybackAnalytics.from(rows, hosts: hosts);
  final names = await repo.channelRows(play.byChannel.keys);
  final inst = await repo.installations(now.subtract(const Duration(days: 30)));
  return AnalyticsData(days, play, DeviceStats.from(inst), {for (final n in names) '${n['id']}': n}, await repo.reportsSince(from), await repo.runsSince(from));
});

String _pct(double? r) => r == null ? '—' : '${(r * 100).round()}%';
String _sec(int? ms) => ms == null ? '—' : '${(ms / 1000).toStringAsFixed(1)}s';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _chName(BuildContext context, AnalyticsData d, String id) {
    final n = d.channels[id];
    if (n == null) return id.substring(0, 8);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final name = '${(ar ? n['name_ar'] : n['name_en']) ?? n['name'] ?? ''}';
    return n['number'] == null ? name : '${n['number']} · $name';
  }

  Future<void> _export(BuildContext context, String name, List<String> header, List<List<Object?>> rows) async {
    final loc = await getSaveLocation(suggestedName: 'mtc-$name-${DateTime.now().toIso8601String().substring(0, 10)}.csv');
    if (loc == null) return;
    await File(loc.path).writeAsString(toExcelCsv(header, rows));
    if (context.mounted) toast(context, L10n.of(context).saved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final days = ref.watch(analyticsDaysProvider);
    final async = ref.watch(analyticsProvider);
    final d = async.value;

    final header = Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SegmentedButton<int>(
        segments: [for (final n in const [1, 7, 30]) ButtonSegment(value: n, label: Text(t.anDays(n)))],
        selected: {days},
        onSelectionChanged: (s) => ref.read(analyticsDaysProvider.notifier).set(s.first),
      ),
      TextButton.icon(onPressed: () => ref.invalidate(analyticsProvider), icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(t.refresh)),
    ]);

    if (async.hasError) return Column(children: [Padding(padding: const EdgeInsets.all(Space.lg), child: header), Expanded(child: migrationAware(context, async.error!))]);
    if (d == null) return async.isLoading ? const Center(child: CircularProgressIndicator()) : EmptyState(icon: Icons.cloud_off_rounded, title: t.anNoData);

    final p = d.play;
    final tot = p.total;
    // صفوف الجداول (تُستخدم للعرض وللتصدير)
    List<Object?> statCells(StatAgg s) => [s.attempts, s.successes, _pct(s.rateIfSample()), s.sessions30, (s.watchSeconds / 3600).toStringAsFixed(1), _sec(s.ttffP50), _sec(s.ttffP90)];
    final statHeader = [t.anAttempts, t.anSuccesses, t.anRate, t.anViews, t.anHours, t.anTtff50, t.anTtff90];
    List<List<Object?>> rowsOf(Iterable<MapEntry<String, StatAgg>> es, String Function(String) label) => [for (final e in es) [label(e.key), ...statCells(e.value)]];

    final top = rowsOf(PlaybackAnalytics.topViewed(p.byChannel).take(25), (k) => _chName(context, d, k));
    final worst = rowsOf(PlaybackAnalytics.worst(p.byChannel).take(25), (k) => _chName(context, d, k));
    final hosts = rowsOf(PlaybackAnalytics.topViewed(p.byHost).take(40), (k) => k);
    final plats = rowsOf(PlaybackAnalytics.topViewed(p.byPlatform), (k) => k);
    final countries = rowsOf(PlaybackAnalytics.topViewed(p.byCountry).take(40), (k) => k);
    final daily = rowsOf(p.byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)), (k) => k);

    final epg = ref.watch(dashboardProvider).value;
    final published = epg?.channelsByState['published'] ?? 0;

    final reasons = <String, int>{};
    var openReports = 0;
    for (final r in d.reports) {
      reasons['${r['reason']}'] = (reasons['${r['reason']}'] ?? 0) + 1;
      if (r['status'] == 'open') openReports++;
    }
    final runs = <String, (int, int)>{}; // المهمة ← (ناجحة، فاشلة)
    for (final r in d.runs) {
      final k = '${r['task_key']}';
      final (ok, bad) = runs[k] ?? (0, 0);
      runs[k] = r['status'] == 'ok' ? (ok + 1, bad) : r['status'] == 'failed' ? (ok, bad + 1) : (ok, bad);
    }

    Widget table(String title, String file, List<String> cols, List<List<Object?>> rows, {String? hint}) => Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: SectionCard(
            title: title,
            trailing: rows.isEmpty
                ? null
                : IconButton(tooltip: t.anExport, onPressed: () => _export(context, file, cols, rows), icon: const Icon(Icons.download_rounded, size: 18)),
            child: rows.isEmpty
                ? Text(t.anNoData, style: TextStyle(color: c.textMuted))
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (hint != null) Padding(padding: const EdgeInsets.only(bottom: Space.sm), child: Text(hint, style: TextStyle(color: c.textMuted, fontSize: 12))),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 40,
                        columnSpacing: Space.lg,
                        columns: [for (final h in cols) DataColumn(label: Text(h, style: TextStyle(color: c.textMuted, fontSize: 12)))],
                        rows: [
                          for (final r in rows)
                            DataRow(cells: [for (final v in r) DataCell(Text(ltrIfNum('$v'), style: TextStyle(color: c.text, fontSize: 13)))]),
                        ],
                      ),
                    ),
                  ]),
          ),
        );

    Widget chips(String title, Map<String, int> m) => Padding(
          padding: const EdgeInsets.only(top: Space.sm),
          child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(width: 90, child: Text(title, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            for (final e in (m.entries.toList()..sort((a, b) => b.value - a.value)).take(12)) Chip(label: Text('${e.key}  ${e.value}'), visualDensity: VisualDensity.compact),
          ]),
        );

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      header,
      const SizedBox(height: Space.sm),
      Text(t.anHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
      const SizedBox(height: Space.md),
      Wrap(spacing: Space.md, runSpacing: Space.md, children: [
        StatCard(label: t.anAttempts, value: '${tot.attempts}', icon: Icons.play_circle_outline_rounded),
        StatCard(
          label: t.anRate,
          value: _pct(tot.rateIfSample(minSampleDashboard)),
          icon: Icons.check_circle_rounded,
          hint: tot.rateIfSample(minSampleDashboard) == null ? t.kpiSampleLow(tot.attempts) : null,
          color: tot.rateIfSample(minSampleDashboard) == null ? null : healthColor(tot.rate! >= 0.8 ? 'playable' : tot.rate! >= 0.6 ? 'degraded' : 'unavailable'),
        ),
        StatCard(label: t.anViews, value: '${tot.sessions30}', icon: Icons.visibility_rounded),
        StatCard(label: t.anHours, value: (tot.watchSeconds / 3600).toStringAsFixed(1), icon: Icons.schedule_rounded),
        StatCard(label: t.anTtff50, value: _sec(tot.ttffP50), icon: Icons.speed_rounded, hint: 'P90 ${_sec(tot.ttffP90)}'),
        StatCard(label: t.kpiDevices7, value: '${d.devices.active7}', icon: Icons.devices_rounded, hint: t.anDevices30(d.devices.active30)),
      ]),
      const SizedBox(height: Space.lg),
      table(t.anTopChannels, 'top-channels', [t.anChannel, ...statHeader], top),
      table(t.anWorstChannels, 'worst-channels', [t.anChannel, ...statHeader], worst, hint: t.anMinSample(minSampleItem)),
      table(t.anByHost, 'hosts', [t.anHost, ...statHeader], hosts),
      table(t.anByPlatform, 'platforms', [t.anPlatform, ...statHeader], plats),
      table(t.anByCountry, 'countries', [t.anCountry, ...statHeader], countries),
      table(t.anByDay, 'daily', [t.anDay, ...statHeader], daily),
      Padding(
        padding: const EdgeInsets.only(bottom: Space.lg),
        child: SectionCard(
          title: t.anDevices,
          trailing: IconButton(
            tooltip: t.anExport,
            onPressed: () => _export(context, 'devices', [t.anGroup, t.anValue, t.anCount], [
              for (final (g, m) in [(t.anPlatform, d.devices.byPlatform), (t.anVersion, d.devices.byVersion), (t.anCountry, d.devices.byCountry), (t.anLanguage, d.devices.byLocale)])
                for (final e in m.entries) [g, e.key, e.value],
            ]),
            icon: const Icon(Icons.download_rounded, size: 18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.anDevicesLine(d.devices.active7, d.devices.active30), style: TextStyle(color: c.text)),
            chips(t.anPlatform, d.devices.byPlatform),
            chips(t.anVersion, d.devices.byVersion),
            chips(t.anCountry, d.devices.byCountry),
            chips(t.anLanguage, d.devices.byLocale),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: Space.lg),
        child: SectionCard(
          title: t.sD6,
          trailing: TextButton(onPressed: () => context.go('/admin/reports'), child: Text(t.alOpenItem)),
          child: d.reports.isEmpty
              ? Text(t.anNoData, style: TextStyle(color: c.textMuted))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.anReportsLine(d.reports.length, openReports), style: TextStyle(color: c.text)),
                  chips(t.anReason, {
                    for (final e in reasons.entries)
                      switch (e.key) { 'not_working' => t.reasonNotWorking, 'wrong_info' => t.reasonWrongInfo, 'bad_quality' => t.reasonBadQuality, _ => t.reasonOther }: e.value,
                  }),
                ]),
        ),
      ),
      table(t.anActivity, 'tasks', [t.anTask, t.anOk, t.anFailed], [
        for (final e in runs.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) [taskLabel(t, e.key), e.value.$1, e.value.$2],
      ]),
      SectionCard(
        title: t.kpiEpgCoverage,
        trailing: TextButton(onPressed: () => context.go('/admin/epg-preview'), child: Text(t.alOpenItem)),
        child: epg == null
            ? Text('…', style: TextStyle(color: c.textMuted))
            : Text(t.kpiEpgHint(epg.epgChannels, published), style: TextStyle(color: c.text)),
      ),
      if (tot.attempts == 0) SizedBox(height: 200, child: EmptyState(icon: Icons.insights_rounded, title: t.anEmpty)),
    ]);
  }
}

/// أرقام ونسب ونطاقات تُعرض LTR داخل الواجهة العربية.
String ltrIfNum(String s) => RegExp(r'^[\d.,%s:\-—/ ]+$').hasMatch(s) || s.contains('.') && !s.contains(' ') ? ltr(s) : s;
