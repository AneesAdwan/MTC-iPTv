// المجموعة E — دليل البرامج (§9.7):
//   ADM-E1 مصادر EPG: XMLTV (رابط، ‎.gz)، الترتيب، الجدولة، تشغيل يدوي، العدّادات.
//   ADM-E2 ربط القنوات: المنشورة بلا برامج مع اقتراحات من قنوات المصادر، والربط بالمعرّف (epg_id).
//   ADM-E3 معاينة الجدول: يوم لقناة، الفجوات والتداخلات، والإزاحة لكل قناة.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/epg_admin_service.dart';
import '../viewer/guide_screen.dart' show fmtRange, textDirOf;
import 'home_layout_screen.dart' show pickChannel;
import 'widgets/admin_widgets.dart';

/// رسالة واضحة إن لم يُطبَّق الترحيل 0004 بعد (جدول غير موجود) بدل خطأ خام.
Widget migrationAware(BuildContext context, Object error) {
  final t = L10n.of(context), c = context.colors;
  final missing = RegExp(r'(does not exist|Could not find|PGRST20[25]|42P01|42883)').hasMatch('$error');
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(missing ? Icons.construction_rounded : Icons.error_outline_rounded, size: 40, color: c.textMuted),
        const SizedBox(height: Space.md),
        Text(missing ? t.needsMigration : '$error', textAlign: TextAlign.center, style: TextStyle(color: c.text)),
      ]),
    ),
  );
}

// ── E1 ─────────────────────────────────────────────────────────────────────
final _epgSourcesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => await ref.watch(adminRepoProvider)?.epgSources() ?? const []);

class EpgSourcesScreen extends ConsumerWidget {
  const EpgSourcesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Map<String, dynamic>? row) async {
    final t = L10n.of(context);
    final name = TextEditingController(text: row?['name'] as String? ?? ''), url = TextEditingController(text: row?['url'] as String? ?? '');
    final prio = TextEditingController(text: '${row?['priority'] ?? 100}'), every = TextEditingController(text: '${row?['interval_hours'] ?? 12}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(row == null ? t.epgAddSource : t.aEdit),
        content: SizedBox(
          width: 520,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: InputDecoration(labelText: t.srcName)),
            TextField(controller: url, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.epgSourceUrl)),
            TextField(controller: prio, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: t.epgPriority)),
            TextField(controller: every, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: t.epgIntervalHours)),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.save))],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepoProvider)?.upsertEpgSource({
        'id': ?row?['id'],
        'name': name.text.trim(),
        'url': url.text.trim(),
        'priority': int.tryParse(prio.text) ?? 100,
        'interval_hours': (int.tryParse(every.text) ?? 12).clamp(1, 168),
      });
    } catch (e) {
      if (context.mounted) toast(context, t.saveFailed('$e'));
    }
    ref.invalidate(_epgSourcesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(_epgSourcesProvider);
    final job = ref.watch(epgAdminProvider);
    ref.listen(epgAdminProvider, (p, n) {
      if (p?.running == true && !n.running) ref.invalidate(_epgSourcesProvider);
    });
    if (async.hasError) return migrationAware(context, async.error!);
    final list = async.value ?? const <Map<String, dynamic>>[];
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton.icon(onPressed: job.running ? null : () => ref.read(epgAdminProvider.notifier).run(), icon: const Icon(Icons.sync_rounded), label: Text(t.epgSyncNow)),
        OutlinedButton.icon(onPressed: () => _edit(context, ref, null), icon: const Icon(Icons.add_rounded), label: Text(t.epgAddSource)),
        if (job.running) Text(t.epgSyncing(job.done, job.total, job.current ?? ''), style: TextStyle(color: c.textMuted)),
        if (!job.running && job.total > 0) Text(t.epgSummary(job.channels, job.programmes), style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
      ]),
      if (job.running) Padding(padding: const EdgeInsets.only(top: Space.sm), child: LinearProgressIndicator(value: job.total == 0 ? null : job.done / job.total)),
      for (final e in job.errors) Text(e, style: TextStyle(color: healthColor('unavailable'), fontSize: 12)),
      const SizedBox(height: Space.sm),
      Text(t.epgGithubNote, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
      const SizedBox(height: Space.md),
      for (final s in list)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: SectionCard(
            title: '${s['priority']}. ${s['name']}',
            trailing: Wrap(spacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (s['last_status'] != null) Pill('${s['last_status']}', s['last_status'] == 'ok' ? healthColor('playable') : healthColor('unavailable')),
              Switch(
                value: s['enabled'] == true,
                onChanged: (v) async {
                  await ref.read(adminRepoProvider)?.upsertEpgSource({'id': s['id'], 'name': s['name'], 'url': s['url'], 'enabled': v});
                  ref.invalidate(_epgSourcesProvider);
                },
              ),
              IconButton(onPressed: () => _edit(context, ref, s), icon: const Icon(Icons.edit_rounded, size: 20)),
              IconButton(
                onPressed: job.running ? null : () => ref.read(epgAdminProvider.notifier).run(onlySource: s['id'] as String),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton(
                onPressed: () async {
                  if (!await confirm(context, t.confirmDelete(1))) return;
                  await ref.read(adminRepoProvider)?.deleteEpgSource(s['id'] as String);
                  ref.invalidate(_epgSourcesProvider);
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Directionality(textDirection: TextDirection.ltr, child: Text('${s['url']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 12))),
              Text(
                [
                  t.epgEvery((s['interval_hours'] as num?)?.toInt() ?? 12),
                  if (s['last_run_at'] != null) t.taskLast(shortTime(DateTime.parse('${s['last_run_at']}').toLocal())),
                  if (s['last_channels'] != null) t.epgSummary((s['last_channels'] as num).toInt(), (s['last_programmes'] as num?)?.toInt() ?? 0),
                  if (s['last_error'] != null) '${s['last_error']}',
                ].join(' · '),
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
            ]),
          ),
        ),
    ]);
  }
}

// ── E2 ─────────────────────────────────────────────────────────────────────
final _missingProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return const [];
  final have = await repo.uidsWithProgrammes();
  return [for (final c in await repo.epgTargets()) if (!have.contains(c['uid'])) c]..sort((a, b) => ((a['number'] as num?) ?? 1 << 30).compareTo((b['number'] as num?) ?? 1 << 30));
});

class EpgMappingScreen extends ConsumerStatefulWidget {
  const EpgMappingScreen({super.key});
  @override
  ConsumerState<EpgMappingScreen> createState() => _EpgMappingScreenState();
}

class _EpgMappingScreenState extends ConsumerState<EpgMappingScreen> {
  /// اقتراحات: معرّف القناة عندنا ← [(المعرّف في المصدر، الاسم، المصدر، تام؟)]
  Map<String, List<(String, String, String, bool)>> suggestions = {};
  bool loading = false;

  Future<void> _load(List<Map<String, dynamic>> missing) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    setState(() => loading = true);
    final pool = <String, (String, String)>{}; // matchKey ← (id, source)
    final names = <String, String>{};
    try {
      for (final s in await repo.epgSources()) {
        if (s['enabled'] != true) continue;
        try {
          final ch = await epgSourceChannels('${s['url']}');
          for (final e in ch.entries) {
            for (final n in e.value) {
              final k = matchKey(n);
              if (k.isEmpty) continue;
              pool.putIfAbsent(k, () => (e.key, '${s['name']}'));
              names.putIfAbsent(e.key, () => n);
            }
          }
        } catch (_) {}
      }
      final out = <String, List<(String, String, String, bool)>>{};
      for (final c in missing) {
        final keys = {for (final n in [c['name'], c['name_ar'], c['name_en'], ...((c['alt_names'] as List?) ?? const [])].whereType<String>()) matchKey(n)}..remove('');
        final hits = <(String, String, String, bool)>[];
        for (final k in keys) {
          final exact = pool[k];
          if (exact != null) hits.add((exact.$1, names[exact.$1] ?? exact.$1, exact.$2, true));
        }
        if (hits.isEmpty) {
          for (final e in pool.entries) {
            if (keys.any((k) => k.length >= 4 && (e.key.contains(k) || k.contains(e.key)))) hits.add((e.value.$1, names[e.value.$1] ?? e.value.$1, e.value.$2, false));
            if (hits.length >= 3) break;
          }
        }
        if (hits.isNotEmpty) out[c['id'] as String] = {for (final h in hits) h.$1: h}.values.toList();
      }
      setState(() => suggestions = out);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _link(String channelId, String epgId) async {
    await ref.read(adminRepoProvider)?.updateChannel(channelId, {'epg_id': epgId});
    setState(() => suggestions.remove(channelId));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final async = ref.watch(_missingProvider);
    if (async.hasError) return migrationAware(context, async.error!);
    final missing = async.value;
    if (missing == null) return const Center(child: CircularProgressIndicator());
    final exact = [for (final m in missing) if (suggestions[m['id']]?.where((h) => h.$4).length == 1) (m['id'] as String, suggestions[m['id']]!.firstWhere((h) => h.$4).$1)];
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Text(t.mapMissing(missing.length), style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
      Text(t.mapHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
      const SizedBox(height: Space.sm),
      Wrap(spacing: Space.sm, children: [
        FilledButton.tonalIcon(
          onPressed: loading ? null : () => _load(missing),
          icon: loading ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high_rounded),
          label: Text(t.mapLoad),
        ),
        if (exact.isNotEmpty)
          FilledButton(
            onPressed: () async {
              for (final (id, epg) in exact) {
                await _link(id, epg);
              }
              ref.invalidate(_missingProvider);
            },
            child: Text(t.mapLinkAll(exact.length)),
          ),
      ]),
      const SizedBox(height: Space.md),
      for (final m in missing)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(width: 40, height: 28, child: m['logo_url'] == null ? null : Image.network('${m['logo_url']}', fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
          title: Text('${m['number'] ?? '—'} · ${m['name_ar'] ?? m['name']}', style: TextStyle(color: c.text)),
          subtitle: Text('${m['epg_id'] ?? m['uid']}', textDirection: TextDirection.ltr, style: TextStyle(color: c.textMuted, fontSize: 12)),
          trailing: suggestions[m['id']] == null
              ? (suggestions.isEmpty ? null : Text(t.mapNone, style: TextStyle(color: c.textDim)))
              : Wrap(spacing: Space.xs, children: [
                  for (final h in suggestions[m['id']]!)
                    ActionChip(
                      avatar: Icon(h.$4 ? Icons.check_circle_rounded : Icons.help_outline_rounded, size: 16, color: h.$4 ? healthColor('playable') : healthColor('degraded')),
                      label: Text('${h.$2} · ${h.$1}'),
                      tooltip: h.$3,
                      onPressed: () => _link(m['id'] as String, h.$1),
                    ),
                ]),
        ),
    ]);
  }
}

// ── E3 ─────────────────────────────────────────────────────────────────────
class EpgPreviewScreen extends ConsumerStatefulWidget {
  const EpgPreviewScreen({super.key});
  @override
  ConsumerState<EpgPreviewScreen> createState() => _EpgPreviewScreenState();
}

class _EpgPreviewScreenState extends ConsumerState<EpgPreviewScreen> {
  AdminChannel? ch;
  DateTime day = DateTime.now();
  List<Map<String, dynamic>>? rows;
  final offset = TextEditingController();
  String? error;

  Future<void> _load() async {
    final repo = ref.read(adminRepoProvider);
    final c = ch;
    if (repo == null || c == null) return;
    try {
      final r = await repo.epgDay(c.epgId ?? c.uid, DateTime(day.year, day.month, day.day));
      // البرامج تُخزَّن بمفتاح uid (كما يكتبها المزامِن)
      final r2 = r.isEmpty && c.epgId != null ? await repo.epgDay(c.uid, DateTime(day.year, day.month, day.day)) : r;
      setState(() {
        rows = r2;
        error = null;
      });
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final items = rows ?? const <Map<String, dynamic>>[];
    final spans = [for (final r in items) (DateTime.parse('${r['start_at']}').toLocal(), DateTime.parse('${r['end_at']}').toLocal())];
    final issues = scheduleIssues(spans);
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton.tonalIcon(
          icon: const Icon(Icons.tv_rounded),
          label: Text(ch == null ? t.pickChannel : ch!.displayName(lang)),
          onPressed: () async {
            final repo = ref.read(adminRepoProvider);
            if (repo == null) return;
            final picked = await pickChannel(context, repo);
            if (picked == null) return;
            setState(() {
              ch = picked;
              offset.text = '${picked.epgOffset}';
            });
            await _load();
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(shortTime(day).substring(0, 10)),
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: day, firstDate: DateTime.now().subtract(const Duration(days: 3)), lastDate: DateTime.now().add(const Duration(days: 7)));
            if (d != null) {
              setState(() => day = d);
              await _load();
            }
          },
        ),
        if (ch != null) ...[
          SizedBox(
            width: 140,
            child: TextField(
              controller: offset,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(labelText: t.e3Offset, isDense: true),
            ),
          ),
          TextButton(
            onPressed: () async {
              final v = (int.tryParse(offset.text.trim()) ?? 0).clamp(-1440, 1440);
              await ref.read(adminRepoProvider)?.updateChannel(ch!.id, {'epg_offset_minutes': v});
              if (context.mounted) toast(context, t.saved);
            },
            child: Text(t.save),
          ),
        ],
      ]),
      if (ch != null) Text(t.e3OffsetHint, style: TextStyle(color: c.textMuted, fontSize: 12)),
      if (error != null) Padding(padding: const EdgeInsets.only(top: Space.md), child: migrationAware(context, error!)),
      if (rows != null) ...[
        const SizedBox(height: Space.md),
        Text(t.e3Issues(issues.where((i) => i.kind == 'gap').length, issues.where((i) => i.kind == 'overlap').length),
            style: TextStyle(color: issues.isEmpty ? healthColor('playable') : healthColor('degraded'), fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.sm),
        if (items.isEmpty) Text(t.noEpgForChannel, style: TextStyle(color: c.textMuted)),
        for (var i = 0; i < items.length; i++) ...[
          for (final iss in issues.where((x) => i > 0 && x.at == (x.kind == 'gap' ? spans[i - 1].$2 : spans[i].$1)))
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
              color: healthColor(iss.kind == 'gap' ? 'degraded' : 'unavailable').withValues(alpha: .12),
              child: Text(iss.kind == 'gap' ? t.e3Gap(iss.length.inMinutes) : t.e3Overlap(iss.length.inMinutes), style: TextStyle(color: c.text, fontSize: 12)),
            ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(width: 110, child: Text(fmtRange(context, spans[i].$1, spans[i].$2), style: TextStyle(color: c.textMuted))),
            title: Text('${items[i]['title']}', textDirection: textDirOf('${items[i]['title']}'), style: TextStyle(color: c.text)),
            subtitle: Text('${items[i]['source'] ?? ''}', style: TextStyle(color: c.textDim, fontSize: 11)),
          ),
        ],
      ],
    ]);
  }
}
