// الشريط العلوي (§6.6): البحث العام (يفتح لوحة الأوامر)، حالة الاتصال، التنبيهات، الحساب.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/local_settings.dart';
import '../../core/text/bidi.dart';
import '../../data/auth/admin_auth.dart';
import '../../data/reminders/reminders.dart';
import '../../features/viewer/widgets/number_entry.dart';
import '../l10n/app_localizations.dart';
import '../screens.dart';
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
          // لوحة الأرقام: الانتقال لقناة برقمها (طلب المالك — الجوال بلا لوحة مفاتيح أرقام)
          IconButton(tooltip: t.numPad, onPressed: () => showNumberPad(context, onChannel: (ch) => context.push('/watch/${ch.id}')), icon: Icon(Icons.dialpad_rounded, color: c.textMuted)),
          IconButton(tooltip: t.searchHint, onPressed: () => showCommandPalette(context, ref), icon: Icon(Icons.search_rounded, color: c.textMuted)),
          const InboxBell(),
          const AccountMenu(),
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
        const InboxBell(),
        const SizedBox(width: Space.xs),
        const AccountMenu(),
      ]),
    );
  }
}

/// أيقونة الحساب (طلب المالك 2026-10-16): كانت شكلًا بلا وظيفة. الآن قائمة: الحالة، لوحة الإدارة،
/// الحساب والأمان، وتسجيل الخروج بتأكيد — أو «دخول المدير» لغير المسجّل.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final st = ref.watch(adminStateProvider).value;
    if (st == null || st.stage == AdminStage.noBackend) return const SizedBox.shrink();
    final signedIn = st.stage != AdminStage.signedOut;
    final email = st.email ?? '';
    final initial = email.isEmpty ? '' : email.characters.first.toUpperCase();
    return PopupMenuButton<String>(
      tooltip: t.accountMenu,
      position: PopupMenuPosition.under,
      onSelected: (v) async {
        switch (v) {
          case 'panel':
            context.go('/admin/dashboard');
          case 'account':
            context.go('/admin/account');
          case 'login':
            context.go(adminLoginScreen.path);
          case 'logout':
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text(t.signOut),
                content: Text(t.signOutConfirm),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
                  FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.signOut)),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(adminAuthProvider)?.signOut();
              if (context.mounted) context.go('/home');
            }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(signedIn ? t.signedInAs(ltr(email)) : t.notSignedIn, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
        ),
        const PopupMenuDivider(),
        if (st.isAdmin) PopupMenuItem(value: 'panel', child: ListTile(leading: const Icon(Icons.dashboard_rounded), title: Text(t.adminPanel), contentPadding: EdgeInsets.zero)),
        if (st.isAdmin) PopupMenuItem(value: 'account', child: ListTile(leading: const Icon(Icons.admin_panel_settings_rounded), title: Text(t.sH1), contentPadding: EdgeInsets.zero)),
        if (!st.isAdmin) PopupMenuItem(value: 'login', child: ListTile(leading: const Icon(Icons.lock_person_rounded), title: Text(t.adminSignIn), contentPadding: EdgeInsets.zero)),
        if (signedIn)
          PopupMenuItem(
            value: 'logout',
            child: ListTile(leading: Icon(Icons.logout_rounded, color: c.bad), title: Text(t.signOut, style: TextStyle(color: c.bad)), contentPadding: EdgeInsets.zero),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: signedIn ? c.accent.withValues(alpha: .18) : c.surface2,
          child: initial.isEmpty
              ? Icon(Icons.person_rounded, size: 18, color: c.textMuted)
              : Text(initial, style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
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

/// جرس الإشعارات مع عدد غير المقروء (V-09).
class InboxBell extends ConsumerWidget {
  const InboxBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors, t = L10n.of(context);
    final n = ref.watch(unreadProvider).value ?? 0;
    return IconButton(
      tooltip: t.sV09,
      onPressed: () => context.go('/inbox'),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        backgroundColor: c.accent,
        child: Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: n > 0 ? c.accent : c.textMuted),
      ),
    );
  }
}