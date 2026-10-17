// Sign-in: email + password → (first time) authenticator enrollment with QR → TOTP code.
// What is shown is driven only by the server's admin_status answer (see admin_auth.dart).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/theme/tokens.dart';
import '../core/env.dart';
import '../core/prefs.dart';
import '../core/tr.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'admin_auth.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final prefs = ref.watch(prefsProvider);
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -1.2), radius: 1.4, colors: [c.accent.withValues(alpha: 0.10), c.bg]),
              ),
            ),
          ),
          PositionedDirectional(
            top: Space.lg,
            end: Space.lg,
            child: Row(
              children: [
                TextButton(key: const ValueKey('signin-lang'), onPressed: prefs.toggleLang, child: Text(context.lang == Lang.ar ? 'English' : 'العربية')),
                IconButton(
                  tooltip: context.tr(const Tr('الوضع الفاتح/الداكن', 'Light/dark')),
                  onPressed: prefs.toggleTheme,
                  icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(Space.xxl),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: c.line),
                  ),
                  child: ListenableBuilder(
                    listenable: auth,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Brand(),
                        const SizedBox(height: Space.xl),
                        _StageBody(auth: auth),
                        if (auth.error != null) ...[
                          const SizedBox(height: Space.lg),
                          ErrorState(error: auth.error!, onRetry: auth.stage == AdminStage.unreachable ? auth.recheck : auth.clearError, compact: true),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: Space.md,
            start: Space.lg,
            child: Text('${Env.appTitle} ${Env.version} · ${Env.name}', style: TextStyle(color: c.textDim, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const BrandMark(size: 56),
      const SizedBox(height: Space.sm),
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          'MTC-iPTv',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
        ),
      ),
      Text(
        'SuperAdmin',
        style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
    ],
  );
}

class _StageBody extends StatelessWidget {
  final AuthController auth;
  const _StageBody({required this.auth});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget msg(Tr title, Tr body, {Widget? action, IconData icon = Icons.info_outline, Tone tone = Tone.info}) => Column(
      key: ValueKey('stage-${auth.stage.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 36, color: c.tone(tone)),
        const SizedBox(height: Space.md),
        Text(
          context.tr(title),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Space.sm),
        Text(
          context.tr(body),
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textMuted),
        ),
        if (action != null) ...[const SizedBox(height: Space.lg), action],
      ],
    );
    final signOut = OutlinedButton(
      key: const ValueKey('signin-signout'),
      onPressed: auth.busy ? null : auth.signOut,
      child: Text(context.tr(const Tr('تسجيل الخروج', 'Sign out'))),
    );

    if (!auth.started) return const SizedBox(height: 120, child: LoadingState());
    return switch (auth.stage) {
      AdminStage.noBackend => msg(
        const Tr('ما في خادم مُعدّ', 'No server configured'),
        const Tr('هالنسخة مبنية بدون رابط Supabase. ابنيها لبيئة فيها خادم.', 'This build has no Supabase URL. Build it for an environment with a server.'),
        icon: Icons.cloud_off,
        tone: Tone.warn,
      ),
      AdminStage.signedOut => _PasswordForm(auth: auth),
      AdminStage.notAdmin => msg(
        const Tr('هالحساب مش حساب مدير', 'This account is not an admin'),
        Tr(
          'الخادم رد إنه ${auth.email ?? ''} مش مسجّل كمدير. ما في وصول للوحة.',
          'The server says ${auth.email ?? ''} is not registered as an admin. No access.',
        ),
        icon: Icons.block,
        tone: Tone.bad,
        action: signOut,
      ),
      AdminStage.needsEnroll => _Enroll(auth: auth, signOut: signOut),
      AdminStage.needsCode => _CodeForm(auth: auth, signOut: signOut),
      AdminStage.admin => msg(
        const Tr('تمّ التحقق', 'Verified'),
        const Tr('جاري فتح اللوحة…', 'Opening the dashboard…'),
        icon: Icons.verified_user_outlined,
        tone: Tone.ok,
      ),
      AdminStage.unreachable => msg(
        const Tr('تعذّر سؤال الخادم', 'Could not ask the server'),
        const Tr('ما منفتح اللوحة بدون تأكيد من الخادم. أعد المحاولة.', 'The dashboard stays closed without the server\'s confirmation. Retry.'),
        icon: Icons.wifi_off,
        tone: Tone.warn,
        action: signOut,
      ),
    };
  }
}

class _PasswordForm extends StatefulWidget {
  final AuthController auth;
  const _PasswordForm({required this.auth});
  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.auth.busy || _email.text.trim().isEmpty || _password.text.isEmpty) return;
    widget.auth.signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      key: const ValueKey('stage-signedOut'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(const Tr('دخول المدير', 'Admin sign-in')), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.lg),
        TextField(
          key: const ValueKey('signin-email'),
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: context.tr(const Tr('البريد الإلكتروني', 'Email'))),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Space.md),
        TextField(
          key: const ValueKey('signin-password'),
          controller: _password,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: context.tr(const Tr('كلمة المرور', 'Password')),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: Space.lg),
        FilledButton(
          key: const ValueKey('signin-submit'),
          onPressed: widget.auth.busy ? null : _submit,
          child: widget.auth.busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr(const Tr('متابعة', 'Continue'))),
        ),
        const SizedBox(height: Space.sm),
        Text(
          context.tr(const Tr('بعد كلمة المرور بيطلب رمز من تطبيق التحقق (خطوتين).', 'After the password you will be asked for an authenticator code.')),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textDim, fontSize: 12),
        ),
      ],
    ),
  );
}

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _CodeField({required this.controller, required this.onSubmit});
  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('signin-code'),
    controller: controller,
    autofocus: true,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLength: 6,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
    decoration: InputDecoration(counterText: '', hintText: '000000', labelText: context.tr(const Tr('رمز التحقق (6 أرقام)', 'Verification code (6 digits)'))),
    onSubmitted: (_) => onSubmit(),
  );
}

class _CodeForm extends StatefulWidget {
  final AuthController auth;
  final Widget signOut;
  const _CodeForm({required this.auth, required this.signOut});
  @override
  State<_CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends State<_CodeForm> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.length == 6 && !widget.auth.busy) widget.auth.verifyCode(_code.text);
  }

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('stage-needsCode'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.tr(const Tr('التحقق بخطوتين', 'Two-step verification')), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: Space.xs),
      Text(
        context.tr(
          Tr(
            'افتح تطبيق التحقق واكتب الرمز لحساب ${widget.auth.email ?? ''}.',
            'Open your authenticator app and enter the code for ${widget.auth.email ?? ''}.',
          ),
        ),
        style: TextStyle(color: context.colors.textMuted),
      ),
      const SizedBox(height: Space.lg),
      _CodeField(controller: _code, onSubmit: _submit),
      const SizedBox(height: Space.lg),
      FilledButton(key: const ValueKey('signin-verify'), onPressed: widget.auth.busy ? null : _submit, child: Text(context.tr(const Tr('تحقق', 'Verify')))),
      const SizedBox(height: Space.sm),
      widget.signOut,
    ],
  );
}

class _Enroll extends StatefulWidget {
  final AuthController auth;
  final Widget signOut;
  const _Enroll({required this.auth, required this.signOut});
  @override
  State<_Enroll> createState() => _EnrollState();
}

class _EnrollState extends State<_Enroll> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.length == 6 && !widget.auth.busy) widget.auth.verifyCode(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.auth.enrollment;
    final c = context.colors;
    return Column(
      key: const ValueKey('stage-needsEnroll'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(const Tr('فعّل التحقق بخطوتين', 'Set up two-step verification')), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.xs),
        Text(
          context.tr(
            const Tr(
              'أول مرة: سجّل البرنامج بتطبيق تحقق (Google Authenticator، Microsoft Authenticator…). الخادم ما بيفتح اللوحة بدونه.',
              'First time: register with an authenticator app (Google/Microsoft Authenticator…). The server will not open the dashboard without it.',
            ),
          ),
          style: TextStyle(color: c.textMuted),
        ),
        const SizedBox(height: Space.lg),
        if (e == null)
          FilledButton.icon(
            key: const ValueKey('signin-enroll-start'),
            onPressed: widget.auth.busy ? null : widget.auth.startEnrollment,
            icon: const Icon(Icons.qr_code_2),
            label: Text(context.tr(const Tr('اعرض رمز QR', 'Show QR code'))),
          )
        else ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Radii.sm)),
              child: QrImageView(key: const ValueKey('signin-qr'), data: e.uri, size: 200, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            context.tr(const Tr('أو اكتب المفتاح يدويًا:', 'Or type the key manually:')),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textDim, fontSize: 12),
          ),
          SelectableText(
            e.secret,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Space.lg),
          _CodeField(controller: _code, onSubmit: _submit),
          const SizedBox(height: Space.md),
          FilledButton(
            key: const ValueKey('signin-verify'),
            onPressed: widget.auth.busy ? null : _submit,
            child: Text(context.tr(const Tr('تحقق وفعّل', 'Verify and enable'))),
          ),
        ],
        const SizedBox(height: Space.sm),
        widget.signOut,
      ],
    );
  }
}
