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

  @override
  String get featured => 'مميزة';

  @override
  String get recentlyAdded => 'مضافة حديثًا';

  @override
  String get continueWatching => 'تابع المشاهدة';

  @override
  String get allChannels => 'كل القنوات';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get catalogEmpty => 'لا توجد قنوات على الجهاز بعد.';

  @override
  String get catalogEmptyHint =>
      'تُجلب القنوات تلقائيًا عند الاتصال بالإنترنت.';

  @override
  String get syncing => 'جارٍ مزامنة القنوات…';

  @override
  String get filterAll => 'الكل';

  @override
  String get country => 'الدولة';

  @override
  String get category => 'الفئة';

  @override
  String channelsCount(int n) {
    return '$n قناة';
  }

  @override
  String get searchChannelsHint => 'ابحث باسم القناة أو رقمها…';

  @override
  String get noMatches => 'لا توجد قنوات مطابقة.';

  @override
  String get favoritesEmpty => 'لا توجد قنوات مفضلة بعد.';

  @override
  String get favoritesEmptyHint => 'اضغط ♥ في صفحة أي قناة لإضافتها هنا.';

  @override
  String get addFavorite => 'أضف للمفضلة';

  @override
  String get removeFavorite => 'أزل من المفضلة';

  @override
  String serverOf(int i, int n) {
    return 'السيرفر $i من $n';
  }

  @override
  String get switchingServer => 'جارٍ التبديل إلى سيرفر آخر…';

  @override
  String get loadingStream => 'جارٍ التحميل…';

  @override
  String get quality => 'الجودة';

  @override
  String get auto => 'تلقائي';

  @override
  String get audioTrack => 'الصوت';

  @override
  String get subtitles => 'الترجمة';

  @override
  String get off => 'إيقاف';

  @override
  String get nextChannel => 'القناة التالية';

  @override
  String get prevChannel => 'القناة السابقة';

  @override
  String get fullscreen => 'ملء الشاشة';

  @override
  String get exitFullscreen => 'إنهاء ملء الشاشة';

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get tryNextServer => 'جرّب سيرفرًا آخر';

  @override
  String get mute => 'كتم';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get errAuthFailed =>
      'السيرفر رفض الوصول (قد تكون القناة محمية أو تحتاج اشتراكًا).';

  @override
  String get errUnavailable => 'القناة غير متاحة حاليًا على هذا السيرفر.';

  @override
  String get errUnsupported => 'صيغة هذا البث غير مدعومة.';

  @override
  String get errNetwork => 'السيرفر لا يستجيب. تحقّق من اتصالك أو جرّب لاحقًا.';

  @override
  String get errGeneric => 'تعذّر تشغيل القناة.';

  @override
  String allServersFailed(int n) {
    return 'جُرّبت كل السيرفرات ($n) دون نجاح.';
  }

  @override
  String get noServers => 'لا توجد روابط لهذه القناة.';

  @override
  String get back => 'رجوع';

  @override
  String channelNumber(int n) {
    return 'القناة $n';
  }

  @override
  String get nowLabel => 'الآن';

  @override
  String get nextLabel => 'التالي';

  @override
  String get jumpToNow => 'الآن';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get yesterday => 'أمس';

  @override
  String get guideEmpty => 'لا يوجد دليل برامج بعد.';

  @override
  String get guideEmptyHint => 'يُجلب الدليل تلقائيًا عند الاتصال بالإنترنت.';

  @override
  String get remindMe => 'ذكّرني';

  @override
  String get cancelReminder => 'إلغاء التذكير';

  @override
  String get reminderSet => 'سنذكّرك قبل بدايته بـ 5 دقائق.';

  @override
  String get reminderRemoved => 'أُلغي التذكير.';

  @override
  String reminderFired(String title) {
    return 'يبدأ قريبًا: $title';
  }

  @override
  String get watchNow => 'شاهد';

  @override
  String get inboxEmpty => 'لا توجد إشعارات.';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get kindReminder => 'تذكير';

  @override
  String get sectionGeneral => 'عام';

  @override
  String get sectionPlayer => 'المشغّل';

  @override
  String get sectionParental => 'الرقابة الأبوية';

  @override
  String get sectionStorage => 'التخزين والمزامنة';

  @override
  String get sectionPrivacy => 'الخصوصية';

  @override
  String get showNumbers => 'إظهار أرقام القنوات';

  @override
  String get maxQuality => 'أعلى جودة تلقائية';

  @override
  String get qualityNoLimit => 'بلا حد، حتى 1080p';

  @override
  String get parentalHint =>
      'رمز من 4 أرقام يقفل الفئات التي تختارها والقنوات المخصّصة للكبار.';

  @override
  String get setPin => 'تعيين رمز';

  @override
  String get removePin => 'إيقاف';

  @override
  String get enterPin => 'أدخل الرمز';

  @override
  String get newPin => 'رمز جديد من 4 أرقام';

  @override
  String get pinWrong => 'الرمز غير صحيح';

  @override
  String get lockedCategories => 'الفئات المقفلة';

  @override
  String get channelLocked => 'هذه القناة مقفلة بالرقابة الأبوية.';

  @override
  String get unlock => 'فتح';

  @override
  String lastSync(String t) {
    return 'آخر مزامنة: $t';
  }

  @override
  String get never => 'لم تتم بعد';

  @override
  String get syncNow => 'زامن الآن';

  @override
  String get syncDone => 'اكتملت المزامنة.';

  @override
  String get clearHistory => 'مسح سجل المشاهدة';

  @override
  String get historyCleared => 'مُسح سجل المشاهدة.';

  @override
  String get telemetry => 'إرسال إحصاءات تشغيل مجهولة';

  @override
  String get telemetryHint =>
      'تساعد في تحسين القنوات. لا تتضمن أي روابط أو حسابات أو بيانات شخصية.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get checkUpdates => 'التحقق من التحديثات';

  @override
  String get upToDate => 'لديك أحدث إصدار.';

  @override
  String updateAvailable(String v) {
    return 'الإصدار $v متوفر.';
  }

  @override
  String get download => 'تنزيل';

  @override
  String get updateCheckFailed => 'تعذّر التحقق من التحديثات.';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyText =>
      'لا يحتاج MTC-iPTv إلى حساب ولا يجمع بيانات شخصية. المفضلة والسجل والتذكيرات والإعدادات تبقى على جهازك. عند تفعيلها، تُرسل إحصاءات تشغيل مجهولة (نجاح أو فشل، زمن البدء، نوع الخطأ) دون روابط أو معرّفات لتحسين القنوات. بلاغات المشاكل تحتوي ما تكتبه فقط، مع التفاصيل التقنية إن اخترت إرفاقها.';

  @override
  String get reportTitle => 'الإبلاغ عن مشكلة';

  @override
  String get reportChannelHint =>
      'افتح القناة ثم اضغط زر العلم في المشغّل للإبلاغ عن مشكلة فيها.';

  @override
  String get reasonNotWorking => 'لا تعمل';

  @override
  String get reasonWrongInfo => 'معلومات خاطئة';

  @override
  String get reasonBadQuality => 'جودة سيئة';

  @override
  String get reasonOther => 'أخرى';

  @override
  String get noteHint => 'التفاصيل (اختياري)';

  @override
  String get attachDiag =>
      'إرفاق تفاصيل تقنية (الإصدار، النظام، نوع الخطأ — دون روابط)';

  @override
  String get send => 'إرسال';

  @override
  String get reportSent => 'شكرًا لك! أُرسل البلاغ.';

  @override
  String get reportFailed => 'تعذّر الإرسال. تحقّق من اتصالك وأعد المحاولة.';

  @override
  String noChannelNumber(int n) {
    return 'لا توجد قناة بالرقم $n';
  }

  @override
  String get openPlayer => 'فتح المشغّل';

  @override
  String get closePlayer => 'إغلاق المشغّل';
}
