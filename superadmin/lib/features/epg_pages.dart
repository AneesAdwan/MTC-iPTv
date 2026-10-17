// Section 5 — Program guide: sources, channel mapping, day preview.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../ui/page_scaffold.dart';
import '../ui/selection.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

class EpgSourcesPage extends StatelessWidget {
  const EpgSourcesPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.epg.pages[0],
    source: (ref) => ref.read(epgRepoProvider).sources,
    header: Panel(
      child: Text(
        context.tr(
          const Tr(
            'الخادم بيزامن كل 6 ساعات. فشل الدليل ما بيوقف ولا بيأثر على القنوات أو التشغيل.',
            'The server syncs every 6 hours. A guide failure never stops or affects channels or playback.',
          ),
        ),
      ),
    ),
    columns: const [
      RowColumn('priority', Tr('الأولوية', 'Priority')),
      RowColumn('name', Tr('المصدر', 'Source'), flex: 3),
      RowColumn('lastOk', Tr('آخر مزامنة ناجحة', 'Last good sync'), flex: 2, tone: true),
      RowColumn('channels', Tr('قنوات', 'Channels')),
      RowColumn('programmes', Tr('برامج', 'Programmes')),
      RowColumn('errors', Tr('أخطاء', 'Errors')),
    ],
    actions: [
      Consumer(
        builder: (context, ref, _) => FilledButton.icon(
          onPressed: () => confirmAndRun(
            context,
            ref,
            title: const Tr('زامن الدليل الآن', 'Sync guide now'),
            spec: Rpc.epgSyncNow,
            run: (r) => ref.read(epgRepoProvider).syncNow(null, reason: r),
          ),
          icon: const Icon(Icons.sync, size: 18),
          label: Text(context.tr(const Tr('زامن الآن', 'Sync now'))),
        ),
      ),
    ],
  );
}

class EpgMappingPage extends StatelessWidget {
  const EpgMappingPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.epg.pages[1],
    source: (ref) => ref.read(epgRepoProvider).mapping,
    selectable: true,
    columns: const [
      RowColumn('channel', Tr('القناة', 'Channel'), flex: 3),
      RowColumn('suggestion', Tr('الاقتراح', 'Suggestion'), flex: 3),
      RowColumn('basis', Tr('على أساس', 'Based on'), flex: 2),
      RowColumn('confidence', Tr('الثقة', 'Confidence'), tone: true),
    ],
    bulkActions: (context, ref, sel, req) => [
      FilledButton(
        onPressed: () => confirmAndRun(
          context,
          ref,
          title: const Tr('اربط المحدد', 'Map selected'),
          spec: Rpc.epgMap,
          affected: sel.count,
          unit: const Tr('قناة', 'channels'),
          run: (r) => ref.read(epgRepoProvider).map(sel.snapshot(), reason: r),
        ),
        child: Text(context.tr(const Tr('اربط', 'Map'))),
      ),
    ],
  );
}

class EpgPreviewPage extends ConsumerWidget {
  const EpgPreviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sampleDataProvider);
    final id = GoRouterState.of(context).uri.queryParameters['channel'] ?? data.channels.first.id;
    final ch = data.channels.firstWhere((c) => c.id == id, orElse: () => data.channels.first);
    final c = context.colors;
    return ServicePage(
      page: Nav.epg.pages[2],
      scroll: true,
      child: Panel(
        title: Tr('${ch.number} · ${ch.nameAr} — اليوم', '${ch.number} · ${ch.nameEn} — today'),
        actions: [
          OutlinedButton(
            onPressed: () => confirmAndRun(
              context,
              ref,
              title: const Tr('ضبط الإزاحة +1 ساعة', 'Set offset +1 h'),
              spec: Rpc.epgMap,
              run: (r) => ref.read(epgRepoProvider).map(SelectionSnapshot.one(ch.id), reason: r, offsetMinutes: 60),
            ),
            child: Text(context.tr(const Tr('الإزاحة +1 س', 'Offset +1 h'))),
          ),
        ],
        child: AsyncView<List<GenericRow>>(
          load: () => ref.read(epgRepoProvider).programmes(ch.id, data.now),
          builder: (context, rows, _) => Column(
            children: [
              for (final r in rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm, horizontal: Space.sm),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                    color: r.tone == Tone.warn ? c.warn.withValues(alpha: 0.07) : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text('${r['start']} – ${r['end']}', textDirection: TextDirection.ltr)),
                      Expanded(child: Text(r['title'])),
                      if (r['note'] == 'gap') Pill(context.tr(const Tr('فجوة', 'Gap')), tone: Tone.warn),
                      if (r['note'] == 'overlap') Pill(context.tr(const Tr('تداخل', 'Overlap')), tone: Tone.warn),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
