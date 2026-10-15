// دليل البرامج (V-07، §11): نسخة محلية من epg_programmes تُقرأ منها كل الشاشات (فورية ودون اتصال).
// المزامنة: كل 6 ساعات على الأكثر، نافذة من قبل 6 ساعات حتى آخر ما يتوفر، استبدال كامل داخل معاملة.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend.dart';
import '../../core/logging/log.dart';
import '../../core/storage/catalog_db.dart';

abstract class EpgApi {
  /// صفحة من البرامج التي تنتهي بعد [since]، مرتبة (channel_uid, start_at).
  Future<List<Map<String, dynamic>>> page(DateTime since, int from, int to);
}

class SupabaseEpgApi implements EpgApi {
  final SupabaseClient client;
  SupabaseEpgApi(this.client);
  @override
  Future<List<Map<String, dynamic>>> page(DateTime since, int from, int to) => client
      .from('epg_programmes')
      .select('channel_uid,start_at,end_at,title,description,category')
      .gte('end_at', since.toUtc().toIso8601String())
      .order('channel_uid', ascending: true) // postgrest-dart: الافتراضي تنازلي
      .order('start_at', ascending: true)
      .range(from, to);
}

/// البرنامج الحالي والتالي لقناة.
class NowNext {
  final ProgrammeRow? now, next;
  const NowNext(this.now, this.next);
  double progress(DateTime t) {
    final n = now;
    if (n == null) return 0;
    final total = n.endAt.difference(n.startAt).inSeconds;
    return total <= 0 ? 0 : (t.difference(n.startAt).inSeconds / total).clamp(0, 1).toDouble();
  }
}

class EpgRepository {
  static const pageSize = 1000;
  static const refreshEvery = Duration(hours: 6);
  final CatalogDb db;
  final EpgApi? api;
  EpgRepository(this.db, this.api);

  /// يجلب الدليل إن مضى وقت كافٍ منذ آخر مرة (أو [force]). يعيد عدد البرامج، أو null إن لم يُجلب.
  Future<int?> sync({bool force = false, DateTime? now}) async {
    final a = api;
    if (a == null) return null;
    final t = now ?? DateTime.now();
    final last = DateTime.tryParse((await (db.select(db.syncState)..where((s) => s.key.equals('epg_synced_at'))).getSingleOrNull())?.value ?? '');
    if (!force && last != null && t.difference(last) < refreshEvery) return null;

    final since = t.subtract(const Duration(hours: 6));
    final rows = <ProgrammesCompanion>[];
    for (var from = 0;; from += pageSize) {
      final page = await a.page(since, from, from + pageSize - 1);
      for (final r in page) {
        rows.add(ProgrammesCompanion.insert(
          channelUid: r['channel_uid'] as String,
          startAt: DateTime.parse(r['start_at'] as String),
          endAt: DateTime.parse(r['end_at'] as String),
          title: r['title'] as String,
          description: Value(r['description'] as String?),
          category: Value(r['category'] as String?),
        ));
      }
      if (page.length < pageSize) break;
    }
    await db.transaction(() async {
      await db.delete(db.programmes).go();
      await db.batch((b) => b.insertAllOnConflictUpdate(db.programmes, rows));
      await db.setSyncValue('epg_synced_at', t.toIso8601String());
    });
    log.info('epg sync ${rows.length} programmes');
    return rows.length;
  }

  /// البرامج المتقاطعة مع [from, to) لكل القنوات (شبكة الدليل).
  Stream<List<ProgrammeRow>> watchRange(DateTime from, DateTime to) => (db.select(db.programmes)
        ..where((p) => p.startAt.isSmallerThanValue(to) & p.endAt.isBiggerThanValue(from))
        ..orderBy([(p) => OrderingTerm.asc(p.channelUid), (p) => OrderingTerm.asc(p.startAt)]))
      .watch();

  Future<NowNext> nowNext(String channelUid, {DateTime? at}) async {
    final t = at ?? DateTime.now();
    final rows = await (db.select(db.programmes)
          ..where((p) => p.channelUid.equals(channelUid) & p.endAt.isBiggerThanValue(t))
          ..orderBy([(p) => OrderingTerm.asc(p.startAt)])
          ..limit(2))
        .get();
    if (rows.isEmpty) return const NowNext(null, null);
    final first = rows.first;
    return first.startAt.isAfter(t) ? NowNext(null, first) : NowNext(first, rows.length > 1 ? rows[1] : null);
  }

  /// الأيام المتوفرة في الدليل (بالتوقيت المحلي).
  Future<List<DateTime>> days() async {
    final min = db.programmes.startAt.min(), max = db.programmes.endAt.max();
    final r = await (db.selectOnly(db.programmes)..addColumns([min, max])).getSingle();
    final a = r.read(min), b = r.read(max);
    if (a == null || b == null) return const [];
    final out = <DateTime>[];
    for (var d = DateTime(a.toLocal().year, a.toLocal().month, a.toLocal().day); d.isBefore(b.toLocal()); d = DateTime(d.year, d.month, d.day + 1)) {
      out.add(d);
    }
    return out;
  }
}

final epgRepoProvider = Provider<EpgRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return EpgRepository(ref.watch(catalogDbProvider), client == null ? null : SupabaseEpgApi(client));
});

/// مزامنة الدليل بعد مزامنة الكتالوج (في الخلفية؛ فشلها لا يمنع شيئًا).
final epgSyncProvider = FutureProvider<int?>((ref) async {
  await ref.watch(startupSyncProvider.future);
  try {
    return await ref.watch(epgRepoProvider).sync();
  } catch (e, s) {
    log.warning('epg sync failed', e, s);
    return null;
  }
});

/// الحالي/التالي لقناة، يتجدد كل دقيقة.
final nowNextProvider = StreamProvider.family<NowNext, String>((ref, uid) async* {
  ref.watch(epgSyncProvider);
  final repo = ref.watch(epgRepoProvider);
  yield await repo.nowNext(uid);
  yield* Stream.periodic(const Duration(minutes: 1)).asyncMap((_) => repo.nowNext(uid));
});
