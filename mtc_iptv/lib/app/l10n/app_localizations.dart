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

  /// No description provided for @plErrHint.
  ///
  /// In ar, this message translates to:
  /// **'قد يكون البث متوقفًا مؤقتًا أو محجوبًا في منطقتك. جرّب لاحقًا أو اختر قناة أخرى.'**
  String get plErrHint;

  /// No description provided for @plLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get plLive;

  /// No description provided for @plChannels.
  ///
  /// In ar, this message translates to:
  /// **'قائمة القنوات'**
  String get plChannels;

  /// No description provided for @plSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get plSettings;

  /// No description provided for @plServer.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر'**
  String get plServer;

  /// No description provided for @plOtherServer.
  ///
  /// In ar, this message translates to:
  /// **'سيرفر آخر'**
  String get plOtherServer;

  /// No description provided for @plCantPlay.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل القناة'**
  String get plCantPlay;

  /// No description provided for @plStats.
  ///
  /// In ar, this message translates to:
  /// **'معلومات البث'**
  String get plStats;

  /// No description provided for @plShortcuts.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات لوحة المفاتيح'**
  String get plShortcuts;

  /// No description provided for @plVolume.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الصوت'**
  String get plVolume;

  /// No description provided for @plSameCategory.
  ///
  /// In ar, this message translates to:
  /// **'نفس الفئة'**
  String get plSameCategory;

  /// No description provided for @plSameCountry.
  ///
  /// In ar, this message translates to:
  /// **'نفس الدولة'**
  String get plSameCountry;

  /// No description provided for @plResolution.
  ///
  /// In ar, this message translates to:
  /// **'الدقة'**
  String get plResolution;

  /// No description provided for @plCodec.
  ///
  /// In ar, this message translates to:
  /// **'الترميز'**
  String get plCodec;

  /// No description provided for @plDecoder.
  ///
  /// In ar, this message translates to:
  /// **'فك الترميز'**
  String get plDecoder;

  /// No description provided for @plBuffer.
  ///
  /// In ar, this message translates to:
  /// **'المخزن المؤقت'**
  String get plBuffer;

  /// No description provided for @plKeyPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل / إيقاف'**
  String get plKeyPlay;

  /// No description provided for @plKeyChannel.
  ///
  /// In ar, this message translates to:
  /// **'القناة السابقة / التالية'**
  String get plKeyChannel;

  /// No description provided for @plKeyVolume.
  ///
  /// In ar, this message translates to:
  /// **'رفع / خفض الصوت'**
  String get plKeyVolume;

  /// No description provided for @plKeyDigits.
  ///
  /// In ar, this message translates to:
  /// **'إدخال رقم قناة'**
  String get plKeyDigits;

  /// No description provided for @plKeyServer.
  ///
  /// In ar, this message translates to:
  /// **'سيرفر آخر'**
  String get plKeyServer;

  /// No description provided for @plKeyHelp.
  ///
  /// In ar, this message translates to:
  /// **'عرض الاختصارات'**
  String get plKeyHelp;

  /// No description provided for @plNotWorking.
  ///
  /// In ar, this message translates to:
  /// **'لا يعمل'**
  String get plNotWorking;

  /// No description provided for @plChannelsHint.
  ///
  /// In ar, this message translates to:
  /// **'↑ ↓ للتنقل · Enter للتشغيل · G للإغلاق'**
  String get plChannelsHint;

  /// No description provided for @accountMenu.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get accountMenu;

  /// No description provided for @signOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من حساب المدير على هذا الجهاز؟'**
  String get signOutConfirm;

  /// No description provided for @adminPanel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminPanel;

  /// No description provided for @notSignedIn.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجّل الدخول'**
  String get notSignedIn;

  /// No description provided for @numPad.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الأرقام'**
  String get numPad;

  /// No description provided for @numPadHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم القناة'**
  String get numPadHint;

  /// No description provided for @numPadGo.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get numPadGo;

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
  /// **'لا يحتاج MTC-iPTv إلى حساب، ولا يجمع اسمك أو بريدك أو عنوان IP أو موقعك الدقيق أو أي معرّف إعلاني. المفضلة والسجل والتذكيرات والإعدادات تبقى على جهازك.\n\nعند تفعيل الإحصاءات يُرسل التطبيق لكل محاولة تشغيل: السيرفر المستخدم (لا رابطه)، النجاح أو الفشل ونوع الخطأ، زمن البدء، مدة المشاهدة (مقرّبة) والدقة — مع معرّف عشوائي للجهاز والمنصّة والإصدار ولغة التطبيق والدولة التقريبية. تُحفظ الأحداث 30 يومًا ثم تبقى مجاميع يومية فقط بلا معرّفات أجهزة، ويُحذف سجل الجهاز بعد 90 يومًا من آخر ظهور. يمكنك إيقاف الإحصاءات أو إعادة تعيين معرّف الجهاز (فيُحذف السابق) من الإعدادات.\n\nبلاغات المشاكل تحتوي ما تكتبه فقط، مع التفاصيل التقنية إن اخترت إرفاقها.'**
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

  /// No description provided for @imFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get imFile;

  /// No description provided for @imUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط'**
  String get imUrl;

  /// No description provided for @imPaste.
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get imPaste;

  /// No description provided for @imXtream.
  ///
  /// In ar, this message translates to:
  /// **'حساب Xtream'**
  String get imXtream;

  /// No description provided for @imChooseFiles.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفًا…'**
  String get imChooseFiles;

  /// No description provided for @imPasteHint.
  ///
  /// In ar, this message translates to:
  /// **'الصق M3U أو CSV أو JSON أو روابط (رابط في كل سطر)…'**
  String get imPasteHint;

  /// No description provided for @imAnalyze.
  ///
  /// In ar, this message translates to:
  /// **'تحليل'**
  String get imAnalyze;

  /// No description provided for @imXServer.
  ///
  /// In ar, this message translates to:
  /// **'الخادم (http://host:port)'**
  String get imXServer;

  /// No description provided for @imXUser.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get imXUser;

  /// No description provided for @imXPass.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get imXPass;

  /// No description provided for @imXtreamNote.
  ///
  /// In ar, this message translates to:
  /// **'يُستخدم الحساب مرة واحدة لهذا الاستيراد ولا يُحفظ.'**
  String get imXtreamNote;

  /// No description provided for @imAnalyzing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحليل…'**
  String get imAnalyzing;

  /// No description provided for @imFormat.
  ///
  /// In ar, this message translates to:
  /// **'الصيغة {f} · الترميز {e}'**
  String imFormat(String f, String e);

  /// No description provided for @imIssues.
  ///
  /// In ar, this message translates to:
  /// **'أسطر لم تُقرأ ({n})'**
  String imIssues(int n);

  /// No description provided for @kNew.
  ///
  /// In ar, this message translates to:
  /// **'قنوات جديدة'**
  String get kNew;

  /// No description provided for @kUpdate.
  ///
  /// In ar, this message translates to:
  /// **'إضافة لقناة موجودة'**
  String get kUpdate;

  /// No description provided for @kExisting.
  ///
  /// In ar, this message translates to:
  /// **'موجودة في الكتالوج'**
  String get kExisting;

  /// No description provided for @kInFile.
  ///
  /// In ar, this message translates to:
  /// **'مكررة في الملف'**
  String get kInFile;

  /// No description provided for @kFailed.
  ///
  /// In ar, this message translates to:
  /// **'غير مدعومة'**
  String get kFailed;

  /// No description provided for @imCommit.
  ///
  /// In ar, this message translates to:
  /// **'استيراد المحدد ({n})'**
  String imCommit(int n);

  /// No description provided for @imCommitHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يُكتب شيء قبل الاستيراد. القنوات الجديدة تذهب لقيد المراجعة؛ والموجودة يُضاف لها الرابط الجديد فقط (تعديلاتك تبقى كما هي).'**
  String get imCommitHint;

  /// No description provided for @imDone.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الاستيراد'**
  String get imDone;

  /// No description provided for @imResult.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت {channels} قناة و{streams} رابط · عُطّل {disabled} رابط'**
  String imResult(int channels, int streams, int disabled);

  /// No description provided for @imGoReview.
  ///
  /// In ar, this message translates to:
  /// **'فتح قيد المراجعة'**
  String get imGoReview;

  /// No description provided for @imNew.
  ///
  /// In ar, this message translates to:
  /// **'استيراد جديد'**
  String get imNew;

  /// No description provided for @imVanished.
  ///
  /// In ar, this message translates to:
  /// **'{n} رابط من هذا المصدر لم يعد موجودًا فيه'**
  String imVanished(int n);

  /// No description provided for @imDisableVanished.
  ///
  /// In ar, this message translates to:
  /// **'تعطيلها (لا حذف)'**
  String get imDisableVanished;

  /// No description provided for @imPossibleDup.
  ///
  /// In ar, this message translates to:
  /// **'مكررة محتملة'**
  String get imPossibleDup;

  /// No description provided for @imAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get imAll;

  /// No description provided for @imNone.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get imNone;

  /// No description provided for @srcAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصدر'**
  String get srcAdd;

  /// No description provided for @srcName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get srcName;

  /// No description provided for @srcUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط القائمة (https)'**
  String get srcUrl;

  /// No description provided for @srcRefresh.
  ///
  /// In ar, this message translates to:
  /// **'جلب ومراجعة'**
  String get srcRefresh;

  /// No description provided for @srcLast.
  ///
  /// In ar, this message translates to:
  /// **'آخر استيراد {t}'**
  String srcLast(String t);

  /// No description provided for @srcCounts.
  ///
  /// In ar, this message translates to:
  /// **'{c} قناة · {s} رابط'**
  String srcCounts(int c, int s);

  /// No description provided for @srcRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة المصدر'**
  String get srcRemove;

  /// No description provided for @srcRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إزالة هذا المصدر؟ روابطه وقنواته تبقى في الكتالوج.'**
  String get srcRemoveConfirm;

  /// No description provided for @srcActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get srcActive;

  /// No description provided for @srcScheduleLater.
  ///
  /// In ar, this message translates to:
  /// **'التحديث التلقائي المجدول يأتي مع المُجدوِل (المرحلة 6). الآن: «جلب ومراجعة».'**
  String get srcScheduleLater;

  /// No description provided for @srcEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا مصادر بعد.'**
  String get srcEmpty;

  /// No description provided for @exFormat.
  ///
  /// In ar, this message translates to:
  /// **'الصيغة'**
  String get exFormat;

  /// No description provided for @exWorkingOnly.
  ///
  /// In ar, this message translates to:
  /// **'الروابط العاملة فقط'**
  String get exWorkingOnly;

  /// No description provided for @exBestOnly.
  ///
  /// In ar, this message translates to:
  /// **'أفضل رابط فقط'**
  String get exBestOnly;

  /// No description provided for @exSkipCreds.
  ///
  /// In ar, this message translates to:
  /// **'استبعاد الروابط ذات بيانات الاعتماد'**
  String get exSkipCreds;

  /// No description provided for @exExport.
  ///
  /// In ar, this message translates to:
  /// **'تصدير…'**
  String get exExport;

  /// No description provided for @exDone.
  ///
  /// In ar, this message translates to:
  /// **'صُدّرت {n} قناة.'**
  String exDone(int n);

  /// No description provided for @exChannels.
  ///
  /// In ar, this message translates to:
  /// **'{n} قناة مطابقة'**
  String exChannels(int n);

  /// No description provided for @needsMigration.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج هذا ترحيلًا على الخادم لم يُطبَّق بعد.'**
  String get needsMigration;

  /// No description provided for @resetInstallId.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين معرّف الجهاز'**
  String get resetInstallId;

  /// No description provided for @resetInstallIdHint.
  ///
  /// In ar, this message translates to:
  /// **'يولّد معرّفًا عشوائيًا جديدًا ويحذف السابق وإحصاءاته من الخادم.'**
  String get resetInstallIdHint;

  /// No description provided for @resetInstallIdDone.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء معرّف جديد للجهاز'**
  String get resetInstallIdDone;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get reset;

  /// No description provided for @kpiSuccess24h.
  ///
  /// In ar, this message translates to:
  /// **'نجاح التشغيل (24 ساعة)'**
  String get kpiSuccess24h;

  /// No description provided for @kpiSampleLow.
  ///
  /// In ar, this message translates to:
  /// **'العيّنة غير كافية ({n} محاولة)'**
  String kpiSampleLow(int n);

  /// No description provided for @kpiAttempts.
  ///
  /// In ar, this message translates to:
  /// **'{n} محاولة'**
  String kpiAttempts(int n);

  /// No description provided for @kpiDevices7.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة النشطة (7 أيام)'**
  String get kpiDevices7;

  /// No description provided for @tkTelemetryRollup.
  ///
  /// In ar, this message translates to:
  /// **'تجميع إحصاءات التشغيل'**
  String get tkTelemetryRollup;

  /// No description provided for @tkAlerts.
  ///
  /// In ar, this message translates to:
  /// **'فحص التنبيهات'**
  String get tkAlerts;

  /// No description provided for @alEpgFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث الدليل'**
  String get alEpgFailed;

  /// No description provided for @alEpgStale.
  ///
  /// In ar, this message translates to:
  /// **'الدليل لم يتحدّث منذ 48 ساعة'**
  String get alEpgStale;

  /// No description provided for @alSourceFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعطّل مصدر'**
  String get alSourceFailed;

  /// No description provided for @alImportFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاستيراد'**
  String get alImportFailed;

  /// No description provided for @alSuccessDrop.
  ///
  /// In ar, this message translates to:
  /// **'انخفاض نسبة نجاح التشغيل'**
  String get alSuccessDrop;

  /// No description provided for @alBackupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت النسخة الاحتياطية'**
  String get alBackupFailed;

  /// No description provided for @alBackupStale.
  ///
  /// In ar, this message translates to:
  /// **'لا نسخة احتياطية منذ 48 ساعة'**
  String get alBackupStale;

  /// No description provided for @alRepeatedReports.
  ///
  /// In ar, this message translates to:
  /// **'بلاغات متكررة'**
  String get alRepeatedReports;

  /// No description provided for @alConnectorStopped.
  ///
  /// In ar, this message translates to:
  /// **'توقف موصل تلقائيًا'**
  String get alConnectorStopped;

  /// No description provided for @alTaskFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت مهمة مجدولة'**
  String get alTaskFailed;

  /// No description provided for @alSuccessDetail.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الأمس {rate} (الأسبوع السابق {prev}) من {attempts} محاولة'**
  String alSuccessDetail(String rate, String prev, String attempts);

  /// No description provided for @alReportsDetail.
  ///
  /// In ar, this message translates to:
  /// **'{name}: {count} بلاغات مفتوحة خلال 24 ساعة'**
  String alReportsDetail(String name, String count);

  /// No description provided for @alAlreadyOpen.
  ///
  /// In ar, this message translates to:
  /// **'يوجد تنبيه مفتوح للحالة نفسها.'**
  String get alAlreadyOpen;

  /// No description provided for @alOpen.
  ///
  /// In ar, this message translates to:
  /// **'المفتوحة'**
  String get alOpen;

  /// No description provided for @alNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get alNew;

  /// No description provided for @alSeen.
  ///
  /// In ar, this message translates to:
  /// **'تمّت رؤيته'**
  String get alSeen;

  /// No description provided for @alResolved.
  ///
  /// In ar, this message translates to:
  /// **'تمّ الحل'**
  String get alResolved;

  /// No description provided for @alAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get alAll;

  /// No description provided for @alScanNow.
  ///
  /// In ar, this message translates to:
  /// **'افحص الآن'**
  String get alScanNow;

  /// No description provided for @alMarkAllSeen.
  ///
  /// In ar, this message translates to:
  /// **'تمّت رؤية الكل'**
  String get alMarkAllSeen;

  /// No description provided for @alHint.
  ///
  /// In ar, this message translates to:
  /// **'يفحص المُجدوِل الشروط كل ساعة. تبقى المشكلة تنبيهًا واحدًا يزداد عدد تكراره، ولا يُحل إلا بقرارك.'**
  String get alHint;

  /// No description provided for @alNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تنبيهات.'**
  String get alNone;

  /// No description provided for @alTimes.
  ///
  /// In ar, this message translates to:
  /// **'{n} مرات'**
  String alTimes(int n);

  /// No description provided for @alFirst.
  ///
  /// In ar, this message translates to:
  /// **'أول مرة {t}'**
  String alFirst(String t);

  /// No description provided for @alLast.
  ///
  /// In ar, this message translates to:
  /// **'آخر مرة {t}'**
  String alLast(String t);

  /// No description provided for @alOpenItem.
  ///
  /// In ar, this message translates to:
  /// **'فتح'**
  String get alOpenItem;

  /// No description provided for @alReopen.
  ///
  /// In ar, this message translates to:
  /// **'إعادة فتح'**
  String get alReopen;

  /// No description provided for @anDays.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =1{اليوم} other{{n} يومًا}}'**
  String anDays(int n);

  /// No description provided for @anAttempts.
  ///
  /// In ar, this message translates to:
  /// **'المحاولات'**
  String get anAttempts;

  /// No description provided for @anSuccesses.
  ///
  /// In ar, this message translates to:
  /// **'الناجحة'**
  String get anSuccesses;

  /// No description provided for @anRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة النجاح'**
  String get anRate;

  /// No description provided for @anViews.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدات (≥ 30 ث)'**
  String get anViews;

  /// No description provided for @anHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات المشاهدة'**
  String get anHours;

  /// No description provided for @anTtff50.
  ///
  /// In ar, this message translates to:
  /// **'زمن البدء (الوسيط)'**
  String get anTtff50;

  /// No description provided for @anTtff90.
  ///
  /// In ar, this message translates to:
  /// **'زمن البدء (P90)'**
  String get anTtff90;

  /// No description provided for @anExport.
  ///
  /// In ar, this message translates to:
  /// **'تصدير CSV (يفتحه Excel)'**
  String get anExport;

  /// No description provided for @anNoData.
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات بعد.'**
  String get anNoData;

  /// No description provided for @anHint.
  ///
  /// In ar, this message translates to:
  /// **'من أحداث تشغيل حقيقية فقط (لا من الفحص). النسبة تُعرض بعيّنة كافية، وزمن البدء عبر عدة أيام تقريبي.'**
  String get anHint;

  /// No description provided for @anDevices30.
  ///
  /// In ar, this message translates to:
  /// **'{n} خلال 30 يومًا'**
  String anDevices30(int n);

  /// No description provided for @anTopChannels.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مشاهدة'**
  String get anTopChannels;

  /// No description provided for @anChannel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get anChannel;

  /// No description provided for @anWorstChannels.
  ///
  /// In ar, this message translates to:
  /// **'الأقل نجاحًا'**
  String get anWorstChannels;

  /// No description provided for @anMinSample.
  ///
  /// In ar, this message translates to:
  /// **'القنوات التي لها {n} محاولة على الأقل.'**
  String anMinSample(int n);

  /// No description provided for @anByHost.
  ///
  /// In ar, this message translates to:
  /// **'حسب الخادم (النطاق)'**
  String get anByHost;

  /// No description provided for @anHost.
  ///
  /// In ar, this message translates to:
  /// **'النطاق'**
  String get anHost;

  /// No description provided for @anByPlatform.
  ///
  /// In ar, this message translates to:
  /// **'حسب المنصّة'**
  String get anByPlatform;

  /// No description provided for @anPlatform.
  ///
  /// In ar, this message translates to:
  /// **'المنصّة'**
  String get anPlatform;

  /// No description provided for @anByCountry.
  ///
  /// In ar, this message translates to:
  /// **'حسب الدولة'**
  String get anByCountry;

  /// No description provided for @anCountry.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get anCountry;

  /// No description provided for @anByDay.
  ///
  /// In ar, this message translates to:
  /// **'حسب اليوم'**
  String get anByDay;

  /// No description provided for @anDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get anDay;

  /// No description provided for @anDevices.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة والإصدارات'**
  String get anDevices;

  /// No description provided for @anGroup.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة'**
  String get anGroup;

  /// No description provided for @anValue.
  ///
  /// In ar, this message translates to:
  /// **'القيمة'**
  String get anValue;

  /// No description provided for @anCount.
  ///
  /// In ar, this message translates to:
  /// **'العدد'**
  String get anCount;

  /// No description provided for @anVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get anVersion;

  /// No description provided for @anLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get anLanguage;

  /// No description provided for @anDevicesLine.
  ///
  /// In ar, this message translates to:
  /// **'نشطة: {a7} خلال 7 أيام، {a30} خلال 30 يومًا'**
  String anDevicesLine(int a7, int a30);

  /// No description provided for @anReportsLine.
  ///
  /// In ar, this message translates to:
  /// **'{total} بلاغًا في الفترة، {open} منها مفتوحة'**
  String anReportsLine(int total, int open);

  /// No description provided for @anReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get anReason;

  /// No description provided for @anActivity.
  ///
  /// In ar, this message translates to:
  /// **'نشاط المهام (استيراد، فحص، دليل، نسخ…)'**
  String get anActivity;

  /// No description provided for @anTask.
  ///
  /// In ar, this message translates to:
  /// **'المهمة'**
  String get anTask;

  /// No description provided for @anOk.
  ///
  /// In ar, this message translates to:
  /// **'نجحت'**
  String get anOk;

  /// No description provided for @anFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت'**
  String get anFailed;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @pictureInPicture.
  ///
  /// In ar, this message translates to:
  /// **'صورة داخل صورة'**
  String get pictureInPicture;

  /// No description provided for @favSyncTitle.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة المفضلة'**
  String get favSyncTitle;

  /// No description provided for @favSyncCreate.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة المفضلة بين أجهزتك'**
  String get favSyncCreate;

  /// No description provided for @favSyncCreateHint.
  ///
  /// In ar, this message translates to:
  /// **'دون حساب: يُنشأ رمز من 8 أحرف تدخله على جهازك الآخر.'**
  String get favSyncCreateHint;

  /// No description provided for @favSyncCreateBtn.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رمز'**
  String get favSyncCreateBtn;

  /// No description provided for @favSyncJoin.
  ///
  /// In ar, this message translates to:
  /// **'ربط برمز من جهاز آخر'**
  String get favSyncJoin;

  /// No description provided for @favSyncJoinShort.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز أو مفتاح التعديل.'**
  String get favSyncJoinShort;

  /// No description provided for @favSyncJoinHint.
  ///
  /// In ar, this message translates to:
  /// **'الرمز وحده يجلب مفضلة الجهاز الآخر ويضيفها لمفضلتك. «مفتاح التعديل» (الرمز ثم - ثم السرّ) يجعل الجهازين يتشاركان قائمة واحدة يعدّلانها معًا.'**
  String get favSyncJoinHint;

  /// No description provided for @favSyncLink.
  ///
  /// In ar, this message translates to:
  /// **'ربط'**
  String get favSyncLink;

  /// No description provided for @favSyncBadCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح'**
  String get favSyncBadCode;

  /// No description provided for @favSyncLinked.
  ///
  /// In ar, this message translates to:
  /// **'تم الربط وجُلبت المفضلة.'**
  String get favSyncLinked;

  /// No description provided for @favSyncNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفضلة بهذا الرمز.'**
  String get favSyncNotFound;

  /// No description provided for @favSyncFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المزامنة. حاول لاحقًا.'**
  String get favSyncFailed;

  /// No description provided for @favSyncCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get favSyncCode;

  /// No description provided for @favSyncOwnerHint.
  ///
  /// In ar, this message translates to:
  /// **'يُرفع كل تغيير تلقائيًا. أعطِ الرمز لجهاز آخر ليجلب القائمة، أو «مفتاح التعديل» ليعدّلها أيضًا.'**
  String get favSyncOwnerHint;

  /// No description provided for @favSyncFollowerHint.
  ///
  /// In ar, this message translates to:
  /// **'يجلب هذا الجهاز القائمة عند كل تشغيل ويضيفها لمفضلته، ولا يعدّلها.'**
  String get favSyncFollowerHint;

  /// No description provided for @favSyncCopyKey.
  ///
  /// In ar, this message translates to:
  /// **'نسخ مفتاح التعديل'**
  String get favSyncCopyKey;

  /// No description provided for @favSyncUnlink.
  ///
  /// In ar, this message translates to:
  /// **'فك الربط'**
  String get favSyncUnlink;

  /// No description provided for @favSyncUnlinkHint.
  ///
  /// In ar, this message translates to:
  /// **'تبقى مفضلتك على هذا الجهاز كما هي.'**
  String get favSyncUnlinkHint;

  /// No description provided for @favSyncDeleteRemote.
  ///
  /// In ar, this message translates to:
  /// **'احذف القائمة المشتركة من الخادم أيضًا'**
  String get favSyncDeleteRemote;

  /// No description provided for @anEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تصل إحصاءات تشغيل بعد. تظهر بعد أن يشاهد المستخدمون بالإصدار الجديد ويُجمَّع اليوم.'**
  String get anEmpty;

  /// No description provided for @epgAddSource.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصدر'**
  String get epgAddSource;

  /// No description provided for @epgSyncNow.
  ///
  /// In ar, this message translates to:
  /// **'زامن الآن'**
  String get epgSyncNow;

  /// No description provided for @epgSyncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة {done}/{total}: {name}'**
  String epgSyncing(int done, int total, String name);

  /// No description provided for @epgSummary.
  ///
  /// In ar, this message translates to:
  /// **'{c} قناة · {p} برنامج'**
  String epgSummary(int c, int p);

  /// No description provided for @epgEvery.
  ///
  /// In ar, this message translates to:
  /// **'كل {h} ساعة'**
  String epgEvery(int h);

  /// No description provided for @epgGithubNote.
  ///
  /// In ar, this message translates to:
  /// **'grabber مشروع iptv-org ما زال يعمل على GitHub (يحتاج Node). مصادر XMLTV هذه تعمل من البرنامج؛ كل مصدر يُكمّل القنوات التي فاتت ما قبله.'**
  String get epgGithubNote;

  /// No description provided for @epgSourceUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط XMLTV (‎.xml أو ‎.xml.gz)'**
  String get epgSourceUrl;

  /// No description provided for @epgPriority.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب (الأصغر أولًا)'**
  String get epgPriority;

  /// No description provided for @epgIntervalHours.
  ///
  /// In ar, this message translates to:
  /// **'كل (ساعات)'**
  String get epgIntervalHours;

  /// No description provided for @mapMissing.
  ///
  /// In ar, this message translates to:
  /// **'{n} قناة منشورة بلا برامج خلال 24 ساعة القادمة'**
  String mapMissing(int n);

  /// No description provided for @mapLoad.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الاقتراحات من المصادر'**
  String get mapLoad;

  /// No description provided for @mapLink.
  ///
  /// In ar, this message translates to:
  /// **'ربط'**
  String get mapLink;

  /// No description provided for @mapLinkAll.
  ///
  /// In ar, this message translates to:
  /// **'ربط كل المطابقات التامة ({n})'**
  String mapLinkAll(int n);

  /// No description provided for @mapNone.
  ///
  /// In ar, this message translates to:
  /// **'لا اقتراح'**
  String get mapNone;

  /// No description provided for @mapHint.
  ///
  /// In ar, this message translates to:
  /// **'الربط يضبط معرّف EPG للقناة (بالمعرّف لا بالاسم). تصل البرامج في المزامنة التالية.'**
  String get mapHint;

  /// No description provided for @e3Issues.
  ///
  /// In ar, this message translates to:
  /// **'{g} فجوة · {o} تداخل'**
  String e3Issues(int g, int o);

  /// No description provided for @e3Offset.
  ///
  /// In ar, this message translates to:
  /// **'الإزاحة (دقائق)'**
  String get e3Offset;

  /// No description provided for @e3OffsetHint.
  ///
  /// In ar, this message translates to:
  /// **'تُطبّق على البرامج التي يكتبها البرنامج من المزامنة التالية.'**
  String get e3OffsetHint;

  /// No description provided for @e3Gap.
  ///
  /// In ar, this message translates to:
  /// **'فجوة {m} دقيقة'**
  String e3Gap(int m);

  /// No description provided for @e3Overlap.
  ///
  /// In ar, this message translates to:
  /// **'تداخل {m} دقيقة'**
  String e3Overlap(int m);

  /// No description provided for @rkGroupCategory.
  ///
  /// In ar, this message translates to:
  /// **'group-title ← الفئة'**
  String get rkGroupCategory;

  /// No description provided for @rkNameCountry.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ← الدولة'**
  String get rkNameCountry;

  /// No description provided for @rkNameLanguage.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ← اللغة'**
  String get rkNameLanguage;

  /// No description provided for @rkNameCleanup.
  ///
  /// In ar, this message translates to:
  /// **'تنظيف الاسم'**
  String get rkNameCleanup;

  /// No description provided for @rkIdMap.
  ///
  /// In ar, this message translates to:
  /// **'tvg-id ← قناتنا'**
  String get rkIdMap;

  /// No description provided for @rPattern.
  ///
  /// In ar, this message translates to:
  /// **'يحتوي'**
  String get rPattern;

  /// No description provided for @rTarget.
  ///
  /// In ar, this message translates to:
  /// **'النتيجة'**
  String get rTarget;

  /// No description provided for @rRegex.
  ///
  /// In ar, this message translates to:
  /// **'تعبير نمطي'**
  String get rRegex;

  /// No description provided for @rNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get rNote;

  /// No description provided for @rulesHint.
  ///
  /// In ar, this message translates to:
  /// **'القواعد تُطبّق على كل استيراد قبل المطابقة. القاعدة تملأ المجهول فقط ولا تستبدل تعديلاتك.'**
  String get rulesHint;

  /// No description provided for @xtSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ هذا الحساب (كلمة المرور مشفّرة في Supabase Vault)'**
  String get xtSave;

  /// No description provided for @xtSaved.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات المحفوظة'**
  String get xtSaved;

  /// No description provided for @xtFetch.
  ///
  /// In ar, this message translates to:
  /// **'جلب ومراجعة'**
  String get xtFetch;

  /// No description provided for @ioLoad.
  ///
  /// In ar, this message translates to:
  /// **'تحميل بيانات iptv-org'**
  String get ioLoad;

  /// No description provided for @ioSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في قنوات iptv-org…'**
  String get ioSearch;

  /// No description provided for @ioInCatalog.
  ///
  /// In ar, this message translates to:
  /// **'في الكتالوج'**
  String get ioInCatalog;

  /// No description provided for @ioNotInCatalog.
  ///
  /// In ar, this message translates to:
  /// **'ليست في الكتالوج'**
  String get ioNotInCatalog;

  /// No description provided for @ioStreams.
  ///
  /// In ar, this message translates to:
  /// **'{n} رابط'**
  String ioStreams(int n);

  /// No description provided for @ioReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة المحدد في الاستيراد ({n})'**
  String ioReview(int n);

  /// No description provided for @ioLicense.
  ///
  /// In ar, this message translates to:
  /// **'بيانات iptv-org (ملكية عامة). وجود رابط هناك ليس دليلًا على حق إعادة توزيعه؛ والقنوات الجديدة تمرّ بالمراجعة دائمًا.'**
  String get ioLicense;

  /// No description provided for @acEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get acEmail;

  /// No description provided for @acMfa.
  ///
  /// In ar, this message translates to:
  /// **'التحقق بخطوتين'**
  String get acMfa;

  /// No description provided for @acAddFactor.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تطبيق مصادقة احتياطي'**
  String get acAddFactor;

  /// No description provided for @acAddFactorHint.
  ///
  /// In ar, this message translates to:
  /// **'مستحسن: تطبيق مصادقة ثانٍ (هاتف آخر أو مدير كلمات مرور). إن فقدت أحدهما يعمل الآخر.'**
  String get acAddFactorHint;

  /// No description provided for @acChangePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get acChangePassword;

  /// No description provided for @acNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة (10 أحرف على الأقل)'**
  String get acNewPassword;

  /// No description provided for @acSignOutAll.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من كل الأجهزة'**
  String get acSignOutAll;

  /// No description provided for @acSignOutAllConfirm.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من كل مكان، ومنه هذا الجهاز؟'**
  String get acSignOutAllConfirm;

  /// No description provided for @acRecovery.
  ///
  /// In ar, this message translates to:
  /// **'فقدت كل تطبيقات المصادقة؟ اتبع docs/runbooks/admin-recovery.md لاستعادة الوصول من لوحة Supabase.'**
  String get acRecovery;

  /// No description provided for @shEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل المهام المجدولة على هذا الجهاز'**
  String get shEnabled;

  /// No description provided for @shTray.
  ///
  /// In ar, this message translates to:
  /// **'البقاء في منطقة الإشعارات عند إغلاق النافذة'**
  String get shTray;

  /// No description provided for @shStartup.
  ///
  /// In ar, this message translates to:
  /// **'البدء مع ويندوز (مخفيًا)'**
  String get shStartup;

  /// No description provided for @shRunNow.
  ///
  /// In ar, this message translates to:
  /// **'شغّل الآن'**
  String get shRunNow;

  /// No description provided for @shAnyTime.
  ///
  /// In ar, this message translates to:
  /// **'أي وقت'**
  String get shAnyTime;

  /// No description provided for @shAllowed.
  ///
  /// In ar, this message translates to:
  /// **'الساعات المسموحة'**
  String get shAllowed;

  /// No description provided for @shNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي {t}'**
  String shNext(String t);

  /// No description provided for @shMissed.
  ///
  /// In ar, this message translates to:
  /// **'فاتت أثناء إطفاء الجهاز: {list}'**
  String shMissed(String list);

  /// No description provided for @shRunning.
  ///
  /// In ar, this message translates to:
  /// **'يعمل: {task}'**
  String shRunning(String task);

  /// No description provided for @shInterval.
  ///
  /// In ar, this message translates to:
  /// **'كل (دقائق)'**
  String get shInterval;

  /// No description provided for @shNote.
  ///
  /// In ar, this message translates to:
  /// **'الفحص الثقيل ينتظر أثناء مشاهدتك لقناة. كل مهمة تعمل على جهاز واحد فقط (قفل على الخادم). المهام الفائتة تُشغَّل عند فتح البرنامج.'**
  String get shNote;

  /// No description provided for @auSearch.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الصف…'**
  String get auSearch;

  /// No description provided for @auAllTables.
  ///
  /// In ar, this message translates to:
  /// **'كل الجداول'**
  String get auAllTables;

  /// No description provided for @auAllActions.
  ///
  /// In ar, this message translates to:
  /// **'كل العمليات'**
  String get auAllActions;

  /// No description provided for @auExport.
  ///
  /// In ar, this message translates to:
  /// **'تصدير CSV'**
  String get auExport;

  /// No description provided for @bkFolder.
  ///
  /// In ar, this message translates to:
  /// **'مجلد النسخ'**
  String get bkFolder;

  /// No description provided for @bkChooseFolder.
  ///
  /// In ar, this message translates to:
  /// **'اختر مجلدًا…'**
  String get bkChooseFolder;

  /// No description provided for @bkPassphrase.
  ///
  /// In ar, this message translates to:
  /// **'عبارة المرور (8 أحرف على الأقل)'**
  String get bkPassphrase;

  /// No description provided for @bkPassphraseHint.
  ///
  /// In ar, this message translates to:
  /// **'لا تُرسل للخادم أبدًا. إن فقدتها لا يمكن فتح النسخ — احفظها في مدير كلمات مرور. نصيحة: اختر مجلدًا متزامنًا مع OneDrive أو Google Drive.'**
  String get bkPassphraseHint;

  /// No description provided for @bkNow.
  ///
  /// In ar, this message translates to:
  /// **'نسخة الآن'**
  String get bkNow;

  /// No description provided for @bkDone.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت النسخة: {name}'**
  String bkDone(String name);

  /// No description provided for @bkList.
  ///
  /// In ar, this message translates to:
  /// **'النسخ في المجلد'**
  String get bkList;

  /// No description provided for @bkOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح ومعاينة'**
  String get bkOpen;

  /// No description provided for @bkRestoreTables.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الجداول المحددة'**
  String get bkRestoreTables;

  /// No description provided for @bkRestoreChannel.
  ///
  /// In ar, this message translates to:
  /// **'استعادة قناة واحدة'**
  String get bkRestoreChannel;

  /// No description provided for @bkCounts.
  ///
  /// In ar, this message translates to:
  /// **'النسخة {b} · الآن {c}'**
  String bkCounts(int b, int c);

  /// No description provided for @bkRestored.
  ///
  /// In ar, this message translates to:
  /// **'استُعيد: {s}'**
  String bkRestored(String s);

  /// No description provided for @bkNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'اختر المجلد وعبارة المرور أولًا.'**
  String get bkNotConfigured;

  /// No description provided for @bkRestoreNote.
  ///
  /// In ar, this message translates to:
  /// **'الاستعادة تضيف الصفوف أو تحدّثها فقط ولا تحذف أي بيانات أحدث. الاستبدال الكامل يُختبر على نسخة منفصلة، لا على الكتالوج الحي.'**
  String get bkRestoreNote;

  /// No description provided for @bkChannelId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف القناة'**
  String get bkChannelId;

  /// No description provided for @mtStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة النظام'**
  String get mtStatus;

  /// No description provided for @mtDbLatency.
  ///
  /// In ar, this message translates to:
  /// **'زمن استجابة قاعدة البيانات: {ms} ms'**
  String mtDbLatency(int ms);

  /// No description provided for @mtEpgStale.
  ///
  /// In ar, this message translates to:
  /// **'لم يُزامَن الدليل منذ أكثر من 48 ساعة'**
  String get mtEpgStale;

  /// No description provided for @mtBackupStale.
  ///
  /// In ar, this message translates to:
  /// **'لا نسخة احتياطية خلال 48 ساعة'**
  String get mtBackupStale;

  /// No description provided for @mtCleanup.
  ///
  /// In ar, this message translates to:
  /// **'التنظيف'**
  String get mtCleanup;

  /// No description provided for @mtDanger.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخطر'**
  String get mtDanger;

  /// No description provided for @mtDangerHint.
  ///
  /// In ar, this message translates to:
  /// **'كل عملية تأخذ نسخة احتياطية إلزامية أولًا، ثم تطلب كتابة كلمة التأكيد.'**
  String get mtDangerHint;

  /// No description provided for @mtTypeWord.
  ///
  /// In ar, this message translates to:
  /// **'اكتب {w} للتأكيد'**
  String mtTypeWord(String w);

  /// No description provided for @mtRefreshCounts.
  ///
  /// In ar, this message translates to:
  /// **'إعادة عدّ المصادر'**
  String get mtRefreshCounts;

  /// No description provided for @mtClearReports.
  ///
  /// In ar, this message translates to:
  /// **'حذف البلاغات المحلولة'**
  String get mtClearReports;

  /// No description provided for @mtClearBrokenLogos.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الشعارات المعطّلة'**
  String get mtClearBrokenLogos;

  /// No description provided for @mtDeleteOffline.
  ///
  /// In ar, this message translates to:
  /// **'حذف الروابط غير المتاحة'**
  String get mtDeleteOffline;

  /// No description provided for @mtDeleteHidden.
  ///
  /// In ar, this message translates to:
  /// **'حذف القنوات المخفية'**
  String get mtDeleteHidden;

  /// No description provided for @mtDeletePending.
  ///
  /// In ar, this message translates to:
  /// **'حذف القنوات قيد المراجعة'**
  String get mtDeletePending;

  /// No description provided for @g1Identity.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get g1Identity;

  /// No description provided for @g1AppNameAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم التطبيق بالعربية'**
  String get g1AppNameAr;

  /// No description provided for @g1AppNameEn.
  ///
  /// In ar, this message translates to:
  /// **'اسم التطبيق بالإنجليزية'**
  String get g1AppNameEn;

  /// No description provided for @g1AboutAr.
  ///
  /// In ar, this message translates to:
  /// **'نص «حول» بالعربية'**
  String get g1AboutAr;

  /// No description provided for @g1AboutEn.
  ///
  /// In ar, this message translates to:
  /// **'نص «حول» بالإنجليزية'**
  String get g1AboutEn;

  /// No description provided for @g1CreditsAr.
  ///
  /// In ar, this message translates to:
  /// **'الاعتمادات بالعربية'**
  String get g1CreditsAr;

  /// No description provided for @g1CreditsEn.
  ///
  /// In ar, this message translates to:
  /// **'الاعتمادات بالإنجليزية'**
  String get g1CreditsEn;

  /// No description provided for @g1CompanyAr.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة بالعربية'**
  String get g1CompanyAr;

  /// No description provided for @g1CompanyEn.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة بالإنجليزية'**
  String get g1CompanyEn;

  /// No description provided for @g1Website.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get g1Website;

  /// No description provided for @g1Email.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get g1Email;

  /// No description provided for @g1Legal.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات القانونية'**
  String get g1Legal;

  /// No description provided for @g1PrivacyAr.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية بالعربية'**
  String get g1PrivacyAr;

  /// No description provided for @g1PrivacyEn.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية بالإنجليزية'**
  String get g1PrivacyEn;

  /// No description provided for @g1PrivacyHint.
  ///
  /// In ar, this message translates to:
  /// **'فارغة = السياسة المدمجة المطابقة لما يجمعه التطبيق فعلًا (§20).'**
  String get g1PrivacyHint;

  /// No description provided for @g1TermsAr.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام بالعربية'**
  String get g1TermsAr;

  /// No description provided for @g1TermsEn.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام بالإنجليزية'**
  String get g1TermsEn;

  /// No description provided for @g3Defaults.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي للأجهزة الجديدة'**
  String get g3Defaults;

  /// No description provided for @g3DefaultLang.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الافتراضية'**
  String get g3DefaultLang;

  /// No description provided for @g3DefaultTheme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر الافتراضي'**
  String get g3DefaultTheme;

  /// No description provided for @g3ParentalCats.
  ///
  /// In ar, this message translates to:
  /// **'فئات مقفلة أبويًا افتراضيًا'**
  String get g3ParentalCats;

  /// No description provided for @g3Catalog.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get g3Catalog;

  /// No description provided for @g3RecentDays.
  ///
  /// In ar, this message translates to:
  /// **'«المضافة حديثًا» تشمل (أيام)'**
  String get g3RecentDays;

  /// No description provided for @g3AttentionDays.
  ///
  /// In ar, this message translates to:
  /// **'«يحتاج انتباهك» بعد (أيام فشل متواصل)'**
  String get g3AttentionDays;

  /// No description provided for @g3AttentionHint.
  ///
  /// In ar, this message translates to:
  /// **'يرفع تنبيهًا لك فقط. لا شيء يُخفى أو يُحذف تلقائيًا (D-14).'**
  String get g3AttentionHint;

  /// No description provided for @g3EpgTz.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية المرجعية للدليل'**
  String get g3EpgTz;

  /// No description provided for @g4Player.
  ///
  /// In ar, this message translates to:
  /// **'المشغّل'**
  String get g4Player;

  /// No description provided for @g4ConnectTimeout.
  ///
  /// In ar, this message translates to:
  /// **'مهلة الشبكة (ثوانٍ)'**
  String get g4ConnectTimeout;

  /// No description provided for @g4FirstFrame.
  ///
  /// In ar, this message translates to:
  /// **'انتظار أول صورة (ثوانٍ) قبل تبديل السيرفر'**
  String get g4FirstFrame;

  /// No description provided for @g4Stall.
  ///
  /// In ar, this message translates to:
  /// **'تجمّد قبل تبديل السيرفر (ثوانٍ)'**
  String get g4Stall;

  /// No description provided for @g4Retries.
  ///
  /// In ar, this message translates to:
  /// **'جولات إضافية على كل السيرفرات'**
  String get g4Retries;

  /// No description provided for @g4Buffer.
  ///
  /// In ar, this message translates to:
  /// **'التخزين المؤقت (ثوانٍ)'**
  String get g4Buffer;

  /// No description provided for @g4UserAgent.
  ///
  /// In ar, this message translates to:
  /// **'User-Agent الافتراضي (فارغ = افتراضي المشغّل)'**
  String get g4UserAgent;

  /// No description provided for @g4Hwdec.
  ///
  /// In ar, this message translates to:
  /// **'فك الترميز بالعتاد'**
  String get g4Hwdec;

  /// No description provided for @g4Probe.
  ///
  /// In ar, this message translates to:
  /// **'فحص الروابط (§12.3)'**
  String get g4Probe;

  /// No description provided for @g4ProbeConnect.
  ///
  /// In ar, this message translates to:
  /// **'مهلة الاتصال (ثوانٍ)'**
  String get g4ProbeConnect;

  /// No description provided for @g4ProbePlaylist.
  ///
  /// In ar, this message translates to:
  /// **'مهلة القائمة (ثوانٍ)'**
  String get g4ProbePlaylist;

  /// No description provided for @g4ProbeFrame.
  ///
  /// In ar, this message translates to:
  /// **'مهلة أول إطار (ثوانٍ)'**
  String get g4ProbeFrame;

  /// No description provided for @g4PerHost.
  ///
  /// In ar, this message translates to:
  /// **'فحوص متزامنة لكل نطاق'**
  String get g4PerHost;

  /// No description provided for @g4Total.
  ///
  /// In ar, this message translates to:
  /// **'فحوص متزامنة إجمالًا'**
  String get g4Total;

  /// No description provided for @g4Ports.
  ///
  /// In ar, this message translates to:
  /// **'المنافذ المسموحة للجلب (مفصولة بفواصل)'**
  String get g4Ports;

  /// No description provided for @g5Maintenance.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة'**
  String get g5Maintenance;

  /// No description provided for @g5MaintOn.
  ///
  /// In ar, this message translates to:
  /// **'وضع الصيانة'**
  String get g5MaintOn;

  /// No description provided for @g5MaintHint.
  ///
  /// In ar, this message translates to:
  /// **'يرى المشاهدون الرسالة بدل التطبيق؛ والمدير يدخل عاديًا.'**
  String get g5MaintHint;

  /// No description provided for @g5MsgAr.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة بالعربية'**
  String get g5MsgAr;

  /// No description provided for @g5MsgEn.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة بالإنجليزية'**
  String get g5MsgEn;

  /// No description provided for @g5Features.
  ///
  /// In ar, this message translates to:
  /// **'المزايا'**
  String get g5Features;

  /// No description provided for @g5FMini.
  ///
  /// In ar, this message translates to:
  /// **'المشغّل المصغّر'**
  String get g5FMini;

  /// No description provided for @g5Refresh.
  ///
  /// In ar, this message translates to:
  /// **'فحص تحديثات الكتالوج كل (دقائق)'**
  String get g5Refresh;

  /// No description provided for @g5Telemetry.
  ///
  /// In ar, this message translates to:
  /// **'جمع إحصاءات تشغيل مجهولة'**
  String get g5Telemetry;

  /// No description provided for @g5KillSwitch.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء قناة فورًا من كل الأجهزة'**
  String get g5KillSwitch;

  /// No description provided for @g5KillHint.
  ///
  /// In ar, this message translates to:
  /// **'تختفي القناة من كل جهاز في مزامنته التالية دون تغيير الكتالوج. أزلها من هنا لإعادتها.'**
  String get g5KillHint;

  /// No description provided for @g2Handle.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو الرابط'**
  String get g2Handle;

  /// No description provided for @g2OwnDeveloper.
  ///
  /// In ar, this message translates to:
  /// **'المطوّر'**
  String get g2OwnDeveloper;

  /// No description provided for @g2Footer.
  ///
  /// In ar, this message translates to:
  /// **'التذييل'**
  String get g2Footer;

  /// No description provided for @g2Splash.
  ///
  /// In ar, this message translates to:
  /// **'شاشة البداية'**
  String get g2Splash;

  /// No description provided for @g2Support.
  ///
  /// In ar, this message translates to:
  /// **'قنوات الدعم'**
  String get g2Support;

  /// No description provided for @followUs.
  ///
  /// In ar, this message translates to:
  /// **'تابعنا'**
  String get followUs;

  /// No description provided for @termsOfUse.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get termsOfUse;

  /// No description provided for @contactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم مباشرة'**
  String get contactSupport;

  /// No description provided for @g2SupportHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر في «الإبلاغ عن مشكلة».'**
  String get g2SupportHint;

  /// No description provided for @g6MinSupported.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأدنى المدعوم'**
  String get g6MinSupported;

  /// No description provided for @g6MinHint.
  ///
  /// In ar, this message translates to:
  /// **'الإصدارات الأقدم تُجبر على التحديث.'**
  String get g6MinHint;

  /// No description provided for @g6Recommended.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار الموصى به'**
  String get g6Recommended;

  /// No description provided for @g6RecHint.
  ///
  /// In ar, this message translates to:
  /// **'الإصدارات الأقدم ترى تنبيهًا بالتحديث.'**
  String get g6RecHint;

  /// No description provided for @g6Url.
  ///
  /// In ar, this message translates to:
  /// **'صفحة التنزيل'**
  String get g6Url;

  /// No description provided for @g6NotesAr.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الإصدار بالعربية'**
  String get g6NotesAr;

  /// No description provided for @g6NotesEn.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الإصدار بالإنجليزية'**
  String get g6NotesEn;

  /// No description provided for @g6Github.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث على GitHub'**
  String get g6Github;

  /// No description provided for @f2Kind.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get f2Kind;

  /// No description provided for @f2Info.
  ///
  /// In ar, this message translates to:
  /// **'معلومة'**
  String get f2Info;

  /// No description provided for @f2Warning.
  ///
  /// In ar, this message translates to:
  /// **'تحذير'**
  String get f2Warning;

  /// No description provided for @f2Style.
  ///
  /// In ar, this message translates to:
  /// **'يظهر كـ'**
  String get f2Style;

  /// No description provided for @f2Banner.
  ///
  /// In ar, this message translates to:
  /// **'شريط'**
  String get f2Banner;

  /// No description provided for @f2Dialog.
  ///
  /// In ar, this message translates to:
  /// **'نافذة ترحيبية'**
  String get f2Dialog;

  /// No description provided for @f2BodyAr.
  ///
  /// In ar, this message translates to:
  /// **'النص بالعربية'**
  String get f2BodyAr;

  /// No description provided for @f2BodyEn.
  ///
  /// In ar, this message translates to:
  /// **'النص بالإنجليزية'**
  String get f2BodyEn;

  /// No description provided for @f2MinVersion.
  ///
  /// In ar, this message translates to:
  /// **'من الإصدار'**
  String get f2MinVersion;

  /// No description provided for @f2MaxVersion.
  ///
  /// In ar, this message translates to:
  /// **'حتى الإصدار'**
  String get f2MaxVersion;

  /// No description provided for @f2Dismissible.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للمشاهد إغلاقه'**
  String get f2Dismissible;

  /// No description provided for @f2Empty.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء بعد.'**
  String get f2Empty;

  /// No description provided for @f1Compose.
  ///
  /// In ar, this message translates to:
  /// **'إشعار جديد'**
  String get f1Compose;

  /// No description provided for @f1Link.
  ///
  /// In ar, this message translates to:
  /// **'يفتح داخل التطبيق (اختياري)'**
  String get f1Link;

  /// No description provided for @f1Image.
  ///
  /// In ar, this message translates to:
  /// **'رابط صورة (اختياري)'**
  String get f1Image;

  /// No description provided for @f1SendAt.
  ///
  /// In ar, this message translates to:
  /// **'جدولة (اختياري، YYYY-MM-DD HH:MM)'**
  String get f1SendAt;

  /// No description provided for @f1SendAtHint.
  ///
  /// In ar, this message translates to:
  /// **'فارغ = الآن. المجدول يصل لصندوق الوارد في موعده على كل المنصّات.'**
  String get f1SendAtHint;

  /// No description provided for @f1Push.
  ///
  /// In ar, this message translates to:
  /// **'إرسال Push لأجهزة Android الآن أيضًا'**
  String get f1Push;

  /// No description provided for @f1PushHint.
  ///
  /// In ar, this message translates to:
  /// **'عبر الدالة القائمة send-push (Firebase). ويندوز وماك يستلمونه في صندوق الوارد.'**
  String get f1PushHint;

  /// No description provided for @f1Sent.
  ///
  /// In ar, this message translates to:
  /// **'نُشر الإشعار'**
  String get f1Sent;

  /// No description provided for @f1History.
  ///
  /// In ar, this message translates to:
  /// **'المُرسلة'**
  String get f1History;

  /// No description provided for @f1CheckFcm.
  ///
  /// In ar, this message translates to:
  /// **'فحص إعداد Push'**
  String get f1CheckFcm;

  /// No description provided for @maintenanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحت الصيانة'**
  String get maintenanceTitle;

  /// No description provided for @updateRequired.
  ///
  /// In ar, this message translates to:
  /// **'يلزم التحديث للمتابعة'**
  String get updateRequired;

  /// No description provided for @updateRecommended.
  ///
  /// In ar, this message translates to:
  /// **'يتوفر إصدار أحدث'**
  String get updateRecommended;

  /// No description provided for @updateNow.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الآن'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get later;
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
