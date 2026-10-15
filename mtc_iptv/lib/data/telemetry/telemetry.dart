// قياس المشاهدين (§12.4) والأجهزة (§20): مستعار، دون الرابط ودون بيانات اعتماد ودون IP.
//  • معرّف تثبيت عشوائي يُحفظ محليًا، ويُعاد توليده بـ«أعد تعيين المعرّف» (ويُحذف السابق من الخادم).
//  • الأحداث تُجمع في الذاكرة وتُرسل دفعات (حتى 50) كل دقيقتين أو عند 20 حدثًا، عبر telemetry_ingest فقط.
//  • إيقاف الإحصاءات من الإعدادات (V-10) أو مركزيًا (G5) = لا يُرسل شيء.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend.dart';
import '../../core/config/env.dart';
import '../../core/logging/log.dart';
import '../../core/settings/local_settings.dart';
import '../settings/remote_config.dart';

class PlayEvent {
  final String streamId;
  final String outcome; // success | failure | abandoned
  final String? errorCode;
  final int? firstFrameMs, watchSeconds, serverIndex, height;
  final DateTime at;
  PlayEvent({required this.streamId, required this.outcome, this.errorCode, this.firstFrameMs, this.watchSeconds, this.serverIndex, this.height, DateTime? at})
      : at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'stream_id': streamId,
        'outcome': outcome,
        'error_code': ?errorCode,
        'first_frame_ms': ?firstFrameMs,
        'watch_seconds': ?watchSeconds,
        'server_index': ?serverIndex,
        'height': ?height,
      };
}

/// UUID v4 عشوائي (Random.secure).
String randomUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class TelemetryService {
  final Ref ref;
  TelemetryService(this.ref);

  static const maxQueue = 200, batch = 50;
  final queue = <Map<String, dynamic>>[];
  bool _sending = false;

  bool get enabled =>
      ref.read(settingsProvider).telemetry && (ref.read(remoteConfigProvider).value ?? RemoteConfig.empty).telemetryEnabled;

  Future<String> installationId() async {
    final db = ref.read(catalogDbProvider);
    final row = await (db.select(db.syncState)..where((s) => s.key.equals('installation_id'))).getSingleOrNull();
    if (row != null && row.value.length == 36) return row.value;
    final id = randomUuid();
    await db.setSyncValue('installation_id', id);
    return id;
  }

  void record(PlayEvent e) {
    if (!enabled) return;
    queue.add(e.toJson());
    if (queue.length > maxQueue) queue.removeRange(0, queue.length - maxQueue); // الأقدم أولًا
    if (queue.length >= 20) unawaited(flush());
  }

  /// يرسل دفعة (أو نبضة «الجهاز نشط» إن لم توجد أحداث). يعيد عدد المحفوظ على الخادم.
  Future<int> flush() async {
    final c = ref.read(supabaseProvider);
    if (c == null || _sending) return 0;
    if (!enabled) {
      queue.clear();
      return 0;
    }
    _sending = true;
    final take = queue.take(batch).toList();
    try {
      final n = await c.rpc('telemetry_ingest', params: {
        'p_installation': await installationId(),
        'p_platform': platformName,
        'p_version': Env.version,
        'p_locale': ref.read(settingsProvider).locale.languageCode,
        'p_events': take,
      });
      queue.removeRange(0, take.length.clamp(0, queue.length));
      return (n as num?)?.toInt() ?? 0;
    } catch (e) {
      // قبل تطبيق الترحيل 0005 أو دون اتصال: تبقى في الطابور (بحدّ أقصى)
      log.fine('telemetry flush skipped: $e');
      return 0;
    } finally {
      _sending = false;
    }
  }

  /// «أعد تعيين المعرّف» (§20.2): يحذف الجهاز وأحداثه من الخادم ويبدأ بمعرّف جديد.
  Future<void> resetId() async {
    final old = await installationId();
    queue.clear();
    try {
      await ref.read(supabaseProvider)?.rpc('telemetry_forget', params: {'p_installation': old});
    } catch (e) {
      log.warning('telemetry forget failed', e);
    }
    await ref.read(catalogDbProvider).setSyncValue('installation_id', randomUuid());
  }
}

final telemetryProvider = Provider<TelemetryService>((ref) {
  final s = TelemetryService(ref);
  final timer = Timer.periodic(const Duration(minutes: 2), (_) => s.flush());
  ref.onDispose(timer.cancel);
  return s;
});

/// نبضة عند التشغيل بعد المزامنة (الأجهزة النشطة، الإصدارات، المنصّات).
final telemetryHeartbeatProvider = FutureProvider<void>((ref) async {
  await ref.watch(remoteConfigSyncProvider.future);
  await ref.read(telemetryProvider).flush();
});
