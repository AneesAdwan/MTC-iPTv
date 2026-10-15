// مستودع الكتالوج للمشاهدة: كل الشاشات تقرأ من القاعدة المحلية (فوري، ويعمل دون اتصال — §22).
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/backend/backend.dart';
import '../../core/storage/catalog_db.dart';

class ChannelFilter {
  final String? country, category, language, query;
  final bool featuredOnly;
  const ChannelFilter({this.country, this.category, this.language, this.query, this.featuredOnly = false});

  @override
  bool operator ==(Object other) =>
      other is ChannelFilter &&
      other.country == country &&
      other.category == category &&
      other.language == language &&
      other.query == query &&
      other.featuredOnly == featuredOnly;
  @override
  int get hashCode => Object.hash(country, category, language, query, featuredOnly);
}

class CountWith<T> {
  final T item;
  final int count;
  const CountWith(this.item, this.count);
}

class CatalogRepository {
  final CatalogDb db;
  CatalogRepository(this.db);

  Stream<List<ChannelRow>> watchChannels(ChannelFilter f, {int? limit}) {
    final q = db.select(db.channels);
    if (f.country != null) q.where((c) => c.country.equals(f.country!));
    if (f.category != null) q.where((c) => c.category.equals(f.category!) | c.categories.like('%"${f.category}"%'));
    if (f.language != null) q.where((c) => c.language.equals(f.language!));
    if (f.featuredOnly) q.where((c) => c.featured.equals(true));
    final query = f.query?.trim() ?? '';
    if (query.isNotEmpty) {
      // كل كلمة مطبّعة يجب أن تظهر في مفتاح البحث (عربي بلا همزات، إنجليزي، أسماء بديلة، أو رقم)
      final number = int.tryParse(query);
      if (number != null) {
        q.where((c) => c.number.equals(number) | c.search.like('%$query%'));
      } else {
        for (final w in query.split(RegExp(r'\s+')).map(matchKey).where((w) => w.isNotEmpty)) {
          q.where((c) => c.search.like('%$w%'));
        }
      }
    }
    q.orderBy([(c) => OrderingTerm(expression: c.number, nulls: NullsOrder.last), (c) => OrderingTerm(expression: c.nameEn)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Stream<List<ChannelRow>> watchRecent({int limit = 20}) => (db.select(db.channels)
        ..where((c) => c.publishedAt.isNotNull())
        ..orderBy([(c) => OrderingTerm.desc(c.publishedAt)])
        ..limit(limit))
      .watch();

  Future<ChannelRow?> channel(String id) => (db.select(db.channels)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// الروابط مرتبة: أولوية المدير، ثم درجة الصحة (§12.5)، والمعطّلة أخيرًا.
  Future<List<StreamRow>> streamsFor(String channelId) async {
    final rows = await (db.select(db.streams)..where((s) => s.channelId.equals(channelId))).get();
    int healthRank(String h) => switch (h) { 'playable' => 0, 'reachable' => 1, 'degraded' => 2, 'inconclusive' => 3, 'geo_restricted' => 4, _ => 5 };
    rows.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      if (p != 0) return p;
      final h = healthRank(a.health).compareTo(healthRank(b.health));
      if (h != 0) return h;
      return (b.score ?? -1).compareTo(a.score ?? -1);
    });
    return rows;
  }

  /// ترتيب كل القنوات بالرقم — للقناة التالية/السابقة في المشغّل ووضع التلفاز.
  Future<List<String>> orderedIds() async {
    final rows = await (db.selectOnly(db.channels)
          ..addColumns([db.channels.id])
          ..orderBy([OrderingTerm(expression: db.channels.number, nulls: NullsOrder.last), OrderingTerm(expression: db.channels.nameEn)]))
        .get();
    return [for (final r in rows) r.read(db.channels.id)!];
  }

  Future<ChannelRow?> byNumber(int n) => (db.select(db.channels)..where((c) => c.number.equals(n))).getSingleOrNull();

  Stream<List<CountWith<CountryRow>>> watchCountries() {
    final count = db.channels.id.count();
    final q = db.select(db.countries).join([innerJoin(db.channels, db.channels.country.equalsExp(db.countries.code))])
      ..addColumns([count])
      ..groupBy([db.countries.code])
      ..orderBy([OrderingTerm.desc(db.countries.isArab), OrderingTerm.desc(count), OrderingTerm.asc(db.countries.sort)]);
    return q.watch().map((rows) => [for (final r in rows) CountWith(r.readTable(db.countries), r.read(count)!)]);
  }

  Stream<List<CountWith<CategoryRow>>> watchCategories() {
    final count = db.channels.id.count();
    final q = db.select(db.categories).join([innerJoin(db.channels, db.channels.category.equalsExp(db.categories.slug))])
      ..addColumns([count])
      ..groupBy([db.categories.slug])
      ..orderBy([OrderingTerm.asc(db.categories.sort)]);
    return q.watch().map((rows) => [for (final r in rows) CountWith(r.readTable(db.categories), r.read(count)!)]);
  }

  Future<CountryRow?> country(String code) => (db.select(db.countries)..where((c) => c.code.equals(code))).getSingleOrNull();
  Future<CategoryRow?> category(String slug) => (db.select(db.categories)..where((c) => c.slug.equals(slug))).getSingleOrNull();

  // ── المفضلة ──────────────────────────────────────────────────────────────
  Stream<List<ChannelRow>> watchFavorites() {
    final q = db.select(db.channels).join([innerJoin(db.favorites, db.favorites.channelId.equalsExp(db.channels.id))])
      ..orderBy([OrderingTerm.asc(db.favorites.position)]);
    return q.watch().map((rows) => [for (final r in rows) r.readTable(db.channels)]);
  }

  Stream<bool> watchIsFavorite(String id) =>
      (db.select(db.favorites)..where((f) => f.channelId.equals(id))).watchSingleOrNull().map((r) => r != null);

  Future<void> toggleFavorite(String id) => db.transaction(() async {
        final existing = await (db.select(db.favorites)..where((f) => f.channelId.equals(id))).getSingleOrNull();
        if (existing != null) {
          await (db.delete(db.favorites)..where((f) => f.channelId.equals(id))).go();
        } else {
          final max = db.favorites.position.max();
          final last = await (db.selectOnly(db.favorites)..addColumns([max])).getSingle();
          await db.into(db.favorites).insert(FavoritesCompanion.insert(channelId: id, position: (last.read(max) ?? 0) + 1, addedAt: DateTime.now()));
        }
      });

  Future<void> moveFavorite(String id, int newIndex) => db.transaction(() async {
        final ids = (await (db.select(db.favorites)..orderBy([(f) => OrderingTerm.asc(f.position)])).get()).map((f) => f.channelId).toList();
        ids.remove(id);
        ids.insert(newIndex.clamp(0, ids.length), id);
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.favorites)..where((f) => f.channelId.equals(ids[i]))).write(FavoritesCompanion(position: Value(i)));
        }
      });

  // ── السجل ────────────────────────────────────────────────────────────────
  Future<void> recordWatch(String id) => db.into(db.history).insertOnConflictUpdate(HistoryCompanion.insert(channelId: id, watchedAt: DateTime.now()));

  Future<void> clearHistory() => db.delete(db.history).go();

  /// وقت آخر مزامنة ناجحة للكتالوج (V-10).
  Stream<DateTime?> watchLastSync() => (db.select(db.syncState)..where((s) => s.key.equals('synced_at')))
      .watchSingleOrNull()
      .map((r) => r == null ? null : DateTime.tryParse(r.value)?.toLocal());

  Stream<List<ChannelRow>> watchHistory({int limit = 12}) {
    final q = db.select(db.channels).join([innerJoin(db.history, db.history.channelId.equalsExp(db.channels.id))])
      ..orderBy([OrderingTerm.desc(db.history.watchedAt)])
      ..limit(limit);
    return q.watch().map((rows) => [for (final r in rows) r.readTable(db.channels)]);
  }
}

final catalogRepoProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(catalogDbProvider)));

// ── أسماء معروضة حسب اللغة ────────────────────────────────────────────────
extension ChannelNameX on ChannelRow {
  String displayName(Locale l) => l.languageCode == 'ar' ? (nameAr ?? nameEn ?? uid) : (nameEn ?? nameAr ?? uid);
}

extension CountryNameX on CountryRow {
  String displayName(Locale l) => l.languageCode == 'ar' ? nameAr : nameEn;
}

extension CategoryNameX on CategoryRow {
  String displayName(Locale l) => l.languageCode == 'ar' ? nameAr : nameEn;
}
