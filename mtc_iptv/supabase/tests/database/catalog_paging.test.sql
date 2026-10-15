-- pgTAP — catalog_changes paging must never skip rows (regression for the 0002 bug found on production:
-- 359 channels / page 200 -> only 200 arrived). Rebuilds the catalog from tiny pages and compares.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

select set_config('test.since', (select (case when is_called then last_value else last_value - 1 end)::text from public.catalog_rev_seq) /* fresh sequence: last_value=1 but not yet handed out */, false);

-- 25 published channels whose streams are inserted AFTER all channels (streams get higher revisions —
-- exactly the shape that triggered the bug), plus 3 hidden channels.
select set_config('mtc.review_bypass', 'on', true);
insert into public.channels (uid, number, name, is_published)
select 'Page.' || g, 8000 + g, 'Paging ' || g, true from generate_series(1, 25) g;
select set_config('mtc.review_bypass', '', true);
insert into public.channels (uid, number, name, is_published) select 'Hidden.' || g, 8100 + g, 'Hidden ' || g, true from generate_series(1, 3) g;
insert into public.streams (channel_id, url)
select c.id, 'https://cdn.example/' || c.uid || '/s' || k || '.m3u8'
from public.channels c cross join generate_series(1, 2) k where c.uid like 'Page.%';

create temp table got_ch (id uuid);
create temp table got_st (id uuid);
create temp table got_rm (id uuid);
do $$
declare since bigint := current_setting('test.since')::bigint; page jsonb; pages int := 0;
begin
  loop
    page := public.catalog_changes(since, 7);   -- tiny pages
    insert into got_ch select (e ->> 'id')::uuid from jsonb_array_elements(page -> 'channels') e;
    insert into got_st select (e ->> 'id')::uuid from jsonb_array_elements(page -> 'streams') e;
    insert into got_rm select (e #>> '{}')::uuid from jsonb_array_elements(page -> 'removed_channels') e;
    pages := pages + 1;
    exit when not (page ->> 'more')::boolean or pages > 100;
    since := (page ->> 'rev')::bigint;
  end loop;
  perform set_config('test.pages', pages::text, true);
end $$;

select is((select count(distinct id) from got_ch)::int, 25, 'all 25 published channels arrive through 7-row pages');
select is((select count(distinct id) from got_st)::int, 50, 'all 50 streams arrive');
select is((select count(distinct id) from got_rm)::int, 3, 'the 3 hidden channels arrive as removals');
select ok(current_setting('test.pages')::int > 3, 'the catalog really was paged');

select * from finish();
rollback;
