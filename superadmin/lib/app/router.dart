// Routes + the server gate. Every navigation into an admin screen re-asks the server
// (AuthController.recheck → admin_status); anything but a confirmed admin goes to /sign-in.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/admin_auth.dart';
import '../auth/auth_controller.dart';
import '../auth/sign_in_screen.dart';
import '../core/tr.dart';
import '../features/pages.dart';
import '../shell/app_shell.dart';
import '../ui/states.dart';
import 'nav.dart';

GoRouter buildRouter(AuthController auth, {String initialLocation = '/home'}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: auth,
  redirect: (context, state) async {
    final atSignIn = state.matchedLocation == '/sign-in';
    if (atSignIn) {
      if (!auth.isAdmin) return null;
      final from = state.uri.queryParameters['from'];
      return (from != null && from.startsWith('/') && !from.startsWith('/sign-in')) ? from : '/home';
    }
    final stage = await auth.recheck();
    if (stage != AdminStage.admin) {
      return Uri(path: '/sign-in', queryParameters: {'from': state.uri.toString()}).toString();
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/home'),
    GoRoute(
      path: '/sign-in',
      pageBuilder: (context, state) => const NoTransitionPage(child: SignInScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        for (final p in Nav.pages)
          GoRoute(
            path: p.path,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: buildPage(p.id, state)),
          ),
        GoRoute(
          path: Nav.channelDetail.path,
          pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: buildPage(Nav.channelDetail.id, state)),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: EmptyState(
      icon: Icons.explore_off_outlined,
      title: const Tr('الصفحة مش موجودة', 'Page not found'),
      message: Tr(state.uri.toString(), state.uri.toString()),
      action: FilledButton(onPressed: () => context.go('/home'), child: Text(context.tr(const Tr('للرئيسية', 'Go home')))),
    ),
  ),
);
