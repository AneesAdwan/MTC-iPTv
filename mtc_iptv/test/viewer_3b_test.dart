// منطق الدفعة 3b دون واجهة: الدليل، التذكيرات، التحديثات، البلاغ، الإعدادات.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/epg/epg_repository.dart';
import 'package:mtc_iptv/data/reminders/reminders.dart';
import 'package:mtc_iptv/data/updates/update_check.dart';
import 'package:mtc_iptv/features/viewer/report_screen.dart';

class FakeEpgApi implements EpgApi {
  final List<Map<String, dynamic>> rows;
  int calls = 0;
  FakeEpgApi(this.rows);
  @override
  Future<List<Map<String, dynamic>>> page(DateTime since, int from, int to) async {
    calls++;
    final ok = rows.where((r) => DateTime.parse(r['end_at'] as String).isAfter(since)).toList();
    return ok.sublist(from.clamp(0, ok.length), (to + 1).clamp(0, ok.length));
  }
}

Map<String, dynamic> prog(String uid, DateTime s, int minutes, String title) => {
      'channel_uid': uid,
      'start_at': s.toUtc().toIso8601String(),
      'end_at': s.add(Duration(minutes: minutes)).toUtc().toIso8601String(),
      'title': title,
      'description': null,
      'category': null,
    };

void main() {
  final now = DateTime(2026, 10, 15, 20, 30);

  group('EPG', () {
    late CatalogDb db;
    setUp(() => db = CatalogDb(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('sync pages through everything and now/next is correct', () async {
      final rows = [
        for (var i = 0; i < 2500; i++) prog('u${i % 5}', now.subtract(const Duration(hours: 2)).add(Duration(minutes: 30 * (i ~/ 5))), 30, 'p$i'),
      ];
      final api = FakeEpgApi(rows);
      final repo = EpgRepository(db, api);
      final n = await repo.sync(now: now);
      expect(api.calls, 3); // 1000 + 1000 + 500
      expect(n, rows.where((r) => DateTime.parse(r['end_at'] as String).isAfter(now.subtract(const Duration(hours: 6)))).length);

      final nn = await repo.nowNext('u0', at: now);
      expect(nn.now!.title, 'p20'); // 18:30 + 4×30د = 20:30
      expect(nn.next!.title, 'p25');
      expect(nn.progress(now), 0);
    });

    test('sync is skipped within 6 hours unless forced', () async {
      final api = FakeEpgApi([prog('u0', now, 60, 'a')]);
      final repo = EpgRepository(db, api);
      await repo.sync(now: now);
      expect(await repo.sync(now: now.add(const Duration(hours: 1))), isNull);
      expect(await repo.sync(now: now.add(const Duration(hours: 1)), force: true), 1);
    });

    test('no programme now: next only', () async {
      final repo = EpgRepository(db, FakeEpgApi([prog('u0', now.add(const Duration(minutes: 10)), 60, 'later')]));
      await repo.sync(now: now);
      final nn = await repo.nowNext('u0', at: now);
      expect(nn.now, isNull);
      expect(nn.next!.title, 'later');
    });
  });

  group('reminders', () {
    late CatalogDb db;
    setUp(() => db = CatalogDb(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('fires 5 minutes before, once, into the inbox', () async {
      final r = ReminderService(db);
      final start = now.add(const Duration(minutes: 20));
      expect(await r.toggle('c1', start, 'News'), isTrue);
      expect(await r.fireDue(now: now), isEmpty);
      expect((await r.fireDue(now: start.subtract(const Duration(minutes: 5)))).single.title, 'News');
      expect(await r.fireDue(now: start), isEmpty); // مرة واحدة
      expect((await r.watchInbox().first).single.channelId, 'c1');
      expect(await r.watchUnread().first, 1);
      await r.markAllRead();
      expect(await r.watchUnread().first, 0);
    });

    test('toggle twice removes the reminder', () async {
      final r = ReminderService(db);
      final start = now.add(const Duration(hours: 1));
      await r.toggle('c1', start, 'x');
      expect(await r.toggle('c1', start, 'x'), isFalse);
      expect(await r.watchKeys().first, isEmpty);
    });
  });

  group('update check', () {
    AppVersion v(String s) => AppVersion.parse(s)!;
    test('ordering', () {
      expect(v('3.0.0-alpha.10').compareTo(v('3.0.0-alpha.9')), greaterThan(0));
      expect(v('3.0.0').compareTo(v('3.0.0-alpha.9')), greaterThan(0));
      expect(v('3.0.1-alpha.1').compareTo(v('3.0.0')), greaterThan(0));
      expect(v('v3.0.0-alpha.8').toString(), '3.0.0-alpha.8');
    });

    final releases = [
      {'tag_name': 'v3.0.0-alpha.9', 'html_url': 'u9', 'draft': false},
      {'tag_name': 'v3.0.0-alpha.8', 'html_url': 'u8', 'draft': false},
      {'tag_name': 'v3.0.0-alpha.10', 'html_url': 'd10', 'draft': true},
      {'tag_name': 'v2.2.5', 'html_url': 'old', 'draft': false},
    ];
    test('alpha user is offered the newest alpha, drafts and 2.x ignored', () {
      expect(pickUpdate(v('3.0.0-alpha.8'), releases)!.pageUrl, 'u9');
      expect(pickUpdate(v('3.0.0-alpha.9'), releases), isNull);
    });
    test('stable user is not offered prereleases', () => expect(pickUpdate(v('3.0.0'), releases), isNull));
  });

  group('report note', () {
    test('diagnostics are appended only with consent and fit 500 chars', () {
      expect(composeReportNote('  hi  '), 'hi');
      final n = composeReportNote('x' * 600, diag: 'v3 · windows');
      expect(n.length, lessThanOrEqualTo(500));
      expect(n.endsWith('[v3 · windows]'), isTrue);
    });
  });

  group('local settings', () {
    test('json round trip keeps the new fields', () {
      final s = LocalSettings(locale: const Locale('en'), showNumbers: false, maxQuality: 720, telemetry: false, pinHash: hashPin('1234'), lockedCategories: const ['kids']);
      final back = LocalSettings.fromJson(s.toJson().cast<String, dynamic>());
      expect([back.showNumbers, back.maxQuality, back.telemetry, back.pinHash, back.lockedCategories], [false, 720, false, hashPin('1234'), ['kids']]);
      expect(back.parentalOn, isTrue);
    });
    test('old settings files get safe defaults', () {
      final s = LocalSettings.fromJson({'locale': 'ar', 'theme': 'dark'});
      expect([s.showNumbers, s.maxQuality, s.telemetry, s.parentalOn], [true, null, true, false]);
    });
    test('the PIN itself is never stored', () => expect(hashPin('1234'), isNot(contains('1234'))));
  });
}
