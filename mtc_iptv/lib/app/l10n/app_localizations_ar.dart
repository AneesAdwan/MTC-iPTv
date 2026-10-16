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
      'لا يحتاج MTC-iPTv إلى حساب، ولا يجمع اسمك أو بريدك أو عنوان IP أو موقعك الدقيق أو أي معرّف إعلاني. المفضلة والسجل والتذكيرات والإعدادات تبقى على جهازك.\n\nعند تفعيل الإحصاءات يُرسل التطبيق لكل محاولة تشغيل: السيرفر المستخدم (لا رابطه)، النجاح أو الفشل ونوع الخطأ، زمن البدء، مدة المشاهدة (مقرّبة) والدقة — مع معرّف عشوائي للجهاز والمنصّة والإصدار ولغة التطبيق والدولة التقريبية. تُحفظ الأحداث 30 يومًا ثم تبقى مجاميع يومية فقط بلا معرّفات أجهزة، ويُحذف سجل الجهاز بعد 90 يومًا من آخر ظهور. يمكنك إيقاف الإحصاءات أو إعادة تعيين معرّف الجهاز (فيُحذف السابق) من الإعدادات.\n\nبلاغات المشاكل تحتوي ما تكتبه فقط، مع التفاصيل التقنية إن اخترت إرفاقها.';

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

  @override
  String get psPublished => 'منشورة';

  @override
  String get psPending => 'قيد المراجعة';

  @override
  String get psHidden => 'مخفية';

  @override
  String get psDraft => 'مسودة';

  @override
  String get psRejected => 'مرفوضة';

  @override
  String get hsPlayable => 'قابل للتشغيل';

  @override
  String get hsReachable => 'قابل للوصول';

  @override
  String get hsDegraded => 'متدهور';

  @override
  String get hsAuthFailed => 'مصادقة مرفوضة';

  @override
  String get hsUnsupported => 'صيغة غير مدعومة';

  @override
  String get hsNetworkError => 'خطأ شبكة';

  @override
  String get hsUnavailable => 'غير متاح';

  @override
  String get hsGeoRestricted => 'قيود وصول محتملة';

  @override
  String get hsInconclusive => 'غير حاسم';

  @override
  String get hsDisabled => 'معطّل';

  @override
  String get kpiChannels => 'القنوات';

  @override
  String get kpiStreams => 'الروابط';

  @override
  String get kpiWorking => 'تعمل';

  @override
  String get kpiFailing => 'فاشلة';

  @override
  String get kpiUncertain => 'غير مثبتة';

  @override
  String get kpiOpenReports => 'بلاغات مفتوحة';

  @override
  String get kpiEpgCoverage => 'تغطية الدليل';

  @override
  String kpiEpgHint(int n, int total) {
    return '$n من $total منشورة لها برامج خلال 24 ساعة';
  }

  @override
  String get streamHealth => 'صحة الروابط';

  @override
  String get recentChanges => 'آخر التغييرات';

  @override
  String get noChanges => 'لا تغييرات مسجّلة بعد.';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get qaReviewPending => 'مراجعة المعلّق';

  @override
  String get qaCheckFailing => 'فحص الروابط الفاشلة';

  @override
  String get qaReports => 'بلاغات المشاهدين';

  @override
  String get refresh => 'تحديث';

  @override
  String get addChannel => 'إضافة قناة';

  @override
  String get searchAdminHint => 'الاسم أو الرقم أو المعرّف أو الشبكة…';

  @override
  String get allStates => 'كل الحالات';

  @override
  String get allCountries => 'كل الدول';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get fFeatured => 'مميزة';

  @override
  String get fNoLogo => 'بلا شعار';

  @override
  String get fManual => 'يدوية';

  @override
  String get colNumber => '#';

  @override
  String get colName => 'الاسم';

  @override
  String get colCountry => 'الدولة';

  @override
  String get colCategory => 'الفئة';

  @override
  String get colStreams => 'الروابط';

  @override
  String get colState => 'الحالة';

  @override
  String get colUpdated => 'آخر تعديل';

  @override
  String pageOf(int from, int to, int total) {
    return '$from–$to من $total';
  }

  @override
  String selected(int n) {
    return 'تم تحديد $n';
  }

  @override
  String get aPublish => 'نشر';

  @override
  String get aHide => 'إخفاء';

  @override
  String get aFeature => 'تمييز';

  @override
  String get aUnfeature => 'إلغاء التمييز';

  @override
  String get aSetCategory => 'تغيير الفئة';

  @override
  String get aSetCountry => 'تغيير الدولة';

  @override
  String get aCheckStreams => 'فحص الروابط';

  @override
  String get aDelete => 'حذف';

  @override
  String get aDisable => 'تعطيل';

  @override
  String get aEnable => 'تفعيل';

  @override
  String get aTry => 'جرّب الآن';

  @override
  String get aCheck => 'فحص';

  @override
  String get aEdit => 'تعديل';

  @override
  String get aResolve => 'تمّ الحل';

  @override
  String get aOpenChannel => 'فتح القناة';

  @override
  String get aHideChannel => 'إخفاء القناة';

  @override
  String confirmDelete(int n) {
    return 'حذف $n عنصر نهائيًا؟ لا يمكن التراجع من هنا (سجل التغييرات يحتفظ بنسخة).';
  }

  @override
  String get saved => 'تم الحفظ.';

  @override
  String saveFailed(String e) {
    return 'تعذّر الحفظ: $e';
  }

  @override
  String get tabInfo => 'المعلومات';

  @override
  String get tabStreams => 'الروابط';

  @override
  String get tabGuide => 'دليل البرامج';

  @override
  String get tabHistory => 'السجل';

  @override
  String get fNameAr => 'الاسم بالعربية';

  @override
  String get fNameEn => 'الاسم بالإنجليزية';

  @override
  String get fAltNames => 'أسماء بديلة (مفصولة بفواصل)';

  @override
  String get fNumber => 'الرقم';

  @override
  String get fNetwork => 'الشبكة';

  @override
  String get fLogoUrl => 'رابط الشعار';

  @override
  String get fLanguage => 'رمز اللغة';

  @override
  String get fQuality => 'الجودة';

  @override
  String get fDescription => 'الوصف';

  @override
  String get fWebsite => 'الموقع';

  @override
  String get fEpgId => 'معرّف EPG (فارغ = uid)';

  @override
  String get fEpgOffset => 'إزاحة الدليل (دقائق)';

  @override
  String get fParental => 'للكبار (قفل أبوي)';

  @override
  String get fPublishState => 'حالة النشر';

  @override
  String get addStream => 'إضافة رابط';

  @override
  String get fUrl => 'رابط البث';

  @override
  String get fLabel => 'اسم السيرفر (اختياري)';

  @override
  String get fUserAgent => 'User-Agent (اختياري)';

  @override
  String get fReferrer => 'Referer (اختياري)';

  @override
  String get dragToReorder =>
      'اسحب لترتيب الأولوية: المشغّل يجرّب السيرفر الأعلى أولًا.';

  @override
  String get noStreamsAdmin => 'لا روابط لهذه القناة.';

  @override
  String lastChecked(String t) {
    return 'فُحص $t';
  }

  @override
  String get neverChecked => 'لم يُفحص بعد';

  @override
  String checkRunning(int done, int total) {
    return 'جارٍ فحص $done من $total…';
  }

  @override
  String checkDone(int done) {
    return 'انتهى الفحص: $done رابط.';
  }

  @override
  String get checkOffline =>
      'توقف الفحص: لا إنترنت على هذا الجهاز، ولم يُسجَّل شيء.';

  @override
  String get stop => 'إيقاف';

  @override
  String get playCheck => 'فحص التشغيل (mpv)';

  @override
  String get playCheckHint =>
      'الطبقة 1 تثبت أن الخادم يستجيب؛ الطبقة 2 تثبت وصول إطار فيديو فعلي.';

  @override
  String get noStreamsInState => 'لا روابط بهذه الحالة.';

  @override
  String get noOpenReports => 'لا بلاغات مفتوحة.';

  @override
  String reportsCount(int n) {
    return '$n بلاغ';
  }

  @override
  String get epgPreviewHint => 'البرامج المحفوظة على هذا الجهاز لهذه القناة.';

  @override
  String get noEpgForChannel => 'لا برامج لهذه القناة.';

  @override
  String notAvailableYet(int p) {
    return 'تأتي مع المرحلة $p.';
  }

  @override
  String reasonLabel(String r) {
    return 'السبب: $r';
  }

  @override
  String get bkUnchecked => 'لم تُفحص';

  @override
  String get bkReady => 'جاهزة للنشر';

  @override
  String get bkDuplicate => 'مكررة';

  @override
  String get bkOffline => 'لا تعمل';

  @override
  String get bkLogo => 'شعار معطّل';

  @override
  String get bkIncomplete => 'ناقصة';

  @override
  String get bkUncheckedHint =>
      'روابطها لم تُفحص بعد: افحص الدلو فتُصنَّف تلقائيًا.';

  @override
  String get bkReadyHint => 'روابطها تعمل وغير مكررة. راجعها ثم وافق عليها.';

  @override
  String get bkDuplicateHint =>
      'نفس قناة موجودة في الكتالوج: ادمجها (تصبح روابطها سيرفرات إضافية) أو علّمها «ليست مكررة».';

  @override
  String get bkOfflineHint => 'لا رابط يعمل. ارفضها، أو انتظر فحصًا جديدًا.';

  @override
  String get bkLogoHint => 'الشعار لا يظهر. أصلحه قبل النشر.';

  @override
  String get bkIncompleteHint => 'قنوات تعمل لكن بلا دولة. عدّلها قبل النشر.';

  @override
  String get reviewEmpty => 'لا شيء بانتظار المراجعة.';

  @override
  String get aApprove => 'موافقة ونشر';

  @override
  String get aReject => 'رفض (حذف)';

  @override
  String get aMerge => 'دمج في الأصلية';

  @override
  String get aNotDuplicate => 'ليست مكررة';

  @override
  String aAllInBucket(int n) {
    return 'كل الدلو ($n)';
  }

  @override
  String originalOf(String name) {
    return 'الأصلية: $name';
  }

  @override
  String streamsWorking(int ok, int n) {
    return '$ok/$n تعمل';
  }

  @override
  String confirmReject(int n) {
    return 'حذف $n قناة معلّقة مع روابطها؟';
  }

  @override
  String doneCount(int n) {
    return 'تم: $n.';
  }

  @override
  String get numOrderBy => 'الترتيب حسب';

  @override
  String get nkArab => 'الدول العربية أولًا';

  @override
  String get nkCountry => 'الدولة';

  @override
  String get nkCategory => 'الفئة';

  @override
  String get nkLanguage => 'اللغة';

  @override
  String get nkFeatured => 'المميزة أولًا';

  @override
  String get nkQuality => 'الجودة';

  @override
  String get nkOnline => 'الروابط العاملة';

  @override
  String get nkName => 'الاسم';

  @override
  String get nkCurrent => 'الرقم الحالي';

  @override
  String get nkNewest => 'الأحدث';

  @override
  String get nkSortOrder => 'ترتيب الظهور';

  @override
  String get numStart => 'أول رقم';

  @override
  String get numBlock => 'حجم الكتلة لكل مجموعة (0 = متتالٍ)';

  @override
  String get numPublishedFirst => 'المنشورة أولًا';

  @override
  String get numPreview => 'معاينة';

  @override
  String get numApply => 'تطبيق';

  @override
  String numSummary(int changed, int total, int max) {
    return '$changed من $total قناة يتغير رقمها · آخر رقم $max';
  }

  @override
  String numConfirm(int n) {
    return 'إعادة ترقيم $n قناة؟ يرى المشاهدون الأرقام الجديدة بعد مزامنتهم التالية.';
  }

  @override
  String numApplied(int n) {
    return 'أُعيد ترقيم $n قناة.';
  }

  @override
  String get numHint =>
      'اختر الترتيب، عاين، ثم طبّق. التغيير كله يتم دفعة واحدة على الخادم، ويبقى الرقم القديم لكل قناة في سجلها.';

  @override
  String get tabCategories => 'الفئات';

  @override
  String get tabCountries => 'الدول';

  @override
  String get tabLanguages => 'اللغات';

  @override
  String get fSlug => 'المعرّف';

  @override
  String get fIcon => 'الأيقونة';

  @override
  String get fHue => 'اللون (0–360)';

  @override
  String get fSort => 'الترتيب';

  @override
  String get fVisible => 'ظاهرة';

  @override
  String get fFlag => 'العلم';

  @override
  String get fContinent => 'القارة';

  @override
  String get fArab => 'دولة عربية';

  @override
  String usedBy(int n) {
    return '$n قناة';
  }

  @override
  String cannotDeleteUsed(int n) {
    return 'مستخدمة في $n قناة — انقلها أولًا.';
  }

  @override
  String get addItem => 'إضافة';

  @override
  String get hostFilter => 'النطاق…';

  @override
  String get allProtocols => 'كل البروتوكولات';

  @override
  String get fCredentials => 'فيها بيانات اعتماد';

  @override
  String get hostsTitle => 'النطاقات';

  @override
  String get jobsRunning => 'يعمل الآن';

  @override
  String get jobsHistory => 'آخر التشغيلات';

  @override
  String get jobsScheduled => 'المهام المجدولة';

  @override
  String get noRuns => 'لا تشغيلات مسجّلة بعد.';

  @override
  String taskEvery(int m) {
    return 'كل $m دقيقة';
  }

  @override
  String taskLast(String t) {
    return 'آخر تشغيل $t';
  }

  @override
  String get tkHealthPublished => 'فحص روابط المنشورة';

  @override
  String get tkHealthAll => 'فحص كل الروابط';

  @override
  String get tkPlaybackSample => 'عيّنة تشغيل';

  @override
  String get tkLogos => 'فحص الشعارات';

  @override
  String get tkEpg => 'مزامنة دليل البرامج';

  @override
  String get tkSources => 'تحديث المصادر';

  @override
  String get tkBackup => 'النسخ الاحتياطي';

  @override
  String get schedulerNote =>
      'المُجدوِل الذي يشغّلها تلقائيًا يأتي مع المرحلة 6 (ADM-H2). الفحوص اليدوية تُسجَّل هنا.';

  @override
  String get hlHero => 'يعرض الآن (الواجهة)';

  @override
  String get hlHeroHint =>
      'قناة أو أكثر تظهر كبيرة أعلى الرئيسية؛ إن كانت أكثر من واحدة تتناوب كل 8 ثوانٍ.';

  @override
  String get hlRows => 'صفوف الرئيسية';

  @override
  String get hlAddRow => 'إضافة صف';

  @override
  String get hlPublishHint =>
      'التغييرات المحفوظة تصل للمشاهدين في مزامنتهم التالية.';

  @override
  String get hlReset => 'استعادة الافتراضي';

  @override
  String get rtFeatured => 'المميزة';

  @override
  String get rtHistory => 'تابع المشاهدة (لكل مشاهد)';

  @override
  String get rtFavorites => 'المفضلة (لكل مشاهد)';

  @override
  String get rtRecent => 'المضافة حديثًا';

  @override
  String get rtCategoriesAuto => 'صفوف الفئات (تلقائي)';

  @override
  String get rtCategory => 'فئة واحدة';

  @override
  String get rtCountry => 'دولة واحدة';

  @override
  String get rtManual => 'قنوات مختارة يدويًا';

  @override
  String get rtAll => 'كل القنوات';

  @override
  String get fTitleAr => 'العنوان بالعربية (اختياري)';

  @override
  String get fTitleEn => 'العنوان بالإنجليزية (اختياري)';

  @override
  String get fCount => 'عدد القنوات في الصف';

  @override
  String get fFrom => 'يظهر من';

  @override
  String get fTo => 'يظهر حتى';

  @override
  String get addChannels => 'إضافة قنوات';

  @override
  String get pickChannel => 'اختر قناة';

  @override
  String netChannels(int n) {
    return '$n قناة';
  }

  @override
  String get netRename => 'إعادة تسمية';

  @override
  String get netNewName => 'الاسم الجديد (فارغ = إزالة الشبكة)';

  @override
  String get logoLibraryLater =>
      'مكتبة الشعارات (الرفع للتخزين وأحجام WebP) تأتي مع إعداد التخزين في المرحلة 6.';

  @override
  String dupGroups(int n) {
    return '$n مجموعة مكررة';
  }

  @override
  String get noDuplicates => 'لا مكررات.';

  @override
  String get aCompare => 'مقارنة';

  @override
  String get aHideOthers => 'إخفاء البقية';

  @override
  String get aMergeHere => 'ادمج فيها';

  @override
  String mergeTitle(String name) {
    return 'الدمج في: $name';
  }

  @override
  String mergePreview(int s, int c) {
    return '$s رابط ينتقل إليها · $c قناة تُخفى (لا تُحذف)';
  }

  @override
  String get mergeFieldsHint => 'الحقول المختلفة: اختر القيمة التي تبقى.';

  @override
  String get mergeUndoHint =>
      'القنوات المدموجة تبقى مخفية مع إشارة لهذه القناة، ويمكن التراجع عن الدمج من صفحتها.';

  @override
  String get mergedHere => 'قنوات مدموجة في هذه القناة';

  @override
  String get aUnmerge => 'تراجع عن الدمج';

  @override
  String get compareHint =>
      'اختر 2–4 قنوات من «المكررات» أو «القنوات» لمقارنتها هنا.';

  @override
  String get playSideBySide => 'تشغيل جنبًا إلى جنب';

  @override
  String get diffOnly => 'الاختلافات فقط';

  @override
  String get compareMoreLater =>
      'مقارنة المصادر واللقطات تأتي مع الاستيراد (المرحلة 5).';

  @override
  String get lgBroken => 'معطّلة';

  @override
  String get lgMissing => 'بلا شعار';

  @override
  String get lgUnchecked => 'لم تُفحص';

  @override
  String get lgOk => 'تعمل';

  @override
  String get checkLogos => 'فحص الشعارات';

  @override
  String logoChecking(int done, int total) {
    return 'فحص الشعارات $done/$total…';
  }

  @override
  String get logoMoreLater =>
      'اقتراحات الشعارات من iptv-org ونسخها للتخزين تأتي مع المرحلتين 5 و6.';

  @override
  String get setLogo => 'تعيين الشعار';

  @override
  String get imFile => 'ملف';

  @override
  String get imUrl => 'رابط';

  @override
  String get imPaste => 'لصق';

  @override
  String get imXtream => 'حساب Xtream';

  @override
  String get imChooseFiles => 'اختر ملفًا…';

  @override
  String get imPasteHint =>
      'الصق M3U أو CSV أو JSON أو روابط (رابط في كل سطر)…';

  @override
  String get imAnalyze => 'تحليل';

  @override
  String get imXServer => 'الخادم (http://host:port)';

  @override
  String get imXUser => 'اسم المستخدم';

  @override
  String get imXPass => 'كلمة المرور';

  @override
  String get imXtreamNote =>
      'يُستخدم الحساب مرة واحدة لهذا الاستيراد ولا يُحفظ.';

  @override
  String get imAnalyzing => 'جارٍ التحليل…';

  @override
  String imFormat(String f, String e) {
    return 'الصيغة $f · الترميز $e';
  }

  @override
  String imIssues(int n) {
    return 'أسطر لم تُقرأ ($n)';
  }

  @override
  String get kNew => 'قنوات جديدة';

  @override
  String get kUpdate => 'إضافة لقناة موجودة';

  @override
  String get kExisting => 'موجودة في الكتالوج';

  @override
  String get kInFile => 'مكررة في الملف';

  @override
  String get kFailed => 'غير مدعومة';

  @override
  String imCommit(int n) {
    return 'استيراد المحدد ($n)';
  }

  @override
  String get imCommitHint =>
      'لا يُكتب شيء قبل الاستيراد. القنوات الجديدة تذهب لقيد المراجعة؛ والموجودة يُضاف لها الرابط الجديد فقط (تعديلاتك تبقى كما هي).';

  @override
  String get imDone => 'انتهى الاستيراد';

  @override
  String imResult(int channels, int streams, int disabled) {
    return 'أُضيفت $channels قناة و$streams رابط · عُطّل $disabled رابط';
  }

  @override
  String get imGoReview => 'فتح قيد المراجعة';

  @override
  String get imNew => 'استيراد جديد';

  @override
  String imVanished(int n) {
    return '$n رابط من هذا المصدر لم يعد موجودًا فيه';
  }

  @override
  String get imDisableVanished => 'تعطيلها (لا حذف)';

  @override
  String get imPossibleDup => 'مكررة محتملة';

  @override
  String get imAll => 'الكل';

  @override
  String get imNone => 'لا شيء';

  @override
  String get srcAdd => 'إضافة مصدر';

  @override
  String get srcName => 'الاسم';

  @override
  String get srcUrl => 'رابط القائمة (https)';

  @override
  String get srcRefresh => 'جلب ومراجعة';

  @override
  String srcLast(String t) {
    return 'آخر استيراد $t';
  }

  @override
  String srcCounts(int c, int s) {
    return '$c قناة · $s رابط';
  }

  @override
  String get srcRemove => 'إزالة المصدر';

  @override
  String get srcRemoveConfirm =>
      'إزالة هذا المصدر؟ روابطه وقنواته تبقى في الكتالوج.';

  @override
  String get srcActive => 'مفعّل';

  @override
  String get srcScheduleLater =>
      'التحديث التلقائي المجدول يأتي مع المُجدوِل (المرحلة 6). الآن: «جلب ومراجعة».';

  @override
  String get srcEmpty => 'لا مصادر بعد.';

  @override
  String get exFormat => 'الصيغة';

  @override
  String get exWorkingOnly => 'الروابط العاملة فقط';

  @override
  String get exBestOnly => 'أفضل رابط فقط';

  @override
  String get exSkipCreds => 'استبعاد الروابط ذات بيانات الاعتماد';

  @override
  String get exExport => 'تصدير…';

  @override
  String exDone(int n) {
    return 'صُدّرت $n قناة.';
  }

  @override
  String exChannels(int n) {
    return '$n قناة مطابقة';
  }

  @override
  String get needsMigration => 'يحتاج هذا ترحيلًا على الخادم لم يُطبَّق بعد.';

  @override
  String get resetInstallId => 'إعادة تعيين معرّف الجهاز';

  @override
  String get resetInstallIdHint =>
      'يولّد معرّفًا عشوائيًا جديدًا ويحذف السابق وإحصاءاته من الخادم.';

  @override
  String get resetInstallIdDone => 'تم إنشاء معرّف جديد للجهاز';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get kpiSuccess24h => 'نجاح التشغيل (24 ساعة)';

  @override
  String kpiSampleLow(int n) {
    return 'العيّنة غير كافية ($n محاولة)';
  }

  @override
  String kpiAttempts(int n) {
    return '$n محاولة';
  }

  @override
  String get kpiDevices7 => 'الأجهزة النشطة (7 أيام)';

  @override
  String get tkTelemetryRollup => 'تجميع إحصاءات التشغيل';

  @override
  String get tkAlerts => 'فحص التنبيهات';

  @override
  String get alEpgFailed => 'فشل تحديث الدليل';

  @override
  String get alEpgStale => 'الدليل لم يتحدّث منذ 48 ساعة';

  @override
  String get alSourceFailed => 'تعطّل مصدر';

  @override
  String get alImportFailed => 'فشل الاستيراد';

  @override
  String get alSuccessDrop => 'انخفاض نسبة نجاح التشغيل';

  @override
  String get alBackupFailed => 'فشلت النسخة الاحتياطية';

  @override
  String get alBackupStale => 'لا نسخة احتياطية منذ 48 ساعة';

  @override
  String get alRepeatedReports => 'بلاغات متكررة';

  @override
  String get alConnectorStopped => 'توقف موصل تلقائيًا';

  @override
  String get alTaskFailed => 'فشلت مهمة مجدولة';

  @override
  String alSuccessDetail(String rate, String prev, String attempts) {
    return 'نسبة الأمس $rate (الأسبوع السابق $prev) من $attempts محاولة';
  }

  @override
  String alReportsDetail(String name, String count) {
    return '$name: $count بلاغات مفتوحة خلال 24 ساعة';
  }

  @override
  String get alAlreadyOpen => 'يوجد تنبيه مفتوح للحالة نفسها.';

  @override
  String get alOpen => 'المفتوحة';

  @override
  String get alNew => 'جديد';

  @override
  String get alSeen => 'تمّت رؤيته';

  @override
  String get alResolved => 'تمّ الحل';

  @override
  String get alAll => 'الكل';

  @override
  String get alScanNow => 'افحص الآن';

  @override
  String get alMarkAllSeen => 'تمّت رؤية الكل';

  @override
  String get alHint =>
      'يفحص المُجدوِل الشروط كل ساعة. تبقى المشكلة تنبيهًا واحدًا يزداد عدد تكراره، ولا يُحل إلا بقرارك.';

  @override
  String get alNone => 'لا تنبيهات.';

  @override
  String alTimes(int n) {
    return '$n مرات';
  }

  @override
  String alFirst(String t) {
    return 'أول مرة $t';
  }

  @override
  String alLast(String t) {
    return 'آخر مرة $t';
  }

  @override
  String get alOpenItem => 'فتح';

  @override
  String get alReopen => 'إعادة فتح';

  @override
  String anDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا',
      one: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get anAttempts => 'المحاولات';

  @override
  String get anSuccesses => 'الناجحة';

  @override
  String get anRate => 'نسبة النجاح';

  @override
  String get anViews => 'المشاهدات (≥ 30 ث)';

  @override
  String get anHours => 'ساعات المشاهدة';

  @override
  String get anTtff50 => 'زمن البدء (الوسيط)';

  @override
  String get anTtff90 => 'زمن البدء (P90)';

  @override
  String get anExport => 'تصدير CSV (يفتحه Excel)';

  @override
  String get anNoData => 'لا بيانات بعد.';

  @override
  String get anHint =>
      'من أحداث تشغيل حقيقية فقط (لا من الفحص). النسبة تُعرض بعيّنة كافية، وزمن البدء عبر عدة أيام تقريبي.';

  @override
  String anDevices30(int n) {
    return '$n خلال 30 يومًا';
  }

  @override
  String get anTopChannels => 'الأكثر مشاهدة';

  @override
  String get anChannel => 'القناة';

  @override
  String get anWorstChannels => 'الأقل نجاحًا';

  @override
  String anMinSample(int n) {
    return 'القنوات التي لها $n محاولة على الأقل.';
  }

  @override
  String get anByHost => 'حسب الخادم (النطاق)';

  @override
  String get anHost => 'النطاق';

  @override
  String get anByPlatform => 'حسب المنصّة';

  @override
  String get anPlatform => 'المنصّة';

  @override
  String get anByCountry => 'حسب الدولة';

  @override
  String get anCountry => 'الدولة';

  @override
  String get anByDay => 'حسب اليوم';

  @override
  String get anDay => 'اليوم';

  @override
  String get anDevices => 'الأجهزة والإصدارات';

  @override
  String get anGroup => 'المجموعة';

  @override
  String get anValue => 'القيمة';

  @override
  String get anCount => 'العدد';

  @override
  String get anVersion => 'الإصدار';

  @override
  String get anLanguage => 'اللغة';

  @override
  String anDevicesLine(int a7, int a30) {
    return 'نشطة: $a7 خلال 7 أيام، $a30 خلال 30 يومًا';
  }

  @override
  String anReportsLine(int total, int open) {
    return '$total بلاغًا في الفترة، $open منها مفتوحة';
  }

  @override
  String get anReason => 'السبب';

  @override
  String get anActivity => 'نشاط المهام (استيراد، فحص، دليل، نسخ…)';

  @override
  String get anTask => 'المهمة';

  @override
  String get anOk => 'نجحت';

  @override
  String get anFailed => 'فشلت';

  @override
  String get copy => 'نسخ';

  @override
  String get pictureInPicture => 'صورة داخل صورة';

  @override
  String get favSyncTitle => 'مزامنة المفضلة';

  @override
  String get favSyncCreate => 'مزامنة المفضلة بين أجهزتك';

  @override
  String get favSyncCreateHint =>
      'دون حساب: يُنشأ رمز من 8 أحرف تدخله على جهازك الآخر.';

  @override
  String get favSyncCreateBtn => 'إنشاء رمز';

  @override
  String get favSyncJoin => 'ربط برمز من جهاز آخر';

  @override
  String get favSyncJoinShort => 'أدخل الرمز أو مفتاح التعديل.';

  @override
  String get favSyncJoinHint =>
      'الرمز وحده يجلب مفضلة الجهاز الآخر ويضيفها لمفضلتك. «مفتاح التعديل» (الرمز ثم - ثم السرّ) يجعل الجهازين يتشاركان قائمة واحدة يعدّلانها معًا.';

  @override
  String get favSyncLink => 'ربط';

  @override
  String get favSyncBadCode => 'الرمز غير صحيح';

  @override
  String get favSyncLinked => 'تم الربط وجُلبت المفضلة.';

  @override
  String get favSyncNotFound => 'لا توجد مفضلة بهذا الرمز.';

  @override
  String get favSyncFailed => 'تعذّرت المزامنة. حاول لاحقًا.';

  @override
  String get favSyncCode => 'الرمز';

  @override
  String get favSyncOwnerHint =>
      'يُرفع كل تغيير تلقائيًا. أعطِ الرمز لجهاز آخر ليجلب القائمة، أو «مفتاح التعديل» ليعدّلها أيضًا.';

  @override
  String get favSyncFollowerHint =>
      'يجلب هذا الجهاز القائمة عند كل تشغيل ويضيفها لمفضلته، ولا يعدّلها.';

  @override
  String get favSyncCopyKey => 'نسخ مفتاح التعديل';

  @override
  String get favSyncUnlink => 'فك الربط';

  @override
  String get favSyncUnlinkHint => 'تبقى مفضلتك على هذا الجهاز كما هي.';

  @override
  String get favSyncDeleteRemote => 'احذف القائمة المشتركة من الخادم أيضًا';

  @override
  String get anEmpty =>
      'لم تصل إحصاءات تشغيل بعد. تظهر بعد أن يشاهد المستخدمون بالإصدار الجديد ويُجمَّع اليوم.';

  @override
  String get epgAddSource => 'إضافة مصدر';

  @override
  String get epgSyncNow => 'زامن الآن';

  @override
  String epgSyncing(int done, int total, String name) {
    return 'جارٍ المزامنة $done/$total: $name';
  }

  @override
  String epgSummary(int c, int p) {
    return '$c قناة · $p برنامج';
  }

  @override
  String epgEvery(int h) {
    return 'كل $h ساعة';
  }

  @override
  String get epgGithubNote =>
      'grabber مشروع iptv-org ما زال يعمل على GitHub (يحتاج Node). مصادر XMLTV هذه تعمل من البرنامج؛ كل مصدر يُكمّل القنوات التي فاتت ما قبله.';

  @override
  String get epgSourceUrl => 'رابط XMLTV (‎.xml أو ‎.xml.gz)';

  @override
  String get epgPriority => 'الترتيب (الأصغر أولًا)';

  @override
  String get epgIntervalHours => 'كل (ساعات)';

  @override
  String mapMissing(int n) {
    return '$n قناة منشورة بلا برامج خلال 24 ساعة القادمة';
  }

  @override
  String get mapLoad => 'تحميل الاقتراحات من المصادر';

  @override
  String get mapLink => 'ربط';

  @override
  String mapLinkAll(int n) {
    return 'ربط كل المطابقات التامة ($n)';
  }

  @override
  String get mapNone => 'لا اقتراح';

  @override
  String get mapHint =>
      'الربط يضبط معرّف EPG للقناة (بالمعرّف لا بالاسم). تصل البرامج في المزامنة التالية.';

  @override
  String e3Issues(int g, int o) {
    return '$g فجوة · $o تداخل';
  }

  @override
  String get e3Offset => 'الإزاحة (دقائق)';

  @override
  String get e3OffsetHint =>
      'تُطبّق على البرامج التي يكتبها البرنامج من المزامنة التالية.';

  @override
  String e3Gap(int m) {
    return 'فجوة $m دقيقة';
  }

  @override
  String e3Overlap(int m) {
    return 'تداخل $m دقيقة';
  }

  @override
  String get rkGroupCategory => 'group-title ← الفئة';

  @override
  String get rkNameCountry => 'الاسم ← الدولة';

  @override
  String get rkNameLanguage => 'الاسم ← اللغة';

  @override
  String get rkNameCleanup => 'تنظيف الاسم';

  @override
  String get rkIdMap => 'tvg-id ← قناتنا';

  @override
  String get rPattern => 'يحتوي';

  @override
  String get rTarget => 'النتيجة';

  @override
  String get rRegex => 'تعبير نمطي';

  @override
  String get rNote => 'ملاحظة';

  @override
  String get rulesHint =>
      'القواعد تُطبّق على كل استيراد قبل المطابقة. القاعدة تملأ المجهول فقط ولا تستبدل تعديلاتك.';

  @override
  String get xtSave => 'حفظ هذا الحساب (كلمة المرور مشفّرة في Supabase Vault)';

  @override
  String get xtSaved => 'الحسابات المحفوظة';

  @override
  String get xtFetch => 'جلب ومراجعة';

  @override
  String get ioLoad => 'تحميل بيانات iptv-org';

  @override
  String get ioSearch => 'ابحث في قنوات iptv-org…';

  @override
  String get ioInCatalog => 'في الكتالوج';

  @override
  String get ioNotInCatalog => 'ليست في الكتالوج';

  @override
  String ioStreams(int n) {
    return '$n رابط';
  }

  @override
  String ioReview(int n) {
    return 'مراجعة المحدد في الاستيراد ($n)';
  }

  @override
  String get ioLicense =>
      'بيانات iptv-org (ملكية عامة). وجود رابط هناك ليس دليلًا على حق إعادة توزيعه؛ والقنوات الجديدة تمرّ بالمراجعة دائمًا.';

  @override
  String get acEmail => 'البريد';

  @override
  String get acMfa => 'التحقق بخطوتين';

  @override
  String get acAddFactor => 'إضافة تطبيق مصادقة احتياطي';

  @override
  String get acAddFactorHint =>
      'مستحسن: تطبيق مصادقة ثانٍ (هاتف آخر أو مدير كلمات مرور). إن فقدت أحدهما يعمل الآخر.';

  @override
  String get acChangePassword => 'تغيير كلمة المرور';

  @override
  String get acNewPassword => 'كلمة المرور الجديدة (10 أحرف على الأقل)';

  @override
  String get acSignOutAll => 'الخروج من كل الأجهزة';

  @override
  String get acSignOutAllConfirm => 'الخروج من كل مكان، ومنه هذا الجهاز؟';

  @override
  String get acRecovery =>
      'فقدت كل تطبيقات المصادقة؟ اتبع docs/runbooks/admin-recovery.md لاستعادة الوصول من لوحة Supabase.';

  @override
  String get shEnabled => 'تشغيل المهام المجدولة على هذا الجهاز';

  @override
  String get shTray => 'البقاء في منطقة الإشعارات عند إغلاق النافذة';

  @override
  String get shStartup => 'البدء مع ويندوز (مخفيًا)';

  @override
  String get shRunNow => 'شغّل الآن';

  @override
  String get shAnyTime => 'أي وقت';

  @override
  String get shAllowed => 'الساعات المسموحة';

  @override
  String shNext(String t) {
    return 'التالي $t';
  }

  @override
  String shMissed(String list) {
    return 'فاتت أثناء إطفاء الجهاز: $list';
  }

  @override
  String shRunning(String task) {
    return 'يعمل: $task';
  }

  @override
  String get shInterval => 'كل (دقائق)';

  @override
  String get shNote =>
      'الفحص الثقيل ينتظر أثناء مشاهدتك لقناة. كل مهمة تعمل على جهاز واحد فقط (قفل على الخادم). المهام الفائتة تُشغَّل عند فتح البرنامج.';

  @override
  String get auSearch => 'معرّف الصف…';

  @override
  String get auAllTables => 'كل الجداول';

  @override
  String get auAllActions => 'كل العمليات';

  @override
  String get auExport => 'تصدير CSV';

  @override
  String get bkFolder => 'مجلد النسخ';

  @override
  String get bkChooseFolder => 'اختر مجلدًا…';

  @override
  String get bkPassphrase => 'عبارة المرور (8 أحرف على الأقل)';

  @override
  String get bkPassphraseHint =>
      'لا تُرسل للخادم أبدًا. إن فقدتها لا يمكن فتح النسخ — احفظها في مدير كلمات مرور. نصيحة: اختر مجلدًا متزامنًا مع OneDrive أو Google Drive.';

  @override
  String get bkNow => 'نسخة الآن';

  @override
  String bkDone(String name) {
    return 'حُفظت النسخة: $name';
  }

  @override
  String get bkList => 'النسخ في المجلد';

  @override
  String get bkOpen => 'فتح ومعاينة';

  @override
  String get bkRestoreTables => 'استعادة الجداول المحددة';

  @override
  String get bkRestoreChannel => 'استعادة قناة واحدة';

  @override
  String bkCounts(int b, int c) {
    return 'النسخة $b · الآن $c';
  }

  @override
  String bkRestored(String s) {
    return 'استُعيد: $s';
  }

  @override
  String get bkNotConfigured => 'اختر المجلد وعبارة المرور أولًا.';

  @override
  String get bkRestoreNote =>
      'الاستعادة تضيف الصفوف أو تحدّثها فقط ولا تحذف أي بيانات أحدث. الاستبدال الكامل يُختبر على نسخة منفصلة، لا على الكتالوج الحي.';

  @override
  String get bkChannelId => 'معرّف القناة';

  @override
  String get mtStatus => 'حالة النظام';

  @override
  String mtDbLatency(int ms) {
    return 'زمن استجابة قاعدة البيانات: $ms ms';
  }

  @override
  String get mtEpgStale => 'لم يُزامَن الدليل منذ أكثر من 48 ساعة';

  @override
  String get mtBackupStale => 'لا نسخة احتياطية خلال 48 ساعة';

  @override
  String get mtCleanup => 'التنظيف';

  @override
  String get mtDanger => 'منطقة الخطر';

  @override
  String get mtDangerHint =>
      'كل عملية تأخذ نسخة احتياطية إلزامية أولًا، ثم تطلب كتابة كلمة التأكيد.';

  @override
  String mtTypeWord(String w) {
    return 'اكتب $w للتأكيد';
  }

  @override
  String get mtRefreshCounts => 'إعادة عدّ المصادر';

  @override
  String get mtClearReports => 'حذف البلاغات المحلولة';

  @override
  String get mtClearBrokenLogos => 'إزالة الشعارات المعطّلة';

  @override
  String get mtDeleteOffline => 'حذف الروابط غير المتاحة';

  @override
  String get mtDeleteHidden => 'حذف القنوات المخفية';

  @override
  String get mtDeletePending => 'حذف القنوات قيد المراجعة';

  @override
  String get g1Identity => 'التطبيق';

  @override
  String get g1AppNameAr => 'اسم التطبيق بالعربية';

  @override
  String get g1AppNameEn => 'اسم التطبيق بالإنجليزية';

  @override
  String get g1AboutAr => 'نص «حول» بالعربية';

  @override
  String get g1AboutEn => 'نص «حول» بالإنجليزية';

  @override
  String get g1CreditsAr => 'الاعتمادات بالعربية';

  @override
  String get g1CreditsEn => 'الاعتمادات بالإنجليزية';

  @override
  String get g1CompanyAr => 'اسم الشركة بالعربية';

  @override
  String get g1CompanyEn => 'اسم الشركة بالإنجليزية';

  @override
  String get g1Website => 'الموقع';

  @override
  String get g1Email => 'البريد';

  @override
  String get g1Legal => 'الصفحات القانونية';

  @override
  String get g1PrivacyAr => 'سياسة الخصوصية بالعربية';

  @override
  String get g1PrivacyEn => 'سياسة الخصوصية بالإنجليزية';

  @override
  String get g1PrivacyHint =>
      'فارغة = السياسة المدمجة المطابقة لما يجمعه التطبيق فعلًا (§20).';

  @override
  String get g1TermsAr => 'شروط الاستخدام بالعربية';

  @override
  String get g1TermsEn => 'شروط الاستخدام بالإنجليزية';

  @override
  String get g3Defaults => 'الافتراضي للأجهزة الجديدة';

  @override
  String get g3DefaultLang => 'اللغة الافتراضية';

  @override
  String get g3DefaultTheme => 'المظهر الافتراضي';

  @override
  String get g3ParentalCats => 'فئات مقفلة أبويًا افتراضيًا';

  @override
  String get g3Catalog => 'الكتالوج';

  @override
  String get g3RecentDays => '«المضافة حديثًا» تشمل (أيام)';

  @override
  String get g3AttentionDays => '«يحتاج انتباهك» بعد (أيام فشل متواصل)';

  @override
  String get g3AttentionHint =>
      'يرفع تنبيهًا لك فقط. لا شيء يُخفى أو يُحذف تلقائيًا (D-14).';

  @override
  String get g3EpgTz => 'المنطقة الزمنية المرجعية للدليل';

  @override
  String get g4Player => 'المشغّل';

  @override
  String get g4ConnectTimeout => 'مهلة الشبكة (ثوانٍ)';

  @override
  String get g4FirstFrame => 'انتظار أول صورة (ثوانٍ) قبل تبديل السيرفر';

  @override
  String get g4Stall => 'تجمّد قبل تبديل السيرفر (ثوانٍ)';

  @override
  String get g4Retries => 'جولات إضافية على كل السيرفرات';

  @override
  String get g4Buffer => 'التخزين المؤقت (ثوانٍ)';

  @override
  String get g4UserAgent => 'User-Agent الافتراضي (فارغ = افتراضي المشغّل)';

  @override
  String get g4Hwdec => 'فك الترميز بالعتاد';

  @override
  String get g4Probe => 'فحص الروابط (§12.3)';

  @override
  String get g4ProbeConnect => 'مهلة الاتصال (ثوانٍ)';

  @override
  String get g4ProbePlaylist => 'مهلة القائمة (ثوانٍ)';

  @override
  String get g4ProbeFrame => 'مهلة أول إطار (ثوانٍ)';

  @override
  String get g4PerHost => 'فحوص متزامنة لكل نطاق';

  @override
  String get g4Total => 'فحوص متزامنة إجمالًا';

  @override
  String get g4Ports => 'المنافذ المسموحة للجلب (مفصولة بفواصل)';

  @override
  String get g5Maintenance => 'الصيانة';

  @override
  String get g5MaintOn => 'وضع الصيانة';

  @override
  String get g5MaintHint =>
      'يرى المشاهدون الرسالة بدل التطبيق؛ والمدير يدخل عاديًا.';

  @override
  String get g5MsgAr => 'الرسالة بالعربية';

  @override
  String get g5MsgEn => 'الرسالة بالإنجليزية';

  @override
  String get g5Features => 'المزايا';

  @override
  String get g5FMini => 'المشغّل المصغّر';

  @override
  String get g5Refresh => 'فحص تحديثات الكتالوج كل (دقائق)';

  @override
  String get g5Telemetry => 'جمع إحصاءات تشغيل مجهولة';

  @override
  String get g5KillSwitch => 'إخفاء قناة فورًا من كل الأجهزة';

  @override
  String get g5KillHint =>
      'تختفي القناة من كل جهاز في مزامنته التالية دون تغيير الكتالوج. أزلها من هنا لإعادتها.';

  @override
  String get g2Handle => 'اسم المستخدم أو الرابط';

  @override
  String get g2OwnDeveloper => 'المطوّر';

  @override
  String get g2Footer => 'التذييل';

  @override
  String get g2Splash => 'شاشة البداية';

  @override
  String get g2Support => 'قنوات الدعم';

  @override
  String get followUs => 'تابعنا';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get contactSupport => 'تواصل مع الدعم مباشرة';

  @override
  String get g2SupportHint => 'تظهر في «الإبلاغ عن مشكلة».';

  @override
  String get g6MinSupported => 'الحد الأدنى المدعوم';

  @override
  String get g6MinHint => 'الإصدارات الأقدم تُجبر على التحديث.';

  @override
  String get g6Recommended => 'الإصدار الموصى به';

  @override
  String get g6RecHint => 'الإصدارات الأقدم ترى تنبيهًا بالتحديث.';

  @override
  String get g6Url => 'صفحة التنزيل';

  @override
  String get g6NotesAr => 'ملاحظات الإصدار بالعربية';

  @override
  String get g6NotesEn => 'ملاحظات الإصدار بالإنجليزية';

  @override
  String get g6Github => 'الأحدث على GitHub';

  @override
  String get f2Kind => 'النوع';

  @override
  String get f2Info => 'معلومة';

  @override
  String get f2Warning => 'تحذير';

  @override
  String get f2Style => 'يظهر كـ';

  @override
  String get f2Banner => 'شريط';

  @override
  String get f2Dialog => 'نافذة ترحيبية';

  @override
  String get f2BodyAr => 'النص بالعربية';

  @override
  String get f2BodyEn => 'النص بالإنجليزية';

  @override
  String get f2MinVersion => 'من الإصدار';

  @override
  String get f2MaxVersion => 'حتى الإصدار';

  @override
  String get f2Dismissible => 'يمكن للمشاهد إغلاقه';

  @override
  String get f2Empty => 'لا شيء بعد.';

  @override
  String get f1Compose => 'إشعار جديد';

  @override
  String get f1Link => 'يفتح داخل التطبيق (اختياري)';

  @override
  String get f1Image => 'رابط صورة (اختياري)';

  @override
  String get f1SendAt => 'جدولة (اختياري، YYYY-MM-DD HH:MM)';

  @override
  String get f1SendAtHint =>
      'فارغ = الآن. المجدول يصل لصندوق الوارد في موعده على كل المنصّات.';

  @override
  String get f1Push => 'إرسال Push لأجهزة Android الآن أيضًا';

  @override
  String get f1PushHint =>
      'عبر الدالة القائمة send-push (Firebase). ويندوز وماك يستلمونه في صندوق الوارد.';

  @override
  String get f1Sent => 'نُشر الإشعار';

  @override
  String get f1History => 'المُرسلة';

  @override
  String get f1CheckFcm => 'فحص إعداد Push';

  @override
  String get maintenanceTitle => 'تحت الصيانة';

  @override
  String get updateRequired => 'يلزم التحديث للمتابعة';

  @override
  String get updateRecommended => 'يتوفر إصدار أحدث';

  @override
  String get updateNow => 'حدّث الآن';

  @override
  String get later => 'لاحقًا';
}
