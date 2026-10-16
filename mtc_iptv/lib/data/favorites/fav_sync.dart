// مزامنة المفضلة برمز بلا حساب (§8.3، §19.5).
//  • «إنشاء رمز»: الخادم يولّد الرمز (8 أحرف) وسرّ التعديل؛ السرّ يبقى على هذا الجهاز فقط.
//  • «ربط برمز» على جهاز آخر:
//      - الرمز وحده ← متابعة للقراءة: تُدمج قائمة الرمز مع المحلية (لا يُحذف شيء محليًا).
//      - «مفتاح التعديل» (الرمز-السرّ) ← مزامنة بالاتجاهين: القائمة المشتركة هي المرجع.
//  • جهاز يملك السرّ يرفع كل تغيير تلقائيًا (بعد ثانيتين)، وكل الأجهزة تسحب عند التشغيل.
import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../core/backend/backend.dart';
import '../../core/logging/log.dart';
import '../../core/storage/catalog_db.dart';

class FavLink {
  final String code;
  final String? secret;
  final DateTime? remoteUpdated;
  const FavLink(this.code, {this.secret, this.remoteUpdated});
  bool get canEdit => secret != null;

  /// ما يُعطى لجهاز آخر ليعدّل أيضًا.
  String? get editKey => secret == null ? null : '$code-$secret';

  Map<String, dynamic> toJson() => {'code': code, 'secret': ?secret, 'remote_updated': ?remoteUpdated?.toIso8601String()};
  factory FavLink.fromJson(Map<String, dynamic> j) =>
      FavLink('${j['code']}', secret: j['secret'] as String?, remoteUpdated: DateTime.tryParse('${j['remote_updated'] ?? ''}'));
  FavLink withRemote(DateTime? t) => FavLink(code, secret: secret, remoteUpdated: t);
}

/// يقبل «ABCD2345» أو «abcd 2345» أو مفتاح التعديل «ABCD2345-<48 hex>».
(String code, String? secret)? parseFavKey(String input) {
  final s = input.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
  final m = RegExp(r'^([A-HJ-NP-Z2-9]{8})(?:-([0-9A-F]{48}))?$').firstMatch(s);
  if (m == null) return null;
  return (m.group(1)!, m.group(2)?.toLowerCase());
}

/// دمج للمتابعة: ترتيب القائمة البعيدة أولًا ثم ما يوجد محليًا فقط.
List<String> mergeFavorites(List<String> remote, List<String> local) => [...remote, ...local.where((x) => !remote.contains(x))];

class FavSyncService {
  final Ref ref;
  FavSyncService(this.ref);
  CatalogDb get _db => ref.read(catalogDbProvider);
  List<String>? _lastSynced; // آخر قائمة رُفعت أو سُحبت (يمنع الرفع المكرر بعد السحب)

  Future<FavLink?> link() async {
    final row = await (_db.select(_db.syncState)..where((s) => s.key.equals('fav_link'))).getSingleOrNull();
    if (row == null) return null;
    try {
      return FavLink.fromJson((jsonDecode(row.value) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(FavLink? l) async {
    if (l == null) {
      await (_db.delete(_db.syncState)..where((s) => s.key.equals('fav_link'))).go();
    } else {
      await _db.setSyncValue('fav_link', jsonEncode(l.toJson()));
    }
  }

  Future<List<String>> localIds() async =>
      (await (_db.select(_db.favorites)..orderBy([(f) => OrderingTerm.asc(f.position)])).get()).map((f) => f.channelId).toList();

  Future<void> _setLocal(List<String> ids) => _db.transaction(() async {
        await _db.delete(_db.favorites).go();
        final now = DateTime.now();
        for (var i = 0; i < ids.length; i++) {
          await _db.into(_db.favorites).insert(FavoritesCompanion.insert(channelId: ids[i], position: i, addedAt: now));
        }
      });

  SupabaseClient get _c {
    final c = ref.read(supabaseProvider);
    if (c == null) throw StateError('offline');
    return c;
  }

  Future<FavLink> create() async {
    final ids = await localIds();
    final r = ((await _c.rpc('fav_create', params: {'p_favorites': ids})) as Map).cast<String, dynamic>();
    final l = FavLink('${r['code']}', secret: '${r['secret']}', remoteUpdated: DateTime.now().toUtc());
    _lastSynced = ids;
    await _save(l);
    return l;
  }

  /// ربط بجهاز آخر. يعيد false إن لم يوجد الرمز.
  Future<bool> join(String input) async {
    final k = parseFavKey(input);
    if (k == null) throw FormatException(input);
    final r = await _c.rpc('fav_get', params: {'p_code': k.$1});
    if (r == null) return false;
    final remote = [for (final x in (r['favorites'] as List? ?? const [])) '$x'];
    final merged = mergeFavorites(remote, await localIds());
    await _setLocal(merged);
    _lastSynced = merged;
    var l = FavLink(k.$1, secret: k.$2, remoteUpdated: DateTime.tryParse('${r['updated_at']}'));
    await _save(l);
    // بمفتاح التعديل: ما كان محليًا فقط يُضاف للقائمة المشتركة
    if (l.canEdit && merged.length != remote.length) {
      try {
        l = l.withRemote(DateTime.tryParse('${await _c.rpc('fav_put', params: {'p_code': l.code, 'p_secret': l.secret, 'p_favorites': merged})}'));
        await _save(l);
      } on Object catch (e) {
        // سرّ غير صحيح: يبقى الربط للقراءة فقط
        log.warning('fav join: edit key refused', e);
        await _save(FavLink(l.code, remoteUpdated: l.remoteUpdated));
      }
    }
    return true;
  }

  /// سحب عند التشغيل أو «زامن الآن». يعيد true إن تغيّرت القائمة المحلية.
  Future<bool> pull() async {
    final l = await link();
    if (l == null) return false;
    final r = await _c.rpc('fav_get', params: {'p_code': l.code});
    if (r == null) {
      log.info('fav set ${l.code} no longer exists (deleted or expired); keeping local list');
      await _save(null);
      return false;
    }
    final updated = DateTime.tryParse('${r['updated_at']}');
    if (l.remoteUpdated != null && updated != null && !updated.isAfter(l.remoteUpdated!)) return false;
    final remote = [for (final x in (r['favorites'] as List? ?? const [])) '$x'];
    final local = await localIds();
    final next = l.canEdit ? remote : mergeFavorites(remote, local);
    _lastSynced = next;
    await _save(l.withRemote(updated));
    if (_same(next, local)) return false;
    await _setLocal(next);
    return true;
  }

  /// رفع القائمة المحلية (لمن يملك السرّ فقط).
  Future<void> push() async {
    final l = await link();
    if (l == null || !l.canEdit) return;
    final ids = await localIds();
    if (_lastSynced != null && _same(ids, _lastSynced!)) return;
    final t = await _c.rpc('fav_put', params: {'p_code': l.code, 'p_secret': l.secret, 'p_favorites': ids});
    _lastSynced = ids;
    await _save(l.withRemote(DateTime.tryParse('$t')));
  }

  Future<void> unlink({bool deleteRemote = false}) async {
    final l = await link();
    if (l == null) return;
    if (deleteRemote && l.canEdit) {
      await _c.rpc('fav_delete', params: {'p_code': l.code, 'p_secret': l.secret});
    }
    _lastSynced = null;
    await _save(null);
  }

  static bool _same(List<String> a, List<String> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
}

final favSyncProvider = Provider<FavSyncService>(FavSyncService.new);

final favLinkProvider = StreamProvider<FavLink?>((ref) {
  final db = ref.watch(catalogDbProvider);
  return (db.select(db.syncState)..where((s) => s.key.equals('fav_link'))).watchSingleOrNull().map((row) {
    if (row == null) return null;
    try {
      return FavLink.fromJson((jsonDecode(row.value) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  });
});

/// سحب عند التشغيل (بعد مزامنة الكتالوج)، ثم رفع تلقائي لكل تغيير محلي (بعد ثانيتين).
final favSyncAutoProvider = Provider<void>((ref) {
  final s = ref.read(favSyncProvider);
  ref.listen(startupSyncProvider, (_, next) {
    if (next.hasValue) {
      unawaited(s.pull().catchError((Object e) {
        log.fine('fav pull: $e');
        return false;
      }));
    }
  });
  final db = ref.read(catalogDbProvider);
  Timer? debounce;
  final sub = db.select(db.favorites).watch().listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () => s.push().catchError((Object e) => log.fine('fav push: $e')));
  });
  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
  });
});
