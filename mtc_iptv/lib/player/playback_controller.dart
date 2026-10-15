// المشغّل (ADR-02 media_kit/libmpv، §7): مشغّل واحد للتطبيق + سلسلة السيرفرات والتبديل التلقائي.
//  • الروابط بأولوية المدير ثم الصحة (CatalogRepository.streamsFor).
//  • فشل/لا إطار خلال 15 ث/تجمّد > 6 ث ← الرابط التالي تلقائيًا (§7.4، G3 ≤ 6 ث).
//  • الترويسات لكل رابط (User-Agent/Referer/Headers، §7.3)، و tls-verify=yes (تقرير PoC §6).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/logging/log.dart';
import '../core/settings/local_settings.dart';
import '../core/storage/catalog_db.dart';
import '../data/catalog/catalog_repository.dart';
import 'hls_resolver.dart';
import 'tls_bundle.dart';

enum PlayPhase { idle, loading, playing, switching, failed }

/// رموز §12.2 (لرسائل الخطأ وللقياس لاحقًا).
String classifyPlayerError(String? msg) {
  final m = (msg ?? '').toLowerCase();
  if (m.contains('401') || m.contains('403') || m.contains('forbidden') || m.contains('unauthorized')) return 'auth_failed';
  if (m.contains('404') || m.contains('410') || m.contains('not found')) return 'unavailable';
  if (m.contains('recognize file format') || m.contains('codec') || m.contains('invalid data')) return 'unsupported';
  if (m.contains('resolve') || m.contains('timed out') || m.contains('timeout') || m.contains('refused') || m.contains('tls') || m.contains('ssl')) {
    return 'network_error';
  }
  if (m.contains('5') && m.contains('http error')) return 'unavailable';
  return 'inconclusive';
}

class PlaybackState {
  final ChannelRow? channel;
  final List<StreamRow> streams;
  final int index; // الرابط الحالي
  final PlayPhase phase;
  final String? errorCode;
  final ResolvedSource? source;
  final int? preferHeight; // اختيار الجودة يدويًا (null = تلقائي)
  const PlaybackState({
    this.channel,
    this.streams = const [],
    this.index = 0,
    this.phase = PlayPhase.idle,
    this.errorCode,
    this.source,
    this.preferHeight,
  });

  StreamRow? get stream => index < streams.length ? streams[index] : null;

  PlaybackState copyWith({
    ChannelRow? channel,
    List<StreamRow>? streams,
    int? index,
    PlayPhase? phase,
    String? errorCode,
    bool clearError = false,
    ResolvedSource? source,
    int? preferHeight,
    bool clearPrefer = false,
  }) =>
      PlaybackState(
        channel: channel ?? this.channel,
        streams: streams ?? this.streams,
        index: index ?? this.index,
        phase: phase ?? this.phase,
        errorCode: clearError ? null : (errorCode ?? this.errorCode),
        source: source ?? this.source,
        preferHeight: clearPrefer ? null : (preferHeight ?? this.preferHeight),
      );
}

/// مشغّل واحد للتطبيق كله (يُنشأ عند أول استخدام).
final playerProvider = Provider<Player>((ref) {
  final p = Player(configuration: const PlayerConfiguration(title: 'MTC-iPTv', logLevel: MPVLogLevel.warn));
  final native = p.platform;
  if (native is NativePlayer) {
    // mpv لا يتحقق من TLS افتراضيًا؛ والتحقق يحتاج حزمة شهادات صريحة (انظر tls_bundle.dart)
    final ca = TlsBundle.path;
    if (ca != null) native.setProperty('tls-ca-file', ca);
    native.setProperty('tls-verify', ca != null ? 'yes' : 'no');
    native.setProperty('network-timeout', '15');
  }
  ref.onDispose(p.dispose);
  return p;
});

final videoControllerProvider = Provider<VideoController>((ref) => VideoController(ref.watch(playerProvider)));

final playbackProvider = NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);

class PlaybackController extends Notifier<PlaybackState> {
  static const firstFrameTimeout = Duration(seconds: 15); // تعريف النجاح في G1 و§12 (بعض الخوادم تحتاج ~9 ث)
  static const stallTimeout = Duration(seconds: 6);

  static const maxRounds = 1; // جولات إعادة إضافية بعد فشل كل السيرفرات
  int _rounds = 0;
  final _subs = <StreamSubscription>[];
  Timer? _watchdog;
  int _token = 0; // يُبطل الأحداث القادمة من محاولة سابقة

  Player get _p => ref.read(playerProvider);
  CatalogRepository get _repo => ref.read(catalogRepoProvider);

  @override
  PlaybackState build() {
    ref.onDispose(() {
      _watchdog?.cancel();
      for (final s in _subs) {
        s.cancel();
      }
    });
    return const PlaybackState();
  }

  /// المشغّل (libmpv) يُنشأ عند أول تشغيل فقط، لا عند قراءة الحالة (المشغّل المصغّر يقرأها دائمًا).
  void _listen() {
    if (_subs.isNotEmpty) return;
    final p = _p;
    _subs
      ..add(p.stream.width.listen((w) {
        if (w != null && w > 0) _onFirstFrame();
      }))
      ..add(p.stream.audioParams.listen((a) {
        // قنوات صوتية فقط: لا يوجد إطار فيديو؛ نعتبر بدء الصوت تشغيلًا
        if (a.sampleRate != null && state.phase == PlayPhase.loading && (p.state.width ?? 0) == 0) {
          Future.delayed(const Duration(seconds: 2), () {
            if (state.phase == PlayPhase.loading && (p.state.width ?? 0) == 0 && p.state.playing) _onFirstFrame();
          });
        }
      }))
      ..add(p.stream.error.listen((e) => _onFailure(classifyPlayerError(e), e)))
      ..add(p.stream.buffering.listen(_onBuffering));
  }

  /// يعمل الآن (أو يحمّل) هذه القناة؟ — للعودة من المشغّل المصغّر دون إعادة فتح البث.
  bool isActive(String channelId) =>
      state.channel?.id == channelId && (state.phase == PlayPhase.playing || state.phase == PlayPhase.loading || state.phase == PlayPhase.switching);

  Future<void> playChannel(String channelId) async {
    if (isActive(channelId)) return;
    _listen();
    _rounds = 0;
    final ch = await _repo.channel(channelId);
    if (ch == null) return;
    final streams = await _repo.streamsFor(channelId);
    state = PlaybackState(channel: ch, streams: streams, phase: streams.isEmpty ? PlayPhase.failed : PlayPhase.loading, errorCode: streams.isEmpty ? 'unavailable' : null);
    unawaited(_repo.recordWatch(channelId));
    if (streams.isNotEmpty) await _openCurrent();
  }

  Future<void> nextServer() async {
    if (state.streams.isEmpty) return;
    state = state.copyWith(index: (state.index + 1) % state.streams.length, phase: PlayPhase.switching, clearError: true, clearPrefer: true);
    await _openCurrent();
  }

  Future<void> retry() async {
    _rounds = 0;
    state = state.copyWith(index: 0, phase: PlayPhase.loading, clearError: true);
    await _openCurrent();
  }

  /// اختيار جودة يدويًا (إعادة فتح على النسخة المطلوبة، §7.4)؛ null = تلقائي.
  Future<void> setQuality(int? height) async {
    state = height == null ? state.copyWith(clearPrefer: true, phase: PlayPhase.switching) : state.copyWith(preferHeight: height, phase: PlayPhase.switching);
    await _openCurrent(keepIndex: true);
  }

  Future<void> stop() async {
    _token++;
    _watchdog?.cancel();
    if (_subs.isNotEmpty) await _p.stop();
    state = const PlaybackState();
  }

  Map<String, String> _headers(StreamRow s) {
    final h = <String, String>{};
    try {
      (jsonDecode(s.headers) as Map).forEach((k, v) => h['$k'] = '$v');
    } catch (_) {}
    if (s.userAgent != null) h['User-Agent'] = s.userAgent!;
    if (s.referrer != null) h['Referer'] = s.referrer!;
    return h;
  }

  Future<void> _openCurrent({bool keepIndex = false}) async {
    final s = state.stream;
    if (s == null) return;
    final token = ++_token;
    final headers = _headers(s);
    final maxQ = ref.read(settingsProvider).maxQuality ?? 1080; // V-10: حد الجودة التلقائية
    final src = await HlsResolver(maxHeight: maxQ).resolve(s.url, headers: headers, prefer: state.preferHeight);
    if (token != _token) return; // أُلغيت بمحاولة أحدث
    state = state.copyWith(source: src, phase: state.phase == PlayPhase.switching ? PlayPhase.switching : PlayPhase.loading);
    log.info('play ch=${state.channel?.number} server=${state.index + 1}/${state.streams.length} local=${src.viaLocalServer} variants=${src.variants.length}');
    await _p.open(Media(src.playUrl, httpHeaders: headers));
    _arm(firstFrameTimeout, token, 'no first frame');
  }

  void _arm(Duration d, int token, String why) {
    _watchdog?.cancel();
    _watchdog = Timer(d, () {
      if (token == _token) _onFailure('network_error', why);
    });
  }

  void _onFirstFrame() {
    if (state.phase == PlayPhase.playing) return;
    _watchdog?.cancel();
    state = state.copyWith(phase: PlayPhase.playing, clearError: true);
  }

  void _onBuffering(bool b) {
    if (state.phase != PlayPhase.playing) return;
    if (b) {
      _arm(stallTimeout, _token, 'stalled');
    } else {
      _watchdog?.cancel();
    }
  }

  Future<void> _onFailure(String code, String? detail) async {
    if (state.channel == null || state.phase == PlayPhase.failed) return;
    log.warning('play failed ch=${state.channel?.number} server=${state.index + 1}: $code ${detail ?? ''}');
    // آخر رابط فشل: جولة إعادة واحدة على كل السيرفرات (تجمّد مؤقت في البث المباشر شائع)،
    // ثم نتوقف ونعرض رسالة مفهومة بدل الدوران بلا نهاية
    if (state.index + 1 >= state.streams.length && _rounds < maxRounds) {
      _rounds++;
      state = state.copyWith(index: 0, phase: PlayPhase.switching, errorCode: code, clearPrefer: true);
      await _openCurrent();
      return;
    }
    if (state.index + 1 >= state.streams.length) {
      _token++;
      _watchdog?.cancel();
      await _p.stop();
      state = state.copyWith(phase: PlayPhase.failed, errorCode: code);
      return;
    }
    state = state.copyWith(index: state.index + 1, phase: PlayPhase.switching, errorCode: code, clearPrefer: true);
    await _openCurrent();
  }
}
