// قراءة وكتابة الإعدادات المركزية (ADM-G1–G6، F1–F2) في site_settings بصلاحية المدير.
// كل مفتاح هنا عام (is_public = true): يقرؤه كل تطبيق مشاهد. لا أسرار فيها.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend.dart';

class SettingsRepository {
  final SupabaseClient db;
  SettingsRepository(this.db);

  Future<Object?> get(String key) async => (await db.from('site_settings').select('value').eq('key', key).maybeSingle())?['value'];

  Future<void> set(String key, Object value) =>
      db.from('site_settings').upsert({'key': key, 'value': value, 'is_public': true, 'updated_at': DateTime.now().toUtc().toIso8601String()});

  /// G2: الحسابات الاجتماعية + توافق الموقع القديم (developer.social).
  Future<void> saveSocial(List<Map<String, dynamic>> links, Map<String, dynamic> support) async {
    await set('social', {'links': links, 'support': support});
    final dev = (await get('developer') as Map?)?.cast<String, dynamic>() ?? {};
    final legacy = <String, String>{
      for (final l in links)
        if (l['owner'] == 'developer' && '${l['platform']}' != 'custom' && '${l['handle'] ?? ''}'.isNotEmpty) '${l['platform']}': '${l['handle']}',
    };
    if (legacy.isNotEmpty) await set('developer', {...dev, 'social': legacy});
  }

  /// F1: إرسال Push لأجهزة Android عبر الدالة القائمة send-push (FCM، الموضوع «all»).
  Future<Map<String, dynamic>> sendPush({required String title, required String body, String? url, bool check = false}) async {
    final r = await db.functions.invoke('send-push', body: {'title': title, 'body': body, 'url': ?url, if (check) 'check': true});
    return (r.data as Map?)?.cast<String, dynamic>() ?? {'status': r.status};
  }
}

final settingsRepoProvider = Provider<SettingsRepository?>((ref) {
  final c = ref.watch(supabaseProvider);
  return c == null ? null : SettingsRepository(c);
});

/// تنظيف معرّف الحساب الاجتماعي (منطق cleanHandle في src/social.js): يقبل اليوزر أو ‎@اليوزر أو الرابط الكامل.
String cleanHandle(String input) {
  var s = input.trim();
  s = s.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  s = s.replaceFirst(RegExp(r'^(www\.|m\.)', caseSensitive: false), '');
  // نطاق ثم مسار: نأخذ أول جزء من المسار
  final m = RegExp(r'^[a-z0-9.-]+\.[a-z]{2,}/(.+)$', caseSensitive: false).firstMatch(s);
  if (m != null) s = m[1]!;
  s = s.split(RegExp(r'[?#]')).first.replaceAll(RegExp(r'/+$'), '');
  if (s.startsWith('in/')) s = s.substring(3); // linkedin.com/in/x
  if (s.startsWith('add/')) s = s.substring(4); // snapchat.com/add/x
  return s.replaceFirst('@', '').trim();
}

/// الرابط المبني لكل منصّة (§9.9 G2).
String socialUrl(String platform, String handle) {
  final h = cleanHandle(handle);
  return switch (platform) {
    'facebook' => 'https://facebook.com/$h',
    'instagram' => 'https://instagram.com/$h',
    'linkedin' => 'https://linkedin.com/in/$h',
    'snapchat' => 'https://snapchat.com/add/$h',
    'threads' => 'https://threads.net/@$h',
    'x' => 'https://x.com/$h',
    'tiktok' => 'https://tiktok.com/@$h',
    'pinterest' => 'https://pinterest.com/$h',
    'whatsapp' => 'https://wa.me/${h.replaceAll(RegExp(r'[^0-9]'), '')}',
    'telegram' => h.startsWith('+') ? 'https://t.me/${h.replaceAll(' ', '')}' : 'https://t.me/$h',
    'youtube' => 'https://youtube.com/@$h',
    _ => handle.trim().startsWith('http') ? handle.trim() : 'https://$h',
  };
}

const socialPlatforms = ['facebook', 'instagram', 'linkedin', 'snapchat', 'threads', 'x', 'tiktok', 'pinterest', 'whatsapp', 'telegram', 'youtube', 'custom'];
