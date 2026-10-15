// صيغة النسخة الاحتياطية (§21.2): JSON ← gzip ← AES-256-GCM بمفتاح PBKDF2-HMAC-SHA256 من عبارة المرور.
// عبارة المرور لا تُحفظ على الخادم؛ فقدانها = فقدان القدرة على فك النسخ.
// الملف: "MTCBAK" + إصدار(1) + التكرارات(4) + ملح(16) + nonce(12) + mac(16) + النص المشفّر.
// أي تعديل في الملف أو عبارة مرور خاطئة ← رفض برسالة واضحة ودون أي كتابة (§21.5).
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';

const backupMagic = 'MTCBAK';
const backupFormatVersion = 1;
const backupIterations = 150000;

class BackupError implements Exception {
  final String kind; // not_backup | unsupported_version | wrong_passphrase_or_corrupt | bad_content
  final String detail;
  const BackupError(this.kind, [this.detail = '']);
  @override
  String toString() => 'BackupError($kind) $detail';
}

Future<SecretKey> _key(String passphrase, List<int> salt, int iterations) =>
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256).deriveKeyFromPassword(password: passphrase, nonce: salt);

List<int> _random(int n) {
  final r = Random.secure();
  return [for (var i = 0; i < n; i++) r.nextInt(256)];
}

Future<Uint8List> encryptBackup(Map<String, dynamic> doc, String passphrase, {int iterations = backupIterations}) async {
  if (passphrase.length < 8) throw const BackupError('bad_content', 'passphrase must be at least 8 characters');
  final plain = gzip.encode(utf8.encode(jsonEncode(doc)));
  final salt = _random(16), nonce = _random(12);
  final box = await AesGcm.with256bits().encrypt(plain, secretKey: await _key(passphrase, salt, iterations), nonce: nonce);
  final head = BytesBuilder()
    ..add(ascii.encode(backupMagic))
    ..addByte(backupFormatVersion)
    ..add((ByteData(4)..setUint32(0, iterations)).buffer.asUint8List())
    ..add(salt)
    ..add(nonce)
    ..add(box.mac.bytes)
    ..add(box.cipherText);
  return head.takeBytes();
}

Future<Map<String, dynamic>> decryptBackup(Uint8List bytes, String passphrase) async {
  const headLen = 6 + 1 + 4 + 16 + 12 + 16;
  if (bytes.length < headLen || ascii.decode(bytes.sublist(0, 6), allowInvalid: true) != backupMagic) {
    throw const BackupError('not_backup');
  }
  if (bytes[6] != backupFormatVersion) throw BackupError('unsupported_version', '${bytes[6]}');
  final iterations = ByteData.sublistView(bytes, 7, 11).getUint32(0);
  final salt = bytes.sublist(11, 27), nonce = bytes.sublist(27, 39), mac = bytes.sublist(39, 55);
  final List<int> plain;
  try {
    plain = await AesGcm.with256bits().decrypt(SecretBox(bytes.sublist(55), nonce: nonce, mac: Mac(mac)), secretKey: await _key(passphrase, salt, iterations));
  } on SecretBoxAuthenticationError {
    throw const BackupError('wrong_passphrase_or_corrupt');
  }
  try {
    final doc = jsonDecode(utf8.decode(gzip.decode(plain)));
    if (doc is! Map<String, dynamic> || doc['app'] != 'MTC-iPTv' || doc['tables'] is! Map) throw const FormatException('shape');
    return doc;
  } catch (e) {
    throw BackupError('bad_content', '$e');
  }
}

String sha256Hex(List<int> bytes) => hash.sha256.convert(bytes).toString();

/// `mtc-iptv_<env>_<YYYYMMDD-HHMM>_<daily|manual>.mtcbak` (§21.2)
String backupFileName(String env, DateTime at, String kind) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'mtc-iptv_${env}_${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}_$kind.mtcbak';
}

/// (البيئة، الوقت، النوع) من اسم الملف، أو null.
(String, DateTime, String)? parseBackupFileName(String name) {
  final m = RegExp(r'^mtc-iptv_([a-z]+)_(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})_(daily|manual|snapshot)\.mtcbak$').firstMatch(name);
  if (m == null) return null;
  return (m[1]!, DateTime(int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!)), m[7]!);
}

/// الاحتفاظ (§21.2): 7 يومية، 4 أسبوعية، 6 شهرية. اليدوية لا تُحذف تلقائيًا. يعيد أسماء الملفات التي تُحذف.
List<String> backupsToPrune(List<String> names) {
  final daily = <(String, DateTime)>[];
  for (final n in names) {
    final p = parseBackupFileName(n);
    if (p != null && p.$3 == 'daily') daily.add((n, p.$2));
  }
  daily.sort((a, b) => b.$2.compareTo(a.$2)); // الأحدث أولًا
  final keep = <String>{};
  keep.addAll(daily.take(7).map((d) => d.$1));
  final weeks = <String>{}, months = <String>{};
  for (final d in daily) {
    // أحدث نسخة في كل أسبوع (يبدأ الإثنين) وكل شهر
    final monday = DateTime(d.$2.year, d.$2.month, d.$2.day).subtract(Duration(days: d.$2.weekday - 1));
    final wk = '${monday.year}-${monday.month}-${monday.day}';
    if (weeks.length < 4 && weeks.add(wk)) keep.add(d.$1);
    final mo = '${d.$2.year}-${d.$2.month}';
    if (months.length < 6 && months.add(mo)) keep.add(d.$1);
  }
  return [for (final d in daily) if (!keep.contains(d.$1)) d.$1];
}
