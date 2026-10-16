// ADM-B2 تفاصيل القناة (§9.4): المعلومات، الروابط (ترتيب بالسحب، جرّب، فحص، تعطيل)، الدليل، السجل.
// (الإحصاءات والمصادر تأتي مع قياس المشاهدين والاستيراد: المرحلتان 6 و5.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/storage/catalog_db.dart';
import '../../../data/admin/admin_repository.dart';
import '../../../data/admin/health_service.dart';
import '../../../data/epg/epg_repository.dart';
import '../../viewer/guide_screen.dart' show fmtRange, textDirOf;
import '../dashboard_screen.dart' show AuditTile;
import '../widgets/admin_widgets.dart';
import 'channels_admin_screen.dart';
import 'stream_preview.dart';

final _channelProvider = FutureProvider.autoDispose.family<AdminChannel?, String>((ref, id) async => ref.watch(adminRepoProvider)?.channel(id));
final _streamsProvider = FutureProvider.autoDispose.family<List<AdminStream>, String>((ref, id) async => await ref.watch(adminRepoProvider)?.streamsOf(id) ?? const []);
final _historyProvider = FutureProvider.autoDispose.family<List<AuditEntry>, String>((ref, id) async => await ref.watch(adminRepoProvider)?.recentAudit(rowId: id, limit: 50) ?? const []);
final _epgProvider = StreamProvider.autoDispose.family<List<ProgrammeRow>, String>((ref, uid) {
  final now = DateTime.now();
  return ref.watch(epgRepoProvider).watchRange(now.subtract(const Duration(hours: 2)), now.add(const Duration(hours: 30))).map((l) => l.where((p) => p.channelUid == uid).toList());
});

class ChannelDetailScreen extends ConsumerWidget {
  final String id;
  const ChannelDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final ch = ref.watch(_channelProvider(id));
    final v = ch.value;
    if (v == null) return Center(child: ch.isLoading ? const CircularProgressIndicator() : Text('${ch.error ?? '404'}'));
    final lang = Localizations.localeOf(context).languageCode;
    return DefaultTabController(
      length: 4,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
          child: Row(children: [
            IconButton(onPressed: () => context.go('/admin/channels'), icon: const BackButtonIcon()),
            SizedBox(width: 48, height: 36, child: v.logoUrl == null ? null : Image.network(v.logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox())),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.displayName(lang), style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${v.number ?? '—'} · ${v.uid}', style: TextStyle(color: c.textMuted, fontSize: 12)),
              ]),
            ),
            StatePill(v.publishState),
            const SizedBox(width: Space.sm),
            OutlinedButton.icon(onPressed: () => previewChannel(context, ref, v.id, v.displayName(lang)), icon: const Icon(Icons.play_arrow_rounded), label: Text(t.aTry)),
          ]),
        ),
        TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [Tab(text: t.tabInfo), Tab(text: t.tabStreams), Tab(text: t.tabGuide), Tab(text: t.tabHistory)]),
        Divider(height: 1, color: c.line),
        Expanded(
          child: TabBarView(children: [
            _InfoTab(ch: v, onSaved: () {
              ref.invalidate(_channelProvider(id));
              ref.invalidate(_historyProvider(id));
              ref.invalidate(adminChannelsProvider);
            }),
            _StreamsTab(ch: v),
            _GuideTab(ch: v),
            _HistoryTab(id: id),
          ]),
        ),
      ]),
    );
  }
}

// ── المعلومات ─────────────────────────────────────────────────────────────
class _InfoTab extends ConsumerStatefulWidget {
  final AdminChannel ch;
  final VoidCallback onSaved;
  const _InfoTab({required this.ch, required this.onSaved});
  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  late final ar = TextEditingController(text: widget.ch.nameAr ?? '');
  late final en = TextEditingController(text: widget.ch.nameEn ?? '');
  late final alt = TextEditingController(text: widget.ch.altNames.join(', '));
  late final number = TextEditingController(text: widget.ch.number?.toString() ?? '');
  late final network = TextEditingController(text: widget.ch.network ?? '');
  late final logo = TextEditingController(text: widget.ch.logoUrl ?? '');
  late final language = TextEditingController(text: widget.ch.languageCode ?? '');
  late final desc = TextEditingController(text: widget.ch.description ?? '');
  late final web = TextEditingController(text: widget.ch.website ?? '');
  late final epg = TextEditingController(text: widget.ch.epgId ?? '');
  late final offset = TextEditingController(text: '${widget.ch.epgOffset}');
  late String? country = widget.ch.countryCode, category = widget.ch.categorySlug, quality = widget.ch.quality;
  late String state = widget.ch.publishState;
  late bool featured = widget.ch.isFeatured, parental = widget.ch.parentalLocked;
  bool saving = false;

  @override
  void dispose() {
    for (final x in [ar, en, alt, number, network, logo, language, desc, web, epg, offset]) {
      x.dispose();
    }
    super.dispose();
  }

  String? _n(TextEditingController x) => x.text.trim().isEmpty ? null : x.text.trim();

  Future<void> _save() async {
    final t = L10n.of(context);
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final ch = widget.ch;
    final next = <String, dynamic>{
      'name_ar': _n(ar),
      'name_en': _n(en),
      'alt_names': [for (final x in alt.text.split(RegExp('[,،]'))) if (x.trim().isNotEmpty) x.trim()],
      'number': int.tryParse(number.text.trim()),
      'network': _n(network),
      'logo_url': _n(logo),
      'country_code': country,
      'category_slug': category,
      'language_code': _n(language),
      'quality': quality,
      'description': _n(desc),
      'website': _n(web),
      'epg_id': _n(epg),
      'epg_offset_minutes': int.tryParse(offset.text.trim()) ?? 0,
      'is_featured': featured,
      'parental_locked': parental,
      'publish_state': state,
    };
    final before = <String, dynamic>{
      'name_ar': ch.nameAr,
      'name_en': ch.nameEn,
      'alt_names': ch.altNames,
      'number': ch.number,
      'network': ch.network,
      'logo_url': ch.logoUrl,
      'country_code': ch.countryCode,
      'category_slug': ch.categorySlug,
      'language_code': ch.languageCode,
      'quality': ch.quality,
      'description': ch.description,
      'website': ch.website,
      'epg_id': ch.epgId,
      'epg_offset_minutes': ch.epgOffset,
      'is_featured': ch.isFeatured,
      'parental_locked': ch.parentalLocked,
      'publish_state': ch.publishState,
    };
    // فقط الحقول المتغيرة (سجل التدقيق يبقى مقروءًا)
    final diff = {for (final e in next.entries) if ('${e.value}' != '${before[e.key]}') e.key: e.value};
    if (diff.isEmpty) return;
    if (diff['name_ar'] == null && diff['name_en'] == null && _n(ar) == null && _n(en) == null) return;
    setState(() => saving = true);
    try {
      await repo.updateChannel(ch.id, diff);
      if (mounted) toast(context, t.saved);
      widget.onSaved();
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final refs = ref.watch(adminRefProvider).value;
    String nm(Map m) => '${lang == 'ar' ? m['name_ar'] : m['name_en']}';
    Widget row(List<Widget> xs) => Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < xs.length; i++) ...[if (i > 0) const SizedBox(width: Space.md), Expanded(child: xs[i])],
          ]),
        );
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: SegmentedButton<String>(
              segments: [for (final s in publishStates) ButtonSegment(value: s, label: Text(publishLabel(t, s)))],
              selected: {state},
              onSelectionChanged: (v) => setState(() => state = v.first),
            ),
          ),
          row([TextField(controller: ar, decoration: InputDecoration(labelText: t.fNameAr)), TextField(controller: en, decoration: InputDecoration(labelText: t.fNameEn))]),
          row([TextField(controller: alt, decoration: InputDecoration(labelText: t.fAltNames))]),
          row([
            TextField(controller: number, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: t.fNumber)),
            TextField(controller: network, decoration: InputDecoration(labelText: t.fNetwork)),
            DropdownButtonFormField<String?>(
              initialValue: quality,
              decoration: InputDecoration(labelText: t.fQuality),
              items: [const DropdownMenuItem(value: null, child: Text('—')), for (final q in const ['SD', 'HD', 'FHD', '4K']) DropdownMenuItem(value: q, child: Text(q))],
              onChanged: (v) => quality = v,
            ),
          ]),
          row([
            DropdownButtonFormField<String?>(
              initialValue: country,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.colCountry),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                for (final x in refs?.$1 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['code'] as String, child: Text('${x['flag_emoji'] ?? ''} ${nm(x)}')),
              ],
              onChanged: (v) => country = v,
            ),
            DropdownButtonFormField<String?>(
              initialValue: category,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.colCategory),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                for (final x in refs?.$2 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x))),
              ],
              onChanged: (v) => category = v,
            ),
            TextField(controller: language, decoration: InputDecoration(labelText: t.fLanguage)),
          ]),
          row([
            TextField(controller: logo, decoration: InputDecoration(labelText: t.fLogoUrl), onChanged: (_) => setState(() {})),
            SizedBox(height: 56, child: _n(logo) == null ? null : Image.network(_n(logo)!, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, color: healthColor('unavailable')))),
          ]),
          row([TextField(controller: desc, maxLines: 3, decoration: InputDecoration(labelText: t.fDescription))]),
          row([
            TextField(controller: web, decoration: InputDecoration(labelText: t.fWebsite)),
            TextField(controller: epg, decoration: InputDecoration(labelText: t.fEpgId)),
            TextField(controller: offset, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.fEpgOffset)),
          ]),
          _MergedSection(keepId: widget.ch.id, onChanged: widget.onSaved),
          SwitchListTile(title: Text(t.fFeatured), value: featured, onChanged: (v) => setState(() => featured = v)),
          SwitchListTile(title: Text(t.fParental), value: parental, onChanged: (v) => setState(() => parental = v)),
          const SizedBox(height: Space.md),
          Row(children: [
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_rounded),
              label: Text(t.save),
            ),
            const Spacer(),
            // سلة المحذوفات (0007): لا حذف فوري؛ والقناة التي في السلة تُسترجع أو تُحذف نهائيًا من هنا
            if (widget.ch.trashedAt != null) ...[
              FilledButton.tonalIcon(
                onPressed: () async {
                  final repo = ref.read(adminRepoProvider);
                  if (repo == null) return;
                  await repo.restoreChannels([widget.ch.id]);
                  ref.invalidate(adminChannelsProvider);
                  widget.onSaved();
                },
                icon: const Icon(Icons.restore_from_trash_rounded),
                label: Text(t.aRestore),
              ),
              const SizedBox(width: Space.sm),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                onPressed: () async {
                  final repo = ref.read(adminRepoProvider);
                  if (repo == null || !await confirm(context, t.confirmPurge(1))) return;
                  await repo.purgeChannels([widget.ch.id]);
                  ref.invalidate(adminChannelsProvider);
                  if (context.mounted) context.go('/admin/channels');
                },
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(t.aPurge),
              ),
            ] else
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                onPressed: () async {
                  final repo = ref.read(adminRepoProvider);
                  if (repo == null || !await confirm(context, t.confirmTrash(1))) return;
                  await repo.trashChannels([widget.ch.id]);
                  ref.invalidate(adminChannelsProvider);
                  if (context.mounted) context.go('/admin/channels');
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(t.aTrash),
              ),
          ]),
        ]),
      ),
    );
  }
}

final _mergedProvider = FutureProvider.autoDispose.family<List<AdminChannel>, String>((ref, id) async => await ref.watch(adminRepoProvider)?.mergedInto(id) ?? const []);

/// القنوات المدموجة في هذه القناة مع «تراجع عن الدمج» (§11.4).
class _MergedSection extends ConsumerWidget {
  final String keepId;
  final VoidCallback onChanged;
  const _MergedSection({required this.keepId, required this.onChanged});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(_mergedProvider(keepId)).value ?? const <AdminChannel>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: SectionCard(
        title: t.mergedHere,
        child: Column(children: [
          for (final m in list)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${m.displayName(lang)} · ${m.uid}', style: TextStyle(color: c.text)),
              trailing: OutlinedButton.icon(
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: Text(t.aUnmerge),
                onPressed: () async {
                  try {
                    await ref.read(adminRepoProvider)?.unmerge(m.id);
                    if (context.mounted) toast(context, t.saved);
                  } catch (e) {
                    if (context.mounted) toast(context, t.saveFailed('$e'));
                  }
                  ref.invalidate(_mergedProvider(keepId));
                  ref.invalidate(_streamsProvider(keepId));
                  onChanged();
                },
              ),
            ),
        ]),
      ),
    );
  }
}

// ── الروابط ───────────────────────────────────────────────────────────────
class _StreamsTab extends ConsumerWidget {
  final AdminChannel ch;
  const _StreamsTab({required this.ch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(_streamsProvider(ch.id)).value ?? const <AdminStream>[];
    final job = ref.watch(healthJobProvider);
    final repo = ref.read(adminRepoProvider);
    void reload() {
      ref.invalidate(_streamsProvider(ch.id));
      ref.invalidate(adminChannelsProvider);
    }

    // إعادة التحميل عند انتهاء فحص يخص هذه القناة
    ref.listen(healthJobProvider, (prev, next) {
      if (prev?.running == true && !next.running) reload();
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton.icon(
            onPressed: repo == null
                ? null
                : () async {
                    if (await showDialog<bool>(context: context, builder: (_) => StreamDialog(repo: repo, channelId: ch.id, priority: list.length)) == true) reload();
                  },
            icon: const Icon(Icons.add_rounded),
            label: Text(t.addStream),
          ),
          OutlinedButton.icon(
            onPressed: job.running || list.isEmpty ? null : () => ref.read(healthJobProvider.notifier).run(list),
            icon: const Icon(Icons.monitor_heart_rounded, size: 18),
            label: Text(t.aCheckStreams),
          ),
          if (job.running) Text(t.checkRunning(job.done, job.total), style: TextStyle(color: c.textMuted)),
          Text(t.dragToReorder, style: TextStyle(color: c.textMuted, fontSize: 12)),
        ]),
      ),
      if (job.running) LinearProgressIndicator(value: job.progress, minHeight: 2),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(t.noStreamsAdmin, style: TextStyle(color: c.textMuted)))
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                itemCount: list.length,
                onReorderItem: (from, to) async {
                  final ids = list.map((s) => s.id).toList();
                  ids.insert(to, ids.removeAt(from)); // to مُعدّل مسبقًا بعد الإزالة
                  await repo?.reorderStreams(ids);
                  reload();
                },
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Card(
                    key: ValueKey(s.id),
                    margin: const EdgeInsets.only(bottom: Space.sm),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xl * 1.5, Space.sm),
                      child: Row(children: [
                        CircleAvatar(radius: 13, backgroundColor: c.surface2, child: Text('${i + 1}', style: TextStyle(color: c.text, fontSize: 12))),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              HealthPill(s.healthState),
                              const SizedBox(width: Space.sm),
                              if (s.label != null) Text(s.label!, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                              if (s.protocol != null) Padding(padding: const EdgeInsetsDirectional.only(start: Space.sm), child: Text(s.protocol!, style: TextStyle(color: c.textMuted, fontSize: 12))),
                              if (s.healthScore != null) Padding(padding: const EdgeInsetsDirectional.only(start: Space.sm), child: Text('${s.healthScore}', style: TextStyle(color: c.textMuted, fontSize: 12))),
                            ]),
                            const SizedBox(height: 4),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: SelectableText(s.maskedUrl, maxLines: 1, style: TextStyle(color: c.textMuted, fontSize: 12)),
                            ),
                            Text(
                              [s.lastCheckedAt == null ? t.neverChecked : t.lastChecked(shortTime(s.lastCheckedAt!)), ?s.healthReason].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.textDim, fontSize: 11.5),
                            ),
                          ]),
                        ),
                        IconButton(tooltip: t.aTry, onPressed: () => showStreamPreview(context, s, ch.displayName(lang)), icon: const Icon(Icons.play_circle_outline_rounded)),
                        IconButton(tooltip: t.aCheck, onPressed: job.running ? null : () => ref.read(healthJobProvider.notifier).run([s]), icon: const Icon(Icons.monitor_heart_outlined)),
                        PopupMenuButton<String>(
                          onSelected: (a) async {
                            if (repo == null) return;
                            switch (a) {
                              case 'edit':
                                if (await showDialog<bool>(context: context, builder: (_) => StreamDialog(repo: repo, channelId: ch.id, stream: s)) == true) reload();
                              case 'toggle':
                                await repo.updateStream(s.id, {'health_state': s.healthState == 'disabled' ? 'inconclusive' : 'disabled'});
                                reload();
                              case 'delete':
                                if (await confirm(context, t.confirmDelete(1))) {
                                  await repo.deleteStreams([s.id]);
                                  reload();
                                }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text(t.aEdit)),
                            PopupMenuItem(value: 'toggle', child: Text(s.healthState == 'disabled' ? t.aEnable : t.aDisable)),
                            PopupMenuItem(value: 'delete', child: Text(t.aDelete, style: const TextStyle(color: Color(0xFFEF4444)))),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

/// إضافة/تعديل رابط.
class StreamDialog extends StatefulWidget {
  final AdminRepository repo;
  final String channelId;
  final AdminStream? stream;
  final int priority;
  const StreamDialog({super.key, required this.repo, required this.channelId, this.stream, this.priority = 0});
  @override
  State<StreamDialog> createState() => _StreamDialogState();
}

class _StreamDialogState extends State<StreamDialog> {
  late final url = TextEditingController(text: widget.stream?.url ?? '');
  late final label = TextEditingController(text: widget.stream?.label ?? '');
  late final ua = TextEditingController(text: widget.stream?.userAgent ?? '');
  late final referrer = TextEditingController(text: widget.stream?.referrer ?? '');
  String? error;
  bool saving = false;

  @override
  void dispose() {
    for (final x in [url, label, ua, referrer]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!RegExp(r'^https?://').hasMatch(url.text.trim())) {
      setState(() => error = 'http(s)://…');
      return;
    }
    setState(() => saving = true);
    String? n(TextEditingController x) => x.text.trim().isEmpty ? null : x.text.trim();
    try {
      final s = widget.stream;
      if (s == null) {
        await widget.repo.addStream(widget.channelId, url: url.text, label: label.text, userAgent: ua.text, referrer: referrer.text, priority: widget.priority);
      } else {
        await widget.repo.updateStream(s.id, {'url': url.text.trim(), 'label': n(label), 'user_agent': n(ua), 'referrer': n(referrer)});
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        saving = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    Widget ltrField(TextEditingController ctrl, String lbl, {bool auto = false}) =>
        TextField(controller: ctrl, autofocus: auto, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: lbl));
    return AlertDialog(
      title: Text(widget.stream == null ? t.addStream : t.aEdit),
      content: SizedBox(
        width: 560,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ltrField(url, t.fUrl, auto: true),
          TextField(controller: label, decoration: InputDecoration(labelText: t.fLabel)),
          ltrField(ua, t.fUserAgent),
          ltrField(referrer, t.fReferrer),
          if (error != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        FilledButton(onPressed: saving ? null : _save, child: Text(t.save)),
      ],
    );
  }
}

// ── الدليل ────────────────────────────────────────────────────────────────
class _GuideTab extends ConsumerWidget {
  final AdminChannel ch;
  const _GuideTab({required this.ch});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final items = ref.watch(_epgProvider(ch.epgId ?? ch.uid)).value ?? const <ProgrammeRow>[];
    final now = DateTime.now();
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Text('${t.fEpgId}: ${ch.epgId ?? ch.uid}', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
      Text(t.epgPreviewHint, style: TextStyle(color: c.textMuted, fontSize: 12)),
      const SizedBox(height: Space.md),
      if (items.isEmpty) Text(t.noEpgForChannel, style: TextStyle(color: c.textMuted)),
      for (final p in items)
        ListTile(
          dense: true,
          tileColor: !now.isBefore(p.startAt) && now.isBefore(p.endAt) ? c.accent.withValues(alpha: .10) : null,
          leading: SizedBox(width: 110, child: Text(fmtRange(context, p.startAt, p.endAt), style: TextStyle(color: c.textMuted))),
          title: Text(p.title, textDirection: textDirOf(p.title), style: TextStyle(color: c.text)),
          subtitle: p.description == null ? null : Text(p.description!, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: textDirOf(p.description!)),
        ),
    ]);
  }
}

// ── السجل ─────────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  final String id;
  const _HistoryTab({required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final list = ref.watch(_historyProvider(id));
    final items = list.value ?? const <AuditEntry>[];
    if (list.hasError) return Center(child: Text('${list.error}'));
    if (items.isEmpty) return Center(child: Text(t.noChanges, style: TextStyle(color: c.textMuted)));
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      for (final e in items)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: AuditTile(entry: e),
          children: [
            for (final (k, a, b) in e.changes.take(30))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 150, child: Text(k, style: TextStyle(color: c.textMuted, fontSize: 12))),
                  Expanded(child: Text('${a ?? '∅'}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
                  const Icon(Icons.arrow_forward_rounded, size: 14),
                  Expanded(child: Text('${b ?? '∅'}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12))),
                ]),
              ),
          ],
        ),
    ]);
  }
}
