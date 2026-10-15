// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class L10nAr extends L10n {
  L10nAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'MTC-iPTv';

  @override
  String get company => 'مجموعة شركات مركز تكنولوجيا الشرق الأوسط — MTC-Group';

  @override
  String get developedBy => 'برمجة وتطوير: أنيس عدوان';

  @override
  String version(String v) {
    return 'الإصدار $v';
  }

  @override
  String get groupViewer => 'المشاهدة';

  @override
  String get groupAdmin => 'الإدارة';

  @override
  String get groupA => 'نظرة عامة';

  @override
  String get groupB => 'الكتالوج';

  @override
  String get groupC => 'الاستيراد والتحويل';

  @override
  String get groupD => 'الجودة';

  @override
  String get groupE => 'دليل البرامج';

  @override
  String get groupF => 'التواصل';

  @override
  String get groupG => 'الإعدادات';

  @override
  String get groupH => 'الأمن والنظام';

  @override
  String get groupI => 'التقارير';

  @override
  String get sV01 => 'البداية';

  @override
  String get sV02 => 'الرئيسية';

  @override
  String get sV03 => 'القنوات';

  @override
  String get sV04 => 'الدول';

  @override
  String get sV05 => 'البحث';

  @override
  String get sV06 => 'المشاهدة';

  @override
  String get sV07 => 'دليل البرامج';

  @override
  String get sV08 => 'المفضلة';

  @override
  String get sV09 => 'الإشعارات';

  @override
  String get sV10 => 'الإعدادات';

  @override
  String get sV11 => 'حول';

  @override
  String get sV12 => 'الإبلاغ عن مشكلة';

  @override
  String get sA1 => 'لوحة المعلومات';

  @override
  String get sA2 => 'المهام والطوابير';

  @override
  String get sA3 => 'التنبيهات';

  @override
  String get sB1 => 'القنوات';

  @override
  String get sB2 => 'تفاصيل القناة';

  @override
  String get sB3 => 'الروابط والسيرفرات';

  @override
  String get sB4 => 'العرض في الرئيسية';

  @override
  String get sB5 => 'التقسيمات';

  @override
  String get sB6 => 'الشبكات والشعارات';

  @override
  String get sB7 => 'الترقيم';

  @override
  String get sC1 => 'معالج الاستيراد';

  @override
  String get sC2 => 'مراجعة الاستيراد';

  @override
  String get sC3 => 'المصادر';

  @override
  String get sC4 => 'المراجع الخارجية';

  @override
  String get sC5 => 'التصدير';

  @override
  String get sC6 => 'قواعد التحويل';

  @override
  String get sD1 => 'قيد المراجعة';

  @override
  String get sD2 => 'المكررات والدمج';

  @override
  String get sD3 => 'المقارنة';

  @override
  String get sD4 => 'صحة البث';

  @override
  String get sD5 => 'الشعارات';

  @override
  String get sD6 => 'بلاغات المشاهدين';

  @override
  String get sE1 => 'مصادر EPG';

  @override
  String get sE2 => 'ربط القنوات';

  @override
  String get sE3 => 'معاينة الجدول';

  @override
  String get sF1 => 'الإشعارات';

  @override
  String get sF2 => 'الإعلانات والشرائط';

  @override
  String get sG1 => 'الهوية';

  @override
  String get sG2 => 'التواصل الاجتماعي';

  @override
  String get sG3 => 'الإعدادات العامة';

  @override
  String get sG4 => 'المشغّل والشبكة';

  @override
  String get sG5 => 'المزايا ووضع الصيانة';

  @override
  String get sG6 => 'الإصدارات والتحديث';

  @override
  String get sH1 => 'الحساب والأمان';

  @override
  String get sH2 => 'المهام المجدولة';

  @override
  String get sH3 => 'سجل التدقيق';

  @override
  String get sH4 => 'النسخ الاحتياطي';

  @override
  String get sH5 => 'الصيانة والتشخيص';

  @override
  String get sI1 => 'التحليلات';

  @override
  String get searchHint => 'بحث عام…';

  @override
  String get searchShortcut => 'Ctrl+K';

  @override
  String get paletteHint => 'اكتب اسم شاشة أو أمر…';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get collapse => 'طي القائمة';

  @override
  String get expand => 'توسيع القائمة';

  @override
  String get statusOnline => 'متصل';

  @override
  String get statusOffline => 'غير متصل';

  @override
  String get statusIdle => 'لا مهام جارية';

  @override
  String get minimize => 'تصغير';

  @override
  String get maximize => 'تكبير';

  @override
  String get restore => 'استعادة';

  @override
  String get close => 'إغلاق';

  @override
  String get placeholderTitle => 'قيد البناء';

  @override
  String placeholderBody(String id, String phase) {
    return 'هذه الشاشة ($id) تُبنى في المرحلة $phase من الخطة.';
  }

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get cmdToggleLanguage => 'تبديل اللغة';

  @override
  String get cmdToggleTheme => 'تبديل المظهر';

  @override
  String get cmdToggleSidebar => 'طي/توسيع القائمة الجانبية';

  @override
  String get adminSignIn => 'دخول المدير';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'دخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String signedInAs(String email) {
    return 'مسجّل باسم $email';
  }

  @override
  String get mfaEnrollTitle => 'فعّل التحقق بخطوتين';

  @override
  String get mfaEnrollBody =>
      'امسح الرمز بتطبيق مصادقة (Google Authenticator أو Microsoft Authenticator أو غيرهما)، ثم أدخل الرمز المكوّن من 6 أرقام. احفظ المفتاح السري في مكان آمن: تحتاجه إن فقدت جوالك.';

  @override
  String get mfaSecret => 'المفتاح السري';

  @override
  String get mfaCodeTitle => 'رمز التحقق';

  @override
  String get mfaCodeBody => 'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة.';

  @override
  String get mfaCode => 'الرمز';

  @override
  String get verify => 'تحقّق';

  @override
  String get notAdminTitle => 'هذا الحساب ليس المدير';

  @override
  String get notAdminBody => 'مركز الإدارة متاح لحساب المدير فقط.';

  @override
  String noBackendBody(String env) {
    return 'لا يوجد خادم مُعدّ لهذه البيئة ($env).';
  }

  @override
  String get authFailed => 'تعذّر الدخول: تحقّق من البريد وكلمة المرور.';

  @override
  String get codeFailed => 'الرمز غير صحيح أو انتهت صلاحيته.';

  @override
  String get copied => 'نُسخ';
}
