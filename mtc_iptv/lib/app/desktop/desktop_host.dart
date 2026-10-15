// العمل في الخلفية على سطح المكتب (§9.10 H2، §14): أيقونة بجانب الساعة، وإغلاق النافذة يخفيها
// (للمدير حين يكون «البقاء في منطقة الإشعارات» مفعّلًا) فيستمر المُجدوِل، والبدء مع ويندوز مخفيًا (--hidden).
// للمشاهد العادي: الإغلاق يُنهي البرنامج كالمعتاد.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// واجهة tray_manager المتوافقة (legacy): نفس ما جُرّب في نموذج المرحلة 0 (Tray + البدء مع ويندوز + التعويض).
// الواجهة الأصلية الجديدة غير مجرّبة بعد؛ الانتقال إليها مهمة منفصلة مع اختبار يدوي.
// ignore_for_file: deprecated_member_use
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/log.dart';
import '../../data/admin/admin_device.dart';
import '../../data/admin/scheduler.dart';
import '../../data/telemetry/telemetry.dart';
import '../../player/playback_controller.dart';
import '../shell/sidebar.dart' show isAdminProvider;

bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

class DesktopHost extends ConsumerStatefulWidget {
  final Widget child;
  const DesktopHost({super.key, required this.child});
  @override
  ConsumerState<DesktopHost> createState() => _DesktopHostState();
}

class _DesktopHostState extends ConsumerState<DesktopHost> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (!isDesktop) return;
    windowManager.addListener(this);
    trayManager.addListener(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      await windowManager.setPreventClose(true);
      await trayManager.setIcon(Platform.isWindows ? 'assets/tray/tray.ico' : 'assets/brand/mtc-iptv-icon.svg');
      await trayManager.setToolTip('MTC-iPTv');
      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'show', label: 'MTC-iPTv'),
        MenuItem.separator(),
        MenuItem(key: 'run', label: 'Run due tasks now · تشغيل المهام المستحقة'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit · خروج'),
      ]));
    } catch (e) {
      log.warning('tray setup failed', e);
    }
  }

  @override
  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    // آخر أحداث القياس (§12.4): تُغلق جلسة المشاهدة وتُرسل الدفعة، بمهلة قصيرة كي لا يتأخر الإغلاق
    try {
      await ref.read(playbackProvider.notifier).stop();
      await ref.read(telemetryProvider).flush().timeout(const Duration(seconds: 3));
    } catch (_) {}
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    final dev = ref.read(adminDeviceProvider).value;
    final admin = ref.read(isAdminProvider);
    if (admin && (dev?.keepInTray ?? true) && (dev?.schedulerEnabled ?? true)) {
      log.info('window closed -> hidden to tray (scheduler keeps running)');
      await windowManager.hide();
    } else {
      await _quit();
    }
  }

  @override
  void onTrayIconMouseDown() => _show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'show':
        _show();
      case 'run':
        ref.read(schedulerProvider.notifier).tick();
      case 'quit':
        _quit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) ref.watch(schedulerProvider); // يبقى المُجدوِل حيًا طوال عمر البرنامج
    return widget.child;
  }
}
