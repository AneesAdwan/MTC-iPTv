# مخطط قاعدة البيانات المستهدف (ERD) — مسودة المرحلة 0

> مبني على §16 ومقيّد بـ ADR-18 (إضافي ومتوافق للخلف). الأعمدة القديمة تبقى حتى R2 + 60 يومًا. يُراجع ويُعتمد ضمن بوابة C.
> الرموز: 🆕 جدول جديد · 🔄 جدول قائم يُطوَّر.

## 1. الكتالوج

```mermaid
erDiagram
  countries ||--o{ channels : "country_code"
  categories ||--o{ channels : "category_slug (الرئيسية)"
  languages ||--o{ channels : "language_code"
  languages ||--o{ countries : "language_code"
  networks |o--o{ channels : "network_id 🆕"
  assets |o--o{ channels : "logo_asset_id 🆕"
  channels ||--o{ channel_categories : "🆕"
  categories ||--o{ channel_categories : ""
  channels ||--o{ streams : "channel_id (cascade)"
  channels ||--o{ channel_field_provenance : "🆕 مصدر كل حقل"
  channels ||--o{ channel_conflicts : "🆕"
  channels ||--o{ channel_history : "🆕"
  channels |o--o{ channels : "duplicate_of / merged_into"
  sources |o--o{ streams : "source_id"
  host_rules |o..o{ streams : "حسب host (منطقي)"

  channels {
    uuid id PK
    text uid UK "tvg-id أو manual:…"
    int number UK
    text name "قديم — يبقى للتوافق"
    text name_ar "🆕"
    text name_en "🆕"
    text publish_state "🆕 draft|pending|published|hidden|rejected"
    text hidden_reason "قديم + سبب الإخفاء"
    bool is_published "قديم — يُزامَن بـ Trigger"
    uuid merged_into "🆕"
    text family_key "🆕"
    int epg_offset_minutes "🆕"
    bool parental_locked "🆕"
    timestamptz published_at
  }
  streams {
    uuid id PK
    uuid channel_id FK
    uuid source_id FK
    text url UK
    text host "مولّد"
    int priority
    bool is_active
    text status "قديم: online|offline|unknown"
    text health_state "🆕 §12.2"
    text health_reason "🆕"
    int health_score "🆕 0-100"
    text user_agent "🆕"
    text referrer "🆕"
    jsonb headers "🆕"
    text protocol "🆕"
    bool has_credentials "🆕"
  }
  channel_field_provenance {
    uuid channel_id FK
    text field
    text source_kind "manual|rule|connector|source|inferred"
    uuid source_id
    timestamptz fetched_at
    real confidence
    bool locked
  }
```

## 2. الاستيراد والمصادر

```mermaid
erDiagram
  sources ||--o{ source_records : "كل جلب"
  connectors ||--o{ sources : "type=connector"
  sources |o--|| source_credentials : "Vault 🆕"
  jobs ||--o{ job_logs : ""
  jobs ||--o{ import_candidates : ""
  source_records ||--o{ import_candidates : ""
  import_candidates }o--o| channels : "matched_channel_id"
  transform_rules }o..o{ import_candidates : "تُطبَّق أثناء التحويل"

  sources {
    uuid id PK
    text type "m3u|xtream|connector"
    text url
    text schedule
    text update_policy
    text content_hash
    text status
  }
  import_candidates {
    uuid id PK
    uuid job_id FK
    text outcome "new|update|duplicate|conflict|rejected"
    text match_key
    text match_reason
    real confidence
    jsonb proposed
    text decision "pending|accepted|rejected"
  }
```

## 3. EPG، الصحة، الإحصاءات

```mermaid
erDiagram
  epg_sources ||--o{ epg_programmes : "source_id 🆕"
  epg_sources ||--o{ epg_channel_mappings : ""
  epg_channel_mappings }o--|| channels : "channel_id"
  streams ||--o{ health_checks : "30 يومًا"
  streams ||--o{ playback_events : "30 يومًا"
  installations ||--o{ playback_events : "مستعار"
  streams ||--o{ playback_stats_daily : "دائم بلا installation_id"

  epg_channel_mappings {
    uuid channel_id FK
    uuid source_id FK
    text epg_channel_id
    text matched_by "manual|tvg-id|name"
  }
  playback_events {
    bigint id PK
    uuid stream_id FK
    uuid installation_id
    text result
    text err_class "رموز §12.2"
    real ttff_s
    text platform
    text app_version
    text country_approx
  }
```

## 4. النظام والتواصل

```mermaid
erDiagram
  admin_users ||--o{ audit_logs : "actor"
  scheduled_tasks ||--o{ task_runs : ""
  notifications ||--o{ notification_deliveries : ""
  installations ||--o{ notification_deliveries : ""
  releases }o--|| releases : "per platform/channel"

  scheduled_tasks {
    text key PK "health_published|epg|backup|…"
    bool enabled
    text cron
    text allowed_hours
    timestamptz next_run_at
    text locked_by "معرّف الجهاز"
  }
  audit_logs {
    bigint id PK
    timestamptz at
    uuid actor
    text action
    text table_name
    text row_id
    jsonb before
    jsonb after
    text reason "manual|import|merge|migration|restore"
  }
```

## 5. قواعد يجب أن يحققها التنفيذ

- كل جدول جديد: RLS مفعّلة + سياسة `is_admin()` (مدير بجلسة MFA) + اختبار pgTAP.
- `catalog` و`catalog_streams`: نفس الأعمدة حتى R2 (تطبيق RN يقرؤها).
- Triggers توافق: `is_published`/`hidden_reason` ↔ `publish_state`، و`name` ↔ `name_ar`/`name_en`، و`epg_id` ↔ `epg_channel_mappings`.
- لا FK بين `epg_programmes` و`channels` (الربط عبر `epg_channel_mappings`)، كما هو اليوم.
