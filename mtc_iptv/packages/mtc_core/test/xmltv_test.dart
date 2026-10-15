import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

const sample = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="AlJazeera.qa"><display-name lang="ar">الجزيرة</display-name><display-name>Al Jazeera</display-name></channel>
  <channel id="mbc1.ae"><display-name>MBC 1 HD</display-name></channel>
  <programme start="20301001100000 +0300" stop="20301001110000 +0300" channel="AlJazeera.qa"><title lang="ar">الحصاد &amp; الأخبار</title><desc>ملخص</desc><category>News</category></programme>
  <programme start="20301001110000 +0300" stop="20301001120000 +0300" channel="AlJazeera.qa"><title>Next</title></programme>
  <programme start="20301001090000 +0000" stop="20301001100000 +0000" channel="mbc1.ae"><title>Show</title></programme>
  <programme start="20301001100000 +0000" stop="20301001090000 +0000" channel="mbc1.ae"><title>Inverted</title></programme>
  <programme start="20301001130000 +0000" stop="20301001140000 +0000" channel="mbc1.ae"><title></title></programme>
</tv>''';

void main() {
  test('time zones are converted to UTC', () {
    expect(parseXmltvTime('20301001100000 +0300'), DateTime.utc(2030, 10, 1, 7));
    expect(parseXmltvTime('20301001100000 -0130'), DateTime.utc(2030, 10, 1, 11, 30));
    expect(parseXmltvTime('203010011000'), DateTime.utc(2030, 10, 1, 10));
  });

  test('channels, programmes, entities; inverted and untitled programmes are skipped', () {
    final d = parseXmltv(sample);
    expect(d.channelNames['AlJazeera.qa'], ['الجزيرة', 'Al Jazeera']);
    expect(d.byChannel['AlJazeera.qa']!.first.title, 'الحصاد & الأخبار');
    expect(d.byChannel['AlJazeera.qa']!.first.category, 'News');
    expect(d.byChannel['mbc1.ae']!.length, 1);
    expect(d.programmes, 3);
  });

  test('window keeps only overlapping programmes', () {
    final d = parseXmltv(sample, from: DateTime.utc(2030, 10, 1, 8, 30), to: DateTime.utc(2030, 10, 1, 9));
    expect(d.byChannel.keys, ['AlJazeera.qa']);
    expect(d.byChannel['AlJazeera.qa']!.single.title, 'Next');
  });

  test('matching: epg_id/uid without @suffix, then normalized name', () {
    final d = parseXmltv(sample);
    final m = matchEpgChannels(d, const [
      EpgTarget('AlJazeera.qa@HD', null, ['Al Jazeera']),
      EpgTarget('manual:1', null, ['MBC 1']),
      EpgTarget('x', 'nothing.here', ['Unknown']),
    ]);
    expect(m, {'AlJazeera.qa@HD': 'AlJazeera.qa', 'manual:1': 'mbc1.ae'});
    expect(matchEpgChannels(d, const [EpgTarget('manual:1', null, ['MBC 1'])], byNameFallback: false), isEmpty);
  });

  test('schedule gaps and overlaps', () {
    DateTime t(int h, [int m = 0]) => DateTime.utc(2030, 1, 1, h, m);
    final issues = scheduleIssues([(t(10), t(11)), (t(11, 30), t(12)), (t(11, 50), t(13))]);
    expect(issues.map((i) => i.kind), ['gap', 'overlap']);
    expect(issues.first.length, const Duration(minutes: 30));
  });
}
