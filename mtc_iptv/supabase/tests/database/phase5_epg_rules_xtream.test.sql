-- pgTAP — 0004 (§10.1، §11، ADM-E1/C6): مصادر الدليل، كتابة البرامج، قواعد التحويل، حسابات Xtream في Vault.
-- يثبت: لا يكتب ولا يقرأ إلا مدير بتحقق بخطوتين؛ كلمة مرور Xtream لا تُخزَّن نصًا؛ الكتابة دون تكرار.
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000005a1', 'admin5@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000005a1');
-- 0008: is_admin() also needs the JWT's session alive in auth.sessions (as_user uses the user id as session id)
insert into auth.sessions (id, user_id, aal, created_at, updated_at) select id, id, 'aal2', now(), now() from auth.users where email like '%@test.local' and id::text like '00000000-0000-0000-0000-%' on conflict do nothing;

create function pg_temp.as_user(uid text, aal text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal, 'session_id', uid)::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true), set_config('role', 'anon', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

-- ── 1) مصادر الدليل ─────────────────────────────────────────────────────────
select ok((select count(*) from public.epg_sources) >= 4, 'the 4 public sources of epg_sync.mjs are seeded');
select pg_temp.as_anon();
select throws_ok($$ select * from public.epg_sources $$, '42501', null, 'anon cannot read epg_sources');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal1');
select is((select count(*)::int from public.epg_sources), 0, 'admin WITHOUT MFA sees no sources (RLS)');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
select ok((select count(*) from public.epg_sources) >= 4, 'admin with MFA sees the sources');

-- ── 2) كتابة البرامج ─────────────────────────────────────────────────────────
select pg_temp.as_anon();
select throws_ok($$ select public.admin_epg_upsert('[]') $$, '42501', null, 'anon cannot call admin_epg_upsert');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal1');
select throws_ok($$ select public.admin_epg_upsert('[]') $$, '42501', null, 'admin WITHOUT MFA cannot write programmes');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
select is(public.admin_epg_upsert('[
  {"channel_uid":"T5.test","start_at":"2030-01-01T10:00:00Z","end_at":"2030-01-01T11:00:00Z","title":"A","source":"t"},
  {"channel_uid":"T5.test","start_at":"2030-01-01T10:00:00Z","end_at":"2030-01-01T11:30:00Z","title":"A dup","source":"t"},
  {"channel_uid":"T5.test","start_at":"2030-01-01T11:00:00Z","end_at":"2030-01-01T10:00:00Z","title":"bad range","source":"t"},
  {"channel_uid":"T5.test","start_at":"2030-01-01T12:00:00Z","end_at":"2030-01-01T13:00:00Z","title":"","source":"t"}
]'::jsonb), 1, 'duplicate keys in one batch, inverted ranges and empty titles are skipped');
select is(public.admin_epg_upsert('[{"channel_uid":"T5.test","start_at":"2030-01-01T10:00:00Z","end_at":"2030-01-01T11:15:00Z","title":"A2","source":"t"}]'::jsonb),
          1, 'same key again = update');
select pg_temp.as_owner();
select is((select title from public.epg_programmes where channel_uid = 'T5.test'), 'A2', 'the update replaced the title');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
select lives_ok($$ select public.admin_epg_finish((select id from public.epg_sources order by priority limit 1), 'ok', 1, 1, null) $$, 'finish records the run');
select pg_temp.as_owner();
select ok(exists (select 1 from public.epg_runs where source like 'app:%'), 'epg_runs has the app run');

-- ── 3) قواعد التحويل ─────────────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
insert into public.transform_rules (kind, pattern, target) values ('group_category', 'Sport', 'sports');
select is((select count(*)::int from public.transform_rules where pattern = 'Sport'), 1, 'admin with MFA writes rules');
select pg_temp.as_anon();
select throws_ok($$ insert into public.transform_rules (kind, pattern, target) values ('name_country', 'x', 'SA') $$, '42501', null, 'anon cannot write rules');

-- ── 4) Xtream: كلمة المرور في Vault فقط ──────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
select set_config('test.xid', public.admin_xtream_save('T', 'http://xt.example:8080/', 'user5', 'Sup3r-Secret')::text, false);
select is(public.admin_xtream_password(current_setting('test.xid')::uuid), 'Sup3r-Secret', 'admin with MFA reads the password back');
select pg_temp.as_owner();
select ok(not exists (select 1 from public.xtream_accounts a where to_jsonb(a)::text like '%Sup3r-Secret%'), 'the password is not stored in the table');
select ok(not exists (select 1 from vault.secrets where secret like '%Sup3r-Secret%'), 'vault stores it encrypted');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal1');
select throws_ok($$ select public.admin_xtream_password(current_setting('test.xid')::uuid) $$, '42501', null, 'admin WITHOUT MFA cannot read the password');
select pg_temp.as_user('00000000-0000-0000-0000-0000000005a1', 'aal2');
select public.admin_xtream_delete(current_setting('test.xid')::uuid);
select pg_temp.as_owner();
select ok(not exists (select 1 from vault.secrets s join public.xtream_accounts a on a.secret_id = s.id where a.id = current_setting('test.xid')::uuid), 'delete removes account and secret');

select * from finish();
rollback;
