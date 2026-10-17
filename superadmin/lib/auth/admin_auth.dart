// Admin sign-in: email + password, then a code from an authenticator app (TOTP).
//
// Rule 1 of the plan (§4, §9.1): the program NEVER decides it is authorized. The stage shown to the
// user is derived only from the server's answer to `admin_status()`:
//   { is_admin_user: bool, aal: 'aal1'|'aal2', is_admin: bool }
// plus the list of enrolled TOTP factors (to choose between "enroll" and "enter code"). The server
// enforces the same checks on every admin_* call; this file only drives the user experience.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

/// What the server says about the current session.
@immutable
class AdminStatus {
  final bool isAdminUser;
  final String aal;
  final bool isAdmin;
  const AdminStatus({required this.isAdminUser, required this.aal, required this.isAdmin});

  factory AdminStatus.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return AdminStatus(isAdminUser: m['is_admin_user'] == true, aal: m['aal'] is String ? m['aal'] as String : 'aal1', isAdmin: m['is_admin'] == true);
  }
}

enum AdminStage {
  /// No Supabase project configured for this build.
  noBackend,

  /// Nobody signed in.
  signedOut,

  /// Signed in, but the server says this account is not an admin.
  notAdmin,

  /// Admin account without a verified authenticator: enroll first.
  needsEnroll,

  /// Admin account with an authenticator, session still aal1: enter the code.
  needsCode,

  /// Server confirmed a full admin session (is_admin = true).
  admin,

  /// The server could not be asked. We do not guess: admin screens stay closed.
  unreachable,
}

/// Pure decision from server facts → stage. Kept separate so it is unit-tested.
AdminStage resolveStage({required bool hasSession, AdminStatus? status, bool? hasVerifiedTotp}) {
  if (!hasSession) return AdminStage.signedOut;
  if (status == null) return AdminStage.unreachable;
  if (!status.isAdminUser) return AdminStage.notAdmin;
  if (status.isAdmin) return AdminStage.admin;
  return (hasVerifiedTotp ?? false) ? AdminStage.needsCode : AdminStage.needsEnroll;
}

@immutable
class TotpEnrollment {
  final String factorId, uri, secret;
  const TotpEnrollment({required this.factorId, required this.uri, required this.secret});
}

/// Everything the UI needs from the auth backend. Supabase in the program, fakes in tests.
abstract interface class AdminAuthGateway {
  bool get configured;
  bool get hasSession;
  String? get email;

  /// Fires whenever the session changes (sign in/out, refresh, revocation detected by the client).
  Stream<void> get sessionChanges;

  Future<void> signIn(String email, String password);
  Future<void> signOut();

  /// RPC `admin_status()`.
  Future<AdminStatus> fetchStatus();
  Future<bool> hasVerifiedTotp();
  Future<TotpEnrollment> enrollTotp();
  Future<void> verifyTotp(String code, {String? factorId});
}

/// Build without a backend (e.g. staging not set up yet).
class NoBackendGateway implements AdminAuthGateway {
  @override
  bool get configured => false;
  @override
  bool get hasSession => false;
  @override
  String? get email => null;
  @override
  Stream<void> get sessionChanges => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async => throw StateError('no backend');
  @override
  Future<void> signOut() async {}
  @override
  Future<AdminStatus> fetchStatus() async => throw StateError('no backend');
  @override
  Future<bool> hasVerifiedTotp() async => false;
  @override
  Future<TotpEnrollment> enrollTotp() async => throw StateError('no backend');
  @override
  Future<void> verifyTotp(String code, {String? factorId}) async => throw StateError('no backend');
}

class SupabaseAdminAuthGateway implements AdminAuthGateway {
  final SupabaseClient client;
  SupabaseAdminAuthGateway(this.client);

  @override
  bool get configured => true;
  @override
  bool get hasSession => client.auth.currentSession != null;
  @override
  String? get email => client.auth.currentUser?.email;

  @override
  Stream<void> get sessionChanges => client.auth.onAuthStateChange.map((_) {});

  @override
  Future<void> signIn(String email, String password) => client.auth.signInWithPassword(email: email.trim(), password: password);

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<AdminStatus> fetchStatus() async => AdminStatus.fromJson(await client.rpc<Object?>('admin_status'));

  @override
  Future<bool> hasVerifiedTotp() async {
    final f = await client.auth.mfa.listFactors();
    return f.totp.any((x) => x.status == FactorStatus.verified);
  }

  @override
  Future<TotpEnrollment> enrollTotp() async {
    // Remove abandoned (unverified) enrollments first, then start a fresh one.
    final factors = await client.auth.mfa.listFactors();
    for (final f in factors.all.where((f) => f.status == FactorStatus.unverified)) {
      await client.auth.mfa.unenroll(f.id);
    }
    final r = await client.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MTC-iPTv', friendlyName: 'MTC-iPTv SuperAdmin');
    final t = r.totp!;
    return TotpEnrollment(factorId: r.id, uri: t.uri, secret: t.secret);
  }

  @override
  Future<void> verifyTotp(String code, {String? factorId}) async {
    final id = factorId ?? (await client.auth.mfa.listFactors()).totp.firstWhere((f) => f.status == FactorStatus.verified).id;
    await client.auth.mfa.challengeAndVerify(factorId: id, code: code.trim());
    await client.auth.refreshSession();
  }
}

/// True when an error means "your session is no longer accepted" (expired, revoked, not admin).
/// Used by the RPC layer to send the user back to sign-in instead of showing a generic failure.
bool isAuthRejection(Object e) {
  if (e is AuthException) return true;
  if (e is PostgrestException) {
    return e.code == '42501' || e.code == 'PGRST301' || e.code == 'PGRST302' || e.code == '401' || e.code == '403';
  }
  return false;
}
