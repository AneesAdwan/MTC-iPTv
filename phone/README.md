# تطبيق MTC-iPTv المستقل (phone/)

تطبيق **أصلي** (ليس متصفحًا) لأندرويد وiOS والأجهزة اللوحية وأندرويد TV وApple TV، يقرأ القنوات من **نفس قاعدة بيانات Supabase** المستخدمة في موقع الويب، عبر الواجهات العامة `catalog` و`catalog_streams` فقط. المشاهدة فقط — بلا لوحة إدارة، فالإدارة تبقى من الويب.

## لماذا هذه التقنية
`react-native-tvos` هي التقنية الوحيدة التي تغطّي من **كود واحد**: أندرويد، iOS، أندرويد TV، وApple TV. تشغيل HLS (`.m3u8`) يتم عبر مشغّل الجهاز الأصلي (ExoPlayer على أندرويد، AVPlayer على iOS/الأجهزة) بلا أي مكتبة ويب.
تلفزيونات **سامسونج (Tizen)** و**LG (webOS)** منصّتهما ويب أصلًا، وتُغطّى لاحقًا بتغليف تطبيق الويب الحالي.

## البنية
```
phone/
  App.js                 ← جذر التطبيق (تحميل القنوات + التنقل بين الرئيسية والمشاهدة)
  index.js, app.json     ← نقطة الدخول
  src/
    config.js            ← رابط Supabase والمفتاح العام (نفس قاعدة الويب)
    lib/supabase.js      ← عميل Supabase (قراءة فقط)
    lib/catalog.js       ← جلب القنوات والروابط والإعدادات + منطق الوسيط
    theme.js             ← ألوان الهوية
    components/           ← بطاقة قناة + صف أفقي (قابل للتركيز بالريموت)
    screens/HomeScreen   ← صفوف الرئيسية (مميزة، مضافة حديثًا، حسب الفئة)
    screens/WatchScreen  ← مشغّل HLS أصلي + تبديل سيرفرات + شريط القناة
```
التطبيق **لا يُعدّل قاعدة البيانات**؛ يقرأ فقط ما هو منشور. أي تعديل (إضافة/إخفاء قنوات) يبقى من لوحة الويب، ويظهر في التطبيق تلقائيًا.

## خطوات البناء (مرة واحدة)
هذا المجلد يحوي الكود المصدري (`src`, `App.js`, `package.json`). الملفات الأصلية للمنصّات (مجلدات `android/` و`ios/`) تُولّد بأمر الإنشاء:

1. **ثبّت المتطلبات:** Node 18+، وأدوات React Native (Android Studio لأندرويد؛ Xcode على ماك لـ iOS وApple TV). دليل: https://reactnative.dev/docs/set-up-your-environment
2. **أنشئ مشروع tvOS فارغًا بنفس الاسم** في مجلد مؤقت:
   ```
   npx @react-native-community/cli@latest init MTCiPTv --version "npm:react-native-tvos@0.76.5-0"
   ```
3. **انسخ فوقه** ملفات هذا المجلد: `App.js` و`index.js` و`app.json` و`src/` و`package.json`.
4. ثبّت الحزم:
   ```
   cd MTCiPTv && npm install
   ```
   وعلى ماك لـ iOS/Apple TV: `npx pod-install`
5. **التشغيل:**
   - أندرويد / أندرويد TV: `npm run android` (جهاز أو محاكي؛ أندرويد TV يعمل بنفس APK)
   - iOS / Apple TV (ماك فقط): افتح `ios/MTCiPTv.xcworkspace` في Xcode، اختر الجهاز (iPhone أو Apple TV)، ثم Run.

## النشر
- **أندرويد (الأسهل):** `cd android && ./gradlew assembleRelease` → ملف APK في `android/app/build/outputs/apk/release/`. ثبّته مباشرة أو ارفعه إلى Google Play / متجر أندرويد TV.
- **iOS / Apple TV:** يحتاج حساب Apple Developer، ويُرفع عبر Xcode إلى App Store / TestFlight.

## الحالة
نسخة أساس عاملة: تحميل القنوات، الصفحة الرئيسية بصفوف، المشاهدة بمشغّل HLS أصلي مع تبديل السيرفرات وشريط القناة ودعم الريموت.
**التالي:** صفحات الدول والفئات والبحث، المفضلة (تُحفظ على الجهاز)، قائمة القنوات أثناء المشاهدة، شاشة البداية والأيقونات، وخط IBM Plex Sans Arabic.
