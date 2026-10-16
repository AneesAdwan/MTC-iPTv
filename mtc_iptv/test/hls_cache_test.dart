// سرعة فتح البث (خطة التحسينات 1.4): القائمة الرئيسية تُحفظ دقيقتين، الجلب المسبق يملؤها، والفشل يمسحها.
// ملف منفصل بلا testWidgets: ربط الواجهات في flutter_test يحجب HttpClient الحقيقي (هنا خادم محلي فقط).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_iptv/player/hls_resolver.dart';

void main() {
  late HttpServer server;
  var hits = 0;
  String url() => 'http://127.0.0.1:${server.port}/master.m3u8';

  setUp(() async {
    hits = 0;
    HlsResolver.clearCache();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      hits++;
      r.response.write('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360\nlow.m3u8\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1280x720\nhd.m3u8\n');
      await r.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  test('second open of the same channel does not wait for the network', () async {
    final a = await const HlsResolver().resolve(url());
    final b = await const HlsResolver().resolve(url());
    expect(hits, 1);
    expect(a.playUrl, endsWith('/hd.m3u8'));
    expect(b.playUrl, a.playUrl);
  });

  test('prefetch fills the cache; invalidate after a failure fetches again', () async {
    await const HlsResolver().prefetch(url());
    expect(hits, 1);
    await const HlsResolver().resolve(url(), prefer: 360);
    expect(hits, 1);
    HlsResolver.invalidate(url());
    final r = await const HlsResolver().resolve(url(), prefer: 360);
    expect(hits, 2);
    expect(r.playUrl, endsWith('/low.m3u8'));
  });

  test('concurrent requests share one download', () async {
    await Future.wait([const HlsResolver().prefetch(url()), const HlsResolver().resolve(url())]);
    expect(hits, 1);
  });

  test('unreachable server falls back to the original URL quickly', () async {
    final dead = 'http://127.0.0.1:1/x.m3u8';
    final sw = Stopwatch()..start();
    final r = await const HlsResolver().resolve(dead);
    expect(r.playUrl, dead);
    expect(sw.elapsed, lessThan(const Duration(seconds: 4)));
  });
}
