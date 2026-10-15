// دخول المدير (ADM-H1): بريد + كلمة مرور ← تسجيل تطبيق المصادقة (أول مرة) ← رمز TOTP ← مركز الإدارة.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/config/env.dart';
import '../../../core/logging/log.dart';
import '../../../data/auth/admin_auth.dart';

class AdminLoginScreen extends ConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminStateProvider);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: state.when(
            loading: () => const Padding(padding: EdgeInsets.all(Space.xl), child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (s) => switch (s.stage) {
              AdminStage.noBackend => _Card(icon: Icons.cloud_off_rounded, title: L10n.of(context).adminSignIn, child: Text(L10n.of(context).noBackendBody(Env.name))),
              AdminStage.signedOut => const _SignInForm(),
              AdminStage.notAdmin => _NotAdmin(email: s.email),
              AdminStage.needsEnroll => const _Enroll(),
              AdminStage.needsCode => const _CodeForm(),
              AdminStage.admin => const SizedBox.shrink(), // الموجّه ينقل إلى لوحة المعلومات
            },
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Card({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: c.accent),
          const SizedBox(height: Space.md),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: Space.lg),
          child,
        ]),
      ),
    );
  }
}

/// زر بحالة انتظار ورسالة خطأ موحّدة.
mixin _Busy<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;
  Future<void> guard(Future<void> Function() f, String failMsg) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await f();
    } catch (e) {
      log.warning('admin auth step failed', e);
      if (mounted) setState(() => error = failMsg);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();
  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> with _Busy {
  final email = TextEditingController(), pass = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _submit() {
    final t = L10n.of(context);
    guard(() => ref.read(adminAuthProvider)!.signIn(email.text, pass.text), t.authFailed);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    return _Card(
      icon: Icons.lock_person_rounded,
      title: t.adminSignIn,
      child: AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: t.email),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: pass,
            obscureText: true,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: t.password),
            onSubmitted: (_) => _submit(),
          ),
          if (error != null) ...[const SizedBox(height: Space.md), Text(error!, style: TextStyle(color: c.bad))],
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: busy ? null : _submit, child: Text(t.signIn)),
        ]),
      ),
    );
  }
}

class _NotAdmin extends ConsumerWidget {
  final String? email;
  const _NotAdmin({this.email});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    return _Card(
      icon: Icons.block_rounded,
      title: t.notAdminTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t.notAdminBody, textAlign: TextAlign.center),
        if (email != null) Text(t.signedInAs(email!), textAlign: TextAlign.center, textDirection: TextDirection.ltr),
        const SizedBox(height: Space.lg),
        OutlinedButton(onPressed: () => ref.read(adminAuthProvider)!.signOut(), child: Text(t.signOut)),
      ]),
    );
  }
}

class _Enroll extends ConsumerStatefulWidget {
  const _Enroll();
  @override
  ConsumerState<_Enroll> createState() => _EnrollState();
}

class _EnrollState extends ConsumerState<_Enroll> with _Busy {
  TotpEnrollment? enrollment;
  final code = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(adminAuthProvider)!.enrollTotp().then((e) {
      if (mounted) setState(() => enrollment = e);
    }).catchError((Object e) {
      log.warning('enroll failed', e);
      if (mounted) setState(() => error = '$e');
    });
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final e = enrollment;
    return _Card(
      icon: Icons.phonelink_lock_rounded,
      title: t.mfaEnrollTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t.mfaEnrollBody, style: TextStyle(color: c.textMuted)),
        const SizedBox(height: Space.lg),
        if (e == null && error == null) const Center(child: CircularProgressIndicator()),
        if (e != null) ...[
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(Space.sm),
              child: QrImageView(data: e.uri, size: 200, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: Space.md),
          Text(t.mfaSecret, style: TextStyle(color: c.textMuted, fontSize: 12)),
          Row(children: [
            Expanded(child: SelectableText(e.secret, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: 'Consolas', letterSpacing: 1))),
            IconButton(
              tooltip: t.copied,
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => Clipboard.setData(ClipboardData(text: e.secret)),
            ),
          ]),
          const SizedBox(height: Space.md),
          _CodeField(controller: code, onSubmit: () => guard(() => ref.read(adminAuthProvider)!.verifyCode(code.text, factorId: e.factorId), t.codeFailed)),
        ],
        if (error != null) ...[const SizedBox(height: Space.md), Text(error!, style: TextStyle(color: c.bad))],
        if (e != null) ...[
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: busy ? null : () => guard(() => ref.read(adminAuthProvider)!.verifyCode(code.text, factorId: e.factorId), t.codeFailed),
            child: Text(t.verify),
          ),
        ],
      ]),
    );
  }
}

class _CodeForm extends ConsumerStatefulWidget {
  const _CodeForm();
  @override
  ConsumerState<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends ConsumerState<_CodeForm> with _Busy {
  final code = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    void submit() => guard(() => ref.read(adminAuthProvider)!.verifyCode(code.text), t.codeFailed);
    return _Card(
      icon: Icons.password_rounded,
      title: t.mfaCodeTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t.mfaCodeBody, style: TextStyle(color: c.textMuted)),
        const SizedBox(height: Space.lg),
        _CodeField(controller: code, onSubmit: submit, autofocus: true),
        if (error != null) ...[const SizedBox(height: Space.md), Text(error!, style: TextStyle(color: c.bad))],
        const SizedBox(height: Space.lg),
        FilledButton(onPressed: busy ? null : submit, child: Text(t.verify)),
        TextButton(onPressed: () => ref.read(adminAuthProvider)!.signOut(), child: Text(t.signOut)),
      ]),
    );
  }
}

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool autofocus;
  const _CodeField({required this.controller, required this.onSubmit, this.autofocus = false});
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofillHints: const [AutofillHints.oneTimeCode],
        style: const TextStyle(fontSize: 24, letterSpacing: 8),
        decoration: InputDecoration(labelText: L10n.of(context).mfaCode, counterText: ''),
        onSubmitted: (_) => onSubmit(),
      );
}
