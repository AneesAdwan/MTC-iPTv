import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'MTC-iPTv'**
  String get appTitle;

  /// No description provided for @company.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة شركات مركز تكنولوجيا الشرق الأوسط — MTC-Group'**
  String get company;

  /// No description provided for @developedBy.
  ///
  /// In ar, this message translates to:
  /// **'برمجة وتطوير: أنيس عدوان'**
  String get developedBy;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {v}'**
  String version(String v);

  /// No description provided for @groupViewer.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدة'**
  String get groupViewer;

  /// No description provided for @groupAdmin.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get groupAdmin;

  /// No description provided for @groupA.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get groupA;

  /// No description provided for @groupB.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get groupB;

  /// No description provided for @groupC.
  ///
  /// In ar, this message translates to:
  /// **'الاستيراد والتحويل'**
  String get groupC;

  /// No description provided for @groupD.
  ///
  /// In ar, this message translates to:
  /// **'الجودة'**
  String get groupD;

  /// No description provided for @groupE.
  ///
  /// In ar, this message translates to:
  /// **'دليل البرامج'**
  String get groupE;

  /// No description provided for @groupF.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get groupF;

  /// No description provided for @groupG.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get groupG;

  /// No description provided for @groupH.
  ///
  /// In ar, this message translates to:
  /// **'الأمن والنظام'**
  String get groupH;

  /// No description provided for @groupI.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get groupI;

  /// No description provided for @sV01.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get sV01;

  /// No description provided for @sV02.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get sV02;

  /// No description provided for @sV03.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get sV03;

  /// No description provided for @sV04.
  ///
  /// In ar, this message translates to:
  /// **'الدول'**
  String get sV04;

  /// No description provided for @sV05.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get sV05;

  /// No description provided for @sV06.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدة'**
  String get sV06;

  /// No description provided for @sV07.
  ///
  /// In ar, this message translates to:
  /// **'دليل البرامج'**
  String get sV07;

  /// No description provided for @sV08.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get sV08;

  /// No description provided for @sV09.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get sV09;

  /// No description provided for @sV10.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get sV10;

  /// No description provided for @sV11.
  ///
  /// In ar, this message translates to:
  /// **'حول'**
  String get sV11;

  /// No description provided for @sV12.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن مشكلة'**
  String get sV12;

  /// No description provided for @sA1.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المعلومات'**
  String get sA1;

  /// No description provided for @sA2.
  ///
  /// In ar, this message translates to:
  /// **'المهام والطوابير'**
  String get sA2;

  /// No description provided for @sA3.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get sA3;

  /// No description provided for @sB1.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get sB1;

  /// No description provided for @sB2.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل القناة'**
  String get sB2;

  /// No description provided for @sB3.
  ///
  /// In ar, this message translates to:
  /// **'الروابط والسيرفرات'**
  String get sB3;

  /// No description provided for @sB4.
  ///
  /// In ar, this message translates to:
  /// **'العرض في الرئيسية'**
  String get sB4;

  /// No description provided for @sB5.
  ///
  /// In ar, this message translates to:
  /// **'التقسيمات'**
  String get sB5;

  /// No description provided for @sB6.
  ///
  /// In ar, this message translates to:
  /// **'الشبكات والشعارات'**
  String get sB6;

  /// No description provided for @sB7.
  ///
  /// In ar, this message translates to:
  /// **'الترقيم'**
  String get sB7;

  /// No description provided for @sC1.
  ///
  /// In ar, this message translates to:
  /// **'معالج الاستيراد'**
  String get sC1;

  /// No description provided for @sC2.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الاستيراد'**
  String get sC2;

  /// No description provided for @sC3.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get sC3;

  /// No description provided for @sC4.
  ///
  /// In ar, this message translates to:
  /// **'المراجع الخارجية'**
  String get sC4;

  /// No description provided for @sC5.
  ///
  /// In ar, this message translates to:
  /// **'التصدير'**
  String get sC5;

  /// No description provided for @sC6.
  ///
  /// In ar, this message translates to:
  /// **'قواعد التحويل'**
  String get sC6;

  /// No description provided for @sD1.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get sD1;

  /// No description provided for @sD2.
  ///
  /// In ar, this message translates to:
  /// **'المكررات والدمج'**
  String get sD2;

  /// No description provided for @sD3.
  ///
  /// In ar, this message translates to:
  /// **'المقارنة'**
  String get sD3;

  /// No description provided for @sD4.
  ///
  /// In ar, this message translates to:
  /// **'صحة البث'**
  String get sD4;

  /// No description provided for @sD5.
  ///
  /// In ar, this message translates to:
  /// **'الشعارات'**
  String get sD5;

  /// No description provided for @sD6.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات المشاهدين'**
  String get sD6;

  /// No description provided for @sE1.
  ///
  /// In ar, this message translates to:
  /// **'مصادر EPG'**
  String get sE1;

  /// No description provided for @sE2.
  ///
  /// In ar, this message translates to:
  /// **'ربط القنوات'**
  String get sE2;

  /// No description provided for @sE3.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الجدول'**
  String get sE3;

  /// No description provided for @sF1.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get sF1;

  /// No description provided for @sF2.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات والشرائط'**
  String get sF2;

  /// No description provided for @sG1.
  ///
  /// In ar, this message translates to:
  /// **'الهوية'**
  String get sG1;

  /// No description provided for @sG2.
  ///
  /// In ar, this message translates to:
  /// **'التواصل الاجتماعي'**
  String get sG2;

  /// No description provided for @sG3.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات العامة'**
  String get sG3;

  /// No description provided for @sG4.
  ///
  /// In ar, this message translates to:
  /// **'المشغّل والشبكة'**
  String get sG4;

  /// No description provided for @sG5.
  ///
  /// In ar, this message translates to:
  /// **'المزايا ووضع الصيانة'**
  String get sG5;

  /// No description provided for @sG6.
  ///
  /// In ar, this message translates to:
  /// **'الإصدارات والتحديث'**
  String get sG6;

  /// No description provided for @sH1.
  ///
  /// In ar, this message translates to:
  /// **'الحساب والأمان'**
  String get sH1;

  /// No description provided for @sH2.
  ///
  /// In ar, this message translates to:
  /// **'المهام المجدولة'**
  String get sH2;

  /// No description provided for @sH3.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get sH3;

  /// No description provided for @sH4.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get sH4;

  /// No description provided for @sH5.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة والتشخيص'**
  String get sH5;

  /// No description provided for @sI1.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات'**
  String get sI1;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث عام…'**
  String get searchHint;

  /// No description provided for @searchShortcut.
  ///
  /// In ar, this message translates to:
  /// **'Ctrl+K'**
  String get searchShortcut;

  /// No description provided for @paletteHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم شاشة أو أمر…'**
  String get paletteHint;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @collapse.
  ///
  /// In ar, this message translates to:
  /// **'طي القائمة'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In ar, this message translates to:
  /// **'توسيع القائمة'**
  String get expand;

  /// No description provided for @statusOnline.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get statusOffline;

  /// No description provided for @statusIdle.
  ///
  /// In ar, this message translates to:
  /// **'لا مهام جارية'**
  String get statusIdle;

  /// No description provided for @minimize.
  ///
  /// In ar, this message translates to:
  /// **'تصغير'**
  String get minimize;

  /// No description provided for @maximize.
  ///
  /// In ar, this message translates to:
  /// **'تكبير'**
  String get maximize;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get restore;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @placeholderTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيد البناء'**
  String get placeholderTitle;

  /// No description provided for @placeholderBody.
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة ({id}) تُبنى في المرحلة {phase} من الخطة.'**
  String placeholderBody(String id, String phase);

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get themeSystem;

  /// No description provided for @cmdToggleLanguage.
  ///
  /// In ar, this message translates to:
  /// **'تبديل اللغة'**
  String get cmdToggleLanguage;

  /// No description provided for @cmdToggleTheme.
  ///
  /// In ar, this message translates to:
  /// **'تبديل المظهر'**
  String get cmdToggleTheme;

  /// No description provided for @cmdToggleSidebar.
  ///
  /// In ar, this message translates to:
  /// **'طي/توسيع القائمة الجانبية'**
  String get cmdToggleSidebar;

  /// No description provided for @adminSignIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول المدير'**
  String get adminSignIn;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signedInAs.
  ///
  /// In ar, this message translates to:
  /// **'مسجّل باسم {email}'**
  String signedInAs(String email);

  /// No description provided for @mfaEnrollTitle.
  ///
  /// In ar, this message translates to:
  /// **'فعّل التحقق بخطوتين'**
  String get mfaEnrollTitle;

  /// No description provided for @mfaEnrollBody.
  ///
  /// In ar, this message translates to:
  /// **'امسح الرمز بتطبيق مصادقة (Google Authenticator أو Microsoft Authenticator أو غيرهما)، ثم أدخل الرمز المكوّن من 6 أرقام. احفظ المفتاح السري في مكان آمن: تحتاجه إن فقدت جوالك.'**
  String get mfaEnrollBody;

  /// No description provided for @mfaSecret.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح السري'**
  String get mfaSecret;

  /// No description provided for @mfaCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get mfaCodeTitle;

  /// No description provided for @mfaCodeBody.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة.'**
  String get mfaCodeBody;

  /// No description provided for @mfaCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get mfaCode;

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get verify;

  /// No description provided for @notAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب ليس المدير'**
  String get notAdminTitle;

  /// No description provided for @notAdminBody.
  ///
  /// In ar, this message translates to:
  /// **'مركز الإدارة متاح لحساب المدير فقط.'**
  String get notAdminBody;

  /// No description provided for @noBackendBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد خادم مُعدّ لهذه البيئة ({env}).'**
  String noBackendBody(String env);

  /// No description provided for @authFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الدخول: تحقّق من البريد وكلمة المرور.'**
  String get authFailed;

  /// No description provided for @codeFailed.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح أو انتهت صلاحيته.'**
  String get codeFailed;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ'**
  String get copied;

  /// No description provided for @featured.
  ///
  /// In ar, this message translates to:
  /// **'مميزة'**
  String get featured;

  /// No description provided for @recentlyAdded.
  ///
  /// In ar, this message translates to:
  /// **'مضافة حديثًا'**
  String get recentlyAdded;

  /// No description provided for @continueWatching.
  ///
  /// In ar, this message translates to:
  /// **'تابع المشاهدة'**
  String get continueWatching;

  /// No description provided for @allChannels.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get allChannels;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @catalogEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قنوات على الجهاز بعد.'**
  String get catalogEmpty;

  /// No description provided for @catalogEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'تُجلب القنوات تلقائيًا عند الاتصال بالإنترنت.'**
  String get catalogEmptyHint;

  /// No description provided for @syncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ مزامنة القنوات…'**
  String get syncing;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @country.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get country;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// No description provided for @channelsCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} قناة'**
  String channelsCount(int n);

  /// No description provided for @searchChannelsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم القناة أو رقمها…'**
  String get searchChannelsHint;

  /// No description provided for @noMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قنوات مطابقة.'**
  String get noMatches;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قنوات مفضلة بعد.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط ♥ في صفحة أي قناة لإضافتها هنا.'**
  String get favoritesEmptyHint;

  /// No description provided for @addFavorite.
  ///
  /// In ar, this message translates to:
  /// **'أضف للمفضلة'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In ar, this message translates to:
  /// **'أزل من المفضلة'**
  String get removeFavorite;

  /// No description provided for @serverOf.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر {i} من {n}'**
  String serverOf(int i, int n);

  /// No description provided for @switchingServer.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التبديل إلى سيرفر آخر…'**
  String get switchingServer;

  /// No description provided for @loadingStream.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get loadingStream;

  /// No description provided for @quality.
  ///
  /// In ar, this message translates to:
  /// **'الجودة'**
  String get quality;

  /// No description provided for @auto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get auto;

  /// No description provided for @audioTrack.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get audioTrack;

  /// No description provided for @subtitles.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة'**
  String get subtitles;

  /// No description provided for @off.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get off;

  /// No description provided for @nextChannel.
  ///
  /// In ar, this message translates to:
  /// **'القناة التالية'**
  String get nextChannel;

  /// No description provided for @prevChannel.
  ///
  /// In ar, this message translates to:
  /// **'القناة السابقة'**
  String get prevChannel;

  /// No description provided for @fullscreen.
  ///
  /// In ar, this message translates to:
  /// **'ملء الشاشة'**
  String get fullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء ملء الشاشة'**
  String get exitFullscreen;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'أعد المحاولة'**
  String get retry;

  /// No description provided for @tryNextServer.
  ///
  /// In ar, this message translates to:
  /// **'جرّب سيرفرًا آخر'**
  String get tryNextServer;

  /// No description provided for @mute.
  ///
  /// In ar, this message translates to:
  /// **'كتم'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكتم'**
  String get unmute;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @errAuthFailed.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر رفض الوصول (قد تكون القناة محمية أو تحتاج اشتراكًا).'**
  String get errAuthFailed;

  /// No description provided for @errUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'القناة غير متاحة حاليًا على هذا السيرفر.'**
  String get errUnavailable;

  /// No description provided for @errUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'صيغة هذا البث غير مدعومة.'**
  String get errUnsupported;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر لا يستجيب. تحقّق من اتصالك أو جرّب لاحقًا.'**
  String get errNetwork;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل القناة.'**
  String get errGeneric;

  /// No description provided for @allServersFailed.
  ///
  /// In ar, this message translates to:
  /// **'جُرّبت كل السيرفرات ({n}) دون نجاح.'**
  String allServersFailed(int n);

  /// No description provided for @noServers.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد روابط لهذه القناة.'**
  String get noServers;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @channelNumber.
  ///
  /// In ar, this message translates to:
  /// **'القناة {n}'**
  String channelNumber(int n);

  /// No description provided for @nowLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get nowLabel;

  /// No description provided for @nextLabel.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get nextLabel;

  /// No description provided for @jumpToNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get jumpToNow;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ar, this message translates to:
  /// **'غدًا'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @guideEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد دليل برامج بعد.'**
  String get guideEmpty;

  /// No description provided for @guideEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'يُجلب الدليل تلقائيًا عند الاتصال بالإنترنت.'**
  String get guideEmptyHint;

  /// No description provided for @remindMe.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني'**
  String get remindMe;

  /// No description provided for @cancelReminder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التذكير'**
  String get cancelReminder;

  /// No description provided for @reminderSet.
  ///
  /// In ar, this message translates to:
  /// **'سنذكّرك قبل بدايته بـ 5 دقائق.'**
  String get reminderSet;

  /// No description provided for @reminderRemoved.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي التذكير.'**
  String get reminderRemoved;

  /// No description provided for @reminderFired.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ قريبًا: {title}'**
  String reminderFired(String title);

  /// No description provided for @watchNow.
  ///
  /// In ar, this message translates to:
  /// **'شاهد'**
  String get watchNow;

  /// No description provided for @inboxEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات.'**
  String get inboxEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @clearAll.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get clearAll;

  /// No description provided for @kindReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير'**
  String get kindReminder;

  /// No description provided for @sectionGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get sectionGeneral;

  /// No description provided for @sectionPlayer.
  ///
  /// In ar, this message translates to:
  /// **'المشغّل'**
  String get sectionPlayer;

  /// No description provided for @sectionParental.
  ///
  /// In ar, this message translates to:
  /// **'الرقابة الأبوية'**
  String get sectionParental;

  /// No description provided for @sectionStorage.
  ///
  /// In ar, this message translates to:
  /// **'التخزين والمزامنة'**
  String get sectionStorage;

  /// No description provided for @sectionPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية'**
  String get sectionPrivacy;

  /// No description provided for @showNumbers.
  ///
  /// In ar, this message translates to:
  /// **'إظهار أرقام القنوات'**
  String get showNumbers;

  /// No description provided for @maxQuality.
  ///
  /// In ar, this message translates to:
  /// **'أعلى جودة تلقائية'**
  String get maxQuality;

  /// No description provided for @qualityNoLimit.
  ///
  /// In ar, this message translates to:
  /// **'بلا حد، حتى 1080p'**
  String get qualityNoLimit;

  /// No description provided for @parentalHint.
  ///
  /// In ar, this message translates to:
  /// **'رمز من 4 أرقام يقفل الفئات التي تختارها والقنوات المخصّصة للكبار.'**
  String get parentalHint;

  /// No description provided for @setPin.
  ///
  /// In ar, this message translates to:
  /// **'تعيين رمز'**
  String get setPin;

  /// No description provided for @removePin.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get removePin;

  /// No description provided for @enterPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز'**
  String get enterPin;

  /// No description provided for @newPin.
  ///
  /// In ar, this message translates to:
  /// **'رمز جديد من 4 أرقام'**
  String get newPin;

  /// No description provided for @pinWrong.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح'**
  String get pinWrong;

  /// No description provided for @lockedCategories.
  ///
  /// In ar, this message translates to:
  /// **'الفئات المقفلة'**
  String get lockedCategories;

  /// No description provided for @channelLocked.
  ///
  /// In ar, this message translates to:
  /// **'هذه القناة مقفلة بالرقابة الأبوية.'**
  String get channelLocked;

  /// No description provided for @unlock.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get unlock;

  /// No description provided for @lastSync.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {t}'**
  String lastSync(String t);

  /// No description provided for @never.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم بعد'**
  String get never;

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'زامن الآن'**
  String get syncNow;

  /// No description provided for @syncDone.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت المزامنة.'**
  String get syncDone;

  /// No description provided for @clearHistory.
  ///
  /// In ar, this message translates to:
  /// **'مسح سجل المشاهدة'**
  String get clearHistory;

  /// No description provided for @historyCleared.
  ///
  /// In ar, this message translates to:
  /// **'مُسح سجل المشاهدة.'**
  String get historyCleared;

  /// No description provided for @telemetry.
  ///
  /// In ar, this message translates to:
  /// **'إرسال إحصاءات تشغيل مجهولة'**
  String get telemetry;

  /// No description provided for @telemetryHint.
  ///
  /// In ar, this message translates to:
  /// **'تساعد في تحسين القنوات. لا تتضمن أي روابط أو حسابات أو بيانات شخصية.'**
  String get telemetryHint;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @checkUpdates.
  ///
  /// In ar, this message translates to:
  /// **'التحقق من التحديثات'**
  String get checkUpdates;

  /// No description provided for @upToDate.
  ///
  /// In ar, this message translates to:
  /// **'لديك أحدث إصدار.'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {v} متوفر.'**
  String updateAvailable(String v);

  /// No description provided for @download.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل'**
  String get download;

  /// No description provided for @updateCheckFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من التحديثات.'**
  String get updateCheckFailed;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @privacyText.
  ///
  /// In ar, this message translates to:
  /// **'لا يحتاج MTC-iPTv إلى حساب ولا يجمع بيانات شخصية. المفضلة والسجل والتذكيرات والإعدادات تبقى على جهازك. عند تفعيلها، تُرسل إحصاءات تشغيل مجهولة (نجاح أو فشل، زمن البدء، نوع الخطأ) دون روابط أو معرّفات لتحسين القنوات. بلاغات المشاكل تحتوي ما تكتبه فقط، مع التفاصيل التقنية إن اخترت إرفاقها.'**
  String get privacyText;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن مشكلة'**
  String get reportTitle;

  /// No description provided for @reportChannelHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح القناة ثم اضغط زر العلم في المشغّل للإبلاغ عن مشكلة فيها.'**
  String get reportChannelHint;

  /// No description provided for @reasonNotWorking.
  ///
  /// In ar, this message translates to:
  /// **'لا تعمل'**
  String get reasonNotWorking;

  /// No description provided for @reasonWrongInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات خاطئة'**
  String get reasonWrongInfo;

  /// No description provided for @reasonBadQuality.
  ///
  /// In ar, this message translates to:
  /// **'جودة سيئة'**
  String get reasonBadQuality;

  /// No description provided for @reasonOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get reasonOther;

  /// No description provided for @noteHint.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل (اختياري)'**
  String get noteHint;

  /// No description provided for @attachDiag.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق تفاصيل تقنية (الإصدار، النظام، نوع الخطأ — دون روابط)'**
  String get attachDiag;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @reportSent.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لك! أُرسل البلاغ.'**
  String get reportSent;

  /// No description provided for @reportFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الإرسال. تحقّق من اتصالك وأعد المحاولة.'**
  String get reportFailed;

  /// No description provided for @noChannelNumber.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قناة بالرقم {n}'**
  String noChannelNumber(int n);

  /// No description provided for @openPlayer.
  ///
  /// In ar, this message translates to:
  /// **'فتح المشغّل'**
  String get openPlayer;

  /// No description provided for @closePlayer.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق المشغّل'**
  String get closePlayer;

  /// No description provided for @psPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشورة'**
  String get psPublished;

  /// No description provided for @psPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get psPending;

  /// No description provided for @psHidden.
  ///
  /// In ar, this message translates to:
  /// **'مخفية'**
  String get psHidden;

  /// No description provided for @psDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get psDraft;

  /// No description provided for @psRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوضة'**
  String get psRejected;

  /// No description provided for @hsPlayable.
  ///
  /// In ar, this message translates to:
  /// **'قابل للتشغيل'**
  String get hsPlayable;

  /// No description provided for @hsReachable.
  ///
  /// In ar, this message translates to:
  /// **'قابل للوصول'**
  String get hsReachable;

  /// No description provided for @hsDegraded.
  ///
  /// In ar, this message translates to:
  /// **'متدهور'**
  String get hsDegraded;

  /// No description provided for @hsAuthFailed.
  ///
  /// In ar, this message translates to:
  /// **'مصادقة مرفوضة'**
  String get hsAuthFailed;

  /// No description provided for @hsUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'صيغة غير مدعومة'**
  String get hsUnsupported;

  /// No description provided for @hsNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ شبكة'**
  String get hsNetworkError;

  /// No description provided for @hsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get hsUnavailable;

  /// No description provided for @hsGeoRestricted.
  ///
  /// In ar, this message translates to:
  /// **'قيود وصول محتملة'**
  String get hsGeoRestricted;

  /// No description provided for @hsInconclusive.
  ///
  /// In ar, this message translates to:
  /// **'غير حاسم'**
  String get hsInconclusive;

  /// No description provided for @hsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get hsDisabled;

  /// No description provided for @kpiChannels.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get kpiChannels;

  /// No description provided for @kpiStreams.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get kpiStreams;

  /// No description provided for @kpiWorking.
  ///
  /// In ar, this message translates to:
  /// **'تعمل'**
  String get kpiWorking;

  /// No description provided for @kpiFailing.
  ///
  /// In ar, this message translates to:
  /// **'فاشلة'**
  String get kpiFailing;

  /// No description provided for @kpiUncertain.
  ///
  /// In ar, this message translates to:
  /// **'غير مثبتة'**
  String get kpiUncertain;

  /// No description provided for @kpiOpenReports.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات مفتوحة'**
  String get kpiOpenReports;

  /// No description provided for @kpiEpgCoverage.
  ///
  /// In ar, this message translates to:
  /// **'تغطية الدليل'**
  String get kpiEpgCoverage;

  /// No description provided for @kpiEpgHint.
  ///
  /// In ar, this message translates to:
  /// **'{n} من {total} منشورة لها برامج خلال 24 ساعة'**
  String kpiEpgHint(int n, int total);

  /// No description provided for @streamHealth.
  ///
  /// In ar, this message translates to:
  /// **'صحة الروابط'**
  String get streamHealth;

  /// No description provided for @recentChanges.
  ///
  /// In ar, this message translates to:
  /// **'آخر التغييرات'**
  String get recentChanges;

  /// No description provided for @noChanges.
  ///
  /// In ar, this message translates to:
  /// **'لا تغييرات مسجّلة بعد.'**
  String get noChanges;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @qaReviewPending.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة المعلّق'**
  String get qaReviewPending;

  /// No description provided for @qaCheckFailing.
  ///
  /// In ar, this message translates to:
  /// **'فحص الروابط الفاشلة'**
  String get qaCheckFailing;

  /// No description provided for @qaReports.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات المشاهدين'**
  String get qaReports;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @addChannel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قناة'**
  String get addChannel;

  /// No description provided for @searchAdminHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم أو الرقم أو المعرّف أو الشبكة…'**
  String get searchAdminHint;

  /// No description provided for @allStates.
  ///
  /// In ar, this message translates to:
  /// **'كل الحالات'**
  String get allStates;

  /// No description provided for @allCountries.
  ///
  /// In ar, this message translates to:
  /// **'كل الدول'**
  String get allCountries;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'كل الفئات'**
  String get allCategories;

  /// No description provided for @fFeatured.
  ///
  /// In ar, this message translates to:
  /// **'مميزة'**
  String get fFeatured;

  /// No description provided for @fNoLogo.
  ///
  /// In ar, this message translates to:
  /// **'بلا شعار'**
  String get fNoLogo;

  /// No description provided for @fManual.
  ///
  /// In ar, this message translates to:
  /// **'يدوية'**
  String get fManual;

  /// No description provided for @colNumber.
  ///
  /// In ar, this message translates to:
  /// **'#'**
  String get colNumber;

  /// No description provided for @colName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get colName;

  /// No description provided for @colCountry.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get colCountry;

  /// No description provided for @colCategory.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get colCategory;

  /// No description provided for @colStreams.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get colStreams;

  /// No description provided for @colState.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get colState;

  /// No description provided for @colUpdated.
  ///
  /// In ar, this message translates to:
  /// **'آخر تعديل'**
  String get colUpdated;

  /// No description provided for @pageOf.
  ///
  /// In ar, this message translates to:
  /// **'{from}–{to} من {total}'**
  String pageOf(int from, int to, int total);

  /// No description provided for @selected.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد {n}'**
  String selected(int n);

  /// No description provided for @aPublish.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get aPublish;

  /// No description provided for @aHide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get aHide;

  /// No description provided for @aFeature.
  ///
  /// In ar, this message translates to:
  /// **'تمييز'**
  String get aFeature;

  /// No description provided for @aUnfeature.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التمييز'**
  String get aUnfeature;

  /// No description provided for @aSetCategory.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الفئة'**
  String get aSetCategory;

  /// No description provided for @aSetCountry.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدولة'**
  String get aSetCountry;

  /// No description provided for @aCheckStreams.
  ///
  /// In ar, this message translates to:
  /// **'فحص الروابط'**
  String get aCheckStreams;

  /// No description provided for @aDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get aDelete;

  /// No description provided for @aDisable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get aDisable;

  /// No description provided for @aEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get aEnable;

  /// No description provided for @aTry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب الآن'**
  String get aTry;

  /// No description provided for @aCheck.
  ///
  /// In ar, this message translates to:
  /// **'فحص'**
  String get aCheck;

  /// No description provided for @aEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get aEdit;

  /// No description provided for @aResolve.
  ///
  /// In ar, this message translates to:
  /// **'تمّ الحل'**
  String get aResolve;

  /// No description provided for @aOpenChannel.
  ///
  /// In ar, this message translates to:
  /// **'فتح القناة'**
  String get aOpenChannel;

  /// No description provided for @aHideChannel.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء القناة'**
  String get aHideChannel;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف {n} عنصر نهائيًا؟ لا يمكن التراجع من هنا (سجل التغييرات يحتفظ بنسخة).'**
  String confirmDelete(int n);

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ.'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ: {e}'**
  String saveFailed(String e);

  /// No description provided for @tabInfo.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات'**
  String get tabInfo;

  /// No description provided for @tabStreams.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get tabStreams;

  /// No description provided for @tabGuide.
  ///
  /// In ar, this message translates to:
  /// **'دليل البرامج'**
  String get tabGuide;

  /// No description provided for @tabHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get tabHistory;

  /// No description provided for @fNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربية'**
  String get fNameAr;

  /// No description provided for @fNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزية'**
  String get fNameEn;

  /// No description provided for @fAltNames.
  ///
  /// In ar, this message translates to:
  /// **'أسماء بديلة (مفصولة بفواصل)'**
  String get fAltNames;

  /// No description provided for @fNumber.
  ///
  /// In ar, this message translates to:
  /// **'الرقم'**
  String get fNumber;

  /// No description provided for @fNetwork.
  ///
  /// In ar, this message translates to:
  /// **'الشبكة'**
  String get fNetwork;

  /// No description provided for @fLogoUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط الشعار'**
  String get fLogoUrl;

  /// No description provided for @fLanguage.
  ///
  /// In ar, this message translates to:
  /// **'رمز اللغة'**
  String get fLanguage;

  /// No description provided for @fQuality.
  ///
  /// In ar, this message translates to:
  /// **'الجودة'**
  String get fQuality;

  /// No description provided for @fDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get fDescription;

  /// No description provided for @fWebsite.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get fWebsite;

  /// No description provided for @fEpgId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف EPG (فارغ = uid)'**
  String get fEpgId;

  /// No description provided for @fEpgOffset.
  ///
  /// In ar, this message translates to:
  /// **'إزاحة الدليل (دقائق)'**
  String get fEpgOffset;

  /// No description provided for @fParental.
  ///
  /// In ar, this message translates to:
  /// **'للكبار (قفل أبوي)'**
  String get fParental;

  /// No description provided for @fPublishState.
  ///
  /// In ar, this message translates to:
  /// **'حالة النشر'**
  String get fPublishState;

  /// No description provided for @addStream.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رابط'**
  String get addStream;

  /// No description provided for @fUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط البث'**
  String get fUrl;

  /// No description provided for @fLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم السيرفر (اختياري)'**
  String get fLabel;

  /// No description provided for @fUserAgent.
  ///
  /// In ar, this message translates to:
  /// **'User-Agent (اختياري)'**
  String get fUserAgent;

  /// No description provided for @fReferrer.
  ///
  /// In ar, this message translates to:
  /// **'Referer (اختياري)'**
  String get fReferrer;

  /// No description provided for @dragToReorder.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لترتيب الأولوية: المشغّل يجرّب السيرفر الأعلى أولًا.'**
  String get dragToReorder;

  /// No description provided for @noStreamsAdmin.
  ///
  /// In ar, this message translates to:
  /// **'لا روابط لهذه القناة.'**
  String get noStreamsAdmin;

  /// No description provided for @lastChecked.
  ///
  /// In ar, this message translates to:
  /// **'فُحص {t}'**
  String lastChecked(String t);

  /// No description provided for @neverChecked.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفحص بعد'**
  String get neverChecked;

  /// No description provided for @checkRunning.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فحص {done} من {total}…'**
  String checkRunning(int done, int total);

  /// No description provided for @checkDone.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الفحص: {done} رابط.'**
  String checkDone(int done);

  /// No description provided for @checkOffline.
  ///
  /// In ar, this message translates to:
  /// **'توقف الفحص: لا إنترنت على هذا الجهاز، ولم يُسجَّل شيء.'**
  String get checkOffline;

  /// No description provided for @stop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stop;

  /// No description provided for @playCheck.
  ///
  /// In ar, this message translates to:
  /// **'فحص التشغيل (mpv)'**
  String get playCheck;

  /// No description provided for @playCheckHint.
  ///
  /// In ar, this message translates to:
  /// **'الطبقة 1 تثبت أن الخادم يستجيب؛ الطبقة 2 تثبت وصول إطار فيديو فعلي.'**
  String get playCheckHint;

  /// No description provided for @noStreamsInState.
  ///
  /// In ar, this message translates to:
  /// **'لا روابط بهذه الحالة.'**
  String get noStreamsInState;

  /// No description provided for @noOpenReports.
  ///
  /// In ar, this message translates to:
  /// **'لا بلاغات مفتوحة.'**
  String get noOpenReports;

  /// No description provided for @reportsCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} بلاغ'**
  String reportsCount(int n);

  /// No description provided for @epgPreviewHint.
  ///
  /// In ar, this message translates to:
  /// **'البرامج المحفوظة على هذا الجهاز لهذه القناة.'**
  String get epgPreviewHint;

  /// No description provided for @noEpgForChannel.
  ///
  /// In ar, this message translates to:
  /// **'لا برامج لهذه القناة.'**
  String get noEpgForChannel;

  /// No description provided for @notAvailableYet.
  ///
  /// In ar, this message translates to:
  /// **'تأتي مع المرحلة {p}.'**
  String notAvailableYet(int p);

  /// No description provided for @reasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'السبب: {r}'**
  String reasonLabel(String r);

  /// No description provided for @bkUnchecked.
  ///
  /// In ar, this message translates to:
  /// **'لم تُفحص'**
  String get bkUnchecked;

  /// No description provided for @bkReady.
  ///
  /// In ar, this message translates to:
  /// **'جاهزة للنشر'**
  String get bkReady;

  /// No description provided for @bkDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'مكررة'**
  String get bkDuplicate;

  /// No description provided for @bkOffline.
  ///
  /// In ar, this message translates to:
  /// **'لا تعمل'**
  String get bkOffline;

  /// No description provided for @bkLogo.
  ///
  /// In ar, this message translates to:
  /// **'شعار معطّل'**
  String get bkLogo;

  /// No description provided for @bkIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'ناقصة'**
  String get bkIncomplete;

  /// No description provided for @bkUncheckedHint.
  ///
  /// In ar, this message translates to:
  /// **'روابطها لم تُفحص بعد: افحص الدلو فتُصنَّف تلقائيًا.'**
  String get bkUncheckedHint;

  /// No description provided for @bkReadyHint.
  ///
  /// In ar, this message translates to:
  /// **'روابطها تعمل وغير مكررة. راجعها ثم وافق عليها.'**
  String get bkReadyHint;

  /// No description provided for @bkDuplicateHint.
  ///
  /// In ar, this message translates to:
  /// **'نفس قناة موجودة في الكتالوج: ادمجها (تصبح روابطها سيرفرات إضافية) أو علّمها «ليست مكررة».'**
  String get bkDuplicateHint;

  /// No description provided for @bkOfflineHint.
  ///
  /// In ar, this message translates to:
  /// **'لا رابط يعمل. ارفضها، أو انتظر فحصًا جديدًا.'**
  String get bkOfflineHint;

  /// No description provided for @bkLogoHint.
  ///
  /// In ar, this message translates to:
  /// **'الشعار لا يظهر. أصلحه قبل النشر.'**
  String get bkLogoHint;

  /// No description provided for @bkIncompleteHint.
  ///
  /// In ar, this message translates to:
  /// **'قنوات تعمل لكن بلا دولة. عدّلها قبل النشر.'**
  String get bkIncompleteHint;

  /// No description provided for @reviewEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء بانتظار المراجعة.'**
  String get reviewEmpty;

  /// No description provided for @aApprove.
  ///
  /// In ar, this message translates to:
  /// **'موافقة ونشر'**
  String get aApprove;

  /// No description provided for @aReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض (حذف)'**
  String get aReject;

  /// No description provided for @aMerge.
  ///
  /// In ar, this message translates to:
  /// **'دمج في الأصلية'**
  String get aMerge;

  /// No description provided for @aNotDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'ليست مكررة'**
  String get aNotDuplicate;

  /// No description provided for @aAllInBucket.
  ///
  /// In ar, this message translates to:
  /// **'كل الدلو ({n})'**
  String aAllInBucket(int n);

  /// No description provided for @originalOf.
  ///
  /// In ar, this message translates to:
  /// **'الأصلية: {name}'**
  String originalOf(String name);

  /// No description provided for @streamsWorking.
  ///
  /// In ar, this message translates to:
  /// **'{ok}/{n} تعمل'**
  String streamsWorking(int ok, int n);

  /// No description provided for @confirmReject.
  ///
  /// In ar, this message translates to:
  /// **'حذف {n} قناة معلّقة مع روابطها؟'**
  String confirmReject(int n);

  /// No description provided for @doneCount.
  ///
  /// In ar, this message translates to:
  /// **'تم: {n}.'**
  String doneCount(int n);

  /// No description provided for @numOrderBy.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب حسب'**
  String get numOrderBy;

  /// No description provided for @nkArab.
  ///
  /// In ar, this message translates to:
  /// **'الدول العربية أولًا'**
  String get nkArab;

  /// No description provided for @nkCountry.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get nkCountry;

  /// No description provided for @nkCategory.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get nkCategory;

  /// No description provided for @nkLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get nkLanguage;

  /// No description provided for @nkFeatured.
  ///
  /// In ar, this message translates to:
  /// **'المميزة أولًا'**
  String get nkFeatured;

  /// No description provided for @nkQuality.
  ///
  /// In ar, this message translates to:
  /// **'الجودة'**
  String get nkQuality;

  /// No description provided for @nkOnline.
  ///
  /// In ar, this message translates to:
  /// **'الروابط العاملة'**
  String get nkOnline;

  /// No description provided for @nkName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nkName;

  /// No description provided for @nkCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الرقم الحالي'**
  String get nkCurrent;

  /// No description provided for @nkNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get nkNewest;

  /// No description provided for @nkSortOrder.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الظهور'**
  String get nkSortOrder;

  /// No description provided for @numStart.
  ///
  /// In ar, this message translates to:
  /// **'أول رقم'**
  String get numStart;

  /// No description provided for @numBlock.
  ///
  /// In ar, this message translates to:
  /// **'حجم الكتلة لكل مجموعة (0 = متتالٍ)'**
  String get numBlock;

  /// No description provided for @numPublishedFirst.
  ///
  /// In ar, this message translates to:
  /// **'المنشورة أولًا'**
  String get numPublishedFirst;

  /// No description provided for @numPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get numPreview;

  /// No description provided for @numApply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get numApply;

  /// No description provided for @numSummary.
  ///
  /// In ar, this message translates to:
  /// **'{changed} من {total} قناة يتغير رقمها · آخر رقم {max}'**
  String numSummary(int changed, int total, int max);

  /// No description provided for @numConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ترقيم {n} قناة؟ يرى المشاهدون الأرقام الجديدة بعد مزامنتهم التالية.'**
  String numConfirm(int n);

  /// No description provided for @numApplied.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد ترقيم {n} قناة.'**
  String numApplied(int n);

  /// No description provided for @numHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر الترتيب، عاين، ثم طبّق. التغيير كله يتم دفعة واحدة على الخادم، ويبقى الرقم القديم لكل قناة في سجلها.'**
  String get numHint;

  /// No description provided for @tabCategories.
  ///
  /// In ar, this message translates to:
  /// **'الفئات'**
  String get tabCategories;

  /// No description provided for @tabCountries.
  ///
  /// In ar, this message translates to:
  /// **'الدول'**
  String get tabCountries;

  /// No description provided for @tabLanguages.
  ///
  /// In ar, this message translates to:
  /// **'اللغات'**
  String get tabLanguages;

  /// No description provided for @fSlug.
  ///
  /// In ar, this message translates to:
  /// **'المعرّف'**
  String get fSlug;

  /// No description provided for @fIcon.
  ///
  /// In ar, this message translates to:
  /// **'الأيقونة'**
  String get fIcon;

  /// No description provided for @fHue.
  ///
  /// In ar, this message translates to:
  /// **'اللون (0–360)'**
  String get fHue;

  /// No description provided for @fSort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get fSort;

  /// No description provided for @fVisible.
  ///
  /// In ar, this message translates to:
  /// **'ظاهرة'**
  String get fVisible;

  /// No description provided for @fFlag.
  ///
  /// In ar, this message translates to:
  /// **'العلم'**
  String get fFlag;

  /// No description provided for @fContinent.
  ///
  /// In ar, this message translates to:
  /// **'القارة'**
  String get fContinent;

  /// No description provided for @fArab.
  ///
  /// In ar, this message translates to:
  /// **'دولة عربية'**
  String get fArab;

  /// No description provided for @usedBy.
  ///
  /// In ar, this message translates to:
  /// **'{n} قناة'**
  String usedBy(int n);

  /// No description provided for @cannotDeleteUsed.
  ///
  /// In ar, this message translates to:
  /// **'مستخدمة في {n} قناة — انقلها أولًا.'**
  String cannotDeleteUsed(int n);

  /// No description provided for @addItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addItem;

  /// No description provided for @hostFilter.
  ///
  /// In ar, this message translates to:
  /// **'النطاق…'**
  String get hostFilter;

  /// No description provided for @allProtocols.
  ///
  /// In ar, this message translates to:
  /// **'كل البروتوكولات'**
  String get allProtocols;

  /// No description provided for @fCredentials.
  ///
  /// In ar, this message translates to:
  /// **'فيها بيانات اعتماد'**
  String get fCredentials;

  /// No description provided for @hostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'النطاقات'**
  String get hostsTitle;

  /// No description provided for @jobsRunning.
  ///
  /// In ar, this message translates to:
  /// **'يعمل الآن'**
  String get jobsRunning;

  /// No description provided for @jobsHistory.
  ///
  /// In ar, this message translates to:
  /// **'آخر التشغيلات'**
  String get jobsHistory;

  /// No description provided for @jobsScheduled.
  ///
  /// In ar, this message translates to:
  /// **'المهام المجدولة'**
  String get jobsScheduled;

  /// No description provided for @noRuns.
  ///
  /// In ar, this message translates to:
  /// **'لا تشغيلات مسجّلة بعد.'**
  String get noRuns;

  /// No description provided for @taskEvery.
  ///
  /// In ar, this message translates to:
  /// **'كل {m} دقيقة'**
  String taskEvery(int m);

  /// No description provided for @taskLast.
  ///
  /// In ar, this message translates to:
  /// **'آخر تشغيل {t}'**
  String taskLast(String t);

  /// No description provided for @tkHealthPublished.
  ///
  /// In ar, this message translates to:
  /// **'فحص روابط المنشورة'**
  String get tkHealthPublished;

  /// No description provided for @tkHealthAll.
  ///
  /// In ar, this message translates to:
  /// **'فحص كل الروابط'**
  String get tkHealthAll;

  /// No description provided for @tkPlaybackSample.
  ///
  /// In ar, this message translates to:
  /// **'عيّنة تشغيل'**
  String get tkPlaybackSample;

  /// No description provided for @tkLogos.
  ///
  /// In ar, this message translates to:
  /// **'فحص الشعارات'**
  String get tkLogos;

  /// No description provided for @tkEpg.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة دليل البرامج'**
  String get tkEpg;

  /// No description provided for @tkSources.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المصادر'**
  String get tkSources;

  /// No description provided for @tkBackup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get tkBackup;

  /// No description provided for @schedulerNote.
  ///
  /// In ar, this message translates to:
  /// **'المُجدوِل الذي يشغّلها تلقائيًا يأتي مع المرحلة 6 (ADM-H2). الفحوص اليدوية تُسجَّل هنا.'**
  String get schedulerNote;

  /// No description provided for @hlHero.
  ///
  /// In ar, this message translates to:
  /// **'يعرض الآن (الواجهة)'**
  String get hlHero;

  /// No description provided for @hlHeroHint.
  ///
  /// In ar, this message translates to:
  /// **'قناة أو أكثر تظهر كبيرة أعلى الرئيسية؛ إن كانت أكثر من واحدة تتناوب كل 8 ثوانٍ.'**
  String get hlHeroHint;

  /// No description provided for @hlRows.
  ///
  /// In ar, this message translates to:
  /// **'صفوف الرئيسية'**
  String get hlRows;

  /// No description provided for @hlAddRow.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صف'**
  String get hlAddRow;

  /// No description provided for @hlPublishHint.
  ///
  /// In ar, this message translates to:
  /// **'التغييرات المحفوظة تصل للمشاهدين في مزامنتهم التالية.'**
  String get hlPublishHint;

  /// No description provided for @hlReset.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الافتراضي'**
  String get hlReset;

  /// No description provided for @rtFeatured.
  ///
  /// In ar, this message translates to:
  /// **'المميزة'**
  String get rtFeatured;

  /// No description provided for @rtHistory.
  ///
  /// In ar, this message translates to:
  /// **'تابع المشاهدة (لكل مشاهد)'**
  String get rtHistory;

  /// No description provided for @rtFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة (لكل مشاهد)'**
  String get rtFavorites;

  /// No description provided for @rtRecent.
  ///
  /// In ar, this message translates to:
  /// **'المضافة حديثًا'**
  String get rtRecent;

  /// No description provided for @rtCategoriesAuto.
  ///
  /// In ar, this message translates to:
  /// **'صفوف الفئات (تلقائي)'**
  String get rtCategoriesAuto;

  /// No description provided for @rtCategory.
  ///
  /// In ar, this message translates to:
  /// **'فئة واحدة'**
  String get rtCategory;

  /// No description provided for @rtCountry.
  ///
  /// In ar, this message translates to:
  /// **'دولة واحدة'**
  String get rtCountry;

  /// No description provided for @rtManual.
  ///
  /// In ar, this message translates to:
  /// **'قنوات مختارة يدويًا'**
  String get rtManual;

  /// No description provided for @rtAll.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get rtAll;

  /// No description provided for @fTitleAr.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالعربية (اختياري)'**
  String get fTitleAr;

  /// No description provided for @fTitleEn.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالإنجليزية (اختياري)'**
  String get fTitleEn;

  /// No description provided for @fCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد القنوات في الصف'**
  String get fCount;

  /// No description provided for @fFrom.
  ///
  /// In ar, this message translates to:
  /// **'يظهر من'**
  String get fFrom;

  /// No description provided for @fTo.
  ///
  /// In ar, this message translates to:
  /// **'يظهر حتى'**
  String get fTo;

  /// No description provided for @addChannels.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قنوات'**
  String get addChannels;

  /// No description provided for @pickChannel.
  ///
  /// In ar, this message translates to:
  /// **'اختر قناة'**
  String get pickChannel;

  /// No description provided for @netChannels.
  ///
  /// In ar, this message translates to:
  /// **'{n} قناة'**
  String netChannels(int n);

  /// No description provided for @netRename.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تسمية'**
  String get netRename;

  /// No description provided for @netNewName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الجديد (فارغ = إزالة الشبكة)'**
  String get netNewName;

  /// No description provided for @logoLibraryLater.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الشعارات (الرفع للتخزين وأحجام WebP) تأتي مع إعداد التخزين في المرحلة 6.'**
  String get logoLibraryLater;

  /// No description provided for @dupGroups.
  ///
  /// In ar, this message translates to:
  /// **'{n} مجموعة مكررة'**
  String dupGroups(int n);

  /// No description provided for @noDuplicates.
  ///
  /// In ar, this message translates to:
  /// **'لا مكررات.'**
  String get noDuplicates;

  /// No description provided for @aCompare.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة'**
  String get aCompare;

  /// No description provided for @aHideOthers.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء البقية'**
  String get aHideOthers;

  /// No description provided for @aMergeHere.
  ///
  /// In ar, this message translates to:
  /// **'ادمج فيها'**
  String get aMergeHere;

  /// No description provided for @mergeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدمج في: {name}'**
  String mergeTitle(String name);

  /// No description provided for @mergePreview.
  ///
  /// In ar, this message translates to:
  /// **'{s} رابط ينتقل إليها · {c} قناة تُخفى (لا تُحذف)'**
  String mergePreview(int s, int c);

  /// No description provided for @mergeFieldsHint.
  ///
  /// In ar, this message translates to:
  /// **'الحقول المختلفة: اختر القيمة التي تبقى.'**
  String get mergeFieldsHint;

  /// No description provided for @mergeUndoHint.
  ///
  /// In ar, this message translates to:
  /// **'القنوات المدموجة تبقى مخفية مع إشارة لهذه القناة، ويمكن التراجع عن الدمج من صفحتها.'**
  String get mergeUndoHint;

  /// No description provided for @mergedHere.
  ///
  /// In ar, this message translates to:
  /// **'قنوات مدموجة في هذه القناة'**
  String get mergedHere;

  /// No description provided for @aUnmerge.
  ///
  /// In ar, this message translates to:
  /// **'تراجع عن الدمج'**
  String get aUnmerge;

  /// No description provided for @compareHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر 2–4 قنوات من «المكررات» أو «القنوات» لمقارنتها هنا.'**
  String get compareHint;

  /// No description provided for @playSideBySide.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل جنبًا إلى جنب'**
  String get playSideBySide;

  /// No description provided for @diffOnly.
  ///
  /// In ar, this message translates to:
  /// **'الاختلافات فقط'**
  String get diffOnly;

  /// No description provided for @compareMoreLater.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة المصادر واللقطات تأتي مع الاستيراد (المرحلة 5).'**
  String get compareMoreLater;

  /// No description provided for @lgBroken.
  ///
  /// In ar, this message translates to:
  /// **'معطّلة'**
  String get lgBroken;

  /// No description provided for @lgMissing.
  ///
  /// In ar, this message translates to:
  /// **'بلا شعار'**
  String get lgMissing;

  /// No description provided for @lgUnchecked.
  ///
  /// In ar, this message translates to:
  /// **'لم تُفحص'**
  String get lgUnchecked;

  /// No description provided for @lgOk.
  ///
  /// In ar, this message translates to:
  /// **'تعمل'**
  String get lgOk;

  /// No description provided for @checkLogos.
  ///
  /// In ar, this message translates to:
  /// **'فحص الشعارات'**
  String get checkLogos;

  /// No description provided for @logoChecking.
  ///
  /// In ar, this message translates to:
  /// **'فحص الشعارات {done}/{total}…'**
  String logoChecking(int done, int total);

  /// No description provided for @logoMoreLater.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات الشعارات من iptv-org ونسخها للتخزين تأتي مع المرحلتين 5 و6.'**
  String get logoMoreLater;

  /// No description provided for @setLogo.
  ///
  /// In ar, this message translates to:
  /// **'تعيين الشعار'**
  String get setLogo;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return L10nAr();
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
