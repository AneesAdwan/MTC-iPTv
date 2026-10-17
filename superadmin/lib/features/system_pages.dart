// Section 7 — System: account & sessions, scheduled tasks, audit log, backup, diagnostics, analytics.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/nav.dart';
import '../app/theme/tokens.dart';
import '../auth/auth_controller.dart';
import '../core/env.dart';
import '../core/tr.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../data/rpc/rpc_catalog.dart';
import '../ui/data_table.dart';
import '../ui/filter_bar.dart';
import '../ui/page_scaffold.dart';
import '../ui/states.dart';
import '../ui/widgets.dart';
import 'common.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final repo = ref.watch(systemRepoProvider);
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    final c = context.colors;
    final sessions = Panel(
      key: const ValueKey('sessions-panel'),
      title: const Tr('الجلسات النشطة', 'Active sessions'),
      child: AsyncView<List<SessionInfo>>(
        load: repo.sessions,
        builder: (context, list, _) => Column(
          children: [
            for (final s in list)
              ListTile(
                leading: Icon(Icons.computer, color: s.current ? c.ok : c.textMuted),
                title: Text(s.device),
                subtitle: Text(
                  context.tr(
                    Tr(
                      'الإصدار ${s.version} · أول نشاط ${fmtDateTime(s.firstSeen)} · آخر نشاط ${fmtDateTime(s.lastSeen)}',
                      'Version ${s.version} · first ${fmtDateTime(s.firstSeen)} · last ${fmtDateTime(s.lastSeen)}',
                    ),
                  ),
                ),
                trailing: s.current
                    ? Pill(context.tr(const Tr('هالجهاز', 'This device')), tone: Tone.ok)
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: c.bad),
                        onPressed: () => confirmAndRun(
                          context,
                          ref,
                          title: Tr('إنهاء جلسة ${s.device}', 'End session ${s.device}'),
                          spec: Rpc.sessionRevoke,
                          unit: const Tr('جلسة', 'session'),
                          run: (r) => repo.revokeSession(s.id, reason: r),
                        ),
                        child: Text(context.tr(const Tr('إنهاء الجلسة', 'End session'))),
                      ),
              ),
          ],
        ),
      ),
    );
    return ServicePage(
      page: Nav.system.pages[0],
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tab != 'sessions') ...[
            Panel(
              title: const Tr('الحساب', 'Account'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FieldRow(
                    label: const Tr('البريد', 'Email'),
                    field: Text(auth.email ?? '—', textDirection: TextDirection.ltr),
                  ),
                  FieldRow(
                    label: const Tr('مستوى الجلسة', 'Session level'),
                    field: Text(auth.aal, textDirection: TextDirection.ltr),
                  ),
                  FieldRow(
                    label: const Tr('كلمة المرور', 'Password'),
                    field: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton(onPressed: null, child: Text(context.tr(const Tr('تغيير (المرحلة 7)', 'Change (Phase 7)')))),
                    ),
                  ),
                  FieldRow(
                    label: const Tr('تطبيقات التحقق', 'Authenticator apps'),
                    field: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton(onPressed: null, child: Text(context.tr(const Tr('إدارة (المرحلة 7)', 'Manage (Phase 7)')))),
                    ),
                  ),
                  Text(
                    context.tr(
                      const Tr(
                        'الخادم بيرفض أي عملية إدارة بدون جلسة تحقق بخطوتين حيّة وغير ملغاة.',
                        'The server refuses any admin operation without a live, non-revoked two-step session.',
                      ),
                    ),
                    style: TextStyle(color: c.textDim, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
          ],
          sessions,
        ],
      ),
    );
  }
}

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.system.pages[1],
    source: (ref) => ref.read(systemRepoProvider).schedules,
    selectable: true,
    columns: const [
      RowColumn('task', Tr('المهمة', 'Task'), flex: 3),
      RowColumn('schedule', Tr('الجدول', 'Schedule'), flex: 2),
      RowColumn('executor', Tr('المنفّذ', 'Executor'), flex: 2),
      RowColumn('enabled', Tr('مفعّلة', 'Enabled')),
      RowColumn('last', Tr('آخر تشغيل', 'Last run'), flex: 2),
      RowColumn('result', Tr('النتيجة', 'Result'), tone: true),
    ],
    bulkActions: (context, ref, sel, req) => [
      FilledButton(
        onPressed: () => confirmAndRun(
          context,
          ref,
          title: const Tr('شغّل الآن', 'Run now'),
          spec: Rpc.taskRunNow,
          affected: sel.count,
          unit: const Tr('مهمة', 'tasks'),
          run: (r) => ref.read(systemRepoProvider).setTask(sel.snapshot().ids.join(','), runNow: true, reason: r),
        ),
        child: Text(context.tr(const Tr('شغّل الآن', 'Run now'))),
      ),
      OutlinedButton(
        onPressed: () => confirmAndRun(
          context,
          ref,
          title: const Tr('إيقاف المهام', 'Disable tasks'),
          spec: Rpc.taskSet,
          affected: sel.count,
          unit: const Tr('مهمة', 'tasks'),
          run: (r) => ref.read(systemRepoProvider).setTask(sel.snapshot().ids.join(','), enabled: false, reason: r),
        ),
        child: Text(context.tr(const Tr('أوقف', 'Disable'))),
      ),
    ],
  );
}

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = routeParams(context);
    final req = requestFrom(params);
    final c = context.colors;
    return ServicePage(
      page: Nav.system.pages[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            pageId: 'system.audit',
            params: params,
            filters: const [
              FilterDef('action', Tr('النوع', 'Type'), [
                FilterOption('admin_channel_update', Tr('تعديل قناة', 'Channel edit')),
                FilterOption('admin_channels_bulk', Tr('تعديل جماعي', 'Bulk edit')),
              ]),
            ],
            onChanged: (p) => setRouteParams(context, p),
          ),
          const SizedBox(height: Space.md),
          Expanded(
            child: MtcDataTable<AuditEntry>(
              source: ref.watch(systemRepoProvider).audit,
              query: req.query,
              filters: req.filters,
              rowHeight: 52,
              columns: [
                TableColumn(label: const Tr('إيمتى', 'When'), width: 140, cell: (context, a) => Text(fmtDateTime(a.at))),
                TableColumn(
                  label: const Tr('مين', 'Who'),
                  flex: 2,
                  cell: (context, a) => Text('${a.actor}\n${a.device}', style: const TextStyle(fontSize: 12)),
                ),
                TableColumn(
                  label: const Tr('شو', 'What'),
                  flex: 3,
                  cell: (context, a) => Text('${a.target} · ${a.field}: ${a.before} → ${a.after}', overflow: TextOverflow.ellipsis),
                ),
                TableColumn(
                  label: const Tr('ليش', 'Why'),
                  flex: 2,
                  cell: (context, a) => Text(
                    a.reason,
                    style: TextStyle(color: c.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TableColumn(
                  label: const Tr('رجّع', 'Revert'),
                  width: 90,
                  cell: (context, a) => TextButton(
                    onPressed: () => confirmAndRun(
                      context,
                      ref,
                      title: const Tr('رجّع هالتغيير', 'Revert this change'),
                      spec: Rpc.auditRevert,
                      run: (r) => ref.read(systemRepoProvider).revert(a.id, reason: r),
                    ),
                    child: Text(context.tr(const Tr('رجّع', 'Revert'))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ServicePage(
      page: Nav.system.pages[3],
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            title: const Tr('نسخة مشفّرة على جهازك', 'Encrypted copy on this PC'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(const Tr('يدوي + أسبوعي، فوق نسخ Supabase اليومية.', 'Manual + weekly, on top of Supabase daily backups.')),
                  style: TextStyle(color: c.textMuted),
                ),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.backup, size: 18),
                      label: Text(context.tr(const Tr('نسخة الآن (المرحلة 7)', 'Back up now (Phase 7)'))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Panel(
            title: const Tr('استعادة', 'Restore'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    const Tr(
                      'الاستعادة بتجرّب أول على نسخة منفصلة. الاستعادة على الإنتاج غير قابلة للعكس: تأكيد بكتابة + نسخة قبلها + تحقق حديث.',
                      'Restore is tried on a separate copy first. Restoring onto production is irreversible: typed confirmation + a backup first + a recent TOTP.',
                    ),
                  ),
                  style: TextStyle(color: c.textMuted),
                ),
                const SizedBox(height: Space.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.bad,
                      side: BorderSide(color: c.bad),
                    ),
                    onPressed: () => confirmAndRun(
                      context,
                      ref,
                      title: const Tr('استعادة على الإنتاج', 'Restore onto production'),
                      spec: Rpc.backupRestore,
                      unit: const Tr('نسخة', 'backup'),
                      confirmLabel: const Tr('استعد', 'Restore'),
                      run: (r) => ref.read(systemRepoProvider).restoreBackup('latest', reason: r),
                    ),
                    child: Text(context.tr(const Tr('استعادة على الإنتاج…', 'Restore onto production…'))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return RecordsTablePage(
      page: Nav.system.pages[4],
      source: (ref) => ref.read(systemRepoProvider).errors,
      header: Panel(
        title: const Tr('الاتصال بالخادم', 'Server connection'),
        actions: [
          OutlinedButton.icon(
            onPressed: auth.recheck,
            icon: const Icon(Icons.network_check, size: 18),
            label: Text(context.tr(const Tr('افحص الآن', 'Check now'))),
          ),
          const SizedBox(width: Space.sm),
          OutlinedButton(
            onPressed: () => confirmAndRun(
              context,
              ref,
              title: const Tr('تنظيف البيانات القديمة', 'Clean up old data'),
              spec: Rpc.maintenanceCleanup,
              run: (r) => ref.read(systemRepoProvider).cleanup(reason: r),
            ),
            child: Text(context.tr(const Tr('تنظيف', 'Clean up'))),
          ),
        ],
        child: ValueListenableBuilder<DateTime?>(
          valueListenable: auth.lastVerified,
          builder: (context, at, _) => Text(
            '${Env.supabaseUrl}  ·  ${context.tr(at == null ? const Tr('ما انفحص بعد', 'not checked yet') : Tr('آخر تأكيد ${fmtDateTime(at)}', 'last confirmed ${fmtDateTime(at)}'))}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
      columns: const [
        RowColumn('at', Tr('إيمتى', 'When'), flex: 2),
        RowColumn('where', Tr('وين', 'Where'), flex: 2),
        RowColumn('message', Tr('الخطأ', 'Error'), flex: 4),
      ],
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => RecordsTablePage(
    page: Nav.system.pages[5],
    source: (ref) => ref.read(systemRepoProvider).analytics,
    filters: const [
      FilterDef('period', Tr('الفترة', 'Period'), [
        FilterOption('day', Tr('يوم', 'Day')),
        FilterOption('week', Tr('أسبوع', 'Week')),
        FilterOption('month', Tr('شهر', 'Month')),
      ]),
    ],
    columns: const [
      RowColumn('channel', Tr('القناة', 'Channel'), flex: 3),
      RowColumn('plays', Tr('مشاهدات', 'Plays')),
      RowColumn('success', Tr('نسبة النجاح', 'Success')),
      RowColumn('startup', Tr('زمن البدء', 'Startup')),
    ],
    actions: [OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.table_view, size: 18), label: Text(context.tr(const Tr('تصدير CSV', 'Export CSV'))))],
  );
}
