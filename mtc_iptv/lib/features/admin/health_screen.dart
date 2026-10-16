// ADM-D4 صحة البث (§12): تبويبات بالحالات الرسمية، فحص (طبقتان)، تجربة، وقرارات المدير.
// قرار المالك D-14: النظام لا يخفي ولا يحذف شيئًا تلقائيًا؛ المدير يختار: إخفاء القناة، تعطيل الرابط، أو الحذف.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/layout/h_scroller.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/health_service.dart';
import 'channels/channels_admin_screen.dart';
import 'channels/stream_preview.dart';
import 'dashboard_screen.dart';
import 'widgets/admin_widgets.dart';

final _byStateProvider = FutureProvider.autoDispose.family<List<(AdminStream, String, int?)>, String>((ref, s) async => await ref.watch(adminRepoProvider)?.streamsByHealth(s) ?? const []);

class HealthScreen extends ConsumerStatefulWidget {
  final String? initialState;
  const HealthScreen({super.key, this.initialState});
  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  late String state = widget.initialState ?? 'unavailable';
  final selected = <String>{};
  bool playCheck = true;

  void _reload() {
    ref.invalidate(_byStateProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(adminChannelsProvider);
    selected.clear();
  }

  Future<void> _act(Future<void> Function(AdminRepository r) f) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final t = L10n.of(context);
    try {
      await f(repo);
      if (mounted) toast(context, t.saved);
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    }
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final counts = ref.watch(dashboardProvider).value?.streamsByHealth ?? const <String, int>{};
    final list = ref.watch(_byStateProvider(state));
    final rows = list.value ?? const [];
    final job = ref.watch(healthJobProvider);
    ref.listen(healthJobProvider, (prev, next) {
      if (prev?.running == true && !next.running) {
        setState(_reload);
        toast(context, next.error != null ? t.checkOffline : t.checkDone(next.done));
      }
    });
    final sel = rows.where((r) => selected.contains(r.$1.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HScroller.children(
          height: 56,
          spacing: 0,
          children: [
            for (final s in healthStates)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.sm),
                child: ChoiceChip(
                  avatar: Icon(healthIcon(s), size: 16, color: healthColor(s)),
                  label: Text('${healthLabel(t, s)} ${counts[s] ?? ''}'),
                  selected: state == s,
                  onSelected: (_) => setState(() {
                    state = s;
                    selected.clear();
                  }),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: t.playCheckHint,
                child: FilterChip(label: Text(t.playCheck), selected: playCheck, onSelected: (v) => setState(() => playCheck = v)),
              ),
              FilledButton.icon(
                onPressed: job.running || rows.isEmpty ? null : () => ref.read(healthJobProvider.notifier).run([for (final r in (sel.isEmpty ? rows : sel)) r.$1], playCheck: playCheck),
                icon: const Icon(Icons.monitor_heart_rounded),
                label: Text(sel.isEmpty ? '${t.aCheck} (${rows.length})' : '${t.aCheck} (${sel.length})'),
              ),
              if (job.running) ...[
                Text(t.checkRunning(job.done, job.total), style: TextStyle(color: c.textMuted)),
                TextButton(onPressed: ref.read(healthJobProvider.notifier).cancel, child: Text(t.stop)),
              ],
            ],
          ),
        ),
        // التحديد (القائمة كاملة معروضة): الكل / عكس / إلغاء + إجراءات المحدد
        SelectionBar(
          selected: selected,
          pageIds: [for (final r in rows) r.$1.id],
          total: rows.length,
          onChanged: () => setState(() {}),
          actions: [
            OutlinedButton(
              onPressed: () => _act((r) async {
                for (final x in sel) {
                  await r.updateStream(x.$1.id, {'health_state': 'disabled'});
                }
              }),
              child: Text(t.aDisable),
            ),
            if (state == 'disabled')
              OutlinedButton(
                onPressed: () => _act((r) async {
                  for (final x in sel) {
                    await r.updateStream(x.$1.id, {'health_state': 'inconclusive'});
                  }
                }),
                child: Text(t.aEnable),
              ),
            OutlinedButton(
              onPressed: () => _act((r) => r.updateChannels({for (final x in sel) x.$1.channelId}.toList(), {'publish_state': 'hidden', 'hidden_reason': 'offline'})),
              child: Text(t.aHideChannel),
            ),
            // قنوات الروابط المحددة إلى السلة (تُسترجع خلال 30 يومًا)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                final ch = {for (final x in sel) x.$1.channelId}.toList();
                if (await confirm(context, t.confirmTrash(ch.length))) await _act((r) => r.trashChannels(ch, reason: 'من صحة الروابط'));
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(t.aTrash),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                if (await confirm(context, t.confirmDelete(sel.length))) await _act((r) => r.deleteStreams([for (final x in sel) x.$1.id]));
              },
              child: Text(t.aDelete),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        if (job.running) LinearProgressIndicator(value: job.progress, minHeight: 2) else if (list.isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(list.isLoading ? '' : t.noStreamsInState, style: TextStyle(color: c.textMuted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
                  itemBuilder: (_, i) {
                    final (s, name, number) = rows[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(value: selected.contains(s.id), onChanged: (v) => setState(() => v == true ? selected.add(s.id) : selected.remove(s.id))),
                      title: Row(
                        children: [
                          Text('${number ?? '—'}  ', style: TextStyle(color: c.textMuted)),
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (s.label != null) Text('  · ${s.label}', style: TextStyle(color: c.textMuted)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              s.maskedUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.textMuted, fontSize: 12),
                            ),
                          ),
                          Text(
                            [s.lastCheckedAt == null ? t.neverChecked : t.lastChecked(shortTime(s.lastCheckedAt!)), ?s.healthReason].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.textDim, fontSize: 11.5),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(tooltip: t.aTry, onPressed: () => showStreamPreview(context, s, name), icon: const Icon(Icons.play_circle_outline_rounded)),
                          IconButton(tooltip: t.aOpenChannel, onPressed: () => context.go('/admin/channel/${s.channelId}'), icon: const Icon(Icons.open_in_new_rounded)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
