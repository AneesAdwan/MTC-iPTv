// دخول المدير (ADM-H1، D-05): بريد + كلمة مرور، ثم رمز من تطبيق المصادقة (TOTP).
// الحماية الحقيقية على الخادم: is_admin() يشترط admin_users + جلسة aal2. هنا تجربة الاستخدام فقط.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend.dart';
import '../../core/logging/log.dart';

enum AdminStage {
  /// لا يوجد خادم مُعدّ لهذه البيئة
  noBackend,
  signedOut,

  /// حساب مسجّل لكنه ليس المدير
  notAdmin,

  /// المدير بلا عامل تحقق مُفعّل: يجب تسجيل تطبيق المصادقة أولًا
  needsEnroll,

  /// المدير بعامل مُفعّل لكن الجلسة aal1: يجب إدخال الرمز
  needsCode,

  /// جلسة مدير كاملة (aal2)
  admin,
}

class AdminState {
  final AdminStage stage;
  final String? email;
  const AdminState(this.stage, {this.email});
  bool get isAdmin => stage == AdminStage.admin;
}

class TotpEnrollment {
  final String factorId, uri, secret, qrSvg;
  const TotpEnrollment(this.factorId, this.uri, this.secret, this.qrSvg);
}

class AdminAuth {
  final SupabaseClient c;
  AdminAuth(this.c);

  Future<void> signIn(String email, String password) => c.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signOut() => c.auth.signOut();

  /// المرحلة الحالية: من الخادم (admin_status) + عوامل التحقق + مستوى الجلسة.
  Future<AdminState> state() async {
    final user = c.auth.currentUser;
    if (user == null) return const AdminState(AdminStage.signedOut);
    final status = Map<String, dynamic>.from(await c.rpc('admin_status') as Map);
    if (status['is_admin_user'] != true) return AdminState(AdminStage.notAdmin, email: user.email);
    if (status['is_admin'] == true) return AdminState(AdminStage.admin, email: user.email);
    final factors = await c.auth.mfa.listFactors();
    final verified = factors.totp.where((f) => f.status == FactorStatus.verified);
    return AdminState(verified.isEmpty ? AdminStage.needsEnroll : AdminStage.needsCode, email: user.email);
  }

  /// يسجّل تطبيق مصادقة جديدًا (ويحذف أي تسجيل سابق لم يُكمل).
  Future<TotpEnrollment> enrollTotp() async {
    final factors = await c.auth.mfa.listFactors();
    for (final f in factors.all.where((f) => f.status == FactorStatus.unverified)) {
      await c.auth.mfa.unenroll(f.id);
    }
    final r = await c.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MTC-iPTv', friendlyName: 'MTC-iPTv admin');
    final t = r.totp!;
    return TotpEnrollment(r.id, t.uri, t.secret, t.qrCode);
  }

  /// يتحقق من الرمز؛ عند النجاح تصبح الجلسة aal2.
  Future<void> verifyCode(String code, {String? factorId}) async {
    final id = factorId ??
        (await c.auth.mfa.listFactors()).totp.firstWhere((f) => f.status == FactorStatus.verified).id;
    await c.auth.mfa.challengeAndVerify(factorId: id, code: code.trim());
    await c.auth.refreshSession();
    log.info('admin MFA verified');
  }
}

final adminAuthProvider = Provider<AdminAuth?>((ref) {
  final c = ref.watch(supabaseProvider);
  return c == null ? null : AdminAuth(c);
});

/// حالة المدير، تُعاد حسابها مع كل تغيّر في الجلسة.
final adminStateProvider = StreamProvider<AdminState>((ref) async* {
  final auth = ref.watch(adminAuthProvider);
  if (auth == null) {
    yield const AdminState(AdminStage.noBackend);
    return;
  }
  Future<AdminState> safe() async {
    try {
      return await auth.state();
    } catch (e) {
      log.warning('admin state failed', e);
      return const AdminState(AdminStage.signedOut);
    }
  }

  yield await safe();
  await for (final _ in auth.c.auth.onAuthStateChange) {
    yield await safe();
  }
});
