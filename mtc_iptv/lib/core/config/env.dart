// البيئات (§9.10 ADM-H5): production / staging. تُختار وقت البناء:
//   flutter build windows --dart-define=MTC_ENV=staging
// لا أسرار هنا إطلاقًا (§19.1): رابط Supabase والمفتاح العام فقط، ويُضافان في المرحلة 2.
enum AppEnv { production, staging }

abstract final class Env {
  static const name = String.fromEnvironment('MTC_ENV', defaultValue: 'production');
  static AppEnv get current => name == 'staging' ? AppEnv.staging : AppEnv.production;
  static bool get isStaging => current == AppEnv.staging;

  /// رقم الإصدار يأتي من pubspec عبر --build-name، ويُمرَّر هنا للعرض.
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '3.0.0');
}
