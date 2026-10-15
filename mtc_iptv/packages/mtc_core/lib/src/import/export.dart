// التصدير (§10.5): M3U (مع tvg-* و#EXTVLCOPT)، CSV، JSON، XSPF — مع إخفاء الروابط ذات بيانات الاعتماد.
import 'dart:convert';

class ExportStream {
  final String url;
  final String? userAgent, referrer, label;
  final bool working, hasCredentials;
  const ExportStream(this.url, {this.userAgent, this.referrer, this.label, this.working = true, this.hasCredentials = false});
}

class ExportChannel {
  final String uid, name;
  final int? number;
  final String? logo, country, category, language, epgId;
  final List<ExportStream> streams; // مرتبة بالأولوية
  const ExportChannel({required this.uid, required this.name, this.number, this.logo, this.country, this.category, this.language, this.epgId, this.streams = const []});
}

class ExportOptions {
  final bool workingOnly; // الروابط العاملة فقط
  final bool bestOnly; // أول رابط فقط (الأفضل بالأولوية)
  final bool skipCredentials; // لا تُصدَّر الروابط ذات بيانات الاعتماد
  const ExportOptions({this.workingOnly = false, this.bestOnly = false, this.skipCredentials = true});
}

/// الروابط التي تُصدَّر لقناة حسب الخيارات.
List<ExportStream> exportStreams(ExportChannel c, ExportOptions o) {
  var s = c.streams.where((x) => (!o.workingOnly || x.working) && (!o.skipCredentials || !x.hasCredentials)).toList();
  if (o.bestOnly && s.length > 1) s = [s.first];
  return s;
}

String _attr(String v) => v.replaceAll('"', "'").replaceAll('\n', ' ');

String toM3u(List<ExportChannel> list, ExportOptions o, {String? epgUrl}) {
  final b = StringBuffer(epgUrl == null ? '#EXTM3U\n' : '#EXTM3U url-tvg="${_attr(epgUrl)}"\n');
  for (final c in list) {
    for (final s in exportStreams(c, o)) {
      b.write('#EXTINF:-1 tvg-id="${_attr(c.epgId ?? c.uid)}"');
      if (c.number != null) b.write(' tvg-chno="${c.number}"');
      if (c.logo != null) b.write(' tvg-logo="${_attr(c.logo!)}"');
      if (c.country != null) b.write(' tvg-country="${c.country}"');
      if (c.language != null) b.write(' tvg-language="${c.language}"');
      if (c.category != null) b.write(' group-title="${_attr(c.category!)}"');
      b.write(',${c.name}\n');
      if (s.userAgent != null) b.write('#EXTVLCOPT:http-user-agent=${s.userAgent}\n');
      if (s.referrer != null) b.write('#EXTVLCOPT:http-referrer=${s.referrer}\n');
      b.write('${s.url}\n');
    }
  }
  return b.toString();
}

String _csvCell(Object? v) {
  final s = v?.toString() ?? '';
  return s.contains(RegExp('[",\n\r]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

String toCsv(List<ExportChannel> list, ExportOptions o) {
  final b = StringBuffer('number,name,tvg-id,country,category,language,logo,url,user_agent,referrer\n');
  for (final c in list) {
    for (final s in exportStreams(c, o)) {
      b.writeln([c.number, c.name, c.epgId ?? c.uid, c.country, c.category, c.language, c.logo, s.url, s.userAgent, s.referrer].map(_csvCell).join(','));
    }
  }
  return b.toString();
}

/// صيغة MTC (تقرؤها شاشة الاستيراد أيضًا).
String toJson(List<ExportChannel> list, ExportOptions o) => const JsonEncoder.withIndent('  ').convert([
      for (final c in list)
        if (exportStreams(c, o).isNotEmpty)
          {
            'uid': c.uid,
            'name': c.name,
            'number': ?c.number,
            'logo': ?c.logo,
            'country': ?c.country,
            'category': ?c.category,
            'language': ?c.language,
            'tvg_id': c.epgId ?? c.uid,
            'streams': [
              for (final s in exportStreams(c, o)) {'url': s.url, 'user_agent': ?s.userAgent, 'referrer': ?s.referrer, 'label': ?s.label},
            ],
          },
    ]);

String _xml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

String toXspf(List<ExportChannel> list, ExportOptions o, {String title = 'MTC-iPTv'}) {
  final b = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n<playlist version="1" xmlns="http://xspf.org/ns/0/">\n  <title>${_xml(title)}</title>\n  <trackList>\n');
  for (final c in list) {
    for (final s in exportStreams(c, o)) {
      b.write('    <track><location>${_xml(s.url)}</location><title>${_xml(c.name)}</title>');
      if (c.logo != null) b.write('<image>${_xml(c.logo!)}</image>');
      b.write('</track>\n');
    }
  }
  b.write('  </trackList>\n</playlist>\n');
  return b.toString();
}
