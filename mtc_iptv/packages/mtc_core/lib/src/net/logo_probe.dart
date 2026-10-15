// فحص الشعارات (§12.7): HTTP + هل هي صورة فعلًا (توقيع الملف، لا نوع المحتوى وحده).
import 'dart:convert';
import 'dart:typed_data';

import 'safe_fetch.dart';

/// نوع الصورة من أول بايتات الملف، أو null إن لم تكن صورة معروفة.
String? imageKind(Uint8List b) {
  bool at(int o, List<int> sig) => b.length >= o + sig.length && [for (var i = 0; i < sig.length; i++) b[o + i] == sig[i]].every((x) => x);
  if (at(0, [0x89, 0x50, 0x4E, 0x47])) return 'png';
  if (at(0, [0xFF, 0xD8, 0xFF])) return 'jpeg';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return 'gif';
  if (at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50])) return 'webp';
  if (at(0, [0x00, 0x00, 0x01, 0x00])) return 'ico';
  if (at(4, [0x66, 0x74, 0x79, 0x70]) && (at(8, [0x61, 0x76, 0x69, 0x66]) || at(8, [0x61, 0x76, 0x69, 0x73]))) return 'avif';
  final head = utf8.decode(b.length > 512 ? b.sublist(0, 512) : b, allowMalformed: true).trimLeft().toLowerCase();
  if (head.startsWith('<svg') || (head.startsWith('<?xml') && head.contains('<svg'))) return 'svg';
  return null;
}

class LogoProbe {
  final Future<SafeFetchResult> Function(Uri uri) fetch;
  LogoProbe({Future<SafeFetchResult> Function(Uri uri)? fetch})
      : fetch = fetch ??
            ((u) => SafeFetcher(policy: const SafeFetchPolicy(anyPort: true, truncate: true, maxBytes: 64 * 1024, timeout: Duration(seconds: 10)))
                .get(u, headers: const {'User-Agent': 'MTC-iPTv-LogoCheck/3'}));

  /// (صالح؟، السبب). null = لا حكم (لا يُسجَّل شيء).
  Future<(bool?, String)> check(String url) async {
    try {
      final r = await fetch(Uri.parse(url));
      if (r.statusCode < 200 || r.statusCode >= 300) return (false, 'HTTP ${r.statusCode}');
      final kind = imageKind(r.body);
      return kind == null ? (false, 'not an image (${r.contentType ?? '?'})') : (true, kind);
    } on SafeFetchException catch (e) {
      // عنوان داخلي أو مخطط مرفوض: سياسة الأمان وحدها لا تكفي للحكم على الشعار
      if (e.code == 'blocked_address' || e.code == 'scheme' || e.code == 'port') return (null, e.code);
      return (false, e.code);
    } catch (e) {
      return (false, '$e');
    }
  }
}
