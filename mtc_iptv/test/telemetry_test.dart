// قياس المشاهدين (§12.4، §20) وتجميع التحليلات (ADM-I1).
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/core/backend/backend.dart';
import 'package:mtc_iptv/core/settings/local_settings.dart';
import 'package:mtc_iptv/core/storage/catalog_db.dart';
import 'package:mtc_iptv/data/admin/analytics.dart';
import 'package:mtc_iptv/data/telemetry/telemetry.dart';

void main() {
  group('events', () {
    test('random installation id is a v4 UUID and never repeats', () {
      final a = randomUuid(), b = randomUuid();
      expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(a, isNot(b));
    });

    test('event json carries no link, only the stream id and measurements', () {
      final j = PlayEvent(streamId: 's1', outcome: 'failure', errorCode: 'network_error', serverIndex: 1).toJson();
      expect(j.keys, containsAll(['at', 'stream_id', 'outcome', 'error_code', 'server_index']));
      expect(j.containsKey('url'), isFalse);
      expect(j.containsKey('first_frame_ms'), isFalse); // الحقول الفارغة لا تُرسل
    });
  });

  group('service', () {
    late ProviderContainer c;
    setUp(() {
      c = ProviderContainer(overrides: [
        catalogDbProvider.overrideWith((ref) {
          final db = CatalogDb(NativeDatabase.memory());
          ref.onDispose(db.close);
          return db;
        }),
      ]);
    });
    tearDown(() => c.dispose());

    test('installation id is stable, reset makes a new one', () async {
      final s = c.read(telemetryProvider);
      final id = await s.installationId();
      expect(await s.installationId(), id);
      await s.resetId(); // بلا خادم: لا يفشل
      expect(await s.installationId(), isNot(id));
    });

    test('queue is capped and nothing is recorded when the user turns statistics off', () async {
      final s = c.read(telemetryProvider);
      for (var i = 0; i < 19; i++) {
        s.record(PlayEvent(streamId: 's$i', outcome: 'success'));
      }
      expect(s.queue.length, 19);
      c.read(settingsProvider.notifier).setTelemetry(false);
      s.record(PlayEvent(streamId: 'x', outcome: 'success'));
      expect(s.queue.length, 19);
      expect(await s.flush(), 0); // بلا خادم
      c.read(settingsProvider.notifier).setTelemetry(true);
    });
  });

  group('analytics', () {
    final rows = [
      {'day': '2026-10-15', 'stream_id': 'a', 'channel_id': 'c1', 'platform': 'windows', 'country': 'JO', 'attempts': 30, 'successes': 27, 'abandoned': 2, 'sessions_30s': 20, 'watch_seconds': 3600, 'ttff_p50_ms': 1000, 'ttff_p90_ms': 3000, 'failures': {'network_error': 3}},
      {'day': '2026-10-16', 'stream_id': 'a', 'channel_id': 'c1', 'platform': 'android', 'country': '', 'attempts': 10, 'successes': 3, 'abandoned': 0, 'sessions_30s': 1, 'watch_seconds': 60, 'ttff_p50_ms': 4000, 'ttff_p90_ms': 9000, 'failures': {'network_error': 2, 'unavailable': 5}},
      {'day': '2026-10-16', 'stream_id': 'b', 'channel_id': 'c2', 'platform': 'windows', 'country': 'SA', 'attempts': 5, 'successes': 1, 'abandoned': 0, 'sessions_30s': 0, 'watch_seconds': 0, 'ttff_p50_ms': null, 'ttff_p90_ms': null, 'failures': {'auth_failed': 4}},
    ];
    final p = PlaybackAnalytics.from(rows, hosts: {'a': 'cdn.one', 'b': 'cdn.two'});

    test('totals, rate and failure codes', () {
      expect(p.total.attempts, 45);
      expect(p.total.successes, 31);
      expect(p.total.sessions30, 21);
      expect(p.total.failures, {'network_error': 5, 'unavailable': 5, 'auth_failed': 4});
      expect(p.byCountry.keys, containsAll(['JO', 'SA', '—']));
      expect(p.byHost['cdn.one']!.attempts, 40);
    });

    test('start time is weighted by successful plays', () {
      // (1000×27 + 4000×3) / 30 = 1300
      expect(p.byChannel['c1']!.ttffP50, 1300);
      expect(p.byChannel['c2']!.ttffP50, isNull);
    });

    test('rates only with enough samples; worst list ignores small samples', () {
      expect(p.byChannel['c1']!.rateIfSample(), closeTo(0.75, 0.001));
      expect(p.byChannel['c2']!.rateIfSample(), isNull); // 5 < 20
      expect(PlaybackAnalytics.worst(p.byChannel).map((e) => e.key), ['c1']);
      expect(PlaybackAnalytics.topViewed(p.byChannel).first.key, 'c1');
      expect(p.total.rateIfSample(minSampleDashboard), isNull); // 45 < 100
    });

    test('devices: active 7 and 30 days', () {
      final now = DateTime.utc(2026, 10, 16, 12);
      final d = DeviceStats.from([
        {'platform': 'windows', 'app_version': '3.0.0', 'country': 'JO', 'locale': 'ar', 'last_seen_at': '2026-10-16T10:00:00Z'},
        {'platform': 'android', 'app_version': '3.0.0', 'country': null, 'locale': 'en', 'last_seen_at': '2026-10-01T10:00:00Z'},
        {'platform': 'android', 'app_version': '2.9.0', 'country': 'SA', 'locale': 'ar', 'last_seen_at': '2026-08-01T10:00:00Z'},
      ], now: now);
      expect(d.active7, 1);
      expect(d.active30, 2);
      expect(d.byPlatform, {'windows': 1, 'android': 1});
      expect(d.byCountry['—'], 1);
    });

    test('CSV for Excel has a BOM and escapes quotes', () {
      final s = toExcelCsv(['a', 'b'], [
        ['قناة "1"', 2],
      ]);
      expect(s.startsWith('﻿'), isTrue);
      expect(s, contains('"قناة ""1"""'));
    });
  });
}
