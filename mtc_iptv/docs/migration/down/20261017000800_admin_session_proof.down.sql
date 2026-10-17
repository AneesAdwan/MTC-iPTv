-- ROLLBACK of migration 20261017000800_admin_session_proof (SuperAdmin plan §9.1).
-- Run manually (SQL Editor / psql) only if 0008 must be undone — AFTER the 0009 rollback (its
-- admin_source_remove calls is_admin_fresh) — then delete its row from supabase_migrations.schema_migrations.
-- ⚠ Puts back the JWT-only admin check (Appendix B م-16): a signed-out/revoked session's token is
--   accepted again until it expires. Revocation marks in admin_sessions are dropped.
begin;

drop function if exists public.admin_session_revoke(uuid, text);
drop function if exists public.admin_sessions_list();
drop function if exists public.admin_session_touch(text, text, text);

-- 0002 definitions
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.admin_users where user_id = (select auth.uid()))
     and coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2'
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create or replace function public.admin_status() returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'is_admin_user', exists (select 1 from public.admin_users where user_id = (select auth.uid())),
    'aal', coalesce((select auth.jwt()) ->> 'aal', 'aal1'),
    'is_admin', public.is_admin())
$$;
grant execute on function public.admin_status() to authenticated;

drop function if exists public.is_admin_fresh(interval);
drop function if exists public.admin_session_ok();
drop function if exists public.jwt_session_id();
drop table if exists public.admin_sessions;

commit;
notify pgrst, 'reload schema';
