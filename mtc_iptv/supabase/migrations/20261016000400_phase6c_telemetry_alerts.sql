-- ════════════════════════════════════════════════════════════════════════════
-- 0005 — المرحلة 6 (الدفعة الثالثة): قياس المشاهدين (§12.4، §20)، الأجهزة، التجميع اليومي، تنبيهات المدير (ADM-A3).
-- إضافي فقط: جداول ودوال جديدة، ولا يغيّر أي جدول أو سياسة قائمة.
-- الخصوصية (§20): معرّف تثبيت عشوائي (مستعار)، لا IP، لا رابط ولا بيانات اعتماد، الدولة من ترويسة الشبكة فقط.
-- الكتابة من المشاهدين عبر telemetry_ingest فقط (حدود حجم ومعدل)، ولا يقرأ الجداول إلا المدير (aal2).
-- التراجع: docs/migration/down/20261016000400_phase6c_telemetry_alerts.down.sql
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1) الأجهزة (§20.1) ──────────────────────────────────────────────────────
create table if not exists public.installations (
  id            uuid primary key,                          -- يولّده التطبيق عشوائيًا، ويُعاد توليده بـ«أعد تعيين المعرّف»
  platform      text not null check (platform in ('windows', 'android', 'macos', 'linux', 'ios')),
  app_version   text check (length(app_version) <= 40),
  locale        text check (locale in ('ar', 'en')),
  country       text check (country ~ '^[A-Z]{2}$'),       -- تقريبية من ترويسة الشبكة، لا IP
  push_token    text check (length(push_token) <= 4096),   -- للنظام فقط (لا يقرؤه المدير)
  first_seen_at timestamptz not null default now(),
  last_seen_at  timestamptz not null default now()
);
create index if not exists installations_seen_idx on public.installations(last_seen_at);
alter table public.installations enable row level security;
create policy "admin read" on public.installations for select to authenticated using ((select public.is_admin()));
revoke all on public.installations from anon, authenticated;
grant select (id, platform, app_version, locale, country, first_seen_at, last_seen_at) on public.installations to authenticated;

-- ─── 2) أحداث التشغيل الخام (احتفاظ 30 يومًا) ─────────────────────────────────
create table if not exists public.playback_events (
  id              bigint generated always as identity primary key,
  installation_id uuid not null references public.installations(id) on delete cascade,
  at              timestamptz not null default now(),
  channel_id      uuid not null,
  stream_id       uuid not null,
  outcome         text not null check (outcome in ('success', 'failure', 'abandoned')),
  error_code      text check (error_code in ('auth_failed', 'unsupported', 'network_error', 'unavailable', 'geo_restricted', 'inconclusive')),
  first_frame_ms  integer check (first_frame_ms between 0 and 600000),
  watch_seconds   integer check (watch_seconds between 0 and 86400),   -- مقرّبة لأقرب 10 ثوانٍ
  server_index    smallint check (server_index between 0 and 50),
  height          smallint check (height between 0 and 8640),
  codec           text check (length(codec) <= 20),
  platform        text not null,
  app_version     text,
  country         text
);
create index if not exists playback_events_at_idx on public.playback_events(at);
create index if not exists playback_events_inst_idx on public.playback_events(installation_id, at);
alter table public.playback_events enable row level security;
create policy "admin read" on public.playback_events for select to authenticated using ((select public.is_admin()));
revoke all on public.playback_events from anon, authenticated;
grant select on public.playback_events to authenticated;

-- ─── 3) التجميع اليومي الدائم (بلا معرّفات أجهزة) ────────────────────────────
create table if not exists public.playback_stats_daily (
  day           date not null,
  stream_id     uuid not null,
  channel_id    uuid not null,
  platform      text not null,
  country       text not null default '',                  -- '' = غير معروفة
  attempts      integer not null default 0,                -- success + failure (المتروكة قبل أول إطار لا تُحسب)
  successes     integer not null default 0,
  abandoned     integer not null default 0,
  sessions_30s  integer not null default 0,                -- «مشاهدة» = جلسة ≥ 30 ثانية
  watch_seconds bigint not null default 0,
  ttff_p50_ms   integer,
  ttff_p90_ms   integer,
  failures      jsonb not null default '{}'::jsonb,        -- رمز الخطأ ← العدد
  primary key (day, stream_id, platform, country)
);
create index if not exists playback_stats_channel_idx on public.playback_stats_daily(channel_id, day);
alter table public.playback_stats_daily enable row level security;
create policy "admin read" on public.playback_stats_daily for select to authenticated using ((select public.is_admin()));
revoke all on public.playback_stats_daily from anon, authenticated;
grant select on public.playback_stats_daily to authenticated;

-- نسبة نجاح المشاهدين لكل رابط خلال 7 أيام (§12.2، §12.5) — للمدير، دون الكتابة على streams (لا ضجيج في التدقيق)
create or replace view public.stream_viewer_stats_7d with (security_invoker = true) as
  select stream_id, channel_id, sum(attempts)::int as attempts, sum(successes)::int as successes,
         case when sum(attempts) > 0 then round(sum(successes)::numeric / sum(attempts), 3) end as success_rate,
         sum(sessions_30s)::int as sessions_30s
    from public.playback_stats_daily
   where day >= current_date - 7
   group by stream_id, channel_id;
revoke all on public.stream_viewer_stats_7d from anon, authenticated;
grant select on public.stream_viewer_stats_7d to authenticated;

-- ─── 4) الاستقبال من التطبيقات ───────────────────────────────────────────────
-- p_events: [{at, stream_id, outcome, error_code, first_frame_ms, watch_seconds, server_index, height, codec}] — حتى 50 في الطلب.
-- القناة تؤخذ من الرابط نفسه (لا يقبل روابط غير موجودة). حد 300 حدث في الساعة لكل جهاز.
create or replace function public.telemetry_ingest(p_installation uuid, p_platform text, p_version text, p_locale text,
                                                   p_events jsonb default '[]'::jsonb, p_push_token text default null)
returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_country text;
  v_recent int;
  n int := 0;
begin
  if p_installation is null or p_platform not in ('windows', 'android', 'macos', 'linux', 'ios') then
    raise exception 'invalid installation' using errcode = '22023';
  end if;
  begin
    v_country := upper(nullif(current_setting('request.headers', true)::json ->> 'cf-ipcountry', ''));
  exception when others then v_country := null;
  end;
  if v_country !~ '^[A-Z]{2}$' or v_country in ('XX', 'T1') then v_country := null; end if;

  insert into public.installations as i (id, platform, app_version, locale, country, push_token)
  values (p_installation, p_platform, left(p_version, 40), case when p_locale in ('ar', 'en') then p_locale end, v_country, left(p_push_token, 4096))
  on conflict (id) do update
    set platform = excluded.platform, app_version = excluded.app_version, locale = coalesce(excluded.locale, i.locale),
        country = coalesce(excluded.country, i.country), push_token = coalesce(excluded.push_token, i.push_token), last_seen_at = now();

  -- مفتاح الإيقاف المركزي (G5 telemetry_enabled): يبقى عدّ الأجهزة النشطة فقط
  if coalesce((select (value ->> 'telemetry_enabled')::boolean from public.site_settings where key = 'features'), true) = false then
    return 0;
  end if;
  if jsonb_typeof(p_events) <> 'array' or jsonb_array_length(p_events) = 0 then return 0; end if;

  select count(*) into v_recent from public.playback_events where installation_id = p_installation and at > now() - interval '1 hour';
  if v_recent >= 300 then return 0; end if;

  insert into public.playback_events (installation_id, at, channel_id, stream_id, outcome, error_code, first_frame_ms, watch_seconds,
                                      server_index, height, codec, platform, app_version, country)
  select p_installation, least(greatest(coalesce(x.at, now()), now() - interval '2 days'), now()), s.channel_id, s.id, x.outcome,
         case when x.outcome = 'failure' then coalesce(x.error_code, 'inconclusive') end,
         case when x.first_frame_ms between 0 and 600000 then x.first_frame_ms end,
         case when x.watch_seconds between 0 and 86400 then (x.watch_seconds / 10) * 10 end,
         case when x.server_index between 0 and 50 then x.server_index end,
         case when x.height between 0 and 8640 then x.height end,
         left(x.codec, 20), p_platform, left(p_version, 40), v_country
    from (select * from jsonb_to_recordset(p_events) as r(at timestamptz, stream_id uuid, outcome text, error_code text, first_frame_ms int,
                                                           watch_seconds int, server_index smallint, height smallint, codec text)
           limit least(50, 300 - v_recent)) x
    join public.streams s on s.id = x.stream_id
   where x.outcome in ('success', 'failure', 'abandoned')
     and (x.error_code is null or x.error_code in ('auth_failed', 'unsupported', 'network_error', 'unavailable', 'geo_restricted', 'inconclusive'));
  get diagnostics n = row_count;
  return n;
end $$;

-- «أعد تعيين المعرّف» / طلب الحذف (§20.2): يحذف الجهاز وأحداثه الخام (التجميعات لا تحمل معرّفه أصلًا)
create or replace function public.telemetry_forget(p_installation uuid) returns void
language sql security definer set search_path = public, pg_temp as $$
  delete from public.installations where id = p_installation;
$$;

revoke all on function public.telemetry_ingest(uuid, text, text, text, jsonb, text), public.telemetry_forget(uuid) from public;
grant execute on function public.telemetry_ingest(uuid, text, text, text, jsonb, text), public.telemetry_forget(uuid) to anon, authenticated;

-- ─── 5) التجميع اليومي + الاحتفاظ (مهمة مجدولة في برنامج المدير، D-13) ──────
create or replace function public.admin_telemetry_rollup(p_from date default current_date - 1) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_rows int; v_events int; v_inst int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  -- لا يُعاد تجميع يوم لم تعد أحداثه الخام موجودة (حتى لا تُمسح تجميعاته)
  p_from := greatest(p_from, (now() - interval '29 days')::date);
  delete from public.playback_stats_daily where day >= p_from;
  insert into public.playback_stats_daily (day, stream_id, channel_id, platform, country, attempts, successes, abandoned,
                                           sessions_30s, watch_seconds, ttff_p50_ms, ttff_p90_ms, failures)
  select e.day, e.stream_id, min(e.channel_id::text)::uuid, e.platform, e.country,
         count(*) filter (where e.outcome <> 'abandoned'),
         count(*) filter (where e.outcome = 'success'),
         count(*) filter (where e.outcome = 'abandoned'),
         count(*) filter (where e.watch_seconds >= 30),
         coalesce(sum(e.watch_seconds), 0),
         (percentile_cont(0.5) within group (order by e.first_frame_ms) filter (where e.outcome = 'success'))::int,
         (percentile_cont(0.9) within group (order by e.first_frame_ms) filter (where e.outcome = 'success'))::int,
         coalesce((select jsonb_object_agg(f.error_code, f.c) from (
                     select x.error_code, count(*) c from public.playback_events x
                      where x.outcome = 'failure' and (x.at at time zone 'utc')::date = e.day and x.stream_id = e.stream_id
                        and x.platform = e.platform and coalesce(x.country, '') = e.country
                      group by x.error_code) f), '{}'::jsonb)
    from (select (at at time zone 'utc')::date as day, stream_id, channel_id, platform, coalesce(country, '') as country,
                 outcome, first_frame_ms, watch_seconds
            from public.playback_events where at >= p_from::timestamp at time zone 'utc') e
   group by e.day, e.stream_id, e.platform, e.country;
  get diagnostics v_rows = row_count;

  delete from public.playback_events where at < now() - interval '30 days';
  get diagnostics v_events = row_count;
  delete from public.installations where last_seen_at < now() - interval '90 days';
  get diagnostics v_inst = row_count;
  return jsonb_build_object('rows', v_rows, 'purged_events', v_events, 'purged_installations', v_inst);
end $$;
revoke all on function public.admin_telemetry_rollup(date) from public, anon;
grant execute on function public.admin_telemetry_rollup(date) to authenticated;

-- ─── 6) تنبيهات المدير (ADM-A3) ──────────────────────────────────────────────
create table if not exists public.admin_alerts (
  id          bigint generated always as identity primary key,
  kind        text not null check (kind in ('epg_failed', 'epg_stale', 'source_failed', 'import_failed', 'success_drop',
                                            'backup_failed', 'backup_stale', 'repeated_reports', 'connector_stopped', 'task_failed')),
  severity    text not null default 'warning' check (severity in ('info', 'warning', 'critical')),
  dedupe_key  text not null check (length(dedupe_key) <= 200),
  title       text not null check (length(title) <= 300),
  detail      jsonb not null default '{}'::jsonb,
  ref_type    text,                                        -- channel / stream / task / epg_source / source …
  ref_id      text,
  status      text not null default 'new' check (status in ('new', 'seen', 'resolved')),
  occurrences integer not null default 1,
  first_at    timestamptz not null default now(),
  last_at     timestamptz not null default now(),
  resolved_at timestamptz
);
create unique index if not exists admin_alerts_open_key on public.admin_alerts(dedupe_key) where status <> 'resolved';
create index if not exists admin_alerts_status_idx on public.admin_alerts(status, last_at desc);
alter table public.admin_alerts enable row level security;
create policy "admin all" on public.admin_alerts for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.admin_alerts from anon;
grant select, update on public.admin_alerts to authenticated;

-- رفع تنبيه (أو زيادة تكرار المفتوح نفسه) — يستدعيه الفحص أدناه وبرنامج المدير (مثل توقف موصل)
create or replace function public.admin_alert_raise(p_kind text, p_severity text, p_key text, p_title text,
                                                    p_detail jsonb default '{}'::jsonb, p_ref_type text default null, p_ref_id text default null)
returns bigint
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id bigint;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  update public.admin_alerts
     set occurrences = occurrences + 1, last_at = now(), detail = coalesce(p_detail, detail), title = p_title,
         severity = p_severity, status = case when status = 'seen' then 'seen' else 'new' end
   where dedupe_key = p_key and status <> 'resolved'
  returning id into v_id;
  if v_id is null then
    insert into public.admin_alerts (kind, severity, dedupe_key, title, detail, ref_type, ref_id)
    values (p_kind, p_severity, p_key, p_title, coalesce(p_detail, '{}'::jsonb), p_ref_type, p_ref_id)
    returning id into v_id;
  end if;
  return v_id;
end $$;

-- فحص الشروط على الخادم (مهمة «alerts» كل ساعة). لا يحل التنبيهات تلقائيًا: الحل قرار المدير.
create or replace function public.admin_alerts_scan() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int := 0; r record; v_last timestamptz; v_att int; v_ok int; v_prev numeric;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;

  -- مهام مجدولة فشل آخر تشغيل لها
  for r in select key, last_run_at from public.scheduled_tasks where enabled and last_status = 'failed' loop
    perform public.admin_alert_raise(
      case r.key when 'epg' then 'epg_failed' when 'backup' then 'backup_failed' when 'sources' then 'import_failed' else 'task_failed' end,
      case when r.key in ('backup', 'epg') then 'critical' else 'warning' end,
      'task:' || r.key, r.key, jsonb_build_object('last_run_at', r.last_run_at), 'task', r.key);
    n := n + 1;
  end loop;

  -- مصادر دليل فشلت
  for r in select id, name, last_error from public.epg_sources where enabled and last_status = 'failed' loop
    perform public.admin_alert_raise('epg_failed', 'warning', 'epg_source:' || r.id, r.name, jsonb_build_object('error', r.last_error), 'epg_source', r.id::text);
    n := n + 1;
  end loop;

  -- الدليل لم يتحدّث منذ 48 ساعة (من أي مصدر: البرنامج أو مزامنة GitHub)
  select max(ran_at) into v_last from public.epg_runs where programmes > 0;
  if v_last is null or v_last < now() - interval '48 hours' then
    perform public.admin_alert_raise('epg_stale', 'critical', 'epg_stale', 'epg', jsonb_build_object('last_ok', v_last));
    n := n + 1;
  end if;

  -- لا نسخة احتياطية ناجحة منذ 48 ساعة (والمهمة مفعّلة)
  if exists (select 1 from public.scheduled_tasks where key = 'backup' and enabled) then
    select max(started_at) into v_last from public.task_runs where task_key = 'backup' and status = 'ok';
    if v_last is null or v_last < now() - interval '48 hours' then
      perform public.admin_alert_raise('backup_stale', 'critical', 'backup_stale', 'backup', jsonb_build_object('last_ok', v_last));
      n := n + 1;
    end if;
  end if;

  -- انخفاض نسبة نجاح التشغيل: أمس بعيّنة ≥ 100 تحت 70%، أو أقل بـ 15 نقطة من متوسط الأسبوع السابق
  select sum(attempts), sum(successes) into v_att, v_ok from public.playback_stats_daily where day = current_date - 1;
  if coalesce(v_att, 0) >= 100 then
    select sum(successes)::numeric / nullif(sum(attempts), 0) into v_prev
      from public.playback_stats_daily where day between current_date - 8 and current_date - 2;
    if v_ok::numeric / v_att < 0.7 or (v_prev is not null and v_ok::numeric / v_att < v_prev - 0.15) then
      perform public.admin_alert_raise('success_drop', 'critical', 'success_drop:' || (current_date - 1),
        'success', jsonb_build_object('rate', round(v_ok::numeric / v_att, 3), 'previous', round(v_prev, 3), 'attempts', v_att));
      n := n + 1;
    end if;
  end if;

  -- بلاغات متكررة: 3 بلاغات مفتوحة أو أكثر على القناة نفسها خلال 24 ساعة
  for r in select rp.channel_id, count(*) c, max(coalesce(ch.name_ar, ch.name)) nm
             from public.reports rp join public.channels ch on ch.id = rp.channel_id
            where rp.status = 'open' and rp.created_at > now() - interval '24 hours'
            group by rp.channel_id having count(*) >= 3 loop
    perform public.admin_alert_raise('repeated_reports', 'warning', 'reports:' || r.channel_id, coalesce(r.nm, ''),
      jsonb_build_object('count', r.c), 'channel', r.channel_id::text);
    n := n + 1;
  end loop;
  return n;
end $$;

revoke all on function public.admin_alert_raise(text, text, text, text, jsonb, text, text), public.admin_alerts_scan() from public, anon;
grant execute on function public.admin_alert_raise(text, text, text, text, jsonb, text, text), public.admin_alerts_scan() to authenticated;

-- ─── 7) المهام المجدولة الجديدة ──────────────────────────────────────────────
insert into public.scheduled_tasks(key, interval_min) values ('telemetry_rollup', 1440), ('alerts', 60)
on conflict do nothing;

notify pgrst, 'reload schema';
