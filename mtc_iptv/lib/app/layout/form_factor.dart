// أنماط التخطيط الأربعة (§6.5). تُحدَّد مرة لكل إطار من حجم النافذة والمنصّة.
import 'dart:io';

import 'package:flutter/widgets.dart';

enum FormFactor { desktop, tablet, phone, tv }

/// Android TV يُكتشف لاحقًا (R2) عبر قناة منصّة؛ حتى ذلك يمكن فرضه بـ --dart-define=MTC_TV=true للتجربة.
const _forceTv = bool.fromEnvironment('MTC_TV');

/// للاختبارات فقط: فرض نمط معيّن (التابلت والتلفاز لا يظهران على سطح المكتب تلقائيًا).
@visibleForTesting
FormFactor? debugFormFactorOverride;

FormFactor formFactorOf(BuildContext context) {
  if (debugFormFactorOverride != null) return debugFormFactorOverride!;
  if (_forceTv) return FormFactor.tv;
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
