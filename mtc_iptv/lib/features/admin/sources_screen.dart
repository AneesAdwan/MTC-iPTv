// ADM-C3 المصادر (§10.4): قوائم M3U المتكررة — «جلب ومراجعة» يمرّ بنفس المعاينة التجريبية،
// ويعرض «الفرق منذ آخر جلب» (الروابط التي اختفت) مع خيار تعطيلها لا حذفها. الإزالة لا تحذف روابط ولا قنوات.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/import_service.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'widgets/admin_widgets.dart';

final _sourcesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => await ref.watch(adminRepoProvider)?.sources() ?? const []);

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final t = L10n.of(context);
    final name = TextEditingController(), url = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(t.srcAdd),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: t.srcName)),
            TextField(controller: url, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.srcUrl)),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.save))],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepoProvider)?.addSource(name.text, url.text);
    } catch (e) {
      if (context.mounted) toast(context, t.saveFailed('$e'));
    }
    ref.invalidate(_sourcesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(_sourcesProvider);
    final list = async.value ?? const <Map<String, dynamic>>[];
    final busy = ref.watch(importProvider).phase == ImportPhase.analyzing;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Row(children: [
          FilledButton.icon(onPressed: () => _add(context, ref), icon: const Icon(Icons.add_rounded), label: Text(t.srcAdd)),
          const SizedBox(width: Space.md),
          Expanded(child: Text(t.srcScheduleLater, style: TextStyle(color: c.textMuted, fontSize: 12))),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? (async.isLoading ? const Center(child: CircularProgressIndicator()) : EmptyState(icon: Icons.playlist_play_rounded, title: t.srcEmpty))
            : ListView.separated(
                padding: const EdgeInsets.all(Space.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
                itemBuilder: (_, i) {
                  final s = list[i];
                  final id = s['id'] as String;
                  final last = DateTime.tryParse('${s['last_import_at']}')?.toLocal();
                  final status = '${s['status']}';
                  return SectionCard(
                    title: '${s['name']}',
                    trailing: Wrap(spacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Pill(status, status == 'ready' ? healthColor('playable') : (status == 'failed' ? healthColor('unavailable') : healthColor('inconclusive'))),
                      Switch(
                        value: s['is_active'] == true,
                        onChanged: (v) async {
                          await ref.read(adminRepoProvider)?.updateSource(id, {'is_active': v});
                          ref.invalidate(_sourcesProvider);
                        },
                      ),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Directionality(textDirection: TextDirection.ltr, child: SelectableText('${s['url']}', maxLines: 1, style: TextStyle(color: c.textMuted, fontSize: 12))),
                      const SizedBox(height: Space.xs),
                      Text(
                        [
                          t.srcCounts((s['channel_count'] as num?)?.toInt() ?? 0, (s['stream_count'] as num?)?.toInt() ?? 0),
                          if (last != null) t.srcLast(shortTime(last)),
                          if (s['last_error'] != null) '${s['last_error']}',
                        ].join(' · '),
                        style: TextStyle(color: c.textMuted, fontSize: 12.5),
                      ),
                      const SizedBox(height: Space.sm),
                      Wrap(spacing: Space.sm, children: [
                        FilledButton.tonalIcon(
                          onPressed: busy
                              ? null
                              : () {
                                  ref.read(importProvider.notifier).fromUrl('${s['url']}', sourceId: id, label: '${s['name']}');
                                  context.go('/admin/import-review');
                                },
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: Text(t.srcRefresh),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            if (!await confirm(context, t.srcRemoveConfirm)) return;
                            try {
                              await ref.read(adminRepoProvider)?.removeSource(id);
                            } catch (e) {
                              if (context.mounted) toast(context, t.saveFailed('$e'));
                            }
                            ref.invalidate(_sourcesProvider);
                          },
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: Text(t.srcRemove),
                        ),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}
