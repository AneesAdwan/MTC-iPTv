// V-06 المشاهدة (§7.5، §8.1): المشغّل + شريط التحكم + معلومات القناة.
// اختصارات سطح المكتب: Space تشغيل/إيقاف · F ملء الشاشة · M كتم · ↑/PgUp القناة السابقة ·
// ↓/PgDn التالية · N سيرفر آخر · Esc خروج من ملء الشاشة/رجوع.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/layout/form_factor.dart';
import '../../app/shell/title_bar.dart';
import '../../app/theme/tokens.dart';
import '../../core/storage/catalog_db.dart';
import '../../core/text/bidi.dart';
import '../../data/catalog/catalog_repository.dart';
import '../../data/epg/epg_repository.dart';
import '../../player/pip.dart';
import '../../player/playback_controller.dart';
import 'guide_screen.dart' show fmtRange, showProgrammeSheet;
import 'parental.dart';
import 'report_screen.dart';
import 'widgets/channel_card.dart';
import 'widgets/mini_player.dart';
import 'widgets/number_entry.dart';
import '../../data/settings/remote_config.dart';

final _isFavProvider = StreamProvider.family<bool, String>((ref, id) => ref.watch(catalogRepoProvider).watchIsFavorite(id));

class WatchScreen extends ConsumerStatefulWidget {
  final String channelId;
  const WatchScreen({super.key, required this.channelId});
  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  bool fullscreen = false;
  final _focus = FocusNode();
  // يُحفظ مسبقًا: استخدام ref داخل dispose غير مسموح في Riverpod 3
  late final PlaybackController _playback;
  late final WatchOpen _open;
  bool _miniEnabled = true; // G5: إن أُوقف المشغّل المصغّر مركزيًا يتوقف البث عند المغادرة

  @override
  void initState() {
    super.initState();
    _playback = ref.read(playbackProvider.notifier);
    _open = ref.read(watchOpenProvider.notifier);
    Future.microtask(() {
      _open.enter();
      _start(widget.channelId);
    });
    Pip.allow(true); // Android: مغادرة التطبيق أثناء المشاهدة تفتح صورة داخل صورة
  }

  @override
  void didUpdateWidget(WatchScreen old) {
    super.didUpdateWidget(old);
    if (old.channelId != widget.channelId) _start(widget.channelId);
  }

  /// الرقابة الأبوية أولًا (§8.4)، ثم التشغيل (أو متابعة البث نفسه إن جاء من المشغّل المصغّر).
  Future<void> _start(String id) async {
    final ch = await ref.read(catalogRepoProvider).channel(id);
    if (!mounted || ch == null) return;
    if (!await ensureUnlocked(context, ref, ch)) {
      if (mounted) _back();
      return;
    }
    await _playback.playChannel(id);
  }

  @override
  void dispose() {
    _focus.dispose();
    Pip.allow(false);
    if (fullscreen && _desktop) windowManager.setFullScreen(false);
    // لا نوقف البث: يستمر في المشغّل المصغّر حتى يغلقه المستخدم
    Future.microtask(_open.leave);
    if (!_miniEnabled) _playback.stop();
    super.dispose();
  }

  bool get _desktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> _toggleFullscreen() async {
    setState(() => fullscreen = !fullscreen);
    if (_desktop) await windowManager.setFullScreen(fullscreen);
  }

  Future<void> _step(int delta) async {
    final ids = await ref.read(catalogRepoProvider).orderedIds();
    final i = ids.indexOf(widget.channelId);
    if (ids.isEmpty || !mounted) return;
    final next = ids[((i < 0 ? 0 : i) + delta) % ids.length];
    context.replace('/watch/$next');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(playbackProvider);
    _miniEnabled = ref.watch(remoteConfigProvider).value?.feature('mini_player') ?? true;
    final player = ref.watch(playerProvider);
    final vc = ref.watch(videoControllerProvider);

    final video = ColoredBox(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        Video(controller: vc, controls: NoVideoControls, fill: Colors.black),
        _StatusOverlay(state: s),
      ]),
    );

    // داخل نافذة صورة داخل صورة: الفيديو وحده، بلا عناوين ولا أزرار
    if (ref.watch(pipModeProvider).value ?? false) return video;

    final body = fullscreen
        ? Stack(children: [Positioned.fill(child: video), Positioned(left: 0, right: 0, bottom: 0, child: _ControlBar(player: player, state: s, fullscreen: true, onFullscreen: _toggleFullscreen, onStep: _step))])
        : LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 1000;
            final player0 = Column(children: [
              AspectRatio(aspectRatio: 16 / 9, child: video),
              _ControlBar(player: player, state: s, fullscreen: false, onFullscreen: _toggleFullscreen, onStep: _step),
            ]);
            final info = _ChannelInfo(state: s);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: SingleChildScrollView(child: player0)),
                    SizedBox(width: 340, child: info),
                  ])
                : ListView(children: [player0, info]);
          });

    return NumberEntry(
      onChannel: (ch) => context.replace('/watch/${ch.id}'),
      child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): player.playOrPause,
        const SingleActivator(LogicalKeyboardKey.keyF): _toggleFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyM): () => player.setVolume(player.state.volume > 0 ? 0 : 100),
        const SingleActivator(LogicalKeyboardKey.keyN): ref.read(playbackProvider.notifier).nextServer,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => _step(1),
        const SingleActivator(LogicalKeyboardKey.escape): () => fullscreen ? _toggleFullscreen() : _back(),
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Material(
          color: fullscreen ? Colors.black : c.bg,
          // شريط العنوان المخصص (أزرار النافذة والسحب): المشاهدة خارج الهيكل العام فلا ترثه
          child: Column(children: [
            if (!fullscreen && formFactorOf(context).isDesktop) const TitleBar(),
            Expanded(
              child: Scaffold(
                backgroundColor: fullscreen ? Colors.black : c.bg,
                appBar: fullscreen
                    ? null
                    : AppBar(
                        backgroundColor: c.bg2,
                        title: Text(s.channel?.displayName(Localizations.localeOf(context)) ?? ''),
                        leading: BackButton(onPressed: _back),
                      ),
                body: body,
              ),
            ),
          ]),
        ),
      ),
    ),
    );
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');
}

class _StatusOverlay extends StatelessWidget {
  final PlaybackState state;
  const _StatusOverlay({required this.state});

  String _error(L10n t, String? code) => switch (code) {
        'auth_failed' => t.errAuthFailed,
        'unavailable' => t.errUnavailable,
        'unsupported' => t.errUnsupported,
        'network_error' => t.errNetwork,
        _ => t.errGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final style = const TextStyle(color: Colors.white, fontSize: 14);
    switch (state.phase) {
      case PlayPhase.loading:
      case PlayPhase.switching:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: Space.md),
            Text(state.phase == PlayPhase.switching ? t.switchingServer : t.loadingStream, style: style),
          ]),
        );
      case PlayPhase.failed:
        return Consumer(builder: (context, ref, _) {
          final ctrl = ref.read(playbackProvider.notifier);
          return Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(Space.xl),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
                const SizedBox(height: Space.md),
                Text(state.streams.isEmpty ? t.noServers : _error(t, state.errorCode), textAlign: TextAlign.center, style: style.copyWith(fontSize: 16)),
                if (state.streams.length > 1)
                  Padding(padding: const EdgeInsets.only(top: Space.xs), child: Text(t.allServersFailed(state.streams.length), style: style.copyWith(color: Colors.white60))),
                const SizedBox(height: Space.lg),
                Wrap(spacing: Space.sm, children: [
                  FilledButton.icon(onPressed: ctrl.retry, icon: const Icon(Icons.refresh_rounded), label: Text(t.retry)),
                ]),
              ]),
            ),
          );
        });
      case PlayPhase.idle:
      case PlayPhase.playing:
        return const SizedBox.shrink();
    }
  }
}

class _ControlBar extends ConsumerWidget {
  final Player player;
  final PlaybackState state;
  final bool fullscreen;
  final VoidCallback onFullscreen;
  final void Function(int) onStep;
  const _ControlBar({required this.player, required this.state, required this.fullscreen, required this.onFullscreen, required this.onStep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final ctrl = ref.read(playbackProvider.notifier);
    final fg = fullscreen ? Colors.white : c.text;
    final playing = ref.watch(_playingProvider).value ?? false;
    final volume = ref.watch(_volumeProvider).value ?? 100;
    final tracks = ref.watch(_tracksProvider).value;
    final id = state.channel?.id;
    final fav = id == null ? false : (ref.watch(_isFavProvider(id)).value ?? false);
    final audio = tracks?.audio.where((a) => a.id != 'auto' && a.id != 'no').toList() ?? const <AudioTrack>[];
    final subs = tracks?.subtitle.where((a) => a.id != 'auto' && a.id != 'no').toList() ?? const <SubtitleTrack>[];
    final variants = state.source?.variants ?? const [];

    IconButton btn(IconData i, String tip, VoidCallback? f, {Color? color}) =>
        IconButton(tooltip: tip, onPressed: f, icon: Icon(i, color: color ?? fg));

    return Container(
      color: fullscreen ? Colors.black54 : c.bg2,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      child: _AdaptiveBar([
        btn(Icons.skip_previous_rounded, t.prevChannel, () => onStep(-1)),
        btn(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, playing ? t.pause : t.play, player.playOrPause),
        btn(Icons.skip_next_rounded, t.nextChannel, () => onStep(1)),
        btn(volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded, volume > 0 ? t.mute : t.unmute, () => player.setVolume(volume > 0 ? 0 : 100)),
        const SizedBox(width: Space.sm),
        if (state.streams.length > 1)
          TextButton.icon(
            onPressed: ctrl.nextServer,
            icon: Icon(Icons.dns_rounded, size: 18, color: fg),
            label: Text(t.serverOf(state.index + 1, state.streams.length), style: TextStyle(color: fg, fontSize: 12.5)),
          ),
        const Spacer(),
        if (variants.length > 1)
          PopupMenuButton<int?>(
            tooltip: t.quality,
            icon: Icon(Icons.high_quality_rounded, color: fg),
            onSelected: ctrl.setQuality,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: null, checked: state.preferHeight == null, child: Text(t.auto)),
              for (final v in variants) CheckedPopupMenuItem(value: v.height, checked: state.preferHeight == v.height, child: Text(v.label)),
            ],
          ),
        if (audio.length > 1)
          PopupMenuButton<AudioTrack>(
            tooltip: t.audioTrack,
            icon: Icon(Icons.audiotrack_rounded, color: fg),
            onSelected: player.setAudioTrack,
            itemBuilder: (_) => [for (final a in audio) PopupMenuItem(value: a, child: Text(a.title ?? a.language ?? a.id))],
          ),
        if (subs.isNotEmpty)
          PopupMenuButton<SubtitleTrack>(
            tooltip: t.subtitles,
            icon: Icon(Icons.subtitles_rounded, color: fg),
            onSelected: player.setSubtitleTrack,
            itemBuilder: (_) => [
              PopupMenuItem(value: SubtitleTrack.no(), child: Text(t.off)),
              for (final s in subs) PopupMenuItem(value: s, child: Text(s.title ?? s.language ?? s.id)),
            ],
          ),
        if (id != null)
          btn(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, fav ? t.removeFavorite : t.addFavorite,
              () => ref.read(catalogRepoProvider).toggleFavorite(id),
              color: fav ? c.accent : fg),
        if (id != null && !fullscreen && (ref.watch(remoteConfigProvider).value?.feature('report') ?? true)) btn(Icons.flag_outlined, t.reportTitle, () => showReportDialog(context, id)),
        if (Pip.supported) btn(Icons.picture_in_picture_alt_rounded, t.pictureInPicture, Pip.enter),
        btn(fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, fullscreen ? t.exitFullscreen : t.fullscreen, onFullscreen),
      ]),
    );
  }
}

/// شريط الأزرار: على الشاشات الواسعة صفّ واحد بفاصل مرن، وعلى الجوال أزرار أصغر وسحب أفقي
/// (لا يُقصّ زر خارج الشاشة — زر «القناة السابقة» اختفى بعد إضافة زر PiP على جوال 411dp).
class _AdaptiveBar extends StatelessWidget {
  final List<Widget> children; // Spacer = الفاصل المرن
  const _AdaptiveBar(this.children);
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= 600) return Row(children: children);
        return Theme(
          data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (final w in children) w is Spacer ? const SizedBox(width: Space.md) : w]),
          ),
        );
      });
}

final _playingProvider = StreamProvider<bool>((ref) => ref.watch(playerProvider).stream.playing);
final _volumeProvider = StreamProvider<double>((ref) => ref.watch(playerProvider).stream.volume);
final _tracksProvider = StreamProvider<Tracks>((ref) => ref.watch(playerProvider).stream.tracks);

class _ChannelInfo extends StatelessWidget {
  final PlaybackState state;
  const _ChannelInfo({required this.state});
  @override
  Widget build(BuildContext context) {
    final c = context.colors, t = L10n.of(context);
    final ch = state.channel;
    if (ch == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: c.line)),
            padding: const EdgeInsets.all(Space.sm),
            child: ChannelLogo(ch: ch, size: 64),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ch.displayName(Localizations.localeOf(context)), style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
              if (ch.number != null) Text(t.channelNumber(ch.number!).replaceAll('${ch.number}', ltr('${ch.number}')), style: TextStyle(color: c.textMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: Space.md),
        Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
          for (final x in [ch.country, ch.category, ch.language, ch.quality, ch.network].whereType<String>())
            Chip(label: Text(x), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: Space.lg),
        _NowNextCard(ch: ch),
      ]),
    );
  }
}

/// الحالي والتالي مع التقدّم (V-06، §8.2).
class _NowNextCard extends ConsumerWidget {
  final ChannelRow ch;
  const _NowNextCard({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nn = ref.watch(nowNextProvider(ch.uid)).value;
    if (nn == null || (nn.now == null && nn.next == null)) return const SizedBox.shrink();
    final c = context.colors, t = L10n.of(context);
    Widget line(String label, ProgrammeRow p, {double? progress}) => InkWell(
          onTap: () => showProgrammeSheet(context, ch, p),
          borderRadius: BorderRadius.circular(Radii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: Space.sm),
                Text(fmtRange(context, p.startAt, p.endAt), style: TextStyle(color: c.textMuted, fontSize: 12)),
              ]),
              Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(value: progress, minHeight: 3, color: c.accent, backgroundColor: c.line, borderRadius: BorderRadius.circular(2)),
                ),
            ]),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: c.line)),
      padding: const EdgeInsets.all(Space.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (nn.now != null) line(t.nowLabel, nn.now!, progress: nn.progress(DateTime.now())),
        if (nn.now != null && nn.next != null) Divider(color: c.line, height: Space.lg),
        if (nn.next != null) line(t.nextLabel, nn.next!),
      ]),
    );
  }
}
