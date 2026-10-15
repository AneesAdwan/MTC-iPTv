import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  ImportItem item({String name = 'Rotana Cinema KSA', String? group = 'VIP | Movies', String? tvgId, String? country}) =>
      ImportItem(line: 1, name: name, url: 'https://x/1', group: group, tvgId: tvgId, country: country);

  test('group -> category, name -> country/language, cleanup', () {
    final o = applyRules(item(), const [
      TransformRule('name_cleanup', 'VIP', ''),
      TransformRule('name_cleanup', ' KSA', ''),
      TransformRule('group_category', 'movies', 'movies'),
      TransformRule('name_country', 'KSA', 'sa'),
      TransformRule('name_language', 'rotana', 'ARA'),
    ]);
    expect([o.item.name, o.category, o.item.country, o.item.language], ['Rotana Cinema', 'movies', 'SA', 'ara']);
    expect(o.applied, containsAll(['category:movies', 'country:sa']));
  });

  test('known country/language are not overwritten; first category rule wins', () {
    final o = applyRules(item(country: 'EG'), const [
      TransformRule('name_country', 'KSA', 'SA'),
      TransformRule('group_category', 'VIP', 'general'),
      TransformRule('group_category', 'Movies', 'movies'),
    ]);
    expect([o.item.country, o.category], ['EG', 'general']);
  });

  test('id_map links to our channel so matching finds it', () {
    final o = applyRules(item(tvgId: 'rotana.cinema.sa'), const [TransformRule('id_map', 'Rotana.Cinema.SA', 'manual:42')]);
    expect([o.mappedUid, o.item.tvgId], ['manual:42', 'manual:42']);
    final rep = matchImport([o.item], CatalogIndex([const CatalogChannel(id: 'c42', uid: 'manual:42', name: 'Rotana Cinema')], const {}));
    expect(rep.results.single.channelId, 'c42');
  });

  test('regex rules, and invalid regex is ignored instead of failing the import', () {
    expect(applyRules(item(name: 'Al Jazeera [Geo]'), const [TransformRule('name_cleanup', r'\[.*?\]', '', isRegex: true)]).item.name, 'Al Jazeera');
    expect(applyRules(item(), const [TransformRule('name_country', '([', 'SA', isRegex: true)]).item.country, isNull);
  });
}
