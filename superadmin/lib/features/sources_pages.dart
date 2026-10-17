// Section 4 — Sources: one-click hub, import, connectors, monitoring, enrichment, rules, export, licensing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../data/sample/sample_data.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/preview_dialog.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

class SourcesHubPage extends ConsumerWidget {
  const SourcesHubPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(sourcesRepoProvider);
    return ServicePage(
      page: Nav.sources.pages[0],
      scroll: true,
      child: AsyncView<List<SourceCard>>(
        load: repo.sources,
        builder: (context, cards, _) => Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [for (final s in cards) SizedBox(width: 380, child: _SourceCardView(s: s))],
        ),
      ),
    );
  }
}

class _SourceCardView extends ConsumerWidget {
  final SourceCard s;
  const _SourceCardView({required this.s});

  Future<void> _fetch(BuildContext context, WidgetRef ref) async {
    final scope = await showDialog<Map<String, String>>(context: context, builder: (_) => const _ScopeDialog());
    if (scope == null || !context.mounted) return;
    await confirmAndRun(
      context,
      ref,
      title: Tr('جلب القنوات: ${s.name}', 'Fetch channels: ${s.name}'),
      spec: Rpc.sourceFetch,
      unit: const Tr('مصدر', 'source'),
      confirmLabel: const Tr('جلب القنوات', 'Fetch channels'),
      groups: [
        for (final e in scope.entries) PreviewGroup(Tr(e.key, e.key), 1, examples: [e.value]),
        const PreviewGroup(Tr('ولا شي بيتنشر قبل موافقتك (D-14)', 'Nothing is published before you approve (D-14)'), 0, tone: Tone.ok),
      ],
      run: (r) => ref.read(sourcesRepoProvider).fetch(s.id, scope, reason: r),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    Widget n(Tr l, int v, Tone t) => Column(
      children: [
        Text(
          fmtInt(v),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.tone(t)),
        ),
        Text(context.tr(l), style: TextStyle(color: c.textDim, fontSize: 11.5)),
      ],
    );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.name,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              if (s.paused) Pill(context.tr(const Tr('موقوف', 'Paused')), tone: Tone.warn),
              const SizedBox(width: Space.xs),
              Pill(
                context.tr(s.connected ? const Tr('متصل', 'Connected') : const Tr('فشل الاتصال', 'Connection failed')),
                tone: s.connected ? Tone.ok : Tone.bad,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('${context.tr(s.kind)} · ${context.tr(s.schedule)}', style: TextStyle(color: c.textMuted)),
          Text(
            context.tr(
              Tr(
                'آخر جلب ناجح: ${s.lastSuccess == null ? '—' : fmtDateTime(s.lastSuccess!)}',
                'Last successful fetch: ${s.lastSuccess == null ? '—' : fmtDateTime(s.lastSuccess!)}',
              ),
            ),
            style: TextStyle(color: c.textDim, fontSize: 12),
          ),
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              n(const Tr('جديدة', 'New'), s.fresh, Tone.accent),
              n(const Tr('موجودة', 'Existing'), s.existing, Tone.neutral),
              n(const Tr('بدها مراجعة', 'To review'), s.review, Tone.warn),
              n(const Tr('غير صالحة', 'Invalid'), s.invalid, Tone.bad),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              FilledButton.icon(
                onPressed: s.paused ? null : () => _fetch(context, ref),
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(context.tr(const Tr('جلب الآن', 'Fetch now'))),
              ),
              OutlinedButton(
                onPressed: () => context.go(Uri(path: '/sources/monitoring', queryParameters: {'source': s.name}).toString()),
                child: Text(context.tr(const Tr('السجل', 'Log'))),
              ),
              OutlinedButton(
                onPressed: () => confirmAndRun(
                  context,
                  ref,
                  title: s.paused ? Tr('إعادة تفعيل ${s.name}', 'Resume ${s.name}') : Tr('إيقاف ${s.name}', 'Pause ${s.name}'),
                  spec: Rpc.sourcePause,
                  unit: const Tr('مصدر', 'source'),
                  run: (r) => ref.read(sourcesRepoProvider).setPaused(s.id, !s.paused, reason: r),
                ),
                child: Text(context.tr(s.paused ? const Tr('أعد التفعيل', 'Resume') : const Tr('أوقف', 'Pause'))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeDialog extends StatefulWidget {
  const _ScopeDialog();
  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  final _countries = <String>{'PS', 'JO'};
  String? _category = 'news';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(const Tr('النطاق', 'Scope'))),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(const Tr('الدول', 'Countries'))),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in sampleCountries.entries)
                FilterChip(
                  label: Text(context.tr(e.value)),
                  selected: _countries.contains(e.key),
                  onSelected: (v) => setState(() => v ? _countries.add(e.key) : _countries.remove(e.key)),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(labelText: context.tr(const Tr('الفئة', 'Category'))),
            items: [
              DropdownMenuItem(value: null, child: Text(context.tr(const Tr('الكل', 'All')))),
              for (final e in sampleCategories.entries) DropdownMenuItem(value: e.key, child: Text(context.tr(e.value))),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(const Tr('إلغاء', 'Cancel')))),
      FilledButton(
        onPressed: _countries.isEmpty ? null : () => Navigator.pop(context, {'countries': _countries.join(','), 'category': ?_category}),
        child: Text(context.tr(const Tr('متابعة', 'Continue'))),
      ),
    ],
  );
}

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});
  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  int _step = 0;
  String _kind = 'url';
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ServicePage(
      page: Nav.sources.pages[1],
      scroll: true,
      child: Panel(
        child: Stepper(
          currentStep: _step,
          physics: const NeverScrollableScrollPhysics(),
          onStepTapped: (i) => setState(() => _step = i),
          controlsBuilder: (context, d) => Padding(
            padding: const EdgeInsets.only(top: Space.md),
            child: Row(
              children: [
                if (_step < 3) FilledButton(onPressed: d.onStepContinue, child: Text(context.tr(const Tr('التالي', 'Next')))),
                if (_step == 3)
                  FilledButton(
                    onPressed: () => confirmAndRun(
                      context,
                      ref,
                      title: const Tr('قبول دفعة الاستيراد', 'Accept import batch'),
                      spec: Rpc.importCommit,
                      affected: 230,
                      unit: const Tr('سطر', 'lines'),
                      groups: const [
                        PreviewGroup(Tr('جديدة ← مركز القرارات', 'New → decision center'), 180, tone: Tone.accent),
                        PreviewGroup(Tr('رابط إضافي لقناة موجودة', 'Extra stream for an existing channel'), 50, tone: Tone.info),
                      ],
                      run: (r) => ref.read(sourcesRepoProvider).stageImport({'kind': _kind, 'url': _url.text}, reason: r),
                    ),
                    child: Text(context.tr(const Tr('قبول', 'Accept'))),
                  ),
                const SizedBox(width: Space.sm),
                if (_step > 0) TextButton(onPressed: d.onStepCancel, child: Text(context.tr(const Tr('رجوع', 'Back')))),
              ],
            ),
          ),
          onStepContinue: () => setState(() => _step = (_step + 1).clamp(0, 3)),
          onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 3)),
          steps: [
            Step(
              title: Text(context.tr(const Tr('المصدر', 'Input'))),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'file', label: Text(context.tr(const Tr('ملف M3U', 'M3U file')))),
                      ButtonSegment(value: 'url', label: Text(context.tr(const Tr('رابط قائمة', 'Playlist URL')))),
                      const ButtonSegment(value: 'xtream', label: Text('Xtream')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: Space.md),
                  if (_kind == 'file')
                    Container(
                      height: 110,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line2),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Text(
                        context.tr(
                          const Tr('اسحب الملف هون (بيترفع للخادم والمطابقة بتصير هناك)', 'Drop the file here (uploaded; matching runs on the server)'),
                        ),
                        style: TextStyle(color: c.textMuted),
                      ),
                    )
                  else
                    TextField(
                      controller: _url,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: _kind == 'url' ? 'https://…/playlist.m3u' : 'http://host:port · user · ••••'),
                    ),
                  if (_kind == 'xtream')
                    Padding(
                      padding: const EdgeInsets.only(top: Space.sm),
                      child: Text(
                        context.tr(const Tr('كلمات Xtream بتنحفظ مشفّرة بالخزنة على الخادم.', 'Xtream passwords are stored encrypted in the server vault.')),
                        style: TextStyle(color: c.textDim, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Step(
              title: Text(context.tr(const Tr('التحليل', 'Analysis'))),
              content: Text(
                context.tr(
                  const Tr('1,240 سطر · M3U Plus · 12 بلا اسم · 3 روابط فيها كلمات مرور', '1,240 lines · M3U Plus · 12 unnamed · 3 URLs with credentials'),
                ),
              ),
            ),
            Step(
              title: Text(context.tr(const Tr('المعاينة', 'Preview'))),
              content: Wrap(
                spacing: Space.md,
                children: [
                  Pill(context.tr(const Tr('جديدة 180', 'New 180')), tone: Tone.accent),
                  Pill(context.tr(const Tr('رابط إضافي 50', 'Extra stream 50')), tone: Tone.info),
                  Pill(context.tr(const Tr('موجود أصلًا 960', 'Already present 960')), tone: Tone.neutral),
                  Pill(context.tr(const Tr('فاشل 50', 'Failed 50')), tone: Tone.bad),
                ],
              ),
            ),
            Step(
              title: Text(context.tr(const Tr('القبول', 'Accept'))),
              content: Text(
                context.tr(
                  const Tr(
                    'ولا شي بينكتب قبل هالخطوة. «تراجع عن هالدفعة» بيشيل كل اللي انضاف فيها.',
                    'Nothing is written before this step. "Undo this batch" removes everything it added.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectorsPage extends StatelessWidget {
  const ConnectorsPage({super.key});
  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'P0',
        'iptv-org/iptv',
        Tr('بث مجتمعي', 'Community streams'),
        Tr('المصدر الأساسي، بنطاقات جاهزة (دولة، لغة، منطقة، فئة)', 'Primary source with ready scopes (country, language, region, category)'),
        Tone.ok,
      ),
      (
        'P1',
        'Free-TV/IPTV',
        Tr('بث مجتمعي', 'Community streams'),
        Tr('مصدر تاني لاكتشاف قنوات ناقصة، بدون نسخ مكررة', 'Second source to find missing channels, no duplicates'),
        Tone.info,
      ),
      (
        'P1',
        'iptv-org/database',
        Tr('بيانات قنوات', 'Channel metadata'),
        Tr('مش مصدر بث: بيغذّي تحسين البيانات والمطابقة', 'Not a stream source: feeds enrichment and matching'),
        Tone.info,
      ),
      (
        'P1',
        'iptv-org/epg',
        Tr('دليل برامج', 'Program guide'),
        Tr('مسار منفصل بقسم الدليل؛ فشله ما بيأثر عالقنوات', 'Separate path in the guide section; its failure never affects channels'),
        Tone.info,
      ),
      (
        'P2',
        Tr('مواقع رسمية', 'Official sites'),
        Tr('رسمي', 'Official'),
        Tr('قناة قناة وبس إذا الشروط بتسمح', 'Channel by channel, only when terms allow'),
        Tone.neutral,
      ),
      (
        'P3',
        'FAST (Pluto, Samsung TV Plus, Roku)',
        Tr('—', '—'),
        Tr('ما بننفّذها إلا بطريقة رسمية مسموحة', 'Not implemented unless an official, allowed method exists'),
        Tone.bad,
      ),
    ];
    final c = context.colors;
    return ServicePage(
      page: Nav.sources.pages[2],
      scroll: true,
      child: Panel(
        child: Column(
          children: [
            for (final r in rows)
              ListTile(
                leading: Pill(r.$1, tone: r.$5),
                title: Text(r.$2 is Tr ? context.tr(r.$2 as Tr) : '${r.$2}', textDirection: r.$2 is String ? TextDirection.ltr : null),
                subtitle: Text('${context.tr(r.$3)} · ${context.tr(r.$4)}', style: TextStyle(color: c.textMuted)),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Text(
                context.tr(
                  const Tr(
                    'كل موصل بيمر بنفس المحرّك: فحص الاتصال · جلب · تحليل · توحيد · تحقق · مقارنة · مرحلة انتظار · نشر المعتمد · متابعة الصحة.',
                    'Every connector runs the same engine: connect · fetch · parse · normalise · validate · compare · stage · publish approved · health.',
                  ),
                ),
                style: TextStyle(color: c.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonitoringPage extends ConsumerWidget {
  const MonitoringPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => RecordsTablePage(
    page: Nav.sources.pages[3],
    source: (ref) => ref.read(sourcesRepoProvider).runs,
    header: Panel(
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: context.colors.ok),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              context.tr(
                const Tr(
                  '🛡 حماية «القائمة الفاضية فجأة» شغالة: إذا حجم مصدر نزل بشكل غير طبيعي، العملية بتوقف لحالها وولا شي بيتعطّل أو بينخفى.',
                  '🛡 "Suddenly empty list" guard is on: if a source shrinks abnormally the run stops by itself and nothing is disabled or hidden.',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    columns: const [
      RowColumn('source', Tr('المصدر', 'Source'), flex: 2),
      RowColumn('started', Tr('بلّشت', 'Started'), flex: 2),
      RowColumn('by', Tr('مين', 'By')),
      RowColumn('downloaded', Tr('نزل', 'Downloaded')),
      RowColumn('parsed', Tr('انقرأ', 'Parsed')),
      RowColumn('new', Tr('جديدة', 'New')),
      RowColumn('invalid', Tr('غير صالحة', 'Invalid')),
      RowColumn('result', Tr('النتيجة', 'Result'), flex: 2, tone: true),
    ],
    filters: [
      FilterDef('source', const Tr('المصدر', 'Source'), [for (final s in ref.read(sampleDataProvider).sources()) FilterOption(s.name, Tr(s.name, s.name))]),
      const FilterDef('by', Tr('مين بلّشها', 'Started by'), [FilterOption('admin', Tr('إنت', 'You')), FilterOption('schedule', Tr('الجدول', 'Schedule'))]),
    ],
  );
}

class EnrichmentPage extends StatelessWidget {
  const EnrichmentPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.sources.pages[4],
    source: (ref) => ref.read(sourcesRepoProvider).enrichment,
    selectable: true,
    columns: const [
      RowColumn('channel', Tr('القناة', 'Channel'), flex: 2),
      RowColumn('field', Tr('الحقل', 'Field')),
      RowColumn('current', Tr('الحالي', 'Current'), flex: 2),
      RowColumn('suggested', Tr('المقترح', 'Suggested'), flex: 2),
      RowColumn('confidence', Tr('الثقة', 'Confidence')),
    ],
    filters: const [
      FilterDef('field', Tr('الحقل', 'Field'), [
        FilterOption('name_en', Tr('الاسم الرسمي', 'Official name')),
        FilterOption('logo', Tr('الشعار', 'Logo')),
        FilterOption('country', Tr('الدولة', 'Country')),
        FilterOption('language', Tr('اللغة', 'Language')),
        FilterOption('category', Tr('الفئة', 'Category')),
      ]),
    ],
    bulkActions: (context, ref, sel, req) => [
      FilledButton(
        onPressed: () => confirmAndRun(
          context,
          ref,
          title: const Tr('اقبل الاقتراحات', 'Accept suggestions'),
          spec: Rpc.enrichmentApply,
          affected: sel.count,
          unit: const Tr('اقتراح', 'suggestions'),
          run: (r) => ref.read(sourcesRepoProvider).applyEnrichment(sel.snapshot(), true, reason: r),
        ),
        child: Text(context.tr(const Tr('اقبل', 'Accept'))),
      ),
      OutlinedButton(
        onPressed: () => confirmAndRun(
          context,
          ref,
          title: const Tr('ارفض الاقتراحات (ما بترجع)', 'Reject suggestions (never re-suggested)'),
          spec: Rpc.enrichmentApply,
          affected: sel.count,
          unit: const Tr('اقتراح', 'suggestions'),
          run: (r) => ref.read(sourcesRepoProvider).applyEnrichment(sel.snapshot(), false, reason: r),
        ),
        child: Text(context.tr(const Tr('ارفض', 'Reject'))),
      ),
    ],
  );
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.sources.pages[5],
    source: (ref) => ref.read(sourcesRepoProvider).rules,
    columns: const [
      RowColumn('order', Tr('الأولوية', 'Priority')),
      RowColumn('when', Tr('إذا', 'When'), flex: 3),
      RowColumn('then', Tr('بيصير', 'Then'), flex: 3),
      RowColumn('hits', Tr('طبّقت على', 'Applied to')),
    ],
    actions: [
      Consumer(
        builder: (context, ref, _) => FilledButton.icon(
          onPressed: () => confirmAndRun(
            context,
            ref,
            title: const Tr('حفظ القواعد', 'Save rules'),
            spec: Rpc.rulesSave,
            affected: 4,
            unit: const Tr('قاعدة', 'rules'),
            run: (r) => ref.read(sourcesRepoProvider).saveRules(const [], reason: r),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr(const Tr('قاعدة جديدة', 'New rule'))),
        ),
      ),
    ],
  );
}

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String _format = 'm3u';
  bool _workingOnly = true, _bestOnly = false, _noCredentials = true;
  @override
  Widget build(BuildContext context) => ServicePage(
    page: Nav.sources.pages[6],
    scroll: true,
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldRow(
            label: const Tr('الصيغة', 'Format'),
            field: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'm3u', label: Text('M3U')),
                ButtonSegment(value: 'csv', label: Text('CSV')),
                ButtonSegment(value: 'json', label: Text('JSON')),
                ButtonSegment(value: 'xmltv', label: Text('XMLTV')),
              ],
              selected: {_format},
              onSelectionChanged: (s) => setState(() => _format = s.first),
            ),
          ),
          SwitchListTile(
            value: _workingOnly,
            onChanged: (v) => setState(() => _workingOnly = v),
            title: Text(context.tr(const Tr('العاملة فقط', 'Working only'))),
          ),
          SwitchListTile(
            value: _bestOnly,
            onChanged: (v) => setState(() => _bestOnly = v),
            title: Text(context.tr(const Tr('أفضل رابط فقط', 'Best stream only'))),
          ),
          SwitchListTile(
            value: _noCredentials,
            onChanged: (v) => setState(() => _noCredentials = v),
            title: Text(context.tr(const Tr('بدون روابط فيها كلمات مرور', 'Exclude URLs with credentials'))),
          ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.download, size: 18),
              label: Text(context.tr(const Tr('صدّر (بالمرحلة 5)', 'Export (Phase 5)'))),
            ),
          ),
        ],
      ),
    ),
  );
}

class LicensingPage extends StatelessWidget {
  const LicensingPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.sources.pages[7],
    source: (ref) => ref.read(sourcesRepoProvider).blocks,
    header: Panel(
      child: Text(
        context.tr(
          const Tr(
            '🚫 الإيقاف الفوري بيخفي فورًا عن المشاهدين، وبيمنع إعادة الاستيراد، وبيسجّل السبب. ما في تجاوز لحماية أو قيود جغرافية أو رموز جلسات. (توجيه تقني، مش استشارة قانونية.)',
            '🚫 An immediate takedown hides at once from viewers, blocks re-import and records the reason. No bypassing protections, geo-restrictions or session tokens. (Technical guidance, not legal advice.)',
          ),
        ),
      ),
    ),
    columns: const [
      RowColumn('kind', Tr('النوع', 'Kind')),
      RowColumn('target', Tr('الهدف', 'Target'), flex: 3),
      RowColumn('reason', Tr('السبب', 'Reason'), flex: 2),
      RowColumn('at', Tr('التاريخ', 'Date')),
    ],
    actions: [
      Consumer(
        builder: (context, ref, _) => OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: context.colors.bad),
          onPressed: () => confirmAndRun(
            context,
            ref,
            title: const Tr('إيقاف فوري', 'Immediate takedown'),
            spec: Rpc.blockSet,
            run: (r) => ref.read(sourcesRepoProvider).setBlock('stream', '', true, reason: r),
          ),
          icon: const Icon(Icons.block, size: 18),
          label: Text(context.tr(const Tr('إيقاف فوري…', 'Takedown…'))),
        ),
      ),
    ],
  );
}
