// اختيار جودة HLS مسبقًا (§7.4، تقرير PoC §3.2 و§8.3):
//  • قائمة رئيسية بلا #EXT-X-MEDIA  ← رابط النسخة المختارة مباشرة.
//  • قائمة رئيسية فيها #EXT-X-MEDIA ← «قائمة مصغّرة» (النسخة + كل المسارات البديلة) يخدمها خادم محلي،
//    حتى لا تضيع لغات الصوت والترجمات (memory:// لا يعمل لذلك).
//  • غير ذلك ← الرابط كما هو.
// السبب: demuxer الـ HLS في ffmpeg يفتح ويحلّل كل النسخ قبل البدء (5–24 ث بدل 1–2).
import 'dart:convert';
import 'dart:io';

import '../core/logging/log.dart';

class HlsVariant {
  final int height, bandwidth;
  final Uri uri;
  final String streamInf;
  const HlsVariant(this.height, this.bandwidth, this.uri, this.streamInf);
  String get label => height > 0 ? '${height}p' : '${(bandwidth / 1000).round()}k';
}

class ResolvedSource {
  /// ما يُعطى للمشغّل فعلًا.
  final String playUrl;

  /// النسخ المتاحة (لاختيار الجودة يدويًا)، فارغة إن لم تكن قائمة رئيسية.
  final List<HlsVariant> variants;
  final HlsVariant? selected;
  final bool viaLocalServer;
  const ResolvedSource(this.playUrl, {this.variants = const [], this.selected, this.viaLocalServer = false});
}

/// خادم محلي على 127.0.0.1 لخدمة القوائم المصغّرة فقط (لا يقبل اتصالات من خارج الجهاز).
class LocalPlaylistServer {
  LocalPlaylistServer._();
  static final instance = LocalPlaylistServer._();
  HttpServer? _server;
  final _playlists = <String, String>{};
  var _n = 0;

  Future<Uri> serve(String content) async {
    _server ??= await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((r) async {
        final body = _playlists[r.uri.pathSegments.isEmpty ? '' : r.uri.pathSegments.last];
        if (body == null) {
          r.response.statusCode = HttpStatus.notFound;
        } else {
          r.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
          r.response.write(body);
        }
        await r.response.close();
      });
    final id = 'm${++_n}.m3u8';
    _playlists[id] = content;
    if (_playlists.length > 20) _playlists.remove(_playlists.keys.first); // لا تتراكم في الذاكرة
    return Uri.parse('http://127.0.0.1:${_server!.port}/$id');
  }
}

class HlsResolver {
  final int maxHeight;
  final Duration timeout;
  const HlsResolver({this.maxHeight = 1080, this.timeout = const Duration(seconds: 6)});

  /// [prefer]: ارتفاع مطلوب يدويًا (اختيار الجودة)، وإلا أعلى نسخة ≤ [maxHeight].
  Future<ResolvedSource> resolve(String url, {Map<String, String> headers = const {}, int? prefer}) async {
    if (!url.toLowerCase().split('?').first.endsWith('.m3u8') && !url.toLowerCase().contains('.m3u8?')) {
      return ResolvedSource(url);
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
      headers.forEach(req.headers.set);
      final res = await req.close().timeout(timeout);
      if (res.statusCode >= 400) return ResolvedSource(url); // يترك المشغّل يصنّف الخطأ
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      final base = res.redirects.isEmpty ? Uri.parse(url) : Uri.parse(url).resolveUri(res.redirects.last.location);
      return await _fromPlaylist(url, base, text, prefer);
    } catch (e) {
      log.fine('hls resolve skipped: $e');
      return ResolvedSource(url);
    } finally {
      client.close(force: true);
    }
  }

  Future<ResolvedSource> _fromPlaylist(String original, Uri base, String text, int? prefer) async {
    if (!text.contains('#EXT-X-STREAM-INF')) return ResolvedSource(original);
    final lines = const LineSplitter().convert(text);
    final variants = <HlsVariant>[];
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith('#EXT-X-STREAM-INF')) continue;
      final h = int.tryParse(RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(lines[i])?.group(1) ?? '') ?? 0;
      final bw = int.tryParse(RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i])?.group(1) ?? '') ?? 0;
      final next = lines.skip(i + 1).firstWhere((l) => l.trim().isNotEmpty && !l.startsWith('#'), orElse: () => '');
      if (next.isNotEmpty) variants.add(HlsVariant(h, bw, base.resolve(next.trim()), lines[i]));
    }
    if (variants.isEmpty) return ResolvedSource(original);
    variants.sort((a, b) => a.height != b.height ? b.height.compareTo(a.height) : b.bandwidth.compareTo(a.bandwidth));
    final target = prefer ?? maxHeight;
    final pick = variants.firstWhere((v) => v.height <= target, orElse: () => variants.last);

    final media = lines.where((l) => l.startsWith('#EXT-X-MEDIA')).toList();
    if (media.isEmpty) return ResolvedSource(pick.uri.toString(), variants: variants, selected: pick);

    // قائمة مصغّرة بروابط مطلقة: النسخة المختارة + كل المسارات البديلة
    final absMedia = media.map((l) => l.replaceAllMapped(RegExp(r'URI="([^"]+)"'), (m) => 'URI="${base.resolve(m[1]!)}"'));
    final mini = ['#EXTM3U', '#EXT-X-VERSION:6', ...absMedia, pick.streamInf, pick.uri.toString(), ''].join('\n');
    final served = await LocalPlaylistServer.instance.serve(mini);
    return ResolvedSource(served.toString(), variants: variants, selected: pick, viaLocalServer: true);
  }
}
