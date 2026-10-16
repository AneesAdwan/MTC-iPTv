// المرحلة 1 من خطة التحسينات (docs/plans/improvements-2026-10.md): التمرير الأفقي بالماوس (1.1).
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/layout/h_scroller.dart';
import 'package:mtc_iptv/app/theme/theme.dart';

Widget _host() => MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: HScroller(height: 60, itemCount: 30, itemBuilder: (_, i) => SizedBox(width: 80, child: Text('c$i'))),
        ),
      ),
    );

void main() {
  final desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  testWidgets('arrow reveals off-screen items (desktop)', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('c12'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget); // للأمام فقط في البداية
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    for (var k = 0; k < 3; k++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
    }
    expect(find.text('c12'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
  }, skip: !desktop);

  testWidgets('the selected chip stays visible after the screen is rebuilt (was: bar jumped back)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: HScroller(height: 60, itemCount: 60, selectedIndex: 40, itemBuilder: (_, i) => SizedBox(width: 80, child: Text('c$i'))),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('c40'), findsOneWidget);
    expect(tester.getCenter(find.text('c40')).dx, inInclusiveRange(0, 400));
  });

  testWidgets('mouse drag scrolls', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(200, 30), const Offset(-600, 0), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(find.text('c0'), findsNothing);
  });
}
