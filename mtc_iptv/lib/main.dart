// MTC-iPTv — منتج من MTC-Group. برمجة وتطوير: أنيس عدوان.
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/backend/backend.dart';
import 'core/config/env.dart';
import 'core/logging/log.dart';
import 'core/settings/local_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // libmpv (ADR-02)
  await initLogging();
  log.info('start v${Env.version} env=${Env.name} ${Platform.operatingSystem}');

  // أي خطأ غير معالَج يُسجَّل (دون أسرار) بدل أن يضيع
  FlutterError.onError = (d) {
    log.severe('flutter error', d.exception, d.stack);
    FlutterError.presentError(d);
  };
  PlatformDispatcher.instance.onError = (e, s) {
    log.severe('uncaught', e, s);
    return true;
  };

  final settings = await loadSettings();
  // بلا اتصال أو بلا خادم مُعدّ: يعمل التطبيق من الكتالوج المحلي (§22)
  final hasBackend = await initBackend().catchError((Object e) {
    log.warning('backend init failed', e);
    return false;
  });

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(420, 560),
        center: true,
        title: 'MTC-iPTv',
        titleBarStyle: TitleBarStyle.hidden, // شريط العنوان المخصص (§6.6)
        backgroundColor: Color(0xFF08080C),
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(ProviderScope(
    overrides: [
      initialSettingsProvider.overrideWithValue(settings),
      if (hasBackend) supabaseProvider.overrideWithValue(Supabase.instance.client),
    ],
    child: const MtcApp(),
  ));
}
