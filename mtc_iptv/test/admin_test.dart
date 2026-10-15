// منطق المرحلة 4 دون خادم: دمج نتيجتي الفحص، وإخفاء بيانات الاعتماد.
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:mtc_iptv/data/admin/admin_repository.dart';
import 'package:mtc_iptv/data/admin/health_service.dart';
import 'package:mtc_iptv/player/play_probe.dart';

void main() {
  group('combine L1 + L2 (§12.2)', () {
    const ok = ProbeResult('reachable', 'HLS ok', httpStatus: 200);
    test('L1 failure is final, L2 not needed', () {
      expect(combine(const ProbeResult('unavailable', 'HTTP 404', httpStatus: 404), null).$1, 'unavailable');
    });
    test('fast first frame = playable with high score', () {
      final r = combine(ok, const PlayResult('playable', '1080p', firstFrameMs: 900));
      expect([r.$1, r.$3], ['playable', 100]);
    });
    test('slow start = degraded', () => expect(combine(ok, const PlayResult('degraded', 'slow', firstFrameMs: 8000)).$1, 'degraded'));
    test('reachable but no frame stays reachable (doubt is not failure)', () {
      final r = combine(ok, const PlayResult('inconclusive', 'no frame within 15s'));
      expect(r.$1, 'reachable');
      expect(r.$2, contains('no frame'));
    });
    test('decoder failure after reaching = unsupported', () => expect(combine(ok, const PlayResult('unsupported', 'codec')).$1, 'unsupported'));
    test('L1 only (play check off) = reachable', () => expect(combine(ok, null).$1, 'reachable'));
  });

  group('credential masking (§19.4)', () {
    AdminStream s(String url) => AdminStream(id: '1', channelId: 'c', url: url, hasCredentials: true);
    test('xtream path', () => expect(s('http://h:8080/live/user1/pass1/255.ts').maskedUrl, 'http://h:8080/live/••••/••••/255.ts'));
    test('query params', () => expect(s('https://h/get.php?username=a&password=b&type=m3u').maskedUrl, 'https://h/get.php?username=••••&password=••••&type=m3u'));
    test('userinfo', () => expect(s('https://u:p@h/x.m3u8').maskedUrl, 'https://••••@h/x.m3u8'));
    test('no credentials: unchanged', () => expect(const AdminStream(id: '1', channelId: 'c', url: 'https://h/live/a/b/c.m3u8').maskedUrl, 'https://h/live/a/b/c.m3u8'));
  });

  test('audit entry lists only real changes, without system fields', () {
    final e = AuditEntry(DateTime(2026), 'UPDATE', 'channels', 'manual', {'name': 'A', 'number': 1, 'updated_at': 'x', 'catalog_rev': 1}, {'name': 'B', 'number': 1, 'updated_at': 'y', 'catalog_rev': 2});
    expect(e.changes.map((c) => c.$1), ['name']);
  });
}
