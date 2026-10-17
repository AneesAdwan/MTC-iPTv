# MTC-iPTv SuperAdmin

برنامج الإدارة الجديد لـ MTC-iPTv — **ويندوز فقط، للمدير فقط**. مبني من الصفر حسب الخطة
[`mtc_iptv/docs/plans/admin-rebuild-2026-10.md`](../mtc_iptv/docs/plans/admin-rebuild-2026-10.md) (المرحلة 1.3: الأساس).
اللوحة القديمة داخل `mtc_iptv/` (SuperAdmin المؤقت) بتضل شغالة لحد ما هالبرنامج يغطي كل الخدمات.

## شو موجود هلأ
- **الدخول بخطوتين:** بريد + كلمة مرور ← (أول مرة) تسجيل تطبيق التحقق برمز QR ← رمز TOTP.
  البرنامج **ما بيقرر بنفسه إنه مخوّل**: كل شاشة بتسأل الخادم (`admin_status`) قبل ما تفتح، ومع كل تغيّر بالجلسة، وكل دقيقة.
  إذا الخادم ما أكّد (`is_admin`) أو الجلسة انتهت/انلغت ← رجوع لشاشة الدخول فورًا.
- **الهيكل:** القائمة الجانبية بالأقسام السبعة (يمين بالعربي)، شريط علوي (بحث شامل Ctrl+K، جرس التنبيهات، قائمة الحساب)، شريط نتيجة، وشريط حالة.
- **المكونات الموحّدة** (`lib/ui/`): جدول بترقيم من الخادم، شريط فلاتر وعروض محفوظة، شريط تحديد (المعروض / كل النتائج / عكس / مسح + «n من الكل»)،
  حوار معاينة (مجموعات + سبب إلزامي + صنف التراجع)، شريط نتيجة «تمّ · فشل (التفاصيل) · تراجع»، بطاقة قرار، حالات فارغ/تحميل/خطأ (الخطأ دايمًا فيه «أعد المحاولة» و«التفاصيل»)، وزر ⓘ.
- **الشرح ⓘ:** شرح كل خدمة من القسم 6 بالخطة، بملفات `assets/help/ar/*.md` (47 خدمة + القواعد + أصناف التراجع).
- **الصفحات:** كل صفحات الأقسام السبعة بتصميمها الحقيقي، بس **البيانات تجريبية** لحد المرحلة 2.
- **ولا كتابة مباشرة على الجداول:** كل حفظ بيمر من دالة خادم `admin_*` (القائمة بـ`lib/data/rpc/rpc_catalog.dart`).
  لحد المرحلة 2 الدوال مش موجودة، فالحفظ **ما بينفّذ شي وبيقول هيك بوضوح** بشريط النتيجة.

## التشغيل والبناء
```powershell
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$HOME\scoop\shims;$env:PATH"
cd superadmin
flutter pub get
flutter run -d windows                              # مشروع الإنتاج
flutter run -d windows --dart-define=MTC_ENV=local  # Supabase محلي
flutter analyze
flutter test
flutter build windows --release                     # build\windows\x64\runner\Release\mtc_superadmin.exe
```
خيارات البناء: `--dart-define=APP_VERSION=…`، `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`،
و`--dart-define=MTC_SERVER_FUNCTIONS=true` (بعد ما تنزل دوال المرحلة 2 على الخادم).

## الهوية (ما بتتعارض مع البرامج التانية)
| | المشاهدين | SuperAdmin المؤقت | **SuperAdmin الجديد** |
|---|---|---|---|
| الملف | `mtc_iptv.exe` | `mtc_superadmin.exe` | `mtc_superadmin.exe` (مجلد منفصل) |
| صنف النافذة | `MTC_IPTV_WINDOW` | `MTC_IPTV_SUPERADMIN_WINDOW` | `MTC_SUPERADMIN2_WINDOW` |
| قفل النسخة الواحدة | `Local\MTC-iPTv-SingleInstance` | `Local\MTC-iPTv-SuperAdmin-SingleInstance` | `Local\MTC-iPTv-SuperAdmin2-SingleInstance` |
| مجلد البيانات | `%APPDATA%\MTC-Group\MTC-iPTv` | `%APPDATA%\MTC-Group\MTC-iPTv SuperAdmin` | `%APPDATA%\MTC-Group\mtc_superadmin2` |

- مجلد البيانات بينحدد بالكود (`lib/core/app_paths.dart`) مش من اسم المنتج، لأنه اسم المنتج نفسه «MTC-iPTv SuperAdmin» عند البرنامجين.
  البرنامج ما بيستخدم `path_provider` ولا `shared_preferences`، وفيه بس تفضيلات بسيطة (اللغة، الثيم، العروض المحفوظة).
- **الجلسة بالذاكرة بس:** ولا رمز دخول بينحفظ على القرص؛ كل فتح للبرنامج بيطلب كلمة المرور ورمز التحقق.
- ولا سر بالبرنامج: رابط Supabase والمفتاح العام (anon) بس.

## ترتيب المجلدات
```
lib/
  main.dart            التشغيل: عميل Supabase (Dart نقي)، الجلسة، طبقة RPC
  app/                 التطبيق، المسارات وبوابة الخادم، سجل الأقسام والصفحات (nav.dart)، الثيم
  auth/                الدخول بخطوتين: البوابة (admin_status)، المتحكم، شاشة الدخول
  core/                النصوص الثنائية (Tr)، البيئة، المسارات، التفضيلات، رسائل الأخطاء
  data/                عقد الترقيم، النماذج، واجهات المستودعات وتنفيذها، rpc/ (admin_*)، sample/ (بيانات تجريبية)
  shell/               الهيكل (القائمة، الشريط العلوي، شريط الحالة)، لوحة الأوامر Ctrl+K
  ui/                  المكونات الموحّدة
  features/            صفحات الأقسام السبعة
assets/help/ar/        شرح كل خدمة (القسم 6 من الخطة)
windows/runner/        هوية البرنامج (identity.h، Runner.rc)
test/                  اختبارات البوابة، التنقل بالعربي والإنجليزي، التحديد، المعاينة، شريط النتيجة، الحمايات
```

## لوحة المفاتيح
Ctrl+K بحث · `/` فلتر · Space تحديد · Enter فتح · Del سلة · Ctrl+Z تراجع.

---

## English (short)
**MTC-iPTv SuperAdmin** is the new, separate Windows-only admin program (plan phase 1.3 foundation). It depends only on the shared
pure-Dart package `../mtc_iptv/packages/mtc_core`, never on the viewer app.

- Server-driven sign-in (email + password → TOTP enrollment with QR → TOTP). Every admin screen re-reads `admin_status` before opening;
  anything other than a server-confirmed `is_admin` returns to sign-in. The session lives in memory only.
- Shell with the 7 sections, Ctrl+K palette, alerts bell, account menu, result bar, status bar; stable shareable routes
  (`/channels?state=hidden`, `/decisions?type=broken`).
- Unified components in `lib/ui/`; Arabic help per service in `assets/help/ar/`.
- All pages use sample data until Phase 2. Writes go only through `admin_*` RPCs (`lib/data/rpc/rpc_catalog.dart`); the stub RPC layer
  executes nothing and says so in the result bar. Enable the real calls with `--dart-define=MTC_SERVER_FUNCTIONS=true`.
- Own window class / mutex / data folder (`%APPDATA%\MTC-Group\mtc_superadmin2`), so it runs side by side with the viewer and the interim admin.

Run: `flutter run -d windows` · Test: `flutter test` · Build: `flutter build windows --release`.
Not part of any CI or release script yet.
