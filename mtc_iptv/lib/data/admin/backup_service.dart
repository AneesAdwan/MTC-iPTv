// النسخ الاحتياطي (ADM-H4، §21): كل الجداول المشمولة عبر API بصلاحية المدير ← أرشيف مشفّر في مجلد يختاره المدير
// (+ ملف ‎.sha256)، والاحتفاظ 7/4/6. الاستعادة: تحقق البصمة ← فك التشفير ← معاينة الأعداد ← إضافة/تحديث فقط.
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_core/mtc_core.dart';

import '../../core/config/env.dart';
import '../../core/logging/log.dart';
import 'admin_device.dart';
import 'admin_repository.dart';

/// آخر ترحيل يعرفه هذا الإصدار (يُكتب في النسخة لكشف النسخ الأقدم/الأحدث).
const backupSchema = '20261016000300';

class BackupResult {
  final String path;
  final Map<String, int> counts;
  final int bytes;
  final List<String> pruned;
  const BackupResult(this.path, this.counts, this.bytes, this.pruned);
}

class BackupService {
  final AdminRepository repo;
  BackupService(this.repo);

  /// [kind]: daily | manual | snapshot (قبل عملية خطرة).
  Future<BackupResult> create({required String dir, required String passphrase, String kind = 'manual'}) async {
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final t in AdminRepository.backupTables.keys) {
      try {
        tables[t] = await repo.dumpTable(t);
      } catch (e) {
        // جدول غير موجود بعد (ترحيل لم يُطبَّق) لا يُفشل النسخة كلها
        log.warning('backup: skip $t', e);
      }
    }
    final now = DateTime.now();
    final doc = {
      'app': 'MTC-iPTv',
      'kind': 'backup',
      'format': backupFormatVersion,
      'schema': backupSchema,
      'env': Env.name,
      'app_version': Env.version,
      'created_at': now.toUtc().toIso8601String(),
      'counts': {for (final e in tables.entries) e.key: e.value.length},
      'tables': tables,
    };
    final bytes = await Isolate.run(() => encryptBackup(doc, passphrase));
    final name = backupFileName(Env.name, now, kind);
    final file = File('$dir${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    await File('${file.path}.sha256').writeAsString('${sha256Hex(bytes)}  $name\n');
    // الاحتفاظ (اليومية فقط)
    final names = [for (final f in Directory(dir).listSync().whereType<File>()) f.uri.pathSegments.last];
    final prune = backupsToPrune(names);
    for (final p in prune) {
      for (final suffix in ['', '.sha256']) {
        final f = File('$dir${Platform.pathSeparator}$p$suffix');
        if (f.existsSync()) f.deleteSync();
      }
    }
    log.info('backup $kind ${file.path} ${bytes.length}B pruned=${prune.length}');
    return BackupResult(file.path, {for (final e in tables.entries) e.key: e.value.length}, bytes.length, prune);
  }

  /// يقرأ نسخة: يتحقق من البصمة (إن وُجد ملفها) ثم يفك التشفير. لا يكتب شيئًا.
  static Future<Map<String, dynamic>> open(String path, String passphrase) async {
    final bytes = await File(path).readAsBytes();
    final shaFile = File('$path.sha256');
    if (shaFile.existsSync()) {
      final expected = (await shaFile.readAsString()).trim().split(RegExp(r'\s+')).first;
      if (expected != sha256Hex(bytes)) throw const BackupError('wrong_passphrase_or_corrupt', 'sha256 mismatch');
    }
    return Isolate.run(() => decryptBackup(Uint8List.fromList(bytes), passphrase));
  }

  /// الاستعادة الانتقائية: جداول مختارة، أو قناة واحدة مع روابطها. إضافة/تحديث فقط، بترتيب يحترم المراجع.
  Future<Map<String, int>> restore(Map<String, dynamic> doc, {List<String> tables = const [], String? channelId}) async {
    final t = (doc['tables'] as Map).cast<String, dynamic>();
    final out = <String, int>{};
    if (channelId != null) {
      final ch = [for (final r in (t['channels'] as List? ?? const [])) if ((r as Map)['id'] == channelId) Map<String, dynamic>.from(r)];
      final st = [for (final r in (t['streams'] as List? ?? const [])) if ((r as Map)['channel_id'] == channelId) Map<String, dynamic>.from(r)];
      out['channels'] = await repo.restoreUpsert('channels', ch);
      out['streams'] = await repo.restoreUpsert('streams', st);
      return out;
    }
    for (final name in AdminRepository.restorableTables) {
      if (!tables.contains(name) || t[name] is! List) continue;
      out[name] = await repo.restoreUpsert(name, [for (final r in t[name] as List) Map<String, dynamic>.from(r as Map)]);
    }
    return out;
  }
}

final backupServiceProvider = Provider<BackupService?>((ref) {
  final repo = ref.watch(adminRepoProvider);
  return repo == null ? null : BackupService(repo);
});

/// نسخة فورية بإعدادات هذا الجهاز (تُستخدم قبل عمليات «منطقة الخطر» وفي المُجدوِل).
Future<BackupResult> backupNow(Ref ref, {String kind = 'manual'}) async {
  final svc = ref.read(backupServiceProvider);
  final dev = await ref.read(adminDeviceProvider.future);
  final pass = await readBackupPassphrase();
  if (svc == null) throw StateError('no backend');
  if (dev.backupDir == null || pass == null) throw StateError('backup not configured');
  return svc.create(dir: dev.backupDir!, passphrase: pass, kind: kind);
}
