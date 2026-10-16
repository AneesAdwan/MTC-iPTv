-- ════════════════════════════════════════════════════════════════════════════
-- 0007 — سلة المحذوفات (خطة التحسينات 4.2، قرار المالك 2026-10-16): «الحذف» من اللوحة يضع القناة في السلة
-- 30 يومًا قابلة للاسترجاع، ثم يحذفها المُجدوِل نهائيًا. لا حذف فوري من أي شاشة بعد الآن.
--   • القناة في السلة: publish_state = 'hidden' (تختفي من التطبيق بالمزامنة كأي قناة مخفية)، ورقمها يُحرَّر
--     ويُحفظ مع حالتها السابقة في trash_prev لتُستعاد كما كانت.
--   • admin_review_apply (من اللوحة القديمة) كان يحذف نهائيًا عند «رفض» و«دمج» (inventory §… وMASTER_SPEC:
--     «إخفاء لا حذف»). الآن: «رفض» ← السلة، «دمج» ← الروابط تنتقل والقناة تُخفى مع merged_into (قابل للتراجع).
-- إضافي فقط (أعمدة ودوال). التراجع: docs/migration/down/20261016000700_trash.down.sql
-- ════════════════════════════════════════════════════════════════════════════

alter table public.channels
  add column if not exists trashed_at   timestamptz,
  add column if not exists trashed_by   uuid,
  add column if not exists trash_reason text check (trash_reason is null or length(trash_reason) <= 300),
  add column if not exists trash_prev   jsonb;   -- {publish_state, number}

create index if not exists channels_trashed_idx on public.channels(trashed_at) where trashed_at is not null;

-- إلى السلة. يعيد عدد القنوات التي نُقلت (المنقولة سابقًا تُتجاهل).
create or replace function public.admin_trash(p_ids uuid[], p_reason text default null) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  update public.channels c
     set trash_prev   = jsonb_build_object('publish_state', c.publish_state, 'number', c.number),
         trashed_at   = now(),
         trashed_by   = auth.uid(),
         trash_reason = nullif(trim(p_reason), ''),
         publish_state = 'hidden',
         hidden_reason = 'manual',
         number       = null
   where c.id = any(p_ids) and c.trashed_at is null;
  get diagnostics n = row_count;
  return n;
end $$;

-- استرجاع من السلة: الحالة السابقة كما كانت، والرقم إن لم تأخذه قناة أخرى في الأثناء.
create or replace function public.admin_restore(p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int := 0; r record; v_num int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  for r in select id, trash_prev from public.channels where id = any(p_ids) and trashed_at is not null loop
    v_num := (r.trash_prev ->> 'number')::int;
    if v_num is not null and exists (select 1 from public.channels where number = v_num and id <> r.id) then v_num := null; end if;
    update public.channels
       set publish_state = coalesce(r.trash_prev ->> 'publish_state', 'hidden'),
           number = v_num,
           trashed_at = null, trashed_by = null, trash_reason = null, trash_prev = null
     where id = r.id;
    n := n + 1;
  end loop;
  return n;
end $$;

-- الحذف النهائي: ما مضى عليه [p_days] يومًا في السلة (المُجدوِل)، أو قنوات بعينها من السلة (زر «حذف نهائي»).
-- الروابط والبلاغات تُحذف معها (on delete cascade)، وسجل التدقيق يبقى.
create or replace function public.admin_trash_purge(p_ids uuid[] default null, p_days integer default 30) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  delete from public.channels
   where trashed_at is not null
     and (case when p_ids is null then trashed_at < now() - make_interval(days => greatest(p_days, 1))
               else id = any(p_ids) end);
  get diagnostics n = row_count;
  return n;
end $$;

-- قيد المراجعة: بلا حذف نهائي.
create or replace function public.admin_review_apply(p_action text, p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int := 0; r record;
begin
  if not public.is_admin() then raise exception 'not authorized' using errcode = '42501'; end if;
  case p_action
    when 'approve' then
      update public.channels set is_published = true, hidden_reason = null where id = any(p_ids) and hidden_reason = 'pending';
      get diagnostics n = row_count;
    when 'reject' then
      n := public.admin_trash(array(select id from public.channels where id = any(p_ids) and hidden_reason = 'pending'), 'رفض من قيد المراجعة');
    when 'merge' then
      for r in select id, duplicate_of from public.review_queue where id = any(p_ids) and duplicate_of is not null loop
        update public.streams set channel_id = r.duplicate_of where channel_id = r.id;
        update public.reports set channel_id = r.duplicate_of where channel_id = r.id and status = 'open';
        update public.channels set publish_state = 'hidden', hidden_reason = 'duplicate', merged_into = r.duplicate_of where id = r.id;
        n := n + 1;
      end loop;
    else raise exception 'unknown action %', p_action;
  end case;
  return n;
end $$;

revoke all on function public.admin_trash(uuid[], text), public.admin_restore(uuid[]), public.admin_trash_purge(uuid[], integer),
                       public.admin_review_apply(text, uuid[]) from public, anon;
grant execute on function public.admin_trash(uuid[], text), public.admin_restore(uuid[]), public.admin_trash_purge(uuid[], integer),
                          public.admin_review_apply(text, uuid[]) to authenticated;

notify pgrst, 'reload schema';
