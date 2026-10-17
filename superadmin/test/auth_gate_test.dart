// Sign-in gating: the program shows admin screens only when the SERVER says is_admin.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/auth/admin_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers.dart';

void main() {
  group('resolveStage (pure)', () {
    test('no session → signedOut', () => expect(resolveStage(hasSession: false), AdminStage.signedOut));
    test('no server answer → unreachable (never guess)', () => expect(resolveStage(hasSession: true), AdminStage.unreachable));
    test('not admin', () => expect(resolveStage(hasSession: true, status: notAdminStatus), AdminStage.notAdmin));
    test('aal1 with TOTP → needsCode', () => expect(resolveStage(hasSession: true, status: aal1Status, hasVerifiedTotp: true), AdminStage.needsCode));
    test('aal1 without TOTP → needsEnroll', () => expect(resolveStage(hasSession: true, status: aal1Status, hasVerifiedTotp: false), AdminStage.needsEnroll));
    test('server is_admin → admin', () => expect(resolveStage(hasSession: true, status: adminStatus), AdminStage.admin));
    test('client cannot promote itself: aal2 claim without is_admin is not admin', () {
      const forged = AdminStatus(isAdminUser: true, aal: 'aal2', isAdmin: false);
      expect(resolveStage(hasSession: true, status: forged, hasVerifiedTotp: true), isNot(AdminStage.admin));
    });
    test('AdminStatus.fromJson tolerates junk', () {
      final s = AdminStatus.fromJson({'is_admin_user': 'yes', 'is_admin': 1});
      expect(s.isAdminUser, false);
      expect(s.isAdmin, false);
      expect(s.aal, 'aal1');
    });
  });

  testWidgets('signed out: deep link goes to sign-in, then back to the link after a full admin sign-in', (tester) async {
    final gw = FakeGateway(status: aal1Status);
    await pumpApp(tester, gateway: gw, location: '/channels?state=hidden');
    expect(find.byKey(const ValueKey('stage-signedOut')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('signin-email')), 'admin@mtc.test');
    await tester.enterText(find.byKey(const ValueKey('signin-password')), 'secret');
    await tester.tap(find.byKey(const ValueKey('signin-submit')));
    await tester.pumpAndSettle();
    // Server: admin user but aal1 → code required, still no admin screens.
    expect(find.byKey(const ValueKey('stage-needsCode')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('signin-code')), '123456');
    await tester.tap(find.byKey(const ValueKey('signin-verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('filter-state')), findsOneWidget); // landed on /channels?state=hidden
  });

  testWidgets('wrong password shows a clear error with retry + details', (tester) async {
    await pumpApp(tester, gateway: FakeGateway(status: aal1Status));
    await tester.enterText(find.byKey(const ValueKey('signin-email')), 'a@b.c');
    await tester.enterText(find.byKey(const ValueKey('signin-password')), 'bad');
    await tester.tap(find.byKey(const ValueKey('signin-submit')));
    await tester.pumpAndSettle();
    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);
    expect(find.byKey(const ValueKey('error-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('error-details')), findsOneWidget);
  });

  testWidgets('not an admin: blocked with sign-out only', (tester) async {
    await pumpApp(tester, gateway: FakeGateway(status: notAdminStatus, session: true));
    expect(find.byKey(const ValueKey('stage-notAdmin')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('signin-signout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stage-signedOut')), findsOneWidget);
  });

  testWidgets('aal1 admin session: code screen, wrong code stays locked', (tester) async {
    await pumpApp(tester, gateway: FakeGateway(status: aal1Status, session: true));
    expect(find.byKey(const ValueKey('stage-needsCode')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('signin-code')), '000000');
    await tester.tap(find.byKey(const ValueKey('signin-verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
    expect(find.byKey(const ValueKey('error-retry')), findsOneWidget);
  });

  testWidgets('first time: enrollment shows a QR code, then verification opens the shell', (tester) async {
    await pumpApp(tester, gateway: FakeGateway(status: aal1Status, session: true, totp: false));
    expect(find.byKey(const ValueKey('stage-needsEnroll')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('signin-enroll-start')));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('signin-code')), '654321');
    await tester.tap(find.byKey(const ValueKey('signin-verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
  });

  testWidgets('admin: shell opens; every navigation re-asks the server', (tester) async {
    final app = await pumpApp(tester);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    final before = app.gateway.statusCalls;
    await tester.tap(find.byKey(const ValueKey('nav-channels')));
    await tester.pumpAndSettle();
    expect(app.gateway.statusCalls, greaterThan(before));
  });

  testWidgets('revoked / expired session returns to sign-in immediately', (tester) async {
    final app = await pumpApp(tester);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    // The server revoked the session: admin_status no longer confirms is_admin.
    app.gateway.status = aal1Status;
    app.gateway.emit();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
    expect(find.byKey(const ValueKey('stage-needsCode')), findsOneWidget);

    // Session dropped entirely.
    app.gateway.session = false;
    app.gateway.emit();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stage-signedOut')), findsOneWidget);
  });

  testWidgets('server unreachable: admin screens stay closed', (tester) async {
    final gw = FakeGateway(status: adminStatus, session: true)..statusError = Exception('offline');
    await pumpApp(tester, gateway: gw);
    expect(find.byKey(const ValueKey('stage-unreachable')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
    gw.statusError = null;
    await tester.tap(find.byKey(const ValueKey('error-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
  });

  testWidgets('sign out from the account menu', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('account-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-signout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stage-signedOut')), findsOneWidget);
  });
}
