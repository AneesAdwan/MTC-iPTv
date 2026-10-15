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
