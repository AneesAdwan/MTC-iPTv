// ترحيل بيانات React Native (§24.6): ملف RKStorage حقيقي البنية (catalystLocalStorage) ← Drift.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/migration/rn_migration.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() {
  late Directory dir;
  late CatalogDb db;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('rkstorage');
    db = CatalogDb(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  String makeRkStorage(Map<String, String> kv) {
    final path = '${dir.path}/RKStorage';
    final d = sql.sqlite3.open(path);
    // نفس جدول AsyncStorage على Android
    d.execute('CREATE TABLE catalystLocalStorage (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    final st = d.prepare('INSERT INTO catalystLocalStorage (key, value) VALUES (?, ?)');
    kv.forEach((k, v) => st.execute([k, v]));
    st.close();
    d.close();
    return path;
  }

  test('favorites, continue-watching and notifications move to Drift; admin session does not', () async {
    final path = makeRkStorage({
      'mtc-favorites': jsonEncode(['c3', 'c1', 'c3', '']),
      'mtc-continue': jsonEncode(['c9', 'c1']),
      'mtc-notifications': jsonEncode([
        {'id': '1', 'title': 'مرحبا', 'body': 'نص', 'url': 'mtciptv://watch/c9', 'at': 1760000000000, 'read': true},
        {'id': '2', 'title': '', 'body': 'بلا عنوان'},
      ]),
      'mtc-admin-session': '{"access_token":"secret"}',
      'mtc-player-prefs': '{"volume":0.5}',
    });
    final kv = readRnStorage(path);
    expect(kv.containsKey('mtc-admin-session'), isFalse);

    // مفضلة موجودة محليًا قبل الترحيل تبقى أولًا ولا تتكرر
    await db.into(db.favorites).insert(FavoritesCompanion.insert(channelId: 'c1', position: 0, addedAt: DateTime(2026)));
    final r = await migrateRnValues(db, kv, now: DateTime(2026, 10, 16, 12));
    expect(r.favorites, 1);
    expect(r.history, 2);
    expect(r.notifications, 1);

    final favs = await (db.select(db.favorites)..orderBy([(f) => OrderingTerm.asc(f.position)])).get();
    expect(favs.map((f) => f.channelId), ['c1', 'c3']);
    final hist = await (db.select(db.history)..orderBy([(h) => OrderingTerm.desc(h.watchedAt)])).get();
    expect(hist.map((h) => h.channelId), ['c9', 'c1']);
    final inbox = await db.select(db.inbox).get();
    expect(inbox.single.channelId, 'c9');
    expect(inbox.single.read, isTrue);
    expect(inbox.single.at, DateTime.fromMillisecondsSinceEpoch(1760000000000));

    // علامة «تم» محفوظة، وملف RN لم يُحذف (§24.6: 60 يومًا)
    final mark = await (db.select(db.syncState)..where((s) => s.key.equals(rnMigratedKey))).getSingleOrNull();
    expect(mark, isNotNull);
    expect(File(path).existsSync(), isTrue);
  });

  test('corrupt or missing values never break the migration', () async {
    final r = await migrateRnValues(db, {'mtc-favorites': 'not json', 'mtc-continue': '{"a":1}', 'mtc-notifications': '['});
    expect((r.favorites, r.history, r.notifications), (0, 0, 0));
  });
}
