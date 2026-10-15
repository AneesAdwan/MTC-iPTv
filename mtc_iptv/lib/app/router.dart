// التوجيه (ADR-05): كل شاشة في السجل لها مسار داخل الهيكل العام.
// حماية مسارات الإدارة هنا تجربة استخدام فقط — الحماية الحقيقية على الخادم (§19، is_admin + MFA).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';

import '../features/admin/login/admin_login_screen.dart';
import '../features/placeholder/placeholder_screen.dart';
import 'screens.dart';
import 'shell/app_shell.dart';
import 'shell/sidebar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // يعيد تقييم التوجيه عند تغيّر حالة المدير (دخول/خروج/MFA) دون إعادة بناء الموجّه
  final refresh = ValueNotifier(0);
  ref.listen(isAdminProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final admin = ref.read(isAdminProvider);
      if (path == adminLoginScreen.path) return admin ? '/admin/dashboard' : null;
      final def = screenForPath(path);
      if (def == null) return '/home';
      if (def.group.isAdmin && !admin) return adminLoginScreen.path;
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: adminLoginScreen.path,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminLoginScreen()),
          ),
          for (final s in screens)
            GoRoute(
              path: s.path,
              pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: PlaceholderScreen(def: s)),
            ),
        ],
      ),
    ],
  );
});
