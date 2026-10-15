import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/layout/form_factor.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';

import 'app_shell_test.dart' show app;

Future<void> pumpAt(WidgetTester tester, Size size, {FormFactor? ff, LocalSettings s = const LocalSettings()}) async {
  debugFormFactorOverride = ff;
  addTearDown(() => debugFormFactorOverride = null);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app(s));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone: bottom navigation + drawer menu, no title bar', (tester) async {
    await pumpAt(tester, const Size(400, 820), ff: FormFactor.phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.minimize), findsNothing);

    // الدرج يفتح القائمة الكاملة، والاختيار منه يغلقه وينتقل
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    await tester.tap(find.text('الدول').last);
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('V-04'), findsOneWidget);
  });

  testWidgets('phone: bottom tab switches screen', (tester) async {
    await pumpAt(tester, const Size(400, 820), ff: FormFactor.phone);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('البحث')));
    await tester.pumpAndSettle();
    expect(find.text('V-05'), findsOneWidget);
  });

  testWidgets('tablet: sidebar is icons-only and has no collapse button', (tester) async {
    await pumpAt(tester, const Size(1024, 768), ff: FormFactor.tablet);
    expect(find.text('طي القائمة'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    // العناوين تظهر كتلميحات فقط
    expect(find.byTooltip('القنوات'), findsWidgets);
  });

  testWidgets('desktop: keyboard Tab moves focus into the sidebar items', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    expect(focused!.context, isNotNull);
  });
}

