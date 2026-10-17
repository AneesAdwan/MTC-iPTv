// Build-time environment. No secrets here, ever: the Supabase URL and the PUBLIC anon key only (the
// same values published in the website's config.js). Every real permission is enforced on the server
// (RLS + is_admin(), plan §9.1). The program holds no service key and never decides it is authorized.
//
//   flutter run -d windows                                   (production project)
//   flutter run -d windows --dart-define=MTC_ENV=local       (local Supabase in Docker)
//   --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…   (override, e.g. staging)
enum AppEnv { production, staging, local }

abstract final class Env {
  static const appTitle = 'MTC-iPTv SuperAdmin';
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0-dev');

  static const name = String.fromEnvironment('MTC_ENV', defaultValue: 'production');
  static AppEnv get current => switch (name) {
    'staging' => AppEnv.staging,
    'local' => AppEnv.local,
    _ => AppEnv.production,
  };

  static const _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _keyOverride = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _urlOverride.isNotEmpty
      ? _urlOverride
      : switch (current) {
          AppEnv.production => 'https://nuxfcfyylzgipxdwbnyf.supabase.co',
          AppEnv.local => 'http://127.0.0.1:58321',
          AppEnv.staging => '',
        };

  static String get supabaseAnonKey => _keyOverride.isNotEmpty
      ? _keyOverride
      : switch (current) {
          // Public anon key (role=anon), identical to config.js of the website and mtc_iptv/lib/core/config/env.dart.
          AppEnv.production => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51eGZjZnl5bHpnaXB4ZHdibnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NTk1NzgsImV4cCI6MjEwNzEzNTU3OH0.e_UGRfKLVwLWsyLSnoiPFQblC1XlpSpX_Klviqt7PAQ',
          // Standard local Supabase demo anon key (iss=supabase-demo).
          AppEnv.local => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
          AppEnv.staging => '',
        };

  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// The admin_* server functions arrive in Phase 2. Until then every write goes to the stub RPC layer,
  /// which performs nothing and reports so honestly in the result bar.
  static const serverFunctionsReady = bool.fromEnvironment('MTC_SERVER_FUNCTIONS', defaultValue: false);
}
