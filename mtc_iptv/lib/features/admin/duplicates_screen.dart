// ADM-D2 المكررات والدمج (§11.4): مجموعات بالاسم المطبّع + الدولة (admin_duplicates)،
// دمج **قابل للتراجع** بمعاينة واختيار الحقول المتعارضة، «إخفاء البقية»، و«ليست مكررة».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'channels/channels_admin_screen.dart';
import 'channels/stream_preview.dart';
import 'dashboard_screen.dart';
import 'decisions_dialog.dart';
import 'widgets/admin_widgets.dart';

final duplicatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => await ref.watch(adminRepoProvider)?.duplicates() ?? const []);

class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(duplicatesProvider);
    final groups = async.value ?? const <Map<String, dynamic>>[];
    if (async.isLoading && groups.isEmpty) return const Center(child: CircularProgressIndicator());
    if (async.hasError) return Center(child: Text('${async.error}'));
    if (groups.isEmpty) return EmptyState(icon: Icons.task_alt_rounded, title: t.noDuplicates);

    void reload() {
      ref.invalidate(duplicatesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(adminChannelsProvider);
    }

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Text(t.dupGroups(groups.length), style: TextStyle(color: c.textMuted)),
      const SizedBox(height: Space.md),
      for (final g in groups)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: SectionCard(
            title: '${g['name']}${g['country'] == null ? '' : '  ·  ${g['country']}'}',
            trailing: Wrap(spacing: Space.xs, children: [
              // قرار لكل قناة (4.3): إبقاء/نشر/إخفاء/دمج في…/سلة + تعديل، بملخص قبل التنفيذ
              FilledButton.icon(
                onPressed: () async {
                  if (await showDecisions(context, [for (final x in g['channels'] as List) '${(x as Map)['id']}'])) {
                    reload();
                    if (context.mounted) toast(context, t.dcDone);
                  }
                },
                icon: const Icon(Icons.rule_rounded, size: 18),
                label: Text(t.dcOpen),
              ),
              TextButton.icon(
                onPressed: () => context.go('/admin/compare?ids=${[for (final x in (g['channels'] as List).take(4)) (x as Map)['id']].join(',')}'),
                icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                label: Text(t.aCompare),
              ),
              TextButton(
                onPressed: () async {
                  final repo = ref.read(adminRepoProvider);
                  if (repo == null) return;
                  await repo.markDistinct([for (final x in g['channels'] as List) '${(x as Map)['id']}']);
                  reload();
                },
                child: Text(t.aNotDuplicate),
              ),
            ]),
            child: Column(children: [
              for (final ch in (g['channels'] as List).cast<Map>())
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 44,
                    height: 32,
                    child: ch['logo_url'] == null ? null : Image.network('${ch['logo_url']}', fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                  ),
                  title: Text('${ch['number'] ?? '—'} · ${ch['name']}', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                  subtitle: Text('${ch['uid']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12)),
                  trailing: Wrap(spacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    StatePill(ch['is_published'] == true ? 'published' : 'hidden'),
                    Pill(t.streamsWorking((ch['online'] as num?)?.toInt() ?? 0, (ch['streams'] as num?)?.toInt() ?? 0),
                        ((ch['online'] as num?) ?? 0) > 0 ? healthColor('playable') : healthColor('unavailable')),
                    IconButton(tooltip: t.aTry, onPressed: () => previewChannel(context, ref, '${ch['id']}', '${ch['name']}'), icon: const Icon(Icons.play_circle_outline_rounded)),
                    IconButton(tooltip: t.aOpenChannel, onPressed: () => context.go('/admin/channel/${ch['id']}'), icon: const Icon(Icons.open_in_new_rounded)),
                    FilledButton.tonal(
                      onPressed: () async {
                        final repo = ref.read(adminRepoProvider);
                        if (repo == null) return;
                        final ids = [for (final x in g['channels'] as List) '${(x as Map)['id']}'];
                        final chans = await repo.channelsByIds(ids);
                        if (!context.mounted) return;
                        final keep = chans.firstWhere((x) => x.id == ch['id']);
                        final done = await showDialog<bool>(context: context, builder: (_) => MergeDialog(keep: keep, others: chans.where((x) => x.id != keep.id).toList()));
                        if (done == true) reload();
                      },
                      child: Text(t.aMergeHere),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final repo = ref.read(adminRepoProvider);
                        if (repo == null) return;
                        await repo.hideDuplicates('${ch['id']}', [for (final x in g['channels'] as List) if ((x as Map)['id'] != ch['id']) '${x['id']}']);
                        reload();
                      },
                      child: Text(t.aHideOthers),
                    ),
                  ]),
                ),
            ]),
          ),
        ),
    ]);
  }
}

/// معاينة الدمج + اختيار الحقول المتعارضة (§11.4).
class MergeDialog extends ConsumerStatefulWidget {
  final AdminChannel keep;
  final List<AdminChannel> others;
  const MergeDialog({super.key, required this.keep, required this.others});
  @override
  ConsumerState<MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<MergeDialog> {
  static Map<String, Object?> _fields(AdminChannel c) => {
        'name_ar': c.nameAr,
        'name_en': c.nameEn,
        'number': c.number,
        'logo_url': c.logoUrl,
        'country_code': c.countryCode,
        'category_slug': c.categorySlug,
        'language_code': c.languageCode,
        'quality': c.quality,
        'network': c.network,
        'epg_id': c.epgId,
      };

  late final keepVals = _fields(widget.keep);
  late final conflicts = <String, List<Object?>>{
    for (final k in keepVals.keys)
      if ({keepVals[k], for (final o in widget.others) _fields(o)[k]}.where((v) => v != null).length > 1 || (keepVals[k] == null && widget.others.any((o) => _fields(o)[k] != null)))
        k: {keepVals[k], for (final o in widget.others) _fields(o)[k]}.where((v) => v != null).toList(),
  };
  late final chosen = <String, Object?>{for (final k in conflicts.keys) k: keepVals[k] ?? conflicts[k]!.first};
  bool busy = false;
  String? error;

  Future<void> _merge() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    setState(() => busy = true);
    try {
      await repo.mergeChannels(widget.keep.id, [for (final o in widget.others) o.id],
          keepFields: {for (final e in chosen.entries) if (e.value != keepVals[e.key]) e.key: e.value});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        busy = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final moving = widget.others.fold<int>(0, (a, o) => a + o.streamStates.length);
    return AlertDialog(
      title: Text(t.mergeTitle(widget.keep.displayName(lang))),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.mergePreview(moving, widget.others.length), style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: Space.xs),
            Text(t.mergeUndoHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              Text(t.mergeFieldsHint, style: TextStyle(color: c.text)),
              for (final e in conflicts.entries)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: TextStyle(color: c.textMuted, fontSize: 12)),
                    RadioGroup<Object?>(
                      groupValue: chosen[e.key],
                      onChanged: (v) => setState(() => chosen[e.key] = v),
                      child: Wrap(spacing: Space.sm, children: [
                        for (final v in e.value)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Radio<Object?>(value: v),
                            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Text('$v', overflow: TextOverflow.ellipsis)),
                          ]),
                      ]),
                    ),
                  ]),
                ),
            ],
            if (error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        FilledButton(onPressed: busy ? null : _merge, child: Text(t.aMerge)),
      ],
    );
  }
}
