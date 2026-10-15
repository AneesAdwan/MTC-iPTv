// إثبات مفهوم المشغّل داخل Flutter (ملحق ج) — نفس العيّنات التي اختُبرت بـ mpv وVLC،
// لكن عبر media_kit فعليًا (libmpv المضمّنة مع الحزمة + VideoController حقيقي).
//
// التشغيل:  tools/player-poc/run_flutter_poc.ps1   (يشغّل الخادم المحلي ثم التطبيق)
// الوسائط:  --samples <path>  --out <path>  --only generated|official|catalog  --play 20  --auto
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

late final Map<String, String> argv;

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  argv = {};
  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      final hasValue = i + 1 < args.length && !args[i + 1].startsWith('--');
      argv[args[i].substring(2)] = hasValue ? args[++i] : 'true';
    }
  }
  runApp(const PocApp());
}

/// يقرأ قائمة HLS الرئيسية ويُرجع رابط أعلى نسخة ≤ [maxHeight]، أو الرابط نفسه إن لم تكن رئيسية.
Future<String> resolveHlsVariant(String url, Map<String, String> headers, {int maxHeight = 1080}) async {
  if (!url.toLowerCase().contains('.m3u8')) return url;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(Uri.parse(url));
    headers.forEach(req.headers.set);
    final res = await req.close().timeout(const Duration(seconds: 8));
    final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
    if (!text.contains('#EXT-X-STREAM-INF')) return url;
    // مسارات بديلة (صوت/ترجمة) معرّفة في القائمة الرئيسية: اختيار نسخة واحدة يُضيّعها،
    // فنمرّر القائمة كما هي (أبطأ لكن كاملة). 18% من القوائم الرئيسية الحقيقية (تقرير PoC).
    if (text.contains('#EXT-X-MEDIA')) return url;
    final base = res.redirects.isNotEmpty ? res.redirects.last.location.isAbsolute ? res.redirects.last.location : Uri.parse(url).resolveUri(res.redirects.last.location) : Uri.parse(url);
    final lines = const LineSplitter().convert(text);
    final variants = <(int, int, String)>[];
    for (var i = 0; i < lines.length; i++) {
      if (!lines[i].startsWith('#EXT-X-STREAM-INF')) continue;
      final h = int.tryParse(RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(lines[i])?.group(1) ?? '') ?? 0;
      final bw = int.tryParse(RegExp(r'BANDWIDTH=(\d+)').firstMatch(lines[i])?.group(1) ?? '') ?? 0;
      final next = lines.skip(i + 1).firstWhere((l) => l.trim().isNotEmpty && !l.startsWith('#'), orElse: () => '');
      if (next.isNotEmpty) variants.add((h, bw, base.resolve(next.trim()).toString()));
    }
    if (variants.isEmpty) return url;
    final ok = variants.where((v) => v.$1 <= maxHeight).toList();
    final pool = ok.isEmpty ? variants : ok;
    pool.sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : b.$2.compareTo(a.$2));
    return pool.first.$3;
  } catch (_) {
    return url;
  } finally {
    client.close(force: true);
  }
}

class PocApp extends StatelessWidget {
  const PocApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const Directionality(textDirection: TextDirection.rtl, child: PocHome()),
      );
}

class Sample {
  final Map<String, dynamic> raw;
  Sample(this.raw);
  String get id => raw['id'];
  String get url => raw['url'];
  String get note => raw['note'] ?? '';
  String get group => raw['group'];
  Map<String, String> get headers => {
        if (raw['ua'] != null) 'User-Agent': raw['ua'],
        if (raw['ref'] != null) 'Referer': raw['ref'],
      };
  double play(double def) => (raw['play'] as num?)?.toDouble() ?? def;
  bool get rtmp => raw['rtmp'] == true;
}

class PocHome extends StatefulWidget {
  const PocHome({super.key});
  @override
  State<PocHome> createState() => _PocHomeState();
}

class _PocHomeState extends State<PocHome> {
  final player = Player(configuration: const PlayerConfiguration(title: 'MTC-iPTv PoC', logLevel: MPVLogLevel.warn));
  late final controller = VideoController(player);
  final results = <Map<String, dynamic>>[];
  final log = <String>[];
  List<Sample> samples = [];
  int index = -1;
  bool running = false;

  String get samplesPath => argv['samples'] ?? r'..\..\docs\poc\data\samples.json';
  String get outPath => argv['out'] ?? r'..\..\docs\poc\data\results-mediakit.json';
  double get playSeconds => double.tryParse(argv['play'] ?? '') ?? 20;
  static const firstFrameTimeout = 15.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = (jsonDecode(await File(samplesPath).readAsString()) as List).cast<Map<String, dynamic>>();
    samples = list.map(Sample.new).where((s) => !s.rtmp && (argv['only'] == null || s.group == argv['only'])).toList();
    setState(() {});
    if (argv['auto'] == 'true') unawaited(_runAll());
  }

  Future<void> _runAll() async {
    setState(() => running = true);
    for (var i = 0; i < samples.length && running; i++) {
      setState(() => index = i);
      final r = await _test(samples[i]);
      results.add(r);
      log.insert(0, '${r['ok'] ? '✓' : '✗'} ${samples[i].id}  ${r['first_frame'] ?? '-'}s  ${samples[i].note}');
      setState(() {});
      await _save();
    }
    setState(() => running = false);
    if (argv['auto'] == 'true') exit(0);
  }

  Future<Map<String, dynamic>> _test(Sample s) async {
    final play = s.play(playSeconds);
    final sw = Stopwatch()..start();
    double? firstFrame, firstPos;
    String? error;
    var maxStall = 0.0;
    var lastPos = Duration.zero;
    var lastAdvance = 0.0;
    var completed = false;
    final subs = <StreamSubscription>[
      player.stream.width.listen((w) {
        if (w != null && w > 0) firstFrame ??= sw.elapsedMilliseconds / 1000;
      }),
      player.stream.error.listen((e) => error ??= e),
      player.stream.completed.listen((c) => completed = completed || c),
      player.stream.position.listen((p) {
        final now = sw.elapsedMilliseconds / 1000;
        if (p > Duration.zero) firstPos ??= now;
        if (p != lastPos) {
          if (firstPos != null && lastAdvance > 0) maxStall = maxStall < now - lastAdvance ? now - lastAdvance : maxStall;
          lastPos = p;
          lastAdvance = now;
        }
      }),
    ];
    // اختيار الجودة مسبقًا (تقرير PoC §3.2): بدونه يحلّل ffmpeg كل نسخ HLS قبل البدء
    final url = argv['no-variant'] == 'true' ? s.url : await resolveHlsVariant(s.url, s.headers);
    await player.open(Media(url, httpHeaders: s.headers));

    // انتظار أول إطار (أو بدء الصوت للقنوات الصوتية)
    while (sw.elapsedMilliseconds / 1000 < firstFrameTimeout && firstFrame == null && firstPos == null && error == null && !completed) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    final start = firstFrame ?? firstPos;
    double played = 0;
    if (start != null && error == null) {
      while (!completed && sw.elapsedMilliseconds / 1000 - start < play) {
        await Future.delayed(const Duration(milliseconds: 250));
        final now = sw.elapsedMilliseconds / 1000;
        if (lastAdvance > 0 && now - lastAdvance > maxStall) maxStall = now - lastAdvance;
      }
      played = sw.elapsedMilliseconds / 1000 - start;
    }
    final tracks = player.state.tracks;
    final vp = player.state.videoParams;
    final ap = player.state.audioParams;
    await player.stop();
    for (final x in subs) {
      await x.cancel();
    }
    final ok = start != null && start <= firstFrameTimeout && played >= play * 0.9 && maxStall <= 5;
    return {
      'id': s.id,
      'group': s.group,
      'url': s.url,
      'ok': ok,
      'first_frame': firstFrame,
      'first_audio': firstPos,
      'played': double.parse(played.toStringAsFixed(2)),
      'max_stall': double.parse(maxStall.toStringAsFixed(2)),
      'error': error,
      'resolution': vp.w != null ? '${vp.w}x${vp.h}' : null,
      'hwdec': vp.hwPixelformat,
      'pixelformat': vp.pixelformat,
      'audio_format': ap.format,
      'audio_tracks': tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').length,
      'sub_tracks': tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').length,
      'video_tracks': tracks.video.where((t) => t.id != 'auto' && t.id != 'no').length,
    };
  }

  Future<void> _save() async {
    final f = File(outPath);
    await f.parent.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent(' ').convert({
      'run_at': DateTime.now().toIso8601String(),
      'engine': 'media_kit',
      'play_seconds': playSeconds,
      'results': results,
    }));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = index >= 0 && index < samples.length ? samples[index] : null;
    final ok = results.where((r) => r['ok'] == true).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('MTC-iPTv — إثبات مفهوم المشغّل  ($ok/${results.length} من ${samples.length})'),
        actions: [
          if (!running)
            FilledButton.icon(onPressed: samples.isEmpty ? null : _runAll, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل الاختبار'))
          else
            OutlinedButton.icon(onPressed: () => setState(() => running = false), icon: const Icon(Icons.stop), label: const Text('إيقاف')),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(children: [
        Expanded(
          flex: 3,
          child: Column(children: [
            Expanded(child: Video(controller: controller)),
            if (cur != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${cur.id} — ${cur.note}\n${cur.url}', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12)),
              ),
          ]),
        ),
        SizedBox(
          width: 420,
          child: ListView(padding: const EdgeInsets.all(8), children: [for (final l in log) Text(l, style: const TextStyle(fontSize: 12))]),
        ),
      ]),
    );
  }
}
