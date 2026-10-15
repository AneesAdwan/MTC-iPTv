// اختبارات SSRF الإلزامية (§19.3): عنوان داخلي مباشر، اسم يُحلّ لعنوان داخلي، تحويل لعنوان داخلي،
// rebinding، منفذ غير مسموح، ملف ضخم، بروتوكول غير مسموح، IPv4 داخل IPv6.
import 'dart:io';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

Matcher fails(String code) => throwsA(isA<SafeFetchException>().having((e) => e.code, 'code', code));

void main() {
  group('isBlockedAddress', () {
    for (final ip in [
      '127.0.0.1', '10.1.2.3', '172.16.0.1', '172.31.255.255', '192.168.1.1', '169.254.169.254', '100.64.0.1',
      '0.0.0.0', '224.0.0.1', '255.255.255.255', '::1', '::', 'fc00::1', 'fd12:3456::1', 'fe80::1', '::ffff:192.168.1.1',
      '::ffff:127.0.0.1', 'ff02::1',
    ]) {
      test('blocks $ip', () => expect(isBlockedAddress(InternetAddress(ip)), isTrue));
    }
    for (final ip in ['8.8.8.8', '1.1.1.1', '172.32.0.1', '100.128.0.1', '2606:4700:4700::1111', '::ffff:8.8.8.8']) {
      test('allows $ip', () => expect(isBlockedAddress(InternetAddress(ip)), isFalse));
    }
  });

  group('SafeFetcher.check', () {
    final f = SafeFetcher(resolver: (h) async => switch (h) {
          'internal.example' => [InternetAddress('10.0.0.5')],
          'mixed.example' => [InternetAddress('93.184.216.34'), InternetAddress('192.168.0.10')],
          _ => [InternetAddress('93.184.216.34')],
        });

    test('rejects file:// and ftp://', () async {
      await expectLater(f.check(Uri.parse('file:///C:/Windows/win.ini')), fails('scheme'));
      await expectLater(f.check(Uri.parse('ftp://example.com/x')), fails('scheme'));
    });
    test('rejects a port that is not allowed', () => expectLater(f.check(Uri.parse('http://example.com:22/')), fails('port')));
    test('rejects a literal internal IP', () => expectLater(f.check(Uri.parse('http://192.168.1.1/')), fails('blocked_address')));
    test('rejects a name that resolves to an internal IP', () => expectLater(f.check(Uri.parse('http://internal.example/')), fails('blocked_address')));
    test('rejects when ANY resolved address is internal', () => expectLater(f.check(Uri.parse('http://mixed.example/')), fails('blocked_address')));
    test('accepts a public host on an allowed port', () async => expect((await f.check(Uri.parse('http://example.com:25461/live'))).address, '93.184.216.34'));
    test('admin-allowed local address passes (ADM-G4 exception)', () async {
      final g = SafeFetcher(policy: SafeFetchPolicy(allowedLocal: [InternetAddress('192.168.1.50')]));
      expect((await g.check(Uri.parse('http://192.168.1.50/list.m3u'))).address, '192.168.1.50');
    });
  });

  group('SafeFetcher.get against a local server', () {
    late HttpServer server;
    late SafeFetcher f;
    var resolveCalls = 0;

    setUp(() async {
      resolveCalls = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        switch (r.uri.path) {
          case '/ok':
            r.response.headers.contentType = ContentType('audio', 'x-mpegurl');
            r.response.write('#EXTM3U\n');
          case '/hop':
            r.response.statusCode = 302;
            r.response.headers.set('location', '/ok');
          case '/to-internal':
            r.response.statusCode = 302;
            r.response.headers.set('location', 'http://10.0.0.1:${server.port}/admin'); // allowed port: only the address check can stop it
          case '/loop':
            r.response.statusCode = 302;
            r.response.headers.set('location', '/loop');
          case '/big':
            r.response.add(List.filled(2 * 1024 * 1024, 65));
        }
        await r.response.close();
      });
      // «good.test» يُحلّ إلى خادم الاختبار المحلي (مسموح صراحةً هنا فقط)، ويعدّ مرات الحلّ
      f = SafeFetcher(
        policy: SafeFetchPolicy(allowedPorts: {server.port}, allowedLocal: [InternetAddress.loopbackIPv4], maxBytes: 1024 * 1024),
        resolver: (h) async {
          resolveCalls++;
          return [InternetAddress.loopbackIPv4];
        },
      );
    });
    tearDown(() => server.close(force: true));

    Uri u(String p) => Uri.parse('http://good.test:${server.port}$p');

    test('fetches content and follows a safe redirect', () async {
      final r = await f.get(u('/hop'));
      expect(r.statusCode, 200);
      expect(String.fromCharCodes(r.body), '#EXTM3U\n');
      expect(r.finalUri.path, '/ok');
    });
    test('redirect to an internal address is blocked (every hop is re-checked)', () => expectLater(f.get(u('/to-internal')), fails('blocked_address')));
    test('redirect loop stops at the limit', () => expectLater(f.get(u('/loop')), fails('redirects')));
    test('oversized response is cut off', () => expectLater(f.get(u('/big')), fails('too_large')));
    test('DNS is resolved once per hop and the connection is pinned to it (no rebinding window)', () async {
      await f.get(u('/ok'));
      expect(resolveCalls, 1);
    });
  });
}
