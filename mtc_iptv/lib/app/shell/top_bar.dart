// الشريط العلوي (§6.6): البحث العام (يفتح لوحة الأوامر)، حالة الاتصال، التنبيهات، الحساب.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/local_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'command_palette.dart';

class TopBar extends ConsumerWidget {
  final String title;

  /// الجوال: زر القائمة + أيقونة بحث بدل الحقل، ودون أزرار اللغة والمظهر (موجودة في الإعدادات).
  final bool compact;
  const TopBar({super.key, required this.title, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final s = ref.watch(settingsProvider);
    if (compact) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.line))),
        child: Row(children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.menu_rounded, color: c.textMuted),
          ),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text))),
          IconButton(tooltip: t.searchHint, onPressed: () => showCommandPalette(context, ref), icon: Icon(Icons.search_rounded, color: c.textMuted)),
          IconButton(tooltip: t.sV09, onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: c.textMuted)),
        ]),
      );
    }
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      decoration: BoxDecoration(color: c.bg, border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
        const Spacer(),
        // زر البحث العام: يبدو كحقل، ويفتح لوحة الأوامر
        SizedBox(
          width: 320,
          child: Material(
            color: c.surface2,
            borderRadius: BorderRadius.circular(Radii.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: () => showCommandPalette(context, ref),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.sm), border: Border.all(color: c.line)),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 18, color: c.textDim),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(t.searchHint, style: TextStyle(color: c.textDim, fontSize: 13))),
                  _Kbd(t.searchShortcut),
                ]),
              ),
            ),
          ),
        ),
        const Spacer(),
        _StatusDot(online: true, label: t.statusOnline),
        const SizedBox(width: Space.sm),
        IconButton(
          tooltip: t.cmdToggleLanguage,
          onPressed: () => ref.read(settingsProvider.notifier).toggleLocale(),
          icon: Text(s.locale.languageCode == 'ar' ? 'EN' : 'ع', style: TextStyle(fontWeight: FontWeight.w700, color: c.textMuted)),
        ),
        IconButton(
          tooltip: t.cmdToggleTheme,
          onPressed: () => ref.read(settingsProvider.notifier).toggleTheme(),
          icon: Icon(s.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: c.textMuted),
        ),
        IconButton(tooltip: t.sV09, onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: c.textMuted)),
        const SizedBox(width: Space.xs),
        CircleAvatar(
          radius: 16,
          backgroundColor: c.surface2,
          child: Icon(Icons.person_rounded, size: 18, color: c.textMuted),
        ),
      ]),
    );
  }
}

class _Kbd extends StatelessWidget {
  final String text;
  const _Kbd(this.text);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(4), border: Border.all(color: c.line2)),
        child: Text(text, style: TextStyle(fontSize: 11, color: c.textMuted)),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool online;
  final String label;
  const _StatusDot({required this.online, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = online ? c.ok : c.bad;
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle, boxShadow: [BoxShadow(color: col.withValues(alpha: .5), blurRadius: 6)])),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: c.textMuted)),
    ]);
  }
}
