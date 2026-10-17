// Ctrl+K: jump to any page, decision type or action; or search channels by name/number.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mtc_core/mtc_core.dart' show foldArabic;

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';

@immutable
class PaletteEntry {
  final Tr title;
  final Tr? group;
  final IconData icon;
  final VoidCallback run;
  const PaletteEntry(this.title, this.icon, this.run, {this.group});
}

/// Search key: case-folded, Arabic letter variants and digits folded (shared logic from mtc_core).
String paletteKey(String s) => foldArabic(s.toLowerCase());

List<PaletteEntry> buildPaletteEntries({required void Function(String location) go, List<PaletteEntry> actions = const []}) => [
  for (final s in Nav.sections)
    for (final p in s.pages) PaletteEntry(p.title, p.icon, () => go(p.path), group: s.title),
  for (final t in DecisionType.all) PaletteEntry(t.title, t.icon, () => go('/decisions?type=${t.id}'), group: Nav.decisions.title),
  ...actions,
];

Future<void> showCommandPalette(BuildContext context, {required List<PaletteEntry> entries, required void Function(String q) searchChannels}) =>
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _Palette(entries: entries, searchChannels: searchChannels),
    );

class _Palette extends StatefulWidget {
  final List<PaletteEntry> entries;
  final void Function(String q) searchChannels;
  const _Palette({required this.entries, required this.searchChannels});
  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final _q = TextEditingController();
  int _index = 0;

  List<PaletteEntry> _results(Lang lang) {
    final q = paletteKey(_q.text.trim());
    final list = q.isEmpty
        ? widget.entries
        : widget.entries.where((e) {
            final hay = paletteKey('${e.title.ar} ${e.title.en} ${e.group?.ar ?? ''} ${e.group?.en ?? ''}');
            return hay.contains(q);
          }).toList();
    if (_q.text.trim().isEmpty) return list;
    final text = _q.text.trim();
    return [...list, PaletteEntry(Tr('ابحث بالقنوات عن «$text»', 'Search channels for "$text"'), Icons.search, () => widget.searchChannels(text))];
  }

  void _run(PaletteEntry e) {
    Navigator.pop(context);
    e.run();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final results = _results(context.lang);
    if (_index >= results.length) _index = results.isEmpty ? 0 : results.length - 1;
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Material(
        key: const ValueKey('command-palette'),
        color: c.surface,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: c.line2),
        ),
        child: SizedBox(
          width: 640,
          height: 460,
          child: Column(
            children: [
              Focus(
                onKeyEvent: (node, e) {
                  if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                  if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                    setState(() => _index = (_index + 1).clamp(0, results.length - 1));
                    return KeyEventResult.handled;
                  }
                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                    setState(() => _index = (_index - 1).clamp(0, results.length - 1));
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: TextField(
                    key: const ValueKey('palette-input'),
                    controller: _q,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: context.tr(const Tr('ابحث عن صفحة أو قناة أو إجراء…', 'Search a page, channel or action…')),
                    ),
                    onChanged: (_) => setState(() => _index = 0),
                    onSubmitted: (_) {
                      // Recompute: the text may have changed since the last build.
                      final fresh = _results(context.lang);
                      if (fresh.isNotEmpty) _run(fresh[_index.clamp(0, fresh.length - 1)]);
                    },
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final e = results[i];
                    return ListTile(
                      dense: true,
                      selected: i == _index,
                      selectedTileColor: c.accent.withValues(alpha: 0.10),
                      leading: Icon(e.icon, size: 20),
                      title: Text(context.tr(e.title)),
                      subtitle: e.group == null ? null : Text(context.tr(e.group!), style: TextStyle(color: c.textDim, fontSize: 12)),
                      onTap: () => _run(e),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Text(
                  context.tr(const Tr('↑↓ للتنقل · Enter للفتح · Esc للإغلاق', '↑↓ to move · Enter to open · Esc to close')),
                  style: TextStyle(color: c.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
