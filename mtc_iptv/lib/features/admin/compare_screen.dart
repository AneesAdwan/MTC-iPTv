// ADM-D3 المقارنة (§11.5) — النوع الأول: قناة مع قناة (2–4): حقل بحقل مع إبراز الاختلاف، الروابط ونتائجها،
// وتشغيل جنبًا إلى جنب. (مقارنة المصادر واللقطات تحتاج الاستيراد — المرحلة 5.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../player/tls_bundle.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'decisions_dialog.dart';
import 'widgets/admin_widgets.dart';

final _compareProvider = FutureProvider.autoDispose.family<List<(AdminChannel, List<AdminStream>)>, String>((ref, key) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null || key.isEmpty) return const [];
  final ids = key.split(',').take(4).toList();
  final chans = await repo.channelsByIds(ids);
  final byId = {for (final c in chans) c.id: c};
  return [
    for (final id in ids)
      if (byId[id] != null) (byId[id]!, await repo.streamsOf(id)),
  ];
});

class CompareScreen extends ConsumerStatefulWidget {
  final List<String> ids;
  const CompareScreen({super.key, required this.ids});
  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  bool diffOnly = false, playing = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    if (widget.ids.length < 2) {
      return Column(children: [
        Expanded(child: EmptyState(icon: Icons.compare_arrows_rounded, title: t.compareHint, hint: t.compareMoreLater)),
      ]);
    }
    final data = ref.watch(_compareProvider(widget.ids.join(',')));
    final items = data.value ?? const <(AdminChannel, List<AdminStream>)>[];
    if (items.isEmpty) return Center(child: data.isLoading ? const CircularProgressIndicator() : Text('${data.error ?? ''}'));

    Map<String, String> fields(AdminChannel ch) => {
          t.colNumber: '${ch.number ?? '—'}',
          t.fNameAr: ch.nameAr ?? '—',
          t.fNameEn: ch.nameEn ?? '—',
          'uid': ch.uid,
          t.fPublishState: publishLabel(t, ch.publishState),
          t.colCountry: ch.countryCode ?? '—',
          t.colCategory: ch.categorySlug ?? '—',
          t.fLanguage: ch.languageCode ?? '—',
          t.fQuality: ch.quality ?? '—',
          t.fNetwork: ch.network ?? '—',
          t.fEpgId: ch.epgId ?? '—',
          t.fLogoUrl: ch.logoUrl ?? '—',
          t.colStreams: '${ch.streamsOk}/${ch.streamStates.length}',
        };
    final all = [for (final (ch, _) in items) fields(ch)];
    final keys = all.first.keys.where((k) => !diffOnly || all.map((m) => m[k]).toSet().length > 1).toList();

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Wrap(spacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        // قرار لكل قناة (4.3)
        FilledButton.icon(
          onPressed: () async {
            if (await showDecisions(context, widget.ids)) {
              ref.invalidate(_compareProvider);
              if (context.mounted) toast(context, t.dcDone);
            }
          },
          icon: const Icon(Icons.rule_rounded, size: 18),
          label: Text(t.dcOpen),
        ),
        FilterChip(label: Text(t.diffOnly), selected: diffOnly, onSelected: (v) => setState(() => diffOnly = v)),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => playing = !playing),
          icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
          label: Text(playing ? t.stop : t.playSideBySide),
        ),
        Text(t.compareMoreLater, style: TextStyle(color: c.textMuted, fontSize: 12)),
      ]),
      const SizedBox(height: Space.md),
      if (playing)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (ch, streams) in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: streams.isEmpty ? const AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black)) : _MiniPlayer(stream: streams.first, muted: ch != items.first.$1),
              ),
            ),
        ]),
      const SizedBox(height: Space.md),
      // جدول الحقول: الاختلاف مميّز
      Table(
        border: TableBorder.symmetric(inside: BorderSide(color: c.line)),
        columnWidths: const {0: FixedColumnWidth(150)},
        children: [
          TableRow(children: [
            const SizedBox(),
            for (final (ch, _) in items)
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: InkWell(
                  onTap: () => context.go('/admin/channel/${ch.id}'),
                  child: Row(children: [
                    SizedBox(width: 36, height: 26, child: ch.logoUrl == null ? null : Image.network(ch.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Text(ch.displayName(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.accent, fontWeight: FontWeight.w700))),
                  ]),
                ),
              ),
          ]),
          for (final k in keys)
            TableRow(children: [
              Padding(padding: const EdgeInsets.all(Space.sm), child: Text(k, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
              for (final m in all)
                Container(
                  color: all.map((x) => x[k]).toSet().length > 1 ? healthColor('degraded').withValues(alpha: .10) : null,
                  padding: const EdgeInsets.all(Space.sm),
                  child: Text(m[k]!, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 12.5)),
                ),
            ]),
          TableRow(children: [
            Padding(padding: const EdgeInsets.all(Space.sm), child: Text(t.tabStreams, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
            for (final (_, streams) in items)
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final s in streams)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        HealthPill(s.healthState),
                        Directionality(textDirection: TextDirection.ltr, child: Text(s.maskedUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 11))),
                        if (s.healthReason != null) Text(s.healthReason!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textDim, fontSize: 11)),
                      ]),
                    ),
                ]),
              ),
          ]),
        ],
      ),
    ]);
  }
}

/// مشغّل صغير مستقل لكل قناة في المقارنة (الأول بصوت، البقية مكتومة).
class _MiniPlayer extends StatefulWidget {
  final AdminStream stream;
  final bool muted;
  const _MiniPlayer({required this.stream, required this.muted});
  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  late final Player p = Player(configuration: const PlayerConfiguration(title: 'MTC-iPTv compare', logLevel: MPVLogLevel.error));
  late final VideoController v = VideoController(p);

  @override
  void initState() {
    super.initState();
    () async {
      final native = p.platform;
      if (native is NativePlayer) {
        final ca = TlsBundle.path;
        if (ca != null) await native.setProperty('tls-ca-file', ca);
        await native.setProperty('tls-verify', ca != null ? 'yes' : 'no');
      }
      if (widget.muted) await p.setVolume(0);
      await p.open(Media(widget.stream.url, httpHeaders: widget.stream.requestHeaders));
    }();
  }

  @override
  void dispose() {
    p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(borderRadius: BorderRadius.circular(Radii.sm), child: ColoredBox(color: Colors.black, child: Video(controller: v, controls: NoVideoControls, fill: Colors.black))),
      );
}
