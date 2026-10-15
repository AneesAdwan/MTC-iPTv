// ADM-B7 الترقيم (§9.4): خطة بالتجميع (دولة ← فئة ← اسم…)، معاينة، تطبيق ذري على الخادم
// (admin_renumber_preview/apply الموجودتان في الإنتاج). سجل التدقيق يحفظ الرقم القديم لكل قناة.
// (النطاقات المحجوزة وقفل رقم قناة: تحتاج أعمدة جديدة — مع إعدادات المرحلة 6.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

class NumberingScreen extends ConsumerStatefulWidget {
  const NumberingScreen({super.key});
  @override
  ConsumerState<NumberingScreen> createState() => _NumberingScreenState();
}

class _NumberingScreenState extends ConsumerState<NumberingScreen> {
  // نفس الترتيب الافتراضي لزر اللوحة القديمة (admin_renumber)
  List<String> keys = ['arab', 'country', 'sort_order', 'featured', 'name'];
  final start = TextEditingController(text: '1');
  final block = TextEditingController(text: '0');
  bool publishedFirst = true;
  Map<String, dynamic>? preview;
  String? error;
  bool busy = false;

  Map<String, String> _labels(L10n t) => {
        'arab': t.nkArab,
        'country': t.nkCountry,
        'category': t.nkCategory,
        'language': t.nkLanguage,
        'featured': t.nkFeatured,
        'quality': t.nkQuality,
        'online': t.nkOnline,
        'sort_order': t.nkSortOrder,
        'name': t.nkName,
        'newest': t.nkNewest,
        'current': t.nkCurrent,
      };

  @override
  void dispose() {
    start.dispose();
    block.dispose();
    super.dispose();
  }

  int get _start => int.tryParse(start.text) ?? 1;
  int get _block => int.tryParse(block.text) ?? 0;

  Future<void> _preview() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = await repo.renumberPreview(keys, start: _start, block: _block, publishedFirst: publishedFirst);
      setState(() => preview = p);
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _apply() async {
    final repo = ref.read(adminRepoProvider);
    final p = preview;
    if (repo == null || p == null) return;
    final t = L10n.of(context);
    final changed = (p['changed'] as num?)?.toInt() ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(t.numConfirm(changed)),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.numApply))],
      ),
    );
    if (ok != true) return;
    setState(() => busy = true);
    try {
      final n = await repo.renumberApply(keys, start: _start, block: _block, publishedFirst: publishedFirst);
      ref.invalidate(adminChannelsProvider);
      if (mounted) toast(context, t.numApplied(n));
      await _preview();
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final labels = _labels(t);
    final p = preview;
    final rows = (p?['rows'] as List?)?.cast<Map>() ?? const <Map>[];
    final unused = labels.keys.where((k) => !keys.contains(k)).toList();

    final plan = SectionCard(
      title: t.numOrderBy,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t.numHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
        const SizedBox(height: Space.sm),
        // الترتيب بالسحب: الأول هو أساس التجميع (§9.4)
        ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          onReorderItem: (from, to) => setState(() {
            keys.insert(to, keys.removeAt(from));
            preview = null;
          }),
          children: [
            for (var i = 0; i < keys.length; i++)
              ListTile(
                key: ValueKey(keys[i]),
                dense: true,
                leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator_rounded)),
                title: Text('${i + 1}. ${labels[keys[i]] ?? keys[i]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() {
                    keys.removeAt(i);
                    preview = null;
                  }),
                ),
              ),
          ],
        ),
        if (unused.isNotEmpty)
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            for (final k in unused)
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text(labels[k]!),
                onPressed: () => setState(() {
                  keys.add(k);
                  preview = null;
                }),
              ),
          ]),
        const SizedBox(height: Space.md),
        Row(children: [
          Expanded(
            child: TextField(
              controller: start,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.numStart),
              onChanged: (_) => setState(() => preview = null),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: TextField(
              controller: block,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.numBlock),
              onChanged: (_) => setState(() => preview = null),
            ),
          ),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.numPublishedFirst),
          value: publishedFirst,
          onChanged: (v) => setState(() {
            publishedFirst = v;
            preview = null;
          }),
        ),
        Row(children: [
          FilledButton.tonalIcon(onPressed: busy ? null : _preview, icon: const Icon(Icons.preview_rounded), label: Text(t.numPreview)),
          const SizedBox(width: Space.sm),
          FilledButton.icon(onPressed: busy || p == null || ((p['changed'] as num?) ?? 0) == 0 ? null : _apply, icon: const Icon(Icons.format_list_numbered_rounded), label: Text(t.numApply)),
          if (busy) const Padding(padding: EdgeInsets.all(Space.sm), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ]),
        if (error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
      ]),
    );

    final result = p == null
        ? const SizedBox.shrink()
        : SectionCard(
            title: t.numSummary((p['changed'] as num?)?.toInt() ?? 0, (p['total'] as num?)?.toInt() ?? 0, (p['max'] as num?)?.toInt() ?? 0),
            child: Column(children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(
                      width: 120,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('${r['old_number'] ?? '—'}  →  ${r['new_number']}',
                            style: TextStyle(color: r['old_number'] == r['new_number'] ? c.textMuted : c.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    SizedBox(width: 28, height: 22, child: r['logo_url'] == null ? null : Image.network('${r['logo_url']}', fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text('${r['name']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 13))),
                    Text([r['country'], r['category']].whereType<String>().join(' · '), style: TextStyle(color: c.textMuted, fontSize: 12)),
                    if (r['is_published'] != true) Padding(padding: const EdgeInsetsDirectional.only(start: Space.sm), child: StatePill(r['hidden_reason'] == 'pending' ? 'pending' : 'hidden')),
                  ]),
                ),
            ]),
          );

    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 1000
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 420, child: ListView(padding: const EdgeInsets.all(Space.lg), children: [plan])),
              Expanded(child: ListView(padding: const EdgeInsets.all(Space.lg), children: [result])),
            ])
          : ListView(padding: const EdgeInsets.all(Space.lg), children: [plan, const SizedBox(height: Space.lg), result]),
    );
  }
}
