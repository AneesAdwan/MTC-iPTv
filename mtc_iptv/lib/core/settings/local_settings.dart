// الإعدادات المحلية للجهاز (§9.9: منفصلة عن الإعدادات المركزية).
// ملف JSON بسيط في مجلد التطبيق؛ تنتقل إلى Drift في المرحلة 2 مع بقية التخزين المحلي.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/log.dart';

@immutable
class LocalSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final bool sidebarCollapsed;

  const LocalSettings({this.locale = const Locale('ar'), this.themeMode = ThemeMode.dark, this.sidebarCollapsed = false});

  LocalSettings copyWith({Locale? locale, ThemeMode? themeMode, bool? sidebarCollapsed}) => LocalSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      );

  Map<String, Object> toJson() => {'locale': locale.languageCode, 'theme': themeMode.name, 'sidebarCollapsed': sidebarCollapsed};

  factory LocalSettings.fromJson(Map<String, dynamic> j) => LocalSettings(
        locale: Locale(j['locale'] == 'en' ? 'en' : 'ar'),
        themeMode: ThemeMode.values.firstWhere((m) => m.name == j['theme'], orElse: () => ThemeMode.dark),
        sidebarCollapsed: j['sidebarCollapsed'] == true,
      );
}

/// يُحمَّل قبل runApp ويُمرَّر عبر override، فلا تومض الواجهة بالإعدادات الافتراضية.
final initialSettingsProvider = Provider<LocalSettings>((_) => const LocalSettings());

final settingsProvider = NotifierProvider<SettingsController, LocalSettings>(SettingsController.new);

class SettingsController extends Notifier<LocalSettings> {
  @override
  LocalSettings build() => ref.read(initialSettingsProvider);

  void setLocale(Locale l) => _set(state.copyWith(locale: l));
  void toggleLocale() => setLocale(Locale(state.locale.languageCode == 'ar' ? 'en' : 'ar'));
  void setThemeMode(ThemeMode m) => _set(state.copyWith(themeMode: m));
  void toggleTheme() => setThemeMode(state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  void toggleSidebar() => _set(state.copyWith(sidebarCollapsed: !state.sidebarCollapsed));

  void _set(LocalSettings s) {
    state = s;
    saveSettings(s);
  }
}

Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}settings.json');

Future<LocalSettings> loadSettings() async {
  try {
    final f = await _file();
    if (await f.exists()) return LocalSettings.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
  } catch (e) {
    log.warning('settings load failed', e);
  }
  return const LocalSettings();
}

Future<void> saveSettings(LocalSettings s) async {
  try {
    await (await _file()).writeAsString(jsonEncode(s.toJson()));
  } catch (e) {
    log.warning('settings save failed', e);
  }
}
