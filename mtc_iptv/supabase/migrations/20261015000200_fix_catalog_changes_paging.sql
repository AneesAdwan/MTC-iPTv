-- ════════════════════════════════════════════════════════════════════════════
-- Migration 0003 — fix catalog_changes() paging (found by a read-only sync against production)
--
-- Bug in 0002: channels, streams and tombstones were paged independently with the same `since`,
-- and the returned `rev` was the MAX over all three. When one table filled its page while another
-- still had rows with lower revisions, the next call (since = that max) skipped them.
-- Production: 359 channels, page 200 -> only 200 channels reached the device.
--
-- Fix: the page is cut at the LOWEST last-revision among the tables that filled their page.
-- Every table returns only rows with since < rev <= cut, so nothing can be skipped; `more` is true
-- whenever a cut happened. Function-only change: no table or data is touched.
-- ════════════════════════════════════════════════════════════════════════════

create or replace function public.catalog_changes(since bigint default 0, max_rows integer default 2000)
returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  c_n int; c_max bigint;
  s_n int; s_max bigint;
  t_n int; t_max bigint;
  cut bigint;
  more boolean;
begin
  select count(*), max(catalog_rev) into c_n, c_max
    from (select catalog_rev from public.channels where catalog_rev > since order by catalog_rev limit max_rows) x;
  select count(*), max(catalog_rev) into s_n, s_max
    from (select catalog_rev from public.streams where catalog_rev > since order by catalog_rev limit max_rows) x;
  select count(*), max(rev) into t_n, t_max
    from (select rev from public.catalog_tombstones where rev > since order by rev limit max_rows) x;

  -- least() ignores nulls: only tables that filled their page constrain the cut
  cut := least(case when c_n = max_rows then c_max end,
               case when s_n = max_rows then s_max end,
               case when t_n = max_rows then t_max end);
  more := cut is not null;
  if not more then
    cut := greatest(since, coalesce(c_max, 0), coalesce(s_max, 0), coalesce(t_max, 0));
  end if;

  return jsonb_build_object(
    'rev', cut,
    'more', more,
    'channels', coalesce((select jsonb_agg(jsonb_build_object(
        'id', id, 'uid', uid, 'number', number, 'name_ar', name_ar, 'name_en', name_en, 'alt_names', alt_names,
        'network', network, 'logo_url', case when logo_status = 'broken' then null else logo_url end,
        'country', country_code, 'category', category_slug, 'categories', extra_categories, 'language', language_code,
        'quality', quality, 'featured', is_featured, 'sort', sort_order, 'epg_id', epg_id, 'epg_offset', epg_offset_minutes,
        'family', family_key, 'parental', parental_locked, 'published_at', published_at) order by catalog_rev)
      from public.channels where catalog_rev > since and catalog_rev <= cut and publish_state = 'published'), '[]'::jsonb),
    'streams', coalesce((select jsonb_agg(jsonb_build_object(
        'id', s.id, 'channel_id', s.channel_id, 'url', s.url, 'label', coalesce(s.label, public.server_of(s.host)),
        'quality', s.quality, 'priority', s.priority, 'user_agent', s.user_agent, 'referrer', s.referrer,
        'headers', s.headers, 'protocol', s.protocol, 'health', s.health_state, 'score', s.health_score) order by s.catalog_rev)
      from public.streams s join public.channels c on c.id = s.channel_id
      where s.catalog_rev > since and s.catalog_rev <= cut
        and s.health_state <> 'disabled' and c.publish_state = 'published'), '[]'::jsonb),
    'removed_channels', coalesce((select jsonb_agg(id) from public.channels
                                  where catalog_rev > since and catalog_rev <= cut and publish_state <> 'published'), '[]'::jsonb)
      || coalesce((select jsonb_agg(row_id) from public.catalog_tombstones
                   where rev > since and rev <= cut and table_name = 'channels'), '[]'::jsonb),
    'removed_streams', coalesce((select jsonb_agg(s.id) from public.streams s join public.channels c on c.id = s.channel_id
                                 where s.catalog_rev > since and s.catalog_rev <= cut
                                   and (s.health_state = 'disabled' or c.publish_state <> 'published')), '[]'::jsonb)
      || coalesce((select jsonb_agg(row_id) from public.catalog_tombstones
                   where rev > since and rev <= cut and table_name = 'streams'), '[]'::jsonb)
  );
end $$;

revoke all on function public.catalog_changes(bigint, integer) from public;
grant execute on function public.catalog_changes(bigint, integer) to anon, authenticated;
notify pgrst, 'reload schema';
