-- pgTAP — 0008 server-side admin proof (SuperAdmin plan §9.1, م-16). Run: supabase test db
-- is_admin() = admin_users + JWT aal2 + the JWT's session alive in auth.sessions (same user, aal2,
-- not expired) + not revoked in admin_sessions. is_admin_fresh() adds a recent TOTP (amr).
-- Every rejection comes from the server; the client is not involved.
begin;
create extension if not exists pgtap with schema extensions;
select plan(37);

-- ── fixtures ────────────────────────────────────────────────────────────────
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000008a1', 'admin8@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-0000000008b2', 'viewer8@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000008a1');

insert into auth.sessions (id, user_id, aal, not_after, created_at, updated_at) values
  ('80000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000008a1', 'aal2', null, now(), now()),                       -- valid
  ('80000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-0000000008a1', 'aal2', now() - interval '1 minute', now(), now()), -- expired
  ('80000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-0000000008a1', 'aal2', null, now(), now()),                       -- revoked from the panel
  ('80000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-0000000008a1', 'aal1', null, now(), now()),                       -- session never got MFA
  ('80000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-0000000008a1', 'aal2', now() + interval '1 hour', now(), now()),  -- second device (to revoke)
  ('80000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-0000000008b2', 'aal2', null, now(), now());                       -- viewer
insert into public.admin_sessions (session_id, user_id, revoked_at, revoked_reason) values
  ('80000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-0000000008a1', now(), 'lost laptop');

-- claims as GoTrue issues them; totp_age = seconds since the TOTP verification (null = no TOTP in amr)
create function pg_temp.as_user(uid text, aal text, sid text, totp_age integer default 60) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_strip_nulls(jsonb_build_object(
           'sub', uid, 'role', 'authenticated', 'aal', aal, 'session_id', sid,
           'amr', case when totp_age is null then jsonb_build_array(jsonb_build_object('method', 'password', 'timestamp', extract(epoch from now())::bigint - 3600))
                       else jsonb_build_array(jsonb_build_object('method', 'totp', 'timestamp', extract(epoch from now())::bigint - totp_age),
                                              jsonb_build_object('method', 'password', 'timestamp', extract(epoch from now())::bigint - 3600)) end))::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true), set_config('role', 'anon', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

-- ── rejections ──────────────────────────────────────────────────────────────
select pg_temp.as_anon();
select is(public.is_admin(), false, 'anon is not admin');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008b2', 'aal2', '80000000-0000-0000-0000-0000000000b2');
select is(public.is_admin(), false, 'non-admin with a valid aal2 session is not admin');
select throws_ok($$ select public.admin_sessions_list() $$, '42501', null, 'non-admin cannot list sessions');
select is((select count(*) from public.admin_sessions)::int, 0, 'non-admin reads no admin_sessions rows');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal1', '80000000-0000-0000-0000-000000000001');
select is(public.is_admin(), false, 'admin with aal1 JWT is not admin');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-0000000000ff');
select is(public.is_admin(), false, 'admin aal2 but session row missing (signed out / deleted) is not admin');
select throws_ok($$ select public.admin_task_acquire('epg', 'dev-x') $$, '42501', null, 'admin RPC refuses a deleted session');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', null);
select is(public.is_admin(), false, 'admin aal2 JWT without session_id is not admin');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', 'not-a-uuid');
select is(public.is_admin(), false, 'malformed session_id claim -> not admin (no error)');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000002');
select is(public.is_admin(), false, 'expired session (not_after in the past) is not admin');
select throws_ok($$ select public.admin_trash(array[]::uuid[]) $$, '42501', null, 'admin RPC refuses an expired session');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000004');
select is(public.is_admin(), false, 'JWT says aal2 but the session record is aal1 -> not admin');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000003');
select is(public.is_admin(), false, 'session revoked from the panel is not admin (even though auth.sessions still has it)');
select throws_ok($$ select public.admin_session_touch('pc', 'windows', '1.0') $$, '42501', null, 'revoked session cannot heartbeat');
select is((select count(*) from public.audit_logs)::int, 0, 'revoked session reads no audit rows (RLS via is_admin)');

select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-0000000000b2');
select is(public.is_admin(), false, 'another user''s session id does not make the admin admin');

-- ── acceptance ──────────────────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000001', 300);
select is(public.is_admin(), true, 'admin + aal2 + live session -> admin');
select is(public.is_admin_fresh(), true, 'TOTP 5 minutes ago -> fresh');
select is(public.admin_status() - 'aal', '{"is_admin_user": true, "is_admin": true, "session_ok": true, "fresh": true}'::jsonb,
  'admin_status reports session_ok and fresh');
select lives_ok($$ select public.admin_session_touch('Office PC', 'windows', '3.1.0') $$, 'admin heartbeat records the session');
select is((select device || '|' || platform || '|' || app_version from public.admin_sessions where session_id = '80000000-0000-0000-0000-000000000001'),
  'Office PC|windows|3.1.0', 'device info stored');
select ok(public.admin_sessions_list() @> '[{"session_id":"80000000-0000-0000-0000-000000000001","current":true,"alive":true,"device":"Office PC"}]',
  'session list shows the current live session');
select ok(public.admin_sessions_list() @> '[{"session_id":"80000000-0000-0000-0000-000000000003","alive":false,"revoked_reason":"lost laptop"}]',
  'session list shows the revoked session');
select ok(not (public.admin_sessions_list()::text like '%80000000-0000-0000-0000-0000000000b2%'), 'session list excludes non-admin sessions');

-- ── freshness for dangerous operations ─────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000001', 1200);
select is(public.is_admin(), true, 'stale TOTP (20 min): still admin for normal work');
select is(public.is_admin_fresh(), false, 'stale TOTP (20 min) -> not fresh');
select is(public.is_admin_fresh(interval '30 minutes'), true, 'custom max_age 30 min accepts 20 min');
select throws_ok($$ select public.admin_session_revoke('80000000-0000-0000-0000-000000000005', 'test') $$, '42501', null,
  'revoking a session with a stale TOTP is refused');
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000001', null);
select is(public.is_admin_fresh(), false, 'no TOTP entry in amr -> not fresh');

-- ── revoke ──────────────────────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000001', 30);
select throws_ok($$ select public.admin_session_revoke('80000000-0000-0000-0000-0000000000ee', 'x') $$, 'P0002', null,
  'revoking an unknown session is refused');
select throws_ok($$ select public.admin_session_revoke('80000000-0000-0000-0000-0000000000b2', 'x') $$, 'P0002', null,
  'revoking a non-admin user''s session is refused');
select is(public.admin_session_revoke('80000000-0000-0000-0000-000000000005', 'second device') ->> 'deleted', 'true', 'fresh admin revokes the other device');
select pg_temp.as_owner();
select is((select count(*) from auth.sessions where id = '80000000-0000-0000-0000-000000000005')::int, 0, 'revoked session deleted from auth.sessions');
select is((select revoked_reason from public.admin_sessions where session_id = '80000000-0000-0000-0000-000000000005'), 'second device', 'revocation recorded');
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000005', 30);
select is(public.is_admin(), false, 'the revoked device''s still-unexpired JWT is refused immediately');

-- ── removed from admin_users ────────────────────────────────────────────────
select pg_temp.as_owner();
delete from public.admin_users where user_id = '00000000-0000-0000-0000-0000000008a1';
select pg_temp.as_user('00000000-0000-0000-0000-0000000008a1', 'aal2', '80000000-0000-0000-0000-000000000001', 30);
select is(public.is_admin(), false, 'user removed from admin_users is not admin (valid session, fresh TOTP)');
select is(public.is_admin_fresh(), false, 'user removed from admin_users is not fresh admin');

select * from finish();
rollback;
