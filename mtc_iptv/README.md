# MTC-iPTv — التطبيق الموحّد (Flutter)

منتج من **MTC-Group** — مجموعة شركات مركز تكنولوجيا الشرق الأوسط · برمجة وتطوير: **أنيس عدوان**

> المواصفات الكاملة والقرارات: [docs/MASTER_SPEC.md](docs/MASTER_SPEC.md) · حالة إثبات المفهوم: [docs/poc/README.md](docs/poc/README.md)

## التشغيل للتطوير

```powershell
# Flutter مثبّت عبر scoop
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$env:PATH"
cd mtc_iptv
flutter pub get
flutter run -d windows                                   # الإنتاج (افتراضي)
flutter run -d windows --dart-define=MTC_ENV=staging     # بيئة التجارب
```

| الأمر | الوظيفة |
|---|---|
| `flutter analyze` | التحليل (يجب أن يكون نظيفًا) |
| `flutter test` | اختبارات التطبيق |
| `cd packages\mtc_core; dart test` | اختبارات المنطق الأساسي |
| `flutter gen-l10n` | توليد الترجمات بعد تعديل `lib/app/l10n/*.arb` |
| `flutter build windows --release` | بناء Windows |

**اختصارات داخل التطبيق:** `Ctrl+K` لوحة الأوامر · `Ctrl+B` طي القائمة الجانبية.

## البنية (§23)

```text
lib/
  main.dart                  تهيئة: التسجيل، الإعدادات، النافذة
  app/
    app.dart                 MaterialApp: اللغة والاتجاه والثيم
    router.dart              التوجيه (go_router)
    screens.dart             ⭐ سجل الشاشات: المصدر الوحيد للقائمة والتوجيه ولوحة الأوامر
    theme/tokens.dart        ⭐ رموز الألوان والمسافات — لا ألوان مباشرة في الشاشات
    l10n/                    ملفات الترجمة ARB (العربية هي القالب)
    layout/form_factor.dart  أنماط التخطيط: desktop / tablet / phone / tv
    shell/                   شريط العنوان، القائمة، الشريط العلوي، الحالة، لوحة الأوامر
  core/
    config/env.dart          البيئات (production / staging)
    logging/log.dart         سجل يومي في مجلد التطبيق، مع إخفاء بيانات الاعتماد
    settings/                الإعدادات المحلية (اللغة، المظهر، القائمة)
  features/                  الشاشات (حاليًا شاشات مؤقتة لكل معرّف)
packages/mtc_core/           Dart نقي: المحلّلات، التطبيع العربي، المطابقة
tools/                       أدوات المرحلة 0 (إثبات المفهوم) — خارج التطبيق
docs/                        المواصفات، القرارات، التقارير، الترحيل
```

## قواعد الكود

- **إضافة شاشة** = سطر في `lib/app/screens.dart` + عنوانها في ملفي ARB.
- **لا ألوان مباشرة**: `context.colors.accent` وأمثالها من `tokens.dart`.
- **الاتجاه**: `EdgeInsetsDirectional` و`AlignmentDirectional` دائمًا، لا `left/right`.
- **لا أسرار في الكود** (§19.1). الروابط تمرّ عبر `safe()` قبل أي سجل.
- كل مكوّن تفاعلي يُستخدم بلوحة المفاتيح وحدها (أساس التلفاز، §6.5).
