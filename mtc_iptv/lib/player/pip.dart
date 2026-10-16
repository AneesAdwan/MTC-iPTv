// صورة داخل صورة على Android (§7.6، R2): النافذة الصغيرة فوق التطبيقات الأخرى.
//  • شاشة المشاهدة تسمح بها أثناء التشغيل (setPip)، فيدخلها النظام تلقائيًا عند مغادرة التطبيق،
//    أو يدويًا بزر في شريط التحكم (enterPip).
//  • داخل PiP تعرض شاشة المشاهدة الفيديو وحده (MainActivity يُبلغ بالتغيّر: «pip»).
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/layout/form_factor.dart';

class Pip {
  Pip._();
  static const _ch = MethodChannel('mtc/instance');

  /// الجوال والتابلت فقط (Android TV له مشغّله بملء الشاشة).
  static bool get supported => Platform.isAndroid && !isAndroidTv;

  static final _changes = StreamController<bool>.broadcast();

  /// يستدعيه معالج القناة (deep_links.dart) عند «pip».
  static void onModeChanged(bool inPip) => _changes.add(inPip);

  static Future<void> allow(bool allowed) async {
    if (!supported) return;
    try {
      await _ch.invokeMethod('setPip', allowed);
    } catch (_) {}
  }

  static Future<bool> enter() async {
    if (!supported) return false;
    try {
      return await _ch.invokeMethod<bool>('enterPip') ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// هل التطبيق الآن داخل نافذة PiP؟
final pipModeProvider = StreamProvider<bool>((ref) async* {
  yield false;
  yield* Pip._changes.stream;
});
