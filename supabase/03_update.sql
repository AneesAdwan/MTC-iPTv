-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — 03_update.sql : ترقية قاعدة البيانات إلى آخر إصدار دون حذف أي بيانات
--
-- لأي قاعدة بُنيت بإصدار أقدم من 01_schema.sql: يضيف الأعمدة الناقصة، ويعيد إنشاء كل الدوال
-- والواجهات والمشغّلات والصلاحيات كما في آخر إصدار. القنوات والروابط والمصادر والإعدادات تبقى كما هي.
-- آمن للتشغيل أكثر من مرة.
--
-- ⚙️ مولّد تلقائيًا من 01_schema.sql — لا تعدّله يدويًا.
-- التشغيل: Supabase Dashboard → SQL Editor → New query → الصق → Run
-- ════════════════════════════════════════════════════════════════════════════
begin;

-- ─── 0) تنظيف البنية القديمة ────────────────────────────────────────────────
drop view if exists public.catalog, public.catalog_streams cascade;
drop function if exists public.touch_updated_at() cascade;
drop function if exists public.norm_name(text) cascade;
drop function if exists public.server_of(text) cascade;
drop function if exists public.admin_stats() cascade;
drop function if exists public.admin_import(uuid, jsonb, boolean) cascade;
drop function if exists public.admin_finish_import(uuid, text[]) cascade;
drop function if exists public.admin_delete_source(uuid) cascade;
drop function if exists public.admin_cleanup(text) cascade;
drop function if exists public.admin_record_checks(jsonb) cascade;
drop function if exists public.admin_record_logos(jsonb) cascade;
drop function if exists public.admin_duplicates() cascade;
drop function if exists public.admin_merge(uuid, uuid[]) cascade;
drop function if exists public.admin_hide_duplicates(uuid, uuid[]) cascade;
drop function if exists public.admin_renumber() cascade;
drop view if exists public.review_queue cascade;
drop function if exists public.channels_review_gate() cascade;
drop function if exists public.channels_stamp_published() cascade;
drop function if exists public.admin_review_apply(text, uuid[]) cascade;
drop function if exists public.admin_create_channel(jsonb, text) cascade;
drop function if exists public.admin_iptv_add(jsonb, boolean) cascade;
drop function if exists public.admin_restore_reset(boolean) cascade;
drop function if exists public.admin_restore_rows(text, jsonb) cascade;
drop function if exists public.admin_restore_links(jsonb) cascade;
drop function if exists public.dup_key(public.channels) cascade;
drop function if exists public.admin_mark_distinct(uuid[]) cascade;
drop function if exists public.admin_stream_action(text, uuid[]) cascade;
drop function if exists public.admin_renumber_plan(text[], integer, integer, boolean) cascade;
drop function if exists public.admin_renumber_preview(text[], integer, integer, boolean, integer) cascade;
drop function if exists public.admin_renumber_apply(text[], integer, integer, boolean) cascade;

-- ─── 1) المشرفون ────────────────────────────────────────────────────────────
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users add column if not exists created_at timestamptz not null default now();

-- إعدادات الموقع (مفتاح ← قيمة). لا تُحذف عند إعادة تشغيل هذا الملف.
-- is_public = يقرأها الزائر (قناة «يعرض الآن»، حسابات المطوّر)
create table if not exists public.site_settings (
  key        text primary key check (key ~ '^[a-z0-9_.]+$'),
  value      jsonb not null default 'null',
  is_public  boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.site_settings add column if not exists value      jsonb not null default 'null';
alter table public.site_settings add column if not exists is_public  boolean not null default false;
alter table public.site_settings add column if not exists updated_at timestamptz not null default now();

-- ─── 2) الجداول المرجعية: اللغات، الدول، الفئات ─────────────────────────────
create table if not exists public.languages (
  code        text primary key check (code ~ '^[a-z]{3}$'),          -- ISO 639-3: ara, eng, fra
  name_ar     text not null,
  name_en     text not null,
  sort_order  integer not null default 100,
  is_visible  boolean not null default true
);
alter table public.languages add column if not exists name_ar     text not null;
alter table public.languages add column if not exists name_en     text not null;
alter table public.languages add column if not exists sort_order  integer not null default 100;
alter table public.languages add column if not exists is_visible  boolean not null default true;

create table if not exists public.countries (
  code          text primary key check (code ~ '^[A-Z]{2}$'),        -- ISO 3166-1: SA, EG
  name_ar       text not null,
  name_en       text not null,
  flag_emoji    text,
  flag_url      text generated always as ('https://flagcdn.com/w80/' || lower(code) || '.png') stored,
  continent     text check (continent in ('africa','americas','asia','europe','oceania')),
  is_arab       boolean not null default false,
  language_code text references public.languages(code) on update cascade on delete set null,  -- اللغة الأساسية
  sort_order    integer not null default 100,
  is_visible    boolean not null default true
);
alter table public.countries add column if not exists name_ar       text not null;
alter table public.countries add column if not exists name_en       text not null;
alter table public.countries add column if not exists flag_emoji    text;
alter table public.countries add column if not exists flag_url      text generated always as ('https://flagcdn.com/w80/' || lower(code) || '.png') stored;
alter table public.countries add column if not exists continent     text check (continent in ('africa','americas','asia','europe','oceania'));
alter table public.countries drop constraint if exists countries_continent_check;
alter table public.countries add constraint countries_continent_check check (continent in ('africa','americas','asia','europe','oceania')) not valid;
alter table public.countries add column if not exists is_arab       boolean not null default false;
alter table public.countries add column if not exists language_code text references public.languages(code) on update cascade on delete set null;
alter table public.countries add column if not exists sort_order    integer not null default 100;
alter table public.countries add column if not exists is_visible    boolean not null default true;

create table if not exists public.categories (
  slug        text primary key check (slug ~ '^[a-z0-9-]+$'),        -- news, sports, ...
  name_ar     text not null,
  name_en     text not null,
  icon        text not null default 'tv',                            -- اسم أيقونة من src/icons.js
  hue         integer not null default 220 check (hue between 0 and 360),
  sort_order  integer not null default 100,
  is_visible  boolean not null default true
);
alter table public.categories add column if not exists name_ar     text not null;
alter table public.categories add column if not exists name_en     text not null;
alter table public.categories add column if not exists icon        text not null default 'tv';
alter table public.categories add column if not exists hue         integer not null default 220 check (hue between 0 and 360);
alter table public.categories drop constraint if exists categories_hue_check;
alter table public.categories add constraint categories_hue_check check (hue between 0 and 360) not valid;
alter table public.categories add column if not exists sort_order  integer not null default 100;
alter table public.categories add column if not exists is_visible  boolean not null default true;

-- ─── 3) مصادر البث (قوائم M3U) ──────────────────────────────────────────────
create table if not exists public.playlist_sources (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (length(trim(name)) between 1 and 150),
  url            text not null unique check (url ~ '^https://'),
  is_active      boolean not null default true,                       -- يدخل في «تحديث الكل»
  auto_publish   boolean not null default true,                       -- نشر القنوات الجديدة تلقائيًا
  status         text not null default 'pending' check (status in ('pending','processing','ready','failed')),
  channel_count  integer not null default 0,
  stream_count   integer not null default 0,
  last_import_at timestamptz,
  last_error     text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
alter table public.playlist_sources add column if not exists name           text not null check (length(trim(name)) between 1 and 150);
alter table public.playlist_sources drop constraint if exists playlist_sources_name_check;
alter table public.playlist_sources add constraint playlist_sources_name_check check (length(trim(name)) between 1 and 150) not valid;
alter table public.playlist_sources add column if not exists url            text not null unique check (url ~ '^https://');
alter table public.playlist_sources drop constraint if exists playlist_sources_url_check;
alter table public.playlist_sources add constraint playlist_sources_url_check check (url ~ '^https://') not valid;
alter table public.playlist_sources add column if not exists is_active      boolean not null default true;
alter table public.playlist_sources add column if not exists auto_publish   boolean not null default true;
alter table public.playlist_sources add column if not exists status         text not null default 'pending' check (status in ('pending','processing','ready','failed'));
alter table public.playlist_sources drop constraint if exists playlist_sources_status_check;
alter table public.playlist_sources add constraint playlist_sources_status_check check (status in ('pending','processing','ready','failed')) not valid;
alter table public.playlist_sources add column if not exists channel_count  integer not null default 0;
alter table public.playlist_sources add column if not exists stream_count   integer not null default 0;
alter table public.playlist_sources add column if not exists last_import_at timestamptz;
alter table public.playlist_sources add column if not exists last_error     text;
alter table public.playlist_sources add column if not exists created_at     timestamptz not null default now();
alter table public.playlist_sources add column if not exists updated_at     timestamptz not null default now();

-- ─── 4) القنوات ─────────────────────────────────────────────────────────────
create table if not exists public.channels (
  id               uuid primary key default gen_random_uuid(),
  uid              text not null unique,                              -- معرّف ثابت: tvg-id (AlJazeera.qa) أو manual:…
  number           integer unique check (number > 0),                 -- رقم القناة (مثل التلفاز)
  name             text not null check (length(trim(name)) between 1 and 250),
  alt_names        text[] not null default '{}',
  network          text,                                              -- الشبكة: MBC, BBC …
  logo_url         text,
  logo_status      text not null default 'unknown' check (logo_status in ('unknown','ok','broken')),
  country_code     text references public.countries(code)  on update cascade on delete set null,
  category_slug    text references public.categories(slug) on update cascade on delete set null,
  extra_categories text[] not null default '{}',
  language_code    text references public.languages(code)  on update cascade on delete set null,
  quality          text check (quality in ('SD','HD','FHD','4K')),
  description      text check (length(description) <= 1000),
  website          text,
  epg_id           text,                                              -- معرّف EPG بديل لـ uid (لمطابقة XMLTV)؛ إن كان فاضيًا يُستعمل uid بعد حذف لاحقة @…
  is_published     boolean not null default true,
  is_featured      boolean not null default false,
  is_manual        boolean not null default false,                    -- أضيفت يدويًا (لا تُحذف مع المصادر)
  prefer_app       boolean not null default false,                    -- تعمل في التطبيق لا المتصفح: تبقى ظاهرة رغم فشل فحص الويب، وعليها شارة «الأفضل عبر التطبيق»
  hidden_reason    text check (hidden_reason in ('manual','duplicate','offline','reported','pending')),  -- pending = بانتظار مراجعة المدير
  duplicate_of     uuid references public.channels(id) on delete set null,
  published_at     timestamptz,                                       -- أول نشر فعلي للمشاهدين (لقائمة «مضافة حديثًا»)
  dup_key          text,                                              -- يحدده المدير: «ليست مكررة» يعطي القناة مفتاحًا خاصًا بها
  sort_order       integer not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
alter table public.channels add column if not exists uid              text not null unique;
alter table public.channels add column if not exists number           integer unique check (number > 0);
alter table public.channels drop constraint if exists channels_number_check;
alter table public.channels add constraint channels_number_check check (number > 0) not valid;
alter table public.channels add column if not exists name             text not null check (length(trim(name)) between 1 and 250);
alter table public.channels drop constraint if exists channels_name_check;
alter table public.channels add constraint channels_name_check check (length(trim(name)) between 1 and 250) not valid;
alter table public.channels add column if not exists alt_names        text[] not null default '{}';
alter table public.channels add column if not exists network          text;
alter table public.channels add column if not exists logo_url         text;
alter table public.channels add column if not exists logo_status      text not null default 'unknown' check (logo_status in ('unknown','ok','broken'));
alter table public.channels drop constraint if exists channels_logo_status_check;
alter table public.channels add constraint channels_logo_status_check check (logo_status in ('unknown','ok','broken')) not valid;
alter table public.channels add column if not exists country_code     text references public.countries(code)  on update cascade on delete set null;
alter table public.channels add column if not exists category_slug    text references public.categories(slug) on update cascade on delete set null;
alter table public.channels add column if not exists extra_categories text[] not null default '{}';
alter table public.channels add column if not exists language_code    text references public.languages(code)  on update cascade on delete set null;
alter table public.channels add column if not exists quality          text check (quality in ('SD','HD','FHD','4K'));
alter table public.channels drop constraint if exists channels_quality_check;
alter table public.channels add constraint channels_quality_check check (quality in ('SD','HD','FHD','4K')) not valid;
alter table public.channels add column if not exists description      text check (length(description) <= 1000);
alter table public.channels drop constraint if exists channels_description_check;
alter table public.channels add constraint channels_description_check check (length(description) <= 1000) not valid;
alter table public.channels add column if not exists website          text;
alter table public.channels add column if not exists epg_id           text;
alter table public.channels add column if not exists is_published     boolean not null default true;
alter table public.channels add column if not exists is_featured      boolean not null default false;
alter table public.channels add column if not exists is_manual        boolean not null default false;
alter table public.channels add column if not exists prefer_app       boolean not null default false;
alter table public.channels add column if not exists hidden_reason    text check (hidden_reason in ('manual','duplicate','offline','reported','pending'));
alter table public.channels drop constraint if exists channels_hidden_reason_check;
alter table public.channels add constraint channels_hidden_reason_check check (hidden_reason in ('manual','duplicate','offline','reported','pending')) not valid;
alter table public.channels add column if not exists duplicate_of     uuid references public.channels(id) on delete set null;
alter table public.channels add column if not exists published_at     timestamptz;
alter table public.channels add column if not exists dup_key          text;
alter table public.channels add column if not exists sort_order       integer not null default 0;
alter table public.channels add column if not exists created_at       timestamptz not null default now();
alter table public.channels add column if not exists updated_at       timestamptz not null default now();

-- ─── 5) روابط البث (سيرفرات القناة) ────────────────────────────────────────
create table if not exists public.streams (
  id              uuid primary key default gen_random_uuid(),
  channel_id      uuid not null references public.channels(id) on delete cascade,
  source_id       uuid references public.playlist_sources(id) on delete cascade,  -- null = رابط يدوي
  url             text not null unique check (url ~ '^https?://' and length(url) <= 2000),
  host            text generated always as (lower(substring(url from '^https?://([^/:?#]+)'))) stored,
  label           text,                                               -- اسم السيرفر الظاهر (اختياري)
  quality         text,
  priority        integer not null default 0,                         -- الأصغر يُجرَّب أولًا
  is_active       boolean not null default true,
  status          text not null default 'unknown' check (status in ('unknown','online','offline')),
  http_status     integer,
  response_ms     integer,
  fail_count      integer not null default 0,
  last_error      text,
  last_checked_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.streams add column if not exists channel_id      uuid not null references public.channels(id) on delete cascade;
alter table public.streams add column if not exists source_id       uuid references public.playlist_sources(id) on delete cascade;
alter table public.streams add column if not exists url             text not null unique check (url ~ '^https?://' and length(url) <= 2000);
alter table public.streams drop constraint if exists streams_url_check;
alter table public.streams add constraint streams_url_check check (url ~ '^https?://' and length(url) <= 2000) not valid;
alter table public.streams add column if not exists host            text generated always as (lower(substring(url from '^https?://([^/:?#]+)'))) stored;
alter table public.streams add column if not exists label           text;
alter table public.streams add column if not exists quality         text;
alter table public.streams add column if not exists priority        integer not null default 0;
alter table public.streams add column if not exists is_active       boolean not null default true;
alter table public.streams add column if not exists status          text not null default 'unknown' check (status in ('unknown','online','offline'));
alter table public.streams drop constraint if exists streams_status_check;
alter table public.streams add constraint streams_status_check check (status in ('unknown','online','offline')) not valid;
alter table public.streams add column if not exists http_status     integer;
alter table public.streams add column if not exists response_ms     integer;
alter table public.streams add column if not exists fail_count      integer not null default 0;
alter table public.streams add column if not exists last_error      text;
alter table public.streams add column if not exists last_checked_at timestamptz;
alter table public.streams add column if not exists created_at      timestamptz not null default now();
alter table public.streams add column if not exists updated_at      timestamptz not null default now();

-- ─── 6) بلاغات المشاهدين ────────────────────────────────────────────────────
create table if not exists public.reports (
  id         bigint generated always as identity primary key,
  channel_id uuid not null references public.channels(id) on delete cascade,
  stream_id  uuid references public.streams(id) on delete set null,
  reason     text not null check (reason in ('not_working','wrong_info','bad_quality','other')),
  note       text check (length(note) <= 500),
  status     text not null default 'open' check (status in ('open','resolved')),
  created_at timestamptz not null default now()
);
alter table public.reports add column if not exists channel_id uuid not null references public.channels(id) on delete cascade;
alter table public.reports add column if not exists stream_id  uuid references public.streams(id) on delete set null;
alter table public.reports add column if not exists reason     text not null check (reason in ('not_working','wrong_info','bad_quality','other'));
alter table public.reports drop constraint if exists reports_reason_check;
alter table public.reports add constraint reports_reason_check check (reason in ('not_working','wrong_info','bad_quality','other')) not valid;
alter table public.reports add column if not exists note       text check (length(note) <= 500);
alter table public.reports drop constraint if exists reports_note_check;
alter table public.reports add constraint reports_note_check check (length(note) <= 500) not valid;
alter table public.reports add column if not exists status     text not null default 'open' check (status in ('open','resolved'));
alter table public.reports drop constraint if exists reports_status_check;
alter table public.reports add constraint reports_status_check check (status in ('open','resolved')) not valid;
alter table public.reports add column if not exists created_at timestamptz not null default now();

-- ─── 7) الفهارس ─────────────────────────────────────────────────────────────
create index if not exists channels_pub_idx      on public.channels(is_published, sort_order, number);
create index if not exists channels_country_idx  on public.channels(country_code);
create index if not exists channels_category_idx on public.channels(category_slug);
create index if not exists channels_language_idx on public.channels(language_code);
create index if not exists channels_name_idx     on public.channels(lower(name));
create index if not exists streams_channel_idx   on public.streams(channel_id, priority);
create index if not exists streams_source_idx    on public.streams(source_id);
create index if not exists streams_status_idx    on public.streams(status);
create index if not exists reports_channel_idx   on public.reports(channel_id, status);

-- القنوات المنشورة قبل وجود تاريخ النشر: تاريخ نشرها = تاريخ إضافتها
update public.channels set published_at = created_at where is_published and hidden_reason is null and published_at is null;

-- ─── 8) دوال مساعدة ─────────────────────────────────────────────────────────
create function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists channels_touch on public.channels;
create trigger channels_touch before update on public.channels         for each row execute function public.touch_updated_at();
drop trigger if exists streams_touch on public.streams;
create trigger streams_touch  before update on public.streams          for each row execute function public.touch_updated_at();
drop trigger if exists sources_touch on public.playlist_sources;
create trigger sources_touch  before update on public.playlist_sources for each row execute function public.touch_updated_at();
drop trigger if exists settings_touch on public.site_settings;
create trigger settings_touch before update on public.site_settings    for each row execute function public.touch_updated_at();

-- بوابة المراجعة: أي قناة تُضاف لقاعدة البيانات — بأي طريقة (ملف SQL، استيراد M3U، استعادة نسخة،
-- إضافة عبر API) — لا تُنشر إلا بعد موافقة المدير من «قيد المراجعة».
-- الاستثناء الوحيد: القناة التي يضيفها المدير يدويًا من اللوحة (admin_create_channel) لأنه راجعها بنفسه.
create function public.channels_review_gate() returns trigger language plpgsql as $$
begin
  if new.is_published and coalesce(current_setting('mtc.review_bypass', true), '') <> 'on' then
    new.is_published := false;
    new.hidden_reason := 'pending';
  end if;
  return new;
end $$;
drop trigger if exists channels_review_gate on public.channels;
create trigger channels_review_gate before insert on public.channels for each row execute function public.channels_review_gate();

-- تاريخ النشر: يُسجَّل مرة واحدة عند أول ظهور للقناة للمشاهدين (إضافة يدوية أو موافقة من المراجعة)
-- ولا يتغير إذا أُخفيت القناة مؤقتًا ثم عادت — فلا تقفز القنوات القديمة إلى «مضافة حديثًا».
create function public.channels_stamp_published() returns trigger language plpgsql as $$
begin
  if new.is_published and new.hidden_reason is null and new.published_at is null then new.published_at := now(); end if;
  return new;
end $$;
drop trigger if exists channels_stamp_published on public.channels;
create trigger channels_stamp_published before insert or update on public.channels for each row execute function public.channels_stamp_published();

-- اسم مُطبَّع لكشف التكرار: "Al Jazeera (1080p) HD" → "aljazeera"
create function public.norm_name(n text) returns text language sql immutable as $$
  select regexp_replace(
           regexp_replace(lower(coalesce(n, '')), '\s*[\(\[][^\)\]]*[\)\]]', '', 'g'),
           '([[:space:]]|[-_.:''"!?&*/\\|،]|\m(hd|fhd|sd|uhd|4k|tv)\M)+', '', 'g')  -- نُبقي + لأن ATV و ATV+ قناتان مختلفتان
$$;

-- مفتاح كشف التكرار: الاسم المُطبَّع، إلا إذا قرر المدير أن القناة «ليست مكررة» (dup_key خاص بها)
-- فتبقى القناتان معًا ولا تُكشفان من جديد، بينما أي نسخة جديدة من الأصلية تُكشف كالمعتاد.
create function public.dup_key(c public.channels) returns text language sql immutable as $$
  select coalesce(c.dup_key, public.norm_name(c.name))
$$;

-- السيرفر = النطاق الرئيسي للرابط: "edge1.cdn.akamaized.net" → "akamaized.net"
create function public.server_of(h text) returns text language sql immutable as $$
  select regexp_replace(coalesce(h, ''), '^.*\.([^.]+\.[^.]+)$', '\1')
$$;

create or replace function public.is_mtc_admin() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid())
$$;

-- ─── 9) واجهات العرض للمشاهدين (قراءة فقط) ─────────────────────────────────
-- القنوات المنشورة التي لديها رابط واحد على الأقل غير معطّل
create view public.catalog as
select c.id, c.uid, c.epg_id, c.number, c.name, c.network, c.description, c.quality, c.is_featured, c.sort_order, c.published_at,
       case when c.logo_status = 'broken' then null else c.logo_url end as logo_url,
       c.country_code, co.name_ar as country_name, co.name_en as country_name_en, co.flag_url, co.is_arab, co.continent,
       c.category_slug, cat.name_ar as category_name, c.extra_categories,
       c.language_code, l.name_ar as language_name, c.prefer_app,
       s.server, s.stream_count, s.online
from public.channels c
join lateral (
  -- كل قناة منشورة لها رابط مُفعّل تظهر — الفحص استشاري لا يُخفي شيئًا (الموقع يحاول، والتطبيق يضمن التشغيل)
  select count(*)::int as stream_count,
         bool_or(st.status = 'online') as online,
         (array_agg(coalesce(st.label, public.server_of(st.host)) order by (st.status = 'online') desc, st.priority))[1] as server
  from public.streams st
  where st.channel_id = c.id and st.is_active
) s on s.stream_count > 0
left join public.countries  co  on co.code  = c.country_code
left join public.categories cat on cat.slug = c.category_slug
left join public.languages  l   on l.code   = c.language_code
where c.is_published;

-- روابط القنوات المنشورة (تُطلب عند التشغيل فقط)
create view public.catalog_streams as
select st.id, st.channel_id, st.url, st.quality, st.priority, st.status,
       coalesce(st.label, public.server_of(st.host)) as server
from public.streams st
join public.channels c on c.id = st.channel_id
where c.is_published and st.is_active;  -- كل الروابط المُفعّلة تُسلَّم للمشغّل (الفحص استشاري، والتطبيق يشغّل ما يعجز عنه المتصفح)

-- ─── 9ب) قائمة المراجعة (للمدير فقط: تحترم صلاحيات جدول القنوات) ──────────
-- كل قناة «بانتظار المراجعة» مع تصنيفها:
--   unchecked  روابطها لم تُفحص بعد        offline    لا يوجد رابط يعمل
--   duplicate  مكررة لقناة أخرى أفضل منها  logo       الشعار لا يعمل
--   incomplete بدون دولة                   ready      جاهزة للنشر
-- القناة «الأصلية» في كل مجموعة مكررة: المنشورة أولًا، ثم صاحبة روابط تعمل أكثر، ثم الرقم الأصغر.
create view public.review_queue with (security_invoker = true) as
with st as (
  select channel_id, count(*)::int as total,
         count(*) filter (where status = 'online')::int  as online,
         count(*) filter (where status = 'unknown')::int as unchecked
  from public.streams where is_active group by channel_id
), ranked as (
  select c.id, c.number, c.name, c.uid, c.logo_url, c.logo_status, c.quality, c.country_code, c.category_slug,
         c.language_code, c.is_published, c.hidden_reason, c.created_at,
         coalesce(st.total, 0) as total, coalesce(st.online, 0) as online, coalesce(st.unchecked, 0) as unchecked,
         first_value(c.id) over w as keeper,
         row_number() over w as rn
  from public.channels c left join st on st.channel_id = c.id
  where c.is_published or c.hidden_reason = 'pending'
  window w as (partition by public.dup_key(c), c.country_code
               order by c.is_published desc, coalesce(st.online, 0) > 0 desc, coalesce(st.online, 0) desc, c.number nulls last, c.id)
)
select id, number, name, uid, logo_url, logo_status, quality, country_code, category_slug, language_code, created_at,
       total, online, unchecked, case when rn > 1 then keeper end as duplicate_of,
       case when total = 0 then 'offline'
            when online = 0 and unchecked > 0 then 'unchecked'
            when online = 0 then 'offline'
            when rn > 1 then 'duplicate'
            when logo_status = 'broken' then 'logo'
            when country_code is null then 'incomplete'
            else 'ready' end as bucket
from ranked where hidden_reason = 'pending';

-- ─── 10) دوال لوحة الإدارة (تتحقق من صلاحية المشرف) ─────────────────────────
-- إحصاءات اللوحة في طلب واحد
create function public.admin_stats() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if not public.is_mtc_admin() then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'channels',        (select count(*) from channels),
    'published',       (select count(*) from channels where is_published),
    'hidden',          (select count(*) from channels where not is_published),
    'featured',        (select count(*) from channels where is_featured),
    'manual',          (select count(*) from channels where is_manual),
    'no_stream',       (select count(*) from channels c where not exists (select 1 from streams s where s.channel_id = c.id and s.is_active and s.status <> 'offline')),
    'streams',         (select count(*) from streams),
    'online',          (select count(*) from streams where status = 'online'),
    'offline',         (select count(*) from streams where status = 'offline'),
    'unchecked',       (select count(*) from streams where status = 'unknown'),
    'disabled',        (select count(*) from streams where not is_active),
    'slow',            (select count(*) from streams where is_active and status = 'online' and response_ms > 4000),
    'broken_logos',    (select count(*) from channels where logo_status = 'broken'),
    'sources',         (select count(*) from playlist_sources),
    'reports',         (select count(*) from reports where status = 'open'),
    'duplicates',      (select count(*) from (select 1 from channels c group by dup_key(c), country_code having count(*) > 1) d),
    'countries',       (select count(distinct country_code) from channels),
    'pending',         (select count(*) from channels where hidden_reason = 'pending'),
    'review',          (select coalesce(jsonb_object_agg(bucket, n), '{}') from (select bucket, count(*) as n from review_queue group by 1) r),
    'by_category',     (select coalesce(jsonb_agg(x order by x.n desc), '[]') from (select category_slug as slug, count(*) as n from channels group by 1) x),
    'by_country',      (select coalesce(jsonb_agg(x order by x.n desc), '[]') from (select country_code as code, count(*) as n from channels group by 1 order by 2 desc limit 12) x)
  );
end $$;

-- استيراد دفعة من الروابط: ينشئ القنوات الجديدة ويضيف روابطها. لا يغيّر تعديلات المشرف.
-- p_items: [{uid,name,logo,country,category,language,quality,url,label,network}]
create function public.admin_import(p_source uuid, p_items jsonb, p_publish boolean default true) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_channels int; v_streams int; v_next int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;

  insert into channels (uid, name, network, logo_url, country_code, category_slug, language_code, quality, is_published)
  select distinct on (x.uid) x.uid, left(x.name, 250), x.network, x.logo, co.code, coalesce(cat.slug, 'general'),
         coalesce(l.code, co.language_code), case when x.quality in ('SD','HD','FHD','4K') then x.quality end, p_publish
  from jsonb_to_recordset(p_items) as x(uid text, name text, network text, logo text, country text, category text, language text, quality text, url text, label text)
  left join countries  co  on co.code  = upper(x.country)
  left join categories cat on cat.slug = lower(x.category)
  left join languages  l   on l.code   = lower(x.language)
  where coalesce(x.uid, '') <> '' and coalesce(trim(x.name), '') <> ''
  order by x.uid
  on conflict (uid) do update set logo_url = coalesce(channels.logo_url, excluded.logo_url);
  get diagnostics v_channels = row_count;

  -- أرقام للقنوات الجديدة بعد آخر رقم
  select coalesce(max(number), 0) into v_next from channels;
  update channels c set number = v_next + n.rn
  from (select id, row_number() over (order by name) as rn from channels where number is null) n
  where c.id = n.id;

  insert into streams (channel_id, source_id, url, label, quality)
  select c.id, p_source, x.url, nullif(x.label, ''), x.quality
  from jsonb_to_recordset(p_items) as x(uid text, url text, label text, quality text)
  join channels c on c.uid = x.uid
  where x.url ~ '^https?://' and length(x.url) <= 2000
  on conflict (url) do update set source_id = coalesce(streams.source_id, excluded.source_id);
  get diagnostics v_streams = row_count;

  return jsonb_build_object('channels', v_channels, 'streams', v_streams);
end $$;

-- إنهاء الاستيراد: حذف روابط المصدر التي لم تعد في القائمة + القنوات التي بقيت بلا روابط
create function public.admin_finish_import(p_source uuid, p_urls text[]) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_removed int; v_orphans int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  delete from streams where source_id = p_source and not (url = any(p_urls));
  get diagnostics v_removed = row_count;
  delete from channels c where not c.is_manual and not exists (select 1 from streams s where s.channel_id = c.id);
  get diagnostics v_orphans = row_count;
  update playlist_sources set status = 'ready', last_error = null, last_import_at = now(),
    stream_count  = (select count(*) from streams where source_id = p_source),
    channel_count = (select count(distinct channel_id) from streams where source_id = p_source)
  where id = p_source;
  return jsonb_build_object('removed_streams', v_removed, 'removed_channels', v_orphans);
end $$;

-- حذف مصدر مع روابطه والقنوات التي لم يعد لها أي رابط
create function public.admin_delete_source(p_source uuid) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_streams int; v_channels int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  delete from streams where source_id = p_source;
  get diagnostics v_streams = row_count;
  delete from channels c where not c.is_manual and not exists (select 1 from streams s where s.channel_id = c.id);
  get diagnostics v_channels = row_count;
  delete from playlist_sources where id = p_source;
  return jsonb_build_object('streams', v_streams, 'channels', v_channels);
end $$;

-- عمليات التنظيف الجماعية
create function public.admin_cleanup(p_action text) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int := 0;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  case p_action
    when 'delete_offline_streams' then delete from streams where status = 'offline';
    when 'hide_dead_channels' then
      update channels c set is_published = false, hidden_reason = 'offline'
      where c.is_published and not exists (select 1 from streams s where s.channel_id = c.id and s.is_active and s.status <> 'offline');
    when 'delete_dead_channels' then
      delete from channels c where not exists (select 1 from streams s where s.channel_id = c.id and s.is_active and s.status <> 'offline');
    when 'clear_broken_logos' then update channels set logo_url = null, logo_status = 'unknown' where logo_status = 'broken';
    when 'reset_checks' then update streams set status = 'unknown', fail_count = 0, last_error = null, http_status = null, response_ms = null, last_checked_at = null where true;
    when 'delete_hidden' then delete from channels where not is_published;
    when 'delete_pending' then delete from channels where hidden_reason = 'pending';
    when 'delete_manual' then delete from channels where is_manual;
    when 'delete_all_channels' then delete from channels where true;
    when 'reset_all' then delete from channels where true; delete from playlist_sources where true; delete from reports where true;
    when 'clear_reports' then delete from reports where status = 'resolved';
    when 'refresh_counts' then
      update playlist_sources p set stream_count = (select count(*) from streams where source_id = p.id),
                                    channel_count = (select count(distinct channel_id) from streams where source_id = p.id) where true;
    else raise exception 'unknown action %', p_action;
  end case;
  get diagnostics n = row_count;
  return n;
end $$;

-- حفظ نتائج فحص الروابط: [{id, ok, status, ms, err}]
create function public.admin_record_checks(p_results jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update streams s set
    status = case when r.ok then 'online' else 'offline' end,
    http_status = r.status, response_ms = r.ms, last_error = nullif(r.err, ''),
    fail_count = case when r.ok then 0 else s.fail_count + 1 end,
    last_checked_at = now()
  from jsonb_to_recordset(p_results) as r(id uuid, ok boolean, status int, ms int, err text)
  where s.id = r.id;
  get diagnostics n = row_count;
  return n;
end $$;

-- حفظ نتائج فحص الشعارات: [{id, ok}]
create function public.admin_record_logos(p_results jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update channels c set logo_status = case when r.ok then 'ok' else 'broken' end
  from jsonb_to_recordset(p_results) as r(id uuid, ok boolean) where c.id = r.id;
  get diagnostics n = row_count;
  return n;
end $$;

-- مجموعات القنوات المكررة (نفس الاسم المُطبَّع ونفس الدولة)
create function public.admin_duplicates() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  return coalesce((
    select jsonb_agg(g order by g->>'name')
    from (
      select jsonb_build_object(
        'key', dup_key(c) || '|' || coalesce(c.country_code, ''),
        'name', min(c.name),
        'country', c.country_code,
        'channels', jsonb_agg(jsonb_build_object(
          'id', c.id, 'name', c.name, 'number', c.number, 'logo_url', c.logo_url, 'quality', c.quality,
          'is_published', c.is_published, 'is_featured', c.is_featured, 'uid', c.uid,
          'streams', (select count(*) from streams s where s.channel_id = c.id),
          'online',  (select count(*) from streams s where s.channel_id = c.id and s.status = 'online'))
          order by c.is_published desc, c.number)) as g
      from channels c
      group by dup_key(c), c.country_code
      having count(*) > 1
    ) d
  ), '[]'::jsonb);
end $$;

-- دمج قنوات مكررة في قناة واحدة (تنتقل الروابط ثم تُحذف المكررات)
create function public.admin_merge(p_keep uuid, p_remove uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update streams set channel_id = p_keep where channel_id = any(p_remove) and channel_id <> p_keep;
  update reports set channel_id = p_keep where channel_id = any(p_remove) and channel_id <> p_keep;
  delete from channels where id = any(p_remove) and id <> p_keep;
  get diagnostics n = row_count;
  return n;
end $$;

-- إخفاء المكررات مع الإشارة إلى القناة الأصلية
create function public.admin_hide_duplicates(p_keep uuid, p_hide uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update channels set is_published = false, hidden_reason = 'duplicate', duplicate_of = p_keep
  where id = any(p_hide) and id <> p_keep;
  get diagnostics n = row_count;
  return n;
end $$;

-- ─── نظام إعادة الترقيم المرن ───────────────────────────────────────────────
-- p_keys: أسس الترتيب بالأولوية، من القائمة المسموحة:
--   arab (العربية أولًا) · country (ترتيب الدول) · country_name (اسم الدولة أبجديًا) · category (الفئة)
--   language (اللغة) · featured (المميزة أولًا) · quality (الأعلى جودة أولًا) · online (الأكثر روابط تعمل)
--   name / name_desc (الاسم) · newest / oldest (تاريخ الإضافة) · sort_order (ترتيب الظهور) · current (الرقم الحالي)
-- p_start: أول رقم · p_block: إن كان > 0 تبدأ كل مجموعة (حسب أول أساس) من رقم مستدير (مضاعفات p_block)
-- p_published_first: المنشورة أولًا ثم غير المنشورة (المعلّقة والمخفية) في آخر القائمة
create function public.admin_renumber_plan(p_keys text[], p_start integer default 1, p_block integer default 0, p_published_first boolean default true)
returns table (id uuid, new_number integer)
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  k text; ord text[] := '{}'; grp text := null; sql text;
  map constant jsonb := jsonb_build_object(
    'arab',         jsonb_build_array('coalesce(co.is_arab, false) desc', 'coalesce(co.is_arab, false)::text'),
    'country',      jsonb_build_array('co.sort_order nulls last, co.name_ar nulls last', 'coalesce(c.country_code, ''-'')'),
    'country_name', jsonb_build_array('co.name_ar nulls last', 'coalesce(c.country_code, ''-'')'),
    'category',     jsonb_build_array('cat.sort_order nulls last, cat.name_ar nulls last', 'coalesce(c.category_slug, ''-'')'),
    'language',     jsonb_build_array('l.sort_order nulls last, l.name_ar nulls last', 'coalesce(c.language_code, ''-'')'),
    'featured',     jsonb_build_array('c.is_featured desc', 'c.is_featured::text'),
    'quality',      jsonb_build_array('case c.quality when ''4K'' then 4 when ''FHD'' then 3 when ''HD'' then 2 when ''SD'' then 1 else 0 end desc',
                                      'coalesce(c.quality, ''-'')'),
    'online',       jsonb_build_array('(select count(*) from streams s where s.channel_id = c.id and s.is_active and s.status = ''online'') desc', null),
    'name',         jsonb_build_array('lower(c.name)', null),
    'name_desc',    jsonb_build_array('lower(c.name) desc', null),
    'newest',       jsonb_build_array('c.created_at desc', null),
    'oldest',       jsonb_build_array('c.created_at', null),
    'sort_order',   jsonb_build_array('c.sort_order', null),
    'current',      jsonb_build_array('c.number nulls last', null));
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  if p_start is null or p_start < 1 then raise exception 'أول رقم يجب أن يكون 1 أو أكثر'; end if;
  if p_published_first then ord := ord || 'c.is_published desc'::text; end if;
  foreach k in array coalesce(p_keys, '{}') loop
    if not map ? k then raise exception 'أساس ترتيب غير معروف: %', k; end if;
    ord := ord || (map->k->>0);
    if grp is null and p_block > 0 then grp := map->k->>1; end if;   -- المجموعة = أول أساس قابل للتجميع
  end loop;
  ord := ord || 'c.number nulls last'::text || 'c.id'::text;          -- ترتيب ثابت عند التساوي

  sql := format($q$
    with base as (
      select c.id, %3$s as g, row_number() over (order by %1$s) as rn
      from channels c
      left join countries co on co.code = c.country_code
      left join categories cat on cat.slug = c.category_slug
      left join languages l on l.code = c.language_code
    ), grp as (
      select g, min(rn) as first_rn, count(*) as n, ceil(count(*)::numeric / %2$s)::int * %2$s as size from base group by g
    ), starts as (
      select g, first_rn, coalesce(sum(size) over (order by first_rn rows between unbounded preceding and 1 preceding), 0) as off from grp
    )
    select b.id, (%4$s + s.off + (row_number() over (partition by b.g order by b.rn)) - 1)::int
    from base b join starts s on s.g = b.g
  $q$, array_to_string(ord, ', '), greatest(p_block, 1),
       case when grp is null then '''all''' else format('(c.is_published::text || ''|'' || %s)', grp) end,
       p_start);
  -- بدون مجموعات: ترقيم متتالٍ مباشر
  if grp is null then
    sql := format('select c.id, (%2$s + row_number() over (order by %1$s) - 1)::int from channels c
      left join countries co on co.code = c.country_code left join categories cat on cat.slug = c.category_slug
      left join languages l on l.code = c.language_code', array_to_string(ord, ', '), p_start);
  end if;
  return query execute sql;
end $$;

-- معاينة قبل التطبيق: أول p_limit قناة بأرقامها القديمة والجديدة + عدد ما سيتغير + بدايات المجموعات
create function public.admin_renumber_preview(p_keys text[], p_start integer default 1, p_block integer default 0,
                                              p_published_first boolean default true, p_limit integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare r jsonb;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  with p as (select * from admin_renumber_plan(p_keys, p_start, p_block, p_published_first)),
  j as (select p.new_number, c.number as old_number, c.name, c.logo_url, c.is_published, c.hidden_reason, c.quality,
               co.name_ar as country, co.flag_url, cat.name_ar as category
        from p join channels c on c.id = p.id
        left join countries co on co.code = c.country_code left join categories cat on cat.slug = c.category_slug)
  select jsonb_build_object(
    'total',   (select count(*) from j),
    'changed', (select count(*) from j where old_number is distinct from new_number),
    'max',     (select max(new_number) from j),
    'rows',    coalesce((select jsonb_agg(x order by x.new_number) from (select * from j order by new_number limit p_limit) x), '[]'))
  into r;
  return r;
end $$;

-- التطبيق: يمسح الأرقام ثم يكتب الجديدة دفعة واحدة (الأرقام فريدة)
create function public.admin_renumber_apply(p_keys text[], p_start integer default 1, p_block integer default 0, p_published_first boolean default true)
returns integer language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  create temp table _plan on commit drop as select * from admin_renumber_plan(p_keys, p_start, p_block, p_published_first);
  update channels set number = null where number is not null;
  update channels c set number = p.new_number from _plan p where c.id = p.id;
  get diagnostics n = row_count;
  return n;
end $$;

-- إعادة الترقيم الافتراضية (زر سريع): العربية أولًا ← ترتيب الدول ← ترتيب الظهور ← المميزة ← الاسم
create function public.admin_renumber() returns integer
language sql security definer set search_path = public, pg_temp as $$
  select public.admin_renumber_apply(array['arab', 'country', 'sort_order', 'featured', 'name'], 1, 0, true)
$$;

-- قرارات المراجعة: approve نشر · reject حذف نهائي · merge دمج المكررة في أصلها (روابطها تصبح سيرفرات إضافية)
create function public.admin_review_apply(p_action text, p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int := 0; r record;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  case p_action
    when 'approve' then
      update channels set is_published = true, hidden_reason = null where id = any(p_ids) and hidden_reason = 'pending';
      get diagnostics n = row_count;
    when 'reject' then
      delete from channels where id = any(p_ids) and hidden_reason = 'pending';
      get diagnostics n = row_count;
    when 'merge' then
      for r in select id, duplicate_of from review_queue where id = any(p_ids) and duplicate_of is not null loop
        update streams set channel_id = r.duplicate_of where channel_id = r.id;
        update reports set channel_id = r.duplicate_of where channel_id = r.id;
        delete from channels where id = r.id;
        n := n + 1;
      end loop;
    else raise exception 'unknown action %', p_action;
  end case;
  return n;
end $$;

-- إضافة قناة يدويًا من اللوحة (تتجاوز بوابة المراجعة لأن المدير أدخلها بنفسه)
create function public.admin_create_channel(p_channel jsonb, p_url text) returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid; v_num int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  if coalesce(p_url, '') !~ '^https?://' then raise exception 'رابط البث غير صالح'; end if;
  perform set_config('mtc.review_bypass', 'on', true);
  v_num := coalesce((p_channel->>'number')::int, (select coalesce(max(number), 0) + 1 from channels));
  insert into channels (uid, epg_id, number, name, logo_url, network, website, description, category_slug, country_code, language_code,
                        quality, sort_order, is_published, is_featured, is_manual, hidden_reason)
  values ('manual:' || gen_random_uuid(), nullif(p_channel->>'epg_id', ''), v_num, p_channel->>'name', nullif(p_channel->>'logo_url', ''), nullif(p_channel->>'network', ''),
          nullif(p_channel->>'website', ''), nullif(p_channel->>'description', ''), coalesce(nullif(p_channel->>'category_slug', ''), 'general'),
          nullif(p_channel->>'country_code', ''), nullif(p_channel->>'language_code', ''), nullif(p_channel->>'quality', ''),
          coalesce((p_channel->>'sort_order')::int, 0), coalesce((p_channel->>'is_published')::boolean, true),
          coalesce((p_channel->>'is_featured')::boolean, false), true,
          case when coalesce((p_channel->>'is_published')::boolean, true) then null else 'manual' end)
  returning id into v_id;
  perform set_config('mtc.review_bypass', 'off', true);
  insert into streams (channel_id, url) values (v_id, p_url);
  return v_id;
end $$;

-- ─── الإضافة من البحث في iptv-org (صفحة «البحث في iptv-org» في اللوحة) ──────────
-- لكل قناة مختارة: إن كانت موجودة (نفس معرّف iptv-org أو قناة حددها المدير) تُضاف روابطها الجديدة إليها،
-- وإلا تُنشأ قناة جديدة. القنوات الجديدة تمر ببوابة المراجعة، إلا إذا اختار المدير «نشر مباشرة».
-- الروابط المكررة (موجودة في أي قناة) تُتجاهل، ونتيجة الفحص من المتصفح تُحفظ مع الرابط.
create function public.admin_iptv_add(p_items jsonb, p_publish boolean default false) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare it jsonb; v_id uuid; v_new int := 0; v_merged int := 0; v_links int := 0; n int; v_pr int; v_country text;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  for it in select * from jsonb_array_elements(coalesce(p_items, '[]')) loop
    v_id := nullif(it->>'target', '')::uuid;
    if v_id is null then select id into v_id from channels where uid = it->>'uid'; end if;
    if v_id is null then
      v_country := (select code from countries where code = upper(it->>'country'));
      if p_publish then perform set_config('mtc.review_bypass', 'on', true); end if;
      insert into channels (uid, number, name, alt_names, network, logo_url, country_code, category_slug, extra_categories,
                            language_code, quality, website, is_published, is_manual, prefer_app)
      values (it->>'uid', (select coalesce(max(number), 0) + 1 from channels), left(it->>'name', 250),
              array(select jsonb_array_elements_text(coalesce(it->'alt', '[]'))),
              nullif(it->>'network', ''), nullif(it->>'logo', ''), v_country,
              coalesce((select slug from categories where slug = it->>'category'), 'general'),
              array(select x from jsonb_array_elements_text(coalesce(it->'extra', '[]')) x where exists (select 1 from categories where slug = x)),
              coalesce((select code from languages where code = it->>'language'), (select language_code from countries where code = v_country)),
              case when it->>'quality' in ('SD', 'HD', 'FHD', '4K') then it->>'quality' end,
              nullif(it->>'website', ''), true, true, coalesce((it->>'prefer_app')::boolean, false))
      returning id into v_id;
      perform set_config('mtc.review_bypass', 'off', true);
      v_new := v_new + 1;
    else
      v_merged := v_merged + 1;
      if coalesce((it->>'prefer_app')::boolean, false) then update channels set prefer_app = true where id = v_id; end if;
    end if;
    select coalesce(max(priority) + 1, 0) into v_pr from streams where channel_id = v_id;
    insert into streams (channel_id, url, quality, priority, status, response_ms, last_checked_at)
    select v_id, s->>'url', nullif(s->>'quality', ''), v_pr + o::int - 1,
           case when s->>'status' in ('online', 'offline') then s->>'status' else 'unknown' end,
           nullif(s->>'ms', '')::int, case when s->>'status' in ('online', 'offline') then now() end
    from jsonb_array_elements(coalesce(it->'streams', '[]')) with ordinality as t(s, o)
    where s->>'url' ~ '^https://' and length(s->>'url') <= 2000
    on conflict (url) do nothing;
    get diagnostics n = row_count;
    v_links := v_links + n;
  end loop;
  return jsonb_build_object('created', v_new, 'merged', v_merged, 'streams', v_links);
end $$;

-- ─── الاستعادة من نسخة احتياطية (تُستدعى من اللوحة على دفعات) ───────────────
-- 1) تفريغ البيانات: القنوات والروابط والمصادر والبلاغات (+ الجداول المرجعية إن طُلب)
create function public.admin_restore_reset(p_refs boolean default false) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  delete from reports where true; delete from streams where true; delete from channels where true; delete from playlist_sources where true;
  if p_refs then delete from categories where true; delete from countries where true; delete from languages where true; end if;
end $$;

-- 2) إدخال دفعة صفوف لجدول واحد كما هي في النسخة. القنوات تمر ببوابة المراجعة (المنشورة تصبح «بانتظار المراجعة»).
create function public.admin_restore_rows(p_table text, p_rows jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare cols text; n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  if p_table not in ('languages', 'countries', 'categories', 'playlist_sources', 'channels', 'streams', 'reports', 'site_settings') then
    raise exception 'جدول غير مسموح: %', p_table;
  end if;
  -- الأعمدة القابلة للكتابة فقط (بدون المولّدة تلقائيًا مثل flag_url و host ومعرّف البلاغ)
  select string_agg(quote_ident(column_name), ', ' order by ordinal_position) into cols
  from information_schema.columns
  where table_schema = 'public' and table_name = p_table and is_generated = 'NEVER' and coalesce(identity_generation, '') <> 'ALWAYS'
    and not (p_table = 'channels' and column_name = 'duplicate_of')  -- تُربط لاحقًا عبر admin_restore_links
    and column_name in (select jsonb_object_keys(p_rows->0));          -- الأعمدة الغائبة تأخذ قيمتها الافتراضية
  if cols is null or jsonb_array_length(p_rows) = 0 then return 0; end if;
  execute format('insert into public.%I (%s) select %s from jsonb_populate_recordset(null::public.%I, $1) %s',
                 p_table, cols, cols, p_table,
                 case p_table when 'site_settings' then 'on conflict (key) do update set value = excluded.value, is_public = excluded.is_public'
                              when 'reports' then '' else 'on conflict do nothing' end)
  using p_rows;
  get diagnostics n = row_count;
  return n;
end $$;

-- 3) إعادة ربط «مكررة من» بعد إدخال كل القنوات: [{id, duplicate_of}]
create function public.admin_restore_links(p_links jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update channels c set duplicate_of = l.duplicate_of
  from jsonb_to_recordset(p_links) as l(id uuid, duplicate_of uuid)
  where c.id = l.id and exists (select 1 from channels k where k.id = l.duplicate_of);
  get diagnostics n = row_count;
  return n;
end $$;

-- «ليست مكررة — أبقِ الاثنين»: كل قناة محددة تأخذ مفتاح تكرار خاصًا بها فلا تُعامل كنسخة من غيرها
create function public.admin_mark_distinct(p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  update channels set dup_key = 'distinct:' || id::text, duplicate_of = null,
         hidden_reason = case when hidden_reason = 'duplicate' then 'manual' else hidden_reason end
  where id = any(p_ids);
  get diagnostics n = row_count;
  return n;
end $$;

-- التحكم بنتائج فحص الروابط: enable تفعيل · disable تعطيل (يبقى ولا يُستخدم) · delete حذف · reset إعادة لحالة «لم يُفحص»
create function public.admin_stream_action(p_action text, p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  case p_action
    when 'enable'  then update streams set is_active = true  where id = any(p_ids);
    when 'disable' then update streams set is_active = false where id = any(p_ids);
    when 'delete'  then delete from streams where id = any(p_ids);
    when 'reset'   then update streams set status = 'unknown', fail_count = 0, last_error = null, http_status = null, response_ms = null, last_checked_at = null where id = any(p_ids);
    else raise exception 'unknown action %', p_action;
  end case;
  get diagnostics n = row_count;
  return n;
end $$;

-- ─── 11) الصلاحيات (RLS) ────────────────────────────────────────────────────
alter table public.admin_users      enable row level security;
alter table public.languages        enable row level security;
alter table public.countries        enable row level security;
alter table public.categories       enable row level security;
alter table public.playlist_sources enable row level security;
alter table public.channels         enable row level security;
alter table public.streams          enable row level security;
alter table public.reports          enable row level security;
alter table public.site_settings    enable row level security;

drop policy if exists "admin self" on public.admin_users;
create policy "admin self" on public.admin_users for select to authenticated using (user_id = (select auth.uid()));

-- الجداول المرجعية: الكل يقرأ الظاهر، المشرف يعدّل
drop policy if exists "anon read" on public.languages;
create policy "anon read" on public.languages  for select to anon using (is_visible);
drop policy if exists "anon read" on public.countries;
create policy "anon read" on public.countries  for select to anon using (is_visible);
drop policy if exists "anon read" on public.categories;
create policy "anon read" on public.categories for select to anon using (is_visible);
drop policy if exists "auth read" on public.languages;
create policy "auth read" on public.languages  for select to authenticated using (is_visible or (select public.is_mtc_admin()));
drop policy if exists "auth read" on public.countries;
create policy "auth read" on public.countries  for select to authenticated using (is_visible or (select public.is_mtc_admin()));
drop policy if exists "auth read" on public.categories;
create policy "auth read" on public.categories for select to authenticated using (is_visible or (select public.is_mtc_admin()));
drop policy if exists "admin write" on public.languages;
create policy "admin write" on public.languages  for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));
drop policy if exists "admin write" on public.countries;
create policy "admin write" on public.countries  for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));
drop policy if exists "admin write" on public.categories;
create policy "admin write" on public.categories for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));

-- القنوات والروابط والمصادر: للمشرف فقط (المشاهد يقرأ عبر catalog و catalog_streams)
drop policy if exists "admin all" on public.playlist_sources;
create policy "admin all" on public.playlist_sources for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));
drop policy if exists "admin all" on public.channels;
create policy "admin all" on public.channels         for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));
drop policy if exists "admin all" on public.streams;
create policy "admin all" on public.streams          for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));

-- الإعدادات: الزائر يقرأ العامة فقط، المشرف يدير الكل (الجدول دائم فنحذف السياسات قبل إعادة إنشائها)
drop policy if exists "public read" on public.site_settings;
drop policy if exists "auth read" on public.site_settings;
drop policy if exists "admin all" on public.site_settings;
drop policy if exists "public read" on public.site_settings;
create policy "public read" on public.site_settings for select to anon using (is_public);
drop policy if exists "auth read" on public.site_settings;
create policy "auth read" on public.site_settings for select to authenticated using (is_public or (select public.is_mtc_admin()));
drop policy if exists "admin all" on public.site_settings;
create policy "admin all" on public.site_settings for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));

-- البلاغات: أي زائر يرسل بلاغًا، المشرف يدير
drop policy if exists "anyone report" on public.reports;
create policy "anyone report" on public.reports for insert to anon, authenticated with check (status = 'open');
drop policy if exists "admin all" on public.reports;
create policy "admin all" on public.reports for all to authenticated using ((select public.is_mtc_admin())) with check ((select public.is_mtc_admin()));

revoke all on public.admin_users, public.languages, public.countries, public.categories,
  public.playlist_sources, public.channels, public.streams, public.reports, public.site_settings from anon, authenticated;
grant select on public.languages, public.countries, public.categories to anon, authenticated;
grant insert, update, delete on public.languages, public.countries, public.categories to authenticated;
grant select on public.admin_users to authenticated;
grant select, insert, update, delete on public.playlist_sources, public.channels, public.streams to authenticated;
grant insert on public.reports to anon, authenticated;
grant select, update, delete on public.reports to authenticated;
grant select on public.catalog, public.catalog_streams to anon, authenticated;
grant select on public.site_settings to anon, authenticated;
grant insert, update, delete on public.site_settings to authenticated;
revoke all on public.review_queue from anon; grant select on public.review_queue to authenticated;

revoke execute on all functions in schema public from public, anon;
grant execute on function public.is_mtc_admin(), public.admin_stats(), public.admin_import(uuid, jsonb, boolean),
  public.admin_finish_import(uuid, text[]), public.admin_delete_source(uuid), public.admin_cleanup(text),
  public.admin_record_checks(jsonb), public.admin_record_logos(jsonb), public.admin_duplicates(),
  public.admin_merge(uuid, uuid[]), public.admin_hide_duplicates(uuid, uuid[]), public.admin_renumber(),
  public.admin_review_apply(text, uuid[]), public.admin_create_channel(jsonb, text), public.admin_restore_reset(boolean),
  public.admin_restore_rows(text, jsonb), public.admin_restore_links(jsonb),
  public.admin_mark_distinct(uuid[]), public.admin_stream_action(text, uuid[]),
  public.admin_renumber_plan(text[], integer, integer, boolean), public.admin_renumber_preview(text[], integer, integer, boolean, integer),
  public.admin_renumber_apply(text[], integer, integer, boolean), public.admin_iptv_add(jsonb, boolean) to authenticated;
grant execute on function public.norm_name(text), public.server_of(text), public.touch_updated_at() to anon, authenticated;
grant execute on function public.dup_key(public.channels) to authenticated;

-- إعدادات افتراضية: تُضاف مرة واحدة فقط ولا تُستبدل عند إعادة التشغيل
insert into public.site_settings (key, value, is_public) values
  ('hero', '{"channel_id": null}', true),
  ('proxy', '{"url": "", "hosts": []}', true),  -- وسيط البث للنطاقات المحمية (يُضبط من لوحة الإدارة)
  ('developer', '{"name_ar": "أنيس عدوان", "name_en": "Anees Adwan", "social": {
     "facebook": "AneesAdwan", "instagram": "AneesAdwan", "linkedin": "AneesAdwan", "snapchat": "AneesAdwan",
     "threads": "AneesAdwan", "x": "AneesAdwan", "tiktok": "AneesAdwan", "pinterest": "AneesAdwan",
     "whatsapp": "+970599273296", "telegram": "+970599273296"}}', true)
on conflict (key) do nothing;

-- ─── 12) البيانات المرجعية (مولّدة من iptv-org — لا تعدّلها يدويًا هنا) ─────
-- @@REFERENCE_DATA_START
-- اللغات
insert into public.languages (code, name_ar, name_en, sort_order) values
  ('ach', 'الأكولية', 'Acoli', 100),
  ('afr', 'الأفريقانية', 'Afrikaans', 100),
  ('aii', 'aii', 'Assyrian Neo-Aramaic', 100),
  ('amh', 'الأمهرية', 'Amharic', 100),
  ('ara', 'العربية', 'Arabic', 1),
  ('arz', 'arz', 'Egyptian Arabic', 100),
  ('asm', 'الأسامية', 'Assamese', 100),
  ('aym', 'الأيمارا', 'Aymara', 100),
  ('aze', 'الأذربيجانية', 'Azerbaijani', 100),
  ('bak', 'الباشكيرية', 'Bashkir', 100),
  ('bel', 'البيلاروسية', 'Belarusian', 100),
  ('ben', 'البنغالية', 'Bengali', 100),
  ('bho', 'البهوجبورية', 'Bhojpuri', 100),
  ('bis', 'البيسلامية', 'Bislama', 100),
  ('bjz', 'bjz', 'Baruga', 100),
  ('bos', 'البوسنية', 'Bosnian', 100),
  ('bul', 'البلغارية', 'Bulgarian', 100),
  ('bwg', 'bwg', 'Barwe', 100),
  ('cal', 'cal', 'Carolinian', 100),
  ('cat', 'الكتالانية', 'Catalan', 100),
  ('ces', 'التشيكية', 'Czech', 100),
  ('cha', 'التشامورو', 'Chamorro', 100),
  ('cmn', 'الصينية', 'Mandarin Chinese', 100),
  ('cnr', 'الصربية (الجبل الأسود)', 'Montenegrin', 100),
  ('crs', 'الفرنسية الكريولية السيشيلية', 'Seselwa Creole French', 100),
  ('dan', 'الدانمركية', 'Danish', 100),
  ('deu', 'الألمانية', 'German', 100),
  ('div', 'المالديفية', 'Dhivehi', 100),
  ('dzo', 'دزونكا', 'Dzongkha', 100),
  ('ell', 'اليونانية', 'Greek', 100),
  ('eng', 'الإنجليزية', 'English', 2),
  ('est', 'الإستونية', 'Estonian', 100),
  ('eus', 'الباسكية', 'Basque', 100),
  ('far', 'far', 'Fataleka', 100),
  ('fas', 'الفارسية', 'Persian', 100),
  ('fin', 'الفنلندية', 'Finnish', 100),
  ('fra', 'الفرنسية', 'French', 3),
  ('gle', 'الأيرلندية', 'Irish', 100),
  ('glg', 'الجاليكية', 'Galician', 100),
  ('gom', 'الكونكانية', 'Goan Konkani', 100),
  ('grn', 'الغوارانية', 'Guarani', 100),
  ('guj', 'الغوجاراتية', 'Gujarati', 100),
  ('heb', 'العبرية', 'Hebrew', 100),
  ('hin', 'الهندية', 'Hindi', 100),
  ('hmn', 'الهمونجية', 'Hmong', 100),
  ('hrv', 'الكرواتية', 'Croatian', 100),
  ('hun', 'الهنغارية', 'Hungarian', 100),
  ('hye', 'الأرمنية', 'Armenian', 100),
  ('ind', 'الإندونيسية', 'Indonesian', 100),
  ('isl', 'الأيسلندية', 'Icelandic', 100),
  ('ita', 'الإيطالية', 'Italian', 100),
  ('its', 'its', 'Isekiri', 100),
  ('jpn', 'اليابانية', 'Japanese', 100),
  ('kal', 'الكالاليست', 'Greenlandic', 100),
  ('kan', 'الكانادا', 'Kannada', 100),
  ('kat', 'الجورجية', 'Georgian', 100),
  ('kaz', 'الكازاخستانية', 'Kazakh', 100),
  ('khm', 'الخميرية', 'Khmer', 100),
  ('kin', 'الكينيارواندا', 'Kinyarwanda', 100),
  ('kir', 'القيرغيزية', 'Kirghiz', 100),
  ('kok', 'الكونكانية', 'Konkani (macrolanguage)', 100),
  ('koo', 'koo', 'Konzo', 100),
  ('kor', 'الكورية', 'Korean', 100),
  ('kur', 'الكردية', 'Kurdish', 100),
  ('lao', 'اللاوية', 'Lao', 100),
  ('lav', 'اللاتفية', 'Latvian', 100),
  ('lit', 'الليتوانية', 'Lithuanian', 100),
  ('ltz', 'اللكسمبورغية', 'Letzeburgesch', 100),
  ('lug', 'الغاندا', 'Ganda', 100),
  ('lus', 'الميزو', 'Lushai', 100),
  ('mal', 'المالايالامية', 'Malayalam', 100),
  ('mar', 'الماراثية', 'Marathi', 100),
  ('mkd', 'المقدونية', 'Macedonian', 100),
  ('mlt', 'المالطية', 'Maltese', 100),
  ('mon', 'المنغولية', 'Mongolian', 100),
  ('mos', 'الموسي', 'Mossi', 100),
  ('mri', 'الماورية', 'Maori', 100),
  ('msa', 'الماليزية', 'Malay', 100),
  ('mya', 'البورمية', 'Burmese', 100),
  ('nep', 'النيبالية', 'Nepali', 100),
  ('nld', 'الهولندية', 'Dutch', 100),
  ('nor', 'النرويجية', 'Norwegian', 100),
  ('nyn', 'النيانكول', 'Nyankole', 100),
  ('ori', 'الأورية', 'Oriya (macrolanguage)', 100),
  ('ory', 'الأورية', 'Odia', 100),
  ('pan', 'البنجابية', 'Panjabi', 100),
  ('pap', 'البابيامينتو', 'Papiamento', 100),
  ('pol', 'البولندية', 'Polish', 100),
  ('por', 'البرتغالية', 'Portuguese', 100),
  ('prd', 'prd', 'Dari (Parsi)', 100),
  ('pus', 'البشتو', 'Pashto', 100),
  ('ron', 'الرومانية', 'Romanian', 100),
  ('rus', 'الروسية', 'Russian', 100),
  ('sah', 'الساخيّة', 'Yakut', 100),
  ('sin', 'السنهالية', 'Sinhala', 100),
  ('slk', 'السلوفاكية', 'Slovak', 100),
  ('slv', 'السلوفانية', 'Slovenian', 100),
  ('snd', 'السندية', 'Sindhi', 100),
  ('som', 'الصومالية', 'Somali', 100),
  ('spa', 'الإسبانية', 'Spanish', 100),
  ('sqi', 'الألبانية', 'Albanian', 100),
  ('srp', 'الصربية', 'Serbian', 100),
  ('swa', 'السواحلية', 'Swahili', 100),
  ('swe', 'السويدية', 'Swedish', 100),
  ('tam', 'التاميلية', 'Tamil', 100),
  ('tel', 'التيلوغوية', 'Telugu', 100),
  ('tgl', 'الفلبينية', 'Tagalog', 100),
  ('tha', 'التايلاندية', 'Thai', 100),
  ('tir', 'التغرينية', 'Tigrinya', 100),
  ('tur', 'التركية', 'Turkish', 100),
  ('uig', 'الأويغورية', 'Uighur', 100),
  ('ukr', 'الأوكرانية', 'Ukrainian', 100),
  ('urd', 'الأوردية', 'Urdu', 100),
  ('uzb', 'الأوزبكية', 'Uzbek', 100),
  ('vie', 'الفيتنامية', 'Vietnamese', 100),
  ('wol', 'الولوفية', 'Wolof', 100),
  ('yor', 'اليوروبا', 'Yoruba', 100),
  ('yue', 'الكَنْتُونية', 'Yue Chinese', 100),
  ('zgh', 'التمازيغية المغربية القياسية', 'Standard Moroccan Tamazight', 100),
  ('zho', 'الصينية', 'Chinese', 100) on conflict do nothing;

-- الدول
insert into public.countries (code, name_ar, name_en, flag_emoji, continent, is_arab, language_code, sort_order) values
  ('AF', 'أفغانستان', 'Afghanistan', '🇦🇫', 'asia', false, 'pus', 100),
  ('AX', 'جزر آلاند', 'Aland', '🇦🇽', null, false, 'swe', 100),
  ('AL', 'ألبانيا', 'Albania', '🇦🇱', 'europe', false, 'sqi', 100),
  ('DZ', 'الجزائر', 'Algeria', '🇩🇿', 'africa', true, 'ara', 17),
  ('AS', 'ساموا الأمريكية', 'American Samoa', '🇦🇸', 'oceania', false, 'eng', 100),
  ('AD', 'أندورا', 'Andorra', '🇦🇩', 'europe', false, 'cat', 100),
  ('AO', 'أنغولا', 'Angola', '🇦🇴', 'africa', false, 'por', 100),
  ('AI', 'أنغويلا', 'Anguilla', '🇦🇮', 'americas', false, 'eng', 100),
  ('AQ', 'أنتاركتيكا', 'Antarctica', '🇦🇶', null, false, 'eng', 100),
  ('AG', 'أنتيغوا وبربودا', 'Antigua and Barbuda', '🇦🇬', 'americas', false, 'eng', 100),
  ('AR', 'الأرجنتين', 'Argentina', '🇦🇷', 'americas', false, 'grn', 100),
  ('AM', 'أرمينيا', 'Armenia', '🇦🇲', 'europe', false, 'hye', 100),
  ('AW', 'أروبا', 'Aruba', '🇦🇼', 'americas', false, 'nld', 100),
  ('AU', 'أستراليا', 'Australia', '🇦🇺', 'oceania', false, 'eng', 100),
  ('AT', 'النمسا', 'Austria', '🇦🇹', 'europe', false, 'deu', 100),
  ('AZ', 'أذربيجان', 'Azerbaijan', '🇦🇿', 'europe', false, 'aze', 100),
  ('BS', 'جزر البهاما', 'Bahamas', '🇧🇸', 'americas', false, 'eng', 100),
  ('BH', 'البحرين', 'Bahrain', '🇧🇭', 'asia', true, 'ara', 6),
  ('BD', 'بنغلاديش', 'Bangladesh', '🇧🇩', 'asia', false, 'ben', 100),
  ('BB', 'بربادوس', 'Barbados', '🇧🇧', 'americas', false, 'eng', 100),
  ('BY', 'بيلاروس', 'Belarus', '🇧🇾', 'europe', false, 'bel', 100),
  ('BE', 'بلجيكا', 'Belgium', '🇧🇪', 'europe', false, 'deu', 100),
  ('BZ', 'بليز', 'Belize', '🇧🇿', 'americas', false, 'bjz', 100),
  ('BJ', 'بنين', 'Benin', '🇧🇯', 'africa', false, 'fra', 100),
  ('BM', 'برمودا', 'Bermuda', '🇧🇲', 'americas', false, 'eng', 100),
  ('BT', 'بوتان', 'Bhutan', '🇧🇹', 'asia', false, 'dzo', 100),
  ('BO', 'بوليفيا', 'Bolivia', '🇧🇴', 'americas', false, 'aym', 100),
  ('BQ', 'هولندا الكاريبية', 'Bonaire', '🇧🇶', null, false, 'eng', 100),
  ('BA', 'البوسنة والهرسك', 'Bosnia and Herzegovina', '🇧🇦', 'europe', false, 'bos', 100),
  ('BW', 'بوتسوانا', 'Botswana', '🇧🇼', 'africa', false, 'eng', 100),
  ('BV', 'جزيرة بوفيه', 'Bouvet Island', '🇧🇻', 'americas', false, 'nor', 100),
  ('BR', 'البرازيل', 'Brazil', '🇧🇷', 'americas', false, 'por', 100),
  ('IO', 'الإقليم البريطاني في المحيط الهندي', 'British Indian Ocean Territory', '🇮🇴', null, false, 'eng', 100),
  ('VG', 'جزر فيرجن البريطانية', 'British Virgin Islands', '🇻🇬', 'americas', false, 'eng', 100),
  ('BN', 'بروناي', 'Brunei', '🇧🇳', 'asia', false, 'msa', 100),
  ('BG', 'بلغاريا', 'Bulgaria', '🇧🇬', 'europe', false, 'bul', 100),
  ('BF', 'بوركينا فاسو', 'Burkina Faso', '🇧🇫', 'africa', false, 'fra', 100),
  ('BI', 'بوروندي', 'Burundi', '🇧🇮', 'africa', false, 'fra', 100),
  ('KH', 'كمبوديا', 'Cambodia', '🇰🇭', 'asia', false, 'khm', 100),
  ('CM', 'الكاميرون', 'Cameroon', '🇨🇲', 'africa', false, 'eng', 100),
  ('CA', 'كندا', 'Canada', '🇨🇦', 'americas', false, 'eng', 100),
  ('CV', 'الرأس الأخضر', 'Cape Verde', '🇨🇻', 'africa', false, 'por', 100),
  ('KY', 'جزر كايمان', 'Cayman Islands', '🇰🇾', 'americas', false, 'eng', 100),
  ('CF', 'جمهورية أفريقيا الوسطى', 'Central African Republic', '🇨🇫', 'africa', false, 'fra', 100),
  ('TD', 'تشاد', 'Chad', '🇹🇩', 'africa', false, 'ara', 100),
  ('CL', 'تشيلي', 'Chile', '🇨🇱', 'americas', false, 'spa', 100),
  ('CN', 'الصين', 'China', '🇨🇳', 'asia', false, 'zho', 100),
  ('CX', 'جزيرة كريسماس', 'Christmas Island', '🇨🇽', null, false, 'eng', 100),
  ('CC', 'جزر كوكوس (كيلينغ)', 'Cocos (Keeling) Islands', '🇨🇨', null, false, 'eng', 100),
  ('CO', 'كولومبيا', 'Colombia', '🇨🇴', 'americas', false, 'spa', 100),
  ('KM', 'جزر القمر', 'Comoros', '🇰🇲', 'africa', true, 'ara', 22),
  ('CK', 'جزر كوك', 'Cook Islands', '🇨🇰', 'oceania', false, 'eng', 100),
  ('CR', 'كوستاريكا', 'Costa Rica', '🇨🇷', 'americas', false, 'spa', 100),
  ('HR', 'كرواتيا', 'Croatia', '🇭🇷', 'europe', false, 'hrv', 100),
  ('CU', 'كوبا', 'Cuba', '🇨🇺', 'americas', false, 'spa', 100),
  ('CW', 'كوراساو', 'Curacao', '🇨🇼', 'americas', false, 'eng', 100),
  ('CY', 'قبرص', 'Cyprus', '🇨🇾', 'europe', false, 'ell', 100),
  ('CZ', 'التشيك', 'Czech Republic', '🇨🇿', 'europe', false, 'ces', 100),
  ('CD', 'الكونغو الديمقراطية', 'Democratic Republic of the Congo', '🇨🇩', 'africa', false, 'fra', 100),
  ('DK', 'الدانمرك', 'Denmark', '🇩🇰', 'europe', false, 'dan', 100),
  ('DJ', 'جيبوتي', 'Djibouti', '🇩🇯', 'africa', true, 'ara', 21),
  ('DM', 'دومينيكا', 'Dominica', '🇩🇲', 'americas', false, 'eng', 100),
  ('DO', 'جمهورية الدومينيكان', 'Dominican Republic', '🇩🇴', 'americas', false, 'spa', 100),
  ('TL', 'تيمور - ليشتي', 'East Timor', '🇹🇱', 'asia', false, 'por', 100),
  ('EC', 'الإكوادور', 'Ecuador', '🇪🇨', 'americas', false, 'spa', 100),
  ('EG', 'مصر', 'Egypt', '🇪🇬', 'africa', true, 'ara', 2),
  ('SV', 'السلفادور', 'El Salvador', '🇸🇻', 'americas', false, 'spa', 100),
  ('GQ', 'غينيا الاستوائية', 'Equatorial Guinea', '🇬🇶', 'africa', false, 'fra', 100),
  ('ER', 'إريتريا', 'Eritrea', '🇪🇷', 'africa', false, 'ara', 100),
  ('EE', 'إستونيا', 'Estonia', '🇪🇪', 'europe', false, 'est', 100),
  ('ET', 'إثيوبيا', 'Ethiopia', '🇪🇹', 'africa', false, 'amh', 100),
  ('FK', 'جزر فوكلاند', 'Falkland Islands', '🇫🇰', 'americas', false, 'eng', 100),
  ('FO', 'جزر فارو', 'Faroe Islands', '🇫🇴', null, false, 'dan', 100),
  ('FJ', 'فيجي', 'Fiji', '🇫🇯', 'oceania', false, 'eng', 100),
  ('FI', 'فنلندا', 'Finland', '🇫🇮', 'europe', false, 'fin', 100),
  ('FR', 'فرنسا', 'France', '🇫🇷', 'europe', false, 'fra', 100),
  ('GF', 'غويانا الفرنسية', 'French Guiana', '🇬🇫', 'americas', false, 'fra', 100),
  ('PF', 'بولينيزيا الفرنسية', 'French Polynesia', '🇵🇫', 'oceania', false, 'fra', 100),
  ('TF', 'الأقاليم الجنوبية الفرنسية', 'French Southern Territories', '🇹🇫', 'africa', false, 'fra', 100),
  ('GA', 'الغابون', 'Gabon', '🇬🇦', 'africa', false, 'fra', 100),
  ('GM', 'غامبيا', 'Gambia', '🇬🇲', 'africa', false, 'eng', 100),
  ('GE', 'جورجيا', 'Georgia', '🇬🇪', 'europe', false, 'kat', 100),
  ('DE', 'ألمانيا', 'Germany', '🇩🇪', 'europe', false, 'deu', 100),
  ('GH', 'غانا', 'Ghana', '🇬🇭', 'africa', false, 'eng', 100),
  ('GI', 'جبل طارق', 'Gibraltar', '🇬🇮', null, false, 'eng', 100),
  ('GR', 'اليونان', 'Greece', '🇬🇷', 'europe', false, 'ell', 100),
  ('GL', 'غرينلاند', 'Greenland', '🇬🇱', 'americas', false, 'kal', 100),
  ('GD', 'غرينادا', 'Grenada', '🇬🇩', 'americas', false, 'eng', 100),
  ('GP', 'غوادلوب', 'Guadeloupe', '🇬🇵', 'americas', false, 'fra', 100),
  ('GU', 'غوام', 'Guam', '🇬🇺', 'oceania', false, 'cha', 100),
  ('GT', 'غواتيمالا', 'Guatemala', '🇬🇹', 'americas', false, 'spa', 100),
  ('GG', 'غيرنزي', 'Guernsey', '🇬🇬', null, false, 'eng', 100),
  ('GN', 'غينيا', 'Guinea', '🇬🇳', 'africa', false, 'fra', 100),
  ('GW', 'غينيا بيساو', 'Guinea-Bissau', '🇬🇼', 'africa', false, 'por', 100),
  ('GY', 'غيانا', 'Guyana', '🇬🇾', 'americas', false, 'eng', 100),
  ('HT', 'هايتي', 'Haiti', '🇭🇹', 'americas', false, 'fra', 100),
  ('HM', 'جزيرة هيرد وجزر ماكدونالد', 'Heard Island and McDonald Islands', '🇭🇲', null, false, 'eng', 100),
  ('HN', 'هندوراس', 'Honduras', '🇭🇳', 'americas', false, 'spa', 100),
  ('HK', 'هونغ كونغ الصينية (منطقة إدارية خاصة)', 'Hong Kong', '🇭🇰', null, false, 'eng', 100),
  ('HU', 'هنغاريا', 'Hungary', '🇭🇺', 'europe', false, 'hun', 100),
  ('IS', 'آيسلندا', 'Iceland', '🇮🇸', 'europe', false, 'isl', 100),
  ('IN', 'الهند', 'India', '🇮🇳', 'asia', false, 'eng', 100),
  ('ID', 'إندونيسيا', 'Indonesia', '🇮🇩', 'asia', false, 'ind', 100),
  ('IR', 'إيران', 'Iran', '🇮🇷', 'asia', false, 'fas', 100),
  ('IQ', 'العراق', 'Iraq', '🇮🇶', 'asia', true, 'ara', 12),
  ('IE', 'أيرلندا', 'Ireland', '🇮🇪', 'europe', false, 'eng', 100),
  ('IM', 'جزيرة مان', 'Isle of Man', '🇮🇲', null, false, 'eng', 100),
  ('IL', 'إسرائيل', 'Israel', '🇮🇱', 'asia', false, 'ara', 100),
  ('IT', 'إيطاليا', 'Italy', '🇮🇹', 'europe', false, 'ita', 100),
  ('CI', 'ساحل العاج', 'Ivory Coast', '🇨🇮', 'africa', false, 'fra', 100),
  ('JM', 'جامايكا', 'Jamaica', '🇯🇲', 'americas', false, 'eng', 100),
  ('JP', 'اليابان', 'Japan', '🇯🇵', 'asia', false, 'jpn', 100),
  ('JE', 'جيرسي', 'Jersey', '🇯🇪', null, false, 'eng', 100),
  ('JO', 'الأردن', 'Jordan', '🇯🇴', 'asia', true, 'ara', 8),
  ('KZ', 'كازاخستان', 'Kazakhstan', '🇰🇿', 'europe', false, 'kaz', 100),
  ('KE', 'كينيا', 'Kenya', '🇰🇪', 'africa', false, 'eng', 100),
  ('KI', 'كيريباتي', 'Kiribati', '🇰🇮', 'oceania', false, 'eng', 100),
  ('XK', 'كوسوفو', 'Kosovo', '🇽🇰', null, false, 'sqi', 100),
  ('KW', 'الكويت', 'Kuwait', '🇰🇼', 'asia', true, 'ara', 5),
  ('KG', 'قيرغيزستان', 'Kyrgyzstan', '🇰🇬', 'asia', false, 'kir', 100),
  ('LA', 'لاوس', 'Laos', '🇱🇦', 'asia', false, 'lao', 100),
  ('LV', 'لاتفيا', 'Latvia', '🇱🇻', 'europe', false, 'lav', 100),
  ('LB', 'لبنان', 'Lebanon', '🇱🇧', 'asia', true, 'ara', 10),
  ('LS', 'ليسوتو', 'Lesotho', '🇱🇸', 'africa', false, 'eng', 100),
  ('LR', 'ليبيريا', 'Liberia', '🇱🇷', 'africa', false, 'eng', 100),
  ('LY', 'ليبيا', 'Libya', '🇱🇾', 'africa', true, 'ara', 15),
  ('LI', 'ليختنشتاين', 'Liechtenstein', '🇱🇮', 'europe', false, 'deu', 100),
  ('LT', 'ليتوانيا', 'Lithuania', '🇱🇹', 'europe', false, 'lit', 100),
  ('LU', 'لوكسمبورغ', 'Luxembourg', '🇱🇺', 'europe', false, 'deu', 100),
  ('MO', 'منطقة ماكاو الإدارية الخاصة', 'Macao', '🇲🇴', null, false, 'por', 100),
  ('MG', 'مدغشقر', 'Madagascar', '🇲🇬', 'africa', false, 'fra', 100),
  ('MW', 'ملاوي', 'Malawi', '🇲🇼', 'africa', false, 'eng', 100),
  ('MY', 'ماليزيا', 'Malaysia', '🇲🇾', 'asia', false, 'eng', 100),
  ('MV', 'جزر المالديف', 'Maldives', '🇲🇻', 'asia', false, 'div', 100),
  ('ML', 'مالي', 'Mali', '🇲🇱', 'africa', false, 'fra', 100),
  ('MT', 'مالطا', 'Malta', '🇲🇹', 'europe', false, 'eng', 100),
  ('MH', 'جزر مارشال', 'Marshall Islands', '🇲🇭', 'oceania', false, 'eng', 100),
  ('MQ', 'جزر المارتينيك', 'Martinique', '🇲🇶', 'americas', false, 'fra', 100),
  ('MR', 'موريتانيا', 'Mauritania', '🇲🇷', 'africa', true, 'ara', 19),
  ('MU', 'موريشيوس', 'Mauritius', '🇲🇺', 'africa', false, 'eng', 100),
  ('YT', 'مايوت', 'Mayotte', '🇾🇹', 'africa', false, 'fra', 100),
  ('MX', 'المكسيك', 'Mexico', '🇲🇽', 'americas', false, 'spa', 100),
  ('FM', 'ميكرونيزيا', 'Micronesia', '🇫🇲', 'oceania', false, 'eng', 100),
  ('MD', 'مولدوفا', 'Moldova', '🇲🇩', 'europe', false, 'ron', 100),
  ('MC', 'موناكو', 'Monaco', '🇲🇨', 'europe', false, 'fra', 100),
  ('MN', 'منغوليا', 'Mongolia', '🇲🇳', 'asia', false, 'mon', 100),
  ('ME', 'الجبل الأسود', 'Montenegro', '🇲🇪', 'europe', false, 'cnr', 100),
  ('MS', 'مونتسرات', 'Montserrat', '🇲🇸', 'americas', false, 'eng', 100),
  ('MA', 'المغرب', 'Morocco', '🇲🇦', 'africa', true, 'ara', 18),
  ('MZ', 'موزمبيق', 'Mozambique', '🇲🇿', 'africa', false, 'por', 100),
  ('MM', 'ميانمار (بورما)', 'Myanmar', '🇲🇲', 'asia', false, 'mya', 100),
  ('NA', 'ناميبيا', 'Namibia', '🇳🇦', 'africa', false, 'afr', 100),
  ('NR', 'ناورو', 'Nauru', '🇳🇷', 'oceania', false, 'eng', 100),
  ('NP', 'نيبال', 'Nepal', '🇳🇵', 'asia', false, 'nep', 100),
  ('NL', 'هولندا', 'Netherlands', '🇳🇱', 'europe', false, 'nld', 100),
  ('NC', 'كاليدونيا الجديدة', 'New Caledonia', '🇳🇨', 'oceania', false, 'fra', 100),
  ('NZ', 'نيوزيلندا', 'New Zealand', '🇳🇿', 'oceania', false, 'eng', 100),
  ('NI', 'نيكاراغوا', 'Nicaragua', '🇳🇮', 'americas', false, 'spa', 100),
  ('NE', 'النيجر', 'Niger', '🇳🇪', 'africa', false, 'fra', 100),
  ('NG', 'نيجيريا', 'Nigeria', '🇳🇬', 'africa', false, 'eng', 100),
  ('NU', 'نيوي', 'Niue', '🇳🇺', 'oceania', false, 'eng', 100),
  ('NF', 'جزيرة نورفولك', 'Norfolk Island', '🇳🇫', 'oceania', false, 'eng', 100),
  ('KP', 'كوريا الشمالية', 'North Korea', '🇰🇵', 'asia', false, 'kor', 100),
  ('MK', 'مقدونيا الشمالية', 'North Macedonia', '🇲🇰', 'europe', false, 'mkd', 100),
  ('MP', 'جزر ماريانا الشمالية', 'Northern Mariana Islands', '🇲🇵', 'oceania', false, 'cal', 100),
  ('NO', 'النرويج', 'Norway', '🇳🇴', 'europe', false, 'nor', 100),
  ('OM', 'عُمان', 'Oman', '🇴🇲', 'asia', true, 'ara', 7),
  ('PK', 'باكستان', 'Pakistan', '🇵🇰', 'asia', false, 'eng', 100),
  ('PW', 'بالاو', 'Palau', '🇵🇼', 'oceania', false, 'eng', 100),
  ('PS', 'فلسطين', 'Palestine', '🇵🇸', 'asia', true, 'ara', 9),
  ('PA', 'بنما', 'Panama', '🇵🇦', 'americas', false, 'spa', 100),
  ('PG', 'بابوا غينيا الجديدة', 'Papua New Guinea', '🇵🇬', 'oceania', false, 'eng', 100),
  ('PY', 'باراغواي', 'Paraguay', '🇵🇾', 'americas', false, 'grn', 100),
  ('PE', 'بيرو', 'Peru', '🇵🇪', 'americas', false, 'aym', 100),
  ('PH', 'الفلبين', 'Philippines', '🇵🇭', 'asia', false, 'eng', 100),
  ('PN', 'جزر بيتكيرن', 'Pitcairn Islands', '🇵🇳', 'oceania', false, 'eng', 100),
  ('PL', 'بولندا', 'Poland', '🇵🇱', 'europe', false, 'pol', 100),
  ('PT', 'البرتغال', 'Portugal', '🇵🇹', 'europe', false, 'por', 100),
  ('PR', 'بورتوريكو', 'Puerto Rico', '🇵🇷', 'americas', false, 'eng', 100),
  ('QA', 'قطر', 'Qatar', '🇶🇦', 'asia', true, 'ara', 4),
  ('CG', 'الكونغو', 'Republic of the Congo', '🇨🇬', 'africa', false, 'fra', 100),
  ('RO', 'رومانيا', 'Romania', '🇷🇴', 'europe', false, 'ron', 100),
  ('RU', 'روسيا', 'Russia', '🇷🇺', 'europe', false, 'rus', 100),
  ('RW', 'رواندا', 'Rwanda', '🇷🇼', 'africa', false, 'eng', 100),
  ('RE', 'روينيون', 'Reunion', '🇷🇪', 'africa', false, 'fra', 100),
  ('BL', 'سان بارتليمي', 'Saint Barthélemy', '🇧🇱', 'americas', false, 'fra', 100),
  ('SH', 'سانت هيلينا', 'Saint Helena', '🇸🇭', 'africa', false, 'eng', 100),
  ('KN', 'سانت كيتس ونيفيس', 'Saint Kitts and Nevis', '🇰🇳', 'americas', false, 'eng', 100),
  ('LC', 'سانت لوسيا', 'Saint Lucia', '🇱🇨', 'americas', false, 'eng', 100),
  ('MF', 'سان مارتن', 'Saint Martin', '🇲🇫', 'americas', false, 'fra', 100),
  ('PM', 'سان بيير ومكويلون', 'Saint Pierre and Miquelon', '🇵🇲', 'americas', false, 'fra', 100),
  ('VC', 'سانت فنسنت وجزر غرينادين', 'Saint Vincent and the Grenadines', '🇻🇨', 'americas', false, 'eng', 100),
  ('WS', 'ساموا', 'Samoa', '🇼🇸', 'oceania', false, 'eng', 100),
  ('SM', 'سان مارينو', 'San Marino', '🇸🇲', 'europe', false, 'ita', 100),
  ('SA', 'السعودية', 'Saudi Arabia', '🇸🇦', 'asia', true, 'ara', 1),
  ('SN', 'السنغال', 'Senegal', '🇸🇳', 'africa', false, 'fra', 100),
  ('RS', 'صربيا', 'Serbia', '🇷🇸', 'europe', false, 'srp', 100),
  ('SC', 'سيشل', 'Seychelles', '🇸🇨', 'africa', false, 'crs', 100),
  ('SL', 'سيراليون', 'Sierra Leone', '🇸🇱', 'africa', false, 'eng', 100),
  ('SG', 'سنغافورة', 'Singapore', '🇸🇬', 'asia', false, 'eng', 100),
  ('SX', 'سانت مارتن', 'Sint Maarten', '🇸🇽', 'americas', false, 'eng', 100),
  ('SK', 'سلوفاكيا', 'Slovakia', '🇸🇰', 'europe', false, 'slk', 100),
  ('SI', 'سلوفينيا', 'Slovenia', '🇸🇮', 'europe', false, 'slv', 100),
  ('SB', 'جزر سليمان', 'Solomon Islands', '🇸🇧', 'oceania', false, 'eng', 100),
  ('SO', 'الصومال', 'Somalia', '🇸🇴', 'africa', true, 'ara', 20),
  ('ZA', 'جنوب أفريقيا', 'South Africa', '🇿🇦', 'africa', false, 'afr', 100),
  ('GS', 'جورجيا الجنوبية وجزر ساندويتش الجنوبية', 'South Georgia and the South Sandwich Islands', '🇬🇸', 'americas', false, 'eng', 100),
  ('KR', 'كوريا الجنوبية', 'South Korea', '🇰🇷', 'asia', false, 'kor', 100),
  ('SS', 'جنوب السودان', 'South Sudan', '🇸🇸', 'africa', false, 'eng', 100),
  ('ES', 'إسبانيا', 'Spain', '🇪🇸', 'europe', false, 'spa', 100),
  ('LK', 'سريلانكا', 'Sri Lanka', '🇱🇰', 'asia', false, 'sin', 100),
  ('SD', 'السودان', 'Sudan', '🇸🇩', 'africa', true, 'ara', 14),
  ('SR', 'سورينام', 'Suriname', '🇸🇷', 'americas', false, 'nld', 100),
  ('SJ', 'سفالبارد وجان ماين', 'Svalbard and Jan Mayen', '🇸🇯', null, false, 'nor', 100),
  ('SZ', 'إسواتيني', 'Swaziland', '🇸🇿', 'africa', false, 'eng', 100),
  ('SE', 'السويد', 'Sweden', '🇸🇪', 'europe', false, 'swe', 100),
  ('CH', 'سويسرا', 'Switzerland', '🇨🇭', 'europe', false, 'deu', 100),
  ('SY', 'سوريا', 'Syria', '🇸🇾', 'asia', true, 'ara', 11),
  ('ST', 'ساو تومي وبرينسيبي', 'Sao Tome and Principe', '🇸🇹', 'africa', false, 'por', 100),
  ('TW', 'تايوان', 'Taiwan', '🇹🇼', 'asia', false, 'zho', 100),
  ('TJ', 'طاجيكستان', 'Tajikistan', '🇹🇯', 'asia', false, 'rus', 100),
  ('TZ', 'تنزانيا', 'Tanzania', '🇹🇿', 'africa', false, 'eng', 100),
  ('TH', 'تايلاند', 'Thailand', '🇹🇭', 'asia', false, 'tha', 100),
  ('TG', 'توغو', 'Togo', '🇹🇬', 'africa', false, 'fra', 100),
  ('TK', 'توكيلاو', 'Tokelau', '🇹🇰', 'oceania', false, 'eng', 100),
  ('TO', 'تونغا', 'Tonga', '🇹🇴', 'oceania', false, 'eng', 100),
  ('TT', 'ترينيداد وتوباغو', 'Trinidad and Tobago', '🇹🇹', 'americas', false, 'eng', 100),
  ('TN', 'تونس', 'Tunisia', '🇹🇳', 'africa', true, 'ara', 16),
  ('TR', 'تركيا', 'Turkiye', '🇹🇷', 'europe', false, 'tur', 100),
  ('TM', 'تركمانستان', 'Turkmenistan', '🇹🇲', 'asia', false, 'rus', 100),
  ('TC', 'جزر توركس وكايكوس', 'Turks and Caicos Islands', '🇹🇨', 'americas', false, 'eng', 100),
  ('TV', 'توفالو', 'Tuvalu', '🇹🇻', 'oceania', false, 'eng', 100),
  ('UM', 'جزر الولايات المتحدة النائية', 'U.S. Minor Outlying Islands', '🇺🇲', null, false, 'eng', 100),
  ('VI', 'جزر فيرجن الأمريكية', 'U.S. Virgin Islands', '🇻🇮', 'americas', false, 'eng', 100),
  ('UG', 'أوغندا', 'Uganda', '🇺🇬', 'africa', false, 'eng', 100),
  ('UA', 'أوكرانيا', 'Ukraine', '🇺🇦', 'europe', false, 'ukr', 100),
  ('AE', 'الإمارات', 'United Arab Emirates', '🇦🇪', 'asia', true, 'ara', 3),
  ('UK', 'المملكة المتحدة', 'United Kingdom', '🇬🇧', 'europe', false, 'eng', 100),
  ('US', 'أمريكا', 'United States', '🇺🇸', 'americas', false, 'eng', 100),
  ('UY', 'أورغواي', 'Uruguay', '🇺🇾', 'americas', false, 'spa', 100),
  ('UZ', 'أوزبكستان', 'Uzbekistan', '🇺🇿', 'asia', false, 'rus', 100),
  ('VU', 'فانواتو', 'Vanuatu', '🇻🇺', 'oceania', false, 'bis', 100),
  ('VA', 'الفاتيكان', 'Vatican City', '🇻🇦', 'europe', false, 'ita', 100),
  ('VE', 'فنزويلا', 'Venezuela', '🇻🇪', 'americas', false, 'spa', 100),
  ('VN', 'فيتنام', 'Vietnam', '🇻🇳', 'asia', false, 'vie', 100),
  ('WF', 'جزر والس وفوتونا', 'Wallis and Futuna', '🇼🇫', 'oceania', false, 'fra', 100),
  ('EH', 'الصحراء الغربية', 'Western Sahara', '🇪🇭', 'africa', false, 'zgh', 100),
  ('YE', 'اليمن', 'Yemen', '🇾🇪', 'asia', true, 'ara', 13),
  ('ZM', 'زامبيا', 'Zambia', '🇿🇲', 'africa', false, 'eng', 100),
  ('ZW', 'زيمبابوي', 'Zimbabwe', '🇿🇼', 'africa', false, 'bwg', 100) on conflict do nothing;

-- الفئات
insert into public.categories (slug, name_ar, name_en, icon, hue, sort_order) values
  ('news', 'أخبار', 'News', 'live', 0, 1),
  ('sports', 'رياضة', 'Sports', 'ball', 140, 2),
  ('movies', 'أفلام', 'Movies', 'film', 280, 3),
  ('series', 'مسلسلات', 'Series', 'tv', 320, 4),
  ('kids', 'أطفال', 'Kids', 'star', 45, 5),
  ('animation', 'رسوم متحركة', 'Animation', 'star', 30, 6),
  ('entertainment', 'ترفيه', 'Entertainment', 'play', 25, 7),
  ('comedy', 'كوميديا', 'Comedy', 'heart', 50, 8),
  ('music', 'موسيقى', 'Music', 'music', 200, 9),
  ('documentary', 'وثائقي', 'Documentary', 'globe', 95, 10),
  ('science', 'علوم', 'Science', 'zap', 185, 11),
  ('religious', 'دينية', 'Religious', 'book', 165, 12),
  ('education', 'تعليم', 'Education', 'book', 220, 13),
  ('culture', 'ثقافة', 'Culture', 'book', 260, 14),
  ('business', 'اقتصاد وأعمال', 'Business', 'chart', 55, 15),
  ('weather', 'طقس', 'Weather', 'sun', 195, 16),
  ('lifestyle', 'أسلوب حياة', 'Lifestyle', 'heart', 340, 17),
  ('cooking', 'طبخ', 'Cooking', 'fork', 15, 18),
  ('travel', 'سفر', 'Travel', 'globe', 175, 19),
  ('outdoor', 'مغامرات', 'Outdoor', 'sun', 110, 20),
  ('auto', 'سيارات', 'Auto', 'car', 5, 21),
  ('shop', 'تسوّق', 'Shop', 'bag', 300, 22),
  ('classic', 'كلاسيك', 'Classic', 'film', 35, 23),
  ('family', 'عائلة', 'Family', 'user', 20, 24),
  ('relax', 'استرخاء', 'Relax', 'heart', 160, 25),
  ('legislative', 'برلمانية', 'Legislative', 'shield', 210, 26),
  ('public', 'حكومية', 'Public', 'shield', 230, 27),
  ('general', 'عامة', 'General', 'tv', 240, 28) on conflict do nothing;
-- @@REFERENCE_DATA_END

-- ─── 14) جدول البث (EPG) ────────────────────────────────────────────────────
-- برامج القنوات (XMLTV). channel_uid يقابل channels.uid. تُحدَّث تلقائيًا عبر GitHub Actions.
create table if not exists public.epg_programmes (
  id           bigint generated always as identity primary key,
  channel_uid  text not null,
  start_at     timestamptz not null,
  end_at       timestamptz not null,
  title        text not null,
  description  text,
  category     text,
  icon_url     text,
  source       text,
  unique (channel_uid, start_at)
);
alter table public.epg_programmes add column if not exists channel_uid  text not null;
alter table public.epg_programmes add column if not exists start_at     timestamptz not null;
alter table public.epg_programmes add column if not exists end_at       timestamptz not null;
alter table public.epg_programmes add column if not exists title        text not null;
alter table public.epg_programmes add column if not exists description  text;
alter table public.epg_programmes add column if not exists category     text;
alter table public.epg_programmes add column if not exists icon_url     text;
alter table public.epg_programmes add column if not exists source       text;
create index if not exists epg_prog_idx on public.epg_programmes (channel_uid, start_at);

-- سجلّ كل تحديث EPG
create table if not exists public.epg_runs (
  id           bigint generated always as identity primary key,
  ran_at       timestamptz not null default now(),
  source       text,
  channels_ok  integer not null default 0,
  programmes   integer not null default 0,
  errors       text
);
alter table public.epg_runs add column if not exists ran_at       timestamptz not null default now();
alter table public.epg_runs add column if not exists source       text;
alter table public.epg_runs add column if not exists channels_ok  integer not null default 0;
alter table public.epg_runs add column if not exists programmes   integer not null default 0;
alter table public.epg_runs add column if not exists errors       text;

alter table public.epg_programmes enable row level security;
alter table public.epg_runs       enable row level security;
drop policy if exists "anon read" on public.epg_programmes;
create policy "anon read" on public.epg_programmes for select to anon using (true);
drop policy if exists "auth read" on public.epg_programmes;
create policy "auth read" on public.epg_programmes for select to authenticated using (true);
drop policy if exists "auth read runs" on public.epg_runs;
create policy "auth read runs" on public.epg_runs for select to authenticated using (true);

revoke all on public.epg_programmes, public.epg_runs from anon, authenticated;
grant select on public.epg_programmes to anon, authenticated;
grant select on public.epg_runs to authenticated;
grant select, insert, update, delete on public.epg_programmes, public.epg_runs to service_role;

-- السابق/الحالي/التالي لكل قناة باستعلام واحد (لشاشة القنوات)
create or replace function public.epg_now(p_uids text[])
returns table (channel_uid text, slot text, title text, start_at timestamptz, end_at timestamptz, category text, description text)
language sql stable security definer set search_path = public, pg_temp as $$
  (select channel_uid, 'now'::text as slot, title, start_at, end_at, category, description
     from public.epg_programmes where channel_uid = any(p_uids) and now() >= start_at and now() < end_at)
  union all
  (select distinct on (channel_uid) channel_uid, 'next' as slot, title, start_at, end_at, category, description
     from public.epg_programmes where channel_uid = any(p_uids) and start_at > now()
     order by channel_uid, start_at)
  union all
  (select distinct on (channel_uid) channel_uid, 'prev' as slot, title, start_at, end_at, category, description
     from public.epg_programmes where channel_uid = any(p_uids) and end_at <= now()
     order by channel_uid, end_at desc)
$$;

-- جدول يوم كامل لقناة
create or replace function public.epg_day(p_uid text, p_day date)
returns setof public.epg_programmes
language sql stable security definer set search_path = public, pg_temp as $$
  select * from public.epg_programmes
   where channel_uid = p_uid and start_at >= p_day::timestamptz and start_at < (p_day + 1)::timestamptz
   order by start_at
$$;

-- حذف البرامج المنتهية قبل أكثر من يوم
create or replace function public.epg_cleanup() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n integer;
begin
  delete from public.epg_programmes where end_at < now() - interval '1 day';
  get diagnostics n = row_count; return n;
end $$;

grant execute on function public.epg_now(text[]), public.epg_day(text, date) to anon, authenticated;
grant execute on function public.epg_cleanup() to service_role, authenticated;

commit;

-- تحديث ذاكرة واجهة API فورًا حتى ترى الجداول الجديدة (يمنع خطأ schema cache)
notify pgrst, 'reload schema';

