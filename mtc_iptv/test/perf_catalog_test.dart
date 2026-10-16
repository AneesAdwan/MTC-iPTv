// الأداء (§26.1): كتالوج محلي بـ 10,000 قناة و20,000 رابط — البحث والتصفية والعدّ والذاكرة.
// حدود سخية تمنع التراجع؛ الأرقام الفعلية تُطبع وتُوثَّق في docs/releases/3.0.0-windows.md.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/catalog/catalog_repository.dart';
import 'package:mtc_iptv/data/catalog/catalog_sync.dart';

void main() {
  test('10,000 channels: load, search, filter, counts, memory', () async {
    final rss0 = ProcessInfo.currentRss;
    final db = CatalogDb(NativeDatabase.memory());
    addTearDown(db.close);
    const cats = ['news', 'sports', 'kids', 'movies', 'music', 'religious', 'docs', 'general'];
    const ccs = ['SA', 'AE', 'EG', 'JO', 'QA', 'KW', 'MA', 'IQ'];

    final sw = Stopwatch()..start();
    await db.batch((b) {
      b.insertAll(db.channels, [
        for (var i = 0; i < 10000; i++)
          ChannelsCompanion.insert(
            id: 'c$i',
            uid: 'Ch$i.x',
            number: Value(i + 1),
            nameAr: Value('قناة رقم $i'),
            nameEn: Value('Channel $i'),
            category: Value(cats[i % cats.length]),
            country: Value(ccs[i % ccs.length]),
            featured: Value(i % 97 == 0),
            search: Value(CatalogSync.searchKey({'name_ar': 'قناة رقم $i', 'name_en': 'Channel $i', 'number': i + 1})),
          ),
      ]);
      b.insertAll(db.streams, [
        for (var i = 0; i < 20000; i++)
          StreamsCompanion.insert(id: 's$i', channelId: 'c${i ~/ 2}', url: 'https://cdn.example/$i.m3u8', priority: Value(i % 2)),
      ]);
    });
    final tLoad = sw.elapsedMilliseconds;
    final repo = CatalogRepository(db);

    Future<(int, int)> timed(ChannelFilter f) async {
      final s = Stopwatch()..start();
      final rows = await repo.watchChannels(f).first;
      return (rows.length, s.elapsedMilliseconds);
    }

    final all = await timed(const ChannelFilter());
    final search = await timed(const ChannelFilter(query: 'قناه رقم 9999'));
    final searchEn = await timed(const ChannelFilter(query: 'channel 42'));
    final byNumber = await timed(const ChannelFilter(query: '5000'));
    final cat = await timed(const ChannelFilter(category: 'sports'));
    final sw2 = Stopwatch()..start();
    final countries = await repo.watchCountries().first;
    final categories = await repo.watchCategories().first;
    final tCounts = sw2.elapsedMilliseconds;
    final sw3 = Stopwatch()..start();
    final streams = await repo.streamsFor('c1234');
    final tStreams = sw3.elapsedMilliseconds;
    final rssMb = (ProcessInfo.currentRss - rss0) / 1048576;

    // ignore: avoid_print
    print('perf: load ${tLoad}ms · all ${all.$2}ms (${all.$1}) · search-ar ${search.$2}ms (${search.$1}) · '
        'search-en ${searchEn.$2}ms (${searchEn.$1}) · number ${byNumber.$2}ms · category ${cat.$2}ms (${cat.$1}) · '
        'counts ${tCounts}ms · streams ${tStreams}ms · +RSS ${rssMb.toStringAsFixed(0)}MB');

    expect(all.$1, 10000);
    expect(search.$1, greaterThanOrEqualTo(1));
    expect(cat.$1, 1250);
    expect(streams.length, 2);
    expect(countries, isNotNull);
    expect(categories, isNotNull);
    for (final t in [all.$2, search.$2, searchEn.$2, byNumber.$2, cat.$2, tCounts, tStreams]) {
      expect(t, lessThan(3000));
    }
  });
}
