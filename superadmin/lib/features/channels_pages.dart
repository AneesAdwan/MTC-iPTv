// Section 2 — Channels: list (+ side panel), add, channel page, bulk edit, trash, numbering, networks.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/prefs.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/paging.dart';
import '../data/providers.dart';
import '../data/repositories.dart';
import '../data/rpc/rpc_catalog.dart';
import '../data/sample/sample_data.dart';
import '../ui/data_table.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/preview_dialog.dart';
import '../ui/selection.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

final channelFilters = [
  FilterDef('state', const Tr('الحالة', 'State'), [for (final s in ChannelState.values.where((s) => s != ChannelState.trashed)) FilterOption(s.name, s.label)]),
  FilterDef('country', const Tr('الدولة', 'Country'), [for (final e in sampleCountries.entries) FilterOption(e.key, e.value)]),
  FilterDef('category', const Tr('الفئة', 'Category'), [for (final e in sampleCategories.entries) FilterOption(e.key, e.value)]),
  const FilterDef('missing', Tr('ناقص', 'Missing'), [
    FilterOption('logo', Tr('بلا شعار', 'No logo')),
    FilterOption('epg', Tr('بلا دليل', 'No EPG')),
    FilterOption('working', Tr('بلا رابط يعمل', 'No working stream')),
  ]),
];

const channelViews = [
  SavedView('منشورة بلا دليل · Published without EPG', {'state': 'published', 'missing': 'epg'}, builtIn: true),
  SavedView('منشورة بلا رابط يعمل · Published, nothing works', {'state': 'published', 'missing': 'working'}, builtIn: true),
  SavedView('مخفية · Hidden', {'state': 'hidden'}, builtIn: true),
];

List<TableColumn<Channel>> channelColumns(BuildContext context) {
  final c = context.colors;
  return [
    TableColumn(label: const Tr('الرقم', 'No.'), width: 70, sortKey: 'number', numeric: true, cell: (context, ch) => Text('${ch.number}')),
    TableColumn(
      label: const Tr('الشعار', 'Logo'),
      width: 56,
      cell: (context, ch) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: ch.hasLogo ? c.accent.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ch.hasLogo ? Colors.transparent : c.line2),
        ),
        child: Center(
          child: ch.hasLogo
              ? Text(
                  ch.nameEn.isEmpty ? '?' : ch.nameEn[0],
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                )
              : Icon(Icons.hide_image_outlined, size: 14, color: c.textDim),
        ),
      ),
    ),
    TableColumn(
      label: const Tr('الاسم', 'Name'),
      flex: 3,
      sortKey: 'name',
      cell: (context, ch) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ch.nameAr,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            ch.nameEn,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.textDim, fontSize: 11.5),
          ),
        ],
      ),
    ),
    TableColumn(
      label: const Tr('الدولة', 'Country'),
      width: 110,
      cell: (context, ch) => Text('${ch.country} · ${context.tr(sampleCountries[ch.country]!)}', overflow: TextOverflow.ellipsis),
    ),
    TableColumn(label: const Tr('الفئة', 'Category'), width: 100, cell: (context, ch) => Text(context.tr(sampleCategories[ch.category]!))),
    TableColumn(
      label: const Tr('الروابط', 'Streams'),
      width: 90,
      sortKey: 'links',
      cell: (context, ch) => Text(
        '${ch.workingLinks}/${ch.totalLinks}',
        style: TextStyle(color: ch.workingLinks == 0 ? c.bad : null, fontWeight: FontWeight.w600),
      ),
    ),
    TableColumn(
      label: const Tr('الحالة', 'State'),
      width: 120,
      cell: (context, ch) => Pill(context.tr(ch.state.label), tone: ch.state.tone),
    ),
    TableColumn(
      label: const Tr('آخر تعديل', 'Updated'),
      width: 150,
      sortKey: 'updated',
      cell: (context, ch) => Text(fmtDateTime(ch.updatedAt), style: TextStyle(color: c.textMuted)),
    ),
  ];
}

class ChannelsListPage extends ConsumerStatefulWidget {
  const ChannelsListPage({super.key});
  @override
  ConsumerState<ChannelsListPage> createState() => _ChannelsListPageState();
}

class _ChannelsListPageState extends ConsumerState<ChannelsListPage> {
  final _sel = SelectionModel();
  final _table = TableController();

  @override
  void dispose() {
    _sel.dispose();
    _table.dispose();
    super.dispose();
  }

  Future<void> _bulk(BulkAction action, PageRequest req, {String? value}) async {
    final repo = ref.read(channelsRepoProvider);
    final snap = _sel.snapshot();
    final preview = await repo.previewBulk(action, snap, req, value: value);
    if (!mounted) return;
    final r = await previewAndRun(context, ref, preview, (reason) => repo.applyBulk(action, snap, req, value: value, reason: reason));
    if (r != null && r.done > 0) {
      _sel.clear();
      _table.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = GoRouterState.of(context).uri.queryParameters;
    final openId = all['open'];
    final params = routeParams(context, ignore: const {'open', 'tab'});
    final req = requestFrom(params);
    final repo = ref.watch(channelsRepoProvider);
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterBar(
          pageId: 'channels.list',
          params: params,
          filters: channelFilters,
          builtInViews: channelViews,
          searchHint: const Tr('ابحث بالاسم أو الرقم…  ( / )', 'Search by name or number…  ( / )'),
          onChanged: (p) => setRouteParams(context, p),
        ),
        const SizedBox(height: Space.md),
        Expanded(
          child: MtcDataTable<Channel>(
            source: repo.channels,
            query: req.query,
            filters: req.filters,
            selection: _sel,
            controller: _table,
            columns: channelColumns(context),
            onOpen: (ch) => setRouteParams(context, params, keep: {'open': ch.id}),
            onDelete: (ch) {
              if (!_sel.isSelected(ch.id)) {
                _sel.clear();
                _sel.setSelected(ch.id, true);
              }
              _bulk(BulkAction.trash, req);
            },
            emptyMessage: const Tr('غيّر البحث أو الفلاتر.', 'Change the search or filters.'),
          ),
        ),
        SelectionBar(
          model: _sel,
          shownIds: () => _table.shownIds,
          actions: [
            FilledButton(
              key: const ValueKey('bulk-publish'),
              onPressed: () => _bulk(BulkAction.publish, req),
              child: Text(context.tr(const Tr('نشر', 'Publish'))),
            ),
            OutlinedButton(key: const ValueKey('bulk-hide'), onPressed: () => _bulk(BulkAction.hide, req), child: Text(context.tr(const Tr('إخفاء', 'Hide')))),
            PopupMenuButton<BulkAction>(
              key: const ValueKey('bulk-more'),
              tooltip: context.tr(const Tr('المزيد', 'More')),
              onSelected: (a) => _bulk(a, req),
              itemBuilder: (ctx) => [
                PopupMenuItem(value: BulkAction.feature, child: Text(ctx.tr(const Tr('تمييز', 'Feature')))),
                PopupMenuItem(value: BulkAction.setCountry, child: Text(ctx.tr(const Tr('تعيين الدولة…', 'Set country…')))),
                PopupMenuItem(value: BulkAction.setCategory, child: Text(ctx.tr(const Tr('تعيين الفئة…', 'Set category…')))),
                PopupMenuItem(value: BulkAction.setLanguage, child: Text(ctx.tr(const Tr('تعيين اللغة…', 'Set language…')))),
                PopupMenuItem(value: BulkAction.probe, child: Text(ctx.tr(const Tr('فحص الروابط', 'Probe streams')))),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: BulkAction.trash,
                  child: Text(ctx.tr(const Tr('نقل للسلة (Del)', 'Move to trash (Del)')), style: TextStyle(color: ctx.colors.bad)),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Text(context.tr(const Tr('المزيد', 'More'))), const Icon(Icons.arrow_drop_down)]),
              ),
            ),
          ],
        ),
      ],
    );
    return ServicePage(
      page: Nav.channels.pages[0],
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/channels/new'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr(const Tr('إضافة قناة', 'Add channel'))),
        ),
      ],
      child: openId == null
          ? list
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: list),
                const SizedBox(width: Space.md),
                SizedBox(
                  width: 480,
                  child: ChannelPanel(
                    key: ValueKey(openId),
                    channelId: openId,
                    tab: all['tab'],
                    onClose: () => setRouteParams(context, params),
                    onTab: (t) => setRouteParams(context, params, keep: {'open': openId, 'tab': t}),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Channel page content (tabs: info · streams · EPG · history). Used beside the list and full-page.
class ChannelPanel extends ConsumerWidget {
  final String channelId;
  final String? tab;
  final VoidCallback? onClose;
  final ValueChanged<String> onTab;
  const ChannelPanel({super.key, required this.channelId, required this.onTab, this.tab, this.onClose});

  static const tabs = ['info', 'streams', 'epg', 'history'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(channelsRepoProvider);
    final c = context.colors;
    final index = tabs.indexOf(tab ?? 'info').clamp(0, tabs.length - 1);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: AsyncView<Channel?>(
        load: () => repo.channel(channelId),
        builder: (context, ch, _) {
          if (ch == null) return const EmptyState(title: Tr('القناة مش موجودة', 'Channel not found'), icon: Icons.tv_off);
          return DefaultTabController(
            length: tabs.length,
            initialIndex: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.sm, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ch.number} · ${ch.name(context.lang)}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Pill(context.tr(ch.state.label), tone: ch.state.tone),
                          ],
                        ),
                      ),
                      if (onClose != null) ...[
                        IconButton(
                          tooltip: context.tr(const Tr('افتح بصفحة كاملة', 'Open full page')),
                          onPressed: () => context.go('/channels/${ch.id}'),
                          icon: const Icon(Icons.open_in_full, size: 18),
                        ),
                        IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
                      ],
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  onTap: (i) => onTab(tabs[i]),
                  tabs: [
                    Tab(text: context.tr(const Tr('المعلومات', 'Info'))),
                    Tab(text: context.tr(const Tr('الروابط', 'Streams'))),
                    Tab(text: context.tr(const Tr('الدليل', 'EPG'))),
                    Tab(text: context.tr(const Tr('السجل', 'History'))),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InfoTab(ch: ch),
                      _StreamsTab(ch: ch),
                      _EpgTab(ch: ch),
                      _HistoryTab(ch: ch),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoTab extends ConsumerStatefulWidget {
  final Channel ch;
  const _InfoTab({required this.ch});
  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  late final Map<String, TextEditingController> _f = {
    'name_ar': TextEditingController(text: widget.ch.nameAr),
    'name_en': TextEditingController(text: widget.ch.nameEn),
    'number': TextEditingController(text: '${widget.ch.number}'),
    'network': TextEditingController(text: widget.ch.network),
  };
  final Set<String> _locked = {'name_ar'};

  @override
  void dispose() {
    for (final c in _f.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _changes {
    final orig = {'name_ar': widget.ch.nameAr, 'name_en': widget.ch.nameEn, 'number': '${widget.ch.number}', 'network': widget.ch.network};
    return {
      for (final e in _f.entries)
        if (e.value.text != orig[e.key]) e.key: e.value.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    final labels = {
      'name_ar': const Tr('الاسم بالعربي', 'Arabic name'),
      'name_en': const Tr('الاسم بالإنجليزي', 'English name'),
      'number': const Tr('الرقم', 'Number'),
      'network': const Tr('الشبكة', 'Network'),
    };
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        for (final e in _f.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: TextField(
              controller: e.value,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr(labels[e.key]!),
                suffixIcon: IconButton(
                  tooltip: context.tr(const Tr('🔒 القفل: الاستيراد ما بيغيّر هالحقل أبدًا', '🔒 Lock: imports never change this field')),
                  icon: Icon(_locked.contains(e.key) ? Icons.lock : Icons.lock_open, size: 18),
                  onPressed: () => setState(() => _locked.contains(e.key) ? _locked.remove(e.key) : _locked.add(e.key)),
                ),
              ),
            ),
          ),
        Text(
          '${context.tr(const Tr('الدولة', 'Country'))}: ${widget.ch.country} · ${context.tr(const Tr('الفئة', 'Category'))}: ${context.tr(sampleCategories[widget.ch.category]!)}',
        ),
        const SizedBox(height: Space.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: const ValueKey('channel-save'),
            onPressed: _changes.isEmpty
                ? null
                : () => confirmAndRun(
                    context,
                    ref,
                    title: Tr('حفظ ${widget.ch.nameAr}', 'Save ${widget.ch.nameEn}'),
                    spec: Rpc.channelUpdate,
                    unit: const Tr('قناة', 'channel'),
                    groups: [
                      for (final e in _changes.entries) PreviewGroup(Tr(e.key, e.key), 1, examples: ['${e.value}']),
                    ],
                    run: (r) => ref.read(channelsRepoProvider).update(widget.ch.id, {..._changes, 'locked': _locked.toList()}, reason: r),
                  ),
            child: Text(context.tr(const Tr('حفظ', 'Save'))),
          ),
        ),
      ],
    );
  }
}

class _StreamsTab extends ConsumerWidget {
  final Channel ch;
  const _StreamsTab({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AsyncView<List<StreamLink>>(
      load: () => ref.read(channelsRepoProvider).streams(ch.id),
      builder: (context, links, _) => links.isEmpty
          ? const EmptyState(title: Tr('ما في روابط', 'No streams'))
          : ReorderableListView(
              padding: const EdgeInsets.all(Space.md),
              buildDefaultDragHandles: false,
              onReorderItem: (a, b) => confirmAndRun(
                context,
                ref,
                title: const Tr('ترتيب الروابط', 'Reorder streams'),
                spec: Rpc.streamsUpdate,
                run: (r) => ref.read(adminRpcProvider).call(Rpc.streamsUpdate, {
                  'p_channel_id': ch.id,
                  'p_move': [a, b],
                }, reason: r),
              ),
              children: [
                for (final (i, l) in links.indexed)
                  Container(
                    key: ValueKey(l.id),
                    margin: const EdgeInsets.only(bottom: Space.sm),
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator, size: 18)),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.maskedUrl, textDirection: TextDirection.ltr, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: Space.sm,
                                children: [
                                  Pill(context.tr(l.status.label), tone: l.status.tone),
                                  if (!l.enabled) Pill(context.tr(const Tr('معطّل يدويًا', 'Disabled')), tone: Tone.neutral),
                                  Text(l.sources.join(' · '), style: TextStyle(color: c.textDim, fontSize: 11.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) => confirmAndRun(
                            context,
                            ref,
                            title: Tr('رابط ${i + 1}: $v', 'Stream ${i + 1}: $v'),
                            spec: v == 'probe' ? Rpc.streamsProbe : Rpc.streamsUpdate,
                            run: (r) => ref.read(adminRpcProvider).call(v == 'probe' ? Rpc.streamsProbe : Rpc.streamsUpdate, {
                              'p_stream_id': l.id,
                              'p_op': v,
                            }, reason: r),
                          ),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'try', child: Text(ctx.tr(const Tr('جرّب (مشغّل مصغّر)', 'Try (mini player)')))),
                            PopupMenuItem(value: 'probe', child: Text(ctx.tr(const Tr('افحص', 'Probe')))),
                            PopupMenuItem(
                              value: l.enabled ? 'disable' : 'enable',
                              child: Text(ctx.tr(l.enabled ? const Tr('عطّل', 'Disable') : const Tr('فعّل', 'Enable'))),
                            ),
                            PopupMenuItem(value: 'headers', child: Text(ctx.tr(const Tr('ترويسات (UA / Referer)', 'Headers (UA / Referer)')))),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(ctx.tr(const Tr('حذف', 'Delete')), style: TextStyle(color: ctx.colors.bad)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EpgTab extends ConsumerWidget {
  final Channel ch;
  const _EpgTab({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(Space.lg),
    children: [
      FieldRow(
        label: const Tr('معرّف الدليل', 'EPG id'),
        field: Text(ch.epgId ?? '—', textDirection: TextDirection.ltr),
      ),
      FieldRow(label: const Tr('إزاحة الوقت', 'Time offset'), field: const Text('+0 h')),
      const SizedBox(height: Space.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: () => context.go('/epg/preview?channel=${ch.id}'),
          icon: const Icon(Icons.view_timeline_outlined, size: 18),
          label: Text(context.tr(const Tr('معاينة برامج اليوم', "Preview today's programmes"))),
        ),
      ),
    ],
  );
}

class _HistoryTab extends ConsumerWidget {
  final Channel ch;
  const _HistoryTab({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AsyncView<List<AuditEntry>>(
      load: () => ref.read(channelsRepoProvider).history(ch.id),
      builder: (context, entries, _) => ListView.separated(
        padding: const EdgeInsets.all(Space.md),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final a = entries[i];
          return ListTile(
            dense: true,
            title: Text('${a.field}: ${a.before} → ${a.after}'),
            subtitle: Text('${fmtDateTime(a.at)} · ${a.actor} · ${a.reason}', style: TextStyle(color: c.textDim)),
            trailing: TextButton(
              onPressed: () => confirmAndRun(
                context,
                ref,
                title: const Tr('رجّع هالقيمة', 'Restore this value'),
                spec: Rpc.auditRevert,
                run: (r) => ref.read(systemRepoProvider).revert(a.id, reason: r),
              ),
              child: Text(context.tr(const Tr('رجّع هالقيمة', 'Restore value'))),
            ),
          );
        },
      ),
    );
  }
}

class ChannelDetailPage extends StatelessWidget {
  final String channelId;
  const ChannelDetailPage({super.key, required this.channelId});
  @override
  Widget build(BuildContext context) {
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    return ServicePage(
      page: Nav.channelDetail,
      crumb: channelId,
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/channels'),
          icon: const Icon(Icons.list, size: 18),
          label: Text(context.tr(const Tr('للقائمة', 'Back to list'))),
        ),
      ],
      child: ChannelPanel(
        channelId: channelId,
        tab: tab,
        onTab: (t) => context.go(Uri(path: '/channels/$channelId', queryParameters: {'tab': t}).toString()),
      ),
    );
  }
}

class NewChannelPage extends ConsumerStatefulWidget {
  const NewChannelPage({super.key});
  @override
  ConsumerState<NewChannelPage> createState() => _NewChannelPageState();
}

class _NewChannelPageState extends ConsumerState<NewChannelPage> {
  final _form = GlobalKey<FormState>();
  final _ar = TextEditingController(),
      _en = TextEditingController(),
      _num = TextEditingController(),
      _url = TextEditingController(),
      _logo = TextEditingController();
  String? _country, _category;

  @override
  void initState() {
    super.initState();
    ref.read(channelsRepoProvider).suggestNumber().then((n) {
      if (mounted && _num.text.isEmpty) _num.text = '$n';
    });
  }

  @override
  void dispose() {
    for (final c in [_ar, _en, _num, _url, _logo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(bool forReview) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final fields = {
      'name_ar': _ar.text.trim(),
      'name_en': _en.text.trim(),
      'number': int.parse(_num.text),
      'country': _country,
      'category': _category,
      'logo_url': _logo.text.trim(),
      'stream_url': _url.text.trim(),
    };
    await confirmAndRun(
      context,
      ref,
      title: forReview ? const Tr('حفظ القناة للمراجعة', 'Save channel for review') : const Tr('إنشاء ونشر القناة', 'Create and publish the channel'),
      spec: Rpc.channelCreate,
      unit: const Tr('قناة', 'channel'),
      confirmLabel: const Tr('أنشئ', 'Create'),
      groups: [
        PreviewGroup(Tr(_ar.text, _en.text), 1, tone: forReview ? Tone.warn : Tone.ok, examples: ['#${_num.text}']),
      ],
      run: (r) => ref.read(channelsRepoProvider).create(fields, forReview: forReview, reason: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) => (v == null || v.trim().isEmpty) ? context.tr(const Tr('مطلوب', 'Required')) : null;
    return ServicePage(
      page: Nav.channels.pages[1],
      scroll: true,
      child: Panel(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldRow(
                label: const Tr('الاسم بالعربي', 'Arabic name'),
                field: TextFormField(key: const ValueKey('new-name-ar'), controller: _ar, validator: req),
              ),
              FieldRow(
                label: const Tr('الاسم بالإنجليزي', 'English name'),
                field: TextFormField(controller: _en, textDirection: TextDirection.ltr),
              ),
              FieldRow(
                label: const Tr('الرقم', 'Number'),
                help: const Tr('مقترح: أول رقم فاضي. الخادم بيتأكد إنه مش مستخدم.', 'Suggested: first free number. The server checks it is unused.'),
                field: TextFormField(
                  controller: _num,
                  validator: (v) => int.tryParse(v ?? '') == null ? context.tr(const Tr('رقم فقط', 'Numbers only')) : null,
                ),
              ),
              FieldRow(
                label: const Tr('الدولة', 'Country'),
                field: DropdownButtonFormField<String>(
                  initialValue: _country,
                  items: [for (final e in sampleCountries.entries) DropdownMenuItem(value: e.key, child: Text('${e.key} · ${context.tr(e.value)}'))],
                  onChanged: (v) => setState(() => _country = v),
                ),
              ),
              FieldRow(
                label: const Tr('الفئة', 'Category'),
                field: DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: [for (final e in sampleCategories.entries) DropdownMenuItem(value: e.key, child: Text(context.tr(e.value)))],
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
              FieldRow(
                label: const Tr('رابط الشعار', 'Logo URL'),
                field: TextFormField(controller: _logo, textDirection: TextDirection.ltr),
              ),
              FieldRow(
                label: const Tr('الرابط الأول', 'First stream URL'),
                field: TextFormField(
                  controller: _url,
                  textDirection: TextDirection.ltr,
                  validator: (v) => (Uri.tryParse(v?.trim() ?? '')?.hasScheme ?? false) ? null : context.tr(const Tr('رابط غير صالح', 'Invalid URL')),
                ),
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                children: [
                  FilledButton(
                    key: const ValueKey('new-publish'),
                    onPressed: () => _save(false),
                    child: Text(context.tr(const Tr('احفظ وانشر', 'Save and publish'))),
                  ),
                  OutlinedButton(onPressed: () => _save(true), child: Text(context.tr(const Tr('احفظ للمراجعة', 'Save for review')))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});
  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  final _sel = SelectionModel();
  final _table = TableController();
  @override
  void dispose() {
    _sel.dispose();
    _table.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(channelsRepoProvider);
    final params = routeParams(context);
    final req = requestFrom(params);
    final c = context.colors;
    return ServicePage(
      page: Nav.channels.pages[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(pageId: 'channels.trash', params: params, onChanged: (p) => setRouteParams(context, p)),
          const SizedBox(height: Space.md),
          Expanded(
            child: MtcDataTable<Channel>(
              source: repo.trash,
              query: req.query,
              selection: _sel,
              controller: _table,
              emptyTitle: const Tr('السلة فاضية', 'Trash is empty'),
              columns: [
                ...channelColumns(context).take(3),
                TableColumn(
                  label: const Tr('بينحذف نهائيًا', 'Purged on'),
                  width: 150,
                  cell: (context, ch) =>
                      Text(ch.trashedAt == null ? '—' : fmtDateTime(ch.trashedAt!.add(const Duration(days: 30))), style: TextStyle(color: c.warn)),
                ),
              ],
            ),
          ),
          SelectionBar(
            model: _sel,
            shownIds: () => _table.shownIds,
            actions: [
              FilledButton(
                onPressed: () => confirmAndRun(
                  context,
                  ref,
                  title: const Tr('استرجاع من السلة', 'Restore from trash'),
                  spec: Rpc.channelsRestore,
                  affected: _sel.count,
                  unit: const Tr('قناة', 'channels'),
                  run: (r) => repo.restore(_sel.snapshot(), reason: r),
                ),
                child: Text(context.tr(const Tr('استرجاع', 'Restore'))),
              ),
              const SizedBox(width: Space.xl),
              // Permanent delete stands alone, away from the normal buttons (plan §8).
              OutlinedButton(
                key: const ValueKey('trash-purge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.bad,
                  side: BorderSide(color: c.bad),
                ),
                onPressed: () => confirmAndRun(
                  context,
                  ref,
                  title: const Tr('حذف نهائي', 'Delete permanently'),
                  spec: Rpc.channelsPurge,
                  affected: _sel.count,
                  unit: const Tr('قناة', 'channels'),
                  confirmLabel: const Tr('احذف نهائيًا', 'Delete permanently'),
                  run: (r) => repo.purge(_sel.snapshot(), reason: r),
                ),
                child: Text(context.tr(const Tr('حذف نهائي…', 'Delete permanently…'))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NumberingPage extends ConsumerStatefulWidget {
  const NumberingPage({super.key});
  @override
  ConsumerState<NumberingPage> createState() => _NumberingPageState();
}

class _NumberingPageState extends ConsumerState<NumberingPage> {
  final _order = <String>['country', 'category', 'name'];
  int _start = 1;
  bool _arabFirst = true;

  List<(Channel, int)> _plan(List<Channel> all) {
    final list = all.where((c) => c.state == ChannelState.published).toList();
    const arab = {'PS', 'JO', 'SA', 'QA', 'AE', 'EG', 'LB', 'IQ', 'KW', 'MA'};
    int cmp(Channel a, Channel b) {
      if (_arabFirst) {
        final x = arab.contains(a.country) ? 0 : 1, y = arab.contains(b.country) ? 0 : 1;
        if (x != y) return x - y;
      }
      for (final k in _order) {
        final r = switch (k) {
          'country' => a.country.compareTo(b.country),
          'category' => a.category.compareTo(b.category),
          _ => a.nameAr.compareTo(b.nameAr),
        };
        if (r != 0) return r;
      }
      return 0;
    }

    list.sort(cmp);
    return [for (final (i, c) in list.indexed) (c, _start + i)];
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(sampleDataProvider);
    final plan = _plan(data.channels);
    final changed = plan.where((p) => p.$1.number != p.$2).toList();
    final c = context.colors;
    final labels = {'country': const Tr('الدولة', 'Country'), 'category': const Tr('الفئة', 'Category'), 'name': const Tr('الاسم', 'Name')};
    return ServicePage(
      page: Nav.channels.pages[3],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: Panel(
              title: const Tr('الخطة', 'Plan'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _arabFirst,
                    onChanged: (v) => setState(() => _arabFirst = v),
                    title: Text(context.tr(const Tr('الدول العربية أول', 'Arab countries first'))),
                  ),
                  Text(context.tr(const Tr('ترتيب التجميع (اسحب):', 'Grouping order (drag):')), style: TextStyle(color: c.textMuted)),
                  SizedBox(
                    height: 150,
                    child: ReorderableListView(
                      onReorderItem: (a, b) => setState(() {
                        final x = _order.removeAt(a);
                        _order.insert(b, x);
                      }),
                      children: [for (final k in _order) ListTile(key: ValueKey(k), dense: true, title: Text(context.tr(labels[k]!)))],
                    ),
                  ),
                  TextFormField(
                    initialValue: '$_start',
                    decoration: InputDecoration(labelText: context.tr(const Tr('نقطة البداية', 'Start at'))),
                    onChanged: (v) => setState(() => _start = int.tryParse(v) ?? 1),
                  ),
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: changed.isEmpty
                        ? null
                        : () => confirmAndRun(
                            context,
                            ref,
                            title: const Tr('طبّق الترقيم', 'Apply numbering'),
                            spec: Rpc.channelsRenumber,
                            affected: changed.length,
                            unit: const Tr('قناة', 'channels'),
                            confirmLabel: const Tr('طبّق', 'Apply'),
                            run: (r) => ref.read(channelsRepoProvider).renumber({'order': _order, 'start': _start, 'arab_first': _arabFirst}, reason: r),
                          ),
                    child: Text(context.tr(Tr('طبّق (${fmtInt(changed.length)} تغيير)', 'Apply (${fmtInt(changed.length)} changes)'))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Panel(
              title: const Tr('المعاينة: القديم ← الجديد', 'Preview: old → new'),
              child: SizedBox(
                height: 520,
                child: ListView.builder(
                  itemCount: plan.length.clamp(0, 300),
                  itemExtent: 34,
                  itemBuilder: (context, i) {
                    final (ch, n) = plan[i];
                    return Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text('${ch.number}', style: TextStyle(color: c.textDim)),
                        ),
                        Icon(context.isRtl ? Icons.arrow_back : Icons.arrow_forward, size: 14, color: c.textDim),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '$n',
                            style: TextStyle(fontWeight: FontWeight.w700, color: n == ch.number ? null : c.accent),
                          ),
                        ),
                        Expanded(child: Text('${ch.nameAr} · ${ch.country} · ${context.tr(sampleCategories[ch.category]!)}', overflow: TextOverflow.ellipsis)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworksPage extends ConsumerWidget {
  const NetworksPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sampleDataProvider);
    final counts = <String, int>{};
    for (final c in data.channels) {
      counts[c.network] = (counts[c.network] ?? 0) + 1;
    }
    final rows = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ServicePage(
      page: Nav.channels.pages[4],
      scroll: true,
      child: Panel(
        child: Column(
          children: [
            for (final e in rows)
              ListTile(
                dense: true,
                leading: const Icon(Icons.hub_outlined),
                title: Text(e.key),
                subtitle: Text(context.tr(Tr('${fmtInt(e.value)} قناة', '${fmtInt(e.value)} channels'))),
                trailing: Wrap(
                  spacing: Space.sm,
                  children: [
                    TextButton(
                      onPressed: () => context.go(Uri(path: '/channels', queryParameters: {'q': e.key}).toString()),
                      child: Text(context.tr(const Tr('فتح القنوات', 'Open channels'))),
                    ),
                    TextButton(
                      onPressed: () async {
                        final to = await _ask(context, e.key);
                        if (to == null || to.isEmpty || to == e.key || !context.mounted) return;
                        await confirmAndRun(
                          context,
                          ref,
                          title: Tr('إعادة تسمية «${e.key}» ← «$to»', 'Rename "${e.key}" → "$to"'),
                          spec: Rpc.networkRename,
                          affected: e.value,
                          unit: const Tr('قناة', 'channels'),
                          run: (r) => ref.read(channelsRepoProvider).renameNetwork(e.key, to, reason: r),
                        );
                      },
                      child: Text(context.tr(const Tr('إعادة تسمية', 'Rename'))),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _ask(BuildContext context, String current) {
    final ctl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(const Tr('الاسم الموحّد', 'Unified name'))),
        content: TextField(controller: ctl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr(const Tr('إلغاء', 'Cancel')))),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: Text(ctx.tr(const Tr('متابعة', 'Continue')))),
        ],
      ),
    ).whenComplete(ctl.dispose);
  }
}
