import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

/// خادم وهمي: مسار ← (رمز HTTP، المحتوى).
StreamProbe fake(Map<String, (int, String)> routes, {List<String>? seen}) => StreamProbe(fetch: (uri, headers, max) async {
      seen?.add('${uri.path} ${headers['User-Agent']?.split('/').first}');
      final r = routes[uri.path];
      if (r == null) return SafeFetchResult(uri, 404, null, Uint8List(0));
      return SafeFetchResult(uri, r.$1, null, Uint8List.fromList(utf8.encode(r.$2)));
    });

void main() {
  const master = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1,RESOLUTION=1280x720\nv/720.m3u8\n';
  const media = '#EXTM3U\n#EXT-X-TARGETDURATION:4\n#EXTINF:4,\nseg1.ts\n#EXTINF:4,\nseg2.ts\n';

  test('HLS master -> variant -> first segment = reachable', () async {
    final seen = <String>[];
    final r = await fake({'/live/index.m3u8': (200, master), '/live/v/720.m3u8': (200, media), '/live/v/seg1.ts': (200, 'TSDATA')}, seen: seen)
        .check('https://cdn.example/live/index.m3u8');
    expect(r.state, 'reachable');
    expect(seen.map((s) => s.split(' ').first), ['/live/index.m3u8', '/live/v/720.m3u8', '/live/v/seg1.ts']);
    expect(seen.first, endsWith('MTC-iPTv-HealthCheck')); // User-Agent واضح (§12.6)
  });

  test('empty media playlist = unavailable', () async {
    final r = await fake({'/a.m3u8': (200, '#EXTM3U\n#EXT-X-TARGETDURATION:4\n')}).check('https://x/a.m3u8');
    expect(r.state, 'unavailable');
  });

  test('missing segment = unavailable with reason', () async {
    final r = await fake({'/a.m3u8': (200, media)}).check('https://x/a.m3u8');
    expect([r.state, r.reason], ['unavailable', 'segment: HTTP 404']);
  });

  test('403 means auth_failed only when the URL carries credentials', () async {
    final p = fake({'/a.m3u8': (403, '')});
    expect((await p.check('https://x/a.m3u8', hasCredentials: true)).state, 'auth_failed');
    expect((await p.check('https://x/a.m3u8')).state, 'inconclusive'); // عند الشك (§12.2)
  });

  test('5xx is inconclusive, 404/410 unavailable', () async {
    expect((await fake({'/a': (503, '')}).check('https://x/a')).state, 'inconclusive');
    expect((await fake({'/a': (410, '')}).check('https://x/a')).state, 'unavailable');
  });

  test('non-HLS with data = reachable', () async {
    expect((await fake({'/a.ts': (200, 'xx')}).check('http://x/a.ts')).state, 'reachable');
  });

  test('network failures map to network_error; blocked hosts are not judged', () async {
    Future<ProbeResult> throwing(Object e) => StreamProbe(fetch: (_, _, _) async => throw e).check('https://x/a');
    expect((await throwing(SafeFetchException('dns', 'x'))).state, 'network_error');
    expect((await throwing(SafeFetchException('timeout', 'x'))).state, 'network_error');
    expect((await throwing(const SocketException('refused'))).state, 'network_error');
    expect((await throwing(SafeFetchException('blocked_address', 'x'))).state, 'inconclusive');
  });

  test('truncate returns a partial body instead of failing', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response.add(List.filled(100000, 65));
      req.response.close();
    });
    final f = SafeFetcher(
      policy: SafeFetchPolicy(maxBytes: 1000, truncate: true, anyPort: true, allowedLocal: [InternetAddress.loopbackIPv4]),
    );
    final r = await f.get(Uri.parse('http://127.0.0.1:${server.port}/x'));
    expect(r.body.length, 1000);
    await server.close(force: true);
  });
}
