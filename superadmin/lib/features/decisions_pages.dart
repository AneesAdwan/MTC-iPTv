// Section 3 — Decision center: one inbox for everything that needs a decision, plus compare.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/errors.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/paging.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../data/sample/sample_data.dart';
import '../shell/app_shell.dart';
import '../ui/decision_card.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/preview_dialog.dart';
import '../ui/selection.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

/// Decisions available per type (plan §6 section 3 table).
const decisionActions = <String, List<(String, Tr)>>{
  'review': [
    ('publish', Tr('نشر', 'Publish')),
    ('edit_publish', Tr('عدّل وانشر', 'Edit & publish')),
    ('merge', Tr('ادمج بقناة موجودة', 'Merge into existing')),
    ('reject', Tr('رفض (سلة)', 'Reject (trash)')),
  ],
  'incomplete': [('assign', Tr('عيّن', 'Assign')), ('publish', Tr('انشر', 'Publish'))],
  'duplicates': [
    ('keep', Tr('إبقاء', 'Keep')),
    ('keep_publish', Tr('إبقاء ونشر', 'Keep & publish')),
    ('hide', Tr('إخفاء', 'Hide')),
    ('merge_links', Tr('ادمج روابطها', 'Merge streams')),
    ('trash', Tr('سلة', 'Trash')),
    ('not_duplicate', Tr('ليست مكررة', 'Not a duplicate')),
  ],
  'broken': [
    ('try', Tr('جرّب', 'Try')),
    ('reprobe', Tr('أعد الفحص', 'Re-probe')),
    ('alt_server', Tr('سيرفر بديل', 'Alternative server')),
    ('disable_link', Tr('عطّل الرابط', 'Disable stream')),
    ('hide', Tr('أخفِ القناة', 'Hide channel')),
  ],
  'logos': [
    ('edit_logo', Tr('عدّل الشعار', 'Edit logo')),
    ('suggest_logo', Tr('اقتراح من iptv-org', 'Suggest from iptv-org')),
    ('no_logo', Tr('بلا شعار', 'No logo')),
  ],
  'reports': [('try', Tr('جرّب', 'Try')), ('probe', Tr('افحص', 'Probe')), ('resolved', Tr('تمّ الحل', 'Resolved')), ('hide', Tr('أخفِ', 'Hide'))],
  'conflicts': [
    ('accept', Tr('اقبل التغيير', 'Accept change')),
    ('keep_mine', Tr('خلّي قيمتي', 'Keep my value')),
    ('lock_forever', Tr('اقفل نهائيًا', 'Lock permanently')),
  ],
  'enrichment': [
    ('accept', Tr('اقبل', 'Accept')),
    ('accept_all_type', Tr('اقبل الكل لهالنوع', 'Accept all of this kind')),
    ('edit', Tr('عدّل', 'Edit')),
    ('reject', Tr('ارفض', 'Reject')),
  ],
  'unmatched': [('link', Tr('اربطه بالقناة', 'Link to channel')), ('new', Tr('قناة جديدة', 'New channel')), ('reject', Tr('ارفض', 'Reject'))],
  'sources': [
    ('open_log', Tr('افتح السجل', 'Open log')),
    ('retry', Tr('أعد المحاولة', 'Retry')),
    ('rollback', Tr('ارجع لآخر نسخة سليمة', 'Roll back to last good')),
    ('pause', Tr('أوقف المصدر', 'Pause source')),
  ],
};

const _dangerDecisions = {'reject', 'trash', 'hide', 'pause', 'disable_link'};

class DecisionsPage extends ConsumerStatefulWidget {
  const DecisionsPage({super.key});
  @override
  ConsumerState<DecisionsPage> createState() => _DecisionsPageState();
}

class _DecisionsPageState extends ConsumerState<DecisionsPage> {
  final _sel = SelectionModel();
  PageRequest? _req;
  PageResult<DecisionItem>? _page;
  UiError? _error;

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  Future<void> _load(PageRequest req) async {
    _req = req;
    setState(() => _error = null);
    try {
      final p = await ref.read(decisionsRepoProvider).items.fetch(req);
      if (!mounted || _req != req) return;
      setState(() => _page = p);
      _sel.setTotal(p.total);
    } catch (e, st) {
      if (mounted) setState(() => _error = describeError(e, st));
    }
  }

  Future<void> _decide(String decision, Tr label, SelectionSnapshot snap, PageRequest req) async {
    final type = DecisionType.byId(req.filters['type']);
    await previewAndRun(
      context,
      ref,
      OperationPreview(
        title: Tr('قرار: ${label.ar}', 'Decision: ${label.en}'),
        confirmLabel: const Tr('نفّذ', 'Run'),
        affected: snap.count,
        unit: const Tr('بند', 'items'),
        undoClass: Rpc.decisionsApply.undoClass,
        groups: [PreviewGroup(type?.title ?? const Tr('كل الأنواع', 'All types'), snap.count, tone: Tone.info)],
      ),
      (r) => ref.read(decisionsRepoProvider).apply(decision, snap, req, reason: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = routeParams(context);
    final req = requestFrom(params).copyWith(limit: 20, offset: _req != null && requestFrom(params).sameFilter(_req!) ? _req!.offset : 0);
    if (_req == null || !_req!.sameFilter(req)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sel.clear(); // a selection belongs to one filter
        _load(req);
      });
      _req = req;
      _page = null;
    }
    final type = DecisionType.byId(params['type']);
    final counts = ref.watch(decisionCountsProvider).value ?? const {};
    final c = context.colors;
    final actions = type == null ? const <(String, Tr)>[] : decisionActions[type.id]!;

    Widget list;
    if (_error != null) {
      list = ErrorState(error: _error!, onRetry: () => _load(req));
    } else if (_page == null) {
      list = const LoadingState();
    } else if (_page!.items.isEmpty) {
      list = const EmptyState(title: Tr('ما في شي بدو قرار هون', 'Nothing needs a decision here'), icon: Icons.task_alt);
    } else {
      list = ListenableBuilder(
        listenable: _sel,
        builder: (context, _) => ListView.separated(
          itemCount: _page!.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (context, i) {
            final d = _page!.items[i];
            final t = DecisionType.byId(d.type);
            return DecisionCard(
              key: ValueKey(d.id),
              title: d.title,
              typeLabel: t?.title ?? Tr(d.type, d.type),
              why: d.why,
              evidence: d.evidence,
              confidence: d.confidence,
              confidenceReasons: d.confidenceReasons,
              selected: _sel.isSelected(d.id),
              onSelectChanged: (v) => _sel.setSelected(d.id, v),
              actions: [
                for (final (id, label) in decisionActions[d.type] ?? const <(String, Tr)>[])
                  DecisionAction(
                    label,
                    () => _decide(id, label, SelectionSnapshot.one(d.id), req),
                    primary: id == (decisionActions[d.type]!.first.$1),
                    danger: _dangerDecisions.contains(id),
                  ),
              ],
            );
          },
        ),
      );
    }

    final total = _page?.total ?? 0;
    return ServicePage(
      page: Nav.decisions.pages[0],
      help: ['3.0', ?type?.help],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TypeChip(
                  label: const Tr('الكل', 'All'),
                  count: counts.values.fold(0, (a, b) => a + b),
                  selected: type == null,
                  onTap: () => setRouteParams(context, {...params}..remove('type')),
                ),
                for (final t in DecisionType.all)
                  _TypeChip(
                    key: ValueKey('type-${t.id}'),
                    label: t.title,
                    icon: t.icon,
                    count: counts[t.id] ?? 0,
                    selected: type?.id == t.id,
                    onTap: () => setRouteParams(context, {...params, 'type': t.id}),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          FilterBar(
            pageId: 'decisions.inbox',
            params: {...params}..remove('type'),
            filters: [
              FilterDef('country', const Tr('الدولة', 'Country'), [for (final e in sampleCountries.entries) FilterOption(e.key, e.value)]),
              FilterDef('category', const Tr('الفئة', 'Category'), [for (final e in sampleCategories.entries) FilterOption(e.key, e.value)]),
            ],
            onChanged: (p) => setRouteParams(context, {...p, 'type': ?type?.id}),
          ),
          const SizedBox(height: Space.md),
          Expanded(child: list),
          Row(
            children: [
              const Spacer(),
              Text(
                context.tr(
                  Tr(
                    '${fmtInt(total == 0 ? 0 : req.offset + 1)}–${fmtInt(req.offset + (_page?.items.length ?? 0))} من ${fmtInt(total)}',
                    '${fmtInt(total == 0 ? 0 : req.offset + 1)}–${fmtInt(req.offset + (_page?.items.length ?? 0))} of ${fmtInt(total)}',
                  ),
                ),
                style: TextStyle(color: c.textMuted),
              ),
              IconButton(
                onPressed: req.offset > 0 ? () => _load(req.copyWith(offset: req.offset - req.limit)) : null,
                icon: Icon(context.isRtl ? Icons.chevron_right : Icons.chevron_left),
              ),
              IconButton(
                onPressed: req.offset + req.limit < total ? () => _load(req.copyWith(offset: req.offset + req.limit)) : null,
                icon: Icon(context.isRtl ? Icons.chevron_left : Icons.chevron_right),
              ),
            ],
          ),
          SelectionBar(
            model: _sel,
            shownIds: () => [for (final d in _page?.items ?? <DecisionItem>[]) d.id],
            actions: type == null
                ? [Text(context.tr(const Tr('اختار نوع لتطبيق قرار جماعي', 'Pick a type to apply a bulk decision')), style: TextStyle(color: c.textMuted))]
                : [
                    for (final (id, label) in actions.where((a) => a.$1 != 'try' && a.$1 != 'open_log' && a.$1 != 'edit'))
                      OutlinedButton(onPressed: () => _decide(id, label, _sel.snapshot(), req), child: Text(context.tr(label))),
                  ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final Tr label;
  final IconData? icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({super.key, required this.label, required this.count, required this.selected, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: Space.sm),
    child: ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text('${context.tr(label)}  ${fmtInt(count)}'),
    ),
  );
}

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});
  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  final List<Channel> _picked = [];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(sampleDataProvider);
    final c = context.colors;
    final fields = <(Tr, String Function(Channel))>[
      (const Tr('الرقم', 'Number'), (x) => '${x.number}'),
      (const Tr('الاسم بالعربي', 'Arabic name'), (x) => x.nameAr),
      (const Tr('الاسم بالإنجليزي', 'English name'), (x) => x.nameEn),
      (const Tr('الدولة', 'Country'), (x) => x.country),
      (const Tr('الفئة', 'Category'), (x) => x.category),
      (const Tr('الشبكة', 'Network'), (x) => x.network),
      (const Tr('الروابط', 'Streams'), (x) => '${x.workingLinks}/${x.totalLinks}'),
      (const Tr('الحالة', 'State'), (x) => context.tr(x.state.label)),
      (const Tr('الدليل', 'EPG'), (x) => x.epgId ?? '—'),
    ];
    return ServicePage(
      page: Nav.decisions.pages[1],
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            title: const Tr('اختار 2–4 قنوات', 'Pick 2–4 channels'),
            child: Autocomplete<Channel>(
              displayStringForOption: (x) => '${x.number} · ${x.nameAr} · ${x.nameEn}',
              optionsBuilder: (v) {
                final q = v.text.trim().toLowerCase();
                if (q.isEmpty) return const [];
                return data.channels.where((x) => x.nameAr.contains(q) || x.nameEn.toLowerCase().contains(q) || '${x.number}' == q).take(12);
              },
              onSelected: (x) => setState(() {
                if (_picked.length < 4 && !_picked.contains(x)) _picked.add(x);
              }),
            ),
          ),
          const SizedBox(height: Space.lg),
          if (_picked.length < 2)
            const EmptyState(title: Tr('اختار قناتين على الأقل للمقارنة', 'Pick at least two channels to compare'), icon: Icons.compare_arrows)
          else
            Panel(
              child: Table(
                border: TableBorder.all(color: c.line),
                columnWidths: const {0: FixedColumnWidth(160)},
                children: [
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      for (final x in _picked)
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(x.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _picked.remove(x))),
                            ],
                          ),
                        ),
                    ],
                  ),
                  for (final (label, get) in fields)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: Text(context.tr(label), style: TextStyle(color: c.textMuted)),
                        ),
                        for (final x in _picked)
                          Container(
                            color: _picked.map(get).toSet().length > 1 ? c.warn.withValues(alpha: 0.08) : null,
                            padding: const EdgeInsets.all(Space.sm),
                            child: Text(get(x)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          if (_picked.length >= 2) ...[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              children: [
                FilledButton(
                  onPressed: () => confirmAndRun(
                    context,
                    ref,
                    title: Tr('دمج في «${_picked.first.nameAr}»', 'Merge into "${_picked.first.nameEn}"'),
                    spec: Rpc.channelsMerge,
                    affected: _picked.length - 1,
                    unit: const Tr('قناة', 'channels'),
                    groups: [
                      PreviewGroup(
                        const Tr('روابطها بتنتقل والقناة بتنخفى', 'Streams move, channel is hidden'),
                        _picked.length - 1,
                        examples: [for (final x in _picked.skip(1)) x.nameAr],
                      ),
                    ],
                    run: (r) => ref.read(adminRpcProvider).call(Rpc.channelsMerge, {
                      'p_keep': _picked.first.id,
                      'p_merge': [for (final x in _picked.skip(1)) x.id],
                    }, reason: r),
                  ),
                  child: Text(context.tr(const Tr('ادمج بالأولى', 'Merge into the first'))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
