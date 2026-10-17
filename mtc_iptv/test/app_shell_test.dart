import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:mtc_iptv/app/app.dart';
import 'package:mtc_iptv/app/l10n/app_localizations_ar.dart';
import 'package:mtc_iptv/app/l10n/app_localizations_en.dart';
import 'package:mtc_iptv/app/screens.dart';
import 'package:mtc_iptv/app/shell/sidebar.dart';
import 'package:mtc_iptv/core/backend/backend.dart';
import 'package:mtc_iptv/core/config/env.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/auth/admin_auth.dart';
import 'package:mtc_iptv/features/admin/analytics_screen.dart';

/// [admin]: يعرض قسم الإدارة (جلسة مدير كاملة) دون خادم. [superAdmin]: نسخة برنامج الإدارة (افتراضيًا)،
/// أو `false` = تطبيق المشاهدين المنشور (بلا أي مدخل للإدارة).
Widget app(LocalSettings s, {bool admin = true, bool superAdmin = true}) {
  Env.superAdmin = superAdmin;
  return ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(s),
        // تطبيق المشاهدين: حالة الجلسة الحقيقية تمر عبر بوابة Env.superAdmin داخل isAdminProvider
        if (superAdmin)
          isAdminProvider.overrideWithValue(admin)
        else
          adminStateProvider.overrideWith((ref) => Stream.value(AdminState(admin ? AdminStage.admin : AdminStage.signedOut, email: 'owner@example.com'))),
        catalogDbProvider.overrideWith((ref) {
          final db = CatalogDb(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MtcApp(),
    );
}

/// testWidgets + إزالة الشجرة في النهاية: استعلامات drift المراقَبة تُغلق بمؤقت صفري عند الإلغاء،
/// فنُفرغ الشجرة وننفّذ المؤقت داخل الاختبار بدل أن يبقى معلّقًا.
void appTest(String name, Future<void> Function(WidgetTester) body, {Object? tags}) => testWidgets(name, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    }, tags: tags);

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
    appTest('Arabic is RTL by default and shows Arabic titles', (tester) async {
      await pumpApp(tester, const LocalSettings());
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.rtl);
      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('الإدارة'), findsOneWidget);
    });

    appTest('English is LTR and shows English titles', (tester) async {
      await pumpApp(tester, const LocalSettings(locale: Locale('en')));
      final dir = Directionality.of(tester.element(find.byType(Scaffold).first));
      expect(dir, TextDirection.ltr);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Admin'), findsOneWidget);
    });

    appTest('light theme builds', (tester) async {
      await pumpApp(tester, const LocalSettings(themeMode: ThemeMode.light));
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    });
  });

  group('admin guard (UX only; the server enforces is_admin + MFA)', () {
    appTest('non-admin sees only the admin sign-in entry, not the admin sections', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const LocalSettings(), admin: false));
      await tester.pumpAndSettle();
      expect(find.text('دخول المدير'), findsOneWidget);
      expect(find.text('لوحة المعلومات'), findsNothing);
    });

    appTest('non-admin opening an admin route lands on the sign-in screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const LocalSettings(), admin: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('دخول المدير'));
      await tester.pumpAndSettle();
      // بلا خادم في الاختبار: شاشة الدخول تشرح أن البيئة بلا خادم
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });
  });

  group('viewer apps have no admin entry (owner 2026-10-17: SuperAdmin is the only way in)', () {
    Future<void> pumpViewer(WidgetTester tester, {bool admin = false}) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const LocalSettings(), admin: admin, superAdmin: false));
      await tester.pumpAndSettle();
    }

    appTest('no admin sign-in, no admin section, no account menu', (tester) async {
      await pumpViewer(tester);
      expect(find.text('دخول المدير'), findsNothing);
      expect(find.text('الإدارة'), findsNothing);
      expect(find.byTooltip(L10nAr().accountMenu), findsNothing);
    });

    appTest('even an existing admin session shows nothing admin', (tester) async {
      await pumpViewer(tester, admin: true);
      expect(find.text('لوحة المعلومات'), findsNothing);
      expect(find.text('الإدارة'), findsNothing);
    });

    appTest('admin routes redirect home', (tester) async {
      await pumpViewer(tester);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final p in ['/admin/login', '/admin/dashboard', '/admin/channel/x']) {
        router.go(p);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home', reason: p);
      }
    });
  });

  group('navigation', () {    appTest('tapping a sidebar item opens its screen', (tester) async {
      await pumpApp(tester, const LocalSettings());
      // القائمة كسولة: نمرّرها حتى يظهر العنصر
      await tester.scrollUntilVisible(find.text('التحليلات'), 200, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120)); // لا يغطيه زر طي القائمة
      await tester.pumpAndSettle();
      await tester.tap(find.text('التحليلات'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
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
