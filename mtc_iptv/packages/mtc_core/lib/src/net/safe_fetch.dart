/// جلب آمن للروابط التي يحددها مستخدم أو مصدر خارجي (§19.3، SSRF).
///
/// يعمل في برنامج المدير (D-13)، فالخطر أن يجعله مصدر خبيث يطلب عناوين **شبكته المحلية**.
/// الضوابط:
///  • http/https فقط، والمنافذ من قائمة سماح.
///  • حلّ DNS مرة، ورفض أي عنوان داخلي/محجوز (IPv4 وIPv6 وIPv4 داخل IPv6)،
///    ثم الاتصال **بنفس العنوان المتحقق منه** (يمنع DNS rebinding)، مع إرسال Host وSNI الأصليين.
///  • تحويلات HTTP يدوية (حدّ أقصى)، وكل خطوة تمرّ بالتحقق كاملًا.
///  • مهلة وحجم أقصى بقراءة متدفقة.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SafeFetchException implements Exception {
  final String code; // scheme | port | blocked_address | dns | redirects | too_large | timeout | http
  final String message;
  SafeFetchException(this.code, this.message);
  @override
  String toString() => 'SafeFetchException($code): $message';
}

class SafeFetchPolicy {
  final Set<int> allowedPorts;

  /// عناوين محلية يسمح بها المدير صراحةً (ADM-G4) — فارغة افتراضيًا.
  final List<InternetAddress> allowedLocal;
  final int maxRedirects;
  final int maxBytes;
  final Duration timeout;

  /// أي منفذ مسموح (فحص الروابط في برنامج المدير: روابط البث تستخدم منافذ كثيرة).
  /// حظر العناوين الداخلية يبقى كما هو.
  final bool anyPort;

  /// عند تجاوز [maxBytes]: أعد ما وصل بدل الخطأ (عيّنة من مقطع للفحص).
  final bool truncate;

  const SafeFetchPolicy({
    this.allowedPorts = const {80, 443, 8080, 8000, 25461},
    this.allowedLocal = const [],
    this.maxRedirects = 3,
    this.maxBytes = 50 * 1024 * 1024,
    this.timeout = const Duration(seconds: 20),
    this.anyPort = false,
    this.truncate = false,
  });
}

class SafeFetchResult {
  final Uri finalUri;
  final int statusCode;
  final String? contentType;
  final Uint8List body;
  SafeFetchResult(this.finalUri, this.statusCode, this.contentType, this.body);
}

typedef Resolver = Future<List<InternetAddress>> Function(String host);

/// يُرجع true إن كان العنوان داخليًا/محجوزًا ويجب رفضه.
bool isBlockedAddress(InternetAddress a) {
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) return _blockedV4(b);
  // IPv6
  if (b.length != 16) return true;
  final allZero = b.every((x) => x == 0);
  if (allZero) return true; // ::
  final loop = b.sublist(0, 15).every((x) => x == 0) && b[15] == 1;
  if (loop) return true; // ::1
  // IPv4-mapped ::ffff:a.b.c.d  و IPv4-compatible ::a.b.c.d
  final first10Zero = b.sublist(0, 10).every((x) => x == 0);
  if (first10Zero && b[10] == 0xff && b[11] == 0xff) return _blockedV4(b.sublist(12));
  if (b.sublist(0, 12).every((x) => x == 0)) return _blockedV4(b.sublist(12));
  if ((b[0] & 0xfe) == 0xfc) return true; // fc00::/7 unique local
  if (b[0] == 0xfe && (b[1] & 0xc0) == 0x80) return true; // fe80::/10 link-local
  if (b[0] == 0xff) return true; // ff00::/8 multicast
  if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) return true; // 2001:db8::/32 documentation
  if (b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xff && b[3] == 0x9b) return _blockedV4(b.sublist(12)); // 64:ff9b::/96 NAT64
  return false;
}

bool _blockedV4(List<int> b) {
  final a = b[0], c = b[1];
  return a == 0 || // 0.0.0.0/8
      a == 10 || // 10/8
      a == 127 || // loopback
      (a == 100 && c >= 64 && c <= 127) || // 100.64/10 CGNAT
      (a == 169 && c == 254) || // link-local + cloud metadata 169.254.169.254
      (a == 172 && c >= 16 && c <= 31) || // 172.16/12
      (a == 192 && c == 168) || // 192.168/16
      (a == 192 && c == 0 && b[2] == 0) || // 192.0.0/24
      (a == 192 && c == 0 && b[2] == 2) || // TEST-NET-1
      (a == 198 && (c == 18 || c == 19)) || // benchmarking
      (a == 198 && c == 51 && b[2] == 100) || // TEST-NET-2
      (a == 203 && c == 0 && b[2] == 113) || // TEST-NET-3
      a >= 224; // multicast 224/4 + reserved 240/4 + broadcast
}

class SafeFetcher {
  final SafeFetchPolicy policy;
  final Resolver resolve;
  SafeFetcher({this.policy = const SafeFetchPolicy(), Resolver? resolver}) : resolve = resolver ?? ((h) => InternetAddress.lookup(h));

  int _port(Uri u) => u.hasPort ? u.port : (u.scheme == 'https' ? 443 : 80);

  bool _allowedLocal(InternetAddress a) => policy.allowedLocal.any((x) => x.address == a.address);

  /// يتحقق من الرابط ويُرجع العنوان المثبّت الذي سيُتصل به.
  Future<InternetAddress> check(Uri u) async {
    if (u.scheme != 'http' && u.scheme != 'https') throw SafeFetchException('scheme', 'scheme ${u.scheme} not allowed');
    if (!policy.anyPort && !policy.allowedPorts.contains(_port(u))) throw SafeFetchException('port', 'port ${_port(u)} not allowed');
    final literal = InternetAddress.tryParse(u.host);
    final List<InternetAddress> addrs;
    try {
      addrs = literal != null ? [literal] : await resolve(u.host).timeout(const Duration(seconds: 5));
    } catch (e) {
      throw SafeFetchException('dns', 'cannot resolve ${u.host}');
    }
    if (addrs.isEmpty) throw SafeFetchException('dns', 'no address for ${u.host}');
    // كل العناوين يجب أن تكون آمنة (لا يكفي أن يكون أحدها عامًا)
    for (final a in addrs) {
      if (isBlockedAddress(a) && !_allowedLocal(a)) throw SafeFetchException('blocked_address', '${u.host} -> internal address');
    }
    return addrs.first;
  }

  Future<SafeFetchResult> get(Uri start, {Map<String, String> headers = const {}}) async {
    final deadline = DateTime.now().add(policy.timeout);
    var uri = start;
    for (var hop = 0; hop <= policy.maxRedirects; hop++) {
      final pinned = await check(uri);
      final client = HttpClient()
        ..autoUncompress = true
        ..connectionTimeout = const Duration(seconds: 8)
        ..findProxy = ((_) => 'DIRECT')
        // نتصل بالعنوان المثبّت نفسه، مع SNI/Host الأصليين (يمنع تبدّل DNS بين التحقق والاتصال)
        ..connectionFactory = (u, _, _) {
          final port = _port(u);
          if (u.scheme == 'https') {
            return Socket.startConnect(pinned, port).then((task) => ConnectionTask.fromSocket(
                  task.socket.then((s) => SecureSocket.secure(s, host: u.host)),
                  task.cancel,
                ));
          }
          return Socket.startConnect(pinned, port);
        };
      try {
        final left = deadline.difference(DateTime.now());
        if (left.isNegative) throw SafeFetchException('timeout', 'timeout');
        final req = await client.getUrl(uri).timeout(left);
        req.followRedirects = false;
        headers.forEach(req.headers.set);
        final res = await req.close().timeout(deadline.difference(DateTime.now()));
        if (res.isRedirect || (res.statusCode >= 300 && res.statusCode < 400 && res.headers.value('location') != null)) {
          await res.drain<void>();
          if (hop == policy.maxRedirects) throw SafeFetchException('redirects', 'too many redirects');
          uri = uri.resolve(res.headers.value('location')!);
          continue;
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in res.timeout(deadline.difference(DateTime.now()))) {
          bytes.add(chunk);
          if (bytes.length > policy.maxBytes) {
            if (policy.truncate) break;
            throw SafeFetchException('too_large', 'response exceeds ${policy.maxBytes} bytes');
          }
        }
        final body = bytes.takeBytes();
        return SafeFetchResult(
            uri, res.statusCode, res.headers.contentType?.mimeType, body.length > policy.maxBytes ? Uint8List.sublistView(body, 0, policy.maxBytes) : body);
      } on TimeoutException {
        throw SafeFetchException('timeout', 'timeout');
      } finally {
        client.close(force: true);
      }
    }
    throw SafeFetchException('redirects', 'too many redirects');
  }
}
