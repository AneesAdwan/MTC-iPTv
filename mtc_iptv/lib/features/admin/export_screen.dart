// ADM-C5 التصدير (§10.5): نفس فلاتر القنوات، الصيغ M3U وCSV وJSON وXSPF، وخيارات: العاملة فقط، الأفضل فقط،
// واستبعاد الروابط ذات بيانات الاعتماد (افتراضيًا). (XMLTV وExcel: مع الدليل والجداول لاحقًا.)
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/logging/log.dart';
import '../../data/admin/admin_repository.dart';
import 'channels/channels_admin_screen.dart';
import 'widgets/admin_widgets.dart';

/// صفوف الخادم ← قنوات التصدير (الروابط بالأولوية).
List<ExportChannel> toExportChannels(List<Map<String, dynamic>> rows, {String lang = 'ar'}) => [
      for (final r in rows)
        ExportChannel(
          uid: r['uid'] as String,
          name: '${(lang == 'ar' ? (r['name_ar'] ?? r['name_en']) : (r['name_en'] ?? r['name_ar'])) ?? r['name']}',
          number: (r['number'] as num?)?.toInt(),
          logo: r['logo_url'] as String?,
          country: r['country_code'] as String?,
          category: r['category_slug'] as String?,
          language: r['language_code'] as String?,
          epgId: r['epg_id'] as String?,
          streams: [
            for (final s in ((r['streams'] as List?) ?? const []).cast<Map>().toList()..sort((a, b) => ((a['priority'] as num?) ?? 0).compareTo((b['priority'] as num?) ?? 0)))
              if (s['health_state'] != 'disabled')
                ExportStream(
                  '${s['url']}',
                  userAgent: s['user_agent'] as String?,
                  referrer: s['referrer'] as String?,
                  label: s['label'] as String?,
                  working: workingStates.contains(s['health_state']),
                  hasCredentials: s['has_credentials'] == true,
                ),
          ],
        ),
    ];

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});
  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String? state = 'published', country, category;
  String format = 'm3u', lang = 'ar';
  bool workingOnly = false, bestOnly = false, skipCreds = true, busy = false;

  Future<void> _export() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final t = L10n.of(context);
    setState(() => busy = true);
    try {
      final rows = await repo.exportRows(state: state, country: country, category: category);
      final chans = toExportChannels(rows, lang: lang);
      final o = ExportOptions(workingOnly: workingOnly, bestOnly: bestOnly, skipCredentials: skipCreds);
      final (text, ext, mime) = switch (format) {
        'csv' => (toCsv(chans, o), 'csv', 'text/csv'),
        'json' => (toJson(chans, o), 'json', 'application/json'),
        'xspf' => (toXspf(chans, o), 'xspf', 'application/xspf+xml'),
        _ => (toM3u(chans, o), 'm3u', 'audio/x-mpegurl'),
      };
      final loc = await getSaveLocation(suggestedName: 'mtc-iptv-${DateTime.now().toIso8601String().substring(0, 10)}.$ext');
      if (loc == null) return;
      await XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: mime, name: 'export.$ext').saveTo(loc.path);
      // كل تصدير يُسجَّل (§10.5): في سجل البرنامج (سجل التدقيق على الخادم مع المرحلة 6)
      log.info('export format=$format channels=${chans.length} state=$state country=$country category=$category working=$workingOnly best=$bestOnly skipCreds=$skipCreds');
      if (mounted) toast(context, t.exDone(chans.length));
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final ui = Localizations.localeOf(context).languageCode;
    final refs = ref.watch(adminRefProvider).value;
    String nm(Map m) => '${ui == 'ar' ? m['name_ar'] : m['name_en']}';
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
          SectionCard(
            title: t.kpiChannels,
            child: Wrap(spacing: Space.md, runSpacing: Space.sm, children: [
              DropdownButton<String?>(
                value: state,
                items: [DropdownMenuItem(value: null, child: Text(t.allStates)), for (final s in publishStates) DropdownMenuItem(value: s, child: Text(publishLabel(t, s)))],
                onChanged: (v) => setState(() => state = v),
              ),
              DropdownButton<String?>(
                value: country,
                hint: Text(t.allCountries),
                items: [DropdownMenuItem(value: null, child: Text(t.allCountries)), for (final x in refs?.$1 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['code'] as String, child: Text(nm(x)))],
                onChanged: (v) => setState(() => country = v),
              ),
              DropdownButton<String?>(
                value: category,
                hint: Text(t.allCategories),
                items: [DropdownMenuItem(value: null, child: Text(t.allCategories)), for (final x in refs?.$2 ?? const <Map<String, dynamic>>[]) DropdownMenuItem(value: x['slug'] as String, child: Text(nm(x)))],
                onChanged: (v) => setState(() => category = v),
              ),
            ]),
          ),
          const SizedBox(height: Space.md),
          SectionCard(
            title: t.exFormat,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'm3u', label: Text('M3U')), ButtonSegment(value: 'csv', label: Text('CSV')), ButtonSegment(value: 'json', label: Text('JSON')), ButtonSegment(value: 'xspf', label: Text('XSPF'))],
                selected: {format},
                onSelectionChanged: (v) => setState(() => format = v.first),
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'ar', label: Text('العربية')), ButtonSegment(value: 'en', label: Text('English'))],
                selected: {lang},
                onSelectionChanged: (v) => setState(() => lang = v.first),
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.exWorkingOnly), value: workingOnly, onChanged: (v) => setState(() => workingOnly = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.exBestOnly), value: bestOnly, onChanged: (v) => setState(() => bestOnly = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.exSkipCreds), value: skipCreds, onChanged: (v) => setState(() => skipCreds = v)),
            ]),
          ),
          const SizedBox(height: Space.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: busy ? null : _export,
              icon: busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_rounded),
              label: Text(t.exExport),
            ),
          ),
        ]),
      ),
    );
  }
}
