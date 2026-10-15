// ADM-D5 الشعارات (§9.6، §12.7): المعطّلة، بلا شعار، لم تُفحص، العاملة — فحص حقيقي (هل هي صورة فعلًا؟)
// يُسجَّل عبر admin_record_logos، وتعديل الشعار مباشرة. (اقتراحات iptv-org والنسخ للتخزين: المرحلتان 5 و6.)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

final _logoCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async => await ref.watch(adminRepoProvider)?.logoCounts() ?? const {});
final _logoListProvider = FutureProvider.autoDispose.family<List<AdminChannel>, String>((ref, s) async => await ref.watch(adminRepoProvider)?.channelsByLogo(s) ?? const []);

class LogosScreen extends ConsumerStatefulWidget {
  const LogosScreen({super.key});
  @override
  ConsumerState<LogosScreen> createState() => _LogosScreenState();
}

class _LogosScreenState extends ConsumerState<LogosScreen> {
  String tab = 'broken';
  int done = 0, total = 0;
  bool running = false, cancel = false;

  Future<void> _check(List<AdminChannel> chans) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final todo = chans.where((c) => c.logoUrl != null).toList();
    setState(() {
      running = true;
      cancel = false;
      done = 0;
      total = todo.length;
    });
    final probe = LogoProbe();
    final pending = <(String, bool)>[];
    Future<void> flush() async {
      if (pending.isEmpty) return;
      final batch = List.of(pending);
      pending.clear();
      await repo.recordLogos(batch);
    }

    final queue = [...todo];
    Future<void> worker() async {
      while (queue.isNotEmpty && !cancel) {
        final ch = queue.removeAt(0);
        final (ok, _) = await probe.check(ch.logoUrl!);
        if (ok != null) pending.add((ch.id, ok));
        if (pending.length >= 50) await flush();
        if (mounted) setState(() => done++);
      }
    }

    try {
      await Future.wait([for (var i = 0; i < 8; i++) worker()]);
      await flush();
    } catch (e) {
      if (mounted) toast(context, L10n.of(context).saveFailed('$e'));
    }
    if (!mounted) return;
    setState(() => running = false);
    ref.invalidate(_logoCountsProvider);
    ref.invalidate(_logoListProvider);
    ref.invalidate(adminChannelsProvider);
  }

  Future<void> _setLogo(AdminChannel ch) async {
    final t = L10n.of(context);
    final ctrl = TextEditingController(text: ch.logoUrl ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.setLogo),
        content: SizedBox(
          width: 520,
          child: StatefulBuilder(
            builder: (c, set) => Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: ctrl, autofocus: true, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.fLogoUrl), onChanged: (_) => set(() {})),
              const SizedBox(height: Space.md),
              SizedBox(
                height: 90,
                child: ctrl.text.trim().isEmpty
                    ? null
                    : Image.network(ctrl.text.trim(), fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, size: 40, color: healthColor('unavailable'))),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(t.save)),
        ],
      ),
    );
    if (url == null) return;
    final repo = ref.read(adminRepoProvider);
    await repo?.updateChannel(ch.id, {'logo_url': url.isEmpty ? null : url, 'logo_status': 'unknown'});
    ref.invalidate(_logoCountsProvider);
    ref.invalidate(_logoListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final counts = ref.watch(_logoCountsProvider).value ?? const <String, int>{};
    final list = ref.watch(_logoListProvider(tab));
    final items = list.value ?? const <AdminChannel>[];
    final tabs = {'broken': (t.lgBroken, Icons.broken_image_rounded, healthColor('unavailable')), 'missing': (t.lgMissing, Icons.image_not_supported_rounded, healthColor('inconclusive')), 'unknown': (t.lgUnchecked, Icons.help_rounded, healthColor('reachable')), 'ok': (t.lgOk, Icons.check_circle_rounded, healthColor('playable'))};

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final e in tabs.entries)
            ChoiceChip(
              avatar: Icon(e.value.$2, size: 16, color: e.value.$3),
              label: Text('${e.value.$1}  ${counts[e.key] ?? ''}'),
              selected: tab == e.key,
              onSelected: (_) => setState(() => tab = e.key),
            ),
          if (tab != 'missing')
            FilledButton.icon(
              onPressed: running || items.isEmpty ? null : () => _check(items),
              icon: const Icon(Icons.image_search_rounded),
              label: Text('${t.checkLogos} (${items.length})'),
            ),
          if (running) ...[
            Text(t.logoChecking(done, total), style: TextStyle(color: c.textMuted)),
            TextButton(onPressed: () => setState(() => cancel = true), child: Text(t.stop)),
          ],
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(t.logoMoreLater, style: TextStyle(color: c.textMuted, fontSize: 12))),
      if (running) Padding(padding: const EdgeInsets.only(top: Space.sm), child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 2)),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(Space.lg),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisExtent: 150, crossAxisSpacing: Space.md, mainAxisSpacing: Space.md),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final ch = items[i];
            return Material(
              color: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _setLogo(ch),
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Column(children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: c.bg2, borderRadius: BorderRadius.circular(Radii.sm)),
                        child: ch.logoUrl == null
                            ? Icon(Icons.image_not_supported_outlined, color: c.textDim)
                            : Image.network(ch.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, color: healthColor('unavailable'))),
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text('${ch.number ?? '—'} · ${ch.displayName(lang)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      TextButton(onPressed: () => _setLogo(ch), child: Text(t.setLogo, style: const TextStyle(fontSize: 12))),
                      IconButton(iconSize: 18, tooltip: t.aOpenChannel, onPressed: () => context.go('/admin/channel/${ch.id}'), icon: const Icon(Icons.open_in_new_rounded)),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
