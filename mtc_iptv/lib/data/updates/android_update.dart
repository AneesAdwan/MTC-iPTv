// التحديث داخل تطبيق Android (طلب المالك 2026-10-17: «بدي على طول ينزل» بدل فتح GitHub):
//   1. أحدث إصدار من GitHub (نفس checkForUpdate) ← ملف APK المطابق لمعمارية الجهاز (arm64-v8a، armeabi-v7a، x86_64).
//   2. التنزيل داخل التطبيق مع شريط تقدّم إلى cache/updates (المجلد الوحيد المتاح لـ FileProvider).
//   3. التحقق من البصمة مع SHA256SUMS المنشور في الإصدار نفسه — ملف لا يطابق لا يُثبَّت.
//   4. شاشة التثبيت في النظام (المستخدم يوافق دائمًا). Android نفسه يرفض أي ملف بتوقيع غير توقيعنا.
// أول مرة: إذن «تثبيت التطبيقات من هذا المصدر» (Android 8+) — نفتح الإعدادات ثم يضغط «تحديث» مجددًا.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/config/env.dart';
import '../../core/logging/log.dart';
import '../../core/text/bidi.dart';
import 'update_check.dart';

const _native = MethodChannel('mtc/instance');

/// اسم ملف APK المناسب لأول معمارية يدعمها الجهاز (الأسماء من release.ps1: «…-android-ABI.apk»).
String? pickApk(Map<String, String> assets, List<String> abis) {
  for (final abi in abis) {
    for (final name in assets.keys) {
      if (name.endsWith('-android-$abi.apk')) return name;
    }
  }
  return null;
}

/// البصمة من محتوى SHA256SUMS (سطر «hash  name» أو «hash *name»).
String? sumFor(String sums, String name) {
  for (final line in sums.split('\n')) {
    final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$').firstMatch(line.trim());
    if (m != null && m[2] == name) return m[1]!.toLowerCase();
  }
  return null;
}

Future<void> runAndroidUpdate(BuildContext context, {UpdateInfo? known}) async {
  final t = L10n.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String s) => messenger?.showSnackBar(SnackBar(content: Text(s)));
  try {
    final u = known ?? await checkForUpdate(Env.version);
    if (u == null) return say(t.upToDate);
    final abis = [for (final a in await _native.invokeListMethod<String>('abis') ?? const <String>[]) a];
    final name = pickApk(u.assets, abis.isEmpty ? const ['arm64-v8a', 'armeabi-v7a'] : abis);
    if (name == null) return say(t.upNoApk);
    if (await _native.invokeMethod<bool>('canInstall') != true) {
      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          content: Text(t.upInstallPerm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t.upOpenSettings)),
          ],
        ),
      );
      if (go == true) await _native.invokeMethod('openInstallSettings');
      return;
    }
    if (!context.mounted) return;
    final file = await showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DownloadDialog(url: u.assets[name]!, name: name, version: u.version.toString(), sumsUrl: u.assets['SHA256SUMS.txt'] ?? u.assets['SHA256SUMS']),
    );
    if (file == null) return;
    say(t.upInstalling);
    await _native.invokeMethod('installApk', file.path);
  } catch (e) {
    log.warning('android update failed', e);
    say(t.upFailed('$e'));
  }
}

class _DownloadDialog extends StatefulWidget {
  final String url, name, version;
  final String? sumsUrl;
  const _DownloadDialog({required this.url, required this.name, required this.version, this.sumsUrl});
  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  final _client = http.Client();
  double? progress;
  int got = 0, total = 0;
  String? error;
  bool cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final dir = Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}updates');
      if (await dir.exists()) await dir.delete(recursive: true); // ملفات تحديث سابقة
      await dir.create(recursive: true);
      final f = File('${dir.path}${Platform.pathSeparator}${widget.name}');
      final res = await _client.send(http.Request('GET', Uri.parse(widget.url)));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      total = res.contentLength ?? 0;
      final sink = f.openWrite();
      final digestOut = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestOut);
      await for (final chunk in res.stream) {
        if (cancelled) {
          await sink.close();
          return;
        }
        sink.add(chunk);
        hasher.add(chunk);
        got += chunk.length;
        if (mounted) setState(() => progress = total > 0 ? got / total : null);
      }
      await sink.close();
      hasher.close();
      // البصمة من SHA256SUMS في الإصدار نفسه
      if (widget.sumsUrl != null) {
        final sums = await _client.get(Uri.parse(widget.sumsUrl!));
        final expected = sumFor(sums.body, widget.name);
        if (expected != null && expected != digestOut.value.toString()) {
          await f.delete();
          if (mounted) setState(() => error = L10n.of(context).upVerifyFailed);
          return;
        }
      }
      if (mounted) Navigator.pop(context, f);
    } catch (e) {
      if (mounted) setState(() => error = L10n.of(context).upFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    String mb(int b) => (b / 1048576).toStringAsFixed(1);
    return AlertDialog(
      title: Text(t.upDownloading(ltr(widget.version))),
      content: SizedBox(
        width: 340,
        child: error != null
            ? Text(error!, style: const TextStyle(color: Color(0xFFEF4444)))
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                const SizedBox(height: 10),
                Text(
                  total > 0 ? ltr('${mb(got)} / ${mb(total)} MB  ·  ${((progress ?? 0) * 100).round()}%') : ltr('${mb(got)} MB'),
                  textAlign: TextAlign.center,
                ),
              ]),
      ),
      actions: [
        TextButton(
          onPressed: () {
            cancelled = true;
            Navigator.pop(context);
          },
          child: Text(t.cancel),
        ),
      ],
    );
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
