// المطابقة (§11.1) والتشغيل التجريبي (§11.2 Dry-run): كل عنصر مستورد يُصنَّف دون أي كتابة:
//   failed      رابط غير صالح
//   existing    الرابط نفسه موجود في الكتالوج (لا شيء جديد)
//   in_file     الرابط مكرر داخل الملف نفسه
//   update      قناة موجودة بمعرّف (tvg-id/uid أو EPG): يُضاف الرابط كسيرفر، ولا تُستبدل بياناتها
//   new         قناة جديدة: تذهب لقيد المراجعة دائمًا (§10.4)
// المطابقة بالاسم + الدولة ثقتها «متوسطة»: لا دمج تلقائي أبدًا — تبقى «جديدة» مع سبب «مكررة محتملة».
import '../normalize.dart';
import 'import_parse.dart';

class CatalogChannel {
  final String id, uid, name;
  final String? nameAr, nameEn, country, epgId, publishState;
  final List<String> altNames;
  const CatalogChannel({required this.id, required this.uid, required this.name, this.nameAr, this.nameEn, this.country, this.epgId, this.publishState, this.altNames = const []});
}

class CatalogIndex {
  final Map<String, CatalogChannel> byUid = {}, byEpg = {}, byId = {};
  final Map<String, List<CatalogChannel>> byNameCountry = {};
  final Map<String, String> urlToChannel; // الرابط المطبّع ← معرّف القناة

  CatalogIndex(List<CatalogChannel> channels, Map<String, String> urls) : urlToChannel = {for (final e in urls.entries) normalizeUrl(e.key): e.value} {
    for (final c in channels) {
      byId[c.id] = c;
      byUid[c.uid.toLowerCase()] = c;
      byUid.putIfAbsent(_baseId(c.uid), () => c);
      if (c.epgId != null) byEpg[c.epgId!.toLowerCase()] = c;
      for (final n in {c.name, ?c.nameAr, ?c.nameEn, ...c.altNames}) {
        final k = '${matchKey(n)}|${c.country ?? ''}';
        if (matchKey(n).isNotEmpty) (byNameCountry[k] ??= []).add(c);
      }
    }
  }
}

/// AlJazeera.qa@SD ← aljazeera.qa
String _baseId(String id) => id.toLowerCase().split('@').first;

String normalizeUrl(String u) {
  final t = u.trim();
  final m = RegExp(r'^([a-z][a-z0-9+.-]*://)([^/?#]*)(.*)$', caseSensitive: false).firstMatch(t);
  return m == null ? t : '${m[1]!.toLowerCase()}${m[2]!.toLowerCase()}${m[3]}';
}

class MatchResult {
  final ImportItem item;
  final String kind; // failed | existing | in_file | update | new
  final String? channelId; // update/existing: القناة المطابقة
  final String uid; // المعرّف الذي يُرسل للخادم (للقنوات الجديدة يجمع روابط القناة نفسها)
  final String why; // سبب مقروء
  final String? possibleDuplicateOf; // new: مطابقة بالاسم (متوسطة)
  const MatchResult(this.item, this.kind, this.uid, this.why, {this.channelId, this.possibleDuplicateOf});
}

class MatchReport {
  final List<MatchResult> results;
  const MatchReport(this.results);
  Map<String, int> get counts {
    final m = <String, int>{};
    for (final r in results) {
      m[r.kind] = (m[r.kind] ?? 0) + 1;
    }
    return m;
  }

  /// عدد القنوات الجديدة الفعلي (عدة روابط لنفس القناة = قناة واحدة).
  int get newChannels => results.where((r) => r.kind == 'new').map((r) => r.uid).toSet().length;
}

MatchReport matchImport(List<ImportItem> items, CatalogIndex index) {
  final seen = <String>{};
  final out = <MatchResult>[];
  for (final it in items) {
    final url = normalizeUrl(it.url);
    if (!RegExp(r'^(https?)://', caseSensitive: false).hasMatch(url)) {
      // الخادم يقبل http(s) فقط (§19.3)
      out.add(MatchResult(it, 'failed', '', 'unsupported scheme'));
      continue;
    }
    if (!seen.add(url)) {
      out.add(MatchResult(it, 'in_file', '', 'duplicate URL in this file'));
      continue;
    }
    final existing = index.urlToChannel[url];
    if (existing != null) {
      out.add(MatchResult(it, 'existing', index.byId[existing]?.uid ?? '', 'URL already in: ${index.byId[existing]?.name ?? existing}', channelId: existing));
      continue;
    }
    // 2) tvg-id / uid  3) EPG
    final byId = it.tvgId == null ? null : (index.byUid[it.tvgId!.toLowerCase()] ?? index.byUid[_baseId(it.tvgId!)]);
    final byEpg = it.tvgId == null ? null : index.byEpg[it.tvgId!.toLowerCase()];
    final hit = byId ?? byEpg;
    if (hit != null) {
      out.add(MatchResult(it, 'update', hit.uid, byId != null ? 'tvg-id = ${hit.uid}' : 'EPG id = ${hit.epgId}', channelId: hit.id));
      continue;
    }
    // 5) الاسم المطبّع + الدولة: اقتراح فقط
    final key = '${matchKey(it.name)}|${it.country ?? ''}';
    final near = index.byNameCountry[key];
    final uid = it.tvgId ?? 'import:${matchKey(it.name).replaceAll(' ', '-')}:${(it.country ?? 'xx').toLowerCase()}';
    out.add(MatchResult(it, 'new', uid, near == null ? 'no match' : 'possible duplicate (name + country)', possibleDuplicateOf: near?.first.id));
  }
  return MatchReport(out);
}
