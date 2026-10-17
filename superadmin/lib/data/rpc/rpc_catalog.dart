// Intended server functions (Phase 2), named after the plan (§6, §7, §9). Each entry carries its
// undo class (§9.4) and whether it needs a fresh TOTP (§9.1). Names may still be adjusted when the
// migrations are written; the program only refers to them through this catalog.
import '../../core/tr.dart';
import 'admin_rpc.dart';

abstract final class Rpc {
  // ── Generic ───────────────────────────────────────────────────────────────
  static const undo = RpcSpec('admin_undo', UndoClass.full, Tr('تراجع عن عملية بواسطة رمز التراجع', 'Undo an operation by its undo token'));

  // ── 1. Home ───────────────────────────────────────────────────────────────
  static const jobCancel = RpcSpec('admin_job_cancel', UndoClass.compensating, Tr('إيقاف مهمة جارية', 'Stop a running job'));
  static const jobRetry = RpcSpec('admin_job_retry', UndoClass.compensating, Tr('إعادة تشغيل مهمة موقوفة أو فاشلة', 'Re-run a stopped/failed job'));
  static const alertSetState = RpcSpec('admin_alert_set_state', UndoClass.full, Tr('تمّت رؤيته / تمّ الحل لتنبيه', 'Mark an alert seen / resolved'));

  // ── 2. Channels ───────────────────────────────────────────────────────────
  static const channelCreate = RpcSpec('admin_channel_create', UndoClass.full, Tr('إنشاء قناة مع رابطها الأول', 'Create a channel with its first stream'));
  static const channelUpdate = RpcSpec('admin_channel_update', UndoClass.full, Tr('تعديل حقول قناة (مع قفل الحقل)', 'Edit channel fields (with field lock)'));
  static const channelsBulk = RpcSpec(
    'admin_channels_bulk',
    UndoClass.snapshot,
    Tr('تعديل جماعي: نشر، إخفاء، دولة، فئة…', 'Bulk edit: publish, hide, country, category…'),
  );
  static const channelsTrash = RpcSpec('admin_channels_trash', UndoClass.full, Tr('نقل قنوات للسلة', 'Move channels to trash'));
  static const channelsRestore = RpcSpec('admin_channels_restore', UndoClass.full, Tr('استرجاع من السلة', 'Restore from trash'));
  static const channelsPurge = RpcSpec(
    'admin_channels_purge',
    UndoClass.irreversible,
    Tr('حذف نهائي من السلة', 'Delete permanently from trash'),
    needsRecentMfa: true,
  );
  static const channelsRenumber = RpcSpec('admin_channels_renumber', UndoClass.full, Tr('تطبيق خطة ترقيم', 'Apply a numbering plan'));
  static const networkRename = RpcSpec('admin_network_rename', UndoClass.full, Tr('توحيد اسم شبكة على كل قنواتها', 'Rename a network across its channels'));
  static const streamsUpdate = RpcSpec(
    'admin_streams_update',
    UndoClass.full,
    Tr('ترتيب/تعطيل/ترويسات روابط قناة', 'Order / disable / headers of channel streams'),
  );
  static const streamsProbe = RpcSpec('admin_streams_probe', UndoClass.irreversible, Tr('فحص روابط (طلبات خارجية)', 'Probe streams (external requests)'));

  // ── 3. Decision center ────────────────────────────────────────────────────
  static const decisionsApply = RpcSpec(
    'admin_decisions_apply',
    UndoClass.snapshot,
    Tr('تنفيذ قرارات محددة دفعة وحدة', 'Apply selected decisions in one batch'),
  );
  static const channelsMerge = RpcSpec('admin_channels_merge', UndoClass.full, Tr('دمج قنوات', 'Merge channels'));
  static const channelsUnmerge = RpcSpec('admin_channels_unmerge', UndoClass.full, Tr('فك الدمج', 'Unmerge'));

  // ── 4. Sources ────────────────────────────────────────────────────────────
  static const importStage = RpcSpec('admin_import_stage', UndoClass.full, Tr('رفع وتحليل ملف استيراد (بدون كتابة)', 'Upload + analyse an import (no write)'));
  static const importCommit = RpcSpec('admin_import_commit', UndoClass.snapshot, Tr('قبول دفعة استيراد', 'Accept an import batch'));
  static const sourceFetch = RpcSpec('admin_source_fetch', UndoClass.irreversible, Tr('جلب مصدر الآن (مهمة على الخادم)', 'Fetch a source now (server job)'));
  static const sourceUpsert = RpcSpec(
    'admin_source_upsert',
    UndoClass.full,
    Tr('إعدادات مصدر (الجدول، النطاق، الشروط)', 'Source settings (schedule, scope, terms)'),
  );
  static const sourcePause = RpcSpec(
    'admin_source_pause',
    UndoClass.compensating,
    Tr('إيقاف مصدر / إعادة تفعيله', 'Pause / resume a source'),
    needsRecentMfa: true,
  );
  static const sourceRollback = RpcSpec('admin_source_rollback', UndoClass.snapshot, Tr('الرجوع لآخر نسخة سليمة', 'Roll back to the last good snapshot'));
  static const enrichmentApply = RpcSpec(
    'admin_enrichment_apply',
    UndoClass.full,
    Tr('قبول/رفض اقتراحات تحسين البيانات', 'Accept / reject enrichment suggestions'),
  );
  static const rulesSave = RpcSpec('admin_rules_save', UndoClass.full, Tr('حفظ وترتيب قواعد التحويل', 'Save + order transform rules'));
  static const blockSet = RpcSpec('admin_block_set', UndoClass.compensating, Tr('إيقاف فوري لمصدر/قناة/رابط', 'Immediate takedown of a source/channel/stream'));

  // ── 5. EPG ────────────────────────────────────────────────────────────────
  static const epgSourceUpsert = RpcSpec('admin_epg_source_upsert', UndoClass.full, Tr('إضافة/ترتيب مصادر الدليل', 'Add / order EPG sources'));
  static const epgSyncNow = RpcSpec('admin_epg_sync_now', UndoClass.irreversible, Tr('زامن الدليل الآن', 'Sync EPG now'));
  static const epgMap = RpcSpec('admin_epg_map', UndoClass.full, Tr('ربط قناة بمعرّف دليل + الإزاحة', 'Map a channel to an EPG id + offset'));

  // ── 6. Viewer experience ──────────────────────────────────────────────────
  static const homeLayoutSet = RpcSpec('admin_home_layout_set', UndoClass.full, Tr('صفوف رئيسية المشاهدين وترتيبها', 'Viewer home rows and order'));
  static const taxonomyUpsert = RpcSpec('admin_taxonomy_upsert', UndoClass.full, Tr('الفئات والدول واللغات', 'Categories, countries, languages'));
  static const notificationSend = RpcSpec(
    'admin_notification_send',
    UndoClass.irreversible,
    Tr('إرسال إشعار للمشاهدين', 'Send a notification to viewers'),
    needsRecentMfa: true,
  );
  static const announcementUpsert = RpcSpec(
    'admin_announcement_upsert',
    UndoClass.compensating,
    Tr('نشر/إزالة شريط إعلان', 'Publish / remove an announcement banner'),
  );
  static const settingsSet = RpcSpec('admin_settings_set', UndoClass.compensating, Tr('إعدادات عامة تصل للأجهزة', 'Settings delivered to devices'));
  static const releaseSet = RpcSpec('admin_release_set', UndoClass.compensating, Tr('آخر نسخة والتحديث الإجباري', 'Latest version and forced update'));

  // ── 7. System ─────────────────────────────────────────────────────────────
  static const sessionRevoke = RpcSpec('admin_session_revoke', UndoClass.compensating, Tr('إنهاء جلسة مدير', 'End an admin session'), needsRecentMfa: true);
  static const taskSet = RpcSpec('admin_task_set', UndoClass.full, Tr('تفعيل/جدول مهمة دورية', 'Enable / schedule a periodic task'));
  static const taskRunNow = RpcSpec('admin_task_run_now', UndoClass.irreversible, Tr('شغّل المهمة الآن', 'Run a task now'));
  static const auditRevert = RpcSpec('admin_audit_revert', UndoClass.full, Tr('رجّع تغيير من السجل', 'Revert a change from the audit log'));
  static const backupRestore = RpcSpec(
    'admin_backup_restore',
    UndoClass.irreversible,
    Tr('استعادة نسخة احتياطية على الإنتاج', 'Restore a backup onto production'),
    needsRecentMfa: true,
  );
  static const maintenanceCleanup = RpcSpec('admin_maintenance_cleanup', UndoClass.irreversible, Tr('تنظيف البيانات القديمة', 'Clean up old data'));

  static const all = <RpcSpec>[
    undo, jobCancel, jobRetry, alertSetState, //
    channelCreate, channelUpdate, channelsBulk, channelsTrash, channelsRestore, channelsPurge, channelsRenumber,
    networkRename, streamsUpdate, streamsProbe, //
    decisionsApply, channelsMerge, channelsUnmerge, //
    importStage, importCommit, sourceFetch, sourceUpsert, sourcePause, sourceRollback, enrichmentApply, rulesSave, blockSet, //
    epgSourceUpsert, epgSyncNow, epgMap, //
    homeLayoutSet, taxonomyUpsert, notificationSend, announcementUpsert, settingsSet, releaseSet, //
    sessionRevoke, taskSet, taskRunNow, auditRevert, backupRestore, maintenanceCleanup,
  ];
}
