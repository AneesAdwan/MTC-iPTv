// ADM-D1 قيد المراجعة (§9.6): نفس دلاء اللوحة القديمة (العرض review_queue في الإنتاج):
// لم تُفحص، جاهزة، مكررة، لا تعمل، شعار معطّل، ناقصة — مع فحص الدلو، وقبول/رفض/دمج فردي وجماعي.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/layout/h_scroller.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/health_service.dart';
import '../viewer/widgets/channel_card.dart' show EmptyState;
import 'channels/channels_admin_screen.dart';
import 'channels/stream_preview.dart';
import 'dashboard_screen.dart';
import 'decisions_dialog.dart';
import 'widgets/admin_widgets.dart';

const reviewBuckets = ['ready', 'unchecked', 'duplicate', 'offline', 'logo', 'incomplete'];

final _reviewCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async => await ref.watch(adminRepoProvider)?.reviewCounts() ?? const {});
final _reviewPageProvider = FutureProvider.autoDispose.family<(List<Map<String, dynamic>>, int, Map<String, String>), (String, int)>((ref, k) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return (const <Map<String, dynamic>>[], 0, const <String, String>{});
  final (rows, total) = await repo.reviewItems(k.$1, page: k.$2);
  final originals = await repo.channelNames([
    for (final r in rows)
      if (r['duplicate_of'] != null) r['duplicate_of'] as String,
  ]);
  return (rows, total, originals);
});

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String? bucket;
  int page = 0;
  final selected = <String>{};
  bool busy = false;

  (String, String, IconData, Color) _meta(L10n t, String b) => switch (b) {
    'ready' => (t.bkReady, t.bkReadyHint, Icons.check_circle_rounded, healthColor('playable')),
    'unchecked' => (t.bkUnchecked, t.bkUncheckedHint, Icons.help_rounded, healthColor('reachable')),
    'duplicate' => (t.bkDuplicate, t.bkDuplicateHint, Icons.copy_all_rounded, healthColor('degraded')),
    'offline' => (t.bkOffline, t.bkOfflineHint, Icons.cancel_rounded, healthColor('unavailable')),
    'logo' => (t.bkLogo, t.bkLogoHint, Icons.broken_image_rounded, healthColor('geo_restricted')),
    _ => (t.bkIncomplete, t.bkIncompleteHint, Icons.edit_note_rounded, healthColor('inconclusive')),
  };

  void _reload() {
    ref.invalidate(_reviewCountsProvider);
    ref.invalidate(_reviewPageProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(adminChannelsProvider);
    selected.clear();
  }

  Future<void> _do(Future<int> Function(AdminRepository r) f) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final t = L10n.of(context);
    setState(() => busy = true);
    try {
      final n = await f(repo);
      if (mounted) toast(context, t.doneCount(n));
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          _reload();
        });
      }
    }
  }

  /// فحص تشغيل فعلي (لا وصول فقط): الفحص السريع كان يعطي «غير حاسم» فتبقى القناة في «لم تُفحص» للأبد
  /// (inconclusive ← status unknown). يكمل في الخلفية، والدلاء تُحدَّث عند انتهائه.
  Future<void> _check(Future<List<String>> Function() ids) async {
    // يُقرأ قبل الانتظار: قد يغادر المدير الشاشة أثناء جلب الروابط
    final repo = ref.read(adminRepoProvider);
    final health = ref.read(healthJobProvider.notifier);
    if (repo == null) return;
    final streams = [for (final id in await ids()) ...await repo.streamsOf(id)];
    health.run(streams, playCheck: true);
  }

  /// تعيين الدولة أو الفئة لعدة قنوات دفعة واحدة (دلو «ناقصة»: 298 قناة بلا دولة في الإنتاج، 2026-10-16).
  Future<void> _assign(String field, String title, List<String> ids) async {
    final lang = Localizations.localeOf(context).languageCode;
    final refs = await ref.read(adminRefProvider.future);
    if (!mounted) return;
    final list = field == 'country_code' ? refs.$1 : refs.$2;
    final key = field == 'country_code' ? 'code' : 'slug';
    final v = await showDialog<String>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text(title),
        children: [
          SizedBox(
            width: 360,
            height: 420,
            child: ListView(
              children: [for (final x in list) ListTile(title: Text('${x['flag_emoji'] ?? ''} ${lang == 'ar' ? x['name_ar'] : x['name_en']}'.trim()), onTap: () => Navigator.pop(d, x[key] as String))],
            ),
          ),
        ],
      ),
    );
    if (v == null) return;
    await _do((r) async {
      await r.updateChannels(ids, {field: v});
      return ids.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final counts = ref.watch(_reviewCountsProvider).value;
    final job = ref.watch(healthJobProvider);
    ref.listen(healthJobProvider, (prev, next) {
      if (prev?.running == true && !next.running) setState(_reload);
    });
    if (counts == null) return const Center(child: CircularProgressIndicator());
    if (counts.values.every((n) => n == 0)) return EmptyState(icon: Icons.task_alt_rounded, title: t.reviewEmpty);
    final b = bucket ?? reviewBuckets.firstWhere((x) => (counts[x] ?? 0) > 0, orElse: () => 'ready');
    final (title, hint, icon, color) = _meta(t, b);
    final pageData = ref.watch(_reviewPageProvider((b, page)));
    final rows = pageData.value?.$1 ?? const <Map<String, dynamic>>[];
    final total = pageData.value?.$2 ?? 0;
    final originals = pageData.value?.$3 ?? const <String, String>{};
    final ids = selected.toList();
    final approveAllowed = b != 'offline' && b != 'unchecked';

    Future<List<String>> allIds() async => await ref.read(adminRepoProvider)?.reviewIds(b) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HScroller.children(
          height: 56,
          spacing: 0,
          children: [
            for (final x in reviewBuckets)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.sm),
                child: ChoiceChip(
                  avatar: Icon(_meta(t, x).$3, size: 16, color: _meta(t, x).$4),
                  label: Text('${_meta(t, x).$1}  ${counts[x] ?? 0}'),
                  selected: b == x,
                  onSelected: (_) => setState(() {
                    bucket = x;
                    page = 0;
                    selected.clear();
                  }),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: color.withValues(alpha: .35)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text('$title — $hint', style: TextStyle(color: c.text)),
                ),
              ],
            ),
          ),
        ),
        // إجراءات الدلو كله
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (b == 'unchecked' || b == 'offline')
                FilledButton.icon(
                  onPressed: job.running || busy ? null : () => _check(allIds),
                  icon: const Icon(Icons.monitor_heart_rounded),
                  label: Text('${t.aCheckStreams} · ${t.aAllInBucket(counts[b] ?? 0)}'),
                ),
              if (approveAllowed)
                FilledButton.icon(
                  onPressed: busy ? null : () => _do((r) async => r.reviewApply('approve', await allIds())),
                  icon: const Icon(Icons.done_all_rounded),
                  label: Text('${t.aApprove} · ${t.aAllInBucket(counts[b] ?? 0)}'),
                ),
              if (b == 'duplicate')
                OutlinedButton(onPressed: busy ? null : () => _do((r) async => r.reviewApply('merge', await allIds())), child: Text('${t.aMerge} · ${t.aAllInBucket(counts[b] ?? 0)}')),
              if (job.running) Text(t.checkRunning(job.done, job.total), style: TextStyle(color: c.textMuted)),
            ],
          ),
        ),
        // التحديد (المعروض / كل الدلو / عكس) وإجراءات المحدد
        SelectionBar(
          selected: selected,
          pageIds: [for (final r in rows) r['id'] as String],
          total: total,
          allIds: allIds,
          busy: busy,
          onChanged: () => setState(() {}),
          actions: [
            if (approveAllowed) OutlinedButton(onPressed: busy ? null : () => _do((r) => r.reviewApply('approve', ids)), child: Text(t.aApprove)),
            OutlinedButton.icon(onPressed: busy || job.running ? null : () => _check(() async => ids), icon: const Icon(Icons.monitor_heart_rounded, size: 18), label: Text(t.aCheckStreams)),
            OutlinedButton(onPressed: busy ? null : () => _assign('country_code', t.aSetCountry, ids), child: Text(t.aSetCountry)),
            OutlinedButton(onPressed: busy ? null : () => _assign('category_slug', t.aSetCategory, ids), child: Text(t.aSetCategory)),
            if (b == 'duplicate') ...[
              OutlinedButton(onPressed: busy ? null : () => _do((r) => r.reviewApply('merge', ids)), child: Text(t.aMerge)),
              OutlinedButton(onPressed: busy ? null : () => _do((r) => r.markDistinct(ids)), child: Text(t.aNotDuplicate)),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
              onPressed: busy
                  ? null
                  : () async {
                      if (await confirm(context, t.confirmReject(ids.length))) await _do((r) => r.reviewApply('reject', ids));
                    },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(t.aReject),
            ),
          ],
        ),
        if (job.running) LinearProgressIndicator(value: job.progress, minHeight: 2) else if (pageData.isLoading || busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            itemCount: rows.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
            itemBuilder: (_, i) {
              final r = rows[i];
              final id = r['id'] as String;
              final ok = (r['online'] as num?)?.toInt() ?? 0, n = (r['total'] as num?)?.toInt() ?? 0;
              final dup = r['duplicate_of'] as String?;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(value: selected.contains(id), onChanged: (v) => setState(() => v == true ? selected.add(id) : selected.remove(id))),
                    SizedBox(
                      width: 40,
                      height: 30,
                      child: r['logo_url'] == null
                          ? Icon(Icons.image_not_supported_outlined, size: 18, color: c.textDim)
                          : Image.network(
                              '${r['logo_url']}',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(Icons.broken_image_rounded, size: 18, color: healthColor('unavailable')),
                            ),
                    ),
                  ],
                ),
                title: Text(
                  '${r['name']}',
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    '${r['uid']}',
                    [r['category_slug'], r['country_code']].whereType<String>().join(' / '),
                    if (dup != null) t.originalOf(originals[dup] ?? dup),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Pill(t.streamsWorking(ok, n), ok > 0 ? healthColor('playable') : healthColor(n == 0 ? 'unavailable' : 'inconclusive')),
                    if (dup != null)
                      IconButton(
                        tooltip: t.dcOpen,
                        onPressed: () async {
                          if (await showDecisions(context, [dup, id])) setState(_reload);
                        },
                        icon: const Icon(Icons.rule_rounded),
                      ),
                    IconButton(tooltip: t.aTry, onPressed: n == 0 ? null : () => previewChannel(context, ref, id, '${r['name']}'), icon: const Icon(Icons.play_circle_outline_rounded)),
                    IconButton(tooltip: t.aOpenChannel, onPressed: () => context.go('/admin/channel/$id'), icon: const Icon(Icons.open_in_new_rounded)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
          child: Row(
            children: [
              Text(total == 0 ? '' : t.pageOf(page * 50 + 1, page * 50 + rows.length, total), style: TextStyle(color: c.textMuted)),
              const Spacer(),
              IconButton(onPressed: page == 0 ? null : () => setState(() => page--), icon: const Icon(Icons.chevron_left_rounded)),
              IconButton(onPressed: page * 50 + rows.length >= total ? null : () => setState(() => page++), icon: const Icon(Icons.chevron_right_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}
