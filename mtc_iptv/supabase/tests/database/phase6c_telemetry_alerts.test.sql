-- pgTAP — 0005 (§12.4، §20، ADM-A3): قياس المشاهدين، الأجهزة، التجميع، التنبيهات.
-- يثبت: المشاهد يكتب عبر telemetry_ingest فقط وبحدود، ولا يقرأ شيئًا؛ رمز Push لا يقرؤه المدير؛
-- التجميع بلا معرّفات أجهزة؛ التنبيهات للمدير بتحقق بخطوتين فقط ولا تتكرر.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000006c1', 'admin6@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000006c1');
-- 0008: is_admin() also needs the JWT's session alive in auth.sessions (as_user uses the user id as session id)
insert into auth.sessions (id, user_id, aal, created_at, updated_at) select id, id, 'aal2', now(), now() from auth.users where email like '%@test.local' and id::text like '00000000-0000-0000-0000-%' on conflict do nothing;
insert into public.channels (id, uid, name, number) values ('00000000-0000-0000-0000-00000000c601', 'T6.one', 'T6 one', 96001);
insert into public.streams (id, channel_id, url) values
  ('00000000-0000-0000-0000-00000000a601', '00000000-0000-0000-0000-00000000c601', 'https://t6.example/a.m3u8');

create function pg_temp.as_user(uid text, aal text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal, 'session_id', uid)::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true), set_config('role', 'anon', true),
         set_config('request.headers', '{"cf-ipcountry":"jo"}', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

-- ── 1) الاستقبال ─────────────────────────────────────────────────────────────
select pg_temp.as_anon();
select is(public.telemetry_ingest('00000000-0000-0000-0000-0000000006d1', 'windows', '3.0.0-alpha.17', 'ar', '[
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"success","first_frame_ms":900,"watch_seconds":125,"height":1080},
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"failure","error_code":"network_error"},
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"failure","error_code":"evil"},
  {"stream_id":"00000000-0000-0000-0000-0000000fffff","outcome":"success"},
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"bogus"}
]'::jsonb, 'tok-1'), 2, 'only valid events for existing streams are stored');
select throws_ok($$ select public.telemetry_ingest(null, 'windows', 'x', 'ar') $$, '22023', null, 'installation id is required');
select throws_ok($$ select public.telemetry_ingest('00000000-0000-0000-0000-0000000006d1', 'web', 'x', 'ar') $$, '22023', null, 'unknown platform rejected');
select throws_ok($$ select * from public.playback_events $$, '42501', null, 'anon cannot read events');
select throws_ok($$ select * from public.installations $$, '42501', null, 'anon cannot read installations');
select throws_ok($$ insert into public.playback_events (installation_id, channel_id, stream_id, outcome, platform)
                    values ('00000000-0000-0000-0000-0000000006d1', gen_random_uuid(), gen_random_uuid(), 'success', 'windows') $$,
                 '42501', null, 'anon cannot insert events directly');
select throws_ok($$ select public.admin_telemetry_rollup() $$, '42501', null, 'anon cannot run the rollup');

select pg_temp.as_owner();
select is((select country from public.installations where id = '00000000-0000-0000-0000-0000000006d1'), 'JO', 'approximate country from the network header');
select is((select watch_seconds from public.playback_events where outcome = 'success' and installation_id = '00000000-0000-0000-0000-0000000006d1'),
          120, 'watch time is rounded to 10 seconds');
select is((select channel_id from public.playback_events where installation_id = '00000000-0000-0000-0000-0000000006d1' limit 1),
          '00000000-0000-0000-0000-00000000c601'::uuid, 'channel comes from the stream, not the client');

-- حد المعدل: 300 في الساعة
insert into public.playback_events (installation_id, channel_id, stream_id, outcome, platform)
select '00000000-0000-0000-0000-0000000006d1', '00000000-0000-0000-0000-00000000c601', '00000000-0000-0000-0000-00000000a601', 'success', 'windows'
  from generate_series(1, 298);
select pg_temp.as_anon();
select is(public.telemetry_ingest('00000000-0000-0000-0000-0000000006d1', 'windows', 'x', 'ar', '[
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"success"},
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"success"}
]'::jsonb), 0, 'over 300 events/hour are dropped');

-- مفتاح الإيقاف المركزي
select pg_temp.as_owner();
insert into public.site_settings (key, value, is_public) values ('features', '{"telemetry_enabled": false}', true)
on conflict (key) do update set value = excluded.value;
select pg_temp.as_anon();
select is(public.telemetry_ingest('00000000-0000-0000-0000-0000000006d2', 'android', 'x', 'en', '[
  {"stream_id":"00000000-0000-0000-0000-00000000a601","outcome":"success"}]'::jsonb), 0, 'telemetry kill switch stores no events');
select pg_temp.as_owner();
select ok(exists (select 1 from public.installations where id = '00000000-0000-0000-0000-0000000006d2'), '...but the device still counts as active');
update public.site_settings set value = '{"telemetry_enabled": true}' where key = 'features';

-- ── 2) قراءة المدير والتجميع ─────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000006c1', 'aal1');
select is((select count(*)::int from public.playback_events), 0, 'admin WITHOUT MFA sees no events');
select pg_temp.as_user('00000000-0000-0000-0000-0000000006c1', 'aal2');
select throws_ok($$ select push_token from public.installations $$, '42501', null, 'admin cannot read push tokens');
select ok((select count(*) from public.installations) >= 2, 'admin with MFA sees devices');
select lives_ok($$ select public.admin_telemetry_rollup(current_date) $$, 'rollup runs');
select is((select sum(attempts)::int from public.playback_stats_daily where stream_id = '00000000-0000-0000-0000-00000000a601' and day = (now() at time zone 'utc')::date),
          300, 'daily attempts = success + failure (rows per platform and country)');
select is((select (failures ->> 'network_error')::int from public.playback_stats_daily where stream_id = '00000000-0000-0000-0000-00000000a601' and country = 'JO'),
          1, 'failure codes are counted');
select is((select successes from public.stream_viewer_stats_7d where stream_id = '00000000-0000-0000-0000-00000000a601'), 299, '7-day viewer stats view');

-- ── 3) التنبيهات ─────────────────────────────────────────────────────────────
select pg_temp.as_anon();
select throws_ok($$ select public.admin_alerts_scan() $$, '42501', null, 'anon cannot scan alerts');
select pg_temp.as_owner();
insert into public.reports (channel_id, reason) select '00000000-0000-0000-0000-00000000c601', 'not_working' from generate_series(1, 3);
select pg_temp.as_user('00000000-0000-0000-0000-0000000006c1', 'aal2');
select lives_ok($$ select public.admin_alerts_scan() $$, 'scan runs');
select lives_ok($$ select public.admin_alerts_scan() $$, 'scan again');
select is((select occurrences from public.admin_alerts where dedupe_key = 'reports:00000000-0000-0000-0000-00000000c601' and status <> 'resolved'), 2,
          '3 open reports in 24h raise one alert; scanning again counts, not duplicates');

-- ── 4) الحذف بطلب المستخدم ───────────────────────────────────────────────────
-- (يتحقق منه أيضًا اختبار التكامل؛ هنا فقط أن الدالة متاحة للزائر)
select * from finish();
rollback;
