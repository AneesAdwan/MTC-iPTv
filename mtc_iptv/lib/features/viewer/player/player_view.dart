// المشغّل بتصميم الموقع (خطة التحسينات، المرحلة 2؛ المرجع src/player.js + `.yt-*` في src/styles.css):
//  • التحكم فوق الفيديو: تدرّج، شريط «مباشر»، أزرار، شريط صوت يظهر عند المرور (كمبيوتر)؛ يظهر بحركة الماوس
//    أو لمسة، ويختفي بعد 3 ث أثناء التشغيل (والمؤشر يختفي معه).
//  • قائمة إعدادات بنمط الموقع: الجودة، الصوت، الترجمة، السيرفر، معلومات البث، الاختصارات.
//  • شعار MTC-iPTv بالزاوية اليسرى العليا، حجمه نسبة من عرض الفيديو (clamp مثل `.yt-wm`).
//  • قائمة القنوات داخل المشغّل (channel_drawer.dart).
//  • قناة لا تعمل: الرسالة + إعادة المحاولة، سيرفر آخر، السابقة، التالية، إبلاغ.
//  • أسهم جانبية بملء الشاشة، سحب عمودي (لمس) لتغيير القناة، نقرتان (ماوس) لملء الشاشة، حركات الأيقونات.
//  • التلفزيون: والتحكم مخفي، الأعلى/الأسفل يغيّران القناة وOK يُظهره؛ وهو ظاهر، الأسهم تتنقل بين الأزرار.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/layout/form_factor.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/storage/catalog_db.dart';
import '../../../core/text/bidi.dart';
import '../../../data/catalog/catalog_repository.dart';
import '../../../data/epg/epg_repository.dart';
import '../../../data/settings/remote_config.dart';
import '../../../player/pip.dart';
import '../../../player/playback_controller.dart';
import '../guide_screen.dart' show fmtRange;
import '../report_screen.dart';
import '../widgets/channel_card.dart' show ChannelLogo;
import 'channel_drawer.dart';

const _red = Color(0xFFFF0033); // --yt-red
const _panel = Color(0xEB1C1C1C); // rgba(28,28,28,.92)

final _isFavProvider = StreamProvider.family<bool, String>((ref, id) => ref.watch(catalogRepoProvider).watchIsFavorite(id));
final _playingProvider = StreamProvider<bool>((ref) => ref.watch(playerProvider).stream.playing);
final _volumeProvider = StreamProvider<double>((ref) => ref.watch(playerProvider).stream.volume);
final _tracksProvider = StreamProvider<Tracks>((ref) => ref.watch(playerProvider).stream.tracks);

enum _Menu { main, quality, audio, subs, server }

/// زر الرجوع في النظام (Android) لا يصل كمفتاح بل كطلب رجوع: شاشة المشاهدة تسأل المشغّل أولًا.
abstract interface class PlayerBackHandler {
  /// يُغلق قائمة/نافذة مفتوحة أو يخفي التحكم على التلفزيون؛ true إن استهلك الرجوع.
  bool handleBack();
}

class PlayerView extends ConsumerStatefulWidget {
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final void Function(int delta) onStep;
  final void Function(ChannelRow ch) onPick;
  final VoidCallback onBack;
  const PlayerView({super.key, required this.fullscreen, required this.onToggleFullscreen, required this.onStep, required this.onPick, required this.onBack});

  @override
  ConsumerState<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<PlayerView> with TickerProviderStateMixin implements PlayerBackHandler {
  // skipTraversal: المشغّل كله ليس هدفًا للأسهم (كان يسرق التركيز من أزرار الشريط على التلفزيون بلا حلقة)
  final _focus = FocusNode(debugLabel: 'player', skipTraversal: true);
  final _playBtn = FocusNode(debugLabel: 'player-play');
  final _bar = FocusNode(debugLabel: 'player-bar', skipTraversal: true); // يحوي أزرار الشريط: hasFocus = التركيز على أحدها
  bool show = true;
  Timer? _hide;
  _Menu? menu;
  bool drawer = false, stats = false, help = false, volHover = false;

  // حركات: الأيقونة في المنتصف، نسبة الصوت، رسالة أعلى الشاشة، وشريط القناة السفلي
  late final _bezel = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  IconData _bezelIcon = Icons.play_arrow_rounded;
  String? _pill, _osd;
  Timer? _pillT, _osdT;
  late final _lt = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), reverseDuration: const Duration(milliseconds: 450));
  Timer? _ltT;
  String? _ltFor; // آخر قناة عُرض شريطها

  bool get _desktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _wake();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  @override
  void dispose() {
    for (final t in [_hide, _pillT, _osdT, _ltT]) {
      t?.cancel();
    }
    _bezel.dispose();
    _lt.dispose();
    _focus.dispose();
    _playBtn.dispose();
    _bar.dispose();
    super.dispose();
  }

  bool get _overlayOpen => menu != null || drawer || help;

  /// يُظهر التحكم ويعيد عدّاد الإخفاء (3 ث أثناء التشغيل، مثل wake() في الموقع).
  void _wake() {
    if (!mounted) return;
    if (!show) setState(() => show = true);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final s = ref.read(playbackProvider);
      final playing = ref.read(playerProvider).state.playing;
      final tvFocusInBar = isAndroidTv && _bar.hasFocus;
      if (playing && s.phase == PlayPhase.playing && !_overlayOpen && !tvFocusInBar) setState(() => show = false);
    });
  }

  void _hideNow() {
    _hide?.cancel();
    if (mounted && !_overlayOpen) setState(() => show = false);
  }

  void bezel(IconData i) {
    setState(() => _bezelIcon = i);
    _bezel.forward(from: 0);
  }

  void pill(String s) {
    _pillT?.cancel();
    setState(() => _pill = s);
    _pillT = Timer(const Duration(milliseconds: 900), () => mounted ? setState(() => _pill = null) : null);
  }

  void osd(String s) {
    _osdT?.cancel();
    setState(() => _osd = s);
    _osdT = Timer(const Duration(milliseconds: 1800), () => mounted ? setState(() => _osd = null) : null);
  }

  // ── الأفعال ──
  Player get _p => ref.read(playerProvider);
  PlaybackController get _ctrl => ref.read(playbackProvider.notifier);

  void togglePlay() {
    final playing = _p.state.playing;
    _p.playOrPause();
    bezel(playing ? Icons.pause_rounded : Icons.play_arrow_rounded);
    _wake();
  }

  void toggleMute() {
    final v = _p.state.volume;
    _p.setVolume(v > 0 ? 0 : 100);
    bezel(v > 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded);
  }

  void volumeBy(double d) {
    final v = (_p.state.volume + d).clamp(0.0, 100.0);
    _p.setVolume(v);
    pill('${v.round()}%');
  }

  void toggleDrawer([bool? on]) {
    setState(() {
      drawer = on ?? !drawer;
      if (drawer) menu = null;
    });
    if (!drawer) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
    _wake();
  }

  void _openMenu(_Menu? m) {
    setState(() {
      menu = m;
      if (m != null) drawer = false;
    });
    _wake();
  }

  @override
  bool handleBack() {
    if (help || stats) {
      setState(() => help = stats = false);
      return true;
    }
    if (menu != null) {
      _openMenu(null);
      return true;
    }
    if (drawer) {
      toggleDrawer(false);
      return true;
    }
    // التلفزيون: الرجوع الأول يخفي التحكم (والثاني يخرج)
    if (isAndroidTv && show && ref.read(playerProvider).state.playing) {
      _focus.requestFocus();
      _hideNow();
      return true;
    }
    return false;
  }

  // ── لوحة المفاتيح والريموت ──
  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    // الحروف بموضعها على اللوحة لا بالحرف: مع اللغة العربية «F» تعطي «ب» فلا تعمل الاختصارات
    final ph = e.physicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final tv = isAndroidTv;
    KeyEventResult done([VoidCallback? f]) {
      f?.call();
      _wake();
      return KeyEventResult.handled;
    }

    // goBack (زر رجوع Android) لا يُعالج هنا: يصل أيضًا كطلب رجوع من النظام (PopScope في شاشة المشاهدة)،
    // ومعالجته مرتين كانت تنفّذ خطوتين بضغطة واحدة وتُغلق التطبيق.
    if (k == LogicalKeyboardKey.escape) {
      if (help) return done(() => setState(() => help = false));
      if (stats) return done(() => setState(() => stats = false));
      if (menu != null) return done(() => _openMenu(null));
      if (drawer) return done(() => toggleDrawer(false));
      if (tv && show) {
        // لا done(): تُظهر التحكم بعد الفعل. والتركيز يعود للمشغّل حتى لا يضغط OK زرًا مخفيًا
        _focus.requestFocus();
        _hideNow();
        return KeyEventResult.handled;
      }
      return done(widget.fullscreen && !tv ? widget.onToggleFullscreen : widget.onBack);
    }
    if (_overlayOpen) return KeyEventResult.ignored; // القوائم تعالج أسهمها
    // التلفزيون: التركيز داخل الشريط ← يمين/يسار تتنقل بين الأزرار وOK يضغط الزر (أعلى/أسفل تبقى لتغيير القناة).
    // لا تركيز على الشريط ← OK أو يمين/يسار تُظهر التحكم وتركّز «تشغيل».
    final horizontal = k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight;
    final ok = k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter;
    if (tv && _bar.hasFocus && (horizontal || ok)) {
      _wake();
      return KeyEventResult.ignored;
    }
    // فقط حين لا يكون شيء آخر مركّزًا (أزرار شاشة الخطأ مثلًا تُضغط بـ OK كالمعتاد)
    if (tv && _focus.hasPrimaryFocus && (horizontal || ok)) {
      return done(() => WidgetsBinding.instance.addPostFrameCallback((_) => _playBtn.requestFocus()));
    }
    if (k == LogicalKeyboardKey.space || (ph == PhysicalKeyboardKey.keyK || k == LogicalKeyboardKey.keyK) || k == LogicalKeyboardKey.mediaPlayPause) return done(togglePlay);
    if ((ph == PhysicalKeyboardKey.keyM || k == LogicalKeyboardKey.keyM)) return done(toggleMute);
    if ((ph == PhysicalKeyboardKey.keyF || k == LogicalKeyboardKey.keyF)) return done(widget.onToggleFullscreen);
    if ((ph == PhysicalKeyboardKey.keyG || k == LogicalKeyboardKey.keyG)) return done(() => toggleDrawer(true));
    if (shift && (ph == PhysicalKeyboardKey.keyN || k == LogicalKeyboardKey.keyN)) return done(() => widget.onStep(1));
    if (shift && (ph == PhysicalKeyboardKey.keyP || k == LogicalKeyboardKey.keyP)) return done(() => widget.onStep(-1));
    if ((ph == PhysicalKeyboardKey.keyN || k == LogicalKeyboardKey.keyN)) return done(() => _ctrl.nextServer());
    if ((ph == PhysicalKeyboardKey.slash || k == LogicalKeyboardKey.slash || k == LogicalKeyboardKey.question) && shift) return done(() => setState(() => help = !help));
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.pageUp || k == LogicalKeyboardKey.channelUp || k == LogicalKeyboardKey.mediaTrackPrevious) {
      return done(() => widget.onStep(-1));
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.pageDown || k == LogicalKeyboardKey.channelDown || k == LogicalKeyboardKey.mediaTrackNext) {
      return done(() => widget.onStep(1));
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.equal || k == LogicalKeyboardKey.numpadAdd || k == LogicalKeyboardKey.audioVolumeUp) {
      return done(() => volumeBy(5));
    }
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.minus || k == LogicalKeyboardKey.numpadSubtract || k == LogicalKeyboardKey.audioVolumeDown) {
      return done(() => volumeBy(-5));
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(playbackProvider);
    final vc = ref.watch(videoControllerProvider);
    final playing = ref.watch(_playingProvider).value ?? false;
    final t = L10n.of(context);
    final touch = !_desktop && !isAndroidTv;
    final visible = show || !playing || s.phase != PlayPhase.playing || _overlayOpen;

    // شريط القناة السفلي عند بدء قناة جديدة (مثل banner() في الموقع)
    final ch = s.channel;
    if (ch != null && s.phase == PlayPhase.playing && _ltFor != ch.id) {
      _ltFor = ch.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lt.forward(from: 0);
        _ltT?.cancel();
        _ltT = Timer(const Duration(seconds: 6), () => mounted ? _lt.reverse() : null);
      });
    }

    final stack = LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final gutter = (w * .022).clamp(10.0, 24.0);
      return Stack(fit: StackFit.expand, clipBehavior: Clip.hardEdge, children: [
        const ColoredBox(color: Colors.black),
        Video(controller: vc, controls: NoVideoControls, fill: Colors.black),
        // التقاط اللمس/النقر على الفيديو نفسه
        Positioned.fill(child: _gestures(touch)),
        // تدرّج أعلى وأسفل
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C000000), Colors.transparent, Colors.transparent, Color(0xBF000000)],
                  stops: [0, .22, .62, 1],
                ),
              ),
            ),
          ),
        ),
        // الشعار: الزاوية اليسرى العليا، نسبة من عرض الفيديو
        Positioned(
          top: gutter,
          left: gutter,
          child: IgnorePointer(child: _Watermark(height: (w * .036).clamp(18.0, 40.0), dim: visible)),
        ),
        // العنوان (ملء الشاشة فقط، مثل الموقع)
        if (widget.fullscreen && ch != null)
          Positioned(
            top: 0,
            right: 0,
            left: w * .3,
            child: IgnorePointer(child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: const Duration(milliseconds: 250), child: _TopTitle(ch: ch))),
          ),
        // شريط القناة السفلي
        Positioned(
          left: gutter,
          right: gutter,
          bottom: visible ? (w * .08).clamp(58.0, 72.0) : gutter,
          child: IgnorePointer(child: _LowerThird(anim: _lt, ch: ch, scale: (w / 900).clamp(.62, 1.15))),
        ),
        if (s.phase == PlayPhase.loading || s.phase == PlayPhase.switching) IgnorePointer(child: _Spinner(ch: ch, switching: s.phase == PlayPhase.switching)),
        // الأيقونة في المنتصف
        IgnorePointer(child: _Bezel(anim: _bezel, icon: _bezelIcon)),
        if (_pill != null)
          Positioned(
            top: box.maxHeight * .12,
            left: 0,
            right: 0,
            child: IgnorePointer(child: Center(child: _Chip(_pill!, big: true))),
          ),
        if (_osd != null) Positioned(top: 16, left: 0, right: 0, child: IgnorePointer(child: Center(child: _Chip(_osd!)))),
        // أسهم القناة السابقة/التالية على الجانبين (ملء الشاشة، غير اللمس)
        // ليست على التلفزيون: ↑↓ تغيّر القناة، وكانت الأسهم تسرق التركيز من أزرار الشريط
        if (widget.fullscreen && !touch && !drawer && !isAndroidTv) ...[
          Positioned(left: 18, top: 0, bottom: 0, child: Center(child: _SideArrow(visible: visible, icon: Icons.chevron_left_rounded, tip: t.prevChannel, onTap: () => widget.onStep(-1)))),
          Positioned(right: 18, top: 0, bottom: 0, child: Center(child: _SideArrow(visible: visible, icon: Icons.chevron_right_rounded, tip: t.nextChannel, onTap: () => widget.onStep(1)))),
        ],
        if (s.phase == PlayPhase.failed) _ErrorPanel(state: s, onStep: widget.onStep),
        // شريط التحكم
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Focus(focusNode: _bar, child: _bottomBar(s, playing, w)),
            ),
          ),
        ),
        if (menu != null) ...[
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _openMenu(null))),
          Positioned(right: 12, bottom: 62, child: _SettingsMenu(view: menu!, onView: _openMenu, onStats: () => setState(() => stats = true), onHelp: () => setState(() => help = true), osd: osd, maxHeight: box.maxHeight - 80)),
        ],
        if (stats) Positioned(top: 12, left: 12, child: _StatsBox(state: s, onClose: () => setState(() => stats = false))),
        if (help) Positioned.fill(child: _HelpBox(onClose: () => setState(() => help = false))),
        // قائمة القنوات من اليسار
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: const Cubic(.2, .8, .2, 1),
          top: 0,
          bottom: 0,
          left: drawer ? 0 : -(w * .86).clamp(0.0, 380.0) - 70,
          child: drawer
              ? ChannelDrawer(
                  current: ch,
                  onClose: () => toggleDrawer(false),
                  onPick: (x) {
                    widget.onPick(x);
                    if (touch) toggleDrawer(false);
                  },
                )
              : const SizedBox.shrink(),
        ),
      ]);
    });

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      // أي نقرة داخل المشغّل تعيد التركيز إليه (بعد إغلاق القوائم أو تغيّر التخطيط كانت المفاتيح لا تصل)
      child: Listener(
      onPointerDown: (_) {
        if (!_focus.hasFocus) _focus.requestFocus();
      },
      child: MouseRegion(
        cursor: (!visible && widget.fullscreen) ? SystemMouseCursors.none : MouseCursor.defer,
        onHover: (_) => _wake(),
        child: Directionality(textDirection: TextDirection.ltr, child: stack), // مثل الموقع: المشغّل LTR
      ),
      ),
    );
  }

  /// نقرة ماوس = تشغيل/إيقاف، نقرتان = ملء الشاشة؛ لمسة = إظهار/إخفاء التحكم، سحب عمودي = تغيير القناة،
  /// سحب من الحافة اليسرى (ملء الشاشة) = قائمة القنوات.
  Widget _gestures(bool touch) {
    Offset? start;
    return Listener(
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.touch) start = e.position;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (menu != null) return _openMenu(null);
          if (touch) {
            show && (ref.read(playerProvider).state.playing) ? _hideNow() : _wake();
          } else {
            togglePlay();
          }
        },
        onDoubleTap: touch ? null : widget.onToggleFullscreen,
        onVerticalDragEnd: touch
            ? (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() > 300) widget.onStep(v < 0 ? 1 : -1);
              }
            : null,
        onHorizontalDragEnd: touch
            ? (d) {
                final fromEdge = (start?.dx ?? 999) < 40;
                if (widget.fullscreen && fromEdge && (d.primaryVelocity ?? 0) > 200) toggleDrawer(true);
              }
            : null,
      ),
    );
  }

  Widget _bottomBar(PlaybackState s, bool playing, double w) {
    final t = L10n.of(context);
    final id = s.channel?.id;
    final fav = id == null ? false : (ref.watch(_isFavProvider(id)).value ?? false);
    final volume = ref.watch(_volumeProvider).value ?? 100;
    final narrow = w < 560;
    final q = s.source?.selected?.height ?? ref.read(playerProvider).state.height ?? 0;
    final qBadge = q >= 2160 ? '4K' : q >= 1440 ? 'QHD' : q >= 720 ? 'HD' : '';
    final reportOn = ref.watch(remoteConfigProvider).value?.feature('report') ?? true;

    Widget b(String key, IconData i, String tip, VoidCallback f, {double size = 26, Color? color, FocusNode? node, Widget? badge}) => _BarButton(
          key: ValueKey(key),
          focusNode: node,
          tooltip: tip,
          onPressed: () {
            f();
            _wake();
          },
          child: Stack(clipBehavior: Clip.none, children: [Icon(i, size: size, color: color ?? Colors.white), ?badge]),
        );

    final volBtn = MouseRegion(
      onEnter: (_) => setState(() => volHover = true),
      onExit: (_) => setState(() => volHover = false),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        b('pb-mute', volume <= 0 ? Icons.volume_off_rounded : (volume < 50 ? Icons.volume_down_rounded : Icons.volume_up_rounded), volume > 0 ? t.mute : t.unmute, toggleMute),
        if (_desktop)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: volHover ? 76 : 0,
            child: volHover
                ? SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(value: volume.clamp(0, 100), max: 100, label: t.plVolume, onChanged: (v) => _p.setVolume(v)),
                  )
                : null,
          ),
      ]),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // شريط التقدّم: البث مباشر (لا تقديم/رجوع) فالشريط ممتلئ بالأحمر
        SizedBox(
          height: 16,
          child: Center(child: Container(height: 3, color: s.phase == PlayPhase.playing ? _red : Colors.white24)),
        ),
        SizedBox(
          height: 48,
          child: Row(children: [
            b('pb-prev', Icons.skip_previous_rounded, t.prevChannel, () => widget.onStep(-1), size: 24),
            b('pb-play', playing ? Icons.pause_rounded : Icons.play_arrow_rounded, playing ? t.pause : t.play, togglePlay, node: _playBtn),
            b('pb-next', Icons.skip_next_rounded, t.nextChannel, () => widget.onStep(1), size: 24),
            volBtn,
            if (!narrow) _LiveBadge(live: s.phase == PlayPhase.playing && playing, label: t.plLive),
            const Spacer(),
            b('pb-list', Icons.format_list_bulleted_rounded, t.plChannels, () => toggleDrawer(), color: drawer ? context.colors.accent2 : null),
            if (id != null)
              b('pb-fav', fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, fav ? t.removeFavorite : t.addFavorite,
                  () => ref.read(catalogRepoProvider).toggleFavorite(id), color: fav ? context.colors.accent : null, size: 24),
            if (id != null && reportOn && !narrow) b('pb-report', Icons.flag_outlined, t.reportTitle, () => showReportDialog(context, id), size: 24),
            b('pb-gear', Icons.settings_rounded, t.plSettings, () => _openMenu(menu == null ? _Menu.main : null),
                badge: qBadge.isEmpty
                    ? null
                    : Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(2)),
                          child: Text(qBadge, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, height: 1.4)),
                        ),
                      )),
            if (Pip.supported) b('pb-pip', Icons.picture_in_picture_alt_rounded, t.pictureInPicture, Pip.enter, size: 24),
            b('pb-fs', widget.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, widget.fullscreen ? t.exitFullscreen : t.fullscreen, widget.onToggleFullscreen),
          ]),
        ),
      ]),
    );
  }
}

/// زر شفاف بنمط الموقع (40×40، أبيض). حلقة تركيز بيضاء مرسومة بنفسه: حبر InkResponse يُرسم على أقرب
/// Material وهي تحت الفيديو، فلم يكن التركيز يظهر على التلفزيون (محاكي Android TV، 2026-10-16).
/// لا FocusNode جديدة في كل بناء (كانت تُفقد التركيز مع كل تحديث للشريط).
class _BarButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final FocusNode? focusNode;
  const _BarButton({super.key, required this.tooltip, required this.onPressed, required this.child, this.focusNode});
  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool hover = false;
  FocusNode? _own;
  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_BarButton old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasPrimaryFocus;
    return Tooltip(
        message: widget.tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            focusNode: _node,
            onTap: widget.onPressed,
            onHover: (h) => setState(() => hover = h),
            radius: 22,
            highlightShape: BoxShape.circle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: focused ? Colors.white24 : (hover ? Colors.white10 : Colors.transparent),
                border: focused ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      );
  }
}

class _LiveBadge extends StatelessWidget {
  final bool live;
  final String label;
  const _LiveBadge({required this.live, required this.label});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: live ? 1 : .75,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: live ? _red : const Color(0xFF888888))),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

/// شعار MTC-iPTv بمقاسات img/mtc-iptv-logo.svg تمامًا (viewBox 300×64): الرمز SVG (متجهي، حاد بأي مقاس)،
/// والاسم نص حقيقي بخط Inter 900 — كان نص SVG يُرسم بخط بديل لأن Inter غير موجود، فبدا «معدّلًا».
/// ظل ناعم يتبع الحروف (لا مربع) ليُقرأ فوق الفيديو الفاتح.
class _BrandMark extends StatelessWidget {
  final double height;
  const _BrandMark({required this.height});
  @override
  Widget build(BuildContext context) {
    final s = height / 64;
    final style = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w900,
      fontSize: 40 * s,
      letterSpacing: -1 * s,
      height: 1,
      shadows: const [Shadow(color: Color(0x8C000000), blurRadius: 6, offset: Offset(0, 1))],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset('assets/brand/mtc-iptv-icon.svg', width: height, height: height),
        SizedBox(width: 14 * s),
        Text('MTC', style: style.copyWith(color: Colors.white)),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF7A1A)]).createShader(r),
          child: Text('-iPTv', style: style.copyWith(color: Colors.white)),
        ),
      ]),
    );
  }
}

/// للاختبارات ومعاينة التصميم فقط.
@visibleForTesting
Widget debugBrandMark(double height) => _BrandMark(height: height);

/// شعار MTC-iPTv فوق البث: يظهر بمسح من اليسار عند الفتح، وأخفت قليلًا حين يظهر التحكم.
class _Watermark extends StatefulWidget {
  final double height;
  final bool dim;
  const _Watermark({required this.height, required this.dim});
  @override
  State<_Watermark> createState() => _WatermarkState();
}

class _WatermarkState extends State<_Watermark> with SingleTickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(parent: _in, curve: const Cubic(.75, 0, .2, 1));
    return AnimatedOpacity(
      opacity: widget.dim ? .55 : .85,
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _in,
        // مسح من اليسار عند الظهور فقط؛ بعده الشعار ثابت بمقاسه الأصلي (النبضة كانت تغيّر شكله)
        builder: (_, child) => reveal.value >= 1
            ? child!
            : ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: reveal.value.clamp(0.05, 1.0), child: child)),
        child: _BrandMark(height: widget.height),
      ),
    );
  }
}

class _TopTitle extends ConsumerWidget {
  final ChannelRow ch;
  const _TopTitle({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowNextProvider(ch.uid)).value?.now;
    final name = ch.displayName(Localizations.localeOf(context));
    return Directionality(
      textDirection: Directionality.of(context) == TextDirection.ltr ? TextDirection.rtl : TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .12)),
            child: ClipOval(child: ChannelLogo(ch: ch, size: 34)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('${ch.number != null ? '${ltr('${ch.number}')} · ' : ''}$name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)])),
              if (now != null) Text(now.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// للاختبارات ومعاينة التصميم فقط.
@visibleForTesting
Widget debugLowerThird({required AnimationController anim, required ChannelRow ch, double scale = 1}) => _LowerThird(anim: anim, ch: ch, scale: scale);

/// بطاقة القناة عند بدء قناة (طلب المالك 2026-10-17: «فخمة»)، بأسلوب شاشات البث:
/// بطاقة زجاجية تنكشف من الجانب ← لمعة تعبر ← رقم القناة يقفز في شارة متدرجة ← الشعار بتوهج ←
/// الاسم والتفاصيل تباعًا ← «مباشر» بنقطة نابضة ← شريط البرنامج يمتلئ حتى موضعه الحالي. تبقى 6 ث ثم تنزل.
class _LowerThird extends ConsumerStatefulWidget {
  final AnimationController anim; // 0→1 دخول (1.1 ث)، والعكس خروج
  final ChannelRow? ch;
  final double scale; // نسبة من عرض الفيديو
  const _LowerThird({required this.anim, required this.ch, this.scale = 1});
  @override
  ConsumerState<_LowerThird> createState() => _LowerThirdState();
}

class _LowerThirdState extends ConsumerState<_LowerThird> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.ch;
    if (ch == null) return const SizedBox.shrink();
    final c = context.colors, t = L10n.of(context);
    final k = widget.scale;
    final locale = Localizations.localeOf(context);
    final rtl = locale.languageCode == 'ar';
    final nn = ref.watch(nowNextProvider(ch.uid)).value;
    final name = ch.displayName(locale);
    final now = nn?.now, next = nn?.next;
    final tags = [ch.category, ch.country, ch.language].whereType<String>().map((x) => x.toUpperCase()).join('  ·  ');

    return AnimatedBuilder(
      animation: Listenable.merge([widget.anim, _pulse]),
      builder: (context, _) {
        final v = widget.anim.value;
        final leaving = widget.anim.status == AnimationStatus.reverse;
        // مقاطع الدخول (0..1 من مدة الحركة)
        double seg(double a, double b, [Curve cv = Curves.easeOutCubic]) => leaving ? 1 : cv.transform(((v - a) / (b - a)).clamp(0.0, 1.0));
        final card = seg(0, .45, const Cubic(.2, .9, .2, 1));
        final shine = seg(.25, .85, Curves.easeInOut);
        final badge = seg(.15, .55, const Cubic(.34, 1.56, .64, 1));
        final logo = seg(.25, .65, const Cubic(.34, 1.4, .64, 1));
        final title = seg(.32, .72);
        final meta = seg(.42, .82);
        final prog = seg(.5, 1, Curves.easeInOutCubic);
        final exitT = leaving ? Curves.easeIn.transform(1 - v) : 0.0;
        final dot = (math.sin(_pulse.value * 2 * math.pi) + 1) / 2;

        Widget appear(double p, Widget child, {double dy = 10}) =>
            Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, dy * k * (1 - p)), child: child));

        final numberBadge = ch.number == null
            ? const SizedBox.shrink()
            : Transform.scale(
                scale: .5 + .5 * badge,
                child: Opacity(
                  opacity: badge.clamp(0.0, 1.0),
                  child: Container(
                    constraints: BoxConstraints(minWidth: 58 * k),
                    padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 8 * k),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF2D55), Color(0xFFFF5A36), Color(0xFFFF9A2E)]),
                      borderRadius: BorderRadius.circular(14 * k),
                      // توهج متمركز (لا إزاحة: البطاقة تقصّ ما يخرج منها فيظهر ظلًا مربعًا)
                      boxShadow: [BoxShadow(color: const Color(0xFFFF3B50).withValues(alpha: .45), blurRadius: 14 * k)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(t.channelNumber(0).replaceAll('0', '').trim().toUpperCase(),
                          style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 9.5 * k, fontWeight: FontWeight.w700, height: 1)),
                      SizedBox(height: 2 * k),
                      Text(ltr('${ch.number}'), style: TextStyle(color: Colors.white, fontSize: 26 * k, fontWeight: FontWeight.w900, height: 1, letterSpacing: -.5)),
                    ]),
                  ),
                ),
              );

        final logoTile = Transform.scale(
          scale: .7 + .3 * logo,
          child: Opacity(
            opacity: logo.clamp(0.0, 1.0),
            child: Container(
              width: 74 * k,
              height: 56 * k,
              padding: EdgeInsets.all(7 * k),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(14 * k),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: .06 + .06 * dot), blurRadius: 18 * k)],
              ),
              child: ChannelLogo(ch: ch, size: 42 * k),
            ),
          ),
        );

        final live = Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * k, vertical: 3 * k),
          decoration: BoxDecoration(color: const Color(0xFFFF0033).withValues(alpha: .16), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x80FF0033))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7 * k,
              height: 7 * k,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D55),
                boxShadow: [BoxShadow(color: const Color(0xFFFF2D55).withValues(alpha: .4 + .6 * dot), blurRadius: 4 + 8 * dot, spreadRadius: 1.5 * dot)],
              ),
            ),
            SizedBox(width: 5 * k),
            Text(t.plLive, style: TextStyle(color: Colors.white, fontSize: 10.5 * k, fontWeight: FontWeight.w800, letterSpacing: .6)),
          ]),
        );

        final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          appear(
            title,
            Row(children: [
              Flexible(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 21 * k, fontWeight: FontWeight.w800, height: 1.15, shadows: const [Shadow(color: Color(0x99000000), blurRadius: 8)])),
              ),
              SizedBox(width: 8 * k),
              live,
              if (ch.quality != null) ...[
                SizedBox(width: 6 * k),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * k, vertical: 2 * k),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white38)),
                  child: Text(ch.quality!, style: TextStyle(color: Colors.white, fontSize: 9.5 * k, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          ),
          if (tags.isNotEmpty) ...[
            SizedBox(height: 3 * k),
            appear(meta, Text(tags, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFFFFC9A3).withValues(alpha: .85), fontSize: 10.5 * k, fontWeight: FontWeight.w600, letterSpacing: 1.2))),
          ],
          if (now != null) ...[
            SizedBox(height: 8 * k),
            appear(
              meta,
              Row(children: [
                Text(t.nowLabel, style: TextStyle(color: c.accent2, fontSize: 11.5 * k, fontWeight: FontWeight.w800)),
                SizedBox(width: 6 * k),
                Expanded(child: Text(now.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 13 * k, fontWeight: FontWeight.w600))),
                Text(ltr(fmtRange(context, now.startAt, now.endAt)), style: TextStyle(color: Colors.white54, fontSize: 11 * k)),
              ]),
            ),
            SizedBox(height: 6 * k),
            // شريط البرنامج: يمتلئ حتى موضعه الحالي، بتوهج عند الطرف
            LayoutBuilder(builder: (_, box) {
              final p = (nn!.progress(DateTime.now()) * prog).clamp(0.0, 1.0);
              return SizedBox(
                height: 6 * k,
                child: Stack(alignment: AlignmentDirectional.centerStart, children: [
                  Container(height: 3 * k, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(3))),
                  Container(
                    width: box.maxWidth * p,
                    height: 3 * k,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF9A2E)]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF5A36).withValues(alpha: .7), blurRadius: 8 * k)],
                    ),
                  ),
                  PositionedDirectional(
                    start: (box.maxWidth * p - 3 * k).clamp(0.0, box.maxWidth),
                    child: Container(
                      width: 6 * k,
                      height: 6 * k,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: const Color(0xFFFFB46A), blurRadius: 8 * k)]),
                    ),
                  ),
                ]),
              );
            }),
            if (next != null) ...[
              SizedBox(height: 5 * k),
              appear(
                prog,
                Text('${t.nextLabel}:  ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: 11 * k)),
              ),
            ],
          ],
        ]);

        final body = ClipRRect(
          borderRadius: BorderRadius.circular(20 * k),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.fromLTRB(14 * k, 12 * k, 18 * k, 12 * k),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [const Color(0xFF14141C).withValues(alpha: .88), const Color(0xFF0A0A10).withValues(alpha: .62)],
                ),
              ),
              child: Stack(children: [
                Row(children: [numberBadge, SizedBox(width: 12 * k), logoTile, SizedBox(width: 14 * k), Expanded(child: info)]),
                // لمعة تعبر البطاقة مرة واحدة
                if (shine > 0 && shine < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FractionallySizedBox(
                        widthFactor: .35,
                        alignment: Alignment(-1.6 + 3.2 * shine, 0),
                        child: Transform(
                          transform: Matrix4.skewX(-.35),
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: 0)])),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        );

        // إطار رفيع متدرج + خط ضوء علوي
        final framed = Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21 * k),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [const Color(0xFFFF2D55).withValues(alpha: .9), const Color(0xFFFF9A2E).withValues(alpha: .45), Colors.white.withValues(alpha: .06)],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 30 * k, offset: Offset(0, 12 * k))],
          ),
          child: body,
        );

        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 680 * k),
              child: Opacity(
                opacity: (leaving ? 1 - exitT : card).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, leaving ? 30 * k * exitT : 26 * k * (1 - card)),
                  // الانكشاف من جهة البداية؛ بعد اكتماله بلا قصّ حتى يظهر ظل البطاقة كاملًا
                  child: leaving || card >= 1
                      ? framed
                      : ClipRect(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: (.25 + .75 * card).clamp(0.0, 1.0),
                            child: framed,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Spinner extends StatelessWidget {
  final ChannelRow? ch;
  final bool switching;
  const _Spinner({required this.ch, required this.switching});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            const SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white, backgroundColor: Colors.white24)),
            if (ch != null) ClipOval(child: SizedBox(width: 40, height: 40, child: ChannelLogo(ch: ch!, size: 40))),
          ]),
        ),
        const SizedBox(height: 12),
        Text(switching ? t.switchingServer : t.loadingStream, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
      ]),
    );
  }
}

class _Bezel extends StatelessWidget {
  final AnimationController anim;
  final IconData icon;
  const _Bezel({required this.anim, required this.icon});
  @override
  Widget build(BuildContext context) => Center(
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, _) {
            final v = anim.value;
            if (v == 0 || v == 1) return const SizedBox.shrink();
            return Opacity(
              opacity: (1 - v).clamp(0, 1),
              child: Transform.scale(
                scale: 1 + v * .6,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x8C000000)),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
              ),
            );
          },
        ),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final bool big;
  const _Chip(this.text, {this.big = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: big ? 16 : 18, vertical: big ? 8 : 10),
        decoration: BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(big ? 8 : 12)),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: big ? 16 : 15, fontWeight: big ? FontWeight.w700 : FontWeight.w500)),
      );
}

class _SideArrow extends StatelessWidget {
  final bool visible;
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  const _SideArrow({required this.visible, required this.icon, required this.tip, required this.onTap});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Tooltip(
            message: tip,
            child: Material(
              color: const Color(0x6B000000),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                hoverColor: const Color(0xBFFF2D55),
                onTap: onTap,
                child: SizedBox(width: 54, height: 96, child: Icon(icon, color: Colors.white, size: 34)),
              ),
            ),
          ),
        ),
      );
}

/// قناة لا تعمل (خطة 2.5): الرسالة + إعادة المحاولة، سيرفر آخر، السابقة، التالية، إبلاغ.
class _ErrorPanel extends ConsumerWidget {
  final PlaybackState state;
  final void Function(int) onStep;
  const _ErrorPanel({required this.state, required this.onStep});

  String _error(L10n t, String? code) => switch (code) {
        'auth_failed' => t.errAuthFailed,
        'unavailable' => t.errUnavailable,
        'unsupported' => t.errUnsupported,
        'network_error' => t.errNetwork,
        _ => t.plErrHint, // «تعذّر التشغيل» هو العنوان أصلًا
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final ctrl = ref.read(playbackProvider.notifier);
    final id = state.channel?.id;
    final reportOn = ref.watch(remoteConfigProvider).value?.feature('report') ?? true;
    Widget act(IconData i, String label, VoidCallback f, {bool primary = false, bool autofocus = false}) => FilledButton.icon(
          autofocus: autofocus,
          style: FilledButton.styleFrom(
            backgroundColor: primary ? Colors.white : Colors.white.withValues(alpha: .12),
            foregroundColor: primary ? const Color(0xFF111111) : Colors.white,
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          onPressed: f,
          icon: Icon(i, size: 18),
          label: Text(label),
        );
    final message = state.streams.isEmpty ? t.noServers : _error(t, state.errorCode);
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xEB14141C), Color(0xF5000000)])),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Directionality(
            textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 46),
                  const SizedBox(height: 10),
                  Text(t.plCantPlay, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC8C8D0), fontSize: 14)),
                  if (state.streams.length > 1)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(t.allServersFailed(state.streams.length), style: const TextStyle(color: Colors.white54, fontSize: 12.5))),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    act(Icons.refresh_rounded, t.retry, ctrl.retry, primary: true, autofocus: true),
                    if (state.streams.length > 1) act(Icons.dns_rounded, t.plOtherServer, ctrl.nextServer),
                    act(Icons.skip_previous_rounded, t.prevChannel, () => onStep(-1)),
                    act(Icons.skip_next_rounded, t.nextChannel, () => onStep(1)),
                    if (id != null && reportOn) act(Icons.flag_outlined, t.reportTitle, () => showReportDialog(context, id)),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// قائمة الإعدادات بنمط الموقع (`.yt-menu`): صفوف رئيسية، ثم قائمة فرعية بعنوان ورجوع.
class _SettingsMenu extends ConsumerWidget {
  final _Menu view;
  final void Function(_Menu?) onView;
  final VoidCallback onStats, onHelp;
  final void Function(String) osd;
  final double maxHeight;
  const _SettingsMenu({required this.view, required this.onView, required this.onStats, required this.onHelp, required this.osd, required this.maxHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context);
    final s = ref.watch(playbackProvider);
    final ctrl = ref.read(playbackProvider.notifier);
    final player = ref.read(playerProvider);
    final tracks = ref.watch(_tracksProvider).value;
    final audio = tracks?.audio.where((a) => a.id != 'auto' && a.id != 'no').toList() ?? const <AudioTrack>[];
    final subs = tracks?.subtitle.where((a) => a.id != 'auto' && a.id != 'no').toList() ?? const <SubtitleTrack>[];
    final variants = s.source?.variants ?? const [];
    final curH = s.source?.selected?.height ?? player.state.height;
    final selAudio = player.state.track.audio;
    final selSub = player.state.track.subtitle;

    Widget row(IconData i, String label, String value, VoidCallback f) => _MenuRow(onTap: f, children: [
          Icon(i, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
        ]);
    Widget head(String title) => Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))),
          margin: const EdgeInsets.only(bottom: 6),
          child: _MenuRow(onTap: () => onView(_Menu.main), children: [
            const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        );
    Widget opt(String label, bool on, VoidCallback f, {String? extra}) => _MenuRow(height: 42, onTap: f, children: [
          SizedBox(width: 24, child: on ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: on ? FontWeight.w700 : FontWeight.w400))),
          if (extra != null) Text(extra, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
        ]);

    final List<Widget> items = switch (view) {
      _Menu.main => [
          row(Icons.tune_rounded, t.quality, s.preferHeight == null ? '${t.auto}${curH != null && curH > 0 ? ' (${curH}p)' : ''}' : '${s.preferHeight}p', () => onView(_Menu.quality)),
          if (audio.length > 1) row(Icons.audiotrack_rounded, t.audioTrack, selAudio.title ?? selAudio.language ?? '—', () => onView(_Menu.audio)),
          if (subs.isNotEmpty) row(Icons.closed_caption_rounded, t.subtitles, selSub.id == 'no' || selSub.id == 'auto' ? t.off : (selSub.title ?? selSub.language ?? selSub.id), () => onView(_Menu.subs)),
          if (s.streams.length > 1) row(Icons.dns_rounded, t.plServer, '${s.index + 1} / ${s.streams.length}', () => onView(_Menu.server)),
          _MenuRow(onTap: () {
            onView(null);
            onStats();
          }, children: [const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22), const SizedBox(width: 14), Text(t.plStats, style: const TextStyle(color: Colors.white, fontSize: 14))]),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            _MenuRow(onTap: () {
              onView(null);
              onHelp();
            }, children: [const Icon(Icons.keyboard_rounded, color: Colors.white, size: 22), const SizedBox(width: 14), Text(t.plShortcuts, style: const TextStyle(color: Colors.white, fontSize: 14))]),
        ],
      _Menu.quality => [
          head(t.quality),
          for (final v in variants)
            opt(v.label, s.preferHeight == v.height, () {
              ctrl.setQuality(v.height);
              osd(v.label);
              onView(null);
            }, extra: v.bandwidth > 0 ? '${(v.bandwidth / 1e6).toStringAsFixed(1)} Mbps' : null),
          opt('${t.auto}${curH != null && curH > 0 && s.preferHeight == null ? ' ($curH' 'p)' : ''}', s.preferHeight == null, () {
            ctrl.setQuality(null);
            osd(t.auto);
            onView(null);
          }),
        ],
      _Menu.audio => [
          head(t.audioTrack),
          for (final a in audio)
            opt(a.title ?? a.language ?? a.id, selAudio.id == a.id, () {
              player.setAudioTrack(a);
              onView(null);
            }),
        ],
      _Menu.subs => [
          head(t.subtitles),
          opt(t.off, selSub.id == 'no' || selSub.id == 'auto', () {
            player.setSubtitleTrack(SubtitleTrack.no());
            onView(null);
          }),
          for (final x in subs)
            opt(x.title ?? x.language ?? x.id, selSub.id == x.id, () {
              player.setSubtitleTrack(x);
              onView(null);
            }),
        ],
      _Menu.server => [
          head(t.plServer),
          for (var i = 0; i < s.streams.length; i++)
            opt(t.serverOf(i + 1, s.streams.length), s.index == i, () {
              ctrl.selectServer(i);
              osd(t.serverOf(i + 1, s.streams.length));
              onView(null);
            }, extra: [s.streams[i].quality, if (s.streams[i].health == 'unavailable') t.plNotWorking].whereType<String>().join(' · ')),
        ],
    };

    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(minWidth: 280, maxWidth: 340, maxHeight: maxHeight.clamp(120, 600)),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 10))]),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, children: items)),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onTap;
  final double height;
  const _MenuRow({required this.children, required this.onTap, this.height = 46});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        hoverColor: Colors.white10,
        focusColor: Colors.white24,
        child: SizedBox(height: height, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: children))),
      );
}

/// معلومات البث (مثل «إحصاءات للمهتمين» في الموقع): تُحدَّث كل ثانية من mpv.
class _StatsBox extends ConsumerStatefulWidget {
  final PlaybackState state;
  final VoidCallback onClose;
  const _StatsBox({required this.state, required this.onClose});
  @override
  ConsumerState<_StatsBox> createState() => _StatsBoxState();
}

class _StatsBoxState extends ConsumerState<_StatsBox> {
  Timer? _t;
  Map<String, String> props = const {};

  @override
  void initState() {
    super.initState();
    _read();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _read());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    final native = ref.read(playerProvider).platform;
    if (native is! NativePlayer) return;
    final m = <String, String>{};
    for (final k in ['video-codec', 'audio-codec-name', 'hwdec-current', 'demuxer-cache-duration', 'video-bitrate']) {
      try {
        m[k] = await native.getProperty(k);
      } catch (_) {}
    }
    if (mounted) setState(() => props = m);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final s = ref.watch(playbackProvider);
    final p = ref.read(playerProvider).state;
    final url = s.stream?.url;
    final host = url == null ? '—' : (Uri.tryParse(url)?.host ?? '—');
    final cache = double.tryParse(props['demuxer-cache-duration'] ?? '');
    final br = double.tryParse(props['video-bitrate'] ?? '');
    final rows = <(String, String)>[
      (t.plServer, '${s.index + 1} / ${s.streams.length} · $host'),
      (t.plResolution, '${p.width ?? 0}×${p.height ?? 0}${s.source?.selected != null ? ' · ${s.source!.selected!.label}' : ''}'),
      (t.plCodec, '${props['video-codec'] ?? '—'} / ${props['audio-codec-name'] ?? '—'}'),
      if (br != null && br > 0) ('Bitrate', '${(br / 1e6).toStringAsFixed(2)} Mbps'),
      (t.plDecoder, props['hwdec-current'] == null || props['hwdec-current'] == 'no' ? 'software' : props['hwdec-current']!),
      (t.plBuffer, cache == null ? '—' : '${cache.toStringAsFixed(1)} s'),
      (t.plVolume, '${p.volume.round()}%'),
    ];
    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 34, 10),
        decoration: BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(6)),
        child: Stack(clipBehavior: Clip.none, children: [
          Table(defaultColumnWidth: const IntrinsicColumnWidth(), children: [
            for (final (k, v) in rows)
              TableRow(children: [
                Padding(padding: const EdgeInsetsDirectional.only(end: 12), child: Text(k, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12, fontFamily: 'monospace'))),
                Directionality(textDirection: TextDirection.ltr, child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'))),
              ]),
          ]),
          PositionedDirectional(
            top: -6,
            end: -30,
            child: IconButton(visualDensity: VisualDensity.compact, onPressed: widget.onClose, icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18)),
          ),
        ]),
      ),
    );
  }
}

class _HelpBox extends StatelessWidget {
  final VoidCallback onClose;
  const _HelpBox({required this.onClose});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final rows = <(String, String)>[
      ('K / Space', t.plKeyPlay),
      ('M', t.mute),
      ('F', t.fullscreen),
      ('G', t.plChannels),
      ('↑ / ↓ · PgUp / PgDn', t.plKeyChannel),
      ('Shift + N / P', t.plKeyChannel),
      ('← / →  ·  − / +', t.plKeyVolume),
      ('N', t.plKeyServer),
      ('0 – 9', t.plKeyDigits),
      ('?', t.plKeyHelp),
    ];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0xB3000000),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Directionality(
          textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xF51C1C1C), borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(t.plShortcuts, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              for (final (k, d) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(5)),
                      child: Directionality(textDirection: TextDirection.ltr, child: Text(k, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(d, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13.5))),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
