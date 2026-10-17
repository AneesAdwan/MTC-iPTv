-- pgTAP — 0009 multi-source attribution (SuperAdmin plan §9.2, م-15). Run: supabase test db
-- Proves: same URL from two sources = one stream + two attributions; vanished from one source only
-- flips present for that source; removing a source deletes no stream; backfill = streams.source_id;
-- legacy destructive RPCs refuse; viewers have no access.
begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

-- ── fixtures ────────────────────────────────────────────────────────────────
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000009a1', 'admin9@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000009a1');
insert into auth.sessions (id, user_id, aal, created_at, updated_at) values
  ('90000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-0000000009a1', 'aal2', now(), now());

insert into public.playlist_sources (id, name, url) values
  ('90000000-0000-0000-0000-00000000000a', 'Source A', 'https://a.example/list9.m3u'),
  ('90000000-0000-0000-0000-00000000000b', 'Source B', 'https://b.example/list9.m3u'),
  ('90000000-0000-0000-0000-00000000000c', 'Source C', 'https://c.example/list9.m3u');

create function pg_temp.as_admin(totp_age integer default 60) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object(
           'sub', '00000000-0000-0000-0000-0000000009a1', 'role', 'authenticated', 'aal', 'aal2',
           'session_id', '90000000-0000-0000-0000-0000000000a1',
           'amr', jsonb_build_array(jsonb_build_object('method', 'totp', 'timestamp', extract(epoch from now())::bigint - totp_age))
         )::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_admin_aal1() returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object(
           'sub', '00000000-0000-0000-0000-0000000009a1', 'role', 'authenticated', 'aal', 'aal1',
           'session_id', '90000000-0000-0000-0000-0000000000a1')::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true), set_config('role', 'anon', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;
create function pg_temp.attr(p_url text, p_source text) returns boolean language sql as $$
  select a.present from public.stream_source_attributions a join public.streams s on s.id = a.stream_id
   where s.url = p_url and a.source_id = p_source::uuid
$$;

-- ── 1) backfill + compat trigger ────────────────────────────────────────────
select set_config('mtc.review_bypass', 'on', true);
insert into public.channels (id, uid, number, name, is_published) values
  ('90000000-0000-0000-0000-0000000000c1', 'Back9.test', 99001, 'Backfill 9', true);
select set_config('mtc.review_bypass', '', true);
insert into public.streams (id, channel_id, source_id, url) values
  ('90000000-0000-0000-0000-0000000000e1', '90000000-0000-0000-0000-0000000000c1', '90000000-0000-0000-0000-00000000000c', 'https://bf.example/1.m3u8'),
  ('90000000-0000-0000-0000-0000000000e2', '90000000-0000-0000-0000-0000000000c1', '90000000-0000-0000-0000-00000000000c', 'https://bf.example/2.m3u8'),
  ('90000000-0000-0000-0000-0000000000e3', '90000000-0000-0000-0000-0000000000c1', null, 'https://bf.example/manual.m3u8');
select is((select count(*) from public.stream_source_attributions where stream_id in
          ('90000000-0000-0000-0000-0000000000e1', '90000000-0000-0000-0000-0000000000e2', '90000000-0000-0000-0000-0000000000e3'))::int, 2,
  'compat trigger: inserting a stream with source_id creates its attribution (manual stream gets none)');

delete from public.stream_source_attributions where stream_id in ('90000000-0000-0000-0000-0000000000e1', '90000000-0000-0000-0000-0000000000e2');
select ok(public.stream_attributions_backfill() >= 2, 'backfill inserts the missing attributions');
select is((select count(*) from public.streams s where s.source_id is not null
            and not exists (select 1 from public.stream_source_attributions a where a.stream_id = s.id and a.source_id = s.source_id))::int, 0,
  'backfill: every stream with source_id has exactly that attribution');
select is((select count(*) from public.stream_source_attributions a join public.streams s on s.id = a.stream_id where s.source_id is null)::int, 0,
  'backfill: streams without source_id get no attribution');
select is((select present from public.stream_source_attributions where stream_id = '90000000-0000-0000-0000-0000000000e1'), true, 'backfilled rows are present');
select is(public.stream_attributions_backfill(), 0, 'backfill is idempotent');

-- the temporary SuperAdmin's removeSource() writes source_id = null directly: detaches that source
update public.streams set source_id = null where id = '90000000-0000-0000-0000-0000000000e2';
select is((select count(*) from public.stream_source_attributions where stream_id = '90000000-0000-0000-0000-0000000000e2')::int, 0,
  'compat trigger: clearing the deprecated source_id detaches that source');

-- ── 2) same URL from two sources -> one stream, two attributions ───────────
select pg_temp.as_admin();
select lives_ok($$ select public.admin_import('90000000-0000-0000-0000-00000000000a',
  '[{"uid":"Multi9.test","name":"Multi 9","url":"https://cdn9.example/live/multi.m3u8"},
    {"uid":"Solo9.test","name":"Solo 9","url":"https://cdn9.example/live/solo.m3u8"}]'::jsonb) $$, 'import from source A');
select lives_ok($$ select public.admin_import('90000000-0000-0000-0000-00000000000b',
  '[{"uid":"Multi9.test","name":"Multi 9","url":"https://cdn9.example/live/multi.m3u8"},
    {"uid":"Multi9.test","name":"Multi 9","url":"https://CDN9.example/live/variant.m3u8/"}]'::jsonb) $$, 'import the same URL from source B');
select lives_ok($$ select public.admin_import('90000000-0000-0000-0000-00000000000c',
  '[{"uid":"Multi9.test","name":"Multi 9","url":"https://cdn9.example/live/variant.m3u8"}]'::jsonb) $$, 'source C lists another spelling of B''s URL');
select pg_temp.as_owner();
select is((select count(*) from public.streams where url = 'https://cdn9.example/live/multi.m3u8')::int, 1, 'one stream for the shared URL');
select is((select count(*) from public.stream_source_attributions a join public.streams s on s.id = a.stream_id
            where s.url = 'https://cdn9.example/live/multi.m3u8')::int, 2, 'two attributions for the shared URL');
select is((select source_id::text from public.streams where url = 'https://cdn9.example/live/multi.m3u8'), '90000000-0000-0000-0000-00000000000a',
  'deprecated source_id keeps the first source');
select is((select external_id from public.stream_source_attributions a join public.streams s on s.id = a.stream_id
            where s.url = 'https://cdn9.example/live/multi.m3u8' and a.source_id = '90000000-0000-0000-0000-00000000000b'), 'Multi9.test',
  'attribution keeps the source''s record id');
select is((select count(*) from public.streams where public.url_norm(url) = public.url_norm('https://cdn9.example/live/variant.m3u8'))::int, 1,
  'host case / trailing slash variants are one stream');
select is((select count(*) from public.stream_source_attributions a join public.streams s on s.id = a.stream_id
            where public.url_norm(s.url) = public.url_norm('https://cdn9.example/live/variant.m3u8'))::int, 2,
  '... attributed to both sources that list it');

-- ── 3) vanished from one source, present in another -> stream stays active ─
select pg_temp.as_admin();
select is(public.admin_source_sync_finish('90000000-0000-0000-0000-00000000000a', array['https://cdn9.example/live/solo.m3u8']) ->> 'vanished', '1',
  'A no longer lists the shared URL: 1 vanished');
select pg_temp.as_owner();
select is(pg_temp.attr('https://cdn9.example/live/multi.m3u8', '90000000-0000-0000-0000-00000000000a'), false, 'present = false for source A');
select is(pg_temp.attr('https://cdn9.example/live/multi.m3u8', '90000000-0000-0000-0000-00000000000b'), true, 'still present for source B');
select is((select is_active::text || '|' || health_state from public.streams where url = 'https://cdn9.example/live/multi.m3u8'), 'true|inconclusive',
  'the stream itself stays active and untouched');

select pg_temp.as_admin();
select is(public.admin_source_sync_finish('90000000-0000-0000-0000-00000000000a', array[]::text[]) ->> 'orphaned', '1',
  'solo stream vanished from its only source is reported as orphaned');
select pg_temp.as_owner();
select is((select count(*) from public.streams where url = 'https://cdn9.example/live/solo.m3u8')::int, 1, 'orphaned stream is NOT deleted');
select is((select stream_count from public.playlist_sources where id = '90000000-0000-0000-0000-00000000000a'), 0, 'source A count = present attributions');

-- ── 4) removing a source deletes no streams ────────────────────────────────
create temp table t_before as select count(*) as n from public.streams;
select pg_temp.as_admin(1200);
select throws_ok($$ select public.admin_source_remove('90000000-0000-0000-0000-00000000000b', 'x') $$, '42501', null, 'removing a source needs a fresh TOTP');
select pg_temp.as_admin(30);
select is(public.admin_source_remove('90000000-0000-0000-0000-00000000000b', 'test') ->> 'detached', '2', 'source B detached from its 2 streams');
select pg_temp.as_owner();
select is((select count(*) from public.streams), (select n from t_before), 'no stream deleted by removing a source');
select is((select is_active from public.playlist_sources where id = '90000000-0000-0000-0000-00000000000b'), false, 'removed source is disabled');
select throws_ok($$ delete from public.playlist_sources where id = '90000000-0000-0000-0000-00000000000a' $$, '23503', null,
  'an attributed source cannot be hard-deleted (on delete restrict)');

-- ── 5) legacy destructive RPCs refuse ───────────────────────────────────────
select pg_temp.as_admin();
select throws_ok($$ select public.admin_delete_source('90000000-0000-0000-0000-00000000000a') $$, '0A000', null, 'admin_delete_source refuses');
select throws_ok($$ select public.admin_finish_import('90000000-0000-0000-0000-00000000000a', array[]::text[]) $$, '0A000', null, 'admin_finish_import refuses');

-- ── 6) access ───────────────────────────────────────────────────────────────
select throws_ok($$ insert into public.stream_source_attributions(stream_id, source_id) values ('90000000-0000-0000-0000-0000000000e3', '90000000-0000-0000-0000-00000000000a') $$,
  '42501', null, 'even the admin cannot write attributions directly (RPCs only)');
select pg_temp.as_admin_aal1();
select is((select count(*) from public.stream_source_attributions)::int, 0, 'admin without MFA reads no attributions');
select pg_temp.as_anon();
select throws_ok($$ select * from public.stream_source_attributions $$, '42501', null, 'viewers (anon) have no access');

select * from finish();
rollback;
