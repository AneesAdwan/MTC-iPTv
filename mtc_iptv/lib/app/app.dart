import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/backend/backend.dart';
import '../core/settings/local_settings.dart';
import '../data/epg/epg_repository.dart';
import '../features/splash/splash_gate.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme/theme.dart';

class MtcApp extends ConsumerWidget {
  const MtcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    ref.watch(startupSyncProvider); // مزامنة الكتالوج في الخلفية عند البدء
    ref.watch(epgSyncProvider); // ثم دليل البرامج
    return MaterialApp.router(
      title: 'MTC-iPTv',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      // اللغة والاتجاه على مستوى التطبيق (§6.4): العربية RTL افتراضيًا، والتبديل فوري
      locale: s.locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: s.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => SplashGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
