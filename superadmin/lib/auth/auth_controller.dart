// Session state for the whole program, re-read from the server:
//  * before every navigation into an admin screen (router redirect → recheck()),
//  * whenever the client session changes (sign in/out, token refresh, revocation),
//  * on a heartbeat while signed in,
//  * whenever any admin_* call is rejected for auth reasons (reportAuthRejection()).
// If the server stops confirming `is_admin`, the router returns to sign-in immediately.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import 'admin_auth.dart';

class AuthController extends ChangeNotifier {
  final AdminAuthGateway gateway;
  final Duration? heartbeat;

  AuthController(this.gateway, {this.heartbeat});

  AdminStage _stage = AdminStage.signedOut;
  AdminStatus? _status;
  bool _busy = false;
  bool _started = false;
  UiError? _error;
  TotpEnrollment? _enrollment;
  Future<AdminStage>? _inFlight;
  StreamSubscription<void>? _sub;
  Timer? _timer;

  AdminStage get stage => _stage;
  bool get isAdmin => _stage == AdminStage.admin;
  bool get busy => _busy;
  bool get started => _started;
  UiError? get error => _error;
  TotpEnrollment? get enrollment => _enrollment;
  String? get email => gateway.email;
  String get aal => _status?.aal ?? 'aal1';

  /// Last time the server confirmed the current stage. A separate notifier on purpose: the router listens
  /// to this controller, and re-verifying must not re-trigger navigation unless the stage changed.
  final ValueNotifier<DateTime?> lastVerified = ValueNotifier(null);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!gateway.configured) {
      _set(AdminStage.noBackend);
      return;
    }
    _sub = gateway.sessionChanges.listen((_) => unawaited(recheck()));
    if (heartbeat != null) {
      _timer = Timer.periodic(heartbeat!, (_) {
        if (_stage == AdminStage.admin) unawaited(recheck());
      });
    }
    await recheck();
  }

  /// Ask the server again. Concurrent callers share one request.
  Future<AdminStage> recheck() {
    if (!gateway.configured) return Future.value(_set(AdminStage.noBackend));
    return _inFlight ??= _recheck().whenComplete(() => _inFlight = null);
  }

  Future<AdminStage> _recheck() async {
    if (!gateway.hasSession) {
      _status = null;
      _enrollment = null;
      return _set(AdminStage.signedOut);
    }
    try {
      final status = await gateway.fetchStatus();
      _status = status;
      bool? hasTotp;
      if (status.isAdminUser && !status.isAdmin) hasTotp = await gateway.hasVerifiedTotp();
      lastVerified.value = DateTime.now();
      return _set(resolveStage(hasSession: true, status: status, hasVerifiedTotp: hasTotp));
    } catch (e, st) {
      if (isAuthRejection(e)) {
        // Session no longer accepted (expired / revoked): drop it and go back to sign-in.
        try {
          await gateway.signOut();
        } catch (_) {}
        _error = describeError(e, st);
        return _set(AdminStage.signedOut);
      }
      _error = describeError(e, st);
      return _set(AdminStage.unreachable);
    }
  }

  /// Any admin_* call rejected with an auth error lands here.
  void reportAuthRejection() => unawaited(recheck());

  Future<void> signIn(String email, String password) => _run(() async {
    await gateway.signIn(email, password);
    await recheck();
  });

  Future<void> signOut() => _run(() async {
    try {
      await gateway.signOut();
    } finally {
      _status = null;
      _enrollment = null;
      _set(AdminStage.signedOut);
    }
  });

  Future<void> startEnrollment() => _run(() async {
    _enrollment = await gateway.enrollTotp();
  });

  Future<void> verifyCode(String code) => _run(() async {
    await gateway.verifyTotp(code, factorId: _enrollment?.factorId);
    _enrollment = null;
    await recheck();
  });

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() body) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await body();
    } catch (e, st) {
      _error = describeError(e, st);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  AdminStage _set(AdminStage s) {
    final changed = s != _stage;
    _stage = s;
    if (changed) notifyListeners();
    return s;
  }

  @override
  void dispose() {
    _timer?.cancel();
    lastVerified.dispose();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

final authControllerProvider = Provider<AuthController>((ref) => throw UnimplementedError('override authControllerProvider'));
