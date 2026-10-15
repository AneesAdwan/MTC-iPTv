// الهيكل العام حسب نمط الجهاز (§6.5، §6.6):
//   desktop: شريط عنوان + قائمة جانبية قابلة للطي + شريط علوي + شريط حالة
//   tablet : قائمة جانبية مضغوطة (أيقونات)
//   phone  : شريط سفلي لأهم شاشات المشاهدة + قائمة كاملة في Drawer
//   tv     : قائمة جانبية بتركيز واضح (التنقل بالريموت)
// الاختصارات العامة: Ctrl+K لوحة الأوامر، Ctrl+B طي القائمة.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/local_settings.dart';
import '../../data/reminders/reminders.dart';
import '../../features/viewer/widgets/mini_player.dart';
import '../../features/viewer/widgets/number_entry.dart';
import '../l10n/app_localizations.dart';
import '../layout/form_factor.dart';
import '../remote/remote_gates.dart';
import '../screens.dart';
import '../theme/tokens.dart';
import 'command_palette.dart';
import 'sidebar.dart';
import 'status_bar.dart';
import 'title_bar.dart';
import 'top_bar.dart';

/// شاشات الشريط السفلي في الجوال (بالترتيب).
const phoneTabs = ['V-02', 'V-03', 'V-05', 'V-08', 'V-10'];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final def = screenForPath(location);
    final t = L10n.of(context);
    final ff = formFactorOf(context);
    final c = context.colors;
    final phone = ff == FormFactor.phone;

    final content = Column(children: [
      TopBar(title: def?.title(t) ?? t.appTitle, compact: phone),
      const AnnouncementBar(), // F2 + تنبيه التحديث (G6)
      // Material (لا ColoredBox): عناصر ListTile تحتاج سطح Material مباشرًا لتظهر ألوانها وتموّجها
      Expanded(child: Material(color: c.bg, child: child)),
    ]);

    final Widget body = switch (ff) {
      FormFactor.desktop || FormFactor.tv => Row(children: [Sidebar(location: location), Expanded(child: content)]),
      FormFactor.tablet => Row(children: [Sidebar(location: location, forceCollapsed: true), Expanded(child: content)]),
      FormFactor.phone => content,
    };

    // تنبيه التذكير داخل البرنامج (§8.5) مع زر «شاهد»
    ref.listen(firedRemindersProvider, (_, next) {
      final r = next.value;
      if (r == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(t.reminderFired(r.title)),
        action: SnackBarAction(label: t.watchNow, onPressed: () => context.push('/watch/${r.channelId}')),
      ));
    });

    // الأرقام من الريموت/لوحة المفاتيح تفتح القناة مباشرة (§8.2)
    return NumberEntry(
      onChannel: (ch) => context.push('/watch/${ch.id}'),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => showCommandPalette(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => ref.read(settingsProvider.notifier).toggleSidebar(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: c.bg,
            drawer: phone ? Drawer(backgroundColor: c.bg2, child: Sidebar(location: location, inDrawer: true)) : null,
            bottomNavigationBar: phone ? _PhoneTabs(current: def) : null,
            body: Column(children: [
              if (ff.isDesktop) const TitleBar(),
              Expanded(child: Stack(fit: StackFit.expand, children: [body, const MiniPlayer()])),
              if (ff.isDesktop) const StatusBar(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PhoneTabs extends StatelessWidget {
  final ScreenDef? current;
  const _PhoneTabs({required this.current});
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final tabs = [for (final id in phoneTabs) screens.firstWhere((s) => s.id == id)];
    final i = tabs.indexWhere((s) => s.id == current?.id);
    return NavigationBar(
      backgroundColor: c.bg2,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      // شاشة خارج الشريط (من القائمة): لا تبويب محدد
      selectedIndex: i < 0 ? 0 : i,
      onDestinationSelected: (n) => context.go(tabs[n].path),
      destinations: [
        for (final s in tabs)
          NavigationDestination(
            icon: Icon(s.icon, color: c.textMuted),
            selectedIcon: Icon(s.icon, color: i < 0 ? c.textMuted : c.accent),
            label: s.title(t),
          ),
      ],
    );
  }
}
