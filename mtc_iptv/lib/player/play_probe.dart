// فحص التشغيل (§12.1 الطبقة 2): فتح الرابط في mpv دون صورة ولا صوت حتى أول إطار فعلي.
// «قابل للتشغيل» = وصل إطار فيديو (أو صوت لقنوات الراديو) واستمر عيّنةً قصيرة دون خطأ.
import 'dart:async';

import 'package:media_kit/media_kit.dart';

import 'playback_controller.dart' show classifyPlayerError;
import 'tls_bundle.dart';

class PlayResult {
  final String state; // playable | degraded | unsupported | network_error | auth_failed | unavailable | inconclusive
  final String reason;
  final int? firstFrameMs;
  final int? width, height;
  const PlayResult(this.state, this.reason, {this.firstFrameMs, this.width, this.height});
}

class PlayProbe {
  static const firstFrameTimeout = Duration(seconds: 15); // §12.3
  static const sample = Duration(seconds: 3); // عيّنة بعد أول إطار (أقصر من 8 ث للفحص الجماعي)
  static const degradedAfterMs = 5000; // §12.2: زمن بدء > 5 ث = متدهور

  Future<PlayResult> check(String url, {Map<String, String> headers = const {}}) async {
    final p = Player(configuration: const PlayerConfiguration(title: 'MTC-iPTv probe', logLevel: MPVLogLevel.error));
    final native = p.platform;
    if (native is NativePlayer) {
      await native.setProperty('ao', 'null');
      await native.setProperty('vo', 'null');
      // media_kit يضبط vid=no ما لم يُربط VideoController؛ نحتاج فك ترميز الفيديو لإثبات وصول إطار
      await native.setProperty('vid', 'auto');
      await native.setProperty('network-timeout', '10');
      final ca = TlsBundle.path;
      if (ca != null) await native.setProperty('tls-ca-file', ca);
      await native.setProperty('tls-verify', ca != null ? 'yes' : 'no');
    }
    await p.setVolume(0);
    final done = Completer<PlayResult>();
    final sw = Stopwatch();
    final subs = <StreamSubscription>[];
    Timer? timer;

    void finish(PlayResult r) {
      if (!done.isCompleted) done.complete(r);
    }

    void onFrame() {
      if (sw.isRunning == false || timer == null) return;
      timer?.cancel();
      final ms = sw.elapsedMilliseconds;
      timer = null;
      // عيّنة قصيرة: يجب ألا يقع خطأ بعد أول إطار
      Future.delayed(sample, () {
        final w = p.state.width, h = p.state.height;
        finish(ms > degradedAfterMs
            ? PlayResult('degraded', 'first frame ${(ms / 1000).toStringAsFixed(1)}s', firstFrameMs: ms, width: w, height: h)
            : PlayResult('playable', '${h ?? '?'}p · first frame ${(ms / 1000).toStringAsFixed(1)}s', firstFrameMs: ms, width: w, height: h));
      });
    }

    subs
      ..add(p.stream.width.listen((w) {
        if (w != null && w > 0) onFrame();
      }))
      ..add(p.stream.audioParams.listen((a) {
        // قنوات صوتية: لا إطار فيديو؛ بدء الصوت مع عدم وجود مسار فيديو يكفي
        if (a.sampleRate != null && p.state.tracks.video.where((v) => v.id != 'auto' && v.id != 'no').isEmpty) {
          Future.delayed(const Duration(seconds: 2), () {
            if ((p.state.width ?? 0) == 0 && p.state.playing) onFrame();
          });
        }
      }))
      ..add(p.stream.error.listen((e) {
        final code = classifyPlayerError(e);
        finish(PlayResult(code == 'inconclusive' ? 'inconclusive' : code, e.length > 200 ? e.substring(0, 200) : e));
      }));

    timer = Timer(firstFrameTimeout, () => finish(const PlayResult('inconclusive', 'no frame within 15s')));
    sw.start();
    try {
      await p.open(Media(url, httpHeaders: headers));
      return await done.future;
    } finally {
      timer?.cancel();
      for (final s in subs) {
        await s.cancel();
      }
      await p.dispose();
    }
  }
}
