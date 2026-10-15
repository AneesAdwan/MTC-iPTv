// المشغّل المصغّر (§8): عند مغادرة شاشة المشاهدة يستمر البث في نافذة صغيرة فوق بقية الشاشات،
// مع «فتح المشغّل» و«إغلاق». يختفي عند فتح شاشة المشاهدة (فلا يُعرض الفيديو مرتين).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/catalog/catalog_repository.dart';
import '../../../player/playback_controller.dart';
import '../../../data/settings/remote_config.dart';

/// عدد شاشات المشاهدة المفتوحة (عادة 0 أو 1).
final watchOpenProvider = NotifierProvider<WatchOpen, int>(WatchOpen.new);

class WatchOpen extends Notifier<int> {
  @override
  int build() => 0;
  void enter() => state++;
  void leave() => state = state > 0 ? state - 1 : 0;
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playbackProvider);
    final open = ref.watch(watchOpenProvider) > 0;
    final ch = s.channel;
    if (open || ch == null || !(ref.watch(remoteConfigProvider).value?.feature('mini_player') ?? true) || s.phase == PlayPhase.idle || s.phase == PlayPhase.failed) return const SizedBox.shrink();
    final t = L10n.of(context), c = context.colors;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final w = narrow ? 220.0 : 320.0;
    return PositionedDirectional(
      end: Space.lg,
      bottom: Space.lg,
      width: w,
      child: Material(
        elevation: 12,
        color: c.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: () => context.push('/watch/${ch.id}'),
              child: Video(controller: ref.watch(videoControllerProvider), controls: NoVideoControls, fill: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: Space.md),
            child: Row(children: [
              Expanded(
                child: Text(ch.displayName(Localizations.localeOf(context)),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              IconButton(tooltip: t.openPlayer, onPressed: () => context.push('/watch/${ch.id}'), icon: const Icon(Icons.open_in_full_rounded, size: 18)),
              IconButton(tooltip: t.closePlayer, onPressed: () => ref.read(playbackProvider.notifier).stop(), icon: const Icon(Icons.close_rounded, size: 18)),
            ]),
          ),
        ]),
      ),
    );
  }
}
