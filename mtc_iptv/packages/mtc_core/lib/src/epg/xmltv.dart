// XMLTV (ADM-E1، §10.2): قراءة القنوات والبرامج — نفس منطق supabase/epg_sync.mjs منقولًا إلى Dart نقي
// (يعمل في Isolate). المطابقة: معرّف EPG أو uid دون «@…»، ثم الاسم المطبّع (§9.7: بالمعرّف لا بالاسم وحده
// في ADM-E2؛ هنا الاسم احتياطي كما في السكربت الحالي).
import '../normalize.dart';

class XmltvProgramme {
  final String channel;
  final DateTime start, end;
  final String title;
  final String? description, category, icon;
  const XmltvProgramme(this.channel, this.start, this.end, this.title, {this.description, this.category, this.icon});
}

class XmltvData {
  final Map<String, List<String>> channelNames; // معرّف القناة في الملف ← أسماؤها
  final Map<String, List<XmltvProgramme>> byChannel;
  const XmltvData(this.channelNames, this.byChannel);
  int get programmes => byChannel.values.fold(0, (a, l) => a + l.length);
}

String _unesc(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&')
    .trim();

/// وقت XMLTV: «20261013180000 +0300» ← UTC.
DateTime? parseXmltvTime(String s) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?(?:\s*([+-])(\d{2})(\d{2}))?').firstMatch(s.trim());
  if (m == null) return null;
  final utc = DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6] ?? '0'));
  if (m[7] == null) return utc;
  final off = Duration(hours: int.parse(m[8]!), minutes: int.parse(m[9]!));
  return m[7] == '+' ? utc.subtract(off) : utc.add(off);
}

/// [from]/[to]: نافذة البرامج المطلوبة (لا داعي لحمل أسابيع في الذاكرة).
XmltvData parseXmltv(String xml, {DateTime? from, DateTime? to, bool channelsOnly = false}) {
  final names = <String, List<String>>{};
  for (final m in RegExp(r'<channel\s+id="([^"]+)"[^>]*>([\s\S]*?)</channel>').allMatches(xml)) {
    final id = _unesc(m[1]!);
    names[id] = [for (final d in RegExp(r'<display-name[^>]*>([\s\S]*?)</display-name>').allMatches(m[2]!)) _unesc(d[1]!)];
  }
  final by = <String, List<XmltvProgramme>>{};
  if (!channelsOnly) {
    for (final m in RegExp(r'<programme\s+([^>]*?)>([\s\S]*?)</programme>').allMatches(xml)) {
      final attrs = m[1]!, body = m[2]!;
      final ch = RegExp(r'channel="([^"]+)"').firstMatch(attrs)?[1];
      final s = parseXmltvTime(RegExp(r'start="([^"]+)"').firstMatch(attrs)?[1] ?? '');
      final e = parseXmltvTime(RegExp(r'stop="([^"]+)"').firstMatch(attrs)?[1] ?? '');
      if (ch == null || s == null || e == null || !e.isAfter(s)) continue;
      if (from != null && !e.isAfter(from)) continue;
      if (to != null && !s.isBefore(to)) continue;
      final title = _unesc(RegExp(r'<title[^>]*>([\s\S]*?)</title>').firstMatch(body)?[1] ?? '');
      if (title.isEmpty) continue;
      final desc = RegExp(r'<desc[^>]*>([\s\S]*?)</desc>').firstMatch(body)?[1];
      final cat = RegExp(r'<category[^>]*>([\s\S]*?)</category>').firstMatch(body)?[1];
      (by[_unesc(ch)] ??= []).add(XmltvProgramme(_unesc(ch), s, e, title,
          description: desc == null ? null : _unesc(desc), category: cat == null ? null : _unesc(cat), icon: RegExp(r'<icon[^>]*src="([^"]+)"').firstMatch(body)?[1]));
    }
  }
  return XmltvData(names, by);
}

/// قناة عندنا للمطابقة مع الدليل.
class EpgTarget {
  final String uid; // المفتاح الذي تُخزَّن به البرامج (channels.uid)
  final String? epgId;
  final List<String> names;
  const EpgTarget(this.uid, this.epgId, this.names);
}

/// معرّف الملف لكل قناة عندنا: epg_id أو uid دون «@…»، ثم الاسم المطبّع. [byNameFallback] كما في السكربت الحالي.
Map<String, String> matchEpgChannels(XmltvData data, List<EpgTarget> targets, {bool byNameFallback = true}) {
  final lowerIds = {for (final id in data.channelNames.keys) id.toLowerCase(): id};
  final byName = <String, String>{};
  if (byNameFallback) {
    for (final e in data.channelNames.entries) {
      for (final n in e.value) {
        final k = matchKey(n);
        if (k.isNotEmpty) byName.putIfAbsent(k, () => e.key);
      }
    }
  }
  final out = <String, String>{};
  for (final t in targets) {
    final key = (t.epgId ?? t.uid).split('@').first.toLowerCase();
    var id = lowerIds[key] ?? lowerIds[t.uid.toLowerCase()];
    if (id == null && byNameFallback) {
      for (final n in t.names) {
        final hit = byName[matchKey(n)];
        if (hit != null) {
          id = hit;
          break;
        }
      }
    }
    if (id != null && (data.byChannel[id]?.isNotEmpty ?? data.channelNames.containsKey(id))) out[t.uid] = id;
  }
  return out;
}

/// فحص جدول قناة (ADM-E3): الفجوات والتداخلات.
class ScheduleIssue {
  final String kind; // gap | overlap
  final DateTime at;
  final Duration length;
  const ScheduleIssue(this.kind, this.at, this.length);
}

List<ScheduleIssue> scheduleIssues(List<(DateTime, DateTime)> items, {Duration minGap = const Duration(minutes: 5)}) {
  final s = [...items]..sort((a, b) => a.$1.compareTo(b.$1));
  final out = <ScheduleIssue>[];
  for (var i = 1; i < s.length; i++) {
    final prevEnd = s[i - 1].$2, start = s[i].$1;
    if (start.isAfter(prevEnd.add(minGap))) out.add(ScheduleIssue('gap', prevEnd, start.difference(prevEnd)));
    if (start.isBefore(prevEnd)) out.add(ScheduleIssue('overlap', start, prevEnd.difference(start)));
  }
  return out;
}
