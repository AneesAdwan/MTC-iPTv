-- ════════════════════════════════════════════════════════════════════════════
-- 0006 — مزامنة المفضلة برمز بلا حساب (§8.3) مع الإصلاح الأمني (§19.5).
-- الجدول غير موجود في الإنتاج (inventory.md §10: كان في 01_schema.sql ولم يُطبَّق)، فيبدأ هنا آمنًا من الأصل:
--   • الرمز وسرّ التعديل يولّدهما الخادم. الجهاز يحفظ السرّ، والقاعدة تحفظ بصمته فقط (SHA-256).
--   • القراءة بالرمز فقط، والكتابة والحذف تشترطان السرّ. لا وصول مباشر للجدول من أي دور.
--   • الاحتفاظ (§20.1): يُحذف ما لم يُستخدم 365 يومًا (admin_favsets_purge من المُجدوِل).
-- إضافي فقط. التراجع: docs/migration/down/20261016000500_favorite_sets.down.sql
-- ════════════════════════════════════════════════════════════════════════════

create table if not exists public.favorite_sets (
  code         text primary key check (code ~ '^[A-HJ-NP-Z2-9]{8}$'),   -- 8 أحرف بلا الملتبس (0/O، 1/I)
  secret_hash  text not null check (secret_hash ~ '^[0-9a-f]{64}$'),
  favorites    jsonb not null default '[]'::jsonb
               check (jsonb_typeof(favorites) = 'array' and jsonb_array_length(favorites) <= 2000),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  last_used_at timestamptz not null default now()
);
alter table public.favorite_sets enable row level security;
revoke all on public.favorite_sets from anon, authenticated;

create or replace function public._fav_hash(p_secret text) returns text
language sql immutable set search_path = public, extensions, pg_temp as $$
  select encode(extensions.digest(coalesce(p_secret, ''), 'sha256'), 'hex')
$$;
revoke all on function public._fav_hash(text) from public, anon, authenticated;

create or replace function public._fav_clean(p jsonb) returns jsonb
language sql immutable as $$
  -- معرّفات قنوات نصية فقط، بلا تكرار، بحد أقصى 2000، مع الحفاظ على الترتيب
  select coalesce(jsonb_agg(v order by o), '[]'::jsonb)
    from (select distinct on (v) v, o
            from jsonb_array_elements_text(case when jsonb_typeof(p) = 'array' then p else '[]'::jsonb end) with ordinality as e(v, o)
           where length(v) between 1 and 64
           order by v, o) x
   where o <= 2000
$$;

-- إنشاء: يعيد {code, secret}. السرّ يُعرض مرة واحدة فقط ولا يُخزَّن.
create or replace function public.fav_create(p_favorites jsonb default '[]'::jsonb) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text; v_secret text; i int; b bytea;
begin
  for attempt in 1 .. 10 loop
    b := extensions.gen_random_bytes(8);
    v_code := '';
    for i in 0 .. 7 loop
      v_code := v_code || substr(alphabet, (get_byte(b, i) % 32) + 1, 1);
    end loop;
    exit when not exists (select 1 from public.favorite_sets where code = v_code);
    v_code := null;
  end loop;
  if v_code is null then raise exception 'could not allocate a code' using errcode = '55000'; end if;
  v_secret := encode(extensions.gen_random_bytes(24), 'hex');
  insert into public.favorite_sets (code, secret_hash, favorites) values (v_code, public._fav_hash(v_secret), public._fav_clean(p_favorites));
  return jsonb_build_object('code', v_code, 'secret', v_secret);
end $$;

-- قراءة بالرمز (لا تكشف البصمة). null إن لم يوجد.
create or replace function public.fav_get(p_code text) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare r public.favorite_sets;
begin
  update public.favorite_sets set last_used_at = now() where code = upper(trim(p_code)) returning * into r;
  if r.code is null then return null; end if;
  return jsonb_build_object('code', r.code, 'favorites', r.favorites, 'updated_at', r.updated_at);
end $$;

-- كتابة تشترط السرّ. يعيد updated_at الجديد.
create or replace function public.fav_put(p_code text, p_secret text, p_favorites jsonb) returns timestamptz
language plpgsql security definer set search_path = public, pg_temp as $$
declare v timestamptz;
begin
  update public.favorite_sets
     set favorites = public._fav_clean(p_favorites), updated_at = now(), last_used_at = now()
   where code = upper(trim(p_code)) and secret_hash = public._fav_hash(p_secret)
  returning updated_at into v;
  if v is null then raise exception 'invalid code or secret' using errcode = '42501'; end if;
  return v;
end $$;

create or replace function public.fav_delete(p_code text, p_secret text) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  delete from public.favorite_sets where code = upper(trim(p_code)) and secret_hash = public._fav_hash(p_secret);
  if not found then raise exception 'invalid code or secret' using errcode = '42501'; end if;
end $$;

-- الاحتفاظ: 365 يومًا من آخر استخدام (مهمة المُجدوِل في برنامج المدير)
create or replace function public.admin_favsets_purge() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  delete from public.favorite_sets where last_used_at < now() - interval '365 days';
  get diagnostics n = row_count;
  return n;
end $$;

revoke all on function public._fav_clean(jsonb), public.fav_create(jsonb), public.fav_get(text), public.fav_put(text, text, jsonb),
                       public.fav_delete(text, text), public.admin_favsets_purge() from public, anon, authenticated;
grant execute on function public.fav_create(jsonb), public.fav_get(text), public.fav_put(text, text, jsonb), public.fav_delete(text, text)
  to anon, authenticated;
grant execute on function public.admin_favsets_purge() to authenticated;

notify pgrst, 'reload schema';
