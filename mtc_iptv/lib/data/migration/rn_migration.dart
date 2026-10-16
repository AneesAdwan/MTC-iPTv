// ترحيل بيانات تطبيق React Native عند الترقية فوقه على Android (§24.6، R2).
// AsyncStorage على Android = قاعدة SQLite باسم RKStorage (جدول catalystLocalStorage: key, value)
// في مجلد قواعد بيانات التطبيق. يُقرأ مرة واحدة عند أول تشغيل:
//   mtc-favorites      ← المفضلة (بنفس الترتيب)
//   mtc-continue       ← السجل (الأحدث أولًا)
//   mtc-notifications  ← صندوق الوارد
// لا تُرحَّل جلسة المدير (mtc-admin-session): يدخل من جديد بالتحقق بخطوتين.
// **لا يُحذف أي شيء من بيانات RN** (60 يومًا على الأقل): يمكن إعادة المحاولة في إصدار تصحيحي.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../core/backend/backend.dart';
import '../../core/logging/log.dart';
import '../../core/storage/catalog_db.dart';

const rnMigratedKey = 'rn_migrated';

class RnMigrationResult {
  final int favorites, history, notifications;
  const RnMigrationResult(this.favorites, this.history, this.notifications);
  @override
  String toString() => 'favorites=$favorites history=$history notifications=$notifications';
}

List<String> _ids(String? raw) {
  if (raw == null) return const [];
  try {
    final v = jsonDecode(raw);
    if (v is! List) return const [];
    final out = <String>[];
    for (final x in v) {
      if (x is String && x.isNotEmpty && x.length <= 64 && !out.contains(x)) out.add(x);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// يكتب قيم AsyncStorage في قاعدة Drift. يدمج ولا يكرر، ولا يمسّ ما هو موجود محليًا.
Future<RnMigrationResult> migrateRnValues(CatalogDb db, Map<String, String> kv, {DateTime? now}) async {
  final t = now ?? DateTime.now();
  final favs = _ids(kv['mtc-favorites']);
  final cont = _ids(kv['mtc-continue']);
  final notifs = <Map<String, dynamic>>[];
  try {
    final v = jsonDecode(kv['mtc-notifications'] ?? '[]');
    if (v is List) {
      for (final n in v.take(100)) {
        if (n is Map && '${n['title'] ?? ''}'.trim().isNotEmpty) notifs.add(n.cast<String, dynamic>());
      }
    }
  } catch (_) {}

  var f = 0, h = 0, m = 0;
  await db.transaction(() async {
    // المفضلة: بعد الموجود محليًا، بترتيب RN
    final existing = {for (final r in await db.select(db.favorites).get()) r.channelId};
    var pos = existing.length;
    for (final id in favs) {
      if (existing.contains(id)) continue;
      await db.into(db.favorites).insert(FavoritesCompanion.insert(channelId: id, position: pos++, addedAt: t));
      f++;
    }
    // السجل: الأول هو الأحدث؛ نعطي كل عنصر وقتًا أقدم بدقيقة ليبقى الترتيب
    final seen = {for (final r in await db.select(db.history).get()) r.channelId};
    for (var i = 0; i < cont.length; i++) {
      if (seen.contains(cont[i])) continue;
      await db.into(db.history).insert(HistoryCompanion.insert(channelId: cont[i], watchedAt: t.subtract(Duration(minutes: i + 1))));
      h++;
    }
    for (final n in notifs) {
      final link = '${n['url'] ?? ''}';
      final ch = RegExp(r'watch/([A-Za-z0-9_-]{1,64})').firstMatch(link)?.group(1);
      await db.into(db.inbox).insert(InboxCompanion.insert(
            kind: 'announcement',
            title: '${n['title']}'.trim(),
            body: Value('${n['body'] ?? ''}'.trim().isEmpty ? null : '${n['body']}'.trim()),
            channelId: Value(ch),
            at: n['at'] is num ? DateTime.fromMillisecondsSinceEpoch((n['at'] as num).toInt()) : t,
            read: Value(n['read'] == true),
          ));
      m++;
    }
    await db.setSyncValue(rnMigratedKey, jsonEncode({'at': t.toUtc().toIso8601String(), 'favorites': f, 'history': h, 'notifications': m}));
  });
  return RnMigrationResult(f, h, m);
}

/// يقرأ catalystLocalStorage من ملف RKStorage (للقراءة فقط).
Map<String, String> readRnStorage(String path) {
  final d = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
  try {
    final rows = d.select("select key, value from catalystLocalStorage where key in ('mtc-favorites','mtc-continue','mtc-notifications','mtc-player-prefs')");
    return {for (final r in rows) r['key'] as String: (r['value'] as String?) ?? ''};
  } finally {
    d.close();
  }
}

/// يُشاهَد في MtcApp: مرة واحدة عند التشغيل.
final rnMigrationProvider = FutureProvider<RnMigrationResult?>((ref) => migrateFromReactNativeIfNeeded(ref.read(catalogDbProvider)));

/// عند أول تشغيل على Android فقط: إن وُجدت بيانات RN ولم تُرحَّل بعد.
Future<RnMigrationResult?> migrateFromReactNativeIfNeeded(CatalogDb db) async {
  if (!Platform.isAndroid) return null;
  try {
    final done = await (db.select(db.syncState)..where((s) => s.key.equals(rnMigratedKey))).getSingleOrNull();
    if (done != null) return null;
    // /data/data/<pkg>/files ← /data/data/<pkg>/databases/RKStorage
    final support = await getApplicationSupportDirectory();
    final file = File('${support.parent.path}/databases/RKStorage');
    if (!await file.exists()) {
      await db.setSyncValue(rnMigratedKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String(), 'none': true}));
      return null;
    }
    final r = await migrateRnValues(db, readRnStorage(file.path));
    log.info('migrated from React Native: $r');
    return r;
  } catch (e, s) {
    // لا علامة «تم» عند الفشل: يُعاد في التشغيل التالي (أو في إصدار تصحيحي)
    log.warning('React Native migration failed', e, s);
    return null;
  }
}
