-- ════════════════════════════════════════════════════════════════════════════
-- 0004 — المرحلة 5 (الدفعة الثانية): مصادر الدليل، كتابة البرامج من برنامج المدير، قواعد التحويل، حسابات Xtream.
-- إضافي فقط: لا يغيّر أي جدول قائم ولا أي سياسة قائمة. الموقع القديم ومزامنة GitHub للدليل يعملان كما هما.
-- كل الكتابة الجديدة تشترط is_admin() = مدير + جلسة تحقق بخطوتين (aal2).
-- التراجع: docs/migration/down/20261016000300_phase5_epg_rules_xtream.down.sql
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1) مصادر الدليل (ADM-E1) ───────────────────────────────────────────────
create table if not exists public.epg_sources (
  id              uuid primary key default gen_random_uuid(),
  name            text not null check (length(trim(name)) between 1 and 120),
  url             text not null unique check (url ~ '^https?://' and length(url) <= 2000),
  enabled         boolean not null default true,
  priority        integer not null default 100,           -- الأصغر أولًا؛ كل مصدر يُكمّل الناقص
  interval_hours  integer not null default 12 check (interval_hours between 1 and 168),
  last_run_at     timestamptz,
  last_status     text check (last_status in ('ok', 'failed', 'partial')),
  last_channels   integer,
  last_programmes integer,
  last_error      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.epg_sources enable row level security;
create policy "admin all" on public.epg_sources for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.epg_sources from anon;
grant select, insert, update, delete on public.epg_sources to authenticated;

-- نفس المصادر العامة التي يستخدمها supabase/epg_sync.mjs اليوم
insert into public.epg_sources (name, url, priority) values
  ('epgshare01-AR', 'https://epgshare01.online/epgshare01/epg_ripper_AR1.xml.gz', 10),
  ('epgshare01-SA', 'https://epgshare01.online/epgshare01/epg_ripper_SA1.xml.gz', 20),
  ('epgshare01-AE', 'https://epgshare01.online/epgshare01/epg_ripper_AE1.xml.gz', 30),
  ('epgshare01-EG', 'https://epgshare01.online/epgshare01/epg_ripper_EG1.xml.gz', 40)
on conflict (url) do nothing;

-- ─── 2) كتابة البرامج من برنامج المدير (بدل مفتاح الخدمة) ─────────────────
-- p_rows: [{channel_uid,start_at,end_at,title,description,category,icon_url,source}] — دفعة واحدة دون تكرار المفتاح
create or replace function public.admin_epg_upsert(p_rows jsonb) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  insert into public.epg_programmes (channel_uid, start_at, end_at, title, description, category, icon_url, source)
  select distinct on (x.channel_uid, x.start_at)
         x.channel_uid, x.start_at, x.end_at, left(x.title, 500), left(x.description, 4000), left(x.category, 200), x.icon_url, left(x.source, 120)
  from jsonb_to_recordset(coalesce(p_rows, '[]')) as x(channel_uid text, start_at timestamptz, end_at timestamptz, title text,
                                                       description text, category text, icon_url text, source text)
  where coalesce(x.channel_uid, '') <> '' and x.start_at is not null and x.end_at > x.start_at and coalesce(trim(x.title), '') <> ''
  order by x.channel_uid, x.start_at
  on conflict (channel_uid, start_at) do update
    set end_at = excluded.end_at, title = excluded.title, description = excluded.description,
        category = excluded.category, icon_url = excluded.icon_url, source = excluded.source;
  get diagnostics n = row_count;
  return n;
end $$;

-- إنهاء تشغيل: سجل في epg_runs + حالة المصدر + تنظيف البرامج المنتهية
create or replace function public.admin_epg_finish(p_source uuid, p_status text, p_channels integer, p_programmes integer, p_error text)
returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare cleaned int; v_name text;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  update public.epg_sources
     set last_run_at = now(), last_status = p_status, last_channels = p_channels, last_programmes = p_programmes,
         last_error = left(p_error, 1000), updated_at = now()
   where id = p_source
  returning name into v_name;
  insert into public.epg_runs (source, channels_ok, programmes, errors)
  values ('app:' || coalesce(v_name, p_source::text), coalesce(p_channels, 0), coalesce(p_programmes, 0), left(p_error, 2000));
  cleaned := public.epg_cleanup();
  return cleaned;
end $$;

revoke all on function public.admin_epg_upsert(jsonb) from public, anon;
revoke all on function public.admin_epg_finish(uuid, text, integer, integer, text) from public, anon;
grant execute on function public.admin_epg_upsert(jsonb) to authenticated;
grant execute on function public.admin_epg_finish(uuid, text, integer, integer, text) to authenticated;

-- ─── 3) قواعد التحويل (ADM-C6، §10.3) ───────────────────────────────────────
create table if not exists public.transform_rules (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null check (kind in ('group_category', 'name_country', 'name_language', 'name_cleanup', 'id_map')),
  pattern    text not null check (length(pattern) between 1 and 300),   -- نص يُبحث عنه (أو تعبير نمطي إن كان is_regex)
  is_regex   boolean not null default false,
  target     text not null default '' check (length(target) <= 300),    -- الفئة/الدولة/اللغة/البديل/معرّف القناة
  enabled    boolean not null default true,
  priority   integer not null default 100,
  note       text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.transform_rules enable row level security;
create policy "admin all" on public.transform_rules for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.transform_rules from anon;
grant select, insert, update, delete on public.transform_rules to authenticated;

-- ─── 4) حسابات Xtream (§10.1): كلمة المرور في Supabase Vault فقط ─────────────
create table if not exists public.xtream_accounts (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (length(trim(name)) between 1 and 120),
  server         text not null check (server ~ '^https?://' and length(server) <= 500),
  username       text not null check (length(username) between 1 and 200),
  secret_id      uuid not null,                                -- vault.secrets.id (كلمة المرور مشفّرة)
  enabled        boolean not null default true,
  last_import_at timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
alter table public.xtream_accounts enable row level security;
create policy "admin all" on public.xtream_accounts for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.xtream_accounts from anon;
grant select, update, delete on public.xtream_accounts to authenticated;   -- الإضافة عبر الدالة فقط (لتشفير كلمة المرور)

create or replace function public.admin_xtream_save(p_name text, p_server text, p_username text, p_password text) returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_secret uuid; v_id uuid;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  if coalesce(p_password, '') = '' then raise exception 'password required'; end if;
  v_secret := vault.create_secret(p_password, 'xtream:' || gen_random_uuid()::text, 'MTC-iPTv Xtream account password');
  insert into public.xtream_accounts (name, server, username, secret_id)
  values (trim(p_name), rtrim(trim(p_server), '/'), trim(p_username), v_secret)
  returning id into v_id;
  return v_id;
end $$;

-- كلمة المرور تُقرأ فقط عند الجلب، من برنامج المدير، بجلسة تحقق بخطوتين
create or replace function public.admin_xtream_password(p_id uuid) returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare v text;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  select s.decrypted_secret into v
  from public.xtream_accounts a join vault.decrypted_secrets s on s.id = a.secret_id
  where a.id = p_id;
  return v;
end $$;

create or replace function public.admin_xtream_delete(p_id uuid) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_secret uuid;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  delete from public.xtream_accounts where id = p_id returning secret_id into v_secret;
  if v_secret is not null then delete from vault.secrets where id = v_secret; end if;
end $$;

revoke all on function public.admin_xtream_save(text, text, text, text) from public, anon;
revoke all on function public.admin_xtream_password(uuid) from public, anon;
revoke all on function public.admin_xtream_delete(uuid) from public, anon;
grant execute on function public.admin_xtream_save(text, text, text, text) to authenticated;
grant execute on function public.admin_xtream_password(uuid) to authenticated;
grant execute on function public.admin_xtream_delete(uuid) to authenticated;

-- ─── 5) سجل التدقيق للجداول الجديدة (دون كلمات مرور: هي في Vault) ───────────
do $$
declare t text;
begin
  foreach t in array array['epg_sources', 'transform_rules', 'xtream_accounts'] loop
    execute format('drop trigger if exists zz_audit on public.%I', t);
    execute format('create trigger zz_audit after insert or update or delete on public.%I for each row execute function public.audit_row()', t);
  end loop;
end $$;
