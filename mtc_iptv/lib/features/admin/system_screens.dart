// المجموعة H — الأمن والنظام (§9.10):
//   H1 الحساب والأمان · H2 المهام المجدولة · H3 سجل التدقيق · H4 النسخ الاحتياطي · H5 الصيانة والتشخيص
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../core/backend/backend.dart';
import '../../data/admin/admin_device.dart';
import '../../data/admin/admin_repository.dart';
import '../../data/admin/backup_service.dart';
import '../../data/admin/scheduler.dart';
import 'dashboard_screen.dart' show AuditTile;
import 'jobs_screen.dart' show taskLabel;
import 'widgets/admin_widgets.dart';

// ── H1 الحساب والأمان ──────────────────────────────────────────────────────
final _factorsProvider = FutureProvider.autoDispose<List<Factor>>((ref) async {
  final c = ref.watch(supabaseProvider);
  if (c == null) return const [];
  return (await c.auth.mfa.listFactors()).all;
});

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _addFactor(BuildContext context, WidgetRef ref) async {
    final c = ref.read(supabaseProvider);
    if (c == null) return;
    final t = L10n.of(context);
    try {
      final f = await c.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MTC-iPTv', friendlyName: 'backup-${DateTime.now().millisecondsSinceEpoch}');
      if (!context.mounted) return;
      final code = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(t.acAddFactor),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(color: Colors.white, padding: const EdgeInsets.all(8), child: QrImageView(data: f.totp!.uri, size: 200)),
              const SizedBox(height: Space.sm),
              SelectableText(f.totp!.secret, textDirection: TextDirection.ltr),
              TextField(
                controller: code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                decoration: InputDecoration(labelText: t.mfaCode),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.verify))],
        ),
      );
      if (ok == true) {
        await c.auth.mfa.challengeAndVerify(factorId: f.id, code: code.text.trim());
        if (context.mounted) toast(context, t.saved);
      } else {
        await c.auth.mfa.unenroll(f.id); // لم يُكمَل: لا نترك عاملًا غير مُتحقق منه
      }
    } catch (e) {
      if (context.mounted) toast(context, t.saveFailed('$e'));
    }
    ref.invalidate(_factorsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final client = ref.watch(supabaseProvider);
    final user = client?.auth.currentUser;
    final factors = ref.watch(_factorsProvider).value ?? const <Factor>[];
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      SectionCard(
        title: t.acEmail,
        child: Text(user?.email ?? '—', textDirection: TextDirection.ltr, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.acMfa,
        trailing: FilledButton.tonal(onPressed: () => _addFactor(context, ref), child: Text(t.acAddFactor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final f in factors)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(f.status == FactorStatus.verified ? Icons.verified_user_rounded : Icons.hourglass_empty_rounded,
                  color: f.status == FactorStatus.verified ? healthColor('playable') : c.textMuted),
              title: Text(f.friendlyName ?? f.factorType.name),
              subtitle: Text(shortTime(f.createdAt.toLocal())),
            ),
          Text(t.acAddFactorHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
          const SizedBox(height: Space.xs),
          Text(t.acRecovery, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
        ]),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.acChangePassword,
        child: _PasswordForm(client: client),
      ),
      const SizedBox(height: Space.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
          icon: const Icon(Icons.logout_rounded),
          label: Text(t.acSignOutAll),
          onPressed: client == null
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      content: Text(t.acSignOutAllConfirm),
                      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.acSignOutAll))],
                    ),
                  );
                  if (ok == true) await client.auth.signOut(scope: SignOutScope.global);
                },
        ),
      ),
    ]);
  }
}

class _PasswordForm extends StatefulWidget {
  final SupabaseClient? client;
  const _PasswordForm({required this.client});
  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final p1 = TextEditingController(), p2 = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    p1.dispose();
    p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final valid = p1.text.length >= 10 && p1.text == p2.text;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: p1, obscureText: true, decoration: InputDecoration(labelText: t.acNewPassword), onChanged: (_) => setState(() {})),
      TextField(controller: p2, obscureText: true, decoration: InputDecoration(labelText: t.acNewPassword), onChanged: (_) => setState(() {})),
      const SizedBox(height: Space.sm),
      FilledButton(
        onPressed: !valid || busy || widget.client == null
            ? null
            : () async {
                setState(() => busy = true);
                try {
                  await widget.client!.auth.updateUser(UserAttributes(password: p1.text));
                  p1.clear();
                  p2.clear();
                  if (context.mounted) toast(context, t.saved);
                } catch (e) {
                  if (context.mounted) toast(context, t.saveFailed('$e'));
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        child: Text(t.save),
      ),
    ]);
  }
}

// ── H2 المهام المجدولة ─────────────────────────────────────────────────────
final _tasksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => await ref.watch(adminRepoProvider)?.scheduledTasks() ?? const []);
final _startupProvider = FutureProvider.autoDispose<bool>((ref) => StartWithWindows.isEnabled());

class SchedulerScreen extends ConsumerWidget {
  const SchedulerScreen({super.key});

  String _range(String? r, L10n t) {
    final m = RegExp(r'^\[(\d+),(\d+)\)$').firstMatch(r ?? '');
    return m == null ? t.shAnyTime : '${m[1]}:00–${int.parse(m[2]!) - 1}:59';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(context), c = context.colors;
    final dev = ref.watch(adminDeviceProvider).value ?? const AdminDevice();
    final startup = ref.watch(_startupProvider).value ?? false;
    final sched = ref.watch(schedulerProvider);
    final tasks = ref.watch(_tasksProvider).value ?? const <Map<String, dynamic>>[];
    ref.listen(schedulerProvider, (p, n) {
      if (p?.running != n.running) ref.invalidate(_tasksProvider);
    });
    final ctrl = ref.read(adminDeviceProvider.notifier);
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      SectionCard(
        title: t.sH2,
        child: Column(children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.shEnabled), value: dev.schedulerEnabled, onChanged: (v) => ctrl.save(dev.copyWith(schedulerEnabled: v))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.shTray), value: dev.keepInTray, onChanged: (v) => ctrl.save(dev.copyWith(keepInTray: v))),
          if (Platform.isWindows)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.shStartup),
              value: startup,
              onChanged: (v) async {
                try {
                  await StartWithWindows.set(v);
                } catch (e) {
                  if (context.mounted) toast(context, t.saveFailed('$e'));
                }
                ref.invalidate(_startupProvider);
              },
            ),
          Align(alignment: AlignmentDirectional.centerStart, child: Text(t.shNote, style: TextStyle(color: c.textMuted, fontSize: 12.5))),
          if (sched.running != null) Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text(t.shRunning(taskLabel(t, sched.running!)), style: TextStyle(color: c.accent))),
          if (sched.missedOnStart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(t.shMissed(sched.missedOnStart.map((k) => taskLabel(t, k)).join('، ')), style: TextStyle(color: healthColor('degraded'))),
            ),
          if (sched.lastError != null) Text(sched.lastError!, style: TextStyle(color: healthColor('unavailable'), fontSize: 12)),
        ]),
      ),
      const SizedBox(height: Space.md),
      for (final k in tasks)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.line)),
            child: ListTile(
              leading: Switch(
                value: k['enabled'] == true,
                onChanged: (v) async {
                  await ref.read(adminRepoProvider)?.updateTask('${k['key']}', {'enabled': v});
                  ref.invalidate(_tasksProvider);
                },
              ),
              title: Text(taskLabel(t, '${k['key']}'), style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  t.taskEvery((k['interval_min'] as num?)?.toInt() ?? 0),
                  '${t.shAllowed}: ${_range(k['allowed_hours'] as String?, t)}',
                  if (k['last_run_at'] != null) t.taskLast(shortTime(DateTime.parse('${k['last_run_at']}').toLocal())),
                  if (k['next_run_at'] != null) t.shNext(shortTime(DateTime.parse('${k['next_run_at']}').toLocal())),
                ].join(' · '),
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
              trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.xs, children: [
                if (k['last_status'] != null) Pill('${k['last_status']}', k['last_status'] == 'ok' ? healthColor('playable') : healthColor(k['last_status'] == 'failed' ? 'unavailable' : 'inconclusive')),
                IconButton(
                  tooltip: t.aEdit,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: () async {
                    final iv = TextEditingController(text: '${k['interval_min']}');
                    final from = TextEditingController(text: RegExp(r'^\[(\d+),').firstMatch('${k['allowed_hours'] ?? ''}')?[1] ?? '');
                    final to = TextEditingController(text: RegExp(r',(\d+)\)$').firstMatch('${k['allowed_hours'] ?? ''}')?[1] ?? '');
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: Text(taskLabel(t, '${k['key']}')),
                        content: SizedBox(
                          width: 360,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(controller: iv, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: t.shInterval)),
                            Row(children: [
                              Expanded(child: TextField(controller: from, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${t.shAllowed} (0–23)'))),
                              const SizedBox(width: Space.sm),
                              Expanded(child: TextField(controller: to, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '→ (1–24)'))),
                            ]),
                          ]),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)), FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.save))],
                      ),
                    );
                    if (ok != true) return;
                    final a = int.tryParse(from.text), b = int.tryParse(to.text);
                    await ref.read(adminRepoProvider)?.updateTask('${k['key']}', {
                      'interval_min': (int.tryParse(iv.text) ?? 60).clamp(1, 10080),
                      'allowed_hours': a == null || b == null || a >= b ? null : '[${a.clamp(0, 23)},${b.clamp(1, 24)})',
                    });
                    ref.invalidate(_tasksProvider);
                  },
                ),
                FilledButton.tonal(
                  onPressed: sched.running != null ? null : () => ref.read(schedulerProvider.notifier).tick(force: '${k['key']}'),
                  child: Text(t.shRunNow),
                ),
              ]),
            ),
          ),
        ),
    ]);
  }
}

// ── H3 سجل التدقيق ─────────────────────────────────────────────────────────
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});
  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? table, action;
  final rowId = TextEditingController();
  int page = 0;
  (List<AuditEntry>, List<Map<String, dynamic>>, int)? data;
  bool loading = false;

  static const tables = ['channels', 'streams', 'playlist_sources', 'site_settings', 'categories', 'countries', 'languages', 'admin_users', 'epg_sources', 'transform_rules', 'xtream_accounts'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    rowId.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    setState(() => loading = true);
    try {
      final d = await repo.auditSearch(table: table, action: action, rowId: rowId.text, page: page);
      if (mounted) setState(() => data = d);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _export() async {
    final rows = data?.$2 ?? const [];
    String cell(Object? v) {
      final s = v == null ? '' : (v is String ? v : jsonEncode(v));
      return '"${s.replaceAll('"', '""')}"';
    }

    final csv = StringBuffer('at,action,table,row_id,reason,before,after\n');
    for (final r in rows) {
      csv.writeln([r['at'], r['action'], r['table_name'], r['row_id'], r['reason'], r['before'], r['after']].map(cell).join(','));
    }
    final loc = await getSaveLocation(suggestedName: 'mtc-audit-${DateTime.now().toIso8601String().substring(0, 10)}.csv');
    if (loc == null) return;
    await File(loc.path).writeAsString(csv.toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final items = data?.$1 ?? const <AuditEntry>[];
    final total = data?.$3 ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownButton<String?>(
            value: table,
            hint: Text(t.auAllTables),
            items: [DropdownMenuItem(value: null, child: Text(t.auAllTables)), for (final x in tables) DropdownMenuItem(value: x, child: Text(x))],
            onChanged: (v) {
              table = v;
              page = 0;
              _load();
            },
          ),
          DropdownButton<String?>(
            value: action,
            hint: Text(t.auAllActions),
            items: [DropdownMenuItem(value: null, child: Text(t.auAllActions)), for (final x in const ['INSERT', 'UPDATE', 'DELETE']) DropdownMenuItem(value: x, child: Text(x))],
            onChanged: (v) {
              action = v;
              page = 0;
              _load();
            },
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: rowId,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(hintText: t.auSearch, isDense: true, prefixIcon: const Icon(Icons.search_rounded)),
              onSubmitted: (_) {
                page = 0;
                _load();
              },
            ),
          ),
          OutlinedButton.icon(onPressed: items.isEmpty ? null : _export, icon: const Icon(Icons.download_rounded, size: 18), label: Text(t.auExport)),
          if (loading) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: Space.lg), children: [
          for (final e in items)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: AuditTile(entry: e),
              children: [
                for (final (k, a, b) in e.changes.take(40))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 160, child: Text(k, style: TextStyle(color: c.textMuted, fontSize: 12))),
                      Expanded(child: Text('${a ?? '∅'}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                      Expanded(child: Text('${b ?? '∅'}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12))),
                    ]),
                  ),
              ],
            ),
        ]),
      ),
      Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
        child: Row(children: [
          Text(total == 0 ? '' : t.pageOf(page * 100 + 1, page * 100 + items.length, total), style: TextStyle(color: c.textMuted)),
          const Spacer(),
          IconButton(
            onPressed: page == 0
                ? null
                : () {
                    page--;
                    _load();
                  },
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: page * 100 + items.length >= total
                ? null
                : () {
                    page++;
                    _load();
                  },
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
      ),
    ]);
  }
}

// ── H4 النسخ الاحتياطي ─────────────────────────────────────────────────────
class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});
  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  final pass = TextEditingController();
  bool busy = false, hasPass = false;
  String? opened;
  Map<String, dynamic>? doc;
  Map<String, int> current = {};
  final chosen = <String>{};
  final channelId = TextEditingController();

  @override
  void initState() {
    super.initState();
    readBackupPassphrase().then((p) => mounted ? setState(() => hasPass = p != null) : null);
  }

  @override
  void dispose() {
    pass.dispose();
    channelId.dispose();
    super.dispose();
  }

  Future<void> _wrap(Future<void> Function() f) async {
    setState(() => busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) toast(context, e is BackupError ? '${e.kind} ${e.detail}' : '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final dev = ref.watch(adminDeviceProvider).value ?? const AdminDevice();
    final dir = dev.backupDir;
    final files = dir == null || !Directory(dir).existsSync()
        ? const <File>[]
        : (Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.mtcbak')).toList()..sort((a, b) => b.path.compareTo(a.path)));
    final counts = (doc?['counts'] as Map?)?.cast<String, dynamic>() ?? const {};

    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      SectionCard(
        title: t.bkFolder,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(dir ?? '—', textDirection: TextDirection.ltr, style: TextStyle(color: c.text))),
            OutlinedButton(
              onPressed: () async {
                final d = await getDirectoryPath();
                if (d != null) await ref.read(adminDeviceProvider.notifier).save(dev.copyWith(backupDir: d));
              },
              child: Text(t.bkChooseFolder),
            ),
          ]),
          const SizedBox(height: Space.sm),
          Row(children: [
            Expanded(
              child: TextField(
                controller: pass,
                obscureText: true,
                decoration: InputDecoration(labelText: t.bkPassphrase, helperText: hasPass ? '••••••••' : null),
              ),
            ),
            const SizedBox(width: Space.sm),
            FilledButton.tonal(
              onPressed: () async {
                if (pass.text.length < 8) return;
                await writeBackupPassphrase(pass.text);
                pass.clear();
                setState(() => hasPass = true);
                if (context.mounted) toast(context, t.saved);
              },
              child: Text(t.save),
            ),
          ]),
          const SizedBox(height: Space.xs),
          Text(t.bkPassphraseHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: busy || dir == null || !hasPass
                ? null
                : () => _wrap(() async {
                      final svc = ref.read(backupServiceProvider)!;
                      final repo = ref.read(adminRepoProvider)!;
                      final runId = await repo.startRun('backup', Platform.localHostname);
                      try {
                        final r = await svc.create(dir: dir, passphrase: (await readBackupPassphrase())!, kind: 'manual');
                        await repo.finishRun(runId!, status: 'ok', summary: {'file': r.path.split(Platform.pathSeparator).last, 'bytes': r.bytes, 'counts': r.counts, 'manual': true});
                        if (context.mounted) toast(context, t.bkDone(r.path.split(Platform.pathSeparator).last));
                      } catch (e) {
                        await repo.finishRun(runId!, status: 'failed', error: '$e');
                        rethrow;
                      }
                    }),
            icon: busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.backup_rounded),
            label: Text(t.bkNow),
          ),
          if (dir == null || !hasPass) Padding(padding: const EdgeInsets.only(top: Space.xs), child: Text(t.bkNotConfigured, style: TextStyle(color: healthColor('degraded')))),
        ]),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.bkList,
        child: Column(children: [
          for (final f in files.take(60))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(f.path.contains('_daily') ? Icons.event_repeat_rounded : Icons.save_rounded, color: c.textMuted),
              title: Text(f.uri.pathSegments.last, textDirection: TextDirection.ltr, style: TextStyle(color: opened == f.path ? c.accent : c.text, fontSize: 13)),
              subtitle: Text('${(f.lengthSync() / 1024).round()} KB', style: TextStyle(color: c.textMuted)),
              trailing: OutlinedButton(
                onPressed: busy || !hasPass
                    ? null
                    : () => _wrap(() async {
                          final d = await BackupService.open(f.path, (await readBackupPassphrase())!);
                          final repo = ref.read(adminRepoProvider)!;
                          final now = <String, int>{};
                          for (final tb in AdminRepository.restorableTables) {
                            try {
                              now[tb] = await repo.tableCount(tb);
                            } catch (_) {}
                          }
                          setState(() {
                            doc = d;
                            opened = f.path;
                            current = now;
                            chosen.clear();
                          });
                        }),
                child: Text(t.bkOpen),
              ),
            ),
        ]),
      ),
      if (doc != null) ...[
        const SizedBox(height: Space.md),
        SectionCard(
          title: '${doc!['created_at']} · ${doc!['env']} · v${doc!['app_version']}',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.bkRestoreNote, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            for (final tb in AdminRepository.restorableTables)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: chosen.contains(tb),
                onChanged: (v) => setState(() => v == true ? chosen.add(tb) : chosen.remove(tb)),
                title: Text(tb),
                secondary: Text(t.bkCounts((counts[tb] as num?)?.toInt() ?? 0, current[tb] ?? 0), style: TextStyle(color: c.textMuted, fontSize: 12)),
              ),
            Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              FilledButton(
                // معطّل مؤقتًا (جرد A-129): الاستعادة كانت تحوّل كل القنوات المنشورة إلى «معلّقة» بسبب مشغّل المراجعة.
                // تعود بإصلاح خادمي في SuperAdmin الجديد.
                onPressed: kLegacyRestoreDisabled || busy || chosen.isEmpty
                    ? null
                    : () => _wrap(() async {
                          final r = await ref.read(backupServiceProvider)!.restore(doc!, tables: chosen.toList());
                          if (context.mounted) toast(context, t.bkRestored(r.entries.map((e) => '${e.key} ${e.value}').join(' · ')));
                        }),
                child: Text(t.bkRestoreTables),
              ),
              SizedBox(width: 320, child: TextField(controller: channelId, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t.bkChannelId, isDense: true))),
              OutlinedButton(
                onPressed: kLegacyRestoreDisabled || busy
                    ? null
                    : () => _wrap(() async {
                          if (channelId.text.trim().isEmpty) return;
                          final r = await ref.read(backupServiceProvider)!.restore(doc!, channelId: channelId.text.trim());
                          if (context.mounted) toast(context, t.bkRestored(r.entries.map((e) => '${e.key} ${e.value}').join(' · ')));
                        }),
                child: Text(t.bkRestoreChannel),
              ),
            ]),
          ]),
        ),
      ],
    ]);
  }
}

// ── H5 الصيانة والتشخيص ────────────────────────────────────────────────────
final _statusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return const {};
  final sw = Stopwatch()..start();
  await repo.tableCount('countries');
  final latency = sw.elapsedMilliseconds;
  final sizes = <String, int>{};
  for (final tb in [...AdminRepository.backupTables.keys, 'epg_programmes', 'task_runs']) {
    try {
      sizes[tb] = await repo.tableCount(tb);
    } catch (_) {}
  }
  final tasks = await repo.scheduledTasks();
  DateTime? last(String key) {
    final t = tasks.where((x) => x['key'] == key && x['last_status'] == 'ok').firstOrNull;
    return t == null || t['last_run_at'] == null ? null : DateTime.parse('${t['last_run_at']}');
  }

  final runs = await repo.taskRuns(limit: 100);
  DateTime? lastRun(String key) {
    final r = runs.where((x) => x['task_key'] == key && x['status'] == 'ok').firstOrNull;
    return r == null ? null : DateTime.parse('${r['started_at']}');
  }

  final epg = [last('epg'), lastRun('epg')].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  final bak = [last('backup'), lastRun('backup')].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  final now = DateTime.now().toUtc();
  return {
    'latency': latency,
    'sizes': sizes,
    'tasks': tasks,
    'epgStale': epg == null || now.difference(epg) > const Duration(hours: 48),
    'backupStale': bak == null || now.difference(bak) > const Duration(hours: 48),
    'iptvOrg': await IptvOrgConnector().healthCheck(),
  };
});

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  bool busy = false;

  Future<void> _cleanup(String action, {bool danger = false}) async {
    final repo = ref.read(adminRepoProvider);
    if (repo == null) return;
    final t = L10n.of(context);
    if (danger) {
      // لقطة إلزامية قبل أي عملية خطرة (§9.10 H5، §21.2)
      final word = 'DELETE';
      final typed = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(t.mtDanger),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.mtDangerHint),
            const SizedBox(height: Space.sm),
            TextField(controller: typed, autofocus: true, decoration: InputDecoration(labelText: t.mtTypeWord(word))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), onPressed: () => Navigator.pop(d, typed.text.trim() == word), child: Text(t.aDelete)),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => busy = true);
    try {
      if (danger) {
        final dev = await ref.read(adminDeviceProvider.future);
        final pass = await readBackupPassphrase();
        if (dev.backupDir == null || pass == null) throw StateError(t.bkNotConfigured);
        await ref.read(backupServiceProvider)!.create(dir: dev.backupDir!, passphrase: pass, kind: 'snapshot');
      }
      final n = await repo.db.rpc('admin_cleanup', params: {'p_action': action});
      if (mounted) toast(context, t.doneCount((n as num).toInt()));
      ref.invalidate(_statusProvider);
    } catch (e) {
      if (mounted) toast(context, t.saveFailed('$e'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context), c = context.colors;
    final s = ref.watch(_statusProvider);
    final d = s.value ?? const {};
    final sizes = (d['sizes'] as Map?)?.cast<String, int>() ?? const {};
    return ListView(padding: const EdgeInsets.all(Space.lg), children: [
      SectionCard(
        title: t.mtStatus,
        trailing: IconButton(onPressed: () => ref.invalidate(_statusProvider), icon: const Icon(Icons.refresh_rounded)),
        child: s.isLoading
            ? const LinearProgressIndicator()
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.mtDbLatency((d['latency'] as int?) ?? 0), style: TextStyle(color: c.text)),
                if (d['epgStale'] == true) Text('⚠ ${t.mtEpgStale}', style: TextStyle(color: healthColor('unavailable'))),
                if (d['backupStale'] == true) Text('⚠ ${t.mtBackupStale}', style: TextStyle(color: healthColor('unavailable'))),
                Text('iptv-org: ${d['iptvOrg'] == true ? 'OK' : '✗'}', style: TextStyle(color: c.textMuted)),
                const SizedBox(height: Space.sm),
                Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [for (final e in sizes.entries) Pill('${e.key} ${e.value}', c.textMuted)]),
              ]),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.mtCleanup,
        child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
          OutlinedButton(onPressed: busy ? null : () => _cleanup('refresh_counts'), child: Text(t.mtRefreshCounts)),
          OutlinedButton(onPressed: busy ? null : () => _cleanup('clear_reports'), child: Text(t.mtClearReports)),
          OutlinedButton(onPressed: busy ? null : () => _cleanup('clear_broken_logos'), child: Text(t.mtClearBrokenLogos)),
        ]),
      ),
      const SizedBox(height: Space.md),
      SectionCard(
        title: t.mtDanger,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.mtDangerHint, style: TextStyle(color: c.textMuted, fontSize: 12.5)),
          const SizedBox(height: Space.sm),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            for (final (_, l) in [('delete_offline_streams', t.mtDeleteOffline), ('delete_hidden', t.mtDeleteHidden), ('delete_pending', t.mtDeletePending)])
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                // معطّلة مؤقتًا (جرد A-133/A-134/A-135): حذف نهائي بلا سلة يطال قيد المراجعة والسلة والمدموجة وروابط قنوات منشورة.
                onPressed: null,
                child: Text(l),
              ),
          ]),
        ]),
      ),
    ]);
  }
}

/// استعادة النسخ معطّلة في اللوحة المؤقتة حتى إصلاح A-129 (الاستعادة كانت تلغي نشر الكتالوج).
const kLegacyRestoreDisabled = true;
