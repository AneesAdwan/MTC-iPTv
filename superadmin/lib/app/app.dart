import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../core/env.dart';
import '../core/prefs.dart';
import '../core/tr.dart';
import 'router.dart';
import 'theme/theme.dart';

class SuperAdminApp extends ConsumerStatefulWidget {
  final String initialLocation;
  const SuperAdminApp({super.key, this.initialLocation = '/home'});
  @override
  ConsumerState<SuperAdminApp> createState() => _SuperAdminAppState();
}

class _SuperAdminAppState extends ConsumerState<SuperAdminApp> {
  late final GoRouter _router = buildRouter(ref.read(authControllerProvider), initialLocation: widget.initialLocation);
  final _light = buildTheme(Brightness.light);
  final _dark = buildTheme(Brightness.dark);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => MaterialApp.router(
        title: Env.appTitle,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: _light,
        darkTheme: _dark,
        themeMode: prefs.themeMode,
        locale: prefs.lang.locale,
        supportedLocales: [for (final l in Lang.values) l.locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
