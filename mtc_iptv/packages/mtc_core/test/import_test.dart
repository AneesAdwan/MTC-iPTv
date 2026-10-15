import 'dart:convert';
import 'dart:io';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  group('decode (§10.2)', () {
    test('utf-8, BOM, utf-16 and windows-1256', () {
      expect(decodeImport(utf8.encode('قناة')).encoding, 'utf-8');
      expect(decodeImport([0xEF, 0xBB, 0xBF, ...utf8.encode('x')]).text, 'x');
      final le = [0xFF, 0xFE, for (final u in 'قناة'.codeUnits) ...[u & 0xff, u >> 8]];
      expect(decodeImport(le).text, 'قناة');
      // «قناة» في Windows-1256: ق=0xDE ن=0xE4 ا=0xC7 ة=0xC9
      final cp = decodeImport([0xDE, 0xE4, 0xC7, 0xC9]);
      expect([cp.encoding, cp.text], ['windows-1256', 'قناة']);
    });

    test('gzip is unpacked; bombs are refused', () {
      final gz = gzip.encode(utf8.encode('#EXTM3U\n'));
      final d = decodeImport(gz);
      expect([d.gzipped, d.text], [true, '#EXTM3U\n']);
      final bomb = gzip.encode(List.filled(maxImportBytes + 1024, 0x20));
      expect(() => decodeImport(bomb), throwsA(isA<ImportTooLarge>()));
    });
  });

  group('formats (§10.2)', () {
    test('detected from content, not extension', () {
      expect(detectFormat('#EXTM3U\n#EXTINF:-1,A\nhttp://x/a'), 'm3u');
      expect(detectFormat('<?xml version="1.0"?><playlist xmlns="http://xspf.org/ns/0/">'), 'xspf');
      expect(detectFormat('[{"name":"A","url":"http://x"}]'), 'json');
      expect(detectFormat('name,url\nA,http://x/a'), 'csv');
      expect(detectFormat('name\turl\nA\thttp://x/a'), 'tsv');
      expect(detectFormat('http://x/a\nhttp://x/b'), 'txt');
    });

    test('m3u: attributes, cleaned names, quality and country inference', () {
      final p = parseImport('#EXTM3U\n#EXTINF:-1 tvg-id="AlJazeera.qa@SD" tvg-logo="http://l/a.png" group-title="News",Al Jazeera (1080p) [Geo-blocked]\nhttps://x/aja.m3u8\n');
      final it = p.items.single;
      expect([it.name, it.tvgId, it.country, it.group, it.quality], ['Al Jazeera', 'AlJazeera.qa@SD', 'QA', 'News', 'FHD']);
      expect(p.attributes, containsAll(['tvg-id', 'group-title']));
    });

    test('csv with quoted commas and an Arabic header', () {
      final p = parseImport('الاسم,الرابط,الدولة\n"قناة, الأولى",https://x/1.m3u8,SA\nbad,notaurl,SA\n');
      expect(p.format, 'csv');
      expect(p.items.single.name, 'قناة, الأولى');
      expect(p.items.single.country, 'SA');
      expect(p.issues.single.kind, 'invalid_url');
    });

    test('txt: "name,url" and bare urls', () {
      final p = parseImport('MBC 1,https://x/mbc1/index.m3u8\nhttps://x/live/rotana/playlist.m3u8\njunk\n');
      expect(p.items.map((i) => i.name), ['MBC 1', 'rotana']);
      expect(p.issues.single.line, 3);
    });

    test('json: MTC export format with several streams per channel', () {
      final p = parseImport(jsonEncode([
        {'name': 'A', 'tvg_id': 'A.sa', 'streams': [{'url': 'https://x/a1'}, {'url': 'https://x/a2'}]},
      ]));
      expect(p.items.map((i) => i.url), ['https://x/a1', 'https://x/a2']);
      expect(p.items.first.country, 'SA');
    });

    test('xspf', () {
      final p = parseImport('<?xml version="1.0"?><playlist version="1" xmlns="http://xspf.org/ns/0/"><trackList><track><location>https://x/a.m3u8</location><title>A &amp; B</title></track></trackList></playlist>');
      expect(p.items.single.name, 'A & B');
    });
  });

  group('matching (§11.1) — dry run, nothing written', () {
    final index = CatalogIndex([
      const CatalogChannel(id: 'c1', uid: 'AlJazeera.qa', name: 'Al Jazeera', country: 'QA'),
      const CatalogChannel(id: 'c2', uid: 'manual:1', name: 'MBC 1', nameAr: 'إم بي سي 1', country: 'SA', epgId: 'MBC1.sa'),
    ], {'HTTPS://CDN.X/aja.m3u8': 'c1'});

    MatchResult one(String m3u) => matchImport(parseImport('#EXTM3U\n$m3u').items, index).results.single;

    test('same URL (host case-insensitive) = existing', () => expect(one('#EXTINF:-1,X\nhttps://cdn.x/aja.m3u8').kind, 'existing'));
    test('tvg-id with @suffix = update of that channel', () {
      final r = one('#EXTINF:-1 tvg-id="AlJazeera.qa@HD",AJ\nhttps://other/aja2.m3u8');
      expect([r.kind, r.channelId, r.uid], ['update', 'c1', 'AlJazeera.qa']);
    });
    test('EPG id = update', () => expect(one('#EXTINF:-1 tvg-id="MBC1.sa",MBC\nhttps://o/m.m3u8').channelId, 'c2'));
    test('name + country only: new, flagged as possible duplicate (never auto-merged)', () {
      final r = one('#EXTINF:-1 tvg-country="SA",MBC 1 HD\nhttps://o/m2.m3u8');
      expect([r.kind, r.possibleDuplicateOf], ['new', 'c2']);
    });
    test('duplicates inside the file and bad schemes', () {
      final rep = matchImport(parseImport('#EXTM3U\n#EXTINF:-1,N\nhttps://n/1\n#EXTINF:-1,N\nhttps://n/1\n#EXTINF:-1,R\nrtmp://n/live').items, index);
      expect(rep.results.map((r) => r.kind), ['new', 'in_file', 'failed']);
    });
    test('several URLs of one new channel = one new channel', () {
      final rep = matchImport(parseImport('#EXTM3U\n#EXTINF:-1 tvg-id="New.eg",New\nhttps://n/1\n#EXTINF:-1 tvg-id="New.eg",New\nhttps://n/2').items, index);
      expect(rep.newChannels, 1);
    });
  });

  group('export (§10.5)', () {
    const ch = ExportChannel(uid: 'A.sa', name: 'A', number: 7, country: 'SA', category: 'news', streams: [
      ExportStream('https://x/live/u/p/1.ts', hasCredentials: true),
      ExportStream('https://x/a.m3u8', userAgent: 'UA'),
      ExportStream('https://x/b.m3u8', working: false),
    ]);
    test('credentials are skipped by default; working-only and best-only', () {
      expect(exportStreams(ch, const ExportOptions()).map((s) => s.url), ['https://x/a.m3u8', 'https://x/b.m3u8']);
      expect(exportStreams(ch, const ExportOptions(workingOnly: true, bestOnly: true)).map((s) => s.url), ['https://x/a.m3u8']);
    });
    test('m3u round-trips through the importer', () {
      final m3u = toM3u([ch], const ExportOptions());
      expect(m3u, contains('#EXTVLCOPT:http-user-agent=UA'));
      final back = parseImport(m3u).items;
      expect(back.map((i) => [i.tvgId, i.country, i.group, i.userAgent]).first, ['A.sa', 'SA', 'news', 'UA']);
    });
    test('csv, json and xspf round-trip too', () {
      expect(parseImport(toCsv([ch], const ExportOptions())).items.length, 2);
      expect(parseImport(toJson([ch], const ExportOptions())).items.length, 2);
      expect(parseImport(toXspf([ch], const ExportOptions())).items.length, 2);
    });
  });
}
