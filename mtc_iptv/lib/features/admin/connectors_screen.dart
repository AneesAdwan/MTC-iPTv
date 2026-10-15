// ADM-C4 المراجع الخارجية (§13): موصل iptv-org — الحالة، البحث، المقارنة بالكتالوج، وإرسال المحدد للمعاينة.
// لا استيراد تلقائي أبدًا (§13.3-6): المحدد يمرّ بنفس معاينة الاستيراد، والجديد يذهب لقيد المراجعة.
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/import_service.dart';
import 'widgets/admin_widgets.dart';

/// (القنوات، معرّفات الكتالوج بالحروف الصغيرة دون «@…»)
final _ioProvider = FutureProvider<(List<IptvOrgChannel>, Set<String>)>((ref) async {
  final raw = await IptvOrgConnector().fetch();
  final list = await Isolate.run(() => IptvOrgConnector.parse(raw.channels, raw.streams, raw.logos));
  final repo = ref.read(adminRepoProvider);
  final ids = <String>{};
  if (repo != null) {
    final (chans, _) = await repo.matchingCatalog();
    for (final c in chans) {
      ids.add('${c['uid']}'.toLowerCase().split('@').first);
      if (c['epg_id'] != null) ids.add('${c['epg_id']}'.toLowerCase().split('@').first);
    }
  }
  return (list, ids);
});

class ConnectorsScreen extends ConsumerStatefulWidget {
  const ConnectorsScreen({super.key});
  @override
  ConsumerState<ConnectorsScreen> createState() => _ConnectorsScreenState();
}

class _ConnectorsScreenState extends ConsumerState<ConnectorsScreen> {
  bool started = false, withStreams = true, onlyMissing = true;
  String q = '';
  String? country;
  final selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    if (!started) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('iptv-org · v${IptvOrgConnector.version}', style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: Space.sm),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Text(t.ioLicense, textAlign: TextAlign.center, style: TextStyle(color: c.textMuted))),
          const SizedBox(height: Space.lg),
          FilledButton.icon(onPressed: () => setState(() => started = true), icon: const Icon(Icons.cloud_download_rounded), label: Text(t.ioLoad)),
        ]),
      );
    }
    final async = ref.watch(_ioProvider);
    if (async.isLoading) return const Center(child: CircularProgressIndicator());
    if (async.hasError) return Center(child: Padding(padding: const EdgeInsets.all(Space.xl), child: SelectableText('${async.error}')));
    final (all, inCatalog) = async.value!;
    bool isIn(IptvOrgChannel ch) => inCatalog.contains(ch.id.toLowerCase());
    final key = matchKey(q);
    final countries = ({for (final ch in all) ?ch.country}.toList()..sort());
    final list = all
        .where((ch) =>
            (!withStreams || ch.streams.isNotEmpty) &&
            (!onlyMissing || !isIn(ch)) &&
            (country == null || ch.country == country) &&
            (key.isEmpty || matchKey(ch.name).contains(key) || ch.id.toLowerCase().contains(q.toLowerCase()) || ch.altNames.any((a) => matchKey(a).contains(key))))
        .take(500)
        .toList();
    final chosen = all.where((ch) => selected.contains(ch.id)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 260, child: TextField(decoration: InputDecoration(hintText: t.ioSearch, prefixIcon: const Icon(Icons.search_rounded), isDense: true), onChanged: (v) => setState(() => q = v))),
          DropdownButton<String?>(
            value: country,
            hint: Text(t.allCountries),
            items: [DropdownMenuItem(value: null, child: Text(t.allCountries)), for (final x in countries) DropdownMenuItem(value: x, child: Text(x))],
            onChanged: (v) => setState(() => country = v),
          ),
          FilterChip(label: Text(t.ioStreams(1).replaceAll('1', '≥1')), selected: withStreams, onSelected: (v) => setState(() => withStreams = v)),
          FilterChip(label: Text(t.ioNotInCatalog), selected: onlyMissing, onSelected: (v) => setState(() => onlyMissing = v)),
          FilledButton.icon(
            onPressed: chosen.isEmpty
                ? null
                : () {
                    ref.read(importProvider.notifier).fromText(IptvOrgConnector.toM3u(chosen), label: 'iptv-org (${chosen.length})');
                    context.go('/admin/import-review');
                  },
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(t.ioReview(chosen.length)),
          ),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(t.ioLicense, style: TextStyle(color: c.textMuted, fontSize: 12))),
      Expanded(
        child: ListView.builder(
          itemCount: list.length,
          itemExtent: 60,
          itemBuilder: (_, i) {
            final ch = list[i];
            final inside = isIn(ch);
            return CheckboxListTile(
              value: selected.contains(ch.id),
              onChanged: ch.streams.isEmpty ? null : (v) => setState(() => v == true ? selected.add(ch.id) : selected.remove(ch.id)),
              controlAffinity: ListTileControlAffinity.leading,
              secondary: SizedBox(width: 44, height: 30, child: ch.logo == null ? null : Image.network(ch.logo!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
              title: Row(children: [
                Flexible(child: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600))),
                const SizedBox(width: Space.sm),
                Pill(inside ? t.ioInCatalog : t.ioNotInCatalog, inside ? healthColor('playable') : healthColor('reachable')),
              ]),
              subtitle: Text('${ch.id} · ${ch.country ?? ''} · ${ch.categories.join(', ')} · ${t.ioStreams(ch.streams.length)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(color: c.textMuted, fontSize: 12)),
            );
          },
        ),
      ),
    ]);
  }
}
