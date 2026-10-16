// الإعدادات المركزية (§9.9 G1–G6، F1–F2): تصل كل الأجهزة دون إصدار جديد.
// المصدر: site_settings العامة (is_public) — مفاتيح: brand، social، general، player، features، releases،
// announcements، notifications. التطبيق يجلبها عند المزامنة ويحفظها محليًا (يعمل دون اتصال).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend.dart';
import '../../core/config/env.dart';
import '../../core/logging/log.dart';
import '../../core/settings/local_settings.dart';
import '../../core/storage/catalog_db.dart';
import '../updates/update_check.dart';

const remoteKeys = ['brand', 'social', 'general', 'player', 'features', 'releases', 'announcements', 'notifications', 'developer'];

class RemoteConfig {
  final Map<String, dynamic> raw; // المفتاح ← القيمة
  const RemoteConfig(this.raw);
  static const empty = RemoteConfig({});

  Map<String, dynamic> _m(String k) => (raw[k] as Map?)?.cast<String, dynamic>() ?? const {};
  List<Map<String, dynamic>> _l(String k) => [for (final x in (raw[k] as List?) ?? const []) if (x is Map) x.cast<String, dynamic>()];

  Map<String, dynamic> get brand => _m('brand');
  Map<String, dynamic> get general => _m('general');
  Map<String, dynamic> get player => _m('player');
  Map<String, dynamic> get features => _m('features');
  Map<String, dynamic> get releases => _m('releases');

  /// اسم المطوّر (site_settings.developer العام: name_ar/name_en) — يظهر في المقدمة. null إن لم يصل بعد.
  String? developerName(String lang) {
    final d = _m('developer');
    final v = (lang == 'ar' ? (d['name_ar'] ?? d['name_en']) : (d['name_en'] ?? d['name_ar'])) as String?;
    return v == null || v.trim().isEmpty ? null : v.trim();
  }
  List<Map<String, dynamic>> get social => [for (final x in (raw['social'] is Map ? (raw['social'] as Map)['links'] : raw['social']) as List? ?? const []) if (x is Map) x.cast<String, dynamic>()];
  /// قنوات الدعم (واتساب/تيليجرام) من G2.
  Map<String, String> get support => {
        for (final e in ((raw['social'] is Map ? (raw['social'] as Map)['support'] : null) as Map? ?? const {}).entries)
          if (e.value != null && '${e.value}'.trim().isNotEmpty) '${e.key}': '${e.value}'.trim(),
      };

  /// نص الهوية بلغة الواجهة مع الرجوع للعربية ثم null (فيُستخدم النص المدمج).
  String? brandText(String key, String lang) {
    for (final k in ['${key}_$lang', '${key}_ar']) {
      final v = brand[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  List<Map<String, dynamic>> get announcements => _l('announcements');
  List<Map<String, dynamic>> get notifications => _l('notifications');

  // ── G5 ──
  bool get maintenance => (features['maintenance'] as Map?)?['enabled'] == true;
  String maintenanceMessage(String lang) => '${(features['maintenance'] as Map?)?['message_$lang'] ?? (features['maintenance'] as Map?)?['message_ar'] ?? ''}';
  Set<String> get killedChannels => {for (final x in ((features['kill_switch'] as Map?)?['channels'] as List?) ?? const []) '$x'};
  bool feature(String name) => ((features['features'] as Map?)?[name]) != false; // غياب المفتاح = مفعّلة
  bool get telemetryEnabled => features['telemetry_enabled'] != false;

  // ── G3 ──
  List<String> get parentalLockedCategories => [for (final x in (general['parental_locked_categories'] as List?) ?? const []) '$x'];
  int get recentDays => (general['recent_days'] as num?)?.toInt() ?? 30;

  // ── G4 ──
  int playerSeconds(String key, int fallback) => (player[key] as num?)?.toInt() ?? fallback;

  // ── G6: الإجبار على التحديث أو التنبيه ──
  /// 'force' إن كان الإصدار أقدم من الحد الأدنى المدعوم، 'recommend' إن كان أقدم من الموصى به، وإلا null.
  String? updateRequirement(String current) {
    final cur = AppVersion.parse(current);
    if (cur == null) return null;
    final min = AppVersion.parse('${releases['min_supported'] ?? ''}');
    final rec = AppVersion.parse('${releases['recommended'] ?? ''}');
    if (min != null && cur.compareTo(min) < 0) return 'force';
    if (rec != null && cur.compareTo(rec) < 0) return 'recommend';
    return null;
  }

  String? get updateUrl => releases['url'] as String?;
}

String get platformName => Platform.isWindows
    ? 'windows'
    : Platform.isAndroid
        ? 'android'
        : Platform.isMacOS
            ? 'macos'
            : Platform.operatingSystem;

/// إعلان ظاهر الآن لهذا الجهاز؟ (الفترة، المنصّات، الإصدارات — §9.8 F2)
bool announcementActive(Map<String, dynamic> a, {DateTime? now, String? platform, String? version}) {
  final t = now ?? DateTime.now();
  final from = DateTime.tryParse('${a['from']}'), to = DateTime.tryParse('${a['to']}');
  if (a['enabled'] == false) return false;
  if (from != null && t.isBefore(from)) return false;
  if (to != null && !t.isBefore(to)) return false;
  final plats = [for (final x in (a['platforms'] as List?) ?? const []) '$x'];
  if (plats.isNotEmpty && !plats.contains(platform ?? platformName)) return false;
  final v = AppVersion.parse(version ?? Env.version);
  final minV = AppVersion.parse('${a['min_version'] ?? ''}'), maxV = AppVersion.parse('${a['max_version'] ?? ''}');
  if (v != null && minV != null && v.compareTo(minV) < 0) return false;
  if (v != null && maxV != null && v.compareTo(maxV) > 0) return false;
  return true;
}

/// إشعار موجّه لهذا الجهاز؟ (المنصّة واللغة — §14)
bool notificationTargets(Map<String, dynamic> n, {required String lang, String? platform}) {
  final plats = [for (final x in (n['platforms'] as List?) ?? const []) '$x'];
  final langs = [for (final x in (n['languages'] as List?) ?? const []) '$x'];
  if (plats.isNotEmpty && !plats.contains(platform ?? platformName)) return false;
  if (langs.isNotEmpty && !langs.contains(lang)) return false;
  final at = DateTime.tryParse('${n['send_at'] ?? ''}');
  return at == null || !at.isAfter(DateTime.now());
}

/// يجلب الإعدادات بعد كل مزامنة كتالوج ويحفظها محليًا، ويضيف الإشعارات الجديدة الموجّهة لهذا الجهاز إلى صندوق الوارد.
final remoteConfigSyncProvider = FutureProvider<void>((ref) async {
  await ref.watch(startupSyncProvider.future);
  final json = await fetchRemoteConfigJson(ref);
  if (json == null) return;
  final db = ref.read(catalogDbProvider);
  await db.setSyncValue('remote_config', json);
  await deliverNotifications(db, RemoteConfig((jsonDecode(json) as Map).cast<String, dynamic>()), lang: ref.read(settingsProvider).locale.languageCode);
});

final remoteConfigProvider = StreamProvider<RemoteConfig>((ref) {
  ref.watch(remoteConfigSyncProvider);
  final db = ref.watch(catalogDbProvider);
  return (db.select(db.syncState)..where((s) => s.key.equals('remote_config'))).watchSingleOrNull().map((row) {
    if (row == null) return RemoteConfig.empty;
    try {
      return RemoteConfig((jsonDecode(row.value) as Map).cast<String, dynamic>());
    } catch (_) {
      return RemoteConfig.empty;
    }
  });
});

/// القنوات المخفية فورًا (G5 kill switch) — تُستبعد من كل استعلامات المشاهدة.
final killedChannelsProvider = Provider<Set<String>>((ref) => ref.watch(remoteConfigProvider).value?.killedChannels ?? const {});

/// إعادة المزامنة الدورية (G5 catalog.refresh_interval، افتراضيًا كل 60 دقيقة).
final periodicRefreshProvider = Provider<void>((ref) {
  final minutes = (ref.watch(remoteConfigProvider).value?.features['catalog_refresh_min'] as num?)?.toInt() ?? 60;
  final timer = Timer.periodic(Duration(minutes: minutes.clamp(5, 1440)), (_) => ref.invalidate(startupSyncProvider));
  ref.onDispose(timer.cancel);
});

/// الإشعارات (F1) ← صندوق الوارد مرة واحدة لكل إشعار (المعرّفات المستلمة في SyncState).
Future<int> deliverNotifications(CatalogDb db, RemoteConfig rc, {required String lang}) async {
  final seenRow = await (db.select(db.syncState)..where((s) => s.key.equals('seen_notifications'))).getSingleOrNull();
  final seen = <String>{for (final x in (seenRow == null ? const [] : jsonDecode(seenRow.value) as List)) '$x'};
  var n = 0;
  for (final m in rc.notifications) {
    final id = '${m['id']}';
    if (seen.contains(id) || !notificationTargets(m, lang: lang)) continue;
    final title = '${(lang == 'ar' ? (m['title_ar'] ?? m['title_en']) : (m['title_en'] ?? m['title_ar'])) ?? ''}';
    final body = (lang == 'ar' ? (m['body_ar'] ?? m['body_en']) : (m['body_en'] ?? m['body_ar'])) as String?;
    final link = '${m['link'] ?? ''}';
    await db.into(db.inbox).insert(InboxCompanion.insert(
          kind: 'announcement',
          title: title,
          body: Value(body),
          channelId: Value(link.startsWith('/watch/') ? link.substring(7) : null),
          at: DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
        ));
    seen.add(id);
    n++;
  }
  // نحتفظ بآخر 200 معرّف فقط
  final ids = seen.toList(); // بترتيب الإدراج: الأقدم أولًا
  await db.setSyncValue('seen_notifications', jsonEncode(ids.sublist(ids.length > 200 ? ids.length - 200 : 0)));
  return n;
}

/// جلب المفاتيح العامة (يقرؤها الزائر) وحفظها نصًا في SyncState.
Future<String?> fetchRemoteConfigJson(Ref ref) async {
  final c = ref.read(supabaseProvider);
  if (c == null) return null;
  try {
    final rows = await c.from('site_settings').select('key,value').inFilter('key', remoteKeys);
    return jsonEncode({for (final r in rows) r['key']: r['value']});
  } catch (e) {
    log.warning('remote config fetch failed', e);
    return null;
  }
}
