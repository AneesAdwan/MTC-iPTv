// Implementations. Writes are final-form (they call the admin_* function through AdminRpc, which is
// the stub until Phase 2). Reads use SampleData until the server read views exist.
import '../app/theme/tokens.dart';
import '../core/tr.dart';
import '../ui/preview_dialog.dart';
import '../ui/selection.dart';
import 'models.dart';
import 'paging.dart';
import 'repositories.dart';
import 'rpc/admin_rpc.dart';
import 'rpc/rpc_catalog.dart';
import 'sample/sample_data.dart';

Duration _latency = const Duration(milliseconds: 120);

/// Tests set this to zero.
void setSampleLatency(Duration d) => _latency = d;

Future<T> _later<T>(T Function() f) async {
  if (_latency > Duration.zero) await Future<void>.delayed(_latency);
  return f();
}

ListDataSource<GenericRow> _rows(List<GenericRow> Function() rows) => ListDataSource<GenericRow>(
  rows: rows,
  id: (r) => r.id,
  latency: _latency,
  matches: (r, q) => r.cells.values.any((v) => v.toLowerCase().contains(q.toLowerCase())),
  filter: (r, k, v) => r[k] == v,
  sortValue: (r, k) => r[k],
);

Map<String, Object?> _filterParams(PageRequest f) => {'p_query': f.query, 'p_filters': f.filters};

class DashboardRepositoryImpl implements DashboardRepository {
  final AdminRpc rpc;
  final SampleData data;
  DashboardRepositoryImpl(this.rpc, this.data);

  @override
  Future<Kpis> kpis() => _later(data.kpis);

  @override
  Future<List<DecisionItem>> attention() => _later(() {
    final all = data.decisions();
    return [
      for (final t in ['broken', 'sources', 'reports', 'duplicates', 'review']) all.firstWhere((d) => d.type == t),
    ];
  });

  @override
  late final PagedDataSource<JobInfo> jobs = ListDataSource<JobInfo>(rows: data.jobs, id: (j) => j.id, latency: _latency);

  @override
  Future<List<AlertItem>> alerts() => _later(data.alerts);

  @override
  Future<OpResult> cancelJob(String jobId, {required String reason}) => rpc.call(Rpc.jobCancel, {'p_job_id': jobId}, reason: reason);

  @override
  Future<OpResult> retryJob(String jobId, {required String reason}) => rpc.call(Rpc.jobRetry, {'p_job_id': jobId}, reason: reason);

  @override
  Future<OpResult> setAlertState(String alertId, AlertState state, {required String reason}) =>
      rpc.call(Rpc.alertSetState, {'p_alert_id': alertId, 'p_state': state.name}, reason: reason);
}

class ChannelsRepositoryImpl implements ChannelsRepository {
  final AdminRpc rpc;
  final SampleData data;
  ChannelsRepositoryImpl(this.rpc, this.data);

  static bool _matches(Channel c, String q) {
    final n = int.tryParse(q);
    if (n != null) return c.number == n;
    final l = q.toLowerCase();
    return c.nameAr.contains(q) || c.nameEn.toLowerCase().contains(l);
  }

  static bool _filter(Channel c, String k, String v) => switch (k) {
    'state' => c.state.name == v,
    'country' => c.country == v,
    'category' => c.category == v,
    'missing' => switch (v) {
      'logo' => !c.hasLogo,
      'epg' => !c.hasEpg,
      'working' => c.workingLinks == 0,
      _ => true,
    },
    _ => true,
  };

  static Comparable<Object?> _sort(Channel c, String k) => switch (k) {
    'number' => c.number,
    'name' => c.nameAr,
    'updated' => c.updatedAt.millisecondsSinceEpoch,
    'links' => c.workingLinks,
    _ => c.number,
  };

  @override
  late final PagedDataSource<Channel> channels = ListDataSource<Channel>(
    rows: () => data.channels.where((c) => c.state != ChannelState.trashed).toList(),
    id: (c) => c.id,
    latency: _latency,
    matches: _matches,
    filter: _filter,
    sortValue: _sort,
  );

  @override
  late final PagedDataSource<Channel> trash = ListDataSource<Channel>(
    rows: () => data.channels.where((c) => c.state == ChannelState.trashed).toList(),
    id: (c) => c.id,
    latency: _latency,
    matches: _matches,
    sortValue: _sort,
  );

  @override
  Future<Channel?> channel(String id) => _later(() => data.channels.where((c) => c.id == id).firstOrNull);

  @override
  Future<List<StreamLink>> streams(String channelId) => _later(() => data.streams(channelId));

  @override
  Future<List<AuditEntry>> history(String channelId) => _later(() => data.history(channelId));

  @override
  Future<int> suggestNumber() => _later(() {
    final used = data.channels.map((c) => c.number).toSet();
    var n = 1;
    while (used.contains(n)) {
      n++;
    }
    return n;
  });

  @override
  Future<OperationPreview> previewBulk(BulkAction action, SelectionSnapshot sel, PageRequest filter, {String? value}) async {
    // Phase 2: rpc.preview(Rpc.channelsBulk, …). Until then a local estimate from the sample rows.
    final page = await channels.fetch(filter.copyWith(offset: 0, limit: 1 << 30));
    final chosen = page.items.where((c) => sel.allMatching ? !sel.ids.contains(c.id) : sel.ids.contains(c.id)).toList();
    final target = switch (action) {
      BulkAction.publish => ChannelState.published,
      BulkAction.hide => ChannelState.hidden,
      _ => null,
    };
    final already = target == null ? <Channel>[] : chosen.where((c) => c.state == target).toList();
    final noLink = action == BulkAction.publish ? chosen.where((c) => c.workingLinks == 0 && c.state != target).toList() : <Channel>[];
    final changing = chosen.where((c) => !already.contains(c) && !noLink.contains(c)).toList();
    final spec = action == BulkAction.trash ? Rpc.channelsTrash : Rpc.channelsBulk;
    return OperationPreview(
      title: _bulkTitle(action),
      confirmLabel: const Tr('نفّذ', 'Run'),
      affected: changing.length,
      unit: const Tr('قناة', 'channels'),
      undoClass: spec.undoClass,
      groups: [
        for (final s in ChannelState.values)
          if (changing.any((c) => c.state == s))
            PreviewGroup(
              Tr('${s.label.ar} ← ${target?.label.ar ?? _bulkTitle(action).ar}', '${s.label.en} → ${target?.label.en ?? _bulkTitle(action).en}'),
              changing.where((c) => c.state == s).length,
              tone: s.tone,
              examples: changing.where((c) => c.state == s).take(3).map((c) => c.nameAr).toList(),
            ),
      ],
      excluded: [
        for (final c in already.take(5)) PreviewExclusion(c.nameAr, const Tr('أصلًا بهالحالة', 'already in this state')),
        for (final c in noLink.take(5)) PreviewExclusion(c.nameAr, const Tr('ما إلها ولا رابط يعمل', 'has no working stream')),
      ],
    );
  }

  static Tr _bulkTitle(BulkAction a) => switch (a) {
    BulkAction.publish => const Tr('نشر', 'Publish'),
    BulkAction.hide => const Tr('إخفاء', 'Hide'),
    BulkAction.feature => const Tr('تمييز', 'Feature'),
    BulkAction.setCountry => const Tr('تعيين الدولة', 'Set country'),
    BulkAction.setCategory => const Tr('تعيين الفئة', 'Set category'),
    BulkAction.setLanguage => const Tr('تعيين اللغة', 'Set language'),
    BulkAction.probe => const Tr('فحص', 'Probe'),
    BulkAction.trash => const Tr('نقل للسلة', 'Move to trash'),
  };

  @override
  Future<OpResult> applyBulk(BulkAction action, SelectionSnapshot sel, PageRequest filter, {String? value, required String reason}) {
    final spec = switch (action) {
      BulkAction.trash => Rpc.channelsTrash,
      BulkAction.probe => Rpc.streamsProbe,
      _ => Rpc.channelsBulk,
    };
    return rpc.call(spec, {'p_action': action.name, 'p_value': value, ...sel.toParams(), ..._filterParams(filter)}, reason: reason, affected: sel.count);
  }

  @override
  Future<OpResult> create(Map<String, Object?> fields, {required bool forReview, required String reason}) =>
      rpc.call(Rpc.channelCreate, {'p_fields': fields, 'p_for_review': forReview}, reason: reason);

  @override
  Future<OpResult> update(String id, Map<String, Object?> fields, {required String reason}) =>
      rpc.call(Rpc.channelUpdate, {'p_channel_id': id, 'p_fields': fields}, reason: reason);

  @override
  Future<OpResult> restore(SelectionSnapshot sel, {required String reason}) =>
      rpc.call(Rpc.channelsRestore, sel.toParams(), reason: reason, affected: sel.count);

  @override
  Future<OpResult> purge(SelectionSnapshot sel, {required String reason}) => rpc.call(Rpc.channelsPurge, sel.toParams(), reason: reason, affected: sel.count);

  @override
  Future<OpResult> renumber(Map<String, Object?> plan, {required String reason}) => rpc.call(Rpc.channelsRenumber, {'p_plan': plan}, reason: reason);

  @override
  Future<OpResult> renameNetwork(String from, String to, {required String reason}) => rpc.call(Rpc.networkRename, {'p_from': from, 'p_to': to}, reason: reason);

  @override
  Future<OpResult> undo(String token, {required String reason}) => rpc.call(Rpc.undo, {'p_undo_token': token}, reason: reason);
}

class DecisionsRepositoryImpl implements DecisionsRepository {
  final AdminRpc rpc;
  final SampleData data;
  DecisionsRepositoryImpl(this.rpc, this.data);

  late final List<DecisionItem> _all = data.decisions();

  @override
  late final PagedDataSource<DecisionItem> items = ListDataSource<DecisionItem>(
    rows: () => _all,
    id: (d) => d.id,
    latency: _latency,
    matches: (d, q) => d.title.toLowerCase().contains(q.toLowerCase()),
    filter: (d, k, v) => switch (k) {
      'type' => d.type == v,
      'country' => d.country == v,
      'category' => d.category == v,
      _ => true,
    },
    sortValue: (d, k) => -(d.confidence ?? 0),
  );

  @override
  Future<Map<String, int>> counts() => _later(() {
    final m = <String, int>{};
    for (final d in _all) {
      m[d.type] = (m[d.type] ?? 0) + 1;
    }
    return m;
  });

  @override
  Future<OpResult> apply(String decision, SelectionSnapshot sel, PageRequest filter, {required String reason}) =>
      rpc.call(Rpc.decisionsApply, {'p_decision': decision, ...sel.toParams(), ..._filterParams(filter)}, reason: reason, affected: sel.count);
}

class SourcesRepositoryImpl implements SourcesRepository {
  final AdminRpc rpc;
  final SampleData data;
  SourcesRepositoryImpl(this.rpc, this.data);

  @override
  Future<List<SourceCard>> sources() => _later(data.sources);

  @override
  late final PagedDataSource<GenericRow> runs = _rows(
    () => [
      for (var i = 0; i < 40; i++)
        GenericRow('run$i', {
          'source': data.sources()[i % 5].name,
          'started': fmtDateTime(data.now.subtract(Duration(hours: i * 5))),
          'by': i % 3 == 0 ? 'admin' : 'schedule',
          'downloaded': fmtInt(1200 - i * 7),
          'parsed': fmtInt(1150 - i * 7),
          'new': fmtInt(i % 7 * 3),
          'invalid': fmtInt(i % 4 * 5),
          'result': i % 9 == 4 ? 'stopped: size guard' : (i % 11 == 6 ? 'failed: timeout' : 'ok'),
        }, tone: i % 9 == 4 ? Tone.warn : (i % 11 == 6 ? Tone.bad : Tone.ok)),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> rules = _rows(
    () => const [
      GenericRow('r1', {'order': '1', 'when': 'group-title = "Sport"', 'then': 'category = sports', 'hits': '412'}),
      GenericRow('r2', {'order': '2', 'when': 'name contains "KSA"', 'then': 'country = SA', 'hits': '57'}),
      GenericRow('r3', {'order': '3', 'when': 'name matches HD|FHD', 'then': 'strip from name', 'hits': '1,083'}),
      GenericRow('r4', {'order': '4', 'when': 'tvg-country = "PS"', 'then': 'country = PS', 'hits': '96'}),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> enrichment = _rows(
    () => [
      for (final c in data.channels.take(140))
        GenericRow('e-${c.id}', {
          'channel': c.nameAr,
          'field': ['name_en', 'logo', 'country', 'language', 'category'][c.number % 5],
          'current': c.nameEn.toLowerCase().replaceAll(' ', '_'),
          'suggested': c.nameEn,
          'confidence': '${60 + c.number % 40}%',
        }),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> blocks = _rows(
    () => [
      GenericRow('b1', {
        'kind': 'stream',
        'target': 'http://srv3.example.org/live/••••',
        'reason': 'اعتراض صاحب الحقوق',
        'at': fmtDateTime(data.now.subtract(const Duration(days: 12))),
      }),
      GenericRow('b2', {
        'kind': 'source',
        'target': 'pirate-list.m3u',
        'reason': 'مصدر غير مرخّص',
        'at': fmtDateTime(data.now.subtract(const Duration(days: 40))),
      }),
    ],
  );

  @override
  Future<OpResult> fetch(String sourceId, Map<String, String> scope, {required String reason}) =>
      rpc.call(Rpc.sourceFetch, {'p_source_id': sourceId, 'p_scope': scope}, reason: reason);

  @override
  Future<OpResult> setPaused(String sourceId, bool paused, {required String reason}) =>
      rpc.call(Rpc.sourcePause, {'p_source_id': sourceId, 'p_paused': paused}, reason: reason);

  @override
  Future<OpResult> rollback(String sourceId, {required String reason}) => rpc.call(Rpc.sourceRollback, {'p_source_id': sourceId}, reason: reason);

  @override
  Future<OpResult> stageImport(Map<String, Object?> input, {required String reason}) => rpc.call(Rpc.importStage, {'p_input': input}, reason: reason);

  @override
  Future<OpResult> saveRules(List<Map<String, Object?>> rules, {required String reason}) =>
      rpc.call(Rpc.rulesSave, {'p_rules': rules}, reason: reason, affected: rules.length);

  @override
  Future<OpResult> applyEnrichment(SelectionSnapshot sel, bool accept, {required String reason}) =>
      rpc.call(Rpc.enrichmentApply, {...sel.toParams(), 'p_accept': accept}, reason: reason, affected: sel.count);

  @override
  Future<OpResult> setBlock(String kind, String target, bool blocked, {required String reason}) =>
      rpc.call(Rpc.blockSet, {'p_kind': kind, 'p_target': target, 'p_blocked': blocked}, reason: reason);
}

class EpgRepositoryImpl implements EpgRepository {
  final AdminRpc rpc;
  final SampleData data;
  EpgRepositoryImpl(this.rpc, this.data);

  @override
  late final PagedDataSource<GenericRow> sources = _rows(
    () => [
      GenericRow('g1', {
        'priority': '1',
        'name': 'iptv-org/epg · ar',
        'lastOk': fmtDateTime(data.now.subtract(const Duration(hours: 5))),
        'channels': '760',
        'programmes': '48,210',
        'errors': '0',
      }, tone: Tone.ok),
      GenericRow('g2', {
        'priority': '2',
        'name': 'epgshare01 · MENA',
        'lastOk': fmtDateTime(data.now.subtract(const Duration(days: 1))),
        'channels': '312',
        'programmes': '20,904',
        'errors': '3',
      }, tone: Tone.warn),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> mapping = _rows(
    () => [
      for (final c in data.channels.where((c) => c.state == ChannelState.published && !c.hasEpg).take(120))
        GenericRow('m-${c.id}', {
          'channel': '${c.number} · ${c.nameAr}',
          'suggestion': '${c.nameEn.replaceAll(' ', '')}.${c.country.toLowerCase()}',
          'basis': c.number.isEven ? 'iptv-org id' : 'name + country',
          'confidence': '${c.number.isEven ? 96 : 58 + c.number % 30}%',
        }, tone: c.number.isEven ? Tone.ok : Tone.warn),
    ],
  );

  @override
  Future<List<GenericRow>> programmes(String channelId, DateTime day) => _later(
    () => [
      for (var h = 0; h < 24; h += 2)
        GenericRow('p$h', {
          'start': '${h.toString().padLeft(2, '0')}:00',
          'end': '${(h + 2).toString().padLeft(2, '0')}:00',
          'title': ['نشرة الأخبار', 'برنامج حواري', 'وثائقي', 'رياضة اليوم', 'فيلم السهرة', 'مسلسل'][h ~/ 2 % 6],
          'note': h == 10 ? 'gap' : (h == 16 ? 'overlap' : ''),
        }, tone: h == 10 || h == 16 ? Tone.warn : Tone.neutral),
    ],
  );

  @override
  Future<OpResult> syncNow(String? sourceId, {required String reason}) => rpc.call(Rpc.epgSyncNow, {'p_source_id': sourceId}, reason: reason);

  @override
  Future<OpResult> map(SelectionSnapshot sel, {required String reason, int? offsetMinutes}) =>
      rpc.call(Rpc.epgMap, {...sel.toParams(), 'p_offset_minutes': offsetMinutes}, reason: reason, affected: sel.count);
}

class ExperienceRepositoryImpl implements ExperienceRepository {
  final AdminRpc rpc;
  final SampleData data;
  ExperienceRepositoryImpl(this.rpc, this.data);

  @override
  Future<Map<String, Object?>> settings(String group) => _later(
    () => switch (group) {
      'branding' => {'app_name': 'MTC-iPTv', 'developer': 'Anees Adwan', 'default_lang': 'ar', 'default_theme': 'dark', 'facebook': '', 'telegram': ''},
      'player' => {'start_timeout_s': 12, 'retries_before_switch': 2, 'max_quality': '1080p'},
      'features' => {'reports': true, 'synced_favorites': true, 'maintenance': false, 'maintenance_block': false, 'maintenance_message': ''},
      'releases' => {'windows': '3.0.0-alpha.35', 'android': '3.0.0-alpha.35', 'tv': '3.0.0-alpha.35', 'min_supported': '3.0.0-alpha.30'},
      'announcement' => {'text': 'تطوير — نقوم بعمل تطوير', 'color': 'accent', 'days': 3, 'dismissible': true},
      _ => <String, Object?>{},
    },
  );

  @override
  late final PagedDataSource<GenericRow> taxonomy = _rows(
    () => [
      for (final e in sampleCategories.entries)
        GenericRow('cat-${e.key}', {
          'kind': 'category',
          'ar': e.value.ar,
          'en': e.value.en,
          'visible': 'yes',
          'channels': '${data.channels.where((c) => c.category == e.key).length}',
        }),
      for (final e in sampleCountries.entries)
        GenericRow('cty-${e.key}', {
          'kind': 'country',
          'ar': e.value.ar,
          'en': e.value.en,
          'visible': 'yes',
          'channels': '${data.channels.where((c) => c.country == e.key).length}',
        }),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> notificationsLog = _rows(
    () => [
      GenericRow('n1', {'at': fmtDateTime(data.now.subtract(const Duration(days: 3))), 'text': 'قنوات رياضية جديدة', 'target': 'الكل', 'by': 'admin'}),
      GenericRow('n2', {'at': fmtDateTime(data.now.subtract(const Duration(days: 9))), 'text': 'تحديث 3.0 متوفر', 'target': 'Android', 'by': 'admin'}),
    ],
  );

  @override
  Future<OpResult> saveSettings(String group, Map<String, Object?> values, {required String reason}) {
    final spec = switch (group) {
      'home' => Rpc.homeLayoutSet,
      'releases' => Rpc.releaseSet,
      'announcement' => Rpc.announcementUpsert,
      _ => Rpc.settingsSet,
    };
    return rpc.call(spec, {'p_group': group, 'p_values': values}, reason: reason);
  }

  @override
  Future<OpResult> sendNotification(Map<String, Object?> message, {required String reason}) =>
      rpc.call(Rpc.notificationSend, {'p_message': message}, reason: reason);

  @override
  Future<OpResult> saveTaxonomy(Map<String, Object?> item, {required String reason}) => rpc.call(Rpc.taxonomyUpsert, {'p_item': item}, reason: reason);
}

class SystemRepositoryImpl implements SystemRepository {
  final AdminRpc rpc;
  final SampleData data;
  SystemRepositoryImpl(this.rpc, this.data);

  @override
  Future<List<SessionInfo>> sessions() => _later(data.sessions);

  @override
  late final PagedDataSource<GenericRow> schedules = _rows(
    () => [
      for (final (i, t) in const [
        ('probe_quick', 'فحص الروابط السريع', 'كل ساعة', 'edge'),
        ('logo_check', 'فحص الشعارات', 'يوميًا', 'edge'),
        ('epg_sync', 'مزامنة الدليل', 'كل 6 ساعات', 'github-actions'),
        ('sources_fetch', 'جلب المصادر', 'حسب كل مصدر', 'edge / github-actions'),
        ('enrichment', 'تحسين البيانات', 'أسبوعيًا', 'github-actions'),
        ('duplicates', 'كشف المكررات', 'يوميًا', 'pg_cron'),
        ('alerts', 'التنبيهات', 'كل ساعة', 'pg_cron'),
        ('trash_purge', 'تنظيف السلة (30 يوم)', 'يوميًا', 'pg_cron'),
        ('telemetry_rollup', 'تجميع القياس', 'يوميًا', 'pg_cron'),
      ].indexed)
        GenericRow(t.$1, {
          'task': t.$2,
          'schedule': t.$3,
          'executor': t.$4,
          'enabled': i == 4 ? 'no' : 'yes',
          'last': fmtDateTime(data.now.subtract(Duration(minutes: 20 + i * 50))),
          'result': i == 1 ? 'failed' : 'ok',
        }, tone: i == 1 ? Tone.bad : Tone.ok),
    ],
  );

  @override
  late final PagedDataSource<AuditEntry> audit = ListDataSource<AuditEntry>(
    rows: () => [for (final c in data.channels.take(30)) ...data.history(c.id, count: 3)]..sort((a, b) => b.at.compareTo(a.at)),
    id: (a) => a.id,
    latency: _latency,
    matches: (a, q) => a.target.contains(q) || a.action.contains(q) || a.reason.contains(q),
    filter: (a, k, v) => switch (k) {
      'action' => a.action == v,
      _ => true,
    },
  );

  @override
  late final PagedDataSource<GenericRow> errors = _rows(
    () => [
      for (var i = 0; i < 14; i++)
        GenericRow('err$i', {
          'at': fmtDateTime(data.now.subtract(Duration(hours: i * 3))),
          'where': ['edge:probe', 'client', 'rpc:admin_status'][i % 3],
          'message': ['timeout after 8s', 'SocketException', 'JWT expired'][i % 3],
        }),
    ],
  );

  @override
  late final PagedDataSource<GenericRow> analytics = _rows(
    () => [
      for (final c in data.channels.take(60))
        GenericRow('an-${c.id}', {
          'channel': c.nameAr,
          'plays': fmtInt(5000 - c.number * 61),
          'success': '${(99 - c.number % 17)}%',
          'startup': '${(0.8 + (c.number % 9) / 10).toStringAsFixed(1)} s',
        }),
    ],
  );

  @override
  Future<OpResult> revokeSession(String sessionId, {required String reason}) => rpc.call(Rpc.sessionRevoke, {'p_session_id': sessionId}, reason: reason);

  @override
  Future<OpResult> setTask(String taskId, {bool? enabled, bool runNow = false, required String reason}) => runNow
      ? rpc.call(Rpc.taskRunNow, {'p_task_id': taskId}, reason: reason)
      : rpc.call(Rpc.taskSet, {'p_task_id': taskId, 'p_enabled': enabled}, reason: reason);

  @override
  Future<OpResult> revert(String auditId, {required String reason}) => rpc.call(Rpc.auditRevert, {'p_audit_id': auditId}, reason: reason);

  @override
  Future<OpResult> restoreBackup(String backupId, {required String reason}) => rpc.call(Rpc.backupRestore, {'p_backup_id': backupId}, reason: reason);

  @override
  Future<OpResult> cleanup({required String reason}) => rpc.call(Rpc.maintenanceCleanup, const {}, reason: reason);
}
