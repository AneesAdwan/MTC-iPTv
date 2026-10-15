// فحص الوصول (§12.1 الطبقة 1): الاتصال، HTTP، صلاحية القائمة، وأول مقطع.
// «الرابط يعمل» هنا يعني قابلًا للوصول فقط (reachable)؛ التشغيل الفعلي يُثبت بالطبقة 2 (mpv).
// عند الشك: inconclusive (§12.2) — لا «يعمل» ولا «معطّل».
import 'dart:convert';
import 'dart:io';

import 'safe_fetch.dart';

/// نتيجة فحص بحالة من حالات §12.2 مع سبب مختصر.
class ProbeResult {
  final String state; // reachable | auth_failed | unavailable | network_error | inconclusive | unsupported
  final String reason;
  final int? httpStatus;
  final int ms;
  const ProbeResult(this.state, this.reason, {this.httpStatus, this.ms = 0});
  bool get ok => state == 'reachable';
  @override
  String toString() => 'ProbeResult($state, $reason, http=$httpStatus, ${ms}ms)';
}

typedef ProbeFetch = Future<SafeFetchResult> Function(Uri uri, Map<String, String> headers, int maxBytes);

class StreamProbe {
  static const playlistBytes = 512 * 1024;
  static const segmentBytes = 256 * 1024;
  static const userAgent = 'MTC-iPTv-HealthCheck/3 (+https://github.com/AneesAdwan/MTC-iPTv)';

  final ProbeFetch fetch;
  StreamProbe({ProbeFetch? fetch}) : fetch = fetch ?? _defaultFetch;

  static Future<SafeFetchResult> _defaultFetch(Uri uri, Map<String, String> headers, int maxBytes) => SafeFetcher(
        policy: SafeFetchPolicy(anyPort: true, truncate: true, maxBytes: maxBytes, timeout: const Duration(seconds: 10)),
      ).get(uri, headers: headers);

  /// [hasCredentials]: الرابط فيه اسم مستخدم/كلمة مرور (يحدد معنى 401/403).
  Future<ProbeResult> check(String url, {Map<String, String> headers = const {}, bool hasCredentials = false}) async {
    final sw = Stopwatch()..start();
    final h = {'User-Agent': userAgent, ...headers};
    try {
      final uri = Uri.parse(url);
      final first = await fetch(uri, h, playlistBytes);
      final bad = _httpState(first.statusCode, hasCredentials);
      if (bad != null) return ProbeResult(bad.$1, bad.$2, httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);

      final text = _asText(first);
      if (text == null || !text.trimLeft().startsWith('#EXTM3U')) {
        // ليست HLS (ts/mp4/mpd…): وصول بيانات يكفي للطبقة 1
        if (first.body.isEmpty) return ProbeResult('unavailable', 'empty response', httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);
        return ProbeResult('reachable', 'HTTP ${first.statusCode}${first.contentType == null ? '' : ' ${first.contentType}'}',
            httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);
      }

      // HLS: من القائمة الرئيسية إلى أول نسخة، ثم أول مقطع
      var playlist = text;
      var base = first.finalUri;
      if (playlist.contains('#EXT-X-STREAM-INF')) {
        final variant = _firstUri(playlist, after: '#EXT-X-STREAM-INF');
        if (variant == null) return ProbeResult('unavailable', 'master playlist without variants', httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);
        final v = await fetch(base.resolve(variant), h, playlistBytes);
        final vb = _httpState(v.statusCode, hasCredentials);
        if (vb != null) return ProbeResult(vb.$1, 'variant: ${vb.$2}', httpStatus: v.statusCode, ms: sw.elapsedMilliseconds);
        playlist = _asText(v) ?? '';
        base = v.finalUri;
        if (!playlist.trimLeft().startsWith('#EXTM3U')) return ProbeResult('unavailable', 'variant is not a playlist', httpStatus: v.statusCode, ms: sw.elapsedMilliseconds);
      }
      final seg = _firstUri(playlist, after: '#EXTINF');
      if (seg == null) return ProbeResult('unavailable', 'empty playlist', httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);
      final s = await fetch(base.resolve(seg), h, segmentBytes);
      final sb = _httpState(s.statusCode, hasCredentials);
      if (sb != null) return ProbeResult(sb.$1, 'segment: ${sb.$2}', httpStatus: s.statusCode, ms: sw.elapsedMilliseconds);
      if (s.body.isEmpty) return ProbeResult('unavailable', 'empty segment', httpStatus: s.statusCode, ms: sw.elapsedMilliseconds);
      return ProbeResult('reachable', 'HLS ok', httpStatus: first.statusCode, ms: sw.elapsedMilliseconds);
    } on SafeFetchException catch (e) {
      final state = switch (e.code) {
        'dns' || 'timeout' => 'network_error',
        'blocked_address' || 'scheme' || 'port' => 'inconclusive', // مرفوض بسياسة الأمان، لا حكم على الرابط
        _ => 'inconclusive',
      };
      return ProbeResult(state, e.code == 'dns' ? 'DNS' : e.message, ms: sw.elapsedMilliseconds);
    } on HandshakeException catch (e) {
      return ProbeResult('network_error', 'TLS: ${e.message}', ms: sw.elapsedMilliseconds);
    } on SocketException catch (e) {
      return ProbeResult('network_error', e.osError?.message ?? e.message, ms: sw.elapsedMilliseconds);
    } on FormatException catch (e) {
      return ProbeResult('inconclusive', 'invalid URL: ${e.message}', ms: sw.elapsedMilliseconds);
    } catch (e) {
      return ProbeResult('inconclusive', '$e', ms: sw.elapsedMilliseconds);
    }
  }

  /// null = نجاح HTTP؛ وإلا (الحالة، السبب).
  static (String, String)? _httpState(int code, bool hasCredentials) {
    if (code >= 200 && code < 300) return null;
    if (code == 401 || code == 403) return hasCredentials ? ('auth_failed', 'HTTP $code') : ('inconclusive', 'HTTP $code (possibly geo/token restricted)');
    if (code == 404 || code == 410) return ('unavailable', 'HTTP $code');
    return ('inconclusive', 'HTTP $code'); // 429/5xx…: لا يكفي للحكم من فحص واحد (§12.3)
  }

  static String? _asText(SafeFetchResult r) {
    try {
      return utf8.decode(r.body, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static String? _firstUri(String playlist, {required String after}) {
    final lines = const LineSplitter().convert(playlist);
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith(after)) continue;
      for (var j = i + 1; j < lines.length; j++) {
        final l = lines[j].trim();
        if (l.isEmpty || l.startsWith('#')) continue;
        return l;
      }
    }
    return null;
  }
}
