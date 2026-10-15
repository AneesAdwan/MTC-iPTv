// «جرّب الآن» (ADM-B2/D4): معاينة رابط محدد بمشغّل مستقل في حوار (لا يمس مشغّل المشاهدة).
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../app/theme/tokens.dart';
import '../../../data/admin/admin_repository.dart';
import '../../../player/playback_controller.dart' show classifyPlayerError;
import '../../../player/tls_bundle.dart';
import '../widgets/admin_widgets.dart';

Future<void> showStreamPreview(BuildContext context, AdminStream s, String title) =>
    showDialog(context: context, builder: (_) => Dialog(clipBehavior: Clip.antiAlias, child: _Preview(stream: s, title: title)));

class _Preview extends StatefulWidget {
  final AdminStream stream;
  final String title;
  const _Preview({required this.stream, required this.title});
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  late final Player player = Player(configuration: const PlayerConfiguration(title: 'MTC-iPTv preview', logLevel: MPVLogLevel.error));
  late final VideoController video = VideoController(player);
  final sw = Stopwatch();
  String status = '…';
  String? error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final native = player.platform;
    if (native is NativePlayer) {
      final ca = TlsBundle.path;
      if (ca != null) await native.setProperty('tls-ca-file', ca);
      await native.setProperty('tls-verify', ca != null ? 'yes' : 'no');
    }
    player.stream.width.listen((w) {
      if (w != null && w > 0 && mounted && sw.isRunning) {
        sw.stop();
        setState(() => status = '${player.state.height}p · ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s');
      }
    });
    player.stream.error.listen((e) => mounted ? setState(() => error = '${classifyPlayerError(e)} · $e') : null);
    sw.start();
    await player.open(Media(widget.stream.url, httpHeaders: widget.stream.requestHeaders));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 720,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black, child: Video(controller: video, controls: NoVideoControls, fill: Colors.black))),
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(widget.stream.maskedUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12)),
                ),
              ]),
            ),
            if (error != null)
              Flexible(child: Pill(error!.length > 60 ? '${error!.substring(0, 60)}…' : error!, healthColor('unavailable')))
            else
              Pill(status, healthColor(status == '…' ? 'inconclusive' : 'playable')),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ]),
        ),
      ]),
    );
  }
}
