// تخطيط الرئيسية (ADM-B4 ← V-02): الحفظ والقراءة، التواريخ، والتخطيط الافتراضي، وعرضه في الرئيسية.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/catalog/home_layout.dart';

import 'app_shell_test.dart' show appTest;
import 'viewer_test.dart' show pump;

void main() {
  test('json round trip keeps types, titles, refs, ids and dates', () {
    final l = HomeLayout(hero: const ['c1'], rows: [
      const HomeRow(type: 'category', ref: 'news', titleAr: 'أخبار', count: 10),
      HomeRow(type: 'manual', channelIds: const ['c1', 'c2'], from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 30)),
    ]);
    final back = HomeLayout.fromJson(jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>);
    expect(back.hero, ['c1']);
    expect([back.rows[0].type, back.rows[0].ref, back.rows[0].titleAr, back.rows[0].count], ['category', 'news', 'أخبار', 10]);
    expect(back.rows[1].channelIds, ['c1', 'c2']);
    expect(back.rows[1].from, DateTime(2026, 3, 1));
  });

  test('dated rows show only inside their window (the end day included)', () {
    final r = HomeRow(type: 'manual', from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 30));
    expect(r.activeAt(DateTime(2026, 2, 28, 23)), isFalse);
    expect(r.activeAt(DateTime(2026, 3, 30, 22)), isTrue);
    expect(r.activeAt(DateTime(2026, 3, 31, 0, 1)), isFalse);
    expect(const HomeRow(type: 'all', visible: false).activeAt(DateTime(2026)), isFalse);
  });

  test('unknown row types from a newer admin app are ignored', () {
    final l = HomeLayout.fromJson({'rows': [{'type': 'most_watched'}, {'type': 'featured'}]});
    expect(l.rows.map((r) => r.type), ['featured']);
  });

  appTest('home follows the saved layout: hero + custom-titled category row', (tester) async {
    final db = CatalogDb(NativeDatabase.memory());
    addTearDown(db.close);
    await db.batch((b) {
      b.insertAll(db.channels, [
        ChannelsCompanion.insert(id: 'c1', uid: 'u1', number: const Value(1), nameAr: const Value('الجزيرة'), category: const Value('news')),
        ChannelsCompanion.insert(id: 'c2', uid: 'u2', number: const Value(2), nameAr: const Value('سبيستون'), category: const Value('kids')),
      ]);
    });
    await db.setSyncValue('home_layout', jsonEncode(const HomeLayout(hero: ['c2'], rows: [HomeRow(type: 'category', ref: 'news', titleAr: 'صف الأخبار المختار')]).toJson()));
    await pump(tester, db);
    expect(find.text('صف الأخبار المختار'), findsOneWidget);
    expect(find.text('سبيستون'), findsWidgets, reason: 'hero channel shown');
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
  });
}
