// الاتصال بالخادم (ADR-03): تهيئة Supabase + مزوّدات Riverpod للعميل وقاعدة الكتالوج والمزامنة.
// جلسة المدير تُحفظ في مخزن النظام الآمن (§19.1-9): Credential Manager / Keychain / Keystore.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/catalog/catalog_sync.dart';
import '../config/env.dart';
import '../logging/log.dart';
import '../storage/catalog_db.dart';

class SecureSessionStorage extends LocalStorage {
  static const _key = 'mtc.supabase.session';
  final _s = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => _s.containsKey(key: _key);
  @override
  Future<String?> accessToken() => _s.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) => _s.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _s.delete(key: _key);
}

/// يُستدعى مرة قبل runApp. بلا خادم (staging غير مُعدّ) يعمل التطبيق من الكتالوج المحلي فقط.
Future<bool> initBackend() async {
  if (!Env.hasBackend) {
    log.warning('no backend configured for env=${Env.name}; running offline');
    return false;
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey, // يقبل مفتاح anon القديم أو sb_publishable_
    authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage(), autoRefreshToken: true),
    debug: false,
  );
  log.info('backend ${Uri.parse(Env.supabaseUrl).host}');
  return true;
}

/// null عندما لا يوجد خادم مُعدّ (أو في الاختبارات).
final supabaseProvider = Provider<SupabaseClient?>((_) => null);

final catalogDbProvider = Provider<CatalogDb>((ref) {
  final db = CatalogDb();
  ref.onDispose(db.close);
  return db;
});

final catalogSyncProvider = Provider<CatalogSync?>((ref) {
  final client = ref.watch(supabaseProvider);
  if (client == null) return null;
  return CatalogSync(ref.watch(catalogDbProvider), SupabaseCatalogApi(client));
});

/// مزامنة عند البدء (في الخلفية)؛ الشاشات تقرأ من القاعدة المحلية فورًا ولا تنتظرها.
final startupSyncProvider = FutureProvider<SyncResult?>((ref) async {
  final sync = ref.watch(catalogSyncProvider);
  if (sync == null) return null;
  try {
    // المرجعية أولًا (أسماء الدول والفئات للشاشات)، ثم القنوات
    await sync.syncReference().catchError((Object e) => log.warning('reference sync failed', e));
    return await sync.run();
  } catch (e, s) {
    log.warning('catalog sync failed (offline?)', e, s);
    return null;
  }
});
