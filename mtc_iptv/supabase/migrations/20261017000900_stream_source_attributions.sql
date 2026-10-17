-- ════════════════════════════════════════════════════════════════════════════
-- 0009 — Multi-source attribution (SuperAdmin plan §9.2, fixes Appendix B م-15).
--
-- Before: streams.source_id = ONE source per URL (the second source of the same URL was lost:
-- coalesce(streams.source_id, excluded.source_id)), and the FK was ON DELETE CASCADE, so
-- deleting a source deleted all of its streams — even approved ones or ones another source has.
--
-- Now:
--   • stream_source_attributions(stream_id, source_id): every source that lists the stream,
--     with external_id, first/last seen and present (= still in that source's last fetch).
--   • backfilled from streams.source_id (production pre-check: 527 rows).
--   • streams.source_id stays (DEPRECATED, removed in phase 8) with ON DELETE SET NULL.
--   • admin_import (same signature) also upserts an attribution for p_source.
--   • vanished from a source  -> present = false for THAT source only (admin_source_sync_finish).
--   • removing a source       -> admin_source_remove: detach + disable, no stream is deleted.
--   • legacy destructive admin_finish_import / admin_delete_source now raise (app never calls them).
-- Rollback: docs/migration/down/20261017000900_stream_source_attributions.down.sql
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1) URL normalization used for matching (lower scheme+host, no trailing slash) ─
create or replace function public.url_norm(u text) returns text
language sql immutable parallel safe as $$
  select case when u ~ '^[a-zA-Z][a-zA-Z0-9+.-]*://'
              then lower(substring(u from '^[a-zA-Z][a-zA-Z0-9+.-]*://[^/?#]*'))
                   || regexp_replace(regexp_replace(u, '^[a-zA-Z][a-zA-Z0-9+.-]*://[^/?#]*', ''), '/+$', '')
              else regexp_replace(u, '/+$', '') end
$$;
grant execute on function public.url_norm(text) to anon, authenticated;
create index if not exists streams_url_norm_idx on public.streams (public.url_norm(url));

-- ─── 2) the attribution table ──────────────────────────────────────────────
create table if not exists public.stream_source_attributions (
  stream_id     uuid not null references public.streams(id) on delete cascade,            -- deleting a stream drops only its attributions
  source_id     uuid not null references public.playlist_sources(id) on delete restrict,  -- an attributed source cannot be deleted; use admin_source_remove
  external_id   text check (external_id is null or length(external_id) <= 500),            -- the record id at the source (tvg-id, iptv-org id…)
  first_seen_at timestamptz not null default now(),
  last_seen_at  timestamptz not null default now(),
  present       boolean not null default true,                                             -- still listed in that source's last successful fetch?
  primary key (stream_id, source_id)
);
create index if not exists ssa_source_idx on public.stream_source_attributions(source_id, present);

alter table public.stream_source_attributions enable row level security;
drop policy if exists "admin read" on public.stream_source_attributions;
create policy "admin read" on public.stream_source_attributions for select to authenticated using ((select public.is_admin()));
revoke all on public.stream_source_attributions from anon, authenticated;
grant select on public.stream_source_attributions to authenticated;   -- writes only through the functions below

-- ─── 3) backfill (idempotent; also used by the tests) ──────────────────────
create or replace function public.stream_attributions_backfill() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  insert into public.stream_source_attributions (stream_id, source_id, first_seen_at, last_seen_at, present)
  select s.id, s.source_id, s.created_at, greatest(s.created_at, coalesce(p.last_import_at, s.created_at)), true
    from public.streams s join public.playlist_sources p on p.id = s.source_id
  on conflict (stream_id, source_id) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.stream_attributions_backfill() from public, anon, authenticated;

select public.stream_attributions_backfill();

-- ─── 4) streams.source_id: deprecated, ON DELETE SET NULL ─────────────────
alter table public.streams drop constraint if exists streams_source_id_fkey;
alter table public.streams add constraint streams_source_id_fkey
  foreign key (source_id) references public.playlist_sources(id) on delete set null;
comment on column public.streams.source_id is
  'DEPRECATED (SuperAdmin plan §9.2): first source only, kept for the temporary SuperAdmin and asadmin. '
  'Source membership lives in stream_source_attributions. ON DELETE SET NULL. Removed in phase 8.';

-- Compatibility for writers of the deprecated column (temporary SuperAdmin, restore, asadmin):
--   source_id set   -> attribution upserted (present = true)
--   source_id moved -> the old source's attribution is detached ("this stream no longer comes from X")
create or replace function public.streams_source_compat() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if tg_op = 'UPDATE' and old.source_id is not null and new.source_id is distinct from old.source_id then
    delete from public.stream_source_attributions where stream_id = old.id and source_id = old.source_id;
  end if;
  if new.source_id is not null and (tg_op = 'INSERT' or new.source_id is distinct from old.source_id) then
    insert into public.stream_source_attributions (stream_id, source_id)
    values (new.id, new.source_id)
    on conflict (stream_id, source_id) do update set present = true, last_seen_at = now();
  end if;
  return null;
end $$;
drop trigger if exists streams_source_compat on public.streams;
create trigger streams_source_compat after insert or update of source_id on public.streams
  for each row execute function public.streams_source_compat();

-- ─── 5) admin_import: same signature and result; now records every source ─
-- p_items: [{uid,name,logo,country,category,language,quality,url,label,network,external_id?}]
create or replace function public.admin_import(p_source uuid, p_items jsonb, p_publish boolean default true) returns jsonb
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

  -- a URL already known under another spelling (host case / trailing slash) is the same stream
  insert into streams (channel_id, source_id, url, label, quality)
  select c.id, p_source, x.url, nullif(x.label, ''), x.quality
  from jsonb_to_recordset(p_items) as x(uid text, url text, label text, quality text)
  join channels c on c.uid = x.uid
  where x.url ~ '^https?://' and length(x.url) <= 2000
    and not exists (select 1 from streams s where public.url_norm(s.url) = public.url_norm(x.url) and s.url <> x.url)
  on conflict (url) do update set source_id = coalesce(streams.source_id, excluded.source_id);
  get diagnostics v_streams = row_count;

  -- every source that lists the URL keeps its own attribution (م-15)
  if p_source is not null then
    insert into stream_source_attributions as a (stream_id, source_id, external_id)
    select distinct on (s.id) s.id, p_source, left(coalesce(nullif(x.external_id, ''), nullif(x.uid, '')), 500)
    from jsonb_to_recordset(p_items) as x(uid text, url text, external_id text)
    join streams s on public.url_norm(s.url) = public.url_norm(x.url)
    where x.url ~ '^https?://' and length(x.url) <= 2000
    order by s.id
    on conflict (stream_id, source_id) do update
       set present = true, last_seen_at = now(), external_id = coalesce(excluded.external_id, a.external_id);
  end if;

  return jsonb_build_object('channels', v_channels, 'streams', v_streams);
end $$;

-- ─── 6) end of a source fetch: vanished -> present = false (never deletes) ─
-- p_urls = every URL the source listed in this fetch. Returns counts; "orphaned" = streams of this
-- source that now have no present attribution from any source (candidates for review, untouched).
create or replace function public.admin_source_sync_finish(p_source uuid, p_urls text[]) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_vanished int; v_orphaned int; v_present int; v_channels int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  if not exists (select 1 from playlist_sources where id = p_source) then raise exception 'unknown source' using errcode = 'P0002'; end if;
  perform set_config('mtc.reason', 'import', true);

  with listed as (select distinct public.url_norm(u) as k from unnest(coalesce(p_urls, '{}')) u)
  update stream_source_attributions a set present = false
    from streams s
   where a.source_id = p_source and a.present and s.id = a.stream_id
     and not exists (select 1 from listed where listed.k = public.url_norm(s.url));
  get diagnostics v_vanished = row_count;

  select count(*) into v_orphaned
    from stream_source_attributions a
   where a.source_id = p_source and not a.present
     and not exists (select 1 from stream_source_attributions b where b.stream_id = a.stream_id and b.present);

  select count(*), count(distinct s.channel_id) into v_present, v_channels
    from stream_source_attributions a join streams s on s.id = a.stream_id
   where a.source_id = p_source and a.present;

  update playlist_sources set status = 'ready', last_error = null, last_import_at = now(),
         stream_count = v_present, channel_count = v_channels
   where id = p_source;
  return jsonb_build_object('vanished', v_vanished, 'orphaned', v_orphaned, 'present', v_present, 'channels', v_channels);
end $$;

-- ─── 7) remove a source: detach + disable (no stream or channel is deleted) ─
create or replace function public.admin_source_remove(p_source uuid, p_reason text default null) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_detached int; v_orphaned int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  if not public.is_admin_fresh() then
    raise exception 'recent TOTP verification required' using errcode = '42501', hint = 'reauthenticate';
  end if;
  if not exists (select 1 from playlist_sources where id = p_source) then raise exception 'unknown source' using errcode = 'P0002'; end if;
  perform set_config('mtc.reason', left(coalesce(nullif(trim(p_reason), ''), 'source_remove'), 300), true);

  -- streams whose only attribution is this source (they stay, as manual-like streams, for review)
  select count(*) into v_orphaned
    from stream_source_attributions a
   where a.source_id = p_source
     and not exists (select 1 from stream_source_attributions b where b.stream_id = a.stream_id and b.source_id <> p_source);

  delete from stream_source_attributions where source_id = p_source;
  get diagnostics v_detached = row_count;
  update streams set source_id = null where source_id = p_source;   -- deprecated column follows

  update playlist_sources set is_active = false, auto_publish = false, stream_count = 0, channel_count = 0
   where id = p_source;
  return jsonb_build_object('source_id', p_source, 'detached', v_detached, 'orphaned', v_orphaned, 'disabled', true);
end $$;

revoke all on function public.admin_source_sync_finish(uuid, text[]), public.admin_source_remove(uuid, text) from public, anon;
grant execute on function public.admin_source_sync_finish(uuid, text[]), public.admin_source_remove(uuid, text) to authenticated;

-- ─── 8) admin_cleanup: source counts come from attributions ───────────────
create or replace function public.admin_cleanup(p_action text) returns integer
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
      update playlist_sources p
         set stream_count  = (select count(*) from stream_source_attributions a where a.source_id = p.id and a.present),
             channel_count = (select count(distinct s.channel_id) from stream_source_attributions a join streams s on s.id = a.stream_id
                               where a.source_id = p.id and a.present)
       where true;
    else raise exception 'unknown action %', p_action;
  end case;
  get diagnostics n = row_count;
  return n;
end $$;

-- ─── 9) legacy destructive functions: refuse (mtc_iptv/lib never calls them) ─
create or replace function public.admin_finish_import(p_source uuid, p_urls text[]) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  raise exception 'admin_finish_import was removed: it deleted streams. Use admin_source_sync_finish(source, urls) (marks vanished, deletes nothing).'
    using errcode = '0A000';
end $$;

create or replace function public.admin_delete_source(p_source uuid) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  raise exception 'admin_delete_source was removed: it deleted streams and channels. Use admin_source_remove(source, reason) (detach + disable, deletes nothing).'
    using errcode = '0A000';
end $$;

notify pgrst, 'reload schema';
