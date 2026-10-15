import 'dart:convert';
import 'dart:typed_data';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

LogoProbe fake(int code, List<int> body, {String? type}) => LogoProbe(fetch: (u) async => SafeFetchResult(u, code, type, Uint8List.fromList(body)));

void main() {
  test('image signatures', () {
    expect(imageKind(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D])), 'png');
    expect(imageKind(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'jpeg');
    expect(imageKind(Uint8List.fromList(utf8.encode('RIFF\x00\x00\x00\x00WEBPVP8 '))), 'webp');
    expect(imageKind(Uint8List.fromList(utf8.encode('  <svg xmlns="http://www.w3.org/2000/svg"></svg>'))), 'svg');
    expect(imageKind(Uint8List.fromList(utf8.encode('<html><body>404</body></html>'))), isNull);
  });

  test('a 200 HTML error page is not a working logo', () async {
    expect((await fake(200, utf8.encode('<html>not found</html>'), type: 'text/html').check('https://x/l.png')).$1, isFalse);
  });

  test('HTTP errors are broken; images are ok', () async {
    expect(await fake(404, const []).check('https://x/l.png'), (false, 'HTTP 404'));
    expect(await fake(200, [0x89, 0x50, 0x4E, 0x47, 0, 0]).check('https://x/l.png'), (true, 'png'));
  });

  test('security-policy refusals are not judged as broken', () async {
    final p = LogoProbe(fetch: (_) async => throw SafeFetchException('blocked_address', 'x'));
    expect((await p.check('http://10.0.0.1/l.png')).$1, isNull);
    final dns = LogoProbe(fetch: (_) async => throw SafeFetchException('dns', 'x'));
    expect((await dns.check('https://gone.invalid/l.png')).$1, isFalse);
  });
}
