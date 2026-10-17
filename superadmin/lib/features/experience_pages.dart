// Section 6 — Viewer experience & messaging.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/preview_dialog.dart';
import '../ui/widgets.dart';
import 'common.dart';

class ViewerHomePage extends ConsumerStatefulWidget {
  const ViewerHomePage({super.key});
  @override
  ConsumerState<ViewerHomePage> createState() => _ViewerHomePageState();
}

class _ViewerHomePageState extends ConsumerState<ViewerHomePage> {
  final _rows = <Tr>[
    const Tr('يعرض الآن', 'On now'),
    const Tr('المفضلة', 'Favorites'),
    const Tr('أخبار', 'News'),
    const Tr('رياضة', 'Sports'),
    const Tr('أطفال', 'Kids'),
    const Tr('قائمة مختارة: رمضان (من 1 لـ 30)', 'Curated: Ramadan (1 → 30)'),
  ];
  String _device = 'tv';
  bool _dirty = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ServicePage(
      page: Nav.experience.pages[0],
      actions: [
        FilledButton(
          onPressed: !_dirty
              ? null
              : () => confirmAndRun(
                  context,
                  ref,
                  title: const Tr('حفظ صفوف الرئيسية', 'Save home rows'),
                  spec: Rpc.homeLayoutSet,
                  affected: _rows.length,
                  unit: const Tr('صف', 'rows'),
                  run: (r) => ref.read(experienceRepoProvider).saveSettings('home', {
                    'rows': [for (final x in _rows) x.en],
                  }, reason: r),
                ),
          child: Text(context.tr(const Tr('حفظ', 'Save'))),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 380,
            child: Panel(
              title: const Tr('الصفوف (اسحب للترتيب)', 'Rows (drag to reorder)'),
              child: SizedBox(
                height: 420,
                child: ReorderableListView(
                  onReorderItem: (a, b) => setState(() {
                    final x = _rows.removeAt(a);
                    _rows.insert(b, x);
                    _dirty = true;
                  }),
                  children: [for (final r in _rows) ListTile(key: ValueKey(r.en), leading: const Icon(Icons.drag_indicator), title: Text(context.tr(r)))],
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Panel(
              title: const Tr('معاينة حيّة', 'Live preview'),
              actions: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'phone', icon: const Icon(Icons.smartphone, size: 16), label: Text(context.tr(const Tr('جوال', 'Phone')))),
                    ButtonSegment(value: 'desktop', icon: const Icon(Icons.computer, size: 16), label: Text(context.tr(const Tr('كمبيوتر', 'Desktop')))),
                    ButtonSegment(value: 'tv', icon: const Icon(Icons.tv, size: 16), label: Text(context.tr(const Tr('تلفزيون', 'TV')))),
                  ],
                  selected: {_device},
                  onSelectionChanged: (s) => setState(() => _device = s.first),
                ),
              ],
              child: Center(
                child: Container(
                  width: _device == 'phone' ? 240 : (_device == 'desktop' ? 520 : 600),
                  height: _device == 'phone' ? 420 : 320,
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: c.line2, width: 3),
                  ),
                  child: ListView(
                    children: [
                      for (final r in _rows) ...[
                        Text(context.tr(r), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < 8; i++)
                                Container(
                                  width: 72,
                                  margin: const EdgeInsetsDirectional.only(end: 6),
                                  decoration: BoxDecoration(gradient: c.brandGradient.scale(0.35 + (i % 3) * 0.2), borderRadius: BorderRadius.circular(6)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.sm),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaxonomyPage extends StatelessWidget {
  const TaxonomyPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.experience.pages[1],
    source: (ref) => ref.read(experienceRepoProvider).taxonomy,
    header: Text(
      context.tr(
        const Tr(
          'الحذف ممنوع إذا في قنوات مستخدمة التقسيم (بيقلك كم قناة). فيك تخفيه بدلًا من هيك.',
          'Deleting is blocked while channels use the entry (it tells you how many). Hide it instead.',
        ),
      ),
      style: TextStyle(color: context.colors.textMuted),
    ),
    columns: const [
      RowColumn('kind', Tr('النوع', 'Kind')),
      RowColumn('ar', Tr('بالعربي', 'Arabic'), flex: 2),
      RowColumn('en', Tr('بالإنجليزي', 'English'), flex: 2),
      RowColumn('visible', Tr('ظاهر', 'Visible')),
      RowColumn('channels', Tr('قنوات', 'Channels')),
    ],
    filters: const [
      FilterDef('kind', Tr('النوع', 'Kind'), [
        FilterOption('category', Tr('فئة', 'Category')),
        FilterOption('country', Tr('دولة', 'Country')),
        FilterOption('language', Tr('لغة', 'Language')),
      ]),
    ],
    actions: [
      Consumer(
        builder: (context, ref, _) => FilledButton.icon(
          onPressed: () => confirmAndRun(
            context,
            ref,
            title: const Tr('إضافة تقسيم', 'Add entry'),
            spec: Rpc.taxonomyUpsert,
            run: (r) => ref.read(experienceRepoProvider).saveTaxonomy(const {}, reason: r),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr(const Tr('إضافة', 'Add'))),
        ),
      ),
    ],
  );
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _text = TextEditingController();
  final _link = TextEditingController();
  String _target = 'all';

  @override
  void dispose() {
    _text.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targets = {
      'all': const Tr('كل المشاهدين', 'All viewers'),
      'android': const Tr('أندرويد', 'Android'),
      'windows': const Tr('ويندوز', 'Windows'),
      'tv': const Tr('التلفزيون', 'TV'),
      'country': const Tr('دولة…', 'Country…'),
      'version': const Tr('إصدار…', 'Version…'),
    };
    return ServicePage(
      page: Nav.experience.pages[2],
      scroll: true,
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldRow(
              label: const Tr('النص', 'Text'),
              field: TextField(controller: _text, maxLines: 3, onChanged: (_) => setState(() {})),
            ),
            FieldRow(
              label: const Tr('رابط (اختياري)', 'Link (optional)'),
              help: const Tr('مثلًا قناة', 'e.g. a channel'),
              field: TextField(controller: _link, textDirection: TextDirection.ltr),
            ),
            FieldRow(
              label: const Tr('الاستهداف', 'Target'),
              field: Wrap(
                spacing: 6,
                children: [
                  for (final e in targets.entries)
                    ChoiceChip(label: Text(context.tr(e.value)), selected: _target == e.key, onSelected: (_) => setState(() => _target = e.key)),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const ValueKey('notify-send'),
                onPressed: _text.text.trim().isEmpty
                    ? null
                    : () => previewAndRun(
                        context,
                        ref,
                        OperationPreview(
                          title: const Tr('إرسال إشعار', 'Send notification'),
                          confirmLabel: const Tr('أرسل', 'Send'),
                          affected: _target == 'all' ? 318 : 120,
                          unit: const Tr('جهاز', 'devices'),
                          groups: [
                            PreviewGroup(targets[_target]!, _target == 'all' ? 318 : 120, tone: Tone.info, examples: [_text.text]),
                          ],
                          undoClass: Rpc.notificationSend.undoClass,
                          // "All" needs an explicit typed confirmation (plan §6 6.3).
                          typedConfirm: _target == 'all',
                          needsRecentMfa: true,
                        ),
                        (r) => ref.read(experienceRepoProvider).sendNotification({'text': _text.text, 'link': _link.text, 'target': _target}, reason: r),
                      ),
                icon: const Icon(Icons.send, size: 18),
                label: Text(context.tr(const Tr('معاينة وإرسال', 'Preview and send'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsFormPage(
    page: Nav.experience.pages[3],
    group: 'announcement',
    spec: Rpc.announcementUpsert,
    fields: const [
      SettingField('text', Tr('النص', 'Text'), kind: SettingKind.multiline),
      SettingField(
        'color',
        Tr('اللون', 'Colour'),
        kind: SettingKind.choice,
        options: [FilterOption('accent', Tr('هوية MTC', 'Brand')), FilterOption('info', Tr('أزرق', 'Blue')), FilterOption('warn', Tr('برتقالي', 'Amber'))],
      ),
      SettingField('days', Tr('المدة (أيام)', 'Duration (days)'), kind: SettingKind.number),
      SettingField('dismissible', Tr('قابل للإغلاق', 'Dismissible'), kind: SettingKind.toggle),
    ],
  );
}

class BrandingPage extends StatelessWidget {
  const BrandingPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsFormPage(
    page: Nav.experience.pages[4],
    group: 'branding',
    spec: Rpc.settingsSet,
    fields: const [
      SettingField('app_name', Tr('اسم التطبيق', 'App name')),
      SettingField('developer', Tr('اسم المطوّر (بالانترو)', 'Developer name (intro)')),
      SettingField(
        'default_lang',
        Tr('اللغة الافتراضية', 'Default language'),
        kind: SettingKind.choice,
        options: [FilterOption('ar', Tr('العربية', 'Arabic')), FilterOption('en', Tr('English', 'English'))],
      ),
      SettingField(
        'default_theme',
        Tr('الثيم الافتراضي', 'Default theme'),
        kind: SettingKind.choice,
        options: [FilterOption('dark', Tr('داكن', 'Dark')), FilterOption('light', Tr('فاتح', 'Light'))],
      ),
      SettingField('facebook', Tr('فيسبوك', 'Facebook')),
      SettingField('telegram', Tr('تيليجرام', 'Telegram')),
    ],
  );
}

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsFormPage(
    page: Nav.experience.pages[5],
    group: 'player',
    spec: Rpc.settingsSet,
    fields: const [
      SettingField('start_timeout_s', Tr('مهلة البدء (ثواني)', 'Start timeout (s)'), kind: SettingKind.number),
      SettingField('retries_before_switch', Tr('محاولات قبل سيرفر تاني', 'Retries before switching server'), kind: SettingKind.number),
      SettingField(
        'max_quality',
        Tr('الجودة القصوى الافتراضية', 'Default max quality'),
        kind: SettingKind.choice,
        options: [FilterOption('720p', Tr('720p', '720p')), FilterOption('1080p', Tr('1080p', '1080p')), FilterOption('2160p', Tr('4K', '4K'))],
      ),
    ],
  );
}

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsFormPage(
    page: Nav.experience.pages[6],
    group: 'features',
    spec: Rpc.settingsSet,
    fields: const [
      SettingField('reports', Tr('زر البلاغ بالمشغّل', 'Report button in player'), kind: SettingKind.toggle),
      SettingField('synced_favorites', Tr('المفضلة المتزامنة', 'Synced favorites'), kind: SettingKind.toggle),
      SettingField('maintenance', Tr('وضع الصيانة', 'Maintenance mode'), kind: SettingKind.toggle),
      SettingField('maintenance_block', Tr('منع المشاهدة مؤقتًا', 'Block playback temporarily'), kind: SettingKind.toggle),
      SettingField('maintenance_message', Tr('رسالة الصيانة', 'Maintenance message'), kind: SettingKind.multiline),
    ],
  );
}

class ReleasesPage extends StatelessWidget {
  const ReleasesPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsFormPage(
    page: Nav.experience.pages[7],
    group: 'releases',
    spec: Rpc.releaseSet,
    fields: const [
      SettingField('windows', Tr('آخر نسخة ويندوز', 'Latest Windows')),
      SettingField('android', Tr('آخر نسخة أندرويد', 'Latest Android')),
      SettingField('tv', Tr('آخر نسخة تلفزيون', 'Latest TV')),
      SettingField('min_supported', Tr('أقل نسخة مسموحة (أقدم = تحديث إجباري)', 'Minimum supported (older = forced update)')),
    ],
  );
}
