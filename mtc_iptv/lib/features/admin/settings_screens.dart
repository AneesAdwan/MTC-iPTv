// المجموعة G — الإعدادات المركزية (§9.9) والمجموعة F — التواصل (§9.8، §14).
// كلها في site_settings العامة: تصل كل الأجهزة في مزامنتها التالية دون إصدار جديد.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/settings_repository.dart';
import '../../data/updates/update_check.dart';
import 'channels/channels_admin_screen.dart' show adminRefProvider;
import 'home_layout_screen.dart' show pickChannel;
import 'settings_form.dart';
import 'widgets/admin_widgets.dart';

const _platforms = ['windows', 'android', 'macos'];

// ── G1 الهوية ──────────────────────────────────────────────────────────────
class BrandScreen extends StatelessWidget {
  const BrandScreen({super.key});
  @override
  Widget build(BuildContext context) => SettingsKeyForm(settingKey: 'brand', groups: [
        FieldGroup((t) => t.g1Identity, [
          FieldSpec('app_name_ar', (t) => t.g1AppNameAr, FieldKind.text, initial: 'MTC-iPTv'),
          FieldSpec('app_name_en', (t) => t.g1AppNameEn, FieldKind.text, initial: 'MTC-iPTv'),
          FieldSpec('about_ar', (t) => t.g1AboutAr, FieldKind.multiline),
          FieldSpec('about_en', (t) => t.g1AboutEn, FieldKind.multiline),
          FieldSpec('credits_ar', (t) => t.g1CreditsAr, FieldKind.text, initial: 'برمجة وتطوير: أنيس عدوان'),
          FieldSpec('credits_en', (t) => t.g1CreditsEn, FieldKind.text, initial: 'Developed by: Anees Adwan'),
        ]),
        FieldGroup((t) => 'MTC-Group', [
          FieldSpec('company_ar', (t) => t.g1CompanyAr, FieldKind.text, initial: 'مجموعة شركات مركز تكنولوجيا الشرق الأوسط — MTC-Group'),
          FieldSpec('company_en', (t) => t.g1CompanyEn, FieldKind.text, initial: 'Middle East Technology Center Group — MTC-Group'),
          FieldSpec('website', (t) => t.g1Website, FieldKind.ltr),
          FieldSpec('email', (t) => t.g1Email, FieldKind.ltr),
        ]),
        FieldGroup((t) => t.g1Legal, [
          FieldSpec('privacy_ar', (t) => t.g1PrivacyAr, FieldKind.multiline, hint: (t) => t.g1PrivacyHint),
          FieldSpec('privacy_en', (t) => t.g1PrivacyEn, FieldKind.multiline),
          FieldSpec('terms_ar', (t) => t.g1TermsAr, FieldKind.multiline),
          FieldSpec('terms_en', (t) => t.g1TermsEn, FieldKind.multiline),
        ]),
      ]);
}

// ── G3 الإعدادات العامة ────────────────────────────────────────────────────
class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final cats = ref.watch(adminRefProvider).value?.$2 ?? const <Map<String, dynamic>>[];
    if (cats.isEmpty) return const Center(child: CircularProgressIndicator());
    return SettingsKeyForm(settingKey: 'general', groups: [
      FieldGroup((t) => t.g3Defaults, [
        FieldSpec('default_language', (t) => t.g3DefaultLang, FieldKind.choice, options: [('ar', (t) => 'العربية'), ('en', (t) => 'English')], initial: 'ar'),
        FieldSpec('default_theme', (t) => t.g3DefaultTheme, FieldKind.choice,
            options: [('dark', (t) => t.themeDark), ('light', (t) => t.themeLight), ('system', (t) => t.themeSystem)], initial: 'dark'),
        FieldSpec('parental_locked_categories', (t) => t.g3ParentalCats, FieldKind.chips,
            options: [for (final c in cats) ('${c['slug']}', (t) => '${lang == 'ar' ? c['name_ar'] : c['name_en']}')]),
      ]),
      FieldGroup((t) => t.g3Catalog, [
        FieldSpec('recent_days', (t) => t.g3RecentDays, FieldKind.integer, initial: 30),
        FieldSpec('attention_days', (t) => t.g3AttentionDays, FieldKind.integer, initial: 7, hint: (t) => t.g3AttentionHint),
        FieldSpec('epg_timezone', (t) => t.g3EpgTz, FieldKind.ltr, initial: 'Asia/Riyadh'),
      ]),
    ]);
  }
}

// ── G4 المشغّل والشبكة ─────────────────────────────────────────────────────
class PlayerSettingsScreen extends StatelessWidget {
  const PlayerSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => SettingsKeyForm(settingKey: 'player', groups: [
        FieldGroup((t) => t.g4Player, [
          FieldSpec('network_timeout_s', (t) => t.g4ConnectTimeout, FieldKind.integer, initial: 15),
          FieldSpec('first_frame_s', (t) => t.g4FirstFrame, FieldKind.integer, initial: 15),
          FieldSpec('stall_s', (t) => t.g4Stall, FieldKind.integer, initial: 6),
          FieldSpec('retry_rounds', (t) => t.g4Retries, FieldKind.integer, initial: 1),
          FieldSpec('cache_s', (t) => t.g4Buffer, FieldKind.integer, initial: 10),
          FieldSpec('user_agent', (t) => t.g4UserAgent, FieldKind.ltr),
          FieldSpec('hwdec', (t) => t.g4Hwdec, FieldKind.toggle, initial: true),
        ]),
        FieldGroup((t) => t.g4Probe, [
          FieldSpec('probe.connect_s', (t) => t.g4ProbeConnect, FieldKind.integer, initial: 8),
          FieldSpec('probe.playlist_s', (t) => t.g4ProbePlaylist, FieldKind.integer, initial: 10),
          FieldSpec('probe.first_frame_s', (t) => t.g4ProbeFrame, FieldKind.integer, initial: 15),
          FieldSpec('probe.per_host', (t) => t.g4PerHost, FieldKind.integer, initial: 4),
          FieldSpec('probe.total', (t) => t.g4Total, FieldKind.integer, initial: 16),
          FieldSpec('probe.ports', (t) => t.g4Ports, FieldKind.ltr, initial: '80,443,8080,8000,25461'),
        ]),
      ]);
}

// ── G5 المزايا ووضع الصيانة ────────────────────────────────────────────────
class FeaturesScreen extends ConsumerStatefulWidget {
  const FeaturesScreen({super.key});
  @override
  ConsumerState<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends ConsumerState<FeaturesScreen> {
  int version = 0; // لإعادة بناء النموذج بعد تعديل قائمة الإيقاف الفوري

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return SettingsKeyForm(
      key: ValueKey(version),
      settingKey: 'features',
      groups: [
        FieldGroup((t) => t.g5Maintenance, [
          FieldSpec('maintenance.enabled', (t) => t.g5MaintOn, FieldKind.toggle, initial: false, hint: (t) => t.g5MaintHint),
          FieldSpec('maintenance.message_ar', (t) => t.g5MsgAr, FieldKind.multiline),
          FieldSpec('maintenance.message_en', (t) => t.g5MsgEn, FieldKind.multiline),
        ]),
        FieldGroup((t) => t.g5Features, [
          FieldSpec('features.guide', (t) => t.sV07, FieldKind.toggle, initial: true),
          FieldSpec('features.reminders', (t) => t.remindMe, FieldKind.toggle, initial: true),
          FieldSpec('features.report', (t) => t.sV12, FieldKind.toggle, initial: true),
          FieldSpec('features.mini_player', (t) => t.g5FMini, FieldKind.toggle, initial: true),
          FieldSpec('catalog_refresh_min', (t) => t.g5Refresh, FieldKind.integer, initial: 60),
          FieldSpec('telemetry_enabled', (t) => t.g5Telemetry, FieldKind.toggle, initial: true),
        ]),
      ],
      footer: SectionCard(
        title: t.g5KillSwitch,
        child: _KillSwitch(onChanged: () => setState(() => version++)),
      ),
    );
  }
}

class _KillSwitch extends ConsumerStatefulWidget {
  final VoidCallback onChanged;
  const _KillSwitch({required this.onChanged});
  @override
  ConsumerState<_KillSwitch> createState() => _KillSwitchState();
}

class _KillSwitchState extends ConsumerState<_KillSwitch> {
  Map<String, dynamic>? features;
  Map<String, String> names = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<String> get ids => [for (final x in ((features?['kill_switch'] as Map?)?['channels'] as List?) ?? const []) '$x'];

  Future<void> _load() async {
    final f = (await ref.read(settingsRepoProvider)?.get('features') as Map?)?.cast<String, dynamic>() ?? {};
    final n = await ref.read(adminRepoProvider)?.channelNames([for (final x in ((f['kill_switch'] as Map?)?['channels'] as List?) ?? const []) '$x']) ?? {};
    if (!mounted) return;
    setState(() {
      features = f;
      names = n;
    });
  }

  Future<void> _save(List<String> next) async {
    final f = {...?features, 'kill_switch': {'channels': next}};
    await ref.read(settingsRepoProvider)?.set('features', f);
    await _load();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    if (features == null) return const LinearProgressIndicator();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.g5KillHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
      const SizedBox(height: Space.sm),
      Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
        for (final id in ids) InputChip(label: Text(names[id] ?? id), onDeleted: () => _save([...ids]..remove(id))),
        ActionChip(
          avatar: const Icon(Icons.block_rounded, size: 16),
          label: Text(t.addChannels),
          onPressed: () async {
            final repo = ref.read(adminRepoProvider);
            if (repo == null) return;
            final ch = await pickChannel(context, repo);
            if (ch != null && !ids.contains(ch.id)) await _save([...ids, ch.id]);
          },
        ),
      ]),
    ]);
  }
}

// ── G2 التواصل الاجتماعي ───────────────────────────────────────────────────
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});
  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  List<Map<String, dynamic>>? links;
  Map<String, dynamic> support = {};
  bool dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepoProvider);
    if (repo == null) return;
    final v = await repo.get('social');
    var l = <Map<String, dynamic>>[];
    if (v is Map) {
      l = [for (final x in (v['links'] as List?) ?? const []) Map<String, dynamic>.from(x as Map)];
      support = Map<String, dynamic>.from((v['support'] as Map?) ?? {});
    }
    if (l.isEmpty) {
      // أول مرة: من مفتاح الموقع القديم developer.social
      final dev = await repo.get('developer');
      final s = (dev is Map ? dev['social'] as Map? : null) ?? {};
      l = [for (final e in s.entries) {'platform': '${e.key}', 'handle': '${e.value}', 'owner': 'developer', 'about': true, 'footer': true, 'splash': false}];
    }
    setState(() => links = l);
  }

  void _upd(int i, String k, Object? v) => setState(() {
        links![i][k] = v;
        dirty = true;
      });

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final l = links;
    if (l == null) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Row(children: [
        FilledButton.tonalIcon(
          onPressed: () => setState(() {
            l.add({'platform': 'facebook', 'handle': '', 'owner': 'mtc_iptv', 'about': true, 'footer': true, 'splash': false});
            dirty = true;
          }),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.addItem),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: !dirty
              ? null
              : () async {
                  try {
                    await ref.read(settingsRepoProvider)?.saveSocial([for (var i = 0; i < l.length; i++) {...l[i], 'order': i, 'handle': cleanHandle('${l[i]['handle']}')}], support);
                    setState(() => dirty = false);
                    if (context.mounted) toast(context, t.saved);
                  } catch (e) {
                    if (context.mounted) toast(context, t.saveFailed('$e'));
                  }
                },
          icon: const Icon(Icons.save_rounded),
          label: Text(t.save),
        ),
      ]),
      const SizedBox(height: Space.md),
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (a, b) => setState(() {
          l.insert(b, l.removeAt(a));
          dirty = true;
        }),
        children: [
          for (var i = 0; i < l.length; i++)
            Card(
              key: ValueKey(l[i]),
              margin: const EdgeInsets.only(bottom: Space.sm),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Wrap(spacing: Space.md, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator_rounded)),
                  DropdownButton<String>(
                    value: '${l[i]['platform']}',
                    items: [for (final p in socialPlatforms) DropdownMenuItem(value: p, child: Text(p))],
                    onChanged: (v) => _upd(i, 'platform', v),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextFormField(
                      initialValue: '${l[i]['handle'] ?? ''}',
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: t.g2Handle, isDense: true),
                      onChanged: (v) => _upd(i, 'handle', v),
                    ),
                  ),
                  DropdownButton<String>(
                    value: '${l[i]['owner'] ?? 'mtc_iptv'}',
                    items: [
                      DropdownMenuItem(value: 'developer', child: Text(t.g2OwnDeveloper)),
                      const DropdownMenuItem(value: 'mtc_group', child: Text('MTC-Group')),
                      const DropdownMenuItem(value: 'mtc_iptv', child: Text('MTC-iPTv')),
                    ],
                    onChanged: (v) => _upd(i, 'owner', v),
                  ),
                  for (final (k, label) in [('about', t.sV11), ('footer', t.g2Footer), ('splash', t.g2Splash)])
                    FilterChip(label: Text(label), selected: l[i][k] == true, onSelected: (v) => _upd(i, k, v)),
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(socialUrl('${l[i]['platform']}', '${l[i]['handle']}')), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(socialUrl('${l[i]['platform']}', '${l[i]['handle']}'), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      l.removeAt(i);
                      dirty = true;
                    }),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.g2Support,
        child: Column(children: [
          for (final k in const ['whatsapp', 'telegram'])
            TextFormField(
              initialValue: '${support[k] ?? ''}',
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: k),
              onChanged: (v) => setState(() {
                support[k] = v.trim().isEmpty ? null : v.trim();
                dirty = true;
              }),
            ),
          Align(alignment: AlignmentDirectional.centerStart, child: Text(t.g2SupportHint, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
        ]),
      ),
    ]);
  }
}

// ── G6 الإصدارات والتحديث ──────────────────────────────────────────────────
class ReleasesScreen extends StatelessWidget {
  const ReleasesScreen({super.key});
  @override
  Widget build(BuildContext context) => SettingsKeyForm(
        settingKey: 'releases',
        groups: [
          FieldGroup((t) => t.sG6, [
            FieldSpec('min_supported', (t) => t.g6MinSupported, FieldKind.ltr, hint: (t) => t.g6MinHint),
            FieldSpec('recommended', (t) => t.g6Recommended, FieldKind.ltr, hint: (t) => t.g6RecHint),
            FieldSpec('url', (t) => t.g6Url, FieldKind.ltr, initial: 'https://github.com/AneesAdwan/MTC-iPTv/releases'),
            FieldSpec('notes_ar', (t) => t.g6NotesAr, FieldKind.multiline),
            FieldSpec('notes_en', (t) => t.g6NotesEn, FieldKind.multiline),
          ]),
        ],
        footer: const _GithubReleases(),
      );
}

class _GithubReleases extends StatefulWidget {
  const _GithubReleases();
  @override
  State<_GithubReleases> createState() => _GithubReleasesState();
}

class _GithubReleasesState extends State<_GithubReleases> {
  String? latest;
  @override
  void initState() {
    super.initState();
    checkForUpdate('0.0.0-alpha.0').then((u) => mounted ? setState(() => latest = u?.version.toString()) : null).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    return Text('${t.g6Github}: ${latest ?? '…'}', textDirection: TextDirection.ltr, style: TextStyle(color: c.textMuted));
  }
}

// ── F2 الإعلانات والشرائط ──────────────────────────────────────────────────
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  List<Map<String, dynamic>>? items;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepoProvider)?.get('announcements').then((v) => setState(() => items = [for (final x in (v as List?) ?? const []) Map<String, dynamic>.from(x as Map)]));
  }

  Future<void> _save() async {
    final t = L10n.of(context);
    try {
      await ref.read(settingsRepoProvider)?.set('announcements', items!);
      if (mounted) toast(context, t.saved);
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    }
  }

  Future<void> _edit([int? i]) async {
    final a = i == null ? <String, dynamic>{'id': DateTime.now().microsecondsSinceEpoch.toString(), 'kind': 'info', 'style': 'banner', 'dismissible': true, 'enabled': true} : Map<String, dynamic>.from(items![i]);
    final r = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _AnnouncementDialog(initial: a));
    if (r == null) return;
    setState(() => i == null ? items!.add(r) : items![i] = r);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final l = items;
    if (l == null) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      Align(alignment: AlignmentDirectional.centerStart, child: FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add_rounded), label: Text(t.addItem))),
      const SizedBox(height: Space.md),
      if (l.isEmpty) Text(t.f2Empty, style: TextStyle(color: c.textMuted)),
      for (var i = 0; i < l.length; i++)
        Card(
          child: ListTile(
            leading: Icon(
              l[i]['kind'] == 'warning' ? Icons.warning_amber_rounded : (l[i]['kind'] == 'maintenance' ? Icons.construction_rounded : Icons.info_outline_rounded),
              color: l[i]['enabled'] == false ? c.textDim : c.accent,
            ),
            title: Text('${l[i]['title_ar'] ?? l[i]['title_en'] ?? ''}'),
            subtitle: Text([
              '${l[i]['style']}',
              if (l[i]['from'] != null || l[i]['to'] != null) '${'${l[i]['from'] ?? '…'}'.split('T').first} → ${'${l[i]['to'] ?? '…'}'.split('T').first}',
              if ((l[i]['platforms'] as List?)?.isNotEmpty ?? false) (l[i]['platforms'] as List).join(', '),
            ].join(' · ')),
            trailing: Wrap(children: [
              Switch(
                value: l[i]['enabled'] != false,
                onChanged: (v) async {
                  setState(() => l[i]['enabled'] = v);
                  await _save();
                },
              ),
              IconButton(onPressed: () => _edit(i), icon: const Icon(Icons.edit_rounded)),
              IconButton(
                onPressed: () async {
                  if (!await confirm(context, t.confirmDelete(1))) return;
                  setState(() => l.removeAt(i));
                  await _save();
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ]),
          ),
        ),
    ]);
  }
}

class _AnnouncementDialog extends StatefulWidget {
  final Map<String, dynamic> initial;
  const _AnnouncementDialog({required this.initial});
  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final a = Map<String, dynamic>.from(widget.initial);
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    Widget tf(String k, String label, {int lines = 1, bool ltr = false}) => TextFormField(
          initialValue: '${a[k] ?? ''}',
          maxLines: lines,
          textDirection: ltr ? TextDirection.ltr : null,
          decoration: InputDecoration(labelText: label),
          onChanged: (v) => a[k] = v.trim().isEmpty ? null : v.trim(),
        );
    final plats = {for (final x in (a['platforms'] as List?) ?? const []) '$x'};
    return AlertDialog(
      title: Text(t.sF2),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: '${a['kind']}',
                  decoration: InputDecoration(labelText: t.f2Kind),
                  items: [
                    DropdownMenuItem(value: 'info', child: Text(t.f2Info)),
                    DropdownMenuItem(value: 'warning', child: Text(t.f2Warning)),
                    DropdownMenuItem(value: 'maintenance', child: Text(t.g5Maintenance)),
                  ],
                  onChanged: (v) => a['kind'] = v,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: '${a['style']}',
                  decoration: InputDecoration(labelText: t.f2Style),
                  items: [DropdownMenuItem(value: 'banner', child: Text(t.f2Banner)), DropdownMenuItem(value: 'dialog', child: Text(t.f2Dialog))],
                  onChanged: (v) => a['style'] = v,
                ),
              ),
            ]),
            tf('title_ar', t.fTitleAr),
            tf('title_en', t.fTitleEn),
            tf('body_ar', t.f2BodyAr, lines: 3),
            tf('body_en', t.f2BodyEn, lines: 3),
            Row(children: [
              Expanded(child: tf('from', '${t.fFrom} (YYYY-MM-DD)', ltr: true)),
              const SizedBox(width: Space.md),
              Expanded(child: tf('to', '${t.fTo} (YYYY-MM-DD)', ltr: true)),
            ]),
            Row(children: [
              Expanded(child: tf('min_version', t.f2MinVersion, ltr: true)),
              const SizedBox(width: Space.md),
              Expanded(child: tf('max_version', t.f2MaxVersion, ltr: true)),
            ]),
            const SizedBox(height: Space.sm),
            StatefulBuilder(
              builder: (c, set) => Wrap(spacing: Space.xs, children: [
                for (final p in _platforms)
                  FilterChip(
                    label: Text(p),
                    selected: plats.contains(p),
                    onSelected: (v) => set(() {
                      v ? plats.add(p) : plats.remove(p);
                      a['platforms'] = plats.toList();
                    }),
                  ),
              ]),
            ),
            StatefulBuilder(
              builder: (c, set) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.f2Dismissible), value: a['dismissible'] != false, onChanged: (v) => set(() => a['dismissible'] = v)),
            ),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(context, a), child: Text(t.save))],
    );
  }
}

// ── F1 الإشعارات ───────────────────────────────────────────────────────────
class NotificationsAdminScreen extends ConsumerStatefulWidget {
  const NotificationsAdminScreen({super.key});
  @override
  ConsumerState<NotificationsAdminScreen> createState() => _NotificationsAdminScreenState();
}

class _NotificationsAdminScreenState extends ConsumerState<NotificationsAdminScreen> {
  final titleAr = TextEditingController(), titleEn = TextEditingController(), bodyAr = TextEditingController(), bodyEn = TextEditingController();
  final link = TextEditingController(), image = TextEditingController(), sendAt = TextEditingController();
  final plats = <String>{}, langs = <String>{};
  bool push = true, busy = false;
  List<Map<String, dynamic>> history = [];
  String? fcm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final x in [titleAr, titleEn, bodyAr, bodyEn, link, image, sendAt]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final v = await ref.read(settingsRepoProvider)?.get('notifications');
    if (mounted) setState(() => history = [for (final x in (v as List?) ?? const []) Map<String, dynamic>.from(x as Map)]);
  }

  Future<void> _send() async {
    final repo = ref.read(settingsRepoProvider);
    if (repo == null || (titleAr.text.trim().isEmpty && titleEn.text.trim().isEmpty)) return;
    final t = L10n.of(context);
    setState(() => busy = true);
    String? pushResult;
    try {
      final n = {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'title_ar': titleAr.text.trim().isEmpty ? null : titleAr.text.trim(),
        'title_en': titleEn.text.trim().isEmpty ? null : titleEn.text.trim(),
        'body_ar': bodyAr.text.trim().isEmpty ? null : bodyAr.text.trim(),
        'body_en': bodyEn.text.trim().isEmpty ? null : bodyEn.text.trim(),
        'link': link.text.trim().isEmpty ? null : link.text.trim(),
        'image': image.text.trim().isEmpty ? null : image.text.trim(),
        'platforms': plats.toList(),
        'languages': langs.toList(),
        'send_at': sendAt.text.trim().isEmpty ? null : DateTime.tryParse(sendAt.text.trim())?.toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      // صندوق الوارد لكل المنصّات (يصل في المزامنة)؛ نحتفظ بآخر 50
      final next = [n, ...history].take(50).toList();
      await repo.set('notifications', next);
      // Push فوري لأجهزة Android (FCM) عبر الدالة القائمة — المجدولة تصل عبر المزامنة فقط
      if (push && (plats.isEmpty || plats.contains('android')) && n['send_at'] == null) {
        final r = await repo.sendPush(title: '${n['title_ar'] ?? n['title_en']}', body: '${n['body_ar'] ?? n['body_en'] ?? ''}', url: n['link'] as String?);
        pushResult = r['ok'] == true ? 'FCM ✓' : 'FCM: ${r['error'] ?? r}';
      }
      for (final x in [titleAr, titleEn, bodyAr, bodyEn, link, image, sendAt]) {
        x.clear();
      }
      setState(() => history = next);
      if (mounted) toast(context, [t.f1Sent, ?pushResult].join(' · '));
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      SectionCard(
        title: t.f1Compose,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: TextField(controller: titleAr, decoration: InputDecoration(labelText: t.fTitleAr))),
            const SizedBox(width: Space.md),
            Expanded(child: TextField(controller: titleEn, decoration: InputDecoration(labelText: t.fTitleEn))),
          ]),
          Row(children: [
            Expanded(child: TextField(controller: bodyAr, maxLines: 3, decoration: InputDecoration(labelText: t.f2BodyAr))),
            const SizedBox(width: Space.md),
            Expanded(child: TextField(controller: bodyEn, maxLines: 3, decoration: InputDecoration(labelText: t.f2BodyEn))),
          ]),
          TextField(controller: link, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.f1Link, helperText: '/watch/<channel-id> · /guide · /home')),
          TextField(controller: image, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.f1Image)),
          TextField(controller: sendAt, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.f1SendAt, helperText: t.f1SendAtHint)),
          const SizedBox(height: Space.sm),
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            for (final p in _platforms) FilterChip(label: Text(p), selected: plats.contains(p), onSelected: (v) => setState(() => v ? plats.add(p) : plats.remove(p))),
            const SizedBox(width: Space.md),
            for (final l in const ['ar', 'en']) FilterChip(label: Text(l), selected: langs.contains(l), onSelected: (v) => setState(() => v ? langs.add(l) : langs.remove(l))),
          ]),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.f1Push), subtitle: Text(t.f1PushHint), value: push, onChanged: (v) => setState(() => push = v)),
          Row(children: [
            FilledButton.icon(onPressed: busy ? null : _send, icon: const Icon(Icons.send_rounded), label: Text(t.send)),
            const SizedBox(width: Space.sm),
            TextButton(
              onPressed: () async {
                final r = await ref.read(settingsRepoProvider)?.sendPush(title: '', body: '', check: true).catchError((Object e) => {'error': '$e'});
                setState(() => fcm = r?['ready'] == true ? 'FCM ✓ ${r?['project']}' : 'FCM ✗ ${r?['error'] ?? r}');
              },
              child: Text(t.f1CheckFcm),
            ),
            if (fcm != null) Flexible(child: Text(fcm!, style: TextStyle(color: c.textMuted, fontSize: 12))),
          ]),
        ]),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.f1History,
        child: Column(children: [
          if (history.isEmpty) Text(t.f2Empty, style: TextStyle(color: c.textMuted)),
          for (final n in history)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.campaign_rounded),
              title: Text('${n['title_ar'] ?? n['title_en']}'),
              subtitle: Text([
                shortTime(DateTime.parse('${n['created_at']}').toLocal()),
                if (n['send_at'] != null) '⏰ ${shortTime(DateTime.parse('${n['send_at']}').toLocal())}',
                if ((n['platforms'] as List?)?.isNotEmpty ?? false) (n['platforms'] as List).join(','),
              ].join(' · ')),
            ),
        ]),
      ),
    ]);
  }
}

/// مولّد: ‎FilteringTextInputFormatter مستخدم في الحقول الرقمية.
final digitsOnly = FilteringTextInputFormatter.digitsOnly;
