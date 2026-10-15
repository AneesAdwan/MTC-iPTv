// البيئات (§9.10 ADM-H5): production / staging / local. تُختار وقت البناء:
//   flutter run -d windows --dart-define=MTC_ENV=local      (Supabase محلي في Docker: supabase start)
//   flutter build windows --dart-define=MTC_ENV=staging
// لا أسرار هنا إطلاقًا (§19.1): رابط Supabase و**المفتاح العام (anon)** فقط — نفس ما في config.js المنشور
// للموقع. الصلاحيات الحقيقية تفرضها RLS و is_admin() على الخادم.
enum AppEnv { production, staging, local }

abstract final class Env {
  static const name = String.fromEnvironment('MTC_ENV', defaultValue: 'production');
  static AppEnv get current => switch (name) { 'staging' => AppEnv.staging, 'local' => AppEnv.local, _ => AppEnv.production };
  static bool get isStaging => current == AppEnv.staging;
  static bool get isProduction => current == AppEnv.production;

  /// رقم الإصدار يُمرَّر من scripts/release.ps1 (--dart-define=APP_VERSION).
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '3.0.0-dev');

  // يمكن تجاوزهما وقت البناء (مشروع staging):  --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…
  static const _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _keyOverride = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _urlOverride.isNotEmpty
      ? _urlOverride
      : switch (current) {
          AppEnv.production => 'https://nuxfcfyylzgipxdwbnyf.supabase.co',
          AppEnv.local => 'http://127.0.0.1:58321',
          AppEnv.staging => '', // يُضاف عند إنشاء مشروع staging
        };

  static String get supabaseAnonKey => _keyOverride.isNotEmpty ? _keyOverride : supabaseAnonKeyFor(current);

  static String supabaseAnonKeyFor(AppEnv env) => switch (env) {
          // المفتاح العام نفسه المنشور في config.js للموقع (role=anon)
          AppEnv.production => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51eGZjZnl5bHpnaXB4ZHdibnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTk1NzgsImV4cCI6MjEwNzEzNTU3OH0.e_UGRfKLVwLWsyLSnoiPFQblC1XlpSpX_Klviqt7PAQ',
          // مفتاح Supabase المحلي التجريبي القياسي (role=anon، iss=supabase-demo)
          AppEnv.local => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
          AppEnv.staging => '',
        };

  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}