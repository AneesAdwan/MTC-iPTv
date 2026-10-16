-- pgTAP — 0006 (§8.3، §19.5): مزامنة المفضلة برمز.
-- يثبت: لا وصول مباشر للجدول؛ الرمز والسرّ من الخادم؛ الكتابة والحذف بالسرّ فقط؛ السرّ لا يُخزَّن نصًا؛ التنظيف.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

create function pg_temp.as_anon() returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true), set_config('role', 'anon', true)
$$;
create function pg_temp.as_owner() returns void language sql as $$
  select set_config('role', 'postgres', true), set_config('request.jwt.claims', '', true)
$$;

select pg_temp.as_anon();
create temp table t_set as select public.fav_create('["c1","c2","c1",""]'::jsonb) as r;
grant select on t_set to anon;

select ok((select r ->> 'code' from t_set) ~ '^[A-HJ-NP-Z2-9]{8}$', 'server generates an 8-char unambiguous code');
select ok(length(select_secret) = 48, 'and a 48-hex secret') from (select r ->> 'secret' as select_secret from t_set) s;
select is((public.fav_get((select r ->> 'code' from t_set)) -> 'favorites'), '["c1","c2"]'::jsonb, 'read by code: cleaned, no duplicates or empties');
select is(public.fav_get(lower((select r ->> 'code' from t_set))) -> 'code', to_jsonb((select r ->> 'code' from t_set)), 'code is case-insensitive');
select is(public.fav_get('ZZZZZZZZ'), null, 'unknown code = null');
select throws_ok($$ select * from public.favorite_sets $$, '42501', null, 'anon cannot read the table directly');
select throws_ok($$ update public.favorite_sets set favorites = '[]' $$, '42501', null, 'anon cannot write the table directly');
select throws_ok(format($$ select public.fav_put(%L, 'wrong', '["x"]') $$, (select r ->> 'code' from t_set)), '42501', null, 'write with a wrong secret is refused');
select lives_ok(format($$ select public.fav_put(%L, %L, '["c3"]') $$, (select r ->> 'code' from t_set), (select r ->> 'secret' from t_set)), 'write with the secret works');
select is((public.fav_get((select r ->> 'code' from t_set)) -> 'favorites'), '["c3"]'::jsonb, 'new list stored');
select throws_ok($$ select public.admin_favsets_purge() $$, '42501', null, 'anon cannot purge');

select pg_temp.as_owner();
select ok((select secret_hash <> (select r ->> 'secret' from t_set) from public.favorite_sets where code = (select r ->> 'code' from t_set)), 'the secret itself is never stored');

select pg_temp.as_anon();
select throws_ok(format($$ select public.fav_delete(%L, 'nope') $$, (select r ->> 'code' from t_set)), '42501', null, 'delete needs the secret');
select lives_ok(format($$ select public.fav_delete(%L, %L) $$, (select r ->> 'code' from t_set), (select r ->> 'secret' from t_set)), 'delete with the secret');

select * from finish();
rollback;
