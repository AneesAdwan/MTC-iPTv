// التسجيل (§19.1-10): لا تُكتب أسرار أبدًا. الروابط تمرّ عبر maskCredentials قبل أي سجل.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mtc_core/mtc_core.dart';
import 'package:path_provider/path_provider.dart';

final log = Logger('mtc');

IOSink? _sink;

/// يكتب السجل إلى ملف يومي في مجلد التطبيق، ويُبقي آخر 7 ملفات.
Future<void> initLogging() async {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  try {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}logs');
    await dir.create(recursive: true);
    final day = DateTime.now().toIso8601String().substring(0, 10);
    _sink = File('${dir.path}${Platform.pathSeparator}mtc-$day.log').openWrite(mode: FileMode.append);
    final old = (await dir.list().where((e) => e.path.endsWith('.log')).toList())..sort((a, b) => b.path.compareTo(a.path));
    for (final f in old.skip(7)) {
      unawaited(f.delete());
    }
  } catch (_) {
    // المجلد غير متاح (اختبارات): نكتفي بالطرفية
  }
  Logger.root.onRecord.listen((r) {
    final line = '${r.time.toIso8601String()} ${r.level.name.padRight(7)} ${r.loggerName}: ${safe(r.message)}'
        '${r.error != null ? ' | ${safe('${r.error}')}' : ''}';
    if (kDebugMode) debugPrint(line);
    _sink?.writeln(line);
    if (r.stackTrace != null) _sink?.writeln(r.stackTrace);
  });
}

/// يُخفي بيانات الاعتماد في أي نص قبل تسجيله (§19.4).
String safe(String s) => s.replaceAllMapped(RegExp(r'[a-z]+://\S+', caseSensitive: false), (m) => maskCredentials(m[0]!));
