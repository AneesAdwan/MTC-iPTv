// اختبارات الصور (§26.1): تثبّت شكل الهيكل بالعربية والإنجليزية وبالمظهرين.
// تُحدَّث عمدًا بعد تغيير مقصود في الشكل:  flutter test --update-goldens --tags golden
// موسومة golden ولا تعمل في CI (الخطوط ترسم بفروق بكسل بين الأجهزة).
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/layout/form_factor.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';

import 'app_shell_test.dart' show app;

Future<void> loadFonts() async {
  final plex = FontLoader('IBMPlexSansArabic');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    plex.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$w.ttf'));
  }
  await plex.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
    }
  }
}

void main() {
  setUpAll(loadFonts);

  final cases = {
    'desktop_ar_dark': (const Size(1280, 800), FormFactor.desktop, const LocalSettings()),
    'desktop_en_dark': (const Size(1280, 800), FormFactor.desktop, const LocalSettings(locale: Locale('en'))),
    'desktop_ar_light': (const Size(1280, 800), FormFactor.desktop, const LocalSettings(themeMode: ThemeMode.light)),
    'desktop_ar_collapsed': (const Size(1280, 800), FormFactor.desktop, const LocalSettings(sidebarCollapsed: true)),
    'tablet_ar_dark': (const Size(1024, 768), FormFactor.tablet, const LocalSettings()),
    'phone_ar_dark': (const Size(400, 820), FormFactor.phone, const LocalSettings()),
    'phone_en_light': (const Size(400, 820), FormFactor.phone, const LocalSettings(locale: Locale('en'), themeMode: ThemeMode.light)),
  };

  for (final MapEntry(key: name, value: (size, ff, s)) in cases.entries) {
    testWidgets(name, (tester) async {
      debugFormFactorOverride = ff;
      addTearDown(() => debugFormFactorOverride = null);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(s));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    });
  }
}
