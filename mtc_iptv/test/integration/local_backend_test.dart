// اختبار شامل ضد Supabase المحلي (Docker): الدخول بخطوتين + is_admin على الخادم + المزامنة.
// يتطلب:  supabase start   ثم:
//   $env:MTC_LOCAL_SERVICE_KEY = (supabase status -o env | sls '^SERVICE_ROLE_KEY').Line.Split('"')[1]
//   flutter test --tags local
// مفتاح service_role هنا للقاعدة المحلية التجريبية فقط، يُقرأ من البيئة ولا يُكتب في أي ملف.
@Tags(['local'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mtc_iptv/core/config/env.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/catalog/catalog_sync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const url = 'http://127.0.0.1:58321';
final anonKey = Env.supabaseAnonKeyFor(AppEnv.local);
final serviceKey = Platform.environment['MTC_LOCAL_SERVICE_KEY'] ?? '';

/// RFC 6238 TOTP (SHA-1، 6 أرقام، 30 ثانية) — كما تولّده تطبيقات المصادقة.
String totp(String base32Secret, {DateTime? at}) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final bits = base32Secret.toUpperCase().replaceAll('=', '').split('').map((c) => alphabet.indexOf(c).toRadixString(2).padLeft(5, '0')).join();
  final key = Uint8List.fromList([for (var i = 0; i + 8 <= bits.length; i += 8) int.parse(bits.substring(i, i + 8), radix: 2)]);
  final counter = (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 30000;
  final msg = ByteData(8)..setInt64(0, counter);
  final h = Hmac(sha1, key).convert(msg.buffer.asUint8List()).bytes;
  final o = h.last & 0xf;
  final code = ((h[o] & 0x7f) << 24 | h[o + 1] << 16 | h[o + 2] << 8 | h[o + 3]) % 1000000;
  return code.toString().padLeft(6, '0');
}

Future<http.Response> admin(String method, String path, [Object? body]) {
  final req = http.Request(method, Uri.parse('$url$path'))
    ..headers.addAll({'apikey': serviceKey, 'Authorization': 'Bearer $serviceKey', 'Content-Type': 'application/json', 'Prefer': 'return=representation'});
  if (body != null) req.body = jsonEncode(body);
  return http.Client().send(req).then(http.Response.fromStream);
}

void main() {
  final skip = serviceKey.isEmpty ? 'set MTC_LOCAL_SERVICE_KEY and run supabase start' : null;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'admin$stamp@test.local', password = 'Test-$stamp-pass!';
  late String userId;

  setUpAll(() async {
    if (skip != null) return;
    final u = await admin('POST', '/auth/v1/admin/users', {'email': email, 'password': password, 'email_confirm': true});
    expect(u.statusCode, anyOf(200, 201), reason: u.body);
    userId = (jsonDecode(u.body) as Map)['id'] as String;
    final a = await admin('POST', '/rest/v1/admin_users', {'user_id': userId});
    expect(a.statusCode, anyOf(200, 201), reason: a.body);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin('DELETE', '/auth/v1/admin/users/$userId'); // cascade removes admin_users row
  });

  test('admin: password alone is NOT enough; TOTP makes the session admin (server-side)', () async {
    final c = SupabaseClient(url, anonKey);
    await c.auth.signInWithPassword(email: email, password: password);

    var status = Map<String, dynamic>.from(await c.rpc('admin_status') as Map);
    expect(status['is_admin_user'], isTrue);
    expect(status['aal'], 'aal1');
    expect(status['is_admin'], isFalse, reason: 'password only -> not admin');
    await expectLater(c.rpc('admin_task_acquire', params: {'p_key': 'epg', 'p_device': 'test'}), throwsA(isA<PostgrestException>()),
        reason: 'server refuses admin RPC without MFA');

    final enroll = await c.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MTC-iPTv', friendlyName: 'test');
    await c.auth.mfa.challengeAndVerify(factorId: enroll.id, code: totp(enroll.totp!.secret));
    await c.auth.refreshSession();

    status = Map<String, dynamic>.from(await c.rpc('admin_status') as Map);
    expect(status['aal'], 'aal2');
    expect(status['is_admin'], isTrue, reason: 'admin + TOTP -> admin');
    expect(await c.rpc('admin_task_acquire', params: {'p_key': 'epg', 'p_device': 'test-$stamp'}), isA<bool>());

    // a wrong code is rejected
    final f = (await c.auth.mfa.listFactors()).totp.first;
    await expectLater(c.auth.mfa.challengeAndVerify(factorId: f.id, code: '000000'), throwsA(isA<AuthException>()));
    await c.auth.signOut();
  }, skip: skip);

  test('viewer: catalog sync pulls only published channels into the local DB', () async {
    // publish 3 channels on the local DB through the legacy columns (review-gate path the old panel uses)
    final ids = ((jsonDecode((await admin('GET', '/rest/v1/channels?select=id&order=number&limit=3')).body) as List)).map((e) => e['id']).toList();
    final hide = ((jsonDecode((await admin('GET', '/rest/v1/channels?select=id&order=number&offset=3&limit=1')).body) as List)).map((e) => e['id']).toList();
    for (final id in ids) {
      await admin('PATCH', '/rest/v1/channels?id=eq.$id', {'publish_state': 'published'});
    }
    await admin('PATCH', '/rest/v1/channels?id=eq.${hide.first}', {'publish_state': 'hidden'});

    final db = CatalogDb(NativeDatabase.memory());
    addTearDown(db.close);
    final sync = CatalogSync(db, SupabaseCatalogApi(SupabaseClient(url, anonKey)), pageSize: 500);
    final r = await sync.run();
    final local = await db.select(db.channels).get();
    expect(local.map((c) => c.id), containsAll(ids));
    expect(local.map((c) => c.id), isNot(contains(hide.first)), reason: 'hidden channels never reach viewers');
    expect(await db.select(db.streams).get(), isNotEmpty);
    expect(r.toRev, greaterThan(0));

    // second run with nothing new: same revision, nothing upserted
    final again = await sync.run();
    expect(again.toRev, r.toRev);
    expect(again.channelsUpserted, 0);

    // un-publishing reaches the device as a removal
    await admin('PATCH', '/rest/v1/channels?id=eq.${ids.first}', {'publish_state': 'hidden'});
    final third = await sync.run();
    expect(third.channelsRemoved, greaterThanOrEqualTo(1));
    expect((await db.select(db.channels).get()).map((c) => c.id), isNot(contains(ids.first)));
  }, skip: skip);
}
