import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseM3u', () {
    test('extended attributes, header and name with comma', () {
      final r = parseM3u('''#EXTM3U url-tvg="https://epg.example/guide.xml.gz"
#EXTINF:-1 tvg-id="AlJazeera.qa" tvg-name="Al Jazeera" tvg-logo="https://x/l.png" group-title="News, Arabic" tvg-chno="5",Al Jazeera (1080p) [Geo-blocked]
https://live-hls-web-aja.getaj.net/aja/index.m3u8
''');
      expect(r.hasExtM3u, isTrue);
      expect(r.epgUrl, 'https://epg.example/guide.xml.gz');
      final e = r.entries.single;
      expect(e.tvgId, 'AlJazeera.qa');
      expect(e.group, 'News, Arabic');
      expect(e.chno, 5);
      expect(e.name, 'Al Jazeera');
      expect(e.quality, 'FHD');
      expect(e.protocol, 'hls');
      expect(e.duration, -1);
      expect(r.issues, isEmpty);
    });

    test('EXTVLCOPT, EXTHTTP, KODIPROP and pipe headers', () {
      final r = parseM3u('''#EXTM3U
#EXTINF:-1,One
#EXTVLCOPT:http-user-agent=Mozilla/5.0 X
#EXTVLCOPT:http-referrer=https://site.example/
https://a.example/one.m3u8
#EXTINF:-1,Two
#EXTHTTP:{"User-Agent":"UA2","Origin":"https://o.example"}
#KODIPROP:inputstream.adaptive.manifest_type=hls
https://a.example/two.m3u8
#EXTINF:-1,Three
https://a.example/three.m3u8|User-Agent=UA%203&Referer=https://r.example/
''');
      expect(r.entries.map((e) => e.userAgent), ['Mozilla/5.0 X', 'UA2', 'UA 3']);
      expect(r.entries[0].referrer, 'https://site.example/');
      expect(r.entries[1].headers['Origin'], 'https://o.example');
      expect(r.entries[1].kodiProps['inputstream.adaptive.manifest_type'], 'hls');
      expect(r.entries[2].url, 'https://a.example/three.m3u8');
      expect(r.entries[2].referrer, 'https://r.example/');
    });

    test('headers do not leak to the next entry', () {
      final r = parseM3u('#EXTM3U\n#EXTINF:-1,A\n#EXTVLCOPT:http-user-agent=UA\nhttp://a/1.ts\n#EXTINF:-1,B\nhttp://a/2.ts\n');
      expect(r.entries[1].userAgent, isNull);
    });

    test('EXTGRP fills missing group-title', () {
      final r = parseM3u('#EXTM3U\n#EXTINF:-1,A\n#EXTGRP:Sports\nhttp://a/1.m3u8\n');
      expect(r.entries.single.group, 'Sports');
    });

    test('plain list without EXTINF, BOM and CRLF', () {
      final r = parseM3u('﻿http://h.example/live/news.m3u8\r\nrtmp://r.example/app/stream\r\n');
      expect(r.entries.map((e) => e.name), ['news', 'stream']);
      expect(r.entries[1].protocol, 'rtmp');
    });

    test('invalid lines are reported, not thrown', () {
      final r = parseM3u('#EXTM3U\n#EXTINF:-1,Bad\nnot a url\n#EXTINF:-1,Orphan\n#EXTINF:-1,Ok\nhttp://ok/1.ts\n');
      expect(r.entries.single.name, 'Ok');
      expect(r.issues.map((i) => i.kind), containsAll(['invalid_url', 'orphan_extinf']));
    });

    test('not an m3u at all', () {
      expect(parseM3u('<html>hello</html>').issues.map((i) => i.kind), contains('not_m3u'));
    });
  });

  group('credentials', () {
    test('xtream path, query and userinfo are detected and masked', () {
      const x = 'http://host.example:80/live/user1/pass1/255.ts';
      expect(detectCredentials(x), isTrue);
      expect(maskCredentials(x), 'http://host.example:80/live/••••/••••/255.ts');
      expect(detectCredentials('http://h/get.php?username=a&password=b'), isTrue);
      expect(maskCredentials('http://h/get.php?username=a&password=b'), 'http://h/get.php?username=••••&password=••••');
      expect(maskCredentials('http://u:p@h/x.m3u8'), 'http://••••@h/x.m3u8');
      expect(detectCredentials('https://cdn.example/live/channel/index.m3u8'), isFalse);
    });
  });

  group('normalize', () {
    test('normName matches SQL public.norm_name', () {
      expect(normName('Al Jazeera (1080p) HD'), 'aljazeera');
      expect(normName('ATV+'), 'atv+'); // + تبقى عمدًا
      expect(normName('MBC 1 [Geo-blocked]'), 'mbc1');
      expect(normName('Sky News Arabia TV'), 'skynewsarabia');
      expect(normName('beIN Sports 4K'), 'beinsports');
      expect(normName('HDTV'), 'hdtv'); // hd داخل كلمة لا يُحذف
    });

    test('matchKey folds Arabic letters, tashkeel and digits', () {
      expect(matchKey('قناة الجزيرة'), matchKey('قناه الجزيره'));
      expect(matchKey('إم بي سي ١'), matchKey('ام بي سي 1'));
      expect(matchKey('العَرَبِيَّة'), matchKey('العربية'));
    });

    test('cleanDisplayName and prefix code', () {
      expect(cleanDisplayName('|AR| MBC 1 (720p) [Not 24/7]'), 'MBC 1');
      expect(cleanDisplayName('SA: Saudi TV'), 'Saudi TV');
      expect(namePrefixCode('|SA| MBC'), 'SA');
      expect(qualityFromName('Channel 4K'), '4K');
      expect(qualityFromName('Channel'), isNull);
    });
  });
}
