// Shell navigation of all 7 sections and every sub-page, in Arabic (RTL) and English (LTR).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/app/nav.dart';
import 'package:mtc_superadmin/core/tr.dart';

import 'helpers.dart';

String _title(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('page-title'))).data!;

void main() {
  for (final lang in Lang.values) {
    group('lang=${lang.name}', () {
      testWidgets('sidebar opens all 7 sections', (tester) async {
        await pumpApp(tester, lang: lang);
        expect(Nav.sections, hasLength(7));
        final dir = Directionality.of(tester.element(find.byKey(const ValueKey('nav-home'))));
        expect(dir, lang == Lang.ar ? TextDirection.rtl : TextDirection.ltr);
        for (final s in Nav.sections) {
          await tester.tap(find.byKey(ValueKey('nav-${s.id}')));
          await tester.pumpAndSettle();
          expect(_title(tester), s.pages.first.title.of(lang), reason: 'section ${s.id}');
          expect(find.byKey(const ValueKey('help-button')), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('every sub-page opens from the sidebar', (tester) async {
        await pumpApp(tester, lang: lang);
        for (final s in Nav.sections) {
          await tester.tap(find.byKey(ValueKey('nav-${s.id}')));
          await tester.pumpAndSettle();
          for (final p in s.pages.skip(1)) {
            await tester.tap(find.byKey(ValueKey('nav-page-${p.id}')));
            await tester.pumpAndSettle();
            expect(_title(tester), p.title.of(lang), reason: 'page ${p.id}');
            expect(tester.takeException(), isNull, reason: 'page ${p.id}');
          }
        }
      });
    });
  }

  testWidgets('sidebar sits on the right in Arabic and on the left in English', (tester) async {
    await pumpApp(tester, lang: Lang.ar);
    final arX = tester.getCenter(find.byKey(const ValueKey('nav-home'))).dx;
    expect(arX, greaterThan(800));
    await tester.tap(find.byKey(const ValueKey('account-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    final enX = tester.getCenter(find.byKey(const ValueKey('nav-home'))).dx;
    expect(enX, lessThan(800));
    expect(_title(tester), 'Overview');
  });

  testWidgets('shareable routes: /decisions?type=broken and /channels?state=hidden', (tester) async {
    await pumpApp(tester, location: '/decisions?type=broken');
    final chip = tester.widget<ChoiceChip>(find.descendant(of: find.byKey(const ValueKey('type-broken')), matching: find.byType(ChoiceChip)));
    expect(chip.selected, isTrue);
    expect(find.text('أخفِ القناة'), findsWidgets);
  });

  testWidgets('channels list filters through the URL', (tester) async {
    await pumpApp(tester, location: '/channels?state=hidden');
    expect(find.text('الحالة: مخفية'), findsOneWidget);
    expect(find.text('منشورة'), findsNothing); // no published rows in a hidden-only list
  });

  testWidgets('ⓘ opens the Arabic explanation of the service', (tester) async {
    await pumpApp(tester, location: '/channels/trash');
    await tester.tap(find.byKey(const ValueKey('help-button')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('help-dialog')), findsOneWidget);
    expect(find.textContaining('2.5 السلة'), findsOneWidget);
  });

  testWidgets('Ctrl+K command palette jumps to a page', (tester) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('command-palette')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('palette-input')), 'الترقيم');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_title(tester), 'الترقيم');
  });

  testWidgets('bulk action on the channel list goes through preview + reason + stub RPC', (tester) async {
    final app = await pumpApp(tester, location: '/channels?state=review');
    await tester.tap(find.byKey(const ValueKey('sel-shown')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bulk-publish')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('undo-class-snapshot')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('preview-reason')), 'مراجعة أسبوعية');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('preview-run')));
    await tester.pumpAndSettle();
    expect(app.rpc.calls.single.spec.name, 'admin_channels_bulk');
    expect(app.rpc.calls.single.reason, 'مراجعة أسبوعية');
    expect(find.byKey(const ValueKey('result-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-details')), findsOneWidget); // stub: honest failure, never silent
  });
}
