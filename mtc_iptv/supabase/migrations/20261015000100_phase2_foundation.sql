-- ════════════════════════════════════════════════════════════════════════════
-- Migration 0002 — Phase 2 foundation (MASTER_SPEC §16, §19, ADR-18)
--
-- ADDITIVE ONLY: no column/table is dropped or renamed, so the current web panel
-- (asadmin/) and the React Native app keep working on the same database until R1/R2.
-- Old and new columns are kept in sync by compatibility triggers (§24.5).
--
--   1) is_admin(): single admin (D-05) + MFA session (aal2). Legacy is_mtc_admin()
--      stays unchanged for the old panel's policies until R1 (§24.5).
--   2) channels: name_ar/name_en, publish_state, merged_into, … + compat trigger
--   3) streams: headers, protocol, credentials flag, health_* + compat trigger
--   4) channel_field_provenance (§11.2)
--   5) audit_logs written by triggers (ADM-H3), credentials masked
--   6) delta sync: catalog_rev + tombstones + catalog_changes(since) (§22)
--   7) scheduled_tasks / task_runs with lease locks (ADM-H2, D-13)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1) Admin check with MFA ────────────────────────────────────────────────
-- true only for the admin in admin_users AND a session verified with a second factor.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.admin_users where user_id = (select auth.uid()))
     and coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2'
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Lets the app know whether to show the admin center / ask for MFA (no secrets returned).
create or replace function public.admin_status() returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'is_admin_user', exists (select 1 from public.admin_users where user_id = (select auth.uid())),
    'aal', coalesce((select auth.jwt()) ->> 'aal', 'aal1'),
    'is_admin', public.is_admin())
$$;
grant execute on function public.admin_status() to authenticated;

-- ─── Helpers ────────────────────────────────────────────────────────────────
-- Masks credentials inside stream URLs (§19.4): /live/USER/PASS/…, ?username=…, user:pass@
create or replace function public.mask_credentials(u text) returns text
language sql immutable as $$
  select regexp_replace(
           regexp_replace(
             regexp_replace(u, '(/(live|movie|series)/)[^/]+/[^/]+/', '\1••••/••••/', 'i'),
             '([?&](username|user|password|pass|token)=)[^&]*', '\1••••', 'gi'),
           '^([a-z]+://)[^@/]+@', '\1••••@', 'i')
$$;

create or replace function public.url_has_credentials(u text) returns boolean
language sql immutable as $$
  select u ~* '/(live|movie|series)/[^/]+/[^/]+/\d+' or u ~* '[?&](username|user|password|pass|token)=' or u ~ '^[a-z]+://[^/@]+@'
$$;

create or replace function public.url_protocol(u text) returns text
language sql immutable as $$
  select case
    when u ~* '^rtmps?://' then 'rtmp'
    when u ~* '^rtsp://' then 'rtsp'
    when u ~* '^(udp|rtp)://' then 'udp'
    when split_part(lower(u), '?', 1) ~ '\.m3u8?$' then 'hls'
    when split_part(lower(u), '?', 1) ~ '\.mpd$' then 'dash'
    when split_part(lower(u), '?', 1) ~ '\.ts$' then 'ts'
    when split_part(lower(u), '?', 1) ~ '\.mp4$' then 'mp4'
    when split_part(lower(u), '?', 1) ~ '\.flv$' then 'flv'
    else 'http' end
$$;

-- ─── 6a) Delta-sync revision counter (needed by the columns below) ─────────
create sequence if not exists public.catalog_rev_seq;

-- ─── 2) channels: new columns ───────────────────────────────────────────────
alter table public.channels
  add column if not exists name_ar            text check (name_ar is null or length(trim(name_ar)) between 1 and 250),
  add column if not exists name_en            text check (name_en is null or length(trim(name_en)) between 1 and 250),
  add column if not exists publish_state      text check (publish_state in ('draft','pending','published','hidden','rejected')),
  add column if not exists merged_into        uuid references public.channels(id) on delete set null,
  add column if not exists family_key         text,
  add column if not exists epg_offset_minutes integer not null default 0 check (epg_offset_minutes between -1440 and 1440),
  add column if not exists parental_locked    boolean not null default false,
  add column if not exists catalog_rev        bigint;

-- Backfill (production: 359 channels, all published, all names Latin — inventory §10)
update public.channels set
  name_ar = case when name ~ '[؀-ۿ]' then name end,
  name_en = case when name !~ '[؀-ۿ]' then name end,
  publish_state = case
    when is_published and hidden_reason is null then 'published'
    when hidden_reason = 'pending' then 'pending'
    else 'hidden' end,
  merged_into = case when hidden_reason = 'duplicate' then duplicate_of end,
  catalog_rev = nextval('public.catalog_rev_seq')
where publish_state is null;

alter table public.channels alter column publish_state set default 'pending';
alter table public.channels alter column publish_state set not null;

-- Compatibility: legacy (is_published, hidden_reason, name, duplicate_of) <-> new columns.
-- Named zz_* so it runs AFTER channels_review_gate / channels_stamp_published (alphabetical).
-- Inserts: the legacy columns are authoritative (the review gate decides), so no client can
-- bypass the gate by sending publish_state='published' directly.
create or replace function public.channels_zz_compat() returns trigger
language plpgsql as $$
begin
  if tg_op = 'INSERT' or new.publish_state is not distinct from old.publish_state then
    -- derive new <- legacy
    new.publish_state := case
      when new.is_published and new.hidden_reason is null then 'published'
      when new.hidden_reason = 'pending' then 'pending'
      when tg_op = 'UPDATE' and old.publish_state in ('draft','rejected') and not new.is_published then old.publish_state
      else 'hidden' end;
  else
    -- derive legacy <- new (the new app changed publish_state)
    new.is_published := new.publish_state = 'published';
    new.hidden_reason := case new.publish_state
      when 'published' then null
      when 'pending' then 'pending'
      else coalesce(nullif(new.hidden_reason, 'pending'), 'manual') end;
  end if;

  if new.merged_into is distinct from coalesce(old.merged_into, null) and tg_op = 'UPDATE' then
    new.duplicate_of := new.merged_into;
  elsif new.duplicate_of is not null and new.hidden_reason = 'duplicate' then
    new.merged_into := new.duplicate_of;
  end if;

  -- names: the new app writes name_ar/name_en; the legacy apps read/write name
  if tg_op = 'UPDATE' and new.name is distinct from old.name
     and new.name_ar is not distinct from old.name_ar and new.name_en is not distinct from old.name_en then
    if new.name ~ '[؀-ۿ]' then new.name_ar := new.name; else new.name_en := new.name; end if;
  elsif tg_op = 'INSERT' and new.name_ar is null and new.name_en is null then
    if new.name ~ '[؀-ۿ]' then new.name_ar := new.name; else new.name_en := new.name; end if;
  else
    new.name := coalesce(new.name_en, new.name_ar, new.name);
  end if;

  new.catalog_rev := nextval('public.catalog_rev_seq');
  return new;
end $$;
drop trigger if exists channels_zz_compat on public.channels;
create trigger channels_zz_compat before insert or update on public.channels
  for each row execute function public.channels_zz_compat();

create index if not exists channels_rev_idx on public.channels(catalog_rev);
create index if not exists channels_state_idx on public.channels(publish_state);

-- ─── 3) streams: new columns ────────────────────────────────────────────────
alter table public.streams
  add column if not exists user_agent      text check (length(user_agent) <= 500),
  add column if not exists referrer        text check (length(referrer) <= 1000),
  add column if not exists headers         jsonb not null default '{}'::jsonb,
  add column if not exists kodi_props      jsonb not null default '{}'::jsonb,
  add column if not exists protocol        text generated always as (public.url_protocol(url)) stored,
  add column if not exists has_credentials boolean generated always as (public.url_has_credentials(url)) stored,
  add column if not exists health_state    text not null default 'inconclusive'
    check (health_state in ('playable','reachable','degraded','auth_failed','unsupported','network_error','unavailable','geo_restricted','inconclusive','disabled')),
  add column if not exists health_reason   text,
  add column if not exists health_score    smallint check (health_score between 0 and 100),
  add column if not exists catalog_rev     bigint;

-- Backfill per Appendix D: never assume 'playable' before a real playback check
update public.streams set
  health_state = case when not is_active then 'disabled' when status = 'online' then 'reachable' when status = 'offline' then 'unavailable' else 'inconclusive' end,
  catalog_rev = nextval('public.catalog_rev_seq')
where catalog_rev is null;

create or replace function public.streams_zz_compat() returns trigger
language plpgsql as $$
begin
  -- legacy panel changed status / is_active -> map to health_state (unless the new app set it)
  if tg_op = 'INSERT' or new.health_state is not distinct from old.health_state then
    if not new.is_active then new.health_state := 'disabled';
    elsif tg_op = 'INSERT' or new.status is distinct from old.status or new.is_active is distinct from old.is_active then
      new.health_state := case new.status when 'online' then 'reachable' when 'offline' then 'unavailable' else 'inconclusive' end;
    end if;
  else
    -- new app changed health_state -> keep legacy columns meaningful for the old apps
    new.is_active := new.health_state <> 'disabled';
    new.status := case when new.health_state in ('playable','reachable','degraded') then 'online'
                       when new.health_state in ('inconclusive','geo_restricted') then 'unknown'
                       when new.health_state = 'disabled' then new.status
                       else 'offline' end;
  end if;
  new.catalog_rev := nextval('public.catalog_rev_seq');
  return new;
end $$;
drop trigger if exists streams_zz_compat on public.streams;
create trigger streams_zz_compat before insert or update on public.streams
  for each row execute function public.streams_zz_compat();

create index if not exists streams_rev_idx on public.streams(catalog_rev);

-- ─── 4) Field provenance (§11.2) ────────────────────────────────────────────
create table if not exists public.channel_field_provenance (
  channel_id  uuid not null references public.channels(id) on delete cascade,
  field       text not null check (field ~ '^[a-z_]+$'),
  source_kind text not null check (source_kind in ('manual','rule','connector','source','inferred')),
  source_id   uuid,
  fetched_at  timestamptz not null default now(),
  confidence  real check (confidence between 0 and 1),
  locked      boolean not null default false,
  primary key (channel_id, field)
);
alter table public.channel_field_provenance enable row level security;
create policy "admin all" on public.channel_field_provenance for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.channel_field_provenance from anon;
grant select, insert, update, delete on public.channel_field_provenance to authenticated;

-- Manual channels: every field the admin typed is protected from imports (Appendix D)
insert into public.channel_field_provenance (channel_id, field, source_kind, locked)
select c.id, f.field, 'manual', true
from public.channels c
cross join (values ('name_ar'),('name_en'),('number'),('country_code'),('category_slug'),('language_code'),('logo_url'),('epg_id')) f(field)
where c.is_manual
on conflict do nothing;

-- ─── 5) Audit log (ADM-H3) ──────────────────────────────────────────────────
create table if not exists public.audit_logs (
  id         bigint generated always as identity primary key,
  at         timestamptz not null default now(),
  actor      uuid,                                   -- auth.uid(); null = system / SQL editor
  action     text not null check (action in ('INSERT','UPDATE','DELETE')),
  table_name text not null,
  row_id     text,
  before     jsonb,
  after      jsonb,
  reason     text not null default 'manual'          -- manual|import|merge|migration|restore|sync (set via set_config('mtc.reason', …, true))
);
create index if not exists audit_at_idx on public.audit_logs(at desc);
create index if not exists audit_row_idx on public.audit_logs(table_name, row_id);
alter table public.audit_logs enable row level security;
create policy "admin read" on public.audit_logs for select to authenticated using ((select public.is_admin()));
revoke all on public.audit_logs from anon, authenticated;
grant select on public.audit_logs to authenticated;          -- read only; rows come from the trigger

-- jsonb of a row with any URL credentials masked and noisy columns dropped
create or replace function public.audit_clean(j jsonb) returns jsonb
language sql immutable as $$
  select (select coalesce(jsonb_object_agg(k, case when jsonb_typeof(v) = 'string' and (v #>> '{}') ~* '^[a-z]+://'
                                                then to_jsonb(public.mask_credentials(v #>> '{}')) else v end), '{}'::jsonb)
          from jsonb_each(j - 'updated_at' - 'catalog_rev') e(k, v))
$$;

create or replace function public.audit_row() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
declare b jsonb; a jsonb; rid text;
begin
  if tg_op <> 'INSERT' then b := public.audit_clean(to_jsonb(old)); end if;
  if tg_op <> 'DELETE' then a := public.audit_clean(to_jsonb(new)); end if;
  if tg_op = 'UPDATE' and b = a then return null; end if;  -- only bookkeeping columns changed
  rid := coalesce(a, b) ->> (case when tg_table_name = 'site_settings' then 'key'
                                  when tg_table_name in ('countries','languages') then 'code'
                                  when tg_table_name = 'categories' then 'slug'
                                  when tg_table_name = 'admin_users' then 'user_id'
                                  else 'id' end);
  insert into public.audit_logs(actor, action, table_name, row_id, before, after, reason)
  values ((select auth.uid()), tg_op, tg_table_name, rid, b, a, coalesce(nullif(current_setting('mtc.reason', true), ''), 'manual'));
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['channels','streams','playlist_sources','site_settings','categories','countries','languages','admin_users','channel_field_provenance'] loop
    execute format('drop trigger if exists zz_audit on public.%I', t);
    execute format('create trigger zz_audit after insert or update or delete on public.%I for each row execute function public.audit_row()', t);
  end loop;
end $$;

-- ─── 6) Delta sync for the viewer app (§22) ─────────────────────────────────
create table if not exists public.catalog_tombstones (
  rev        bigint primary key default nextval('public.catalog_rev_seq'),
  table_name text not null check (table_name in ('channels','streams')),
  row_id     uuid not null,
  at         timestamptz not null default now()
);
alter table public.catalog_tombstones enable row level security;
revoke all on public.catalog_tombstones from anon, authenticated;

create or replace function public.catalog_tombstone() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  insert into public.catalog_tombstones(table_name, row_id) values (tg_table_name, old.id);
  return null;
end $$;
drop trigger if exists zz_tombstone on public.channels;
create trigger zz_tombstone after delete on public.channels for each row execute function public.catalog_tombstone();
drop trigger if exists zz_tombstone on public.streams;
create trigger zz_tombstone after delete on public.streams for each row execute function public.catalog_tombstone();

-- Everything that changed after `since`. Unpublished/inactive rows are reported as removals
-- (ids only), so nothing non-public leaks to anonymous viewers. Paged by `max_rows`.
create or replace function public.catalog_changes(since bigint default 0, max_rows integer default 2000)
returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  with ch as (
    select c.* from public.channels c where c.catalog_rev > since order by c.catalog_rev limit max_rows
  ), st as (
    select s.* from public.streams s where s.catalog_rev > since order by s.catalog_rev limit max_rows
  ), tb as (
    select t.* from public.catalog_tombstones t where t.rev > since order by t.rev limit max_rows
  )
  select jsonb_build_object(
    'rev', greatest(since,
                    coalesce((select max(catalog_rev) from ch), 0),
                    coalesce((select max(catalog_rev) from st), 0),
                    coalesce((select max(rev) from tb), 0)),
    'more', (select count(*) from ch) = max_rows or (select count(*) from st) = max_rows or (select count(*) from tb) = max_rows,
    'channels', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'uid', uid, 'number', number, 'name_ar', name_ar, 'name_en', name_en, 'alt_names', alt_names,
        'network', network, 'logo_url', case when logo_status = 'broken' then null else logo_url end,
        'country', country_code, 'category', category_slug, 'categories', extra_categories, 'language', language_code,
        'quality', quality, 'featured', is_featured, 'sort', sort_order, 'epg_id', epg_id, 'epg_offset', epg_offset_minutes,
        'family', family_key, 'parental', parental_locked, 'published_at', published_at))
      from ch where publish_state = 'published'), '[]'::jsonb),
    'streams', coalesce((select jsonb_agg(jsonb_build_object(
        'id', s.id, 'channel_id', s.channel_id, 'url', s.url, 'label', coalesce(s.label, public.server_of(s.host)),
        'quality', s.quality, 'priority', s.priority, 'user_agent', s.user_agent, 'referrer', s.referrer,
        'headers', s.headers, 'protocol', s.protocol, 'health', s.health_state, 'score', s.health_score))
      from st s join public.channels c on c.id = s.channel_id
      where s.health_state <> 'disabled' and c.publish_state = 'published'), '[]'::jsonb),
    'removed_channels', coalesce((select jsonb_agg(id) from ch where publish_state <> 'published'), '[]'::jsonb)
      || coalesce((select jsonb_agg(row_id) from tb where table_name = 'channels'), '[]'::jsonb),
    'removed_streams', coalesce((select jsonb_agg(s.id) from st s join public.channels c on c.id = s.channel_id
                                 where s.health_state = 'disabled' or c.publish_state <> 'published'), '[]'::jsonb)
      || coalesce((select jsonb_agg(row_id) from tb where table_name = 'streams'), '[]'::jsonb)
  )
$$;
revoke all on function public.catalog_changes(bigint, integer) from public;
grant execute on function public.catalog_changes(bigint, integer) to anon, authenticated;

-- ─── 7) Scheduler (ADM-H2, D-13): settings + runs + lease lock across admin devices ─
create table if not exists public.scheduled_tasks (
  key           text primary key check (key ~ '^[a-z0-9_]+$'),
  enabled       boolean not null default true,
  interval_min  integer not null check (interval_min between 1 and 10080),
  allowed_hours int4range,                                   -- null = any time; e.g. [1,6) = 01:00–05:59 local
  last_run_at   timestamptz,
  last_status   text check (last_status in ('ok','failed','skipped')),
  next_run_at   timestamptz,
  locked_by     text,                                        -- device id holding the lease
  locked_until  timestamptz,
  updated_at    timestamptz not null default now()
);
create table if not exists public.task_runs (
  id          bigint generated always as identity primary key,
  task_key    text not null references public.scheduled_tasks(key) on delete cascade,
  device      text,
  started_at  timestamptz not null default now(),
  finished_at timestamptz,
  status      text not null default 'running' check (status in ('running','ok','failed','skipped')),
  catch_up    boolean not null default false,
  summary     jsonb not null default '{}'::jsonb,
  error       text
);
create index if not exists task_runs_key_idx on public.task_runs(task_key, started_at desc);
alter table public.scheduled_tasks enable row level security;
alter table public.task_runs enable row level security;
create policy "admin all" on public.scheduled_tasks for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin all" on public.task_runs for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.scheduled_tasks, public.task_runs from anon;
grant select, insert, update, delete on public.scheduled_tasks, public.task_runs to authenticated;

insert into public.scheduled_tasks(key, interval_min) values
  ('health_published', 360), ('health_all', 1440), ('playback_sample', 1440),
  ('logos', 1440), ('epg', 720), ('sources', 360), ('backup', 1440)
on conflict do nothing;

-- Atomically take the lease for a due task (or renew it if this device already holds it).
-- Returns true when the caller should run the task now. Prevents two admin devices from
-- running the same task at once (§17.1).
create or replace function public.admin_task_acquire(p_key text, p_device text, p_lease_min integer default 30)
returns boolean
language plpgsql security definer set search_path = public, pg_temp as $$
declare got boolean;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  update public.scheduled_tasks
     set locked_by = p_device, locked_until = now() + make_interval(mins => p_lease_min), updated_at = now()
   where key = p_key and enabled
     and (locked_until is null or locked_until < now() or locked_by = p_device)
     and (next_run_at is null or next_run_at <= now())
  returning true into got;
  return coalesce(got, false);
end $$;

create or replace function public.admin_task_finish(p_key text, p_device text, p_status text)
returns void
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  update public.scheduled_tasks
     set last_run_at = now(), last_status = p_status, locked_by = null, locked_until = null,
         next_run_at = now() + make_interval(mins => interval_min), updated_at = now()
   where key = p_key and locked_by = p_device;
end $$;
revoke all on function public.admin_task_acquire(text, text, integer), public.admin_task_finish(text, text, text) from public;
grant execute on function public.admin_task_acquire(text, text, integer), public.admin_task_finish(text, text, text) to authenticated;

notify pgrst, 'reload schema';
