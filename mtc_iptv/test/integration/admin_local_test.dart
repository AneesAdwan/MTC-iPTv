// مركز الإدارة (المرحلة 4) ضد Supabase المحلي: كل استعلامات AdminRepository بجلسة مدير حقيقية (TOTP).
// التشغيل كما في local_backend_test.dart:  flutter test --tags local
@Tags(['local'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/backend/backend.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/favorites/fav_sync.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:mtc_iptv/data/admin/admin_repository.dart';
import 'package:mtc_iptv/data/admin/analytics.dart';
import 'package:mtc_iptv/data/admin/backup_service.dart';
import 'package:mtc_iptv/data/admin/import_service.dart';
import 'package:mtc_iptv/data/admin/settings_repository.dart';
import 'package:mtc_iptv/data/settings/remote_config.dart';
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

    // جماعي ثم حذف (0007: السلة أولًا، والنهائي من السلة فقط)
    await repo.updateChannels([id], {'is_featured': true});
    expect((await repo.channel(id))!.isFeatured, isTrue);
    expect(await repo.purgeChannels([id]), 0, reason: 'not in the bin: never purged');
    await repo.trashChannels([id]);
    expect(await repo.purgeChannels([id]), 1);
    expect(await repo.channel(id), isNull);
    expect(await repo.streamsOf(id), isEmpty);
  }, skip: skip);

  test('health: working streams of unpublished channels are added to the system (pending + binned)', () async {
    final pending = (jsonDecode((await admin('POST', '/rest/v1/channels?select=id', {'uid': 'hp.pending.$stamp', 'name': 'HP Pending $stamp', 'is_published': true})).body) as List).single['id'] as String;
    final binned = await repo.createChannel(nameAr: '', nameEn: 'HP Binned $stamp');
    await repo.addStream(pending, url: 'https://example.com/$stamp/hp-p.m3u8');
    await repo.addStream(binned, url: 'https://example.com/$stamp/hp-b.m3u8');
    try {
      await repo.trashChannels([binned]);
      await c.from('streams').update({'health_state': 'playable'}).inFilter('channel_id', [pending, binned]);
      final rows = (await repo.streamsByHealth('playable')).where((r) => r.$1.channelId == pending || r.$1.channelId == binned).toList();
      expect({for (final r in rows) r.$1.channelId: r.$4}, {pending: 'pending', binned: 'trash'});
      expect(await repo.publishChannels([pending, binned]), 2);
      expect((await repo.channel(pending))!.publishState, 'published');
      final b = (await repo.channel(binned))!;
      expect(b.publishState, 'published');
      expect(b.trashedAt, isNull);
    } finally {
      await repo.trashChannels([pending, binned]);
      await repo.purgeChannels([pending, binned]);
    }
  }, skip: skip);

  test('phase 4 (0007): recycle bin, restore, select-all ids, review reject to bin, decisions', () async {
    final base = 80000 + stamp % 9000;
    final a = await repo.createChannel(nameAr: '', nameEn: 'Bin A $stamp', number: base);
    final b = await repo.createChannel(nameAr: '', nameEn: 'Bin B $stamp', number: base + 1);
    final c3 = await repo.createChannel(nameAr: '', nameEn: 'Bin C $stamp', number: base + 2);
    await repo.addStream(a, url: 'https://example.com/$stamp/bin-a.m3u8');
    await repo.addStream(b, url: 'https://example.com/$stamp/bin-b.m3u8');
    await repo.addStream(c3, url: 'https://example.com/$stamp/bin-c.m3u8');
    try {
      // «تحديد كل النتائج» يجلب كل الصفحات حسب الفلتر
      final ids = await repo.channelIds(ChannelQuery(search: 'Bin '));
      expect(ids, containsAll([a, b, c3]));

      // السلة: تختفي من القائمة العادية، تظهر بفلتر السلة، رقمها يتحرر
      expect(await repo.trashChannels([c3], reason: 'test'), 1);
      expect((await repo.channels(ChannelQuery(search: 'Bin C $stamp'))).items, isEmpty);
      final binned = (await repo.channels(ChannelQuery(search: 'Bin C $stamp', trash: true))).items.single;
      expect(binned.trashedAt, isNotNull);
      expect(binned.trashReason, 'test');
      expect(binned.number, isNull);
      expect(binned.publishState, 'hidden');

      // الاسترجاع يعيد الحالة والرقم
      expect(await repo.restoreChannels([c3]), 1);
      final back = (await repo.channel(c3))!;
      expect(back.trashedAt, isNull);
      expect(back.number, base + 2);
      expect(back.publishState, 'published');

      // «قرارات»: B تُدمج في A (روابطها تنتقل، تُخفى، قابلة للتراجع) و C إلى السلة
      await repo.mergeChannels(a, [b]);
      await repo.trashChannels([c3]);
      expect((await repo.streamsOf(a)).length, 2);
      expect((await repo.channel(b))!.publishState, 'hidden');
      expect((await repo.channels(ChannelQuery(search: 'Bin C $stamp', trash: true))).items, hasLength(1));
      expect(await repo.unmerge(b), greaterThan(0));
      expect((await repo.streamsOf(b)).length, 1);

      // قيد المراجعة: «رفض» ← السلة (لا حذف)
      final pending = (jsonDecode((await admin('POST', '/rest/v1/channels?select=id', {'uid': 'bin.pending.$stamp', 'name': 'Bin P $stamp', 'is_published': true})).body) as List).single['id'] as String;
      expect(await repo.reviewApply('reject', [pending]), 1);
      expect((await repo.channels(ChannelQuery(search: 'Bin P $stamp', trash: true))).items.single.id, pending);
      await repo.purgeChannels([pending]);

      // تحديد كل الروابط حسب الفلتر
      final sids = await repo.streamIds(host: 'example.com');
      expect(sids.length, greaterThanOrEqualTo(3));
      expect((await repo.streamsByIds(sids.take(2).toList())).length, 2);
    } finally {
      await repo.trashChannels([a, b, c3]);
      await repo.purgeChannels([a, b, c3]);
    }
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

  test('phase 5b (migration 0004): epg sources/upsert/finish, rules, xtream in vault', () async {
    // مصادر الدليل المزروعة + كتابة برامج بالمفتاح نفسه دون تكرار
    final sources = await repo.epgSources();
    expect(sources.length, greaterThanOrEqualTo(4));
    final now = DateTime.now().toUtc();
    final uid = 'EpgTest$stamp.sa';
    addTearDown(() => admin('DELETE', '/rest/v1/epg_programmes?channel_uid=eq.$uid'));
    final rows = [
      for (var h = 0; h < 3; h++)
        {'channel_uid': uid, 'start_at': now.add(Duration(hours: h)).toIso8601String(), 'end_at': now.add(Duration(hours: h + 1)).toIso8601String(), 'title': 'P$h', 'source': 'test'},
    ];
    expect(await repo.epgUpsert([...rows, rows.first]), 3);
    expect(await repo.uidsWithProgrammes(), contains(uid));
    final day = await repo.epgDay(uid, DateTime(now.year, now.month, now.day));
    expect(day.map((r) => r['title']), contains('P0'));
    await repo.epgFinish(sources.first['id'] as String, status: 'ok', channels: 1, programmes: 3);
    expect((await repo.epgSources()).firstWhere((s) => s['id'] == sources.first['id'])['last_status'], 'ok');

    // قواعد التحويل: حفظ وقراءة وحذف
    await repo.upsertRule({'kind': 'group_category', 'pattern': 'Sport$stamp', 'target': 'sports'});
    final rule = (await repo.transformRules()).firstWhere((r) => r['pattern'] == 'Sport$stamp');
    await repo.deleteRule(rule['id'] as String);
    expect((await repo.transformRules()).where((r) => r['pattern'] == 'Sport$stamp'), isEmpty);

    // Xtream: كلمة المرور في Vault فقط، وتُقرأ بجلسة التحقق بخطوتين
    final id = await repo.saveXtream('T$stamp', 'http://xt.example:8080', 'u$stamp', 'p-$stamp');
    final listed = (await repo.xtreamAccounts()).firstWhere((a) => a['id'] == id);
    expect(listed.containsKey('secret_id'), isFalse, reason: 'the app never selects the secret id');
    expect(await repo.xtreamPassword(id), 'p-$stamp');
    await repo.deleteXtream(id);
    expect((await repo.xtreamAccounts()).where((a) => a['id'] == id), isEmpty);
  }, skip: skip);

  test('phase 6a: backup -> verify -> loss -> restore drill (local only), scheduler lease', () async {
    expect(url, startsWith('http://127.0.0.1'), reason: 'the restore drill must never run against production');
    final dir = await Directory.systemTemp.createTemp('mtc-bak-');
    addTearDown(() => dir.delete(recursive: true));
    final svc = BackupService(repo);

    // بيانات معروفة
    final r = await admin('POST', '/rest/v1/channels', {'uid': 'bak:$stamp', 'name': 'Backup $stamp'});
    final id = ((jsonDecode(r.body) as List).single as Map)['id'] as String;
    await admin('POST', '/rest/v1/streams', {'channel_id': id, 'url': 'https://example.com/bak/$stamp.m3u8'});
    addTearDown(() => admin('DELETE', '/rest/v1/channels?id=eq.$id'));

    // النسخة: ملف + بصمة، والصيغة الصحيحة
    final res = await svc.create(dir: dir.path, passphrase: 'drill-pass-$stamp', kind: 'manual');
    expect(File(res.path).existsSync(), isTrue);
    expect(File('${res.path}.sha256').existsSync(), isTrue);
    final before = {'channels': await repo.tableCount('channels'), 'streams': await repo.tableCount('streams')};
    expect(res.counts['channels'], before['channels']);

    // رفض: عبارة مرور خاطئة، وبصمة لا تطابق
    await expectLater(BackupService.open(res.path, 'wrong-pass'), throwsA(isA<BackupError>()));
    final doc = await BackupService.open(res.path, 'drill-pass-$stamp');
    final sha = File('${res.path}.sha256');
    final good = await sha.readAsString();
    await sha.writeAsString('0' * 64);
    await expectLater(BackupService.open(res.path, 'drill-pass-$stamp'), throwsA(isA<BackupError>()));
    await sha.writeAsString(good);

    // استعادة قناة واحدة بعد حذفها
    await admin('DELETE', '/rest/v1/channels?id=eq.$id');
    expect(await repo.channel(id), isNull);
    final one = await svc.restore(doc, channelId: id);
    expect(one, {'channels': 1, 'streams': 1});
    expect((await repo.streamsOf(id)).single.url, 'https://example.com/bak/$stamp.m3u8');

    // التمرين الكامل (Gate C): فقدان كل القنوات والروابط ثم استعادتها والتحقق بالأعداد
    await admin('DELETE', '/rest/v1/channels?id=not.is.null');
    expect(await repo.tableCount('channels'), 0);
    final all = await svc.restore(doc, tables: ['languages', 'countries', 'categories', 'channels', 'streams']);
    expect(all['channels'], before['channels']);
    expect(await repo.tableCount('channels'), before['channels']);
    expect(await repo.tableCount('streams'), before['streams']);

    // المُجدوِل: قفل المهمة على جهاز واحد
    await repo.updateTask('logos', {'next_run_at': null, 'locked_by': null, 'locked_until': null, 'enabled': true});
    expect(await repo.acquireTask('logos', 'dev-A-$stamp'), isTrue);
    expect(await repo.acquireTask('logos', 'dev-B-$stamp'), isFalse);
    await repo.finishTask('logos', 'dev-A-$stamp', 'ok');
    final t = (await repo.scheduledTasks()).firstWhere((x) => x['key'] == 'logos');
    expect([t['last_status'], t['locked_by']], ['ok', null]);
    expect(DateTime.parse('${t['next_run_at']}').isAfter(DateTime.now().toUtc()), isTrue);
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

  test('phase 6b: central settings are written by the admin and readable by viewers', () async {
    final s = SettingsRepository(c);
    final anon = SupabaseClient(url, anonKey);
    final before = {for (final k in ['features', 'social', 'developer']) k: await s.get(k)};
    try {
      await s.set('features', {
        'maintenance': {'enabled': false},
        'kill_switch': {'channels': ['x$stamp']},
        'features': {'guide': false},
      });
      await s.saveSocial([
        {'platform': 'x', 'handle': 'mtc$stamp', 'owner': 'developer', 'about': true},
      ], {'whatsapp': '+962790000000'});
      final rows = await anon.from('site_settings').select('key,value').inFilter('key', remoteKeys);
      final rc = RemoteConfig({for (final r in rows) r['key'] as String: r['value']});
      expect(rc.killedChannels, {'x$stamp'});
      expect(rc.feature('guide'), isFalse);
      expect(rc.social.single['handle'], 'mtc$stamp');
      expect(rc.support['whatsapp'], '+962790000000');
      // توافق الموقع القديم: developer.social
      expect(((await s.get('developer') as Map)['social'] as Map)['x'], 'mtc$stamp');
      // الزائر لا يكتب
      await expectLater(anon.from('site_settings').upsert({'key': 'features', 'value': {}, 'is_public': true}), throwsA(anything));
    } finally {
      for (final e in before.entries) {
        if (e.value != null) await s.set(e.key, e.value!);
      }
      if (before['features'] == null) await c.from('site_settings').delete().eq('key', 'features');
      if (before['social'] == null) await c.from('site_settings').delete().eq('key', 'social');
    }
  }, skip: skip);

  test('phase 7: favorites sync by code between two devices (owner, follower, editor)', () async {
    ProviderContainer device() => ProviderContainer(overrides: [
          catalogDbProvider.overrideWith((ref) {
            final db = CatalogDb(NativeDatabase.memory());
            ref.onDispose(db.close);
            return db;
          }),
          supabaseProvider.overrideWithValue(SupabaseClient(url, anonKey)),
        ]);
    Future<void> setFavs(ProviderContainer d, List<String> ids) async {
      final db = d.read(catalogDbProvider);
      await db.delete(db.favorites).go();
      for (var i = 0; i < ids.length; i++) {
        await db.into(db.favorites).insert(FavoritesCompanion.insert(channelId: ids[i], position: i, addedAt: DateTime.now()));
      }
    }

    final a = device(), b = device(), e = device();
    addTearDown(() {
      a.dispose();
      b.dispose();
      e.dispose();
    });
    final sa = a.read(favSyncProvider), sb = b.read(favSyncProvider), se = e.read(favSyncProvider);
    await setFavs(a, ['c1', 'c2']);
    final link = await sa.create();
    expect(link.code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{8}$')));

    // متابع بالرمز وحده: يدمج ولا يعدّل
    await setFavs(b, ['c9']);
    expect(await sb.join(link.code.toLowerCase()), isTrue);
    expect(await sb.localIds(), ['c1', 'c2', 'c9']);
    expect((await sb.link())!.canEdit, isFalse);

    // المالك يعدّل ← يرفع ← المتابع يسحب
    await setFavs(a, ['c2', 'c3']);
    await sa.push();
    expect(await sb.pull(), isTrue);
    expect(await sb.localIds(), ['c2', 'c3', 'c1', 'c9']);

    // جهاز ثالث بمفتاح التعديل: قائمة واحدة مشتركة
    await setFavs(e, ['c7']);
    expect(await se.join(link.editKey!), isTrue);
    expect((await se.link())!.canEdit, isTrue);
    expect(await sa.pull(), isTrue);
    expect(await sa.localIds(), ['c2', 'c3', 'c7']);

    // رمز غير موجود، وفك الربط مع الحذف
    expect(await sb.join('ZZZZ2222'), isFalse);
    await sa.unlink(deleteRemote: true);
    expect(await sa.link(), isNull);
    expect(await sb.pull(), isFalse); // حُذفت: يبقى المحلي ويُفك الربط
    expect(await sb.link(), isNull);
    expect(await sb.localIds(), ['c2', 'c3', 'c1', 'c9']);
  }, skip: skip);

  test('phase 6c: viewer telemetry -> rollup -> analytics, alerts, and forget', () async {
    final id = await repo.createChannel(nameAr: 'قياس $stamp', nameEn: 'Telemetry $stamp', number: 70000 + stamp % 9000);
    await repo.addStream(id, url: 'https://example.com/$stamp/t.m3u8', label: 'T');
    final sid = (await repo.streamsOf(id)).single.id;
    final inst = '00000000-0000-4000-8000-${(stamp % 1000000000000).toString().padLeft(12, '0')}';
    final anon = SupabaseClient(url, anonKey);
    try {
      final n = await anon.rpc('telemetry_ingest', params: {
        'p_installation': inst,
        'p_platform': 'windows',
        'p_version': '3.0.0-alpha.17',
        'p_locale': 'ar',
        'p_events': [
          {'stream_id': sid, 'outcome': 'success', 'first_frame_ms': 800, 'watch_seconds': 95},
          {'stream_id': sid, 'outcome': 'failure', 'error_code': 'network_error'},
          {'stream_id': sid, 'outcome': 'abandoned'},
        ],
      });
      expect(n, 3);
      // الزائر لا يقرأ ما كتبه
      await expectLater(anon.from('playback_events').select(), throwsA(anything));

      final r = await repo.telemetryRollup(DateTime.now().toUtc());
      expect(r['rows'], greaterThanOrEqualTo(1));
      final rows = (await repo.playbackStats(DateTime.now().toUtc())).where((x) => x['stream_id'] == sid).toList();
      final a = PlaybackAnalytics.from(rows);
      expect(a.total.attempts, 2);
      expect(a.total.successes, 1);
      expect(a.total.abandoned, 1);
      expect(a.total.sessions30, 1);
      expect(a.total.failures['network_error'], 1);
      expect((await repo.installations(DateTime.now().subtract(const Duration(days: 1)))).any((x) => x['id'] == inst), isTrue);
      expect((await repo.dashboard()).activeDevices7, greaterThanOrEqualTo(1));

      // التنبيهات: الفحص يعمل، وتغيير الحالة
      await repo.alertsScan();
      await repo.raiseAlert('connector_stopped', 'test:$stamp', 'iptv-org', refType: 'connector');
      await repo.raiseAlert('connector_stopped', 'test:$stamp', 'iptv-org', refType: 'connector');
      final al = (await repo.alerts()).firstWhere((x) => x['dedupe_key'] == 'test:$stamp');
      expect(al['occurrences'], 2);
      await repo.setAlertStatus([(al['id'] as num).toInt()], 'resolved');
      expect((await repo.alerts(status: 'resolved')).any((x) => x['id'] == al['id']), isTrue);

      // «أعد تعيين المعرّف»: الجهاز وأحداثه تُحذف، والتجميعات تبقى
      await anon.rpc('telemetry_forget', params: {'p_installation': inst});
      expect((await repo.installations(DateTime.now().subtract(const Duration(days: 1)))).any((x) => x['id'] == inst), isFalse);
      expect((await c.from('playback_events').select('id').eq('installation_id', inst)), isEmpty);
      expect((await repo.playbackStats(DateTime.now().toUtc())).where((x) => x['stream_id'] == sid), isNotEmpty);
    } finally {
      await admin('DELETE', '/rest/v1/admin_alerts?dedupe_key=eq.test:$stamp');
      await admin('DELETE', '/rest/v1/playback_stats_daily?stream_id=eq.$sid');
      await repo.trashChannels([id]);
      await repo.purgeChannels([id]);
    }
  }, skip: skip);
}
