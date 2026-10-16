// إشعارات Push على Android (§14، R2): الكود الأصلي (Push.kt) يطلب الإذن ويشترك في الموضوع «all» —
// نفس قناة تطبيق React Native ودالة send-push — ويعيد رمز FCM، فيُسجَّل في installations (§20: للنظام فقط).
// نسخ المعاينة تُبنى بلا إعداد Firebase فيعيد null ولا شيء يحدث.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/log.dart';
import '../telemetry/telemetry.dart';

final pushInitProvider = FutureProvider<String?>((ref) async {
  if (!Platform.isAndroid) return null;
  try {
    final token = await const MethodChannel('mtc/instance').invokeMethod<String>('pushInit');
    log.info('push: ${token == null ? 'not configured in this build' : 'subscribed to "all"'}');
    if (token != null) ref.read(telemetryProvider).pushToken = token;
    return token;
  } catch (e) {
    log.warning('push init failed', e);
    return null;
  }
});
