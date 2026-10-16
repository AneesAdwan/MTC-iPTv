// V-06 المشاهدة (§7.5، §8.1): المشغّل بتصميم الموقع (player/player_view.dart) + معلومات القناة.
// الاختصارات والإيماءات داخل المشغّل نفسه. ملء الشاشة: النافذة على الكمبيوتر؛ على الجوال إخفاء أشرطة النظام
// والوضع الأفقي؛ والجوال المقلوب أفقيًا والتلفزيون يعرضان المشغّل بملء الشاشة تلقائيًا.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'player/player_view.dart';
import 'widgets/channel_card.dart';
import 'widgets/mini_player.dart';
import 'widgets/number_entry.dart';
import '../../data/settings/remote_config.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String channelId;
  const WatchScreen({super.key, required this.channelId});
  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen> {
  bool fullscreen = false;
  // يُحفظ مسبقًا: استخدام ref داخل dispose غير مسموح في Riverpod 3
  late final PlaybackController _playback;
  late final WatchOpen _open;
  bool _miniEnabled = true; // G5: إن أُوقف المشغّل المصغّر مركزيًا يتوقف البث عند المغادرة
  final _playerKey = GlobalKey(); // المشغّل يحتفظ بحالته عند التبديل بين ملء الشاشة والعرض العادي

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
    Pip.allow(false);
    if (fullscreen) _applyFullscreen(false);
    // لا نوقف البث: يستمر في المشغّل المصغّر حتى يغلقه المستخدم
    Future.microtask(_open.leave);
    if (!_miniEnabled) _playback.stop();
    super.dispose();
  }

  bool get _desktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<void> _applyFullscreen(bool on) async {
    if (_desktop) {
      await windowManager.setFullScreen(on);
    } else if (!isAndroidTv) {
      await SystemChrome.setEnabledSystemUIMode(on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(on ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : const []);
    }
  }

  Future<void> _toggleFullscreen() async {
    setState(() => fullscreen = !fullscreen);
    await _applyFullscreen(fullscreen);
  }

  Future<void> _step(int delta) async {
    final ids = await ref.read(catalogRepoProvider).orderedIds();
    final i = ids.indexOf(widget.channelId);
    if (ids.isEmpty || !mounted) return;
    final next = ids[((i < 0 ? 0 : i) + delta) % ids.length];
    context.replace('/watch/$next');
  }

  void _pick(ChannelRow ch) {
    if (ch.id != widget.channelId) context.replace('/watch/${ch.id}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(playbackProvider);
    _miniEnabled = ref.watch(remoteConfigProvider).value?.feature('mini_player') ?? true;

    // داخل نافذة صورة داخل صورة: الفيديو وحده، بلا عناوين ولا أزرار
    if (ref.watch(pipModeProvider).value ?? false) {
      return ColoredBox(color: Colors.black, child: Video(controller: ref.watch(videoControllerProvider), controls: NoVideoControls, fill: Colors.black));
    }

    final ff = formFactorOf(context);
    final landscapePhone = !_desktop && ff == FormFactor.phone && MediaQuery.orientationOf(context) == Orientation.landscape;
    final fs = fullscreen || landscapePhone || ff == FormFactor.tv;
    final player = PlayerView(key: _playerKey, fullscreen: fs, onToggleFullscreen: _toggleFullscreen, onStep: _step, onPick: _pick, onBack: _back);

    final Widget body = fs
        ? player
        : LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 1000;
            final video = AspectRatio(aspectRatio: 16 / 9, child: player);
            final info = _ChannelInfo(state: s);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: SingleChildScrollView(child: video)),
                    SizedBox(width: 340, child: info),
                  ])
                : ListView(children: [video, info]);
          });

    return NumberEntry(
      onChannel: (ch) => context.replace('/watch/${ch.id}'),
      child: Material(
        color: fs ? Colors.black : c.bg,
        // شريط العنوان المخصص (أزرار النافذة والسحب): المشاهدة خارج الهيكل العام فلا ترثه
        child: Column(children: [
          if (!fs && ff.isDesktop) const TitleBar(),
          Expanded(
            child: Scaffold(
              backgroundColor: fs ? Colors.black : c.bg,
              appBar: fs
                  ? null
                  : AppBar(
                      backgroundColor: c.bg2,
                      title: Text(s.channel?.displayName(Localizations.localeOf(context)) ?? ''),
                      leading: BackButton(onPressed: _back),
                      actions: [
                        IconButton(
                          tooltip: L10n.of(context).numPad,
                          onPressed: () => showNumberPad(context, onChannel: _pick),
                          icon: const Icon(Icons.dialpad_rounded),
                        ),
                      ],
                    ),
              body: body,
            ),
          ),
        ]),
      ),
    );
  }

  void _back() {
    if (fullscreen) {
      _toggleFullscreen();
      return;
    }
    context.canPop() ? context.pop() : context.go('/home');
  }
}

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
