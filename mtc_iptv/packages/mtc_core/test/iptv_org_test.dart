// موصل iptv-org (§13.1 الاختبارات): تحليل بعيّنات محفوظة، وحالات الفشل (شكل متغيّر، ملف فارغ).
import 'dart:convert';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  final channels = jsonEncode([
    {'id': 'AlJazeera.qa', 'name': 'Al Jazeera', 'alt_names': ['الجزيرة'], 'network': null, 'country': 'QA', 'categories': ['news'], 'is_nsfw': false, 'closed': null},
    {'id': 'Adult.xx', 'name': 'X', 'country': 'US', 'categories': [], 'is_nsfw': true},
    {'id': 'Old.tv', 'name': 'Old', 'country': 'EG', 'categories': [], 'is_nsfw': false, 'closed': '2020-01-01'},
  ]);
  final streams = jsonEncode([
    {'channel': 'AlJazeera.qa', 'feed': null, 'url': 'https://live/aja.m3u8', 'quality': '1080p', 'user_agent': 'UA'},
    {'channel': null, 'url': 'https://orphan/x.m3u8'},
  ]);
  final logos = jsonEncode([
    {'channel': 'AlJazeera.qa', 'feed': 'SD', 'url': 'https://logo/feed.png'},
    {'channel': 'AlJazeera.qa', 'feed': null, 'url': 'https://logo/main.png'},
  ]);

  test('parse links streams and the main logo; adult and closed channels are dropped', () {
    final list = IptvOrgConnector.parse(channels, streams, logos);
    expect(list.map((c) => c.id), ['AlJazeera.qa']);
    final aj = list.single;
    expect([aj.logo, aj.country, aj.altNames.single, aj.streams.single.userAgent], ['https://logo/main.png', 'QA', 'الجزيرة', 'UA']);
  });

  test('selected channels become M3U that the importer reads back', () {
    final m3u = IptvOrgConnector.toM3u(IptvOrgConnector.parse(channels, streams, logos));
    final it = parseImport(m3u).items.single;
    expect([it.tvgId, it.country, it.group, it.userAgent, it.quality], ['AlJazeera.qa', 'QA', 'news', 'UA', 'FHD']);
  });

  test('shape change stops the connector instead of importing garbage', () {
    expect(() => IptvOrgConnector.parse('{"channels": []}', '[]', '[]'), throwsA(isA<ConnectorShapeChanged>()));
    final broken = jsonEncode([for (var i = 0; i < 10; i++) {'nope': i}]);
    expect(() => IptvOrgConnector.parse(broken, '[]', '[]'), throwsA(isA<ConnectorShapeChanged>()));
  });

  test('empty files parse to nothing (not an error)', () => expect(IptvOrgConnector.parse('[]', '[]', '[]'), isEmpty));
}
