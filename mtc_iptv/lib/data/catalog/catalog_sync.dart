// المزامنة التفاضلية للكتالوج (§22، الدالة catalog_changes في الترحيل 0002):
// يطلب ما تغيّر منذ آخر رقم (catalog_rev) على صفحات، ويطبّق كل صفحة في معاملة واحدة.
// القنوات غير المنشورة تصل كمعرّفات حذف فقط، فلا يرى المشاهد شيئًا غير منشور.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/log.dart';
import '../../core/storage/catalog_db.dart';

/// مصدر التغييرات (مجرّد للاختبار).
abstract interface class CatalogApi {
  Future<Map<String, dynamic>> changes({required int since, required int maxRows});

  /// الدول/الفئات/اللغات المرئية (صغيرة: تُجلب كاملة).
  Future<({List<Map> countries, List<Map> categories, List<Map> languages})> reference();
}

class SupabaseCatalogApi implements CatalogApi {
  final SupabaseClient client;
  SupabaseCatalogApi(this.client);

  @override
  Future<Map<String, dynamic>> changes({required int since, required int maxRows}) async =>
      Map<String, dynamic>.from(await client.rpc('catalog_changes', params: {'since': since, 'max_rows': maxRows}) as Map);

  @override
  Future<({List<Map> countries, List<Map> categories, List<Map> languages})> reference() async {
    final r = await Future.wait([
      client.from('countries').select('code,name_ar,name_en,flag_emoji,continent,is_arab,sort_order'),
      client.from('categories').select('slug,name_ar,name_en,icon,hue,sort_order'),
      client.from('languages').select('code,name_ar,name_en'),
    ]);
    return (countries: r[0].cast<Map>(), categories: r[1].cast<Map>(), languages: r[2].cast<Map>());
  }
}

class SyncResult {
  final int pages, channelsUpserted, streamsUpserted, channelsRemoved, streamsRemoved, fromRev, toRev;
  const SyncResult(this.pages, this.channelsUpserted, this.streamsUpserted, this.channelsRemoved, this.streamsRemoved, this.fromRev, this.toRev);
  bool get changed => toRev != fromRev;
  @override
  String toString() => 'sync rev $fromRev→$toRev pages=$pages ch+$channelsUpserted/-$channelsRemoved st+$streamsUpserted/-$streamsRemoved';
}

class CatalogSync {
  final CatalogDb db;
  final CatalogApi api;
  final int pageSize;
  CatalogSync(this.db, this.api, {this.pageSize = 2000});

  /// البيانات المرجعية: استبدال كامل في معاملة واحدة (صغيرة، وتتغيّر نادرًا).
  Future<void> syncReference() async {
    final r = await api.reference();
    await db.transaction(() async {
      await db.delete(db.countries).go();
      await db.delete(db.categories).go();
      await db.delete(db.languages).go();
      await db.batch((b) {
        b.insertAll(db.countries, [
          for (final c in r.countries)
            CountriesCompanion.insert(
              code: c['code'] as String,
              nameAr: c['name_ar'] as String,
              nameEn: c['name_en'] as String,
              flag: Value(c['flag_emoji'] as String?),
              continent: Value(c['continent'] as String?),
              isArab: Value(c['is_arab'] == true),
              sort: Value((c['sort_order'] as num?)?.toInt() ?? 100),
            ),
        ]);
        b.insertAll(db.categories, [
          for (final c in r.categories)
            CategoriesCompanion.insert(
              slug: c['slug'] as String,
              nameAr: c['name_ar'] as String,
              nameEn: c['name_en'] as String,
              icon: Value((c['icon'] as String?) ?? 'tv'),
              hue: Value((c['hue'] as num?)?.toInt() ?? 220),
              sort: Value((c['sort_order'] as num?)?.toInt() ?? 100),
            ),
        ]);
        b.insertAll(db.languages, [
          for (final l in r.languages) LanguagesCompanion.insert(code: l['code'] as String, nameAr: l['name_ar'] as String, nameEn: l['name_en'] as String),
        ]);
      });
    });
  }

  Future<SyncResult> run({int maxPages = 50}) async {
    final from = await db.catalogRev();
    var rev = from, pages = 0, chUp = 0, stUp = 0, chRm = 0, stRm = 0;
    while (pages < maxPages) {
      final page = await api.changes(since: rev, maxRows: pageSize);
      pages++;
      final next = (page['rev'] as num).toInt();
      final channels = (page['channels'] as List).cast<Map>();
      final streams = (page['streams'] as List).cast<Map>();
      final removedCh = (page['removed_channels'] as List).cast<String>();
      final removedSt = (page['removed_streams'] as List).cast<String>();

      await db.transaction(() async {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.channels, channels.map(_channel).toList());
          b.insertAllOnConflictUpdate(db.streams, streams.map(_stream).toList());
          if (removedCh.isNotEmpty) {
            b.deleteWhere(db.channels, (c) => c.id.isIn(removedCh));
            b.deleteWhere(db.streams, (s) => s.channelId.isIn(removedCh));
          }
          if (removedSt.isNotEmpty) b.deleteWhere(db.streams, (s) => s.id.isIn(removedSt));
        });
        await db.setSyncValue('catalog_rev', '$next');
        await db.setSyncValue('synced_at', DateTime.now().toUtc().toIso8601String());
      });
      chUp += channels.length;
      stUp += streams.length;
      chRm += removedCh.length;
      stRm += removedSt.length;
      final more = page['more'] == true;
      if (!more || next == rev) {
        rev = next;
        break;
      }
      rev = next;
    }
    final r = SyncResult(pages, chUp, stUp, chRm, stRm, from, rev);
    log.info(r.toString());
    return r;
  }

  static ChannelsCompanion _channel(Map j) => ChannelsCompanion.insert(
        id: j['id'] as String,
        uid: j['uid'] as String,
        number: Value(j['number'] as int?),
        nameAr: Value(j['name_ar'] as String?),
        nameEn: Value(j['name_en'] as String?),
        altNames: Value(jsonEncode(j['alt_names'] ?? const [])),
        network: Value(j['network'] as String?),
        logoUrl: Value(j['logo_url'] as String?),
        country: Value(j['country'] as String?),
        category: Value(j['category'] as String?),
        categories: Value(jsonEncode(j['categories'] ?? const [])),
        language: Value(j['language'] as String?),
        quality: Value(j['quality'] as String?),
        featured: Value(j['featured'] == true),
        sort: Value((j['sort'] as num?)?.toInt() ?? 0),
        epgId: Value(j['epg_id'] as String?),
        epgOffset: Value((j['epg_offset'] as num?)?.toInt() ?? 0),
        family: Value(j['family'] as String?),
        parental: Value(j['parental'] == true),
        publishedAt: Value(j['published_at'] == null ? null : DateTime.tryParse(j['published_at'] as String)),
        search: Value(searchKey(j)),
      );

  /// كل ما يمكن البحث به، مطبّعًا: الاسمان، الأسماء البديلة، الشبكة، والرقم.
  static String searchKey(Map j) => [
        j['name_ar'], j['name_en'], ...?(j['alt_names'] as List?), j['network'],
      ].whereType<String>().map(matchKey).join(' ') + (j['number'] == null ? '' : ' #${j['number']}');

  static StreamsCompanion _stream(Map j) => StreamsCompanion.insert(
        id: j['id'] as String,
        channelId: j['channel_id'] as String,
        url: j['url'] as String,
        label: Value(j['label'] as String?),
        quality: Value(j['quality'] as String?),
        priority: Value((j['priority'] as num?)?.toInt() ?? 0),
        userAgent: Value(j['user_agent'] as String?),
        referrer: Value(j['referrer'] as String?),
        headers: Value(jsonEncode(j['headers'] ?? const {})),
        protocol: Value(j['protocol'] as String?),
        health: Value((j['health'] as String?) ?? 'inconclusive'),
        score: Value((j['score'] as num?)?.toInt()),
      );
}
