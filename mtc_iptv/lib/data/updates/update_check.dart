// التحقق من التحديثات (V-11): أحدث إصدار 3.x منشور على GitHub (D-17: رقم واحد لكل المنصّات).
// إصدارات alpha تُعرض لمن يستخدم alpha؛ النسخة المستقرة لا تُعرض لها إصدارات تجريبية.
import 'dart:convert';

import 'package:http/http.dart' as http;

const releasesApi = 'https://api.github.com/repos/AneesAdwan/MTC-iPTv/releases?per_page=20';

/// رقم إصدار بصيغة X.Y.Z[-tag.N].
class AppVersion implements Comparable<AppVersion> {
  final int major, minor, patch;
  final String? pre; // alpha, beta …
  final int preN;
  const AppVersion(this.major, this.minor, this.patch, [this.pre, this.preN = 0]);

  static AppVersion? parse(String s) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:-([a-z]+)\.?(\d+)?)?').firstMatch(s.trim());
    if (m == null) return null;
    return AppVersion(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), m[4], int.tryParse(m[5] ?? '') ?? 0);
  }

  bool get isPrerelease => pre != null;

  @override
  int compareTo(AppVersion o) {
    for (final d in [major - o.major, minor - o.minor, patch - o.patch]) {
      if (d != 0) return d;
    }
    // النسخة المستقرة أحدث من أي نسخة تجريبية لنفس الرقم
    if (pre == null || o.pre == null) return (pre == null ? 1 : 0) - (o.pre == null ? 1 : 0);
    final p = pre!.compareTo(o.pre!);
    return p != 0 ? p : preN - o.preN;
  }

  @override
  String toString() => '$major.$minor.$patch${pre == null ? '' : '-$pre.$preN'}';
}

class UpdateInfo {
  final AppVersion version;
  final String pageUrl;

  /// ملفات الإصدار: الاسم ← رابط التنزيل المباشر (للتحديث داخل تطبيق Android).
  final Map<String, String> assets;
  const UpdateInfo(this.version, this.pageUrl, [this.assets = const {}]);
}

/// يختار أحدث إصدار مناسب من قائمة إصدارات GitHub؛ null إن كان الحالي هو الأحدث.
UpdateInfo? pickUpdate(AppVersion current, List<dynamic> releases) {
  UpdateInfo? best;
  for (final r in releases.cast<Map<String, dynamic>>()) {
    if (r['draft'] == true) continue;
    final v = AppVersion.parse('${r['tag_name']}');
    if (v == null || v.major < 3) continue; // التطبيق القديم (2.x) خط إصدارات آخر
    if (v.isPrerelease && !current.isPrerelease) continue;
    if (v.compareTo(current) <= 0) continue;
    if (best == null || v.compareTo(best.version) > 0) {
      best = UpdateInfo(v, '${r['html_url']}', {
        for (final a in (r['assets'] as List?) ?? const []) '${(a as Map)['name']}': '${a['browser_download_url']}',
      });
    }
  }
  return best;
}

Future<UpdateInfo?> checkForUpdate(String currentVersion, {http.Client? client}) async {
  final cur = AppVersion.parse(currentVersion) ?? const AppVersion(0, 0, 0, 'dev');
  final c = client ?? http.Client();
  try {
    final res = await c.get(Uri.parse(releasesApi), headers: {'Accept': 'application/vnd.github+json'}).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw StateError('github ${res.statusCode}');
    return pickUpdate(cur, jsonDecode(res.body) as List);
  } finally {
    if (client == null) c.close();
  }
}
