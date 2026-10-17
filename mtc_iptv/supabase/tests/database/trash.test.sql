-- pgTAP — 0007 سلة المحذوفات (خطة التحسينات 4.2).
-- يثبت: المدير فقط؛ السلة تُخفي وتحرّر الرقم؛ الاسترجاع يعيد الحالة والرقم؛ الحذف النهائي للقديم أو المحدد فقط؛
-- «رفض» و«دمج» في قيد المراجعة لا يحذفان نهائيًا بعد الآن.
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-0000-0000-0000000007a1', 'admin7@test.local', 'authenticated', 'authenticated');
insert into public.admin_users (user_id) values ('00000000-0000-0000-0000-0000000007a1');
-- 0008: is_admin() also needs the JWT's session alive in auth.sessions (as_user uses the user id as session id)
insert into auth.sessions (id, user_id, aal, created_at, updated_at) select id, id, 'aal2', now(), now() from auth.users where email like '%@test.local' and id::text like '00000000-0000-0000-0000-%' on conflict do nothing;

create function pg_temp.as_user(uid text, aal text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal, 'session_id', uid)::text, true),
         set_config('role', 'authenticated', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

-- قنوات تجريبية: منشورة برقم، ومعلّقة (قيد المراجعة)، ونسختان مكررتان
select set_config('mtc.review_bypass', 'on', true);
insert into public.channels (id, uid, number, name, is_published) values
  ('00000000-0000-0000-0000-00000000c701', 't7.pub', 9701, 'T7 Published', true),
  ('00000000-0000-0000-0000-00000000c702', 't7.old', 9702, 'T7 Old', true);
select set_config('mtc.review_bypass', '', true);
insert into public.channels (id, uid, name, is_published) values
  ('00000000-0000-0000-0000-00000000c703', 't7.pending', 'T7 Pending', true);  -- البوابة تجعلها pending
insert into public.streams (channel_id, url) values
  ('00000000-0000-0000-0000-00000000c703', 'https://t7.example/p.m3u8');

select throws_ok($$ select public.admin_trash(array['00000000-0000-0000-0000-00000000c701']::uuid[]) $$, '42501', null, 'not an admin: refused');
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal1');
select throws_ok($$ select public.admin_trash(array['00000000-0000-0000-0000-00000000c701']::uuid[]) $$, '42501', null, 'admin without MFA: refused');

select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select is(public.admin_trash(array['00000000-0000-0000-0000-00000000c701']::uuid[], 'test'), 1, 'trash one channel');
select is(public.admin_trash(array['00000000-0000-0000-0000-00000000c701']::uuid[]), 0, 'trashing again does nothing');
select pg_temp.as_owner();
select is((select publish_state from public.channels where uid = 't7.pub'), 'hidden', 'trashed = hidden (leaves the viewer apps)');
select is((select number from public.channels where uid = 't7.pub'), null, 'its number is freed');
select is((select trash_prev from public.channels where uid = 't7.pub'), '{"number": 9701, "publish_state": "published"}'::jsonb, 'previous state kept');

select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select is(public.admin_restore(array['00000000-0000-0000-0000-00000000c701']::uuid[]), 1, 'restore');
select pg_temp.as_owner();
select is((select publish_state || '/' || number from public.channels where uid = 't7.pub'), 'published/9701', 'restored as it was, with its number');

-- الرقم أُخذ أثناء وجودها في السلة: تُستعاد بلا رقم ولا تكسر الفريدية
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select public.admin_trash(array['00000000-0000-0000-0000-00000000c702']::uuid[]);
select pg_temp.as_owner();
update public.channels set number = 9702 where uid = 't7.pub';
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select public.admin_restore(array['00000000-0000-0000-0000-00000000c702']::uuid[]);
select pg_temp.as_owner();
select is((select number from public.channels where uid = 't7.old'), null, 'number taken meanwhile: restored without it');

-- الحذف النهائي: القديم فقط، أو المحدد من السلة فقط
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select public.admin_trash(array['00000000-0000-0000-0000-00000000c702']::uuid[]);
select is(public.admin_trash_purge(), 0, 'nothing older than 30 days: nothing purged');
select is(public.admin_trash_purge(array['00000000-0000-0000-0000-00000000c701']::uuid[]), 0, 'a channel not in the trash is never purged');
select pg_temp.as_owner();
update public.channels set trashed_at = now() - interval '31 days' where uid = 't7.old';
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select is(public.admin_trash_purge(), 1, 'older than 30 days: purged');
select pg_temp.as_owner();
select is((select count(*)::int from public.channels where uid = 't7.old'), 0, 'gone for good');

-- قيد المراجعة: «رفض» يضع في السلة، لا يحذف
select pg_temp.as_user('00000000-0000-0000-0000-0000000007a1', 'aal2');
select is(public.admin_review_apply('reject', array['00000000-0000-0000-0000-00000000c703']::uuid[]), 1, 'review reject');
select pg_temp.as_owner();
select ok((select trashed_at is not null from public.channels where uid = 't7.pending'), 'rejected channel is in the trash, not deleted');
select is((select count(*)::int from public.streams where url = 'https://t7.example/p.m3u8'), 1, 'its streams are kept');

select * from finish();
rollback;
