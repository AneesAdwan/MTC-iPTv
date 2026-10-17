-- ROLLBACK of migration 20261017000900_stream_source_attributions (SuperAdmin plan §9.2).
-- Run manually (SQL Editor / psql) only if 0009 must be undone, BEFORE the 0008 rollback, then delete
-- its row from supabase_migrations.schema_migrations.
-- ⚠ Loses every second-and-later source of a stream (only streams.source_id survives) and puts back the
--   ON DELETE CASCADE that deletes a source's streams (Appendix B م-15). Streams are not touched.
begin;

drop function if exists public.admin_source_remove(uuid, text);
drop function if exists public.admin_source_sync_finish(uuid, text[]);
drop trigger if exists streams_source_compat on public.streams;
drop function if exists public.streams_source_compat();
drop function if exists public.stream_attributions_backfill();
drop table if exists public.stream_source_attributions;
drop index if exists public.streams_url_norm_idx;

alter table public.streams drop constraint if exists streams_source_id_fkey;
alter table public.streams add constraint streams_source_id_fkey
  foreign key (source_id) references public.playlist_sources(id) on delete cascade;
comment on column public.streams.source_id is null;

-- baseline bodies (20261015000000_baseline.sql)
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

drop function if exists public.url_norm(text);

create or replace function public.admin_finish_import(p_source uuid, p_urls text[]) returns jsonb
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

create or replace function public.admin_delete_source(p_source uuid) returns jsonb
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
      update playlist_sources p set stream_count = (select count(*) from streams where source_id = p.id),
                                    channel_count = (select count(distinct channel_id) from streams where source_id = p.id) where true;
    else raise exception 'unknown action %', p_action;
  end case;
  get diagnostics n = row_count;
  return n;
end $$;

commit;
notify pgrst, 'reload schema';
