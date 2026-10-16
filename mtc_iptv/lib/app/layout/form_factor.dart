// أنماط التخطيط الأربعة (§6.5). تُحدَّد مرة لكل إطار من حجم النافذة والمنصّة.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum FormFactor { desktop, tablet, phone, tv }

/// يمكن فرض نمط التلفاز للتجربة: --dart-define=MTC_TV=true
const _forceTv = bool.fromEnvironment('MTC_TV');

/// Android TV: يُسأل النظام مرة قبل runApp (MainActivity «isTv»)؛ شاشة 1080p على التلفاز = 960×540 منطقيًا،
/// فالحجم وحده يعطي «جوال» (اختبار محاكي Android TV 16، 2026-10-16).
bool isAndroidTv = false;

Future<void> detectAndroidTv() async {
  if (!Platform.isAndroid) return;
  try {
    isAndroidTv = await const MethodChannel('mtc/instance').invokeMethod<bool>('isTv') ?? false;
  } catch (_) {}
}

/// للاختبارات فقط: فرض نمط معيّن (التابلت والتلفاز لا يظهران على سطح المكتب تلقائيًا).
@visibleForTesting
FormFactor? debugFormFactorOverride;

FormFactor formFactorOf(BuildContext context) {
  if (debugFormFactorOverride != null) return debugFormFactorOverride!;
  if (_forceTv || isAndroidTv) return FormFactor.tv;
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // سطح المكتب: نافذة ضيقة جدًا تتصرف كالجوال (تجربة التخطيطات الأخرى دون جهاز)
    return MediaQuery.sizeOf(context).width < 600 ? FormFactor.phone : FormFactor.desktop;
  }
  return shortest >= 600 ? FormFactor.tablet : FormFactor.phone;
}

extension FormFactorX on FormFactor {
  bool get isDesktop => this == FormFactor.desktop;
  bool get usesSidebar => this == FormFactor.desktop || this == FormFactor.tablet || this == FormFactor.tv;
}
