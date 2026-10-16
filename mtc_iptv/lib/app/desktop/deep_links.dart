// الروابط العميقة (§23، ملحق أ): mtciptv://watch/<id> بنفس شكل الموقع وتطبيق RN.
//  • عند التشغيل: من وسائط البرنامج (Windows يمرّر الرابط كوسيط بعد تسجيل البروتوكول في المثبّت).
//  • والبرنامج يعمل: النسخة الثانية تمرّر سطر أوامرها للنافذة الحالية (windows/runner/main.cpp)
//    عبر القناة mtc/instance، فنُظهر النافذة ونفتح القناة.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/log.dart';
import '../router.dart';

/// معرّف القناة من رابط `mtciptv://watch/<id>` (أو null). يقبل الشرطة المائلة الأخيرة والاستعلام.
String? channelFromDeepLink(String? link) {
  if (link == null) return null;
  final m = RegExp(r'^mtciptv://watch/([A-Za-z0-9_-]{1,64})/?(?:[?#].*)?$', caseSensitive: false).firstMatch(link.trim().replaceAll('"', ''));
  return m?.group(1);
}

/// أول رابط في الوسائط أو في سطر أوامر نصي.
String? findDeepLink(Iterable<String> args) {
  for (final a in args) {
    final i = a.toLowerCase().indexOf('mtciptv://');
    if (i >= 0) return a.substring(i).split(RegExp(r'[\s"]')).first;
  }
  return null;
}

/// الرابط الذي فُتح به البرنامج (يُمرَّر من main عبر override).
final launchDeepLinkProvider = Provider<String?>((_) => null);

class DeepLinks {
  static const _channel = MethodChannel('mtc/instance');

  /// يُستدعى مرة بعد بناء الموجّه.
  static void attach(WidgetRef ref) {
    final first = channelFromDeepLink(ref.read(launchDeepLinkProvider));
    if (first != null) {
      // بعد أول إطار: الموجّه جاهز
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(routerProvider).push('/watch/$first'));
    }
    if (!Platform.isWindows && !Platform.isAndroid) return;
    // Android: الرابط الذي فُتح به التطبيق يأتي من Intent (MainActivity.kt)، لا من الوسائط
    if (Platform.isAndroid) {
      _channel.invokeMethod<String>('initialLink').then((link) {
        final id = channelFromDeepLink(link);
        if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(routerProvider).push('/watch/$id'));
      }).catchError((Object _) {});
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'args') return null;
      final cmd = '${call.arguments}';
      log.info('second launch: ${cmd.length > 120 ? cmd.substring(0, 120) : cmd}');
      if (cmd.contains('--hidden')) return null; // تشغيل تلقائي مكرر مع ويندوز: لا شيء
      if (Platform.isWindows) {
        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (_) {}
      }
      final id = channelFromDeepLink(findDeepLink([cmd]));
      if (id != null) ref.read(routerProvider).push('/watch/$id');
      return null;
    });
  }
}
