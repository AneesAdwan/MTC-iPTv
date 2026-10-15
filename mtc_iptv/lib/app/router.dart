// التوجيه (ADR-05): كل شاشة في السجل لها مسار داخل الهيكل العام.
// حماية مسارات الإدارة هنا تجربة استخدام فقط — الحماية الحقيقية على الخادم (§19، is_admin + MFA).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

import '../features/admin/channels/channel_detail_screen.dart';
import '../features/admin/channels/channels_admin_screen.dart';
import '../features/admin/dashboard_screen.dart';
import '../features/admin/compare_screen.dart';
import '../features/admin/duplicates_screen.dart';
import '../features/admin/connectors_screen.dart';
import '../features/admin/epg_screens.dart';
import '../features/admin/export_screen.dart';
import '../features/admin/rules_screen.dart';
import '../features/admin/system_screens.dart';
import '../features/admin/health_screen.dart';
import '../features/admin/import_screen.dart';
import '../features/admin/sources_screen.dart';
import '../features/admin/home_layout_screen.dart';
import '../features/admin/logos_screen.dart';
import '../features/admin/networks_screen.dart';
import '../features/admin/jobs_screen.dart';
import '../features/admin/numbering_screen.dart';
import '../features/admin/review_screen.dart';
import '../features/admin/streams_screen.dart';
import '../features/admin/taxonomy_screen.dart';
import '../features/admin/login/admin_login_screen.dart';
import '../features/admin/reports_screen.dart';
import '../features/placeholder/placeholder_screen.dart';
import '../features/viewer/about_screen.dart';
import '../features/viewer/channels_screen.dart';
import '../features/viewer/guide_screen.dart';
import '../features/viewer/home_screen.dart';
import '../features/viewer/inbox_screen.dart';
import '../features/viewer/report_screen.dart';
import '../features/viewer/settings_screen.dart';
import '../features/viewer/watch_screen.dart';
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
            if (s.id != 'V-06')
              GoRoute(
                path: s.path,
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: _screenFor(s, state)),
              ),
          GoRoute(
            path: '/admin/channel/:id',
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: ChannelDetailScreen(key: ValueKey(state.pathParameters['id']), id: state.pathParameters['id']!)),
          ),
        ],
      ),
      // المشاهدة خارج الهيكل: الفيديو يأخذ المساحة كاملة (§8.1)
      GoRoute(path: '/watch/:id', builder: (context, state) => WatchScreen(channelId: state.pathParameters['id']!)),
    ],
  );
});

Widget _screenFor(ScreenDef s, GoRouterState state) {
  final q = state.uri.queryParameters;
  return switch (s.id) {
    'V-02' => const HomeScreen(),
    'V-03' => ChannelsScreen(key: ValueKey(state.uri.toString()), country: q['country'], category: q['category']),
    'V-04' => const CountriesScreen(),
    'V-05' => const SearchScreen(),
    'V-07' => const GuideScreen(),
    'V-08' => const FavoritesScreen(),
    'V-09' => const InboxScreen(),
    'V-10' => const SettingsScreen(),
    'V-11' => const AboutScreen(),
    'V-12' => ReportScreen(key: ValueKey(state.uri.toString()), channelId: q['channel']),
    'ADM-A1' => const DashboardScreen(),
    'ADM-A2' => const JobsScreen(),
    'ADM-B1' => ChannelsAdminScreen(
        key: ValueKey(state.uri.toString()),
        initialState: q['state'],
        initialCountry: q['country'],
        initialCategory: q['category'],
        initialSearch: q['q'],
        openAdd: q['add'] == '1'),
    'ADM-B3' => const StreamsScreen(),
    'ADM-B4' => const HomeLayoutScreen(),
    'ADM-B6' => const NetworksScreen(),
    'ADM-D2' => const DuplicatesScreen(),
    'ADM-D3' => CompareScreen(key: ValueKey(state.uri.toString()), ids: (q['ids'] ?? '').split(',').where((x) => x.isNotEmpty).toList()),
    'ADM-D5' => const LogosScreen(),
    'ADM-B5' => const TaxonomyScreen(),
    'ADM-B7' => const NumberingScreen(),
    'ADM-D1' => const ReviewScreen(),
    'ADM-C1' || 'ADM-C2' => const ImportScreen(),
    'ADM-C3' => const SourcesScreen(),
    'ADM-C4' => const ConnectorsScreen(),
    'ADM-C5' => const ExportScreen(),
    'ADM-C6' => const RulesScreen(),
    'ADM-H1' => const AccountScreen(),
    'ADM-H2' => const SchedulerScreen(),
    'ADM-H3' => const AuditScreen(),
    'ADM-H4' => const BackupsScreen(),
    'ADM-H5' => const MaintenanceScreen(),
    'ADM-E1' => const EpgSourcesScreen(),
    'ADM-E2' => const EpgMappingScreen(),
    'ADM-E3' => const EpgPreviewScreen(),
    'ADM-D4' => HealthScreen(key: ValueKey(state.uri.toString()), initialState: q['state']),
    'ADM-D6' => const ReportsAdminScreen(),
    _ => PlaceholderScreen(def: s),
  };
}
