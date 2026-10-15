// ADM-C1 معالج الاستيراد + ADM-C2 مراجعة الاستيراد (§10.3): المصدر ← التحليل ← المعاينة التجريبية ← القبول.
// الشاشتان تعرضان نفس الجلسة: C1 تبدأها، وC2 تراجع نتائجها (جديد/تحديث/موجود/مكرر/فاشل مع «لماذا»).
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/import_service.dart';
import 'widgets/admin_widgets.dart';

const _kinds = ['new', 'update', 'existing', 'in_file', 'failed'];

String kindLabel(L10n t, String k) => switch (k) {
      'new' => t.kNew,
      'update' => t.kUpdate,
      'existing' => t.kExisting,
      'in_file' => t.kInFile,
      _ => t.kFailed,
    };

Color kindColor(String k) => switch (k) {
      'new' => healthColor('reachable'),
      'update' => healthColor('playable'),
      'existing' => healthColor('inconclusive'),
      'in_file' => healthColor('degraded'),
      _ => healthColor('unavailable'),
    };

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(importProvider);
    final t = L10n.of(context);
    return switch (s.phase) {
      ImportPhase.idle => const _SourceStep(),
      ImportPhase.analyzing || ImportPhase.committing => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Space.md),
            Text(s.phase == ImportPhase.analyzing ? '${t.imAnalyzing}  ${s.label ?? ''}' : t.imAnalyzing, textAlign: TextAlign.center),
          ]),
        ),
      ImportPhase.preview => const _PreviewStep(),
      ImportPhase.done => _DoneStep(state: s),
      ImportPhase.error => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 40, color: healthColor('unavailable')),
            const SizedBox(height: Space.sm),
            Padding(padding: const EdgeInsets.all(Space.lg), child: SelectableText(s.error ?? '', textAlign: TextAlign.center)),
            FilledButton(onPressed: ref.read(importProvider.notifier).reset, child: Text(t.imNew)),
          ]),
        ),
    };
  }
}

// ── 1. المصدر ─────────────────────────────────────────────────────────────
class _SourceStep extends ConsumerStatefulWidget {
  const _SourceStep();
  @override
  ConsumerState<_SourceStep> createState() => _SourceStepState();
}

class _SourceStepState extends ConsumerState<_SourceStep> {
  final url = TextEditingController(), paste = TextEditingController(), server = TextEditingController(), user = TextEditingController(), pass = TextEditingController();

  @override
  void dispose() {
    for (final x in [url, paste, server, user, pass]) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final svc = ref.read(importProvider.notifier);
    Widget pad(Widget w) => Padding(padding: const EdgeInsets.all(Space.lg), child: w);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: DefaultTabController(
          length: 4,
          child: Column(children: [
            TabBar(tabs: [Tab(text: t.imFile), Tab(text: t.imUrl), Tab(text: t.imPaste), Tab(text: t.imXtream)]),
            Expanded(
              child: TabBarView(children: [
                pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('M3U · M3U8 · CSV · TSV · JSON · XSPF · TXT · .gz', style: TextStyle(color: c.textMuted)),
                  const SizedBox(height: Space.md),
                  FilledButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(t.imChooseFiles),
                    onPressed: () async {
                      final f = await openFile(acceptedTypeGroups: const [
                        XTypeGroup(label: 'Playlists', extensions: ['m3u', 'm3u8', 'csv', 'tsv', 'json', 'xspf', 'txt', 'gz']),
                        XTypeGroup(label: '*'),
                      ]);
                      if (f != null) await svc.fromFile(await f.readAsBytes(), f.name);
                    },
                  ),
                ])),
                pad(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextField(controller: url, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'https://…/playlist.m3u')),
                  const SizedBox(height: Space.md),
                  Align(alignment: AlignmentDirectional.centerStart, child: FilledButton(onPressed: () => svc.fromUrl(url.text), child: Text(t.imAnalyze))),
                ])),
                pad(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: TextField(
                      controller: paste,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(hintText: t.imPasteHint, alignLabelWithHint: true),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Align(alignment: AlignmentDirectional.centerStart, child: FilledButton(onPressed: () => svc.fromText(paste.text), child: Text(t.imAnalyze))),
                ])),
                pad(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextField(controller: server, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.imXServer)),
                  TextField(controller: user, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.imXUser)),
                  TextField(controller: pass, obscureText: true, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.imXPass)),
                  const SizedBox(height: Space.sm),
                  Text(t.imXtreamNote, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                  const SizedBox(height: Space.md),
                  Align(alignment: AlignmentDirectional.centerStart, child: FilledButton(onPressed: () => svc.fromXtream(server.text, user.text, pass.text), child: Text(t.imAnalyze))),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── 2–3. التحليل والمعاينة التجريبية ─────────────────────────────────────
class _PreviewStep extends ConsumerStatefulWidget {
  const _PreviewStep();
  @override
  ConsumerState<_PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends ConsumerState<_PreviewStep> {
  String kind = 'new';
  bool disableVanished = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final s = ref.watch(importProvider);
    final svc = ref.read(importProvider.notifier);
    final a = s.analysis!;
    final counts = a.report.counts;
    final results = a.report.results;
    final idx = [for (var i = 0; i < results.length; i++) if (results[i].kind == kind) i];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
        child: Wrap(spacing: Space.md, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(s.label ?? '', style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
          Text(t.imFormat(a.format.toUpperCase(), a.encoding + (a.gzipped ? ' · gzip' : '')), style: TextStyle(color: c.textMuted)),
          if (a.attributes.isNotEmpty) Text(a.attributes.take(8).join(' · '), style: TextStyle(color: c.textDim, fontSize: 12)),
        ]),
      ),
      SizedBox(
        height: 56,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm), children: [
          for (final k in _kinds)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.sm),
              child: ChoiceChip(
                label: Text('${kindLabel(t, k)}  ${counts[k] ?? 0}${k == 'new' ? ' (${a.report.newChannels})' : ''}'),
                avatar: CircleAvatar(radius: 5, backgroundColor: kindColor(k)),
                selected: kind == k,
                onSelected: (_) => setState(() => kind = k),
              ),
            ),
          if (a.issues.isNotEmpty)
            ActionChip(
              avatar: Icon(Icons.warning_amber_rounded, size: 16, color: healthColor('degraded')),
              label: Text(t.imIssues(a.issues.length)),
              onPressed: () => showDialog(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text(t.imIssues(a.issues.length)),
                  content: SizedBox(
                    width: 560,
                    height: 400,
                    child: ListView(children: [
                      for (final i in a.issues.take(500))
                        Directionality(textDirection: TextDirection.ltr, child: Text('${i.line}: ${i.kind}  ${i.detail}', style: const TextStyle(fontSize: 12))),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
      if (a.vanishedStreamIds.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: disableVanished,
            onChanged: (v) => setState(() => disableVanished = v ?? false),
            title: Text('${t.imVanished(a.vanishedStreamIds.length)} — ${t.imDisableVanished}'),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        child: Row(children: [
          if (kind == 'new' || kind == 'update') ...[
            TextButton(onPressed: () => svc.selectKind(kind, true), child: Text(t.imAll)),
            TextButton(onPressed: () => svc.selectKind(kind, false), child: Text(t.imNone)),
          ],
          const Spacer(),
          TextButton(onPressed: svc.reset, child: Text(t.cancel)),
          const SizedBox(width: Space.sm),
          FilledButton.icon(
            onPressed: s.selected.isEmpty && !disableVanished ? null : () => svc.commit(disableVanished: disableVanished),
            icon: const Icon(Icons.download_done_rounded),
            label: Text(t.imCommit(s.selected.length)),
          ),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(t.imCommitHint, style: TextStyle(color: c.textMuted, fontSize: 12))),
      const SizedBox(height: Space.sm),
      Divider(height: 1, color: c.line),
      Expanded(
        child: ListView.builder(
          itemCount: idx.length,
          itemExtent: 64,
          itemBuilder: (_, j) {
            final i = idx[j];
            final r = results[i];
            final selectable = r.kind == 'new' || r.kind == 'update';
            return ListTile(
              leading: selectable ? Checkbox(value: s.selected.contains(i), onChanged: (_) => svc.toggle(i)) : const SizedBox(width: 40),
              title: Row(children: [
                Flexible(child: Text(r.item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text, fontWeight: FontWeight.w600))),
                if (r.item.country != null) Text('  ${r.item.country}', style: TextStyle(color: c.textMuted, fontSize: 12)),
                if (r.item.quality != null) Text('  ${r.item.quality}', style: TextStyle(color: c.textMuted, fontSize: 12)),
                if (r.possibleDuplicateOf != null) Padding(padding: const EdgeInsetsDirectional.only(start: Space.sm), child: Pill(t.imPossibleDup, healthColor('degraded'))),
              ]),
              subtitle: Text(
                '${r.why} · ${r.item.group ?? ''} · ${maskCredentials(r.item.url)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: c.textMuted, fontSize: 11.5),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ── 4. التقرير ────────────────────────────────────────────────────────────
class _DoneStep extends ConsumerWidget {
  final ImportState state;
  const _DoneStep({required this.state});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final d = state.done ?? const {};
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.task_alt_rounded, size: 48, color: healthColor('playable')),
        const SizedBox(height: Space.md),
        Text(t.imDone, style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.sm),
        Text(t.imResult(d['channels'] ?? 0, d['streams'] ?? 0, d['disabled'] ?? 0), style: TextStyle(color: c.textMuted)),
        const SizedBox(height: Space.lg),
        Wrap(spacing: Space.sm, children: [
          FilledButton.icon(onPressed: () => context.go('/admin/review'), icon: const Icon(Icons.fact_check_rounded), label: Text(t.imGoReview)),
          OutlinedButton(onPressed: ref.read(importProvider.notifier).reset, child: Text(t.imNew)),
        ]),
      ]),
    );
  }
}
