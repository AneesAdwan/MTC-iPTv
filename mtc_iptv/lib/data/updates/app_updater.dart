// التحديث داخل البرنامج على Windows (§18.2–18.4، ADR-11): WinSparkle عبر auto_updater.
//  • الـ appcast على GitHub Pages (رابط ثابت)، والحزمة نفسها من GitHub Releases.
//  • كل حزمة موقّعة بـ DSA، والمفتاح العام مضمَّن في البرنامج (windows/runner/Runner.rc ← dsa_pub.pem):
//    WinSparkle يرفض أي ملف توقيعه غير مطابق، فلا يُثبَّت شيء معدّل.
//  • القناة من رقم الإصدار نفسه: alpha/beta ← قناتها، وإلا stable. لا تثبيت صامت: المستخدم يوافق دائمًا.
//  • على المنصّات الأخرى: صفحة الإصدار (Android لاحقًا في R2).
import 'dart:async';
import 'dart:io';

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env.dart';
import '../../core/logging/log.dart';
import 'android_update.dart';
import 'update_check.dart';

const appcastBase = 'https://aneesadwan.github.io/MTC-iPTv/updates';
const releasesPage = 'https://github.com/AneesAdwan/MTC-iPTv/releases';

/// القناة من الإصدار: 3.0.0-alpha.17 ← alpha، 3.0.0-beta.2 ← beta، 3.0.0 ← stable.
String updateChannel(String version) {
  final m = RegExp(r'-([a-z]+)\.').firstMatch(version);
  return m?.group(1) ?? 'stable';
}

/// للاختبار فقط: --dart-define=UPDATE_FEED=http://127.0.0.1:8793/appcast.xml
const _feedOverride = String.fromEnvironment('UPDATE_FEED');

String feedUrlFor(String version, {String platform = 'windows'}) =>
    _feedOverride.isNotEmpty ? _feedOverride : '$appcastBase/$platform-${updateChannel(version)}.xml';

class AppUpdater {
  AppUpdater._();
  static bool _ready = false;
  static Timer? _raiser;
  static const _native = MethodChannel('mtc/instance');

  /// يرفع نوافذ التحديث (WinSparkle) التي لم تُرفع بعد. يعيد عددها.
  static Future<int> raiseWindows() async {
    try {
      return await _native.invokeMethod<int>('raiseUpdater') ?? 0;
    } catch (_) {
      return 0;
    }
  }
  static bool get supported => Platform.isWindows;

  /// مفعّل لنسخ الإصدار فقط (لا لبناء التطوير 3.0.0-dev ولا للاختبارات).
  static bool get enabled => supported && !Env.version.endsWith('-dev');

  /// يُستدعى مرة عند التشغيل: يضبط الـ appcast والفحص الدوري (كل 6 ساعات، WinSparkle يتذكّر «تخطَّ هذا الإصدار»).
  static Future<void> init() async {
    if (!enabled || _ready) return;
    try {
      await autoUpdater.setFeedURL(feedUrlFor(Env.version));
      await autoUpdater.setScheduledCheckInterval(6 * 3600);
      _ready = true;
      // نوافذ WinSparkle تُفتح خلف نافذة البرنامج (بلاغ المالك 2026-10-16: «كبست تنزيل وما صار شي»):
      // كل ثانيتين نطلب من الجزء الأصلي رفع أي نافذة تحديث جديدة إلى الأمام، مرة واحدة لكل نافذة
      _raiser ??= Timer.periodic(const Duration(seconds: 2), (_) => raiseWindows());
      log.info('updater: ${feedUrlFor(Env.version)}');
    } catch (e) {
      log.warning('updater init failed', e);
    }
  }

  /// «تحقق الآن»: نافذة WinSparkle (تنزيل ← تحقق من التوقيع ← تثبيت عند الموافقة)، وإلا صفحة الإصدارات.
  static Future<void> checkNow({String? fallbackUrl, BuildContext? context, UpdateInfo? known}) async {
    // Android: تنزيل وتثبيت من داخل التطبيق (android_update.dart)، لا صفحة GitHub
    if (Platform.isAndroid && context != null && context.mounted && !Env.version.endsWith('-dev')) {
      await runAndroidUpdate(context, known: known);
      return;
    }
    if (enabled) {
      await init();
      if (_ready) {
        await autoUpdater.checkForUpdates();
        // لا ننتظر المؤقّت: نافذة «جارٍ التحقق» تظهر خلال أجزاء من الثانية
        for (final ms in const [300, 900, 2000]) {
          Future.delayed(Duration(milliseconds: ms), raiseWindows);
        }
        return;
      }
    }
    await launchUrl(Uri.parse(fallbackUrl ?? releasesPage), mode: LaunchMode.externalApplication);
  }
}
