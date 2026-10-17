import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_superadmin/app/app.dart';
import 'package:mtc_superadmin/auth/admin_auth.dart';
import 'package:mtc_superadmin/auth/auth_controller.dart';
import 'package:mtc_superadmin/core/prefs.dart';
import 'package:mtc_superadmin/core/tr.dart';
import 'package:mtc_superadmin/data/providers.dart';
import 'package:mtc_superadmin/data/repositories_impl.dart';
import 'package:mtc_superadmin/data/rpc/admin_rpc.dart';
import 'package:supabase/supabase.dart';

const adminStatus = AdminStatus(isAdminUser: true, aal: 'aal2', isAdmin: true);
const aal1Status = AdminStatus(isAdminUser: true, aal: 'aal1', isAdmin: false);
const notAdminStatus = AdminStatus(isAdminUser: false, aal: 'aal2', isAdmin: false);

/// Stands in for Supabase. Every answer is "the server's".
class FakeGateway implements AdminAuthGateway {
  AdminStatus? status;
  bool session;
  bool totp;
  Object? statusError;
  int statusCalls = 0;
  final _changes = StreamController<void>.broadcast();

  FakeGateway({this.status, this.session = false, this.totp = true});

  void emit() => _changes.add(null);

  @override
  bool get configured => true;
  @override
  bool get hasSession => session;
  @override
  String? get email => session ? 'admin@mtc.test' : null;
  @override
  Stream<void> get sessionChanges => _changes.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (password == 'bad') throw const AuthException('Invalid login credentials');
    session = true;
  }

  @override
  Future<void> signOut() async => session = false;

  @override
  Future<AdminStatus> fetchStatus() async {
    statusCalls++;
    if (statusError != null) throw statusError!;
    return status!;
  }

  @override
  Future<bool> hasVerifiedTotp() async => totp;

  @override
  Future<TotpEnrollment> enrollTotp() async =>
      const TotpEnrollment(factorId: 'f1', uri: 'otpauth://totp/MTC-iPTv:admin@mtc.test?secret=JBSWY3DPEHPK3PXP&issuer=MTC-iPTv', secret: 'JBSWY3DPEHPK3PXP');

  @override
  Future<void> verifyTotp(String code, {String? factorId}) async {
    if (code == '000000') throw const AuthException('Invalid TOTP code entered');
    totp = true;
    status = adminStatus;
  }
}

Future<({FakeGateway gateway, AuthController auth, StubAdminRpc rpc, PrefsController prefs})> pumpApp(
  WidgetTester tester, {
  FakeGateway? gateway,
  Lang lang = Lang.ar,
  String location = '/home',
}) async {
  setSampleLatency(Duration.zero);
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final gw = gateway ?? FakeGateway(status: adminStatus, session: true);
  final auth = AuthController(gw);
  final rpc = StubAdminRpc();
  final prefs = PrefsController(MemoryPrefsStore({'lang': lang.name}));
  await auth.start();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), authControllerProvider.overrideWithValue(auth), adminRpcProvider.overrideWithValue(rpc)],
      child: SuperAdminApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return (gateway: gw, auth: auth, rpc: rpc, prefs: prefs);
}
