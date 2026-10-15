// شهادات الجذر للمشغّل (§7.3، تقرير PoC §6).
// libmpv المرفق مبني على mbedtls ولا يقرأ مخزن شهادات النظام، فمع tls-verify=yes كان يرفض كل بث HTTPS.
// نرفق حزمة Mozilla (assets/tls/cacert.pem من curl.se) وننسخها لملف حقيقي لأن mpv يحتاج مسارًا.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/logging/log.dart';

class TlsBundle {
  TlsBundle._();

  /// مسار الحزمة على القرص؛ null إن فشل التجهيز (المشغّل عندها يعمل دون تحقق بدل أن يتعطل كليًا).
  static String? path;

  static Future<void> prepare() async {
    try {
      final data = await rootBundle.load('assets/tls/cacert.pem');
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}cacert.pem');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (!f.existsSync() || f.lengthSync() != bytes.length) await f.writeAsBytes(bytes, flush: true);
      path = f.path;
    } catch (e) {
      log.severe('tls bundle unavailable; playback falls back to tls-verify=no', e);
    }
  }
}
