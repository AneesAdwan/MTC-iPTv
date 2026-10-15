// جلسة الاستيراد (ADM-C1 → C2، §10.3): المصدر ← التحليل (Isolate) ← المطابقة والتشغيل التجريبي ← القبول.
//  • لا كتابة قبل «قبول»: المعاينة كلها تشغيل تجريبي (§11.2 Dry-run).
//  • القنوات الجديدة تذهب دائمًا لقيد المراجعة (D1)، والموجودة يُضاف لها الرابط فقط (admin_import).
//  • حساب Xtream: يُستخدم للجلب مرة واحدة ولا يُحفظ (الحفظ في Vault يحتاج ترحيلًا — يُعرض للموافقة).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/logging/log.dart';
import 'admin_repository.dart';

enum ImportPhase { idle, analyzing, preview, committing, done, error }

class ImportAnalysis {
  final String format, encoding;
  final bool gzipped;
  final List<ImportIssue> issues;
  final Set<String> attributes;
  final MatchReport report;
  final List<String> vanishedStreamIds; // للمصدر المتكرر: روابطه التي لم تعد في القائمة
  const ImportAnalysis(this.format, this.encoding, this.gzipped, this.issues, this.attributes, this.report, {this.vanishedStreamIds = const []});
}

class ImportState {
  final ImportPhase phase;
  final String? label, sourceId, error;
  final ImportAnalysis? analysis;
  final Set<int> selected; // فهارس النتائج المختارة للقبول
  final Map<String, int>? done; // الملخّص بعد القبول
  const ImportState({this.phase = ImportPhase.idle, this.label, this.sourceId, this.error, this.analysis, this.selected = const {}, this.done});
  ImportState copyWith({ImportPhase? phase, Set<int>? selected, Map<String, int>? done, String? error}) =>
      ImportState(phase: phase ?? this.phase, label: label, sourceId: sourceId, error: error ?? this.error, analysis: analysis, selected: selected ?? this.selected, done: done ?? this.done);
}

/// تحليل + مطابقة خارج خيط الواجهة (§10.3: «في Isolate منفصل فلا تتجمد الواجهة»).
Future<ImportAnalysis> analyzeInIsolate(List<int> bytes, List<Map<String, dynamic>> channels, Map<String, String> urls) => Isolate.run(() {
      final d = decodeImport(bytes);
      final p = parseImport(d.text);
      final index = CatalogIndex([
        for (final c in channels)
          CatalogChannel(
            id: c['id'] as String,
            uid: c['uid'] as String,
            name: (c['name'] as String?) ?? '',
            nameAr: c['name_ar'] as String?,
            nameEn: c['name_en'] as String?,
            country: c['country_code'] as String?,
            epgId: c['epg_id'] as String?,
            publishState: c['publish_state'] as String?,
            altNames: [for (final x in (c['alt_names'] as List?) ?? const []) '$x'],
          ),
      ], urls);
      return ImportAnalysis(p.format, d.encoding, d.gzipped, p.issues, p.attributes, matchImport(p.items, index));
    });

/// ربط group-title بفئة موجودة (§10.3 الاستنتاج): بالمعرّف أو الاسمين أو مرادفات شائعة.
String? mapCategory(String? group, List<Map<String, dynamic>> categories) {
  if (group == null || group.trim().isEmpty) return null;
  final g = matchKey(group);
  const synonyms = {
    'news': ['news', 'اخبار', 'خبر', 'akhbar'],
    'sports': ['sport', 'رياضه', 'رياضة', 'football', 'كره'],
    'kids': ['kids', 'children', 'cartoon', 'اطفال', 'كرتون', 'animation'],
    'movies': ['movie', 'film', 'cinema', 'افلام', 'سينما'],
    'series': ['series', 'drama', 'مسلسلات', 'دراما'],
    'music': ['music', 'موسيقي', 'اغاني', 'songs'],
    'religious': ['religious', 'islam', 'quran', 'دين', 'قران', 'اسلام'],
    'documentary': ['document', 'docu', 'وثائقي'],
    'entertainment': ['entertain', 'منوعات', 'ترفيه'],
  };
  for (final c in categories) {
    final slug = '${c['slug']}';
    final keys = {matchKey(slug), matchKey('${c['name_en']}'), matchKey('${c['name_ar']}'), for (final s in synonyms[slug] ?? const <String>[]) matchKey(s)}..removeWhere((k) => k.isEmpty);
    if (keys.any((k) => g == k || g.contains(k))) return slug;
  }
  return null;
}

class ImportService extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  AdminRepository? get _repo => ref.read(adminRepoProvider);

  void reset() => state = const ImportState();

  Future<void> fromText(String text, {String label = 'paste'}) => _analyze(utf8.encode(text), label);
  Future<void> fromFile(List<int> bytes, String name) => _analyze(bytes, name);

  Future<void> fromUrl(String url, {String? sourceId, String? label}) async {
    state = ImportState(phase: ImportPhase.analyzing, label: label ?? url, sourceId: sourceId);
    try {
      final r = await SafeFetcher(policy: const SafeFetchPolicy(anyPort: true, maxBytes: maxImportBytes, timeout: Duration(seconds: 90)))
          .get(Uri.parse(url.trim()), headers: const {'User-Agent': 'MTC-iPTv-Import/3'});
      if (r.statusCode >= 400) throw StateError('HTTP ${r.statusCode}');
      await _analyze(r.body, label ?? url, sourceId: sourceId);
    } catch (e) {
      state = ImportState(phase: ImportPhase.error, label: label ?? url, sourceId: sourceId, error: '$e');
      if (sourceId != null) await _repo?.updateSource(sourceId, {'status': 'failed', 'last_error': '$e'.substring(0, '$e'.length.clamp(0, 300))});
    }
  }

  /// حساب Xtream Codes (§10.1): player_api.php ← قائمة القنوات الحية. لا يُحفظ الحساب.
  Future<void> fromXtream(String server, String user, String pass) async {
    final base = server.trim().replaceAll(RegExp(r'/+$'), '');
    state = ImportState(phase: ImportPhase.analyzing, label: 'Xtream: ${Uri.tryParse(base)?.host ?? base}');
    try {
      final f = SafeFetcher(policy: const SafeFetchPolicy(anyPort: true, maxBytes: maxImportBytes, timeout: Duration(seconds: 90)));
      Future<List> api(String action) async {
        final u = Uri.parse('$base/player_api.php').replace(queryParameters: {'username': user, 'password': pass, 'action': action});
        final r = await f.get(u);
        if (r.statusCode >= 400) throw StateError('HTTP ${r.statusCode}');
        final j = jsonDecode(utf8.decode(r.body, allowMalformed: true));
        if (j is! List) throw StateError('unexpected response (wrong credentials?)');
        return j;
      }

      final cats = {for (final c in await api('get_live_categories')) '${(c as Map)['category_id']}': '${c['category_name']}'};
      final streams = await api('get_live_streams');
      // نحوّلها إلى M3U ثم نمرّ بنفس خط التحليل (صيغة واحدة للمطابقة والتنظيف)
      final b = StringBuffer('#EXTM3U\n');
      for (final s in streams.cast<Map>()) {
        final name = '${s['name'] ?? ''}'.replaceAll(',', ' ');
        b.write('#EXTINF:-1 tvg-id="${s['epg_channel_id'] ?? ''}" tvg-logo="${s['stream_icon'] ?? ''}" group-title="${cats['${s['category_id']}'] ?? ''}",$name\n');
        b.write('$base/live/${Uri.encodeComponent(user)}/${Uri.encodeComponent(pass)}/${s['stream_id']}.ts\n');
      }
      await _analyze(utf8.encode(b.toString()), state.label!);
    } catch (e) {
      state = ImportState(phase: ImportPhase.error, label: state.label, error: '$e');
    }
  }

  Future<void> _analyze(List<int> bytes, String label, {String? sourceId}) async {
    final repo = _repo;
    if (repo == null) return;
    state = ImportState(phase: ImportPhase.analyzing, label: label, sourceId: sourceId);
    try {
      final (channels, streams) = await repo.matchingCatalog();
      final urls = {for (final s in streams) s['url'] as String: s['channel_id'] as String};
      var a = await analyzeInIsolate(bytes, channels, urls);
      if (sourceId != null) {
        // الفرق منذ آخر جلب (§10.4): روابط المصدر التي اختفت من القائمة الآن
        final now = {for (final r in a.report.results) normalizeUrl(r.item.url)};
        final vanished = [for (final s in streams) if (s['source_id'] == sourceId && !now.contains(normalizeUrl(s['url'] as String))) s['id'] as String];
        a = ImportAnalysis(a.format, a.encoding, a.gzipped, a.issues, a.attributes, a.report, vanishedStreamIds: vanished);
      }
      final sel = {for (var i = 0; i < a.report.results.length; i++) if (const {'new', 'update'}.contains(a.report.results[i].kind)) i};
      state = ImportState(phase: ImportPhase.preview, label: label, sourceId: sourceId, analysis: a, selected: sel);
    } catch (e, s) {
      log.warning('import analysis failed', e, s);
      state = ImportState(phase: ImportPhase.error, label: label, sourceId: sourceId, error: '$e');
    }
  }

  void toggle(int i) {
    final s = {...state.selected};
    if (!s.remove(i)) s.add(i);
    state = state.copyWith(selected: s);
  }
  void selectKind(String kind, bool on) {
    final r = state.analysis?.report.results ?? const [];
    final idx = [for (var i = 0; i < r.length; i++) if (r[i].kind == kind) i];
    state = state.copyWith(selected: on ? {...state.selected, ...idx} : ({...state.selected}..removeAll(idx)));
  }

  /// القبول: يُرسل المختار فقط.
  Future<void> commit({bool disableVanished = false}) async {
    final repo = _repo;
    final a = state.analysis;
    if (repo == null || a == null) return;
    state = state.copyWith(phase: ImportPhase.committing);
    int? runId;
    try {
      runId = await repo.startRun('sources', Platform.localHostname);
    } catch (_) {}
    try {
      final cats = await repo.categories();
      final chosen = [for (final i in state.selected) a.report.results[i]];
      final items = [
        for (final r in chosen)
          {
            'uid': r.uid,
            'name': r.item.name,
            'logo': r.item.logo,
            'country': r.item.country,
            'category': mapCategory(r.item.group, cats),
            'language': r.item.language,
            'quality': r.item.quality,
            'url': r.item.url,
            'label': null,
          },
      ];
      final (ch, st) = await repo.importItems(state.sourceId, items);
      for (final r in chosen.where((r) => r.item.userAgent != null || r.item.referrer != null || r.item.headers.isNotEmpty)) {
        await repo.setStreamHeaders(r.item.url, userAgent: r.item.userAgent, referrer: r.item.referrer, headers: r.item.headers);
      }
      var disabled = 0;
      if (disableVanished && a.vanishedStreamIds.isNotEmpty) {
        // تعطيل لا حذف (§10.4)
        for (final id in a.vanishedStreamIds) {
          await repo.updateStream(id, {'health_state': 'disabled', 'health_reason': 'vanished from source'});
        }
        disabled = a.vanishedStreamIds.length;
      }
      if (state.sourceId != null) await repo.markSourceImported(state.sourceId!);
      final summary = {
        'channels': ch,
        'streams': st,
        'new': chosen.where((r) => r.kind == 'new').map((r) => r.uid).toSet().length,
        'updated': chosen.where((r) => r.kind == 'update').length,
        'disabled': disabled,
        'skipped': a.report.results.length - chosen.length,
        'failed': a.report.counts['failed'] ?? 0,
      };
      if (runId != null) await repo.finishRun(runId, status: 'ok', summary: {'label': state.label, ...summary});
      state = state.copyWith(phase: ImportPhase.done, done: summary);
    } catch (e, s) {
      log.warning('import commit failed', e, s);
      if (runId != null) {
        try {
          await repo.finishRun(runId, status: 'failed', error: '$e');
        } catch (_) {}
      }
      state = state.copyWith(phase: ImportPhase.error, error: '$e');
    }
  }
}

final importProvider = NotifierProvider<ImportService, ImportState>(ImportService.new);
