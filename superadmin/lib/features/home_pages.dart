// Section 1 — Home: KPIs, "needs your attention", running jobs, alerts.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../ui/data_table.dart';
import '../ui/decision_card.dart';
import '../ui/page_scaffold.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dashboardRepoProvider);
    return ServicePage(
      page: Nav.home.pages[0],
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsyncView<Kpis>(
            load: repo.kpis,
            builder: (context, k, reload) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(onPressed: reload, icon: const Icon(Icons.refresh, size: 18), label: Text(context.tr(const Tr('تحديث', 'Refresh')))),
                ),
                LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth > 1100 ? 4 : (box.maxWidth > 700 ? 3 : 2);
                    final cards = <Widget>[
                      KpiCard(
                        label: const Tr('قنوات منشورة', 'Published channels'),
                        value: fmtInt(k.published),
                        icon: Icons.live_tv,
                        tone: Tone.ok,
                        onTap: () => context.go('/channels?state=published'),
                      ),
                      KpiCard(
                        label: const Tr('قيد المراجعة', 'In review'),
                        value: fmtInt(k.review),
                        icon: Icons.hourglass_top,
                        tone: Tone.warn,
                        onTap: () => context.go('/decisions?type=review'),
                      ),
                      KpiCard(
                        label: const Tr('مخفية', 'Hidden'),
                        value: fmtInt(k.hidden),
                        icon: Icons.visibility_off_outlined,
                        onTap: () => context.go('/channels?state=hidden'),
                      ),
                      KpiCard(
                        label: const Tr('روابط معطّلة', 'Broken streams'),
                        value: fmtInt(k.linksBroken),
                        icon: Icons.link_off,
                        tone: Tone.bad,
                        hint: Tr(
                          'تعمل ${fmtInt(k.linksWorking)} · غير مؤكدة ${fmtInt(k.linksUnknown)}',
                          'Working ${fmtInt(k.linksWorking)} · unverified ${fmtInt(k.linksUnknown)}',
                        ),
                        onTap: () => context.go('/decisions?type=broken'),
                      ),
                      KpiCard(
                        label: const Tr('نجاح التشغيل (24 ساعة)', 'Playback success (24h)'),
                        value: k.playSamples24h >= 100 && k.playSuccess24h != null ? '${(k.playSuccess24h! * 100).toStringAsFixed(1)}%' : '—',
                        hint: Tr('${fmtInt(k.playSamples24h)} محاولة', '${fmtInt(k.playSamples24h)} attempts'),
                        icon: Icons.play_circle_outline,
                        tone: Tone.info,
                        onTap: () => context.go('/system/analytics'),
                      ),
                      KpiCard(
                        label: const Tr('أجهزة نشطة (7 أيام)', 'Active devices (7d)'),
                        value: fmtInt(k.activeDevices7d),
                        icon: Icons.devices_other,
                        tone: Tone.info,
                        onTap: () => context.go('/system/analytics'),
                      ),
                      KpiCard(
                        label: const Tr('تغطية الدليل', 'EPG coverage'),
                        value: '${(k.epgCoverage * 100).round()}%',
                        icon: Icons.calendar_view_week,
                        tone: Tone.accent,
                        onTap: () => context.go('/epg/mapping'),
                      ),
                      KpiCard(
                        label: const Tr('بلاغات مفتوحة', 'Open reports'),
                        value: fmtInt(k.openReports),
                        icon: Icons.report_outlined,
                        tone: Tone.warn,
                        onTap: () => context.go('/decisions?type=reports'),
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Space.md,
                      crossAxisSpacing: Space.md,
                      childAspectRatio: 2.6,
                      children: cards,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          Panel(
            title: const Tr('بدها انتباهك', 'Needs your attention'),
            child: AsyncView<List<DecisionItem>>(
              load: repo.attention,
              builder: (context, items, _) => Column(
                children: [
                  for (final d in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: DecisionCard(
                        title: d.title,
                        typeLabel: DecisionType.byId(d.type)?.title ?? Tr(d.type, d.type),
                        typeTone: Tone.warn,
                        why: d.why,
                        evidence: d.evidence,
                        actions: [
                          DecisionAction(
                            const Tr('افتح بمركز القرارات', 'Open in decision center'),
                            () => context.go('/decisions?type=${d.type}'),
                            primary: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});
  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final _table = TableController();
  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(dashboardRepoProvider);
    final c = context.colors;
    return ServicePage(
      page: Nav.home.pages[1],
      actions: [
        OutlinedButton.icon(onPressed: _table.reload, icon: const Icon(Icons.refresh, size: 18), label: Text(context.tr(const Tr('تحديث', 'Refresh')))),
      ],
      child: MtcDataTable<JobInfo>(
        source: repo.jobs,
        controller: _table,
        rowHeight: 56,
        columns: [
          TableColumn(
            label: const Tr('المهمة', 'Job'),
            flex: 3,
            cell: (context, j) => Text(context.tr(j.kind), overflow: TextOverflow.ellipsis),
          ),
          TableColumn(
            label: const Tr('الحالة', 'State'),
            width: 110,
            cell: (context, j) => Pill(context.tr(j.state.label), tone: j.state.tone),
          ),
          TableColumn(
            label: const Tr('التقدّم', 'Progress'),
            flex: 2,
            cell: (context, j) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: j.progress, color: c.tone(j.state.tone), backgroundColor: c.surface2),
                const SizedBox(height: 2),
                Text(
                  j.message,
                  style: TextStyle(color: c.textDim, fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TableColumn(
            label: const Tr('المنفّذ', 'Executor'),
            width: 120,
            cell: (context, j) => Text(j.executor, style: TextStyle(color: c.textMuted)),
          ),
          TableColumn(label: const Tr('بدأت', 'Started'), width: 130, cell: (context, j) => Text(fmtDateTime(j.startedAt))),
          TableColumn(
            label: const Tr('إجراء', 'Action'),
            width: 150,
            cell: (context, j) => switch (j.state) {
              JobState.running || JobState.queued => TextButton(
                onPressed: () => confirmAndRun(
                  context,
                  ref,
                  title: Tr('إيقاف: ${context.tr(j.kind)}', 'Stop: ${context.tr(j.kind)}'),
                  spec: Rpc.jobCancel,
                  unit: const Tr('مهمة', 'job'),
                  run: (r) => repo.cancelJob(j.id, reason: r),
                ),
                child: Text(context.tr(const Tr('إيقاف', 'Stop'))),
              ),
              JobState.failed || JobState.stopped => TextButton(
                onPressed: () => confirmAndRun(
                  context,
                  ref,
                  title: Tr('إعادة: ${context.tr(j.kind)}', 'Re-run: ${context.tr(j.kind)}'),
                  spec: Rpc.jobRetry,
                  unit: const Tr('مهمة', 'job'),
                  run: (r) => repo.retryJob(j.id, reason: r),
                ),
                child: Text(context.tr(const Tr('أعد التشغيل', 'Re-run'))),
              ),
              JobState.done => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(dashboardRepoProvider);
    final c = context.colors;
    return ServicePage(
      page: Nav.home.pages[2],
      scroll: true,
      child: AsyncView<List<AlertItem>>(
        load: repo.alerts,
        builder: (context, alerts, _) => alerts.isEmpty
            ? const EmptyState(title: Tr('ما في تنبيهات', 'No alerts'), icon: Icons.notifications_off_outlined)
            : Column(
                children: [
                  for (final a in alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Panel(
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: c.tone(a.severity)),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.tr(a.title), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(context.tr(a.detail), style: TextStyle(color: c.textMuted)),
                                  Text(fmtDateTime(a.at), style: TextStyle(color: c.textDim, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (a.link != null) TextButton(onPressed: () => context.go(a.link!), child: Text(context.tr(const Tr('فتح العنصر', 'Open item')))),
                            if (a.state == AlertState.open)
                              TextButton(
                                onPressed: () => confirmAndRun(
                                  context,
                                  ref,
                                  title: const Tr('تمّت رؤيته', 'Mark as seen'),
                                  spec: Rpc.alertSetState,
                                  run: (r) => repo.setAlertState(a.id, AlertState.seen, reason: r),
                                ),
                                child: Text(context.tr(const Tr('تمّت رؤيته', 'Seen'))),
                              ),
                            if (a.state != AlertState.resolved)
                              TextButton(
                                onPressed: () => confirmAndRun(
                                  context,
                                  ref,
                                  title: const Tr('تمّ الحل', 'Mark as resolved'),
                                  spec: Rpc.alertSetState,
                                  run: (r) => repo.setAlertState(a.id, AlertState.resolved, reason: r),
                                ),
                                child: Text(context.tr(const Tr('تمّ الحل', 'Resolved'))),
                              )
                            else
                              Pill(context.tr(const Tr('محلول', 'Resolved')), tone: Tone.ok),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
