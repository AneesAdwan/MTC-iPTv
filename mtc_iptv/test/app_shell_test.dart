import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:mtc_iptv/app/app.dart';
import 'package:mtc_iptv/app/l10n/app_localizations_ar.dart';
import 'package:mtc_iptv/app/l10n/app_localizations_en.dart';
import 'package:mtc_iptv/app/screens.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';

Widget app(LocalSettings s) => ProviderScope(
      overrides: [initialSettingsProvider.overrideWithValue(s)],
      child: const MtcApp(),
    );

Future<void> pumpApp(WidgetTester tester, LocalSettings s) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app(s));
  await tester.pumpAndSettle();
}

void main() {
  group('screen registry (Appendix B)', () {
    test('ids and paths are unique', () {
      expect(screens.map((s) => s.id).toSet().length, screens.length);
      expect(screens.map((s) => s.path).toSet().length, screens.length);
    });

    test('39 admin screens + 11 viewer screens (V-01 splash is not routed)', () {
      expect(screens.where((s) => s.group.isAdmin).length, 39);
      expect(screens.where((s) => !s.group.isAdmin).length, 11);
    });

    test('every screen has a title in Arabic and English', () {
      for (final s in screens) {
        expect(s.title(L10nAr()), isNotEmpty, reason: s.id);
        expect(s.title(L10nEn()), isNotEmpty, reason: s.id);
      }
    });

    test('screenForPath distinguishes /admin/channels from /admin/channel/<id>', () {
      expect(screenForPath('/admin/channels')!.id, 'ADM-B1');
      expect(screenForPath('/admin/channel/123')!.id, 'ADM-B2');
      expect(screenForPath('/nope'), isNull);
    });
  });

  group('direction & language (§6.4)', () {
    testWidgets('Arabic is RTL by default and shows Arabic titles', (tester) async {
      await pumpApp(tester, const LocalSettings());
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.rtl);
      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('الإدارة'), findsOneWidget);
    });

    testWidgets('English is LTR and shows English titles', (tester) async {
      await pumpApp(tester, const LocalSettings(locale: Locale('en')));
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.ltr);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('light theme builds', (tester) async {
      await pumpApp(tester, const LocalSettings(themeMode: ThemeMode.light));
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    });
  });

  group('navigation', () {
    testWidgets('tapping a sidebar item opens its placeholder with the screen id', (tester) async {
      await pumpApp(tester, const LocalSettings());
      // القائمة كسولة: نمرّرها حتى يظهر العنصر
      await tester.scrollUntilVisible(find.text('صحة البث'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('صحة البث'));
      await tester.pumpAndSettle();
      expect(find.text('ADM-D4'), findsOneWidget);
    });
  });

  group('command palette search (Arabic folding)', () {
    // نفس منطق البحث في لوحة الأوامر: كل كلمة مطبّعة يجب أن تظهر في نص الشاشة المطبّع
    bool matches(String query, ScreenDef s) {
      final hay = matchKey('${s.title(L10nAr())} ${s.title(L10nEn())} ${s.id}');
      return query.trim().split(RegExp(r'\s+')).map(matchKey).every(hay.contains);
    }

    ScreenDef byId(String id) => screens.firstWhere((s) => s.id == id);

    test('hamza-less Arabic finds the screen', () => expect(matches('الاعدادات العامه', byId('ADM-G3')), isTrue));
    test('English finds the screen', () => expect(matches('stream health', byId('ADM-D4')), isTrue));
    test('screen id finds the screen', () => expect(matches('adm-b1', byId('ADM-B1')), isTrue));
    test('unrelated text does not match', () => expect(matches('تحليلات', byId('ADM-B1')), isFalse));
  });
}
