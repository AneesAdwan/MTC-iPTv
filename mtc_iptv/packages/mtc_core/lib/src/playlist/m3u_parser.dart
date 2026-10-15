/// محلّل M3U / M3U8 الموسّع (§10.2).
///
/// يدعم: `#EXTM3U` بسماتها (url-tvg / x-tvg-url)، `#EXTINF` بكل السمات المقتبسة وغير المقتبسة،
/// `#EXTGRP`، `#EXTVLCOPT` (http-user-agent / http-referrer)، `#KODIPROP`، `#EXTHTTP:{json}`،
/// ورابط بلا `#EXTINF` (M3U بسيط). لا يرمي استثناءات على مدخلات معطوبة: يجمعها في [M3uResult.issues].
library;

import 'dart:convert';

import '../normalize.dart';

class M3uEntry {
  final int line; // رقم سطر الرابط في الملف (للتقارير)
  final String rawName;
  final String name; // بعد التنظيف
  final String url;
  final Map<String, String> attrs; // tvg-id, tvg-name, tvg-logo, group-title, ...
  final String? userAgent;
  final String? referrer;
  final Map<String, String> headers; // من #EXTHTTP
  final Map<String, String> kodiProps;
  final double? duration;

  M3uEntry({
    required this.line,
    required this.rawName,
    required this.name,
    required this.url,
    required this.attrs,
    this.userAgent,
    this.referrer,
    this.headers = const {},
    this.kodiProps = const {},
    this.duration,
  });

  String? get tvgId => _nz(attrs['tvg-id']);
  String? get logo => _nz(attrs['tvg-logo']);
  String? get group => _nz(attrs['group-title']);
  String? get country => _nz(attrs['tvg-country']);
  String? get language => _nz(attrs['tvg-language']);
  int? get chno => int.tryParse(attrs['tvg-chno'] ?? '');
  String? get quality => qualityFromName(rawName);
  bool get hasCredentials => detectCredentials(url);
  String get protocol => protocolOf(url);

  static String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

class M3uIssue {
  final int line;
  final String kind; // invalid_url | orphan_extinf | bad_exthttp | not_m3u
  final String detail;
  M3uIssue(this.line, this.kind, this.detail);
  @override
  String toString() => '$line:$kind:$detail';
}

class M3uResult {
  final Map<String, String> header;
  final List<M3uEntry> entries;
  final List<M3uIssue> issues;
  final bool hasExtM3u;
  M3uResult(this.header, this.entries, this.issues, this.hasExtM3u);
  String? get epgUrl => header['url-tvg'] ?? header['x-tvg-url'];
}

// key="value" أو key=value (حتى الفراغ)
final _attr = RegExp(r'''([A-Za-z0-9_\-]+)=(?:"([^"]*)"|'([^']*)'|([^\s,]*))''');
final _urlOk = RegExp(r'^(https?|rtmps?|rtsp|rtp|udp|srt|mms)://\S+$', caseSensitive: false);

M3uResult parseM3u(String text) {
  final header = <String, String>{};
  final entries = <M3uEntry>[];
  final issues = <M3uIssue>[];
  var hasExt = false;

  String? pendName;
  Map<String, String>? pendAttrs;
  double? pendDur;
  int pendLine = 0;
  String? ua, ref, grp;
  var http = <String, String>{};
  var kodi = <String, String>{};

  void reset() {
    pendName = null;
    pendAttrs = null;
    pendDur = null;
    ua = ref = grp = null;
    http = {};
    kodi = {};
  }

  final lines = const LineSplitter().convert(text.startsWith('﻿') ? text.substring(1) : text);
  for (var i = 0; i < lines.length; i++) {
    final ln = i + 1;
    final l = lines[i].trim();
    if (l.isEmpty) continue;

    if (l.startsWith('#EXTM3U')) {
      hasExt = true;
      for (final m in _attr.allMatches(l.substring(7))) {
        header[m.group(1)!.toLowerCase()] = m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
      }
    } else if (l.startsWith('#EXTINF:')) {
      if (pendName != null) issues.add(M3uIssue(pendLine, 'orphan_extinf', pendName!));
      final body = l.substring(8);
      final comma = _lastUnquotedComma(body);
      final meta = comma >= 0 ? body.substring(0, comma) : body;
      pendName = comma >= 0 ? body.substring(comma + 1).trim() : '';
      pendLine = ln;
      final sp = meta.indexOf(' ');
      pendDur = double.tryParse(sp >= 0 ? meta.substring(0, sp) : meta);
      pendAttrs = {
        for (final m in _attr.allMatches(sp >= 0 ? meta.substring(sp) : ''))
          m.group(1)!.toLowerCase(): (m.group(2) ?? m.group(3) ?? m.group(4) ?? '').trim()
      };
      ua = pendAttrs!['user-agent'] ?? ua;
      ref = pendAttrs!['referrer'] ?? pendAttrs!['http-referrer'] ?? ref;
    } else if (l.startsWith('#EXTGRP:')) {
      grp = l.substring(8).trim();
    } else if (l.startsWith('#EXTVLCOPT:')) {
      final kv = l.substring(11);
      final eq = kv.indexOf('=');
      if (eq > 0) {
        final k = kv.substring(0, eq).trim().toLowerCase(), v = kv.substring(eq + 1).trim();
        if (k == 'http-user-agent') ua = v;
        if (k == 'http-referrer' || k == 'http-referer') ref = v;
      }
    } else if (l.startsWith('#KODIPROP:')) {
      final kv = l.substring(10);
      final eq = kv.indexOf('=');
      if (eq > 0) kodi[kv.substring(0, eq).trim()] = kv.substring(eq + 1).trim();
    } else if (l.startsWith('#EXTHTTP:')) {
      try {
        final m = jsonDecode(l.substring(9)) as Map<String, dynamic>;
        m.forEach((k, v) => http[k] = '$v');
        ua = http['User-Agent'] ?? http['user-agent'] ?? ua;
        ref = http['Referer'] ?? http['referer'] ?? ref;
      } catch (_) {
        issues.add(M3uIssue(ln, 'bad_exthttp', l));
      }
    } else if (l.startsWith('#')) {
      continue; // تعليقات أو وسوم غير مدعومة
    } else {
      // سطر رابط. بعض القوائم تلصق "|User-Agent=..." بعد الرابط (أسلوب Kodi)
      var url = l;
      final pipe = url.indexOf('|');
      if (pipe > 0) {
        for (final kv in url.substring(pipe + 1).split('&')) {
          final eq = kv.indexOf('=');
          if (eq <= 0) continue;
          final k = kv.substring(0, eq).toLowerCase(), v = Uri.decodeComponent(kv.substring(eq + 1));
          if (k == 'user-agent') ua = v;
          if (k == 'referer' || k == 'referrer') ref = v;
        }
        url = url.substring(0, pipe);
      }
      if (!_urlOk.hasMatch(url)) {
        issues.add(M3uIssue(ln, 'invalid_url', l.length > 120 ? '${l.substring(0, 120)}…' : l));
        reset();
        continue;
      }
      final attrs = {...?pendAttrs};
      if (grp != null && (attrs['group-title'] ?? '').isEmpty) attrs['group-title'] = grp!;
      final raw = (pendName?.isNotEmpty ?? false) ? pendName! : (attrs['tvg-name'] ?? _nameFromUrl(url));
      entries.add(M3uEntry(
        line: ln,
        rawName: raw,
        name: cleanDisplayName(raw),
        url: url,
        attrs: attrs,
        userAgent: ua,
        referrer: ref,
        headers: http,
        kodiProps: kodi,
        duration: pendDur,
      ));
      reset();
    }
  }
  if (!hasExt && entries.isEmpty) issues.add(M3uIssue(0, 'not_m3u', 'no #EXTM3U and no URLs'));
  return M3uResult(header, entries, issues, hasExt);
}

/// آخر فاصلة خارج علامات التنصيص — الاسم بعدها (الأسماء قد تحتوي فواصل داخل السمات).
int _lastUnquotedComma(String s) {
  var inQ = false, last = -1;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x22) inQ = !inQ;
    if (c == 0x2C && !inQ) {
      last = i;
      break; // أول فاصلة خارج التنصيص تفصل السمات عن الاسم
    }
  }
  return last;
}

String _nameFromUrl(String url) {
  final u = Uri.tryParse(url);
  final seg = u?.pathSegments.where((s) => s.isNotEmpty).toList() ?? [];
  return seg.isEmpty ? (u?.host ?? url) : seg.last.replaceAll(RegExp(r'\.(m3u8?|ts|mpd)$'), '');
}

// /live/USER/PASS/123.ts  أو  ?username=..&password=..  أو  user:pass@host
final _xtream = RegExp(r'/(live|movie|series)/[^/]+/[^/]+/\d+(\.\w+)?$', caseSensitive: false);
final _qcred = RegExp(r'[?&](username|user|password|pass|token)=', caseSensitive: false);

bool detectCredentials(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return false;
  return u.userInfo.isNotEmpty || _xtream.hasMatch(u.path) || _qcred.hasMatch(url);
}

/// يُخفي بيانات الاعتماد للعرض والسجلات (§19.4).
String maskCredentials(String url) {
  var u = url.replaceFirstMapped(RegExp(r'(/(?:live|movie|series)/)[^/]+/[^/]+/', caseSensitive: false), (m) => '${m[1]}••••/••••/');
  u = u.replaceAllMapped(RegExp(r'([?&](?:username|user|password|pass|token)=)[^&]*', caseSensitive: false), (m) => '${m[1]}••••');
  u = u.replaceFirstMapped(RegExp(r'^([a-z]+://)[^@/]+@', caseSensitive: false), (m) => '${m[1]}••••@');
  return u;
}

String protocolOf(String url) {
  final l = url.toLowerCase();
  if (l.startsWith('rtmp')) return 'rtmp';
  if (l.startsWith('rtsp')) return 'rtsp';
  if (l.startsWith('udp') || l.startsWith('rtp')) return 'udp';
  final path = (Uri.tryParse(l)?.path ?? l);
  if (path.endsWith('.m3u8') || path.endsWith('.m3u')) return 'hls';
  if (path.endsWith('.mpd')) return 'dash';
  if (path.endsWith('.ts')) return 'ts';
  if (path.endsWith('.mp4')) return 'mp4';
  if (path.endsWith('.flv')) return 'flv';
  return 'http';
}
