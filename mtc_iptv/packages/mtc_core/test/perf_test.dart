// الأداء (§26.1): 50,000 سطر استيراد و10,000 قناة في الكتالوج.
// حدود سخية (أبطأ أجهزة CI) تمنع التراجع؛ الأرقام الفعلية تُطبع وتُوثَّق في docs/releases/3.0.0-windows.md.
import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  // 25,000 قناة × سطران (#EXTINF + الرابط) = 50,000 سطر
  final m3u = StringBuffer('#EXTM3U\n');
  for (var i = 0; i < 25000; i++) {
    final cc = ['SA', 'AE', 'EG', 'JO', 'QA'][i % 5];
    m3u
      ..writeln('#EXTINF:-1 tvg-id="Ch$i.${cc.toLowerCase()}" tvg-name="Channel $i" tvg-logo="https://logo.example/$i.png" group-title="Group ${i % 40}",Channel $i HD')
      ..writeln('https://cdn${i % 30}.example.com/live/$i/index.m3u8');
  }
  final text = m3u.toString();

  final catalog = [
    for (var i = 0; i < 10000; i++)
      CatalogChannel(id: 'id$i', uid: 'Ch$i.${['sa', 'ae', 'eg', 'jo', 'qa'][i % 5]}', name: 'Channel $i', nameAr: 'قناة $i', country: ['SA', 'AE', 'EG', 'JO', 'QA'][i % 5]),
  ];
  final urls = {for (var i = 0; i < 10000; i += 2) 'https://cdn${i % 30}.example.com/live/$i/index.m3u8': 'id$i'};

  test('50,000-line playlist: parse + match against 10,000 channels', () {
    final sw = Stopwatch()..start();
    final parsed = parseImport(text);
    final tParse = sw.elapsedMilliseconds;
    expect(parsed.items.length, 25000);

    sw.reset();
    final index = CatalogIndex(catalog, urls);
    final tIndex = sw.elapsedMilliseconds;

    sw.reset();
    final report = matchImport(parsed.items, index);
    final tMatch = sw.elapsedMilliseconds;

    final c = report.counts;
    expect(c['existing'], 5000); // نصف قنوات الكتالوج روابطها موجودة
    expect(c['update'], 5000); // والنصف الآخر يطابَق بالمعرّف
    expect(c['new'], 15000);

    print('perf: parse ${tParse}ms · index ${tIndex}ms · match ${tMatch}ms (25k items, 10k catalog)');
    expect(tParse, lessThan(8000));
    expect(tMatch + tIndex, lessThan(8000));
  });

  test('normalization of 10,000 Arabic/English names', () {
    final sw = Stopwatch()..start();
    var n = 0;
    for (var i = 0; i < 10000; i++) {
      n += matchKey('قناة الجزيرة الإخبارية $i HD').length + matchKey('Al Jazeera News $i FHD').length;
    }
    print('perf: matchKey x20,000 ${sw.elapsedMilliseconds}ms');
    expect(n, greaterThan(0));
    expect(sw.elapsedMilliseconds, lessThan(5000));
  });
}
