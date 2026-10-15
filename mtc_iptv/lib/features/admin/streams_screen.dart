// ADM-B3 الروابط والسيرفرات (§9.4): كل الروابط عبر كل القنوات بفلاتر النطاق والحالة والبروتوكول،
// ملخّص النطاقات، والروابط ذات بيانات الاعتماد مقنّعة (§19.4).
// (قواعد النطاقات والوسيط تحتاج جداول جديدة — مع إعدادات المشغّل والشبكة ADM-G4.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/health_service.dart';
import 'channels/channels_admin_screen.dart';
import 'channels/stream_preview.dart';
import 'dashboard_screen.dart';
import 'widgets/admin_widgets.dart';

typedef _StreamQ = (String host, String? state, String? protocol, bool creds, int page);

final _streamsQProvider = FutureProvider.autoDispose.family<(List<(AdminStream, String, int?)>, int), _StreamQ>((ref, q) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return (const <(AdminStream, String, int?)>[], 0);
  return repo.streams(host: q.$1, state: q.$2, protocol: q.$3, credentialsOnly: q.$4, page: q.$5);
});
final _hostsProvider = FutureProvider.autoDispose<List<(String, int, int)>>((ref) async => await ref.watch(adminRepoProvider)?.hosts() ?? const []);

class StreamsScreen extends ConsumerStatefulWidget {
  const StreamsScreen({super.key});
  @override
  ConsumerState<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends ConsumerState<StreamsScreen> {
  final hostCtrl = TextEditingController();
  String host = '';
  String? state, protocol;
  bool creds = false;
  int page = 0;
  final selected = <String>{};

  @override
  void dispose() {
    hostCtrl.dispose();
    super.dispose();
  }

  void _set(VoidCallback f) => setState(() {
        f();
        page = 0;
        selected.clear();
      });

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
    setState(() {
      selected.clear();
      ref.invalidate(_streamsQProvider);
      ref.invalidate(_hostsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(adminChannelsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final data = ref.watch(_streamsQProvider((host, state, protocol, creds, page)));
    final rows = data.value?.$1 ?? const <(AdminStream, String, int?)>[];
    final total = data.value?.$2 ?? 0;
    final hosts = ref.watch(_hostsProvider).value ?? const <(String, int, int)>[];
    final job = ref.watch(healthJobProvider);
    ref.listen(healthJobProvider, (prev, next) {
      if (prev?.running == true && !next.running) ref.invalidate(_streamsQProvider);
    });
    final sel = rows.where((r) => selected.contains(r.$1.id)).toList();

    final list = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: hostCtrl,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(hintText: t.hostFilter, prefixIcon: const Icon(Icons.dns_rounded), isDense: true),
              onSubmitted: (v) => _set(() => host = v),
            ),
          ),
          DropdownButton<String?>(
            value: state,
            hint: Text(t.allStates),
            items: [DropdownMenuItem(value: null, child: Text(t.allStates)), for (final s in healthStates) DropdownMenuItem(value: s, child: Text(healthLabel(t, s)))],
            onChanged: (v) => _set(() => state = v),
          ),
          DropdownButton<String?>(
            value: protocol,
            hint: Text(t.allProtocols),
            items: [DropdownMenuItem(value: null, child: Text(t.allProtocols)), for (final p in const ['hls', 'dash', 'ts', 'mp4', 'flv', 'rtmp', 'rtsp', 'udp', 'http']) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) => _set(() => protocol = v),
          ),
          FilterChip(label: Text(t.fCredentials), selected: creds, onSelected: (v) => _set(() => creds = v)),
          if (sel.isNotEmpty) ...[
            Text(t.selected(sel.length), style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
            OutlinedButton(onPressed: job.running ? null : () => ref.read(healthJobProvider.notifier).run([for (final x in sel) x.$1]), child: Text(t.aCheck)),
            OutlinedButton(
              onPressed: () => _act((r) async {
                for (final x in sel) {
                  await r.updateStream(x.$1.id, {'health_state': 'disabled'});
                }
              }),
              child: Text(t.aDisable),
            ),
            OutlinedButton(
              onPressed: () => _act((r) async {
                for (final x in sel.where((x) => x.$1.healthState == 'disabled')) {
                  await r.updateStream(x.$1.id, {'health_state': 'inconclusive'});
                }
              }),
              child: Text(t.aEnable),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                if (await confirm(context, t.confirmDelete(sel.length))) await _act((r) => r.deleteStreams([for (final x in sel) x.$1.id]));
              },
              child: Text(t.aDelete),
            ),
          ],
          if (job.running) Text(t.checkRunning(job.done, job.total), style: TextStyle(color: c.textMuted)),
        ]),
      ),
      if (data.isLoading) const LinearProgressIndicator(minHeight: 2),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          itemCount: rows.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
          itemBuilder: (_, i) {
            final (s, name, number) = rows[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(value: selected.contains(s.id), onChanged: (v) => setState(() => v == true ? selected.add(s.id) : selected.remove(s.id))),
              title: Row(children: [
                HealthPill(s.healthState),
                const SizedBox(width: Space.sm),
                Flexible(child: Text('${number ?? '—'} · $name', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600))),
                if (s.hasCredentials) Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.key_rounded, size: 15, color: healthColor('degraded'))),
              ]),
              subtitle: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(s.maskedUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12)),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (s.protocol != null) Text(s.protocol!, style: TextStyle(color: c.textDim, fontSize: 12)),
                IconButton(tooltip: t.aTry, onPressed: () => showStreamPreview(context, s, name), icon: const Icon(Icons.play_circle_outline_rounded)),
                IconButton(tooltip: t.aOpenChannel, onPressed: () => context.go('/admin/channel/${s.channelId}'), icon: const Icon(Icons.open_in_new_rounded)),
              ]),
            );
          },
        ),
      ),
      Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
        child: Row(children: [
          Text(total == 0 ? '' : t.pageOf(page * 100 + 1, page * 100 + rows.length, total), style: TextStyle(color: c.textMuted)),
          const Spacer(),
          IconButton(onPressed: page == 0 ? null : () => setState(() => page--), icon: const Icon(Icons.chevron_left_rounded)),
          IconButton(onPressed: page * 100 + rows.length >= total ? null : () => setState(() => page++), icon: const Icon(Icons.chevron_right_rounded)),
        ]),
      ),
    ]);

    final hostPanel = Container(
      decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: c.line))),
      child: ListView(padding: const EdgeInsets.all(Space.md), children: [
        Text(t.hostsTitle, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.sm),
        for (final (h, n, ok) in hosts.take(80))
          InkWell(
            onTap: () => _set(() {
              host = h;
              hostCtrl.text = h;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Text(h, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: host == h ? c.accent : c.text, fontSize: 12.5)))),
                Pill('$ok/$n', ok == 0 ? healthColor('unavailable') : healthColor(ok == n ? 'playable' : 'degraded')),
              ]),
            ),
          ),
      ]),
    );

    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 1100 ? Row(children: [Expanded(child: list), SizedBox(width: 300, child: hostPanel)]) : list,
    );
  }
}
