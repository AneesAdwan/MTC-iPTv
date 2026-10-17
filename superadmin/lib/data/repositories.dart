// Repository interfaces, one per section. Reads come from server views / read RPCs (Phase 2);
// EVERY write goes through an admin_* function from rpc_catalog.dart — never a table write.
import '../ui/preview_dialog.dart';
import '../ui/selection.dart';
import 'models.dart';
import 'paging.dart';
import 'rpc/admin_rpc.dart';

/// Section 1 — Home.
abstract interface class DashboardRepository {
  /// One aggregated server query (plan §6 1.1), refreshed every minute or on demand.
  Future<Kpis> kpis();

  /// Top 5 by impact = viewers × severity (plan §6 1.2).
  Future<List<DecisionItem>> attention();
  PagedDataSource<JobInfo> get jobs;
  Future<List<AlertItem>> alerts();

  /// admin_job_cancel
  Future<OpResult> cancelJob(String jobId, {required String reason});

  /// admin_job_retry
  Future<OpResult> retryJob(String jobId, {required String reason});

  /// admin_alert_set_state
  Future<OpResult> setAlertState(String alertId, AlertState state, {required String reason});
}

enum BulkAction { publish, hide, feature, setCountry, setCategory, setLanguage, probe, trash }

/// Section 2 — Channels.
abstract interface class ChannelsRepository {
  PagedDataSource<Channel> get channels;
  PagedDataSource<Channel> get trash;
  Future<Channel?> channel(String id);
  Future<List<StreamLink>> streams(String channelId);
  Future<List<AuditEntry>> history(String channelId);

  /// First free channel number (plan §6 2.2).
  Future<int> suggestNumber();

  /// admin_channels_bulk(p_preview => true): what will happen to every selected channel.
  Future<OperationPreview> previewBulk(BulkAction action, SelectionSnapshot selection, PageRequest filter, {String? value});

  /// admin_channels_bulk (snapshot) / admin_channels_trash (full).
  Future<OpResult> applyBulk(BulkAction action, SelectionSnapshot selection, PageRequest filter, {String? value, required String reason});

  /// admin_channel_create: channel + first stream in one call, number checked on the server.
  Future<OpResult> create(Map<String, Object?> fields, {required bool forReview, required String reason});

  /// admin_channel_update (with optional field lock 🔒).
  Future<OpResult> update(String id, Map<String, Object?> fields, {required String reason});

  /// admin_channels_restore
  Future<OpResult> restore(SelectionSnapshot selection, {required String reason});

  /// admin_channels_purge (irreversible, typed confirmation + recent TOTP).
  Future<OpResult> purge(SelectionSnapshot selection, {required String reason});

  /// admin_channels_renumber
  Future<OpResult> renumber(Map<String, Object?> plan, {required String reason});

  /// admin_network_rename
  Future<OpResult> renameNetwork(String from, String to, {required String reason});

  /// admin_undo
  Future<OpResult> undo(String token, {required String reason});
}

/// Section 3 — Decision center.
abstract interface class DecisionsRepository {
  PagedDataSource<DecisionItem> get items;
  Future<Map<String, int>> counts();

  /// admin_decisions_apply: all selected decisions in one atomic batch with a snapshot.
  Future<OpResult> apply(String decision, SelectionSnapshot selection, PageRequest filter, {required String reason});
}

/// Section 4 — Sources.
abstract interface class SourcesRepository {
  Future<List<SourceCard>> sources();
  PagedDataSource<GenericRow> get runs;
  PagedDataSource<GenericRow> get rules;
  PagedDataSource<GenericRow> get enrichment;
  PagedDataSource<GenericRow> get blocks;

  /// admin_source_fetch (server job; irreversible: external requests happened).
  Future<OpResult> fetch(String sourceId, Map<String, String> scope, {required String reason});

  /// admin_source_pause (compensating).
  Future<OpResult> setPaused(String sourceId, bool paused, {required String reason});

  /// admin_source_rollback
  Future<OpResult> rollback(String sourceId, {required String reason});

  /// admin_import_stage → admin_import_commit
  Future<OpResult> stageImport(Map<String, Object?> input, {required String reason});

  /// admin_rules_save
  Future<OpResult> saveRules(List<Map<String, Object?>> rules, {required String reason});

  /// admin_enrichment_apply
  Future<OpResult> applyEnrichment(SelectionSnapshot selection, bool accept, {required String reason});

  /// admin_block_set
  Future<OpResult> setBlock(String kind, String target, bool blocked, {required String reason});
}

/// Section 5 — Program guide.
abstract interface class EpgRepository {
  PagedDataSource<GenericRow> get sources;
  PagedDataSource<GenericRow> get mapping;
  Future<List<GenericRow>> programmes(String channelId, DateTime day);

  /// admin_epg_sync_now
  Future<OpResult> syncNow(String? sourceId, {required String reason});

  /// admin_epg_map
  Future<OpResult> map(SelectionSnapshot selection, {required String reason, int? offsetMinutes});
}

/// Section 6 — Viewer experience & messaging.
abstract interface class ExperienceRepository {
  Future<Map<String, Object?>> settings(String group);
  PagedDataSource<GenericRow> get taxonomy;
  PagedDataSource<GenericRow> get notificationsLog;

  /// admin_settings_set / admin_home_layout_set / admin_release_set / admin_announcement_upsert
  Future<OpResult> saveSettings(String group, Map<String, Object?> values, {required String reason});

  /// admin_notification_send (irreversible; "all viewers" needs explicit confirmation).
  Future<OpResult> sendNotification(Map<String, Object?> message, {required String reason});

  /// admin_taxonomy_upsert
  Future<OpResult> saveTaxonomy(Map<String, Object?> item, {required String reason});
}

/// Section 7 — System.
abstract interface class SystemRepository {
  Future<List<SessionInfo>> sessions();
  PagedDataSource<GenericRow> get schedules;
  PagedDataSource<AuditEntry> get audit;
  PagedDataSource<GenericRow> get errors;
  PagedDataSource<GenericRow> get analytics;

  /// admin_session_revoke (deletes the auth session + records revocation; next request from it is refused).
  Future<OpResult> revokeSession(String sessionId, {required String reason});

  /// admin_task_set / admin_task_run_now
  Future<OpResult> setTask(String taskId, {bool? enabled, bool runNow = false, required String reason});

  /// admin_audit_revert
  Future<OpResult> revert(String auditId, {required String reason});

  /// admin_backup_restore (irreversible; tested on a separate copy first).
  Future<OpResult> restoreBackup(String backupId, {required String reason});

  /// admin_maintenance_cleanup
  Future<OpResult> cleanup({required String reason});
}
