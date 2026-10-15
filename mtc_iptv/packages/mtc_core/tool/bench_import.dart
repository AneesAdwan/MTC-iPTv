// قياس أداء الاستيراد (المرحلة 0): تحليل ملف M3U داخل Isolate منفصل،
// مع الزمن والذاكرة وملخّص المحتوى. الاستخدام:
//   dart run tool/bench_import.dart <file.m3u> [<file2.m3u> ...]
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:mtc_core/mtc_core.dart';

Future<void> main(List<String> files) async {
  for (final path in files) {
    final bytes = await File(path).readAsBytes();
    final rssBefore = ProcessInfo.currentRss;
    final sw = Stopwatch()..start();
    // التحليل في Isolate: الواجهة لا تتجمد. نعيد ملخّصًا صغيرًا فقط (لا نقل كائنات ضخمة بين Isolates).
    final summary = await Isolate.run(() {
      final t = Stopwatch()..start();
      final text = utf8.decode(bytes, allowMalformed: true);
      final decodeMs = t.elapsedMilliseconds;
      final r = parseM3u(text);
      final parseMs = t.elapsedMilliseconds - decodeMs;
      final keys = <String, int>{};
      for (final e in r.entries) {
        final k = matchKey(e.name);
        keys[k] = (keys[k] ?? 0) + 1;
      }
      final keyMs = t.elapsedMilliseconds - decodeMs - parseMs;
      int count(bool Function(M3uEntry) f) => r.entries.where(f).length;
      final protos = <String, int>{};
      for (final e in r.entries) {
        protos[e.protocol] = (protos[e.protocol] ?? 0) + 1;
      }
      return {
        'entries': r.entries.length,
        'issues': r.issues.length,
        'issue_kinds': {for (final i in r.issues) i.kind: r.issues.where((x) => x.kind == i.kind).length},
        'decode_ms': decodeMs,
        'parse_ms': parseMs,
        'matchkey_ms': keyMs,
        'distinct_keys': keys.length,
        'dup_in_file': keys.values.where((v) => v > 1).fold<int>(0, (a, v) => a + v - 1),
        'with_tvg_id': count((e) => e.tvgId != null),
        'with_logo': count((e) => e.logo != null),
        'with_group': count((e) => e.group != null),
        'with_headers': count((e) => e.userAgent != null || e.referrer != null || e.headers.isNotEmpty),
        'with_credentials': count((e) => e.hasCredentials),
        'protocols': protos,
        'peak_rss_mb': (ProcessInfo.maxRss / 1048576).round(),
      };
    });
    sw.stop();
    print(const JsonEncoder.withIndent('  ').convert({
      'file': path.split(RegExp(r'[\\/]')).last,
      'size_kb': (bytes.length / 1024).round(),
      'total_ms_incl_isolate': sw.elapsedMilliseconds,
      'rss_before_mb': (rssBefore / 1048576).round(),
      ...summary,
    }));
  }
}
