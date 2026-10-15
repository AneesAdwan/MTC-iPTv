// تجميع تقارير ADM-I1 من playback_stats_daily و installations (منطق نقي قابل للاختبار).
// زمن البدء: الوسيط وP90 اليوميان محسوبان على الخادم؛ عبر عدة أيام/صفوف نأخذ متوسطًا موزونًا بعدد النجاحات (تقريبي).

/// أقل عيّنة لعرض نسبة نجاح لعنصر واحد (§12.3)، وللوحة المعلومات (§9.3).
const minSampleItem = 20, minSampleDashboard = 100;

class StatAgg {
  int attempts = 0, successes = 0, abandoned = 0, sessions30 = 0, watchSeconds = 0;
  double _w50 = 0, _w90 = 0;
  int _wn = 0;
  final failures = <String, int>{};

  void add(Map<String, dynamic> r) {
    final ok = (r['successes'] as num?)?.toInt() ?? 0;
    attempts += (r['attempts'] as num?)?.toInt() ?? 0;
    successes += ok;
    abandoned += (r['abandoned'] as num?)?.toInt() ?? 0;
    sessions30 += (r['sessions_30s'] as num?)?.toInt() ?? 0;
    watchSeconds += (r['watch_seconds'] as num?)?.toInt() ?? 0;
    final p50 = r['ttff_p50_ms'] as num?, p90 = r['ttff_p90_ms'] as num?;
    if (p50 != null && ok > 0) {
      _w50 += p50 * ok;
      _w90 += (p90 ?? p50) * ok;
      _wn += ok;
    }
    final f = r['failures'];
    if (f is Map) {
      f.forEach((k, v) => failures['$k'] = (failures['$k'] ?? 0) + ((v as num?)?.toInt() ?? 0));
    }
  }

  double? get rate => attempts == 0 ? null : successes / attempts;
  int? get ttffP50 => _wn == 0 ? null : (_w50 / _wn).round();
  int? get ttffP90 => _wn == 0 ? null : (_w90 / _wn).round();

  /// النسبة فقط إن كانت العيّنة كافية، وإلا null («غير حاسم»).
  double? rateIfSample([int min = minSampleItem]) => attempts >= min ? rate : null;
}

class PlaybackAnalytics {
  final total = StatAgg();
  final byChannel = <String, StatAgg>{};
  final byHost = <String, StatAgg>{};
  final byPlatform = <String, StatAgg>{};
  final byCountry = <String, StatAgg>{};
  final byDay = <String, StatAgg>{};

  PlaybackAnalytics.from(List<Map<String, dynamic>> rows, {Map<String, String> hosts = const {}}) {
    for (final r in rows) {
      total.add(r);
      byChannel.putIfAbsent('${r['channel_id']}', StatAgg.new).add(r);
      byHost.putIfAbsent(hosts['${r['stream_id']}'] ?? '?', StatAgg.new).add(r);
      byPlatform.putIfAbsent('${r['platform']}', StatAgg.new).add(r);
      final cc = '${r['country'] ?? ''}';
      byCountry.putIfAbsent(cc.isEmpty ? '—' : cc, StatAgg.new).add(r);
      byDay.putIfAbsent('${r['day']}', StatAgg.new).add(r);
    }
  }

  /// ترتيب تنازلي حسب المشاهدات (جلسات ≥ 30 ثانية)، ثم المحاولات.
  static List<MapEntry<String, StatAgg>> topViewed(Map<String, StatAgg> m) =>
      m.entries.toList()..sort((a, b) => b.value.sessions30 != a.value.sessions30 ? b.value.sessions30 - a.value.sessions30 : b.value.attempts - a.value.attempts);

  /// الأسوأ نسبة نجاح بين ما له عيّنة كافية.
  static List<MapEntry<String, StatAgg>> worst(Map<String, StatAgg> m) =>
      m.entries.where((e) => e.value.rateIfSample() != null).toList()..sort((a, b) => a.value.rate!.compareTo(b.value.rate!));
}

class DeviceStats {
  int active7 = 0, active30 = 0;
  final byPlatform = <String, int>{}, byVersion = <String, int>{}, byCountry = <String, int>{}, byLocale = <String, int>{};

  DeviceStats.from(List<Map<String, dynamic>> rows, {DateTime? now}) {
    final t = now ?? DateTime.now();
    for (final r in rows) {
      final seen = DateTime.tryParse('${r['last_seen_at']}');
      if (seen == null) continue;
      final days = t.difference(seen).inHours / 24;
      if (days > 30) continue;
      active30++;
      if (days <= 7) active7++;
      void inc(Map<String, int> m, Object? k) => m['${k ?? '—'}'] = (m['${k ?? '—'}'] ?? 0) + 1;
      inc(byPlatform, r['platform']);
      inc(byVersion, r['app_version']);
      inc(byCountry, r['country']);
      inc(byLocale, r['locale']);
    }
  }
}

/// CSV متوافق مع Excel (UTF-8 مع BOM حتى تظهر العربية صحيحة).
String toExcelCsv(List<String> header, Iterable<List<Object?>> rows) {
  String cell(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
  final b = StringBuffer('﻿')..writeln(header.map(cell).join(','));
  for (final r in rows) {
    b.writeln(r.map(cell).join(','));
  }
  return b.toString();
}
