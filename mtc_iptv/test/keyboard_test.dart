// الوصول بلوحة المفاتيح وحدها (§26.2): Tab يتنقّل بين العناصر دون أن يعلق، وEnter يفتح ما عليه التركيز.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'app_shell_test.dart' show appTest;
import 'viewer_test.dart' show seeded, pump;

String routeOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first)).routerDelegate.currentConfiguration.uri.path;

/// هل العنصر المركّز الآن داخل [target] (أو هو نفسه)؟
bool focusWithin(Finder target) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  final targets = target.evaluate().toSet();
  if (targets.contains(ctx)) return true;
  var hit = false;
  ctx.visitAncestorElements((e) {
    if (targets.contains(e)) hit = true;
    return !hit;
  });
  return hit;
}

/// يضغط Tab حتى يصل التركيز إلى [target] (أو يستنفد المحاولات).
Future<bool> tabTo(WidgetTester tester, Finder target, {int max = 80}) async {
  for (var i = 0; i < max; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (focusWithin(target)) return true;
  }
  return false;
}

void main() {
  appTest('Tab moves focus through many distinct controls (no trap)', (tester) async {
    final db = await seeded();
    addTearDown(db.close);
    await pump(tester, db);
    final seen = <FocusNode>{};
    for (var i = 0; i < 40; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final f = FocusManager.instance.primaryFocus;
      if (f != null) seen.add(f);
    }
    expect(seen.length, greaterThan(10), reason: 'focus visited only ${seen.length} nodes');
  });

  appTest('a sidebar entry opens with Enter alone', (tester) async {
    final db = await seeded();
    addTearDown(db.close);
    await pump(tester, db);
    final item = find.ancestor(of: find.text('الإعدادات').first, matching: find.byType(InkWell)).first;
    expect(await tabTo(tester, item), isTrue, reason: 'Settings never received focus via Tab');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(routeOf(tester), '/settings');
  });

  // فتح المشغّل نفسه يحتاج libmpv (غير متاح في بيئة الاختبار)، فنثبت هنا أن البطاقة تصلها لوحة المفاتيح
  // وأنها قابلة للتفعيل؛ وتفعيل InkWell بـ Enter مُثبت في الاختبار السابق.
  appTest('a channel card is reachable with Tab and activatable', (tester) async {
    final db = await seeded();
    addTearDown(db.close);
    await pump(tester, db);
    final card = find.ancestor(of: find.text('الجزيرة').first, matching: find.byType(InkWell)).first;
    expect(await tabTo(tester, card), isTrue, reason: 'no channel card received focus via Tab');
    expect(tester.widget<InkWell>(card).onTap, isNotNull);
  });
}
