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
import 'app/desktop/deep_links.dart';
import 'app/layout/form_factor.dart';
import 'core/backend/backend.dart';
import 'core/config/env.dart';
import 'core/logging/log.dart';
import 'core/settings/local_settings.dart';
import 'data/updates/app_updater.dart';
import 'player/tls_bundle.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // libmpv (ADR-02)
  await initLogging();
  // --hidden: البدء مع ويندوز في الخلفية (المُجدوِل يعمل والنافذة مخفية، §9.10 H2)
  final hidden = args.contains('--hidden');
  log.info('start v${Env.version} env=${Env.name} ${Platform.operatingSystem}${hidden ? ' hidden' : ''}');

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
  await detectAndroidTv(); // نمط التلفاز (§6.5) قبل أول إطار
  await TlsBundle.prepare();
  // بلا اتصال أو بلا خادم مُعدّ: يعمل التطبيق من الكتالوج المحلي (§22)
  final hasBackend = await initBackend().catchError((Object e) {
    log.warning('backend init failed', e);
    return false;
  });

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(420, 560),
        center: true,
        title: Env.appTitle,
        titleBarStyle: TitleBarStyle.hidden, // شريط العنوان المخصص (§6.6)
        backgroundColor: Color(0xFF08080C),
      ),
      () async {
        if (hidden) return; // يظهر من أيقونة منطقة الإشعارات
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(ProviderScope(
    overrides: [
      initialSettingsProvider.overrideWithValue(settings),
      launchDeepLinkProvider.overrideWithValue(findDeepLink(args)),
      if (hasBackend) supabaseProvider.overrideWithValue(Supabase.instance.client),
    ],
    child: const MtcApp(),
  ));

  // التحديث داخل البرنامج (§18): لنسخ الإصدار فقط، لا لبناء التطوير (3.0.0-dev)
  unawaited(AppUpdater.init());
  // للاختبار فقط (--dart-define=UPDATE_CHECK_ON_START=true): فحص بواجهة WinSparkle بعد 5 ثوانٍ
  if (const bool.fromEnvironment('UPDATE_CHECK_ON_START')) {
    unawaited(Future.delayed(const Duration(seconds: 5), () => AppUpdater.checkNow()));
  }
}
