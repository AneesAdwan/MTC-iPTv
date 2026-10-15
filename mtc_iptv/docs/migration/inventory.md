# جرد النظام الحالي قبل الترحيل (§24.2)

> **الحالة:** ✅ **مكتمل.** المخطط من الملفات، و**الأعداد الحية من الإنتاج** (2026-10-15، `verify_all.sql` ← `counts-before.csv`). انظر §10.
>
> تاريخ الجرد: 2026-10-14

## 1. الجداول (11)

| الجدول | المفتاح | الأعمدة | العلاقات | RLS | آخر عدد معروف |
|---|---|---|---|---|---|
| `admin_users` | `user_id` → `auth.users` | user_id, created_at | `on delete cascade` | قراءة الذات فقط | 1 (متوقع) |
| `site_settings` | `key` (`^[a-z0-9_.]+$`) | key, value jsonb, is_public, updated_at | — | عام: `is_public` / المدير: الكل | مفاتيح معروفة: `developer`، `hero`، `proxy` |
| `languages` | `code` (ISO 639-3) | code, name_ar, name_en, sort_order, is_visible | — | عام: `is_visible` | — |
| `countries` | `code` (ISO 3166-1) | code, name_ar, name_en, flag_emoji, **flag_url (مولّد)**, continent, is_arab, language_code, sort_order, is_visible | → languages | عام: `is_visible` | — |
| `categories` | `slug` | slug, name_ar, name_en, icon, hue, sort_order, is_visible | — | عام: `is_visible` | — |
| `playlist_sources` | `id` uuid | id, name, url (فريد، https فقط), is_active, auto_publish, status, channel_count, stream_count, last_import_at, last_error, created_at, updated_at | — | المدير فقط | **1** (حيّ) |
| `channels` | `id` uuid · `uid` فريد · `number` فريد | id, uid, number, name, alt_names[], network, logo_url, logo_status, country_code, category_slug, extra_categories[], language_code, quality, description, website, epg_id, is_published, is_featured, is_manual, prefer_app, hidden_reason, duplicate_of, published_at, dup_key, sort_order, created_at, updated_at | → countries, categories, languages (`set null`) · → channels (`duplicate_of`, `set null`) | المدير فقط (العامة عبر `catalog`) | **359** (حيّ) |
| `streams` | `id` uuid · `url` فريد | id, channel_id, source_id, url, **host (مولّد)**, label, quality, priority, is_active, status, http_status, response_ms, fail_count, last_error, last_checked_at, created_at, updated_at | → channels (`cascade`) · → playlist_sources (`cascade`) | المدير فقط (العامة عبر `catalog_streams`) | **380** (حيّ) |
| `reports` | `id` identity | id, channel_id, stream_id, reason, note, status, created_at | → channels (`cascade`) · → streams (`set null`) | إدخال للجميع بحالة `open` / المدير: الكل | — |
| `epg_programmes` | `id` identity · (`channel_uid`, `start_at`) فريد | id, channel_uid, start_at, end_at, title, description, category, icon_url, source | **لا FK** (ربط نصي بـ `uid`/`epg_id`) | قراءة للجميع | — |
| `epg_runs` | `id` identity | id, ran_at, source, channels_ok, programmes, errors | — | قراءة للمسجّلين | — |
| `favorite_sets` | `code` (6 أحرف) | code, favorites jsonb, updated_at | — | ⚠️ **قراءة وإدخال وتعديل للجميع** (§19.5) | — |

## 2. الواجهات (3)

| الواجهة | الوظيفة | يعتمد عليها |
|---|---|---|
| `catalog` | القنوات المنشورة التي لها رابط مفعّل + أسماء الدولة والفئة واللغة + `prefer_app` + `online` | الويب، تطبيق RN |
| `catalog_streams` | روابط القنوات المنشورة المفعّلة | الويب، تطبيق RN |
| `review_queue` (`security_invoker`) | القنوات المعلّقة مصنّفة في دلاء | لوحة الويب |

> ⚠️ **قيد توافق:** تطبيق RN (‏`versionCode 21`) يقرأ `catalog` و`catalog_streams` بأعمدتهما الحالية **حتى R2**. أي migration يجب أن تُبقيهما بنفس الأعمدة والمعنى.

## 3. الدوال

| الفئة | الدوال |
|---|---|
| أدوات | `touch_updated_at`، `norm_name`، `dup_key`، `server_of`، `is_mtc_admin` |
| Triggers | `channels_review_gate` (بوابة المراجعة، يتجاوزها `mtc.review_bypass`)، `channels_stamp_published` |
| إدارة (22) | `admin_stats`، `admin_import`، `admin_finish_import`، `admin_delete_source`، `admin_cleanup`، `admin_record_checks`، `admin_record_logos`، `admin_duplicates`، `admin_merge`، `admin_hide_duplicates`، `admin_renumber_plan`، `admin_renumber_preview`، `admin_renumber_apply`، `admin_renumber`، `admin_review_apply`، `admin_create_channel`، `admin_iptv_add`، `admin_restore_reset`، `admin_restore_rows`، `admin_restore_links`، `admin_mark_distinct`، `admin_stream_action` |
| EPG | `epg_now`، `epg_day`، `epg_cleanup` |

## 4. الفهارس والقيود الفريدة

- فريدة: `channels.uid`، `channels.number`، `streams.url`، `playlist_sources.url`، (`epg_programmes.channel_uid`, `start_at`).
- فهارس: `channels(is_published, sort_order, number)`، `channels(country_code)`، `channels(category_slug)`، `channels(language_code)`، `channels(lower(name))`، `streams(channel_id, priority)`، `streams(source_id)`، `streams(status)`، `reports(channel_id, status)`، `epg_programmes(channel_uid, start_at)`.

## 5. سياسات RLS: 24 سياسة على 12 جدولًا

كل الكتابة الإدارية عبر `is_mtc_admin()` (وجود المستخدم في `admin_users`). **لا يوجد شرط MFA حاليًا.**

## 6. خارج قاعدة البيانات

| العنصر | المكان | ملاحظة للترحيل |
|---|---|---|
| مزامنة EPG | `.github/workflows/epg.yml` + `supabase/epg_sync.mjs` (تستخدم `service_role` من أسرار GitHub) | تبقى حتى قبول R1 ثم تُوقف |
| إرسال Push | Edge Function `send-push` (سرّ Firebase) | تُطوَّر، لا تُستبدل |
| وسيط البث | `supabase/cloudflare-worker.js` + `site_settings.proxy` | يبقى اختياريًا |
| ملفات الشعارات | روابط خارجية (`logo_url`) | لا ملفات في Storage حاليًا |

## 7. التخزين المحلي في تطبيق RN (لمرحِّل R2)

| المفتاح | الملف المصدر | يُرحَّل؟ |
|---|---|---|
| `mtc-favorites` | `app/src/store/prefs.ts` | ✅ |
| `mtc-continue` | `app/src/store/prefs.ts` | ✅ |
| `mtc-player-prefs` | `app/src/store/prefs.ts` | ✅ |
| `mtc-notifications` | `app/src/store/notifications.ts` | ✅ |
| `mtc-firstrun-perms` | `app/src/permissions.ts` | ✅ (لتجنّب إعادة طلب الأذونات) |
| `mtc-admin-session` | `app/src/api/supabase.ts` | ❌ (إعادة دخول مع MFA) |

## 8. حالات شاذة يجب عدّها قبل الترحيل

تُعدّ بـ `verify.sql` (القسم «قبل»):

1. قنوات بلا أي رابط.
2. قنوات منشورة بلا رابط مفعّل (لا تظهر في `catalog`).
3. سلاسل `duplicate_of` (قناة مدموجة في قناة مدموجة).
4. `duplicate_of` يشير لقناة غير موجودة أو لنفسها.
5. توزيع `hidden_reason` بكل قيمه.
6. قنوات `is_published = true` مع `hidden_reason` غير فارغ (تناقض).
7. روابط تحتوي بيانات اعتماد (نمط Xtream).
8. `epg_id` المكرر بين أكثر من قناة.
9. أسماء بحروف عربية (لتقسيم `name_ar` / `name_en` — ملحق د).
10. `favorite_sets` بمعرّفات قنوات لم تعد موجودة.

## 9. ما يلزم من المالك لإكمال الجرد

- تشغيل `verify.sql` (القسم «قبل») في Supabase → SQL Editor، وحفظ الناتج في `docs/migration/counts-before.md`.
- لتجربة الترحيل (§24.4): **كلمة مرور قاعدة البيانات** لتنفيذ `supabase db dump` محليًا، و**مشروع Supabase ثانٍ** (staging) — الخطة المجانية تسمح بمشروعين.

## 10. القراءة الحية من الإنتاج — 2026-10-15

المصدر: `verify_all.sql` على قاعدة الإنتاج (قراءة فقط) ← [counts-before.csv](counts-before.csv). **هذه الأرقام هي «قبل» التي تُقارن بها كل تجربة ترحيل.**

| الجدول | العدد | ملاحظة |
|---|---|---|
| `channels` | **359** | **قرار المالك:** حذف باقي القنوات والإبقاء على هذه لتقليل عمليات الفحص (لا بيانات مفقودة) |
| `streams` | **380** | كلها مفعّلة |
| `playlist_sources` | 1 | |
| `epg_programmes` / `epg_runs` | 10,806 / 7 | EPG يعمل |
| `countries` / `languages` / `categories` | 250 / 120 / 28 | |
| `admin_users` | 1 | مدير واحد (يطابق D-05) |
| `site_settings` | 4 | `developer`، `hero`، `proxy`، **`numbering`** (مفتاح لم يكن في الجرد — يُضاف لملحق د) |
| `reports` | 0 | |
| **`favorite_sets`** | **غير موجود** | ⚠️ الجدول في `01_schema.sql` المحلي (تعديل غير ملتزم) **ولم يُطبَّق على الإنتاج**. أثره: ميزة «مزامنة المفضلة برمز» غير مفعّلة حاليًا، و§19.5 يبدأ من جدول جديد لا من ترحيل |

### الحالات الشاذة

| الفحص | النتيجة | الأثر على الترحيل |
|---|---|---|
| قنوات بلا روابط، سلاسل دمج، روابط يتيمة، دول/فئات غير موجودة | **0** | ✅ بيانات نظيفة |
| `published_with_hidden_reason` | 0 | ✅ لا تناقض في الحالة |
| `hidden_reason` | كل الـ 359 = `null` (كلها منشورة) | ترحيل `publish_state` بسيط: الكل `published` |
| **روابط فيها بيانات اعتماد** | **3** | تُعلَّم `has_credentials` وتُقنَّع (§19.4) |
| أسماء عربية | 0 | كل الأسماء لاتينية ← `name_en` = `name`، و`name_ar` فارغ (يُملأ يدويًا أو من iptv-org لاحقًا) |
| قنوات يدوية / `prefer_app` | 0 / 0 | لا حقول محمية تلقائيًا من البيانات الحالية |
| `epg_id` مشترك | 0 | ✅ ربط EPG فريد |
| حالة الروابط | 33 تعمل · 6 معطّلة · **341 لم تُفحص** | الفحص الأول الشامل يجري بعد الترحيل من المُجدوِل |

### البصمات المرجعية (يجب أن تتطابق بعد الترحيل)

| البصمة | القيمة |
|---|---|
| `catalog_rows` / `catalog_streams_rows` | 359 / 380 |
| `catalog_hash` | 758654125114984263 |
| `catalog_streams_hash` | 857857366700949087 |
| `channels.uid+name+number` | 1078690101859414724 |
| `streams.url+channel` | 530753459307278177 |
| `published_ids` | 644531306668517116 |

### الخلاصة

قاعدة صغيرة ونظيفة: **الترحيل منخفض المخاطر.** لا حالات شاذة تحتاج معالجة خاصة سوى 3 روابط ببيانات اعتماد ومفتاح `numbering` الجديد.