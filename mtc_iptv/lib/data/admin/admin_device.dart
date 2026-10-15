// إعدادات جهاز المدير (لا تُرسل للخادم): مجلد النسخ، المُجدوِل، البقاء في منطقة الإشعارات، البدء مع ويندوز.
// عبارة مرور النسخ في مخزن النظام الآمن (Credential Manager) ولا تُحفظ في أي ملف (§21.2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logging/log.dart';

@immutable
class AdminDevice {
  final String? backupDir;
  final bool schedulerEnabled, keepInTray;
  const AdminDevice({this.backupDir, this.schedulerEnabled = true, this.keepInTray = true});
  AdminDevice copyWith({String? backupDir, bool? schedulerEnabled, bool? keepInTray}) =>
      AdminDevice(backupDir: backupDir ?? this.backupDir, schedulerEnabled: schedulerEnabled ?? this.schedulerEnabled, keepInTray: keepInTray ?? this.keepInTray);
  Map<String, Object?> toJson() => {'backupDir': backupDir, 'schedulerEnabled': schedulerEnabled, 'keepInTray': keepInTray};
  factory AdminDevice.fromJson(Map<String, dynamic> j) =>
      AdminDevice(backupDir: j['backupDir'] as String?, schedulerEnabled: j['schedulerEnabled'] != false, keepInTray: j['keepInTray'] != false);
}

const _passKey = 'mtc.backup.passphrase';
const _secure = FlutterSecureStorage();

Future<String?> readBackupPassphrase() => _secure.read(key: _passKey);
Future<void> writeBackupPassphrase(String? v) => v == null ? _secure.delete(key: _passKey) : _secure.write(key: _passKey, value: v);

Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}admin_device.json');

class AdminDeviceController extends AsyncNotifier<AdminDevice> {
  @override
  Future<AdminDevice> build() async {
    try {
      final f = await _file();
      if (await f.exists()) return AdminDevice.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (e) {
      log.warning('admin device config unreadable', e);
    }
    return const AdminDevice();
  }

  Future<void> save(AdminDevice d) async {
    state = AsyncData(d);
    await (await _file()).writeAsString(jsonEncode(d.toJson()));
  }
}

final adminDeviceProvider = AsyncNotifierProvider<AdminDeviceController, AdminDevice>(AdminDeviceController.new);

/// البدء مع ويندوز (§9.10 H2): مفتاح Run للمستخدم الحالي، ويبدأ البرنامج مخفيًا (--hidden).
/// عبر reg.exe المدمج (حزمة launch_at_startup تتعارض مع flutter_secure_storage على win32).
class StartWithWindows {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _name = 'MTC-iPTv';

  static Future<bool> isEnabled() async {
    if (!Platform.isWindows) return false;
    final r = await Process.run('reg', ['query', _key, '/v', _name]);
    return r.exitCode == 0 && '${r.stdout}'.contains(Platform.resolvedExecutable);
  }

  static Future<void> set(bool on) async {
    if (!Platform.isWindows) return;
    final r = on
        ? await Process.run('reg', ['add', _key, '/v', _name, '/t', 'REG_SZ', '/d', '"${Platform.resolvedExecutable}" --hidden', '/f'])
        : await Process.run('reg', ['delete', _key, '/v', _name, '/f']);
    if (r.exitCode != 0 && on) throw StateError('reg: ${r.stderr}');
  }
}
