-- ════════════════════════════════════════════════════════════════════════════
-- 0008 — Server-side admin proof (SuperAdmin plan §9.1, fixes Appendix B م-16).
--
-- Before: is_admin() = admin_users membership + JWT claim aal = aal2. A JWT stayed valid
-- until it expired even after its session was signed out, expired or deleted.
-- Now is_admin() additionally requires that the JWT's session is still alive in auth.sessions
-- (same user, aal2, not past not_after) and was not revoked from the SuperAdmin panel
-- (public.admin_sessions). Dangerous operations use is_admin_fresh(): the last TOTP
-- verification (JWT amr) must be recent (default 15 minutes).
--
-- Same function names/signatures/grants as before, so every existing policy and RPC that
-- calls is_admin() gets the stricter check automatically. Legacy is_mtc_admin() is untouched.
-- Rollback: docs/migration/down/20261017000800_admin_session_proof.down.sql
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 1) admin_sessions: device info + revocation marks ─────────────────────
-- No FK to auth.sessions on purpose: the revocation mark must outlive the deleted session.
create table if not exists public.admin_sessions (
  session_id     uuid primary key,
  user_id        uuid not null references auth.users(id) on delete cascade,
  device         text check (device is null or length(device) <= 200),
  platform       text check (platform is null or length(platform) <= 50),
  app_version    text check (app_version is null or length(app_version) <= 50),
  first_seen_at  timestamptz not null default now(),
  last_seen_at   timestamptz not null default now(),
  revoked_at     timestamptz,
  revoked_by     uuid,
  revoked_reason text check (revoked_reason is null or length(revoked_reason) <= 300)
);
create index if not exists admin_sessions_user_idx on public.admin_sessions(user_id, last_seen_at desc);
alter table public.admin_sessions enable row level security;

-- ─── 2) helpers: the JWT's session ─────────────────────────────────────────
-- session_id claim as uuid (null when missing or malformed — never raises).
create or replace function public.jwt_session_id() returns uuid
language sql stable set search_path = public, pg_temp as $$
  select case when (select auth.jwt()) ->> 'session_id' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then ((select auth.jwt()) ->> 'session_id')::uuid end
$$;

-- The JWT's session is alive in auth.sessions for auth.uid(), aal2, not expired, not revoked.
-- (Independent of admin_users: admin_status() reports it separately.)
create or replace function public.admin_session_ok() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2'
     and exists (
       select 1 from auth.sessions s
        where s.id = public.jwt_session_id()
          and s.user_id = (select auth.uid())
          and s.aal = 'aal2'
          and (s.not_after is null or s.not_after > now()))
     and not exists (
       select 1 from public.admin_sessions r
        where r.session_id = public.jwt_session_id() and r.revoked_at is not null)
$$;

-- ─── 3) is_admin(): membership + MFA + live, non-revoked session ──────────
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.admin_users where user_id = (select auth.uid()))
     and public.admin_session_ok()
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ─── 4) is_admin_fresh(): is_admin() + TOTP verified within max_age ───────
-- amr = [{"method":"totp","timestamp":<unix seconds>}, …] (GoTrue keeps the original
-- verification time across token refreshes, so this is the real age of the second factor).
create or replace function public.is_admin_fresh(max_age interval default interval '15 minutes') returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select public.is_admin()
     and coalesce(max_age > interval '0', false)
     and exists (
       select 1
         from jsonb_array_elements(case when jsonb_typeof((select auth.jwt()) -> 'amr') = 'array'
                                        then (select auth.jwt()) -> 'amr' else '[]'::jsonb end) e
        where jsonb_typeof(e) = 'object'
          and e ->> 'method' = 'totp'
          and (e ->> 'timestamp') ~ '^[0-9]{1,12}(\.[0-9]+)?$'
          and to_timestamp((e ->> 'timestamp')::double precision) >= now() - max_age
          and to_timestamp((e ->> 'timestamp')::double precision) <= now() + interval '1 minute')
$$;
revoke all on function public.jwt_session_id(), public.admin_session_ok(), public.is_admin_fresh(interval) from public;
grant execute on function public.jwt_session_id(), public.admin_session_ok(), public.is_admin_fresh(interval) to anon, authenticated;

-- ─── 5) admin_status(): same keys as before + session_ok + fresh ──────────
create or replace function public.admin_status() returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'is_admin_user', exists (select 1 from public.admin_users where user_id = (select auth.uid())),
    'aal', coalesce((select auth.jwt()) ->> 'aal', 'aal1'),
    'is_admin', public.is_admin(),
    'session_ok', public.admin_session_ok(),
    'fresh', public.is_admin_fresh())
$$;
grant execute on function public.admin_status() to authenticated;

-- ─── 6) RLS: admins read the session list; writes only through the RPCs ───
drop policy if exists "admin read" on public.admin_sessions;
create policy "admin read" on public.admin_sessions for select to authenticated using ((select public.is_admin()));
revoke all on public.admin_sessions from anon, authenticated;
grant select on public.admin_sessions to authenticated;

-- ─── 7) RPCs ────────────────────────────────────────────────────────────────
-- Heartbeat of the current admin session (device info + last_seen). Rejected once revoked.
create or replace function public.admin_session_touch(p_device text default null, p_platform text default null, p_app_version text default null)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare r public.admin_sessions;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  insert into public.admin_sessions as a (session_id, user_id, device, platform, app_version)
  values (public.jwt_session_id(), auth.uid(), left(nullif(trim(p_device), ''), 200),
          left(nullif(trim(p_platform), ''), 50), left(nullif(trim(p_app_version), ''), 50))
  on conflict (session_id) do update
     set last_seen_at = now(),
         device       = coalesce(excluded.device, a.device),
         platform     = coalesce(excluded.platform, a.platform),
         app_version  = coalesce(excluded.app_version, a.app_version)
   where a.user_id = excluded.user_id and a.revoked_at is null
  returning * into r;
  if r.session_id is null then raise exception 'session revoked' using errcode = '42501'; end if;
  return jsonb_build_object('session_id', r.session_id, 'first_seen_at', r.first_seen_at, 'last_seen_at', r.last_seen_at);
end $$;

-- All admin sessions: live ones from auth.sessions (+ device info if touched) and revoked/ended
-- ones from admin_sessions. No tokens, no IPs.
create or replace function public.admin_sessions_list() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  return coalesce((
    select jsonb_agg(x order by x.last_seen_at desc nulls last)
    from (
      select coalesce(s.id, a.session_id) as session_id,
             coalesce(s.user_id, a.user_id) as user_id,
             a.device, a.platform, a.app_version, s.user_agent,
             s.aal::text as aal,
             coalesce(a.first_seen_at, s.created_at) as first_seen_at,
             coalesce(a.last_seen_at, s.refreshed_at::timestamptz, s.updated_at, s.created_at) as last_seen_at,
             s.not_after,
             (s.id is not null and (s.not_after is null or s.not_after > now()) and a.revoked_at is null) as alive,
             a.revoked_at, a.revoked_reason,
             coalesce(s.id, a.session_id) = public.jwt_session_id() as current
        from (select * from auth.sessions where user_id in (select user_id from public.admin_users)) s
        full join public.admin_sessions a on a.session_id = s.id
    ) x
  ), '[]'::jsonb);
end $$;

-- End a session: deletes it from auth.sessions (refresh tokens go with it) and marks it revoked,
-- so the device's still-unexpired JWT is refused on its very next request. Needs a fresh TOTP.
create or replace function public.admin_session_revoke(p_session_id uuid, p_reason text default null) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_user uuid; v_deleted int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  if not public.is_admin_fresh() then
    raise exception 'recent TOTP verification required' using errcode = '42501', hint = 'reauthenticate';
  end if;
  select user_id into v_user from auth.sessions
   where id = p_session_id and user_id in (select user_id from public.admin_users);
  if v_user is null then
    select user_id into v_user from public.admin_sessions where session_id = p_session_id;
  end if;
  if v_user is null then raise exception 'unknown session' using errcode = 'P0002'; end if;

  delete from auth.sessions where id = p_session_id;
  get diagnostics v_deleted = row_count;

  insert into public.admin_sessions as a (session_id, user_id, revoked_at, revoked_by, revoked_reason)
  values (p_session_id, v_user, now(), auth.uid(), left(coalesce(nullif(trim(p_reason), ''), 'manual'), 300))
  on conflict (session_id) do update
     set revoked_at = coalesce(a.revoked_at, now()),
         revoked_by = coalesce(a.revoked_by, excluded.revoked_by),
         revoked_reason = coalesce(a.revoked_reason, excluded.revoked_reason);

  insert into public.audit_logs(actor, action, table_name, row_id, before, after, reason)
  values (auth.uid(), 'DELETE', 'auth.sessions', p_session_id::text,
          jsonb_build_object('session_id', p_session_id, 'user_id', v_user), null,
          left(coalesce(nullif(trim(p_reason), ''), 'session_revoke'), 300));

  return jsonb_build_object('session_id', p_session_id, 'deleted', v_deleted > 0, 'revoked', true);
end $$;

revoke all on function public.admin_session_touch(text, text, text), public.admin_sessions_list(),
                       public.admin_session_revoke(uuid, text) from public, anon;
grant execute on function public.admin_session_touch(text, text, text), public.admin_sessions_list(),
                          public.admin_session_revoke(uuid, text) to authenticated;

notify pgrst, 'reload schema';
