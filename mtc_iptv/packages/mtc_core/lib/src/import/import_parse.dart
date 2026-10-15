// التحليل (§10.2–10.3): كشف الصيغة من المحتوى لا من الامتداد، ثم تحويل كل الصيغ إلى ImportItem موحّد،
// مع تنظيف الأسماء واستنتاج الجودة والدولة. Dart نقي (يعمل في Isolate منفصل من التطبيق).
import 'dart:convert';

import '../normalize.dart';
import '../playlist/m3u_parser.dart';

class ImportItem {
  final int line;
  final String name; // بعد التنظيف
  final String rawName;
  final String url;
  final String? tvgId, logo, group, country, language, quality, userAgent, referrer, epgId;
  final Map<String, String> headers;
  const ImportItem({
    required this.line,
    required this.name,
    required this.url,
    String? rawName,
    this.tvgId,
    this.logo,
    this.group,
    this.country,
    this.language,
    this.quality,
    this.userAgent,
    this.referrer,
    this.epgId,
    this.headers = const {},
  }) : rawName = rawName ?? name;

  ImportItem copyWith({String? name, String? country, String? group, String? language, String? quality, String? tvgId}) => ImportItem(
        line: line,
        name: name ?? this.name,
        rawName: rawName,
        url: url,
        tvgId: tvgId ?? this.tvgId,
        logo: logo,
        group: group ?? this.group,
        country: country ?? this.country,
        language: language ?? this.language,
        quality: quality ?? this.quality,
        userAgent: userAgent,
        referrer: referrer,
        epgId: epgId,
        headers: headers,
      );
}

class ImportIssue {
  final int line;
  final String kind; // invalid_url | orphan_extinf | bad_row | not_playlist | bad_json
  final String detail;
  const ImportIssue(this.line, this.kind, this.detail);
}

class ImportParse {
  final String format; // m3u | xspf | json | csv | tsv | txt
  final List<ImportItem> items;
  final List<ImportIssue> issues;
  final Set<String> attributes; // السمات الموجودة (tvg-id، group-title…)
  const ImportParse(this.format, this.items, this.issues, this.attributes);
}

String detectFormat(String text) {
  final t = text.trimLeft();
  final head = t.length > 4000 ? t.substring(0, 4000) : t;
  if (head.startsWith('#EXTM3U') || head.contains('#EXTINF')) return 'm3u';
  if (head.startsWith('<') && head.contains('<playlist') && head.contains('xspf')) return 'xspf';
  if (head.startsWith('[') || head.startsWith('{')) return 'json';
  final first = head.split(RegExp(r'\r?\n')).first.toLowerCase();
  // ترويسة فيها عمود رابط (بالإنجليزية أو العربية) ولا روابط فيها
  final hasUrlCol = RegExp(r'(^|[,\t"])\s*(url|link|stream|stream_url|الرابط)\s*("|[,\t]|$)').hasMatch(first) && !first.contains('://');
  if (first.contains('\t') && hasUrlCol) return 'tsv';
  if (first.contains(',') && hasUrlCol) return 'csv';
  return 'txt';
}

/// الدولة من tvg-id (AlJazeera.qa ← QA)، أو tvg-country، أو بادئة الاسم (|AR| ← لا دولة؛ |SA| ← SA).
String? inferCountry({String? tvgId, String? tvgCountry, String? rawName}) {
  final c = tvgCountry?.trim().split(RegExp('[;,]')).first.toUpperCase();
  if (c != null && RegExp(r'^[A-Z]{2}$').hasMatch(c)) return c;
  final m = RegExp(r'\.([a-z]{2})(@[\w-]+)?$', caseSensitive: false).firstMatch(tvgId ?? '');
  if (m != null) return m[1]!.toUpperCase();
  final p = namePrefixCode(rawName ?? '');
  if (p != null && p.length == 2 && p != 'AR' && p != 'EN') return p;
  return null;
}

ImportParse parseImport(String text) {
  final format = detectFormat(text);
  return switch (format) {
    'm3u' => _fromM3u(text),
    'xspf' => _fromXspf(text),
    'json' => _fromJson(text),
    'csv' => _fromDelimited(text, ',', 'csv'),
    'tsv' => _fromDelimited(text, '\t', 'tsv'),
    _ => _fromTxt(text),
  };
}

bool _validUrl(String u) => RegExp(r'^(https?|rtmps?|rtsp|udp|rtp)://', caseSensitive: false).hasMatch(u) && u.length <= 2000;

ImportItem _item({required int line, required String rawName, required String url, String? tvgId, String? logo, String? group, String? country, String? language, String? userAgent, String? referrer, Map<String, String> headers = const {}}) {
  final name = cleanDisplayName(rawName);
  return ImportItem(
    line: line,
    rawName: rawName,
    name: name.isEmpty ? rawName.trim() : name,
    url: url.trim(),
    tvgId: (tvgId?.trim().isEmpty ?? true) ? null : tvgId!.trim(),
    logo: (logo?.trim().isEmpty ?? true) ? null : logo!.trim(),
    group: (group?.trim().isEmpty ?? true) ? null : group!.trim(),
    country: inferCountry(tvgId: tvgId, tvgCountry: country, rawName: rawName),
    language: (language?.trim().isEmpty ?? true) ? null : language!.trim().toLowerCase(),
    quality: qualityFromName(rawName),
    userAgent: userAgent,
    referrer: referrer,
    headers: headers,
  );
}

ImportParse _fromM3u(String text) {
  final r = parseM3u(text);
  final attrs = <String>{};
  final items = <ImportItem>[];
  for (final e in r.entries) {
    attrs.addAll(e.attrs.keys);
    items.add(_item(
      line: e.line,
      rawName: e.attrs['tvg-name']?.isNotEmpty == true && e.rawName.trim().isEmpty ? e.attrs['tvg-name']! : e.rawName,
      url: e.url,
      tvgId: e.attrs['tvg-id'],
      logo: e.attrs['tvg-logo'],
      group: e.attrs['group-title'],
      country: e.attrs['tvg-country'],
      language: e.attrs['tvg-language'],
      userAgent: e.userAgent,
      referrer: e.referrer,
      headers: e.headers,
    ));
  }
  return ImportParse('m3u', items, [for (final i in r.issues) ImportIssue(i.line, i.kind, i.detail)], attrs);
}

ImportParse _fromTxt(String text) {
  final items = <ImportItem>[];
  final issues = <ImportIssue>[];
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i].trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    // «الاسم,الرابط» أو رابط وحده
    final idx = l.lastIndexOf(RegExp(r',\s*(https?|rtmps?|rtsp|udp)://'));
    final name = idx > 0 ? l.substring(0, idx) : '';
    final url = idx > 0 ? l.substring(idx + 1).trim() : l;
    if (!_validUrl(url)) {
      issues.add(ImportIssue(i + 1, 'invalid_url', l.length > 120 ? l.substring(0, 120) : l));
      continue;
    }
    items.add(_item(line: i + 1, rawName: name.isEmpty ? _nameFromUrl(url) : name, url: url));
  }
  return ImportParse('txt', items, issues, const {});
}

String _nameFromUrl(String url) {
  final segs = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
  final s = segs.isEmpty ? url : (segs.length > 1 && RegExp(r'^(index|playlist|master|chunklist)', caseSensitive: false).hasMatch(segs.last) ? segs[segs.length - 2] : segs.last);
  return s.replaceAll(RegExp(r'\.(m3u8?|ts|mpd|mp4)$', caseSensitive: false), '');
}

/// CSV/TSV مع ترويسة: الأعمدة تُعرف بأسمائها (name/title، url/link، logo، group/category، country، language، tvg-id/id).
ImportParse _fromDelimited(String text, String sep, String format) {
  final rows = parseDelimited(text, sep);
  if (rows.isEmpty) return ImportParse(format, const [], const [], const {});
  final head = [for (final h in rows.first) h.trim().toLowerCase()];
  int col(List<String> names) => head.indexWhere((h) => names.contains(h));
  final cName = col(['name', 'title', 'channel', 'tvg-name', 'الاسم']);
  final cUrl = col(['url', 'link', 'stream', 'stream_url', 'الرابط']);
  final cLogo = col(['logo', 'tvg-logo', 'image']);
  final cGroup = col(['group', 'group-title', 'category', 'الفئة']);
  final cCountry = col(['country', 'tvg-country', 'الدولة']);
  final cLang = col(['language', 'tvg-language', 'اللغة']);
  final cId = col(['tvg-id', 'tvg_id', 'id', 'uid']);
  final items = <ImportItem>[];
  final issues = <ImportIssue>[];
  if (cUrl < 0) return ImportParse(format, const [], [const ImportIssue(1, 'bad_row', 'no url column')], head.toSet());
  String? at(List<String> r, int c) => c >= 0 && c < r.length ? r[c] : null;
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    final url = (at(r, cUrl) ?? '').trim();
    if (!_validUrl(url)) {
      if (r.any((x) => x.trim().isNotEmpty)) issues.add(ImportIssue(i + 1, 'invalid_url', url));
      continue;
    }
    items.add(_item(
      line: i + 1,
      rawName: (at(r, cName) ?? '').trim().isEmpty ? _nameFromUrl(url) : at(r, cName)!,
      url: url,
      tvgId: at(r, cId),
      logo: at(r, cLogo),
      group: at(r, cGroup),
      country: at(r, cCountry),
      language: at(r, cLang),
    ));
  }
  return ImportParse(format, items, issues, head.toSet());
}

/// محلّل CSV بسيط يدعم الاقتباس "…" والفواصل والأسطر داخل الاقتباس.
List<List<String>> parseDelimited(String text, String sep) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == sep) {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((x) => x.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  row.add(cell.toString());
  if (row.any((x) => x.isNotEmpty)) rows.add(row);
  return rows;
}

ImportParse _fromXspf(String text) {
  final items = <ImportItem>[];
  final issues = <ImportIssue>[];
  String? tag(String block, String name) {
    final m = RegExp('<$name>([\\s\\S]*?)</$name>').firstMatch(block);
    return m == null ? null : _xmlUnescape(m[1]!.trim());
  }

  var n = 0;
  for (final m in RegExp(r'<track>([\s\S]*?)</track>').allMatches(text)) {
    n++;
    final b = m[1]!;
    final url = tag(b, 'location') ?? '';
    if (!_validUrl(url)) {
      issues.add(ImportIssue(n, 'invalid_url', url));
      continue;
    }
    items.add(_item(line: n, rawName: tag(b, 'title') ?? _nameFromUrl(url), url: url, logo: tag(b, 'image')));
  }
  return ImportParse('xspf', items, issues, const {'location', 'title', 'image'});
}

String _xmlUnescape(String s) => s.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&apos;', "'").replaceAll('&amp;', '&');

/// JSON: صيغة MTC للتصدير [{name,url,logo,country,category,language,tvg_id}] أو iptv-org streams [{channel,url,title,quality,user_agent,referrer}].
ImportParse _fromJson(String text) {
  Object? data;
  try {
    data = jsonDecode(text);
  } catch (e) {
    return ImportParse('json', const [], [ImportIssue(1, 'bad_json', '$e')], const {});
  }
  final list = data is List ? data : (data is Map && data['channels'] is List ? data['channels'] as List : const []);
  final items = <ImportItem>[];
  final issues = <ImportIssue>[];
  final attrs = <String>{};
  for (var i = 0; i < list.length; i++) {
    final o = list[i];
    if (o is! Map) continue;
    attrs.addAll(o.keys.map((k) => '$k'));
    String? s(List<String> keys) {
      for (final k in keys) {
        final v = o[k];
        if (v is String && v.trim().isNotEmpty) return v;
      }
      return null;
    }

    // صيغتنا: streams [{url}] أو url مباشر
    final urls = <String>[
      ?s(['url', 'link']),
      if (o['streams'] is List) for (final x in o['streams'] as List) if (x is Map && x['url'] is String) x['url'] as String,
    ];
    if (urls.isEmpty) {
      issues.add(ImportIssue(i + 1, 'invalid_url', '${o['name'] ?? o['channel'] ?? ''}'));
      continue;
    }
    for (final url in urls) {
      if (!_validUrl(url)) {
        issues.add(ImportIssue(i + 1, 'invalid_url', url));
        continue;
      }
      items.add(_item(
        line: i + 1,
        rawName: s(['name', 'title', 'name_en', 'name_ar', 'channel']) ?? _nameFromUrl(url),
        url: url,
        tvgId: s(['tvg_id', 'tvg-id', 'channel', 'uid', 'id']),
        logo: s(['logo', 'logo_url', 'tvg-logo']),
        group: s(['category', 'group', 'group-title']),
        country: s(['country', 'country_code']),
        language: s(['language', 'language_code']),
        userAgent: s(['user_agent', 'userAgent']),
        referrer: s(['referrer', 'referer']),
      ));
    }
  }
  return ImportParse('json', items, issues, attrs);
}
