// موصل iptv-org (§13، ADM-C4): بيانات القنوات والروابط والشعارات من iptv-org/api.
// العقد (§13.1): معرّف وإصدار وإصدار شكل البيانات، فحص صحة، جلب، وتحليل Dart نقي قابل للاختبار دون شبكة.
// الإيقاف التلقائي: إن فشل تحليل > 30% من السجلات (تغيّر شكل البيانات) يُرمى خطأ ولا يُستورد شيء.
// التوثيق: docs/connectors/iptv-org.md
import 'dart:convert';

import '../net/safe_fetch.dart';

class IptvOrgStream {
  final String url;
  final String? title, quality, userAgent, referrer;
  const IptvOrgStream(this.url, {this.title, this.quality, this.userAgent, this.referrer});
}

class IptvOrgChannel {
  final String id, name;
  final List<String> altNames, categories;
  final String? network, country, website, logo;
  final bool nsfw, closed;
  final List<IptvOrgStream> streams;
  const IptvOrgChannel({
    required this.id,
    required this.name,
    this.altNames = const [],
    this.categories = const [],
    this.network,
    this.country,
    this.website,
    this.logo,
    this.nsfw = false,
    this.closed = false,
    this.streams = const [],
  });
}

class ConnectorShapeChanged implements Exception {
  final String detail;
  const ConnectorShapeChanged(this.detail);
  @override
  String toString() => 'ConnectorShapeChanged: $detail';
}

class IptvOrgConnector {
  static const id = 'iptv-org';
  static const version = '1.0.0';
  static const schemaVersion = 1; // channels/streams/logos كما في iptv-org/api منذ 2025 (الشعار في logos.json)
  static const base = 'https://iptv-org.github.io/api';
  static const maxFailRatio = 0.30;

  final Future<SafeFetchResult> Function(Uri) _get;
  IptvOrgConnector({Future<SafeFetchResult> Function(Uri)? get})
      : _get = get ??
            ((u) => SafeFetcher(policy: const SafeFetchPolicy(maxBytes: 80 * 1024 * 1024, timeout: Duration(seconds: 120)))
                .get(u, headers: const {'User-Agent': 'MTC-iPTv-Connector/$version'}));

  Future<bool> healthCheck() async {
    try {
      return (await _get(Uri.parse('$base/categories.json'))).statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// يجلب الملفات الثلاثة (النص الخام) — التحليل منفصل في [parse].
  Future<({String channels, String streams, String logos})> fetch() async {
    Future<String> one(String f) async {
      final r = await _get(Uri.parse('$base/$f'));
      if (r.statusCode != 200) throw StateError('$f: HTTP ${r.statusCode}');
      return utf8.decode(r.body, allowMalformed: true);
    }

    final res = await Future.wait([one('channels.json'), one('streams.json'), one('logos.json')]);
    return (channels: res[0], streams: res[1], logos: res[2]);
  }

  /// يستبعد قنوات الكبار والمغلقة؛ يربط الروابط والشعارات بالقناة.
  static List<IptvOrgChannel> parse(String channelsJson, String streamsJson, String logosJson) {
    final chans = jsonDecode(channelsJson), streams = jsonDecode(streamsJson), logos = jsonDecode(logosJson);
    if (chans is! List || streams is! List || logos is! List) throw const ConnectorShapeChanged('top level is not a list');
    var bad = 0;
    final logoBy = <String, String>{};
    for (final l in logos) {
      if (l is Map && l['channel'] is String && l['url'] is String && l['feed'] == null) logoBy.putIfAbsent(l['channel'] as String, () => l['url'] as String);
    }
    for (final l in logos) {
      if (l is Map && l['channel'] is String && l['url'] is String) logoBy.putIfAbsent(l['channel'] as String, () => l['url'] as String);
    }
    final streamsBy = <String, List<IptvOrgStream>>{};
    for (final s in streams) {
      if (s is! Map || s['url'] is! String) {
        bad++;
        continue;
      }
      final ch = s['channel'];
      if (ch is! String) continue; // روابط بلا قناة معروفة: لا تُربط
      (streamsBy[ch] ??= []).add(IptvOrgStream(s['url'] as String,
          title: s['title'] as String?, quality: s['quality'] as String?, userAgent: s['user_agent'] as String?, referrer: s['referrer'] as String?));
    }
    final out = <IptvOrgChannel>[];
    for (final c in chans) {
      if (c is! Map || c['id'] is! String || c['name'] is! String) {
        bad++;
        continue;
      }
      out.add(IptvOrgChannel(
        id: c['id'] as String,
        name: c['name'] as String,
        altNames: [for (final x in (c['alt_names'] as List?) ?? const []) '$x'],
        categories: [for (final x in (c['categories'] as List?) ?? const []) '$x'],
        network: c['network'] as String?,
        country: c['country'] as String?,
        website: c['website'] as String?,
        logo: logoBy[c['id']],
        nsfw: c['is_nsfw'] == true,
        closed: c['closed'] != null,
        streams: streamsBy[c['id']] ?? const [],
      ));
    }
    final total = chans.length + streams.length;
    if (total > 0 && bad / total > maxFailRatio) throw ConnectorShapeChanged('$bad of $total records unreadable');
    return [for (final c in out) if (!c.nsfw && !c.closed) c];
  }

  /// M3U للقنوات المختارة (يمرّ بعدها بنفس خط الاستيراد والمراجعة).
  static String toM3u(Iterable<IptvOrgChannel> list) {
    final b = StringBuffer('#EXTM3U\n');
    String a(String? v) => (v ?? '').replaceAll('"', "'");
    for (final c in list) {
      for (final s in c.streams) {
        b.write('#EXTINF:-1 tvg-id="${a(c.id)}" tvg-logo="${a(c.logo)}" tvg-country="${a(c.country)}" group-title="${a(c.categories.isEmpty ? null : c.categories.first)}",${c.name}${s.quality == null ? '' : ' (${s.quality})'}\n');
        if (s.userAgent != null) b.write('#EXTVLCOPT:http-user-agent=${s.userAgent}\n');
        if (s.referrer != null) b.write('#EXTVLCOPT:http-referrer=${s.referrer}\n');
        b.write('${s.url}\n');
      }
    }
    return b.toString();
  }
}
