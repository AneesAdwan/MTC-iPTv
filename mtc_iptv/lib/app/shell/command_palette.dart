// لوحة الأوامر (Ctrl+K، §6.6): بحث موحّد في الشاشات والأوامر، بالعربية أو الإنجليزية أو المعرّف.
// تعمل بالكامل بلوحة المفاتيح: ↑↓ للتنقل، Enter للتنفيذ، Esc للإغلاق.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/settings/local_settings.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_ar.dart';
import '../l10n/app_localizations_en.dart';
import '../screens.dart';
import '../theme/tokens.dart';
import 'sidebar.dart';

class PaletteEntry {
  final IconData icon;
  final String title, subtitle;
  final String haystack; // العنوان بالعربية والإنجليزية + المعرّف، مطبّعًا للبحث
  final void Function() run;
  PaletteEntry(this.icon, this.title, this.subtitle, this.haystack, this.run);
}

final _ar = L10nAr(), _en = L10nEn();

Future<void> showCommandPalette(BuildContext context, WidgetRef ref) {
  final t = L10n.of(context);
  final router = GoRouter.of(context);
  final isAdmin = ref.read(isAdminProvider);
  final settings = ref.read(settingsProvider.notifier);
  final entries = <PaletteEntry>[
    for (final s in screens.where((s) => isAdmin || !s.group.isAdmin))
      PaletteEntry(s.icon, s.title(t), '${s.group.title(t)} · ${s.id}', matchKey('${s.title(_ar)} ${s.title(_en)} ${s.id}'),
          () => router.go(s.path)),
    PaletteEntry(Icons.translate_rounded, t.cmdToggleLanguage, '', matchKey('${_ar.cmdToggleLanguage} ${_en.cmdToggleLanguage}'), settings.toggleLocale),
    PaletteEntry(Icons.contrast_rounded, t.cmdToggleTheme, '', matchKey('${_ar.cmdToggleTheme} ${_en.cmdToggleTheme}'), settings.toggleTheme),
    PaletteEntry(Icons.view_sidebar_rounded, t.cmdToggleSidebar, 'Ctrl+B', matchKey('${_ar.cmdToggleSidebar} ${_en.cmdToggleSidebar}'),
        settings.toggleSidebar),
  ];
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _Palette(entries: entries),
  );
}

class _Palette extends StatefulWidget {
  final List<PaletteEntry> entries;
  const _Palette({required this.entries});
  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final query = TextEditingController();
  final scroll = ScrollController();
  int index = 0;

  List<PaletteEntry> get results {
    final q = matchKey(query.text);
    if (q.isEmpty) return widget.entries;
    // كل كلمات البحث يجب أن تظهر (بعد التطبيع العربي) في العنوان أو المعرّف
    final words = query.text.trim().split(RegExp(r'\s+')).map(matchKey).where((w) => w.isNotEmpty);
    return widget.entries.where((e) => words.every(e.haystack.contains)).toList();
  }

  void _run(PaletteEntry e) {
    Navigator.of(context).pop();
    e.run();
  }

  @override
  void dispose() {
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final r = results;
    if (index >= r.length) index = r.isEmpty ? 0 : r.length - 1;
    return Align(
      alignment: const Alignment(0, -0.55),
      child: Material(
        color: c.surface,
        elevation: 24,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.line2)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          // لا تتجاوز عرض الشاشة في الجوال
          width: MediaQuery.sizeOf(context).width.clamp(280.0, 580.0) - 24,
          height: 440,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () => setState(() => index = (index + 1).clamp(0, r.length - 1)),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () => setState(() => index = (index - 1).clamp(0, r.length - 1)),
              const SingleActivator(LogicalKeyboardKey.enter): () => r.isNotEmpty ? _run(r[index]) : null,
            },
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: TextField(
                  controller: query,
                  autofocus: true,
                  onChanged: (_) => setState(() => index = 0),
                  decoration: InputDecoration(hintText: t.paletteHint, prefixIcon: const Icon(Icons.search_rounded)),
                ),
              ),
              Divider(height: 1, color: c.line),
              Expanded(
                child: r.isEmpty
                    ? Center(child: Text(t.noResults, style: TextStyle(color: c.textDim)))
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.all(Space.sm),
                        itemCount: r.length,
                        itemBuilder: (_, i) {
                          final e = r[i];
                          final sel = i == index;
                          return Material(
                            color: sel ? c.accent.withValues(alpha: 0.14) : Colors.transparent,
                            borderRadius: BorderRadius.circular(Radii.sm),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Radii.sm),
                              canRequestFocus: false,
                              onTap: () => _run(e),
                              onHover: (h) => h ? setState(() => index = i) : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
                                child: Row(children: [
                                  Icon(e.icon, size: 19, color: sel ? c.accent : c.textMuted),
                                  const SizedBox(width: Space.md),
                                  Expanded(child: Text(e.title, style: TextStyle(color: c.text, fontSize: 14))),
                                  if (e.subtitle.isNotEmpty)
                                    Text(e.subtitle, style: TextStyle(color: c.textDim, fontSize: 12)),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
