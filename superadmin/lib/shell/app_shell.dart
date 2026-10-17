// The frame around every admin page (plan §8): sidebar with the 7 sections (on the right in RTL),
// top bar (global search / Ctrl+K, alerts bell, account menu), the page, the result bar, status bar.
// Keyboard: Ctrl+K search · / filter · Ctrl+Z undo (Space / Enter / Del live in the table rows).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../auth/auth_controller.dart';
import '../core/env.dart';
import '../core/prefs.dart';
import '../core/tr.dart';
import '../data/providers.dart';
import '../ui/filter_bar.dart';
import '../ui/result_bar.dart';
import '../ui/widgets.dart';
import 'command_palette.dart';

final decisionCountsProvider = FutureProvider<Map<String, int>>((ref) => ref.watch(decisionsRepoProvider).counts());

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _focus = FocusNode(debugLabel: 'shell');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void openPalette() {
    final prefs = ref.read(prefsProvider);
    final auth = ref.read(authControllerProvider);
    showCommandPalette(
      context,
      entries: buildPaletteEntries(
        go: (l) => context.go(l),
        actions: [
          PaletteEntry(const Tr('بدّل اللغة (عربي/English)', 'Switch language (Arabic/English)'), Icons.translate, prefs.toggleLang),
          PaletteEntry(const Tr('بدّل الوضع الفاتح/الداكن', 'Toggle light/dark'), Icons.contrast, prefs.toggleTheme),
          PaletteEntry(const Tr('تسجيل الخروج', 'Sign out'), Icons.logout, () => unawaited(auth.signOut())),
        ],
      ),
      searchChannels: (q) => context.go(Uri(path: '/channels', queryParameters: {'q': q}).toString()),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final k = e.logicalKey;
    if (ctrl && k == LogicalKeyboardKey.keyK) {
      openPalette();
      return KeyEventResult.handled;
    }
    if (_typing()) return KeyEventResult.ignored;
    if (!ctrl && (k == LogicalKeyboardKey.slash || k == LogicalKeyboardKey.numpadDivide)) {
      return ref.read(filterFocusProvider).focus() ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (ctrl && k == LogicalKeyboardKey.keyZ) {
      unawaited(ref.read(resultCenterProvider).undoLast());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: Row(
          children: [
            Sidebar(location: location),
            Expanded(
              child: Column(
                children: [
                  TopBar(onSearch: openPalette),
                  Expanded(
                    child: KeyedSubtree(key: ValueKey(Uri.parse(location).path), child: widget.child),
                  ),
                  const ResultBarHost(),
                  const StatusBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Sidebar extends ConsumerWidget {
  final String location;
  const Sidebar({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final current = Nav.sectionFor(location);
    final path = Uri.parse(location).path;
    final counts = ref.watch(decisionCountsProvider).value;
    final decisionsTotal = counts?.values.fold<int>(0, (a, b) => a + b);
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: c.bg2,
        border: BorderDirectional(end: BorderSide(color: c.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.md),
            child: Row(
              children: [
                const BrandMark(size: 34),
                const SizedBox(width: Space.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MTC-iPTv',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                    Text(
                      'SuperAdmin',
                      style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              children: [
                for (final s in Nav.sections) ...[
                  _SectionTile(section: s, selected: s == current, badge: s == Nav.decisions ? decisionsTotal : null, onTap: () => context.go(s.path)),
                  if (s == current && s.pages.length > 1)
                    for (final p in s.pages) _PageTile(page: p, selected: p.path == path, onTap: () => context.go(p.path)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final NavSection section;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;
  const _SectionTile({required this.section, required this.selected, required this.onTap, this.badge});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? c.accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          key: ValueKey('nav-${section.id}'),
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
            child: Row(
              children: [
                Icon(section.icon, size: 20, color: selected ? c.accent : c.textMuted),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(context.tr(section.title), style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(gradient: c.brandGradient, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      fmtInt(badge!),
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  final NavPage page;
  final bool selected;
  final VoidCallback onTap;
  const _PageTile({required this.page, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      key: ValueKey('nav-page-${page.id}'),
      borderRadius: BorderRadius.circular(Radii.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(44, 7, Space.md, 7),
        child: Text(
          context.tr(page.title),
          style: TextStyle(color: selected ? c.accent : c.textMuted, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13),
        ),
      ),
    );
  }
}

class TopBar extends ConsumerWidget {
  final VoidCallback onSearch;
  const TopBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefs = ref.watch(prefsProvider);
    final auth = ref.watch(authControllerProvider);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: InkWell(
                  key: const ValueKey('global-search'),
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: c.textDim),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            context.tr(const Tr('ابحث عن قناة أو رابط أو إعداد…', 'Search a channel, stream or setting…')),
                            style: TextStyle(color: c.textDim),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            border: Border.all(color: c.line2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ctrl+K',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: c.textDim, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          // Alerts bell — the live feed arrives with the server alerts in Phase 2/7.
          PopupMenuButton<String>(
            key: const ValueKey('alerts-bell'),
            tooltip: context.tr(const Tr('التنبيهات', 'Alerts')),
            onSelected: (v) => context.go(v),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text(ctx.tr(const Tr('التنبيهات المباشرة بتوصل مع خدمات الخادم.', 'Live alerts arrive with the server services.'))),
              ),
              PopupMenuItem(value: '/home/alerts', child: Text(ctx.tr(const Tr('افتح كل التنبيهات', 'Open all alerts')))),
            ],
            child: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Badge(label: const Text('3'), backgroundColor: c.accent, child: const Icon(Icons.notifications_none)),
            ),
          ),
          const SizedBox(width: Space.sm),
          PopupMenuButton<String>(
            key: const ValueKey('account-menu'),
            tooltip: context.tr(const Tr('الحساب', 'Account')),
            onSelected: (v) {
              switch (v) {
                case 'lang':
                  prefs.toggleLang();
                case 'theme':
                  prefs.toggleTheme();
                case 'sessions':
                  context.go('/system?tab=sessions');
                case 'signout':
                  unawaited(auth.signOut());
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.email ?? '',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: ctx.colors.text, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ctx.tr(Tr('جلسة مدير مؤكدة (${auth.aal})', 'Verified admin session (${auth.aal})')),
                      style: TextStyle(color: ctx.colors.ok, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'lang', child: Text(ctx.lang == Lang.ar ? 'English' : 'العربية')),
              PopupMenuItem(value: 'theme', child: Text(ctx.tr(const Tr('الوضع الفاتح/الداكن', 'Light/dark mode')))),
              PopupMenuItem(value: 'sessions', child: Text(ctx.tr(const Tr('الجلسات النشطة', 'Active sessions')))),
              const PopupMenuDivider(),
              PopupMenuItem(key: const ValueKey('menu-signout'), value: 'signout', child: Text(ctx.tr(const Tr('تسجيل الخروج', 'Sign out')))),
            ],
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: c.accent.withValues(alpha: 0.18),
                child: Text(
                  (auth.email ?? '?').substring(0, 1).toUpperCase(),
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final auth = ref.watch(authControllerProvider);
    final style = TextStyle(color: c.textDim, fontSize: 11.5);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: auth.isAdmin ? c.ok : c.warn),
          const SizedBox(width: 6),
          ValueListenableBuilder<DateTime?>(
            valueListenable: auth.lastVerified,
            builder: (context, at, _) => Text(
              context.tr(
                at == null
                    ? const Tr('بانتظار تأكيد الخادم', 'Waiting for server confirmation')
                    : Tr('الخادم أكّد الصلاحية ${fmtTime(at)} · ${auth.aal}', 'Server confirmed access ${fmtTime(at)} · ${auth.aal}'),
              ),
              key: const ValueKey('status-verified'),
              style: style,
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Text(
              context.tr(
                const Tr(
                  'Ctrl+K بحث · / فلتر · Space تحديد · Enter فتح · Del سلة · Ctrl+Z تراجع',
                  'Ctrl+K search · / filter · Space select · Enter open · Del trash · Ctrl+Z undo',
                ),
              ),
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: Space.lg),
          Text('${Env.name} · ${Env.version}', style: style, textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}
