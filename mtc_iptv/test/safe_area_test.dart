// الجوال (Android): الشريط العلوي لا يُرسم تحت شريط حالة النظام (اختبار المحاكي 2026-10-16).
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/shell/top_bar.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';

import 'app_shell_test.dart' show app, appTest;

void main() {
  appTest('phone: the top bar starts below the system status bar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 120); // 40 dp
    tester.view.viewPadding = const FakeViewPadding(top: 120);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const LocalSettings(), admin: false));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(TopBar)).dy, greaterThanOrEqualTo(40));
  });
}
