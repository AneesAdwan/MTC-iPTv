// ADM-B4 العرض في الرئيسية (§9.4): «يعرض الآن» (قناة أو أكثر تتناوب)، والصفوف: إضافة وحذف وترتيب بالسحب،
// لكل صف نوع وعنوان بلغتين وعدد، وقوائم مختارة بتاريخ بداية ونهاية. يُحفظ في site_settings.home_layout.
// (المعاينة الحيّة لكل منصّة واستهداف المنصّات: لاحقًا مع R2.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/catalog/home_layout.dart';
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

String rowTypeLabel(L10n t, String type) => switch (type) {
      'featured' => t.rtFeatured,
      'history' => t.rtHistory,
      'favorites' => t.rtFavorites,
      'recent' => t.rtRecent,
      'categories_auto' => t.rtCategoriesAuto,
      'category' => t.rtCategory,
      'country' => t.rtCountry,
      'manual' => t.rtManual,
      _ => t.rtAll,
    };

/// اختيار قناة منشورة بالبحث.
Future<AdminChannel?> pickChannel(BuildContext context, AdminRepository repo) => showDialog<AdminChannel>(context: context, builder: (_) => _ChannelPicker(repo: repo));

class _ChannelPicker extends StatefulWidget {
  final AdminRepository repo;
  const _ChannelPicker({required this.repo});
  @override
  State<_ChannelPicker> createState() => _ChannelPickerState();
}

class _ChannelPickerState extends State<_ChannelPicker> {
  List<AdminChannel> results = const [];
  Future<void> _search(String q) async {
    final r = await widget.repo.channels(ChannelQuery(search: q, state: 'published'));
    if (mounted) setState(() => results = r.items);
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return AlertDialog(
      title: Text(t.pickChannel),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(children: [
          TextField(autofocus: true, decoration: InputDecoration(hintText: t.searchAdminHint, prefixIcon: const Icon(Icons.search_rounded)), onChanged: _search),
          Expanded(
            child: ListView(children: [
              for (final ch in results)
                ListTile(
                  leading: SizedBox(width: 40, height: 28, child: ch.logoUrl == null ? null : Image.network(ch.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
                  title: Text('${ch.number ?? '—'} · ${ch.displayName(lang)}'),
                  onTap: () => Navigator.pop(context, ch),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class HomeLayoutScreen extends ConsumerStatefulWidget {
  const HomeLayoutScreen({super.key});
  @override
  ConsumerState<HomeLayoutScreen> createState() => _HomeLayoutScreenState();
}

class _HomeLayoutScreenState extends ConsumerState<HomeLayoutScreen> {
  HomeLayout? layout;
  Map<String, String> names = {}; // id ← اسم للعرض
  bool saving = false, dirty = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    try {
      final j = await repo.homeLayout();
      final l = j == null ? HomeLayout.fallback : HomeLayout.fromJson(j);
      final ids = {...l.hero, for (final r in l.rows) ...r.channelIds}.toList();
      final n = await repo.channelNames(ids);
      setState(() {
        layout = l.rows.isEmpty && l.hero.isEmpty ? HomeLayout.fallback : l;
        names = {...n}; // نسخة قابلة للتعديل: channelNames تعيد const {} حين لا قنوات (فيفشل _addChannel)
      });
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  void _update(HomeLayout l) => setState(() {
        layout = l;
        dirty = true;
      });

  void _updateRow(int i, HomeRow r) {
    final rows = [...layout!.rows]..[i] = r;
    _update(HomeLayout(hero: layout!.hero, rows: rows));
  }

  Future<String?> _addChannel() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return null;
    final ch = await pickChannel(context, repo);
    if (ch == null) return null;
    names[ch.id] = '${ch.number ?? '—'} · ${ch.nameAr ?? ch.name}';
    return ch.id;
  }

  Future<void> _save() async {
    final repo = ref.read(adminRepoProvider);
    final l = layout;
    if (repo == null || l == null) return;
    final t = L10n.of(context);
    setState(() => saving = true);
    try {
      await repo.saveHomeLayout(l.toJson());
      if (mounted) toast(context, t.saved);
      setState(() => dirty = false);
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final l = layout;
    if (l == null) return Center(child: error == null ? const CircularProgressIndicator() : Text(error!));
    final refs = ref.watch(adminRefProvider).value;
    String nm(Map m) => '${lang == 'ar' ? m['name_ar'] : m['name_en']}';

    Widget chip(String id, VoidCallback onDelete) => InputChip(label: Text(names[id] ?? id), onDeleted: onDelete);

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Row(children: [
        Expanded(child: Text(t.hlPublishHint, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
        TextButton(onPressed: () => _update(HomeLayout.fallback), child: Text(t.hlReset)),
        const SizedBox(width: Space.sm),
        FilledButton.icon(
          onPressed: saving || !dirty ? null : _save,
          icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
          label: Text(t.save),
        ),
      ]),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.hlHero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.hlHeroHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
          const SizedBox(height: Space.sm),
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            for (final id in l.hero) chip(id, () => _update(HomeLayout(hero: [...l.hero]..remove(id), rows: l.rows))),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16),
              label: Text(t.addChannels),
              onPressed: () async {
                final id = await _addChannel();
                if (id != null && !l.hero.contains(id)) _update(HomeLayout(hero: [...l.hero, id], rows: l.rows));
              },
            ),
          ]),
        ]),
      ),
      const SizedBox(height: Space.lg),
      SectionCard(
        title: t.hlRows,
        trailing: PopupMenuButton<String>(
          tooltip: t.hlAddRow,
          icon: const Icon(Icons.add_rounded),
          onSelected: (type) => _update(HomeLayout(hero: l.hero, rows: [...l.rows, HomeRow(type: type)])),
          itemBuilder: (_) => [for (final x in homeRowTypes) PopupMenuItem(value: x, child: Text(rowTypeLabel(t, x)))],
        ),
        child: ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            final rows = [...l.rows];
            rows.insert(to, rows.removeAt(from));
            _update(HomeLayout(hero: l.hero, rows: rows));
          },
          children: [
            for (var i = 0; i < l.rows.length; i++)
              Card(
                key: ValueKey('row$i-${l.rows[i].type}'),
                margin: const EdgeInsets.only(bottom: Space.sm),
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator_rounded)),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(rowTypeLabel(t, l.rows[i].type), style: TextStyle(color: c.text, fontWeight: FontWeight.w700))),
                      Switch(value: l.rows[i].visible, onChanged: (v) => _updateRow(i, l.rows[i].copyWith(visible: v))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _update(HomeLayout(hero: l.hero, rows: [...l.rows]..removeAt(i))),
                      ),
                    ]),
                    Wrap(spacing: Space.md, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          initialValue: l.rows[i].titleAr,
                          decoration: InputDecoration(labelText: t.fTitleAr, isDense: true),
                          onChanged: (v) => _updateRow(i, HomeRow.fromJson({...l.rows[i].toJson(), 'title_ar': v.trim().isEmpty ? null : v.trim()})),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          initialValue: l.rows[i].titleEn,
                          decoration: InputDecoration(labelText: t.fTitleEn, isDense: true),
                          onChanged: (v) => _updateRow(i, HomeRow.fromJson({...layout!.rows[i].toJson(), 'title_en': v.trim().isEmpty ? null : v.trim()})),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: '${l.rows[i].count}',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(labelText: t.fCount, isDense: true),
                          onChanged: (v) => _updateRow(i, layout!.rows[i].copyWith(count: (int.tryParse(v) ?? 20).clamp(1, 100))),
                        ),
                      ),
                      if (l.rows[i].type == 'category')
                        DropdownButton<String>(
                          value: l.rows[i].ref,
                          hint: Text(t.colCategory),
                          items: [for (final x in refs?.$2 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x)))],
                          onChanged: (v) => _updateRow(i, l.rows[i].copyWith(ref: v)),
                        ),
                      if (l.rows[i].type == 'country')
                        DropdownButton<String>(
                          value: l.rows[i].ref,
                          hint: Text(t.colCountry),
                          items: [for (final x in refs?.$1 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['code'] as String, child: Text('${x['flag_emoji'] ?? ''} ${nm(x)}'))],
                          onChanged: (v) => _updateRow(i, l.rows[i].copyWith(ref: v)),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(l.rows[i].from == null ? '${t.fFrom} / ${t.fTo}' : '${shortTime(l.rows[i].from!).substring(0, 10)} → ${l.rows[i].to == null ? '…' : shortTime(l.rows[i].to!).substring(0, 10)}'),
                        onPressed: () async {
                          final now = DateTime.now();
                          final r = await showDateRangePicker(context: context, firstDate: now.subtract(const Duration(days: 365)), lastDate: now.add(const Duration(days: 730)));
                          if (r != null) _updateRow(i, l.rows[i].copyWith(from: r.start, to: r.end));
                        },
                      ),
                      if (l.rows[i].from != null) TextButton(onPressed: () => _updateRow(i, l.rows[i].copyWith(clearDates: true)), child: Text(t.cancel)),
                    ]),
                    if (l.rows[i].type == 'manual')
                      Padding(
                        padding: const EdgeInsets.only(top: Space.sm),
                        child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
                          for (final id in l.rows[i].channelIds) chip(id, () => _updateRow(i, l.rows[i].copyWith(channelIds: [...l.rows[i].channelIds]..remove(id)))),
                          ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16),
                            label: Text(t.addChannels),
                            onPressed: () async {
                              final id = await _addChannel();
                              if (id != null) _updateRow(i, layout!.rows[i].copyWith(channelIds: [...layout!.rows[i].channelIds, id]));
                            },
                          ),
                        ]),
                      ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}
