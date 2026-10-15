// صيغة النسخة الاحتياطية (§21.5): الذهاب والإياب، وعبارة مرور خاطئة، وملف تالف أو ناقص، والاحتفاظ.
import 'dart:typed_data';

import 'package:mtc_core/mtc_core.dart';
import 'package:test/test.dart';

void main() {
  final doc = {
    'app': 'MTC-iPTv',
    'kind': 'backup',
    'tables': {
      'channels': [
        {'id': '1', 'name': 'الجزيرة'},
      ],
    },
  };
  const pass = 'correct horse battery';

  test('round trip', () async {
    final bytes = await encryptBackup(doc, pass, iterations: 1000);
    expect(String.fromCharCodes(bytes.sublist(0, 6)), 'MTCBAK');
    final back = await decryptBackup(bytes, pass);
    expect((back['tables'] as Map)['channels'], [
      {'id': '1', 'name': 'الجزيرة'},
    ]);
  });

  test('the plaintext is not visible in the file', () async {
    final bytes = await encryptBackup(doc, pass, iterations: 1000);
    expect(String.fromCharCodes(bytes).contains('MTC-iPTv'), isFalse);
  });

  test('wrong passphrase, tampered byte, truncated file and non-backup are refused', () async {
    final bytes = await encryptBackup(doc, pass, iterations: 1000);
    Future<String> kind(Future<void> f) async {
      try {
        await f;
        return 'ok';
      } on BackupError catch (e) {
        return e.kind;
      }
    }

    expect(await kind(decryptBackup(bytes, 'wrong passphrase')), 'wrong_passphrase_or_corrupt');
    final tampered = Uint8List.fromList(bytes)..[bytes.length - 3] ^= 0x01;
    expect(await kind(decryptBackup(tampered, pass)), 'wrong_passphrase_or_corrupt');
    expect(await kind(decryptBackup(bytes.sublist(0, 30), pass)), 'not_backup');
    expect(await kind(decryptBackup(Uint8List.fromList('{"app":"x"}'.codeUnits), pass)), 'not_backup');
    expect(await kind(encryptBackup(doc, 'short')), 'bad_content');
  });

  test('file names and sha256', () {
    final n = backupFileName('production', DateTime(2026, 10, 16, 3, 5), 'daily');
    expect(n, 'mtc-iptv_production_20261016-0305_daily.mtcbak');
    expect(parseBackupFileName(n)!.$3, 'daily');
    expect(sha256Hex([1, 2, 3]).length, 64);
  });

  test('retention: 7 daily + 4 weekly + 6 monthly; manual never pruned', () {
    final names = [
      for (var d = 0; d < 200; d++) backupFileName('production', DateTime(2026, 10, 16).subtract(Duration(days: d)), 'daily'),
      backupFileName('production', DateTime(2025, 1, 1), 'manual'),
    ];
    final prune = backupsToPrune(names).toSet();
    final kept = names.where((n) => !prune.contains(n)).toList();
    expect(kept, contains(backupFileName('production', DateTime(2025, 1, 1), 'manual')));
    final keptDaily = kept.where((n) => n.endsWith('_daily.mtcbak')).length;
    expect(keptDaily, inInclusiveRange(7, 17));
    expect(kept, contains(names[0]));
    expect(kept, contains(names[6]));
    expect(prune.length, 200 - keptDaily);
  });
}
