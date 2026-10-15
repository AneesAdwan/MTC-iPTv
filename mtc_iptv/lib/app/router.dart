// التوجيه (ADR-05): كل شاشة في السجل لها مسار داخل الهيكل العام.
// حماية مسارات الإدارة هنا تجربة استخدام فقط — الحماية الحقيقية على الخادم (§19، is_admin + MFA).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/placeholder/placeholder_screen.dart';
import 'screens.dart';
import 'shell/app_shell.dart';
import 'shell/sidebar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final def = screenForPath(state.uri.path);
      if (def == null) return '/home';
      if (def.group.isAdmin && !ref.read(isAdminProvider)) return '/home';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
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
