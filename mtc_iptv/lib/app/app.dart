import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/backend/backend.dart';
import '../core/settings/local_settings.dart';
import '../data/epg/epg_repository.dart';
import '../features/splash/splash_gate.dart';
import '../data/settings/remote_config.dart';
import 'desktop/desktop_host.dart';
import 'remote/remote_gates.dart';
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
    ref.watch(remoteConfigSyncProvider); // والإعدادات المركزية والإشعارات (G، F)
    ref.watch(periodicRefreshProvider); // إعادة المزامنة الدورية
    // G3: لغة وثيم افتراضيان لجهاز لم يختر مستخدمه بعد
    ref.listen(remoteConfigProvider, (_, next) {
      final g = next.value?.general;
      if (g == null || g.isEmpty) return;
      ref.read(settingsProvider.notifier).applyDefaults(language: g['default_language'] as String?, theme: g['default_theme'] as String?);
    });
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
      builder: (context, child) => DesktopHost(child: SplashGate(child: RemoteGates(child: child ?? const SizedBox.shrink()))),
    );
  }
}
