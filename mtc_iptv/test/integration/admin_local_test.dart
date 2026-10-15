// مركز الإدارة (المرحلة 4) ضد Supabase المحلي: كل استعلامات AdminRepository بجلسة مدير حقيقية (TOTP).
// التشغيل كما في local_backend_test.dart:  flutter test --tags local
@Tags(['local'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/data/admin/admin_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_backend_test.dart' show admin, anonKey, serviceKey, totp, url;

void main() {
  final skip = serviceKey.isEmpty ? 'set MTC_LOCAL_SERVICE_KEY and run supabase start' : null;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'adm$stamp@test.local', password = 'Test-$stamp-pass!';
  late String userId;
  late SupabaseClient c;
  late AdminRepository repo;

  setUpAll(() async {
    if (skip != null) return;
    final u = await admin('POST', '/auth/v1/admin/users', {'email': email, 'password': password, 'email_confirm': true});
    userId = (jsonDecode(u.body) as Map)['id'] as String;
    await admin('POST', '/rest/v1/admin_users', {'user_id': userId});
    c = SupabaseClient(url, anonKey);
    await c.auth.signInWithPassword(email: email, password: password);
    final f = await c.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MTC-iPTv', friendlyName: 't');
    await c.auth.mfa.challengeAndVerify(factorId: f.id, code: totp(f.totp!.secret));
    await c.auth.refreshSession();
    repo = AdminRepository(c);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await c.auth.signOut();
    await admin('DELETE', '/auth/v1/admin/users/$userId');
  });

  test('channel lifecycle: create, list, edit, streams, health, reports, audit, delete', () async {
    final number = 90000 + stamp % 9000;
    final id = await repo.createChannel(nameAr: 'قناة اختبار $stamp', nameEn: 'Test $stamp', number: number);
    await repo.addStream(id, url: 'https://example.com/$stamp/a.m3u8', label: 'A');
    await repo.addStream(id, url: 'https://example.com/$stamp/b.m3u8', label: 'B', priority: 1);

    // القائمة: بحث بالاسم وبالرقم، مع عمود الروابط
    final byName = await repo.channels(ChannelQuery(search: 'Test $stamp'));
    expect(byName.items.single.id, id);
    expect(byName.items.single.streamStates.length, 2);
    expect(byName.items.single.isManual, isTrue);
    expect((await repo.channels(ChannelQuery(search: '$number'))).items.single.id, id);
    expect(byName.total, 1);

    // التعديل بالأعمدة الجديدة يحدّث القديمة (مشغّل التوافق)
    await repo.updateChannel(id, {'publish_state': 'hidden', 'name_en': 'Test $stamp B'});
    final legacy = (jsonDecode((await admin('GET', '/rest/v1/channels?id=eq.$id&select=is_published,hidden_reason,name')).body) as List).single as Map;
    expect(legacy['is_published'], isFalse);
    expect(legacy['hidden_reason'], 'manual');
    expect(legacy['name'], 'Test $stamp B');
    expect((await repo.channels(const ChannelQuery(state: 'hidden', search: ''))).items.map((x) => x.id), contains(id));

    // الروابط: الترتيب، الصحة، والمعطّل لا يتغير بالفحص (D-14)
    var streams = await repo.streamsOf(id);
    expect(streams.map((s) => s.label), ['A', 'B']);
    await repo.reorderStreams([streams[1].id, streams[0].id]);
    streams = await repo.streamsOf(id);
    expect(streams.map((s) => s.label), ['B', 'A']);
    await repo.recordHealth(streams[0].id, state: 'playable', reason: 'L2: 1080p', http: 200, ms: 900, score: 100);
    await repo.updateStream(streams[1].id, {'health_state': 'disabled'});
    await repo.recordHealth(streams[1].id, state: 'playable', reason: 'should not apply');
    streams = await repo.streamsOf(id);
    expect(streams[0].healthState, 'playable');
    expect(streams[0].healthScore, 100);
    expect(streams[1].healthState, 'disabled', reason: 'checks never re-enable a disabled stream');
    final legacyStream = (jsonDecode((await admin('GET', '/rest/v1/streams?id=eq.${streams[1].id}&select=is_active')).body) as List).single as Map;
    expect(legacyStream['is_active'], isFalse);
    expect((await repo.streamsByHealth('playable')).map((r) => r.$1.id), contains(streams[0].id));

    // البلاغات: بلاغ من زائر ← يظهر مجمّعًا ← «تمّ الحل»
    final anon = SupabaseClient(url, anonKey);
    await anon.from('reports').insert({'channel_id': id, 'reason': 'not_working', 'note': 'test'});
    expect((await repo.openReports()).where((g) => g.channelId == id).single.reports.length, 1);
    await repo.resolveReports(id);
    expect((await repo.openReports()).where((g) => g.channelId == id), isEmpty);

    // لوحة المعلومات والسجل
    final d = await repo.dashboard();
    expect(d.channels, greaterThan(0));
    expect(d.streamsByHealth['playable'], greaterThanOrEqualTo(1));
    final history = await repo.recentAudit(rowId: id, limit: 20);
    expect(history.map((e) => e.action), containsAll(['INSERT', 'UPDATE']));
    expect(history.firstWhere((e) => e.action == 'UPDATE').changes.map((x) => x.$1), contains('publish_state'));

    // جماعي ثم حذف
    await repo.updateChannels([id], {'is_featured': true});
    expect((await repo.channel(id))!.isFeatured, isTrue);
    await repo.deleteChannels([id]);
    expect(await repo.channel(id), isNull);
    expect(await repo.streamsOf(id), isEmpty);
  }, skip: skip);

  test('batch 4b: review queue, renumbering, taxonomy, streams, task runs', () async {
    // قناة معلّقة (مسار الاستيراد القديم) برابط لم يُفحص ← دلو «لم تُفحص»
    final r = await admin('POST', '/rest/v1/channels', {'uid': 'review:$stamp', 'name': 'Review $stamp', 'is_published': false, 'hidden_reason': 'pending', 'country_code': null});
    final id = ((jsonDecode(r.body) as List).single as Map)['id'] as String;
    addTearDown(() => admin('DELETE', '/rest/v1/channels?id=eq.$id'));
    await admin('POST', '/rest/v1/streams', {'channel_id': id, 'url': 'https://example.com/review/$stamp.m3u8'});
    expect((await repo.reviewCounts())['unchecked'], greaterThanOrEqualTo(1));
    expect((await repo.reviewIds('unchecked')), contains(id));
    final (items, total) = await repo.reviewItems('unchecked');
    expect(total, greaterThanOrEqualTo(1));
    expect(items.map((x) => x['id']), contains(id));

    // بعد فحص ناجح ينتقل إلى «ناقصة» (بلا دولة) ثم الموافقة تنشره
    final s = (await repo.streamsOf(id)).single;
    await repo.recordHealth(s.id, state: 'playable', reason: 'test');
    expect(await repo.reviewIds('incomplete'), contains(id));
    expect(await repo.reviewApply('approve', [id]), 1);
    expect((await repo.channel(id))!.publishState, 'published');

    // الترقيم: معاينة ثم تطبيق ذري (الأرقام تبقى فريدة)
    final p = await repo.renumberPreview(['name'], start: 1);
    expect((p['total'] as num).toInt(), greaterThan(0));
    final n = await repo.renumberApply(['name'], start: 1);
    expect(n, (p['total'] as num).toInt());
    final nums = (jsonDecode((await admin('GET', '/rest/v1/channels?select=number&number=not.is.null')).body) as List).map((e) => e['number']).toList();
    expect(nums.toSet().length, nums.length, reason: 'numbers stay unique');

    // التقسيمات: إضافة، عدّ الاستخدام، حذف
    await repo.upsertTaxonomy('categories', {'slug': 'test-$stamp', 'name_ar': 'اختبار', 'name_en': 'Test', 'sort_order': 999, 'is_visible': false});
    expect((await repo.taxonomy('categories')).map((x) => x['slug']), contains('test-$stamp'));
    await repo.updateChannel(id, {'category_slug': 'test-$stamp'});
    expect((await repo.taxonomyUsage('categories'))['test-$stamp'], 1);
    await repo.updateChannel(id, {'category_slug': null});
    await repo.deleteTaxonomy('categories', 'test-$stamp');
    expect((await repo.taxonomy('categories')).map((x) => x['slug']), isNot(contains('test-$stamp')));

    // الروابط عبر القنوات + ملخّص النطاقات
    final (streams, count) = await repo.streams(host: 'example.com');
    expect(count, greaterThanOrEqualTo(1));
    expect(streams.map((x) => x.$1.id), contains(s.id));
    expect((await repo.hosts()).map((h) => h.$1), contains('example.com'));

    // سجل التشغيل (يتطلب is_admin = تحقق بخطوتين)
    final run = await repo.startRun('health_all', 'test-$stamp');
    await repo.finishRun(run!, status: 'ok', summary: {'checked': 1});
    final runs = await repo.taskRuns();
    expect(runs.firstWhere((x) => x['id'] == run)['status'], 'ok');
    expect(await repo.scheduledTasks(), isNotEmpty);
  }, skip: skip);
}
