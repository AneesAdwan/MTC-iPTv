-- pgTAP — Phase 2 foundation (§19.2, §26.1). Run: supabase test db
-- Proves: admin = admin_users + MFA (aal2); nobody else writes; compat triggers keep the
-- legacy apps consistent; audit masks credentials; delta sync leaks nothing unpublished;
-- scheduler lease prevents two devices running the same task.
begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

-- ── fixtures ────────────────────────────────────────────────────────────────
-- sync assertions start from the revision just before the fixtures, so they hold on an
-- empty database AND on a full one (the rehearsal DB has 5,241 channels = several pages)
select set_config('test.since', (select (case when is_called then last_value else last_value - 1 end)::text from public.catalog_rev_seq) /* fresh sequence: last_value=1 but not yet handed out */, false);
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'admin@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000000b2', 'viewer@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000000a1');
-- 0008: is_admin() also needs the JWT's session alive in auth.sessions (as_user uses the user id as session id)
insert into auth.sessions (id, user_id, aal, created_at, updated_at) select id, id, 'aal2', now(), now() from auth.users where email like '%@test.local' and id::text like '00000000-0000-0000-0000-%' on conflict do nothing;

-- a published channel (review gate bypass = what the admin's manual add does) + a pending one
select set_config('mtc.review_bypass', 'on', true);
insert into public.channels (id, uid, number, name, is_published) values
  ('10000000-0000-0000-0000-000000000001', 'Pub.test', 9001, 'Published One', true);
select set_config('mtc.review_bypass', '', true);
insert into public.channels (id, uid, number, name, is_published) values
  ('10000000-0000-0000-0000-000000000002', 'Pend.test', 9002, 'Pending One', true);
insert into public.streams (id, channel_id, url, status) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'http://host.example/live/USER1/PASS1/255.ts', 'online'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'https://cdn.example/x/index.m3u8', 'unknown');

create function pg_temp.as_user(uid text, aal text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal, 'session_id', uid)::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true),
         set_config('role', 'anon', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

-- ── 1) is_admin(): admin_users + aal2 ───────────────────────────────────────
select pg_temp.as_anon();
select is(public.is_admin(), false, 'anon is not admin');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select is(public.is_admin(), false, 'admin WITHOUT MFA (aal1) is not admin');
select is((public.admin_status() ->> 'is_admin_user')::boolean, true, 'admin_status: recognised as the admin user (so the app asks for MFA)');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b2', 'aal2');
select is(public.is_admin(), false, 'non-admin with MFA is not admin');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select is(public.is_admin(), true, 'admin WITH MFA (aal2) is admin');

-- ── 2) RLS on new tables ────────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select throws_ok($$ insert into public.channel_field_provenance(channel_id, field, source_kind) values ('10000000-0000-0000-0000-000000000001','name_en','manual') $$,
  '42501', null, 'admin without MFA cannot write provenance');
select is((select count(*) from public.audit_logs)::int, 0, 'admin without MFA reads no audit rows');
select is((select count(*) from public.scheduled_tasks)::int, 0, 'admin without MFA sees no scheduled tasks');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b2', 'aal2');
select throws_ok($$ select public.admin_task_acquire('epg', 'dev-x') $$, '42501', null, 'non-admin cannot acquire a task lease');
select pg_temp.as_anon();
select throws_ok($$ select * from public.audit_logs $$, '42501', null, 'anon has no access to audit_logs');
select throws_ok($$ select * from public.catalog_tombstones $$, '42501', null, 'anon has no access to tombstones');

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select lives_ok($$ insert into public.channel_field_provenance(channel_id, field, source_kind, locked) values ('10000000-0000-0000-0000-000000000001','name_en','manual', true) $$,
  'admin with MFA writes provenance');
select ok((select count(*) from public.audit_logs) > 0, 'admin with MFA reads the audit log');

-- ── 3) compat triggers: legacy <-> new columns ──────────────────────────────
select pg_temp.as_owner();
select is((select publish_state from public.channels where uid = 'Pub.test'), 'published', 'legacy published -> publish_state published');
select is((select publish_state from public.channels where uid = 'Pend.test'), 'pending', 'review gate still holds: client insert -> pending');
select is((select name_en from public.channels where uid = 'Pub.test'), 'Published One', 'Latin name -> name_en');

update public.channels set publish_state = 'published' where uid = 'Pend.test';
select is((select is_published::text || '|' || coalesce(hidden_reason, '-') from public.channels where uid = 'Pend.test'), 'true|-',
  'new app publishes -> legacy is_published=true, hidden_reason=null');

update public.channels set is_published = false, hidden_reason = 'manual' where uid = 'Pend.test';
select is((select publish_state from public.channels where uid = 'Pend.test'), 'hidden', 'legacy panel hides -> publish_state hidden');

update public.channels set name_ar = 'قناة الاختبار' where uid = 'Pub.test';
select is((select name from public.channels where uid = 'Pub.test'), 'Published One', 'legacy name prefers name_en (old apps keep showing Latin)');
update public.channels set name = 'Published One HD' where uid = 'Pub.test';
select is((select name_en from public.channels where uid = 'Pub.test'), 'Published One HD', 'legacy rename flows into name_en');

select is((select has_credentials from public.streams where id = '20000000-0000-0000-0000-000000000001'), true, 'xtream URL flagged has_credentials');
select is((select protocol from public.streams where id = '20000000-0000-0000-0000-000000000001'), 'ts', 'protocol detected: ts');
select is((select protocol from public.streams where id = '20000000-0000-0000-0000-000000000002'), 'hls', 'protocol detected: hls');
select is((select health_state from public.streams where id = '20000000-0000-0000-0000-000000000001'), 'reachable', 'legacy online -> reachable (never assume playable)');
update public.streams set health_state = 'auth_failed' where id = '20000000-0000-0000-0000-000000000001';
select is((select status from public.streams where id = '20000000-0000-0000-0000-000000000001'), 'offline', 'new health auth_failed -> legacy status offline');

-- ── 4) audit masks credentials ──────────────────────────────────────────────
select ok((select bool_and(coalesce(after ->> 'url', '') not like '%PASS1%' and coalesce(before ->> 'url', '') not like '%PASS1%')
           from public.audit_logs where table_name = 'streams'), 'audit log never stores stream passwords');
select ok(exists (select 1 from public.audit_logs where table_name = 'streams' and after ->> 'url' like '%/live/••••/••••/255.ts'),
  'audit log keeps the masked URL');

-- ── 5) delta sync ───────────────────────────────────────────────────────────
select pg_temp.as_anon();
select ok((public.catalog_changes(current_setting('test.since')::bigint) -> 'channels') @> '[{"uid":"Pub.test"}]', 'anon sync returns the published channel');
select ok(not ((public.catalog_changes(current_setting('test.since')::bigint) -> 'channels') @> '[{"uid":"Pend.test"}]'), 'anon sync does NOT return the hidden channel');
select ok((public.catalog_changes(current_setting('test.since')::bigint) -> 'removed_channels') @> '["10000000-0000-0000-0000-000000000002"]', 'hidden channel reported as a removal (id only)');
select pg_temp.as_owner();
delete from public.channels where uid = 'Pend.test';
select pg_temp.as_anon();
select ok((public.catalog_changes(current_setting('test.since')::bigint) -> 'removed_channels') @> '["10000000-0000-0000-0000-000000000002"]', 'deleted channel reported via tombstone');

select ok((public.catalog_changes(0, 1) ->> 'more')::boolean, 'sync pages large catalogs (more=true when the page is full)');

-- ── 6) scheduler lease ──────────────────────────────────────────────────────
-- يبدأ من مهمة حرّة ومستحقة (قاعدة محلية مستعملة قد تحمل عقدًا من اختبار تكامل سابق)
select pg_temp.as_owner();
update public.scheduled_tasks set locked_by = null, locked_until = null, next_run_at = null where key = 'epg';
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select is(public.admin_task_acquire('epg', 'device-A'), true, 'device A takes the lease');
select is(public.admin_task_acquire('epg', 'device-B'), false, 'device B cannot run the same task meanwhile');

select * from finish();
rollback;
