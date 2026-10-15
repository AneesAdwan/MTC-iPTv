// الإعدادات المحلية للجهاز (§9.9: منفصلة عن الإعدادات المركزية) — V-10.
// ملف JSON بسيط في مجلد التطبيق.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/log.dart';

@immutable
class LocalSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final bool sidebarCollapsed;

  /// إظهار أرقام القنوات على البطاقات (V-10 «الأرقام»).
  final bool showNumbers;

  /// أقصى جودة يختارها المشغّل تلقائيًا (ارتفاع الصورة)؛ null = بلا حد.
  final int? maxQuality;

  /// إحصاءات التشغيل المجهولة (D-06: مفعّلة مع إمكانية الإيقاف، §20).
  final bool telemetry;

  /// الرقابة الأبوية (§8.4): بصمة PIN من 4 أرقام (لا يُحفظ الرمز نفسه) والفئات المقفلة.
  final String? pinHash;
  final List<String> lockedCategories;

  /// اختار المستخدم اللغة/الثيم بنفسه؟ إن لا، تُطبَّق افتراضيات الإدارة (G3) عند وصولها.
  /// الملفات القديمة (بلا المفتاح) تُعدّ مخصّصة حتى لا نغيّر واجهة مستخدم قائم.
  final bool customized;

  const LocalSettings({
    this.locale = const Locale('ar'),
    this.themeMode = ThemeMode.dark,
    this.sidebarCollapsed = false,
    this.showNumbers = true,
    this.maxQuality,
    this.telemetry = true,
    this.pinHash,
    this.lockedCategories = const [],
    this.customized = false,
  });

  bool get parentalOn => pinHash != null;

  LocalSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? sidebarCollapsed,
    bool? showNumbers,
    int? maxQuality,
    bool clearMaxQuality = false,
    bool? telemetry,
    String? pinHash,
    bool clearPin = false,
    List<String>? lockedCategories,
    bool? customized,
  }) =>
      LocalSettings(
        customized: customized ?? this.customized,
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
        showNumbers: showNumbers ?? this.showNumbers,
        maxQuality: clearMaxQuality ? null : (maxQuality ?? this.maxQuality),
        telemetry: telemetry ?? this.telemetry,
        pinHash: clearPin ? null : (pinHash ?? this.pinHash),
        lockedCategories: lockedCategories ?? this.lockedCategories,
      );

  Map<String, Object?> toJson() => {
        'locale': locale.languageCode,
        'theme': themeMode.name,
        'sidebarCollapsed': sidebarCollapsed,
        'showNumbers': showNumbers,
        'maxQuality': maxQuality,
        'telemetry': telemetry,
        'pinHash': pinHash,
        'lockedCategories': lockedCategories,
        'customized': customized,
      };

  factory LocalSettings.fromJson(Map<String, dynamic> j) => LocalSettings(
        locale: Locale(j['locale'] == 'en' ? 'en' : 'ar'),
        themeMode: ThemeMode.values.firstWhere((m) => m.name == j['theme'], orElse: () => ThemeMode.dark),
        sidebarCollapsed: j['sidebarCollapsed'] == true,
        showNumbers: j['showNumbers'] != false,
        maxQuality: j['maxQuality'] is int ? j['maxQuality'] as int : null,
        telemetry: j['telemetry'] != false,
        pinHash: j['pinHash'] is String ? j['pinHash'] as String : null,
        lockedCategories: [for (final x in (j['lockedCategories'] as List?) ?? const []) '$x'],
        customized: j['customized'] != false,
      );
}

/// بصمة الرمز مع ملح ثابت للتطبيق (يمنع قراءة الرمز من ملف الإعدادات مباشرة؛ ليس حماية من صاحب الجهاز).
String hashPin(String pin) => sha256.convert(utf8.encode('mtc-iptv/parental/$pin')).toString();

/// يُحمَّل قبل runApp ويُمرَّر عبر override، فلا تومض الواجهة بالإعدادات الافتراضية.
final initialSettingsProvider = Provider<LocalSettings>((_) => const LocalSettings());

final settingsProvider = NotifierProvider<SettingsController, LocalSettings>(SettingsController.new);

class SettingsController extends Notifier<LocalSettings> {
  @override
  LocalSettings build() => ref.read(initialSettingsProvider);

  void setLocale(Locale l) => _set(state.copyWith(locale: l, customized: true));
  void toggleLocale() => setLocale(Locale(state.locale.languageCode == 'ar' ? 'en' : 'ar'));
  void setThemeMode(ThemeMode m) => _set(state.copyWith(themeMode: m, customized: true));

  /// G3: افتراضيات الإدارة للغة والثيم — لجهاز لم يختر مستخدمه بعد (أول تشغيل).
  void applyDefaults({String? language, String? theme}) {
    if (state.customized) return;
    final l = language == 'en' || language == 'ar' ? Locale(language!) : state.locale;
    final m = ThemeMode.values.where((x) => x.name == theme).firstOrNull ?? state.themeMode;
    if (l != state.locale || m != state.themeMode) _set(state.copyWith(locale: l, themeMode: m));
  }
  void toggleTheme() => setThemeMode(state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  void toggleSidebar() => _set(state.copyWith(sidebarCollapsed: !state.sidebarCollapsed));
  void setShowNumbers(bool v) => _set(state.copyWith(showNumbers: v));
  void setMaxQuality(int? h) => _set(h == null ? state.copyWith(clearMaxQuality: true) : state.copyWith(maxQuality: h));
  void setTelemetry(bool v) => _set(state.copyWith(telemetry: v));
  /// [defaults]: الفئات المقفلة افتراضيًا من الإدارة (G3) — تُحدَّد عند أول تفعيل فقط، ويبقى للمستخدم تعديلها.
  void setPin(String? pin, {List<String> defaults = const []}) => _set(pin == null
      ? state.copyWith(clearPin: true, lockedCategories: const [])
      : state.copyWith(
          pinHash: hashPin(pin),
          lockedCategories: state.pinHash == null && state.lockedCategories.isEmpty ? ([...defaults]..sort()) : null,
        ));
  bool checkPin(String pin) => state.pinHash != null && state.pinHash == hashPin(pin);
  void toggleLockedCategory(String slug) {
    final s = {...state.lockedCategories};
    s.contains(slug) ? s.remove(slug) : s.add(slug);
    _set(state.copyWith(lockedCategories: s.toList()..sort()));
  }

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
