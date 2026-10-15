// مركز الإدارة (المرحلة 4) ضد Supabase المحلي: كل استعلامات AdminRepository بجلسة مدير حقيقية (TOTP).
// التشغيل كما في local_backend_test.dart:  flutter test --tags local
@Tags(['local'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:mtc_iptv/data/admin/admin_repository.dart';
import 'package:mtc_iptv/data/admin/import_service.dart';
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

  test('phase 5a: import (dry run -> commit), sources without deletion, export', () async {
    // كتالوج قائم: قناة بمعرّف tvg ورابط
    final r0 = await admin('POST', '/rest/v1/channels', {'uid': 'Imp$stamp.sa', 'name': 'Existing $stamp', 'country_code': null});
    final existingId = ((jsonDecode(r0.body) as List).single as Map)['id'] as String;
    await admin('POST', '/rest/v1/streams', {'channel_id': existingId, 'url': 'https://example.com/imp/$stamp/old.m3u8'});
    final created = <String>[existingId];
    addTearDown(() async {
      for (final id in created) {
        await admin('DELETE', '/rest/v1/channels?id=eq.$id');
      }
    });

    final m3u = '#EXTM3U\n'
        '#EXTINF:-1 tvg-id="Imp$stamp.sa@HD",Existing (1080p)\nhttps://example.com/imp/$stamp/new-server.m3u8\n'
        '#EXTINF:-1 tvg-id="Brand$stamp.eg" group-title="News",Brand New $stamp\n#EXTVLCOPT:http-user-agent=TestUA\nhttps://example.com/imp/$stamp/brand.m3u8\n'
        '#EXTINF:-1,Old link\nhttps://example.com/imp/$stamp/old.m3u8\n';

    // التشغيل التجريبي (نفس ما تفعله الشاشة) — لا كتابة
    final (channels, streams) = await repo.matchingCatalog();
    final index = CatalogIndex([
      for (final c in channels) CatalogChannel(id: c['id'] as String, uid: c['uid'] as String, name: '${c['name']}', country: c['country_code'] as String?, epgId: c['epg_id'] as String?),
    ], {for (final s in streams) s['url'] as String: s['channel_id'] as String});
    final rep = matchImport(parseImport(m3u).items, index);
    expect(rep.results.map((r) => r.kind), ['update', 'new', 'existing']);
    expect(rep.results.first.channelId, existingId);

    // القبول
    final items = [
      for (final r in rep.results.where((r) => r.kind != 'existing'))
        {'uid': r.uid, 'name': r.item.name, 'logo': r.item.logo, 'country': r.item.country, 'category': mapCategory(r.item.group, await repo.categories()), 'quality': r.item.quality, 'url': r.item.url},
    ];
    final (ch, st) = await repo.importItems(null, items);
    expect(st, 2);
    expect(ch, greaterThanOrEqualTo(1));
    await repo.setStreamHeaders('https://example.com/imp/$stamp/brand.m3u8', userAgent: 'TestUA');

    // الموجودة: الاسم لم يتغير (لا استبدال لبيانات المدير) وأصبح لها رابطان
    expect((await repo.channel(existingId))!.name, 'Existing $stamp');
    expect((await repo.streamsOf(existingId)).length, 2);
    // الجديدة: قيد المراجعة دائمًا، بفئة من group-title وترويسة الرابط
    final brand = (await repo.channels(ChannelQuery(search: 'Brand New $stamp'))).items.single;
    created.add(brand.id);
    expect(brand.publishState, 'pending');
    expect(brand.countryCode, 'EG');
    expect((await repo.streamsOf(brand.id)).single.userAgent, 'TestUA');

    // المصدر: الإزالة لا تحذف الروابط (القيد الأصلي cascade)
    final src = await repo.addSource('Test $stamp', 'https://example.com/src-$stamp.m3u');
    await repo.importItems(src, [{'uid': 'Brand$stamp.eg', 'name': 'Brand New $stamp', 'url': 'https://example.com/imp/$stamp/from-source.m3u8'}]);
    await repo.markSourceImported(src);
    expect((await repo.sources()).firstWhere((s) => s['id'] == src)['stream_count'], 1);
    await repo.removeSource(src);
    expect((await repo.streamsOf(brand.id)).map((s) => s.url), contains('https://example.com/imp/$stamp/from-source.m3u8'));

    // التصدير
    final rows = await repo.exportRows(state: 'pending');
    expect(rows.map((r) => r['uid']), contains('Brand$stamp.eg'));
  }, skip: skip);

  test('batch 4c: reversible merge, duplicates, logos, networks, home layout', () async {
    // مجموعة مكررة: نفس الاسم والدولة
    final ids = <String>[];
    for (var i = 0; i < 2; i++) {
      final r = await admin('POST', '/rest/v1/channels', {'uid': 'dup:$stamp:$i', 'name': 'Dup Channel $stamp', 'country_code': null, 'network': 'Net$stamp', 'logo_url': i == 0 ? 'https://example.com/none-$stamp.png' : null});
      ids.add(((jsonDecode(r.body) as List).single as Map)['id'] as String);
      await admin('POST', '/rest/v1/streams', {'channel_id': ids.last, 'url': 'https://example.com/dup/$stamp/$i.m3u8'});
    }
    addTearDown(() async {
      for (final id in ids) {
        await admin('DELETE', '/rest/v1/channels?id=eq.$id');
      }
    });
    final groups = await repo.duplicates();
    expect(groups.any((g) => (g['channels'] as List).map((c) => (c as Map)['id']).toSet().containsAll(ids)), isTrue);

    // الدمج: الروابط تنتقل، والمدموجة مخفية (لا تُحذف) مع merged_into
    await repo.mergeChannels(ids[0], [ids[1]], keepFields: {'name_en': 'Dup Merged $stamp'});
    expect((await repo.streamsOf(ids[0])).length, 2);
    final merged = (await repo.channel(ids[1]))!;
    expect(merged.publishState, 'hidden');
    expect((await repo.mergedInto(ids[0])).map((c) => c.id), [ids[1]]);
    expect((await repo.channel(ids[0]))!.nameEn, 'Dup Merged $stamp');

    // التراجع: تعود روابطها، وتُزال الإشارة
    expect(await repo.unmerge(ids[1]), 1);
    expect((await repo.streamsOf(ids[0])).length, 1);
    expect((await repo.streamsOf(ids[1])).length, 1);
    expect(await repo.mergedInto(ids[0]), isEmpty);

    // الشعارات: تسجيل النتيجة والعدّ
    await repo.recordLogos([(ids[0], false)]);
    expect((await repo.channelsByLogo('broken')).map((c) => c.id), contains(ids[0]));
    expect((await repo.logoCounts())['broken'], greaterThanOrEqualTo(1));

    // الشبكات: العدّ وإعادة التسمية
    expect((await repo.networks()).firstWhere((n) => n.$1 == 'Net$stamp').$2, 2);
    await repo.renameNetwork('Net$stamp', 'Renamed$stamp');
    expect((await repo.networks()).map((n) => n.$1), contains('Renamed$stamp'));

    // تخطيط الرئيسية: يحفظه المدير ويقرؤه الزائر (عام)، و«hero» القديم يتحدث للموقع
    final before = await repo.homeLayout();
    addTearDown(() async {
      if (before == null) {
        await admin('DELETE', '/rest/v1/site_settings?key=eq.home_layout');
      } else {
        await repo.saveHomeLayout(before);
      }
    });
    await repo.saveHomeLayout({'version': 1, 'hero': [ids[0]], 'rows': [{'type': 'featured'}]});
    final anon = SupabaseClient(url, anonKey);
    final pub = await anon.from('site_settings').select('value').eq('key', 'home_layout').single();
    expect(((pub['value'] as Map)['hero'] as List).single, ids[0]);
    final hero = await anon.from('site_settings').select('value').eq('key', 'hero').single();
    expect((hero['value'] as Map)['channel_id'], ids[0]);
  }, skip: skip);
}
