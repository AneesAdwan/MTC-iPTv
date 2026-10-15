// ADM-B1 القنوات (§9.4): جدول بترقيم من الخادم، بحث وفلاتر، إجراءات جماعية، وإضافة يدوية.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/admin/admin_repository.dart';
import '../../../data/admin/health_service.dart';
import '../widgets/admin_widgets.dart';

final adminChannelsProvider = FutureProvider.autoDispose.family<ChannelPage, ChannelQuery>((ref, q) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return const ChannelPage([], 0);
  return repo.channels(q);
});

/// الدول والفئات (من الخادم، تشمل غير الظاهرة).
final adminRefProvider = FutureProvider<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return (const <Map<String, dynamic>>[], const <Map<String, dynamic>>[]);
  return (await repo.countries(), await repo.categories());
});

class ChannelsAdminScreen extends ConsumerStatefulWidget {
  final String? initialState, initialCountry, initialCategory, initialSearch;
  final bool openAdd;
  const ChannelsAdminScreen({super.key, this.initialState, this.initialCountry, this.initialCategory, this.initialSearch, this.openAdd = false});
  @override
  ConsumerState<ChannelsAdminScreen> createState() => _ChannelsAdminScreenState();
}

class _ChannelsAdminScreenState extends ConsumerState<ChannelsAdminScreen> {
  late ChannelQuery q = ChannelQuery(state: widget.initialState, country: widget.initialCountry, category: widget.initialCategory, search: widget.initialSearch ?? '');
  final selected = <String>{};
  late final search = TextEditingController(text: widget.initialSearch ?? '');
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.openAdd) WidgetsBinding.instance.addPostFrameCallback((_) => _add());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _set(ChannelQuery n) => setState(() {
        q = n;
        selected.clear();
      });

  Future<void> _bulk(Future<void> Function(AdminRepository r, List<String> ids) f) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null || selected.isEmpty) return;
    final t = L10n.of(context);
    setState(() => busy = true);
    try {
      await f(repo, selected.toList());
      if (mounted) toast(context, t.saved);
      selected.clear();
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      ref.invalidate(adminChannelsProvider);
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> _pick(String title, List<(String, String)> items) => showDialog<String>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(title),
          children: [
            SizedBox(
              width: 360,
              height: 420,
              child: ListView(children: [for (final i in items) ListTile(title: Text(i.$2), onTap: () => Navigator.pop(c, i.$1))]),
            ),
          ],
        ),
      );

  Future<void> _add() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final id = await showDialog<String>(context: context, builder: (_) => _AddChannelDialog(repo: repo));
    if (id != null && mounted) context.go('/admin/channel/$id');
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final page = ref.watch(adminChannelsProvider(q));
    final refs = ref.watch(adminRefProvider).value;
    final countries = refs?.$1 ?? const [];
    final cats = refs?.$2 ?? const [];
    String nm(Map m) => '${lang == 'ar' ? m['name_ar'] : m['name_en']}';
    final data = page.value;
    final items = data?.items ?? const <AdminChannel>[];
    final from = q.page * ChannelQuery.pageSize;

    final toolbar = Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SizedBox(
        width: 280,
        child: TextField(
          controller: search,
          decoration: InputDecoration(hintText: t.searchAdminHint, prefixIcon: const Icon(Icons.search_rounded), isDense: true),
          onSubmitted: (v) => _set(q.copyWith(search: v)),
        ),
      ),
      DropdownButton<String?>(
        value: q.state,
        hint: Text(t.allStates),
        items: [DropdownMenuItem(value: null, child: Text(t.allStates)), for (final s in publishStates) DropdownMenuItem(value: s, child: Text(publishLabel(t, s)))],
        onChanged: (v) => _set(v == null ? q.copyWith(clearState: true) : q.copyWith(state: v)),
      ),
      DropdownButton<String?>(
        value: q.country,
        hint: Text(t.allCountries),
        items: [
          DropdownMenuItem(value: null, child: Text(t.allCountries)),
          for (final x in countries) DropdownMenuItem(value: x['code'] as String, child: Text('${x['flag_emoji'] ?? ''} ${nm(x)}')),
        ],
        onChanged: (v) => _set(v == null ? q.copyWith(clearCountry: true) : q.copyWith(country: v)),
      ),
      DropdownButton<String?>(
        value: q.category,
        hint: Text(t.allCategories),
        items: [DropdownMenuItem(value: null, child: Text(t.allCategories)), for (final x in cats) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x)))],
        onChanged: (v) => _set(v == null ? q.copyWith(clearCategory: true) : q.copyWith(category: v)),
      ),
      FilterChip(label: Text(t.fFeatured), selected: q.featured, onSelected: (v) => _set(q.copyWith(featured: v))),
      FilterChip(label: Text(t.fNoLogo), selected: q.noLogo, onSelected: (v) => _set(q.copyWith(noLogo: v))),
      FilterChip(label: Text(t.fManual), selected: q.manual, onSelected: (v) => _set(q.copyWith(manual: v))),
      FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded), label: Text(t.addChannel)),
    ]);

    final bulk = selected.isEmpty
        ? const SizedBox.shrink()
        : Container(
            color: c.accent.withValues(alpha: .10),
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(t.selected(selected.length), style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
              if (busy) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              OutlinedButton(onPressed: busy ? null : () => _bulk((r, ids) => r.updateChannels(ids, {'publish_state': 'published'})), child: Text(t.aPublish)),
              OutlinedButton(onPressed: busy ? null : () => _bulk((r, ids) => r.updateChannels(ids, {'publish_state': 'hidden', 'hidden_reason': 'manual'})), child: Text(t.aHide)),
              OutlinedButton(onPressed: busy ? null : () => _bulk((r, ids) => r.updateChannels(ids, {'is_featured': true})), child: Text(t.aFeature)),
              OutlinedButton(onPressed: busy ? null : () => _bulk((r, ids) => r.updateChannels(ids, {'is_featured': false})), child: Text(t.aUnfeature)),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final v = await _pick(t.aSetCategory, [for (final x in cats) (x['slug'] as String, nm(x))]);
                        if (v != null) await _bulk((r, ids) => r.updateChannels(ids, {'category_slug': v}));
                      },
                child: Text(t.aSetCategory),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final v = await _pick(t.aSetCountry, [for (final x in countries) (x['code'] as String, '${x['flag_emoji'] ?? ''} ${nm(x)}')]);
                        if (v != null) await _bulk((r, ids) => r.updateChannels(ids, {'country_code': v}));
                      },
                child: Text(t.aSetCountry),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => _bulk((r, ids) async {
                          final streams = [for (final id in ids) ...await r.streamsOf(id)];
                          ref.read(healthJobProvider.notifier).run(streams); // في الخلفية
                        }),
                icon: const Icon(Icons.monitor_heart_rounded, size: 18),
                label: Text(t.aCheckStreams),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(context, t.confirmDelete(selected.length))) await _bulk((r, ids) => r.deleteChannels(ids));
                      },
                child: Text(t.aDelete),
              ),
            ]),
          );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm), child: toolbar),
      bulk,
      if (page.isLoading) const LinearProgressIndicator(minHeight: 2),
      if (page.hasError) Padding(padding: const EdgeInsets.all(Space.lg), child: Text('${page.error}', style: const TextStyle(color: Color(0xFFEF4444)))),
      Expanded(
        child: ListView.separated(
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
          itemBuilder: (_, i) {
            if (i == 0) {
              final allSel = items.isNotEmpty && items.every((x) => selected.contains(x.id));
              return _Row(
                header: true,
                leading: Checkbox(
                  value: allSel,
                  onChanged: (v) => setState(() => v == true ? selected.addAll(items.map((x) => x.id)) : selected.removeAll(items.map((x) => x.id))),
                ),
                cells: [Text(t.colNumber), Text(t.colName), Text(t.colCountry), Text(t.colCategory), Text(t.colStreams), Text(t.colState), Text(t.colUpdated)],
              );
            }
            final ch = items[i - 1];
            return InkWell(
              onTap: () => context.go('/admin/channel/${ch.id}'),
              child: _Row(
                leading: Checkbox(value: selected.contains(ch.id), onChanged: (v) => setState(() => v == true ? selected.add(ch.id) : selected.remove(ch.id))),
                cells: [
                  Text(ch.number?.toString() ?? '—', style: TextStyle(color: c.textMuted)),
                  Row(children: [
                    SizedBox(
                      width: 36,
                      height: 28,
                      child: ch.logoUrl == null
                          ? Icon(Icons.image_not_supported_outlined, size: 18, color: c.textDim)
                          : Image.network(ch.logoUrl!, fit: BoxFit.contain, cacheWidth: 72, errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, size: 18, color: healthColor('unavailable'))),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(ch.displayName(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600))),
                          if (ch.isFeatured) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: Icon(Icons.star_rounded, size: 15, color: Color(0xFFEAB308))),
                          if (ch.isManual) Padding(padding: const EdgeInsetsDirectional.only(start: 4), child: Icon(Icons.edit_note_rounded, size: 15, color: c.textMuted)),
                        ]),
                        Text(ch.uid, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textDim, fontSize: 11)),
                      ]),
                    ),
                  ]),
                  Text(ch.countryCode ?? '—'),
                  Text(ch.categorySlug ?? '—'),
                  Pill('${ch.streamsOk}/${ch.streamStates.length}',
                      ch.streamStates.isEmpty ? healthColor('unavailable') : (ch.streamsOk == 0 ? healthColor('unavailable') : healthColor(ch.streamsOk == ch.streamStates.length ? 'playable' : 'degraded'))),
                  Align(alignment: AlignmentDirectional.centerStart, child: StatePill(ch.publishState)),
                  Text(ch.updatedAt == null ? '' : shortTime(ch.updatedAt!), style: TextStyle(color: c.textMuted, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
      Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
        child: Row(children: [
          Text(data == null || data.total == 0 ? '' : t.pageOf(from + 1, from + items.length, data.total), style: TextStyle(color: c.textMuted)),
          const Spacer(),
          IconButton(onPressed: q.page == 0 ? null : () => _set(q.copyWith(page: q.page - 1)), icon: const Icon(Icons.chevron_left_rounded)),
          IconButton(onPressed: data == null || from + items.length >= data.total ? null : () => _set(q.copyWith(page: q.page + 1)), icon: const Icon(Icons.chevron_right_rounded)),
        ]),
      ),
    ]);
  }
}

/// صف الجدول بعرض أعمدة ثابت (الاسم يتمدد).
class _Row extends StatelessWidget {
  final Widget leading;
  final List<Widget> cells;
  final bool header;
  const _Row({required this.leading, required this.cells, this.header = false});
  static const widths = [56.0, null, 70.0, 110.0, 80.0, 130.0, 140.0];
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DefaultTextStyle.merge(
      style: TextStyle(color: header ? c.textMuted : c.text, fontSize: 13, fontWeight: header ? FontWeight.w700 : FontWeight.w400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
        child: Row(children: [
          leading,
          for (var i = 0; i < cells.length; i++)
            widths[i] == null
                ? Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: cells[i]))
                : SizedBox(width: widths[i], child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: cells[i])),
        ]),
      ),
    );
  }
}

class _AddChannelDialog extends ConsumerStatefulWidget {
  final AdminRepository repo;
  const _AddChannelDialog({required this.repo});
  @override
  ConsumerState<_AddChannelDialog> createState() => _AddChannelDialogState();
}

class _AddChannelDialogState extends ConsumerState<_AddChannelDialog> {
  final ar = TextEditingController(), en = TextEditingController(), number = TextEditingController(), logo = TextEditingController(), url = TextEditingController();
  String? country, category, error;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    widget.repo.nextFreeNumber().then((n) => mounted && n != null && number.text.isEmpty ? setState(() => number.text = '$n') : null);
  }

  @override
  void dispose() {
    for (final x in [ar, en, number, logo, url]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (ar.text.trim().isEmpty && en.text.trim().isEmpty) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final id = await widget.repo.createChannel(
          nameAr: ar.text, nameEn: en.text, number: int.tryParse(number.text), country: country, category: category, logoUrl: logo.text);
      if (url.text.trim().isNotEmpty) await widget.repo.addStream(id, url: url.text);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      setState(() {
        saving = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final refs = ref.watch(adminRefProvider).value;
    String nm(Map m) => '${lang == 'ar' ? m['name_ar'] : m['name_en']}';
    return AlertDialog(
      title: Text(t.addChannel),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ar, autofocus: true, decoration: InputDecoration(labelText: t.fNameAr)),
            TextField(controller: en, decoration: InputDecoration(labelText: t.fNameEn)),
            TextField(controller: number, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: t.fNumber)),
            DropdownButtonFormField<String?>(
              initialValue: country,
              decoration: InputDecoration(labelText: t.colCountry),
              items: [for (final x in refs?.$1 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['code'] as String, child: Text('${x['flag_emoji'] ?? ''} ${nm(x)}'))],
              onChanged: (v) => country = v,
            ),
            DropdownButtonFormField<String?>(
              initialValue: category,
              decoration: InputDecoration(labelText: t.colCategory),
              items: [for (final x in refs?.$2 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x)))],
              onChanged: (v) => category = v,
            ),
            TextField(controller: logo, decoration: InputDecoration(labelText: t.fLogoUrl)),
            TextField(controller: url, decoration: InputDecoration(labelText: t.fUrl)),
            if (error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: saving ? null : _save, child: Text(t.save)),
      ],
    );
  }
}
