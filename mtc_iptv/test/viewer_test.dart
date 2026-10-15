// شاشات المشاهدة على كتالوج محلي في الذاكرة (دون خادم ودون مشغّل).
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/app/app.dart';
import 'package:mtc_iptv/app/shell/sidebar.dart';
import 'package:mtc_iptv/core/backend/backend.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/catalog/catalog_repository.dart';

import 'app_shell_test.dart' show appTest;

Future<CatalogDb> seeded() async {
  final db = CatalogDb(NativeDatabase.memory());
  await db.batch((b) {
    b.insertAll(db.channels, [
      ChannelsCompanion.insert(id: 'c1', uid: 'u1', number: const Value(1), nameAr: const Value('الجزيرة'), nameEn: const Value('Al Jazeera'),
          category: const Value('news'), country: const Value('QA'), featured: const Value(true), search: const Value('aljazeera الجزيره #1')),
      ChannelsCompanion.insert(id: 'c2', uid: 'u2', number: const Value(2), nameAr: const Value('سبيستون'), nameEn: const Value('Spacetoon'),
          category: const Value('kids'), country: const Value('AE'), search: const Value('spacetoon سبيستون #2')),
    ]);
  });
  return db;
}

Widget viewerApp(CatalogDb db, {String locale = 'ar'}) => ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(LocalSettings(locale: Locale(locale))),
        isAdminProvider.overrideWithValue(false),
        catalogDbProvider.overrideWithValue(db),
      ],
      child: const MtcApp(),
    );

Future<void> pump(WidgetTester tester, CatalogDb db, {String locale = 'ar'}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(viewerApp(db, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  appTest('home lists featured and all channels from the local catalog', (tester) async {
    final db = await seeded();
    addTearDown(db.close);
    await pump(tester, db);
    expect(find.text('الجزيرة'), findsWidgets);
    expect(find.text('سبيستون'), findsWidgets);
  });

  appTest('empty catalog shows the empty state, not a crash', (tester) async {
    final db = CatalogDb(NativeDatabase.memory());
    addTearDown(db.close);
    await pump(tester, db, locale: 'en');
    expect(find.byIcon(Icons.live_tv_rounded), findsWidgets);
  });

  test('search matches hamza-less Arabic, English and channel number', () async {
    final db = await seeded();
    addTearDown(db.close);
    final repo = CatalogRepository(db);
    Future<List<String>> q(String s) async => (await repo.watchChannels(ChannelFilter(query: s)).first).map((c) => c.id).toList();
    expect(await q('الجزيره'), ['c1']);
    expect(await q('space'), ['c2']);
    expect(await q('2'), ['c2']);
  });

  test('category filter', () async {
    final db = await seeded();
    addTearDown(db.close);
    final rows = await CatalogRepository(db).watchChannels(const ChannelFilter(category: 'kids')).first;
    expect(rows.map((c) => c.id), ['c2']);
  });
}
