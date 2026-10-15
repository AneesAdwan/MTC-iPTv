// الطبقة 2 على روابط حقيقية بـ libmpv المرفق (بعد flutter build windows). يدوي:
//   flutter test test/integration/play_probe_live_test.dart --tags local
@Tags(['local'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mtc_iptv/player/play_probe.dart';
import 'package:mtc_iptv/player/tls_bundle.dart';

void main() {
  const dll = 'build/windows/x64/runner/Release/libmpv-2.dll';
  final skip = File(dll).existsSync() ? null : 'run flutter build windows first';

  test('real streams: playable vs failing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized(libmpv: File(dll).absolute.path);
    TlsBundle.path = File('assets/tls/cacert.pem').absolute.path;
    final p = PlayProbe();
    final ok = await p.check('https://live-hls-apps-aja-fa.getaj.net/AJA/01.m3u8');
    // ignore: avoid_print
    print('AJA: ${ok.state} ${ok.reason}');
    expect(ok.state, anyOf('playable', 'degraded'));
    expect(ok.height, greaterThan(0));
    final bad = await p.check('https://example.com/does-not-exist.m3u8');
    // ignore: avoid_print
    print('404: ${bad.state} ${bad.reason}');
    expect(bad.state, isNot(anyOf('playable', 'degraded')));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
