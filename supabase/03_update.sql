-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — 03_update.sql : تحديث v2.4 دون حذف أي بيانات
--
-- لمن شغّل 01_schema.sql قبل v2.4: يضيف (1) تاريخ النشر لقائمة «مضافة حديثًا» في الرئيسية
--                                  (2) دالة الإضافة من «البحث في iptv-org» في اللوحة
-- (إذا شغّلت 01_schema.sql الجديد من الصفر فلا حاجة لهذا الملف.)
-- التشغيل: Supabase Dashboard → SQL Editor → New query → الصق → Run
-- ════════════════════════════════════════════════════════════════════════════
begin;

alter table public.channels add column if not exists published_at timestamptz;

-- القنوات المنشورة حاليًا: تاريخ نشرها = تاريخ إضافتها
update public.channels set published_at = created_at where is_published and hidden_reason is null and published_at is null;

create or replace function public.channels_stamp_published() returns trigger language plpgsql as $$
begin
  if new.is_published and new.hidden_reason is null and new.published_at is null then new.published_at := now(); end if;
  return new;
end $$;
drop trigger if exists channels_stamp_published on public.channels;
create trigger channels_stamp_published before insert or update on public.channels for each row execute function public.channels_stamp_published();

drop view if exists public.catalog;
create view public.catalog as
select c.id, c.number, c.name, c.network, c.description, c.quality, c.is_featured, c.sort_order, c.published_at,
       case when c.logo_status = 'broken' then null else c.logo_url end as logo_url,
       c.country_code, co.name_ar as country_name, co.name_en as country_name_en, co.flag_url, co.is_arab, co.continent,
       c.category_slug, cat.name_ar as category_name, c.extra_categories,
       c.language_code, l.name_ar as language_name,
       s.server, s.stream_count, s.online
from public.channels c
join lateral (
  select count(*)::int as stream_count,
         bool_or(st.status = 'online') as online,
         (array_agg(coalesce(st.label, public.server_of(st.host)) order by (st.status = 'online') desc, st.priority))[1] as server
  from public.streams st
  where st.channel_id = c.id and st.is_active and st.status <> 'offline'
) s on s.stream_count > 0
left join public.countries  co  on co.code  = c.country_code
left join public.categories cat on cat.slug = c.category_slug
left join public.languages  l   on l.code   = c.language_code
where c.is_published;

grant select on public.catalog to anon, authenticated;

drop function if exists public.admin_iptv_add(jsonb, boolean);
-- ─── الإضافة من البحث في iptv-org (صفحة «البحث في iptv-org» في اللوحة) ──────────
-- لكل قناة مختارة: إن كانت موجودة (نفس معرّف iptv-org أو قناة حددها المدير) تُضاف روابطها الجديدة إليها،
-- وإلا تُنشأ قناة جديدة. القنوات الجديدة تمر ببوابة المراجعة، إلا إذا اختار المدير «نشر مباشرة».
-- الروابط المكررة (موجودة في أي قناة) تُتجاهل، ونتيجة الفحص من المتصفح تُحفظ مع الرابط.
create function public.admin_iptv_add(p_items jsonb, p_publish boolean default false) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare it jsonb; v_id uuid; v_new int := 0; v_merged int := 0; v_links int := 0; n int; v_pr int; v_country text;
begin
  if not is_mtc_admin() then raise exception 'forbidden'; end if;
  for it in select * from jsonb_array_elements(coalesce(p_items, '[]')) loop
    v_id := nullif(it->>'target', '')::uuid;
    if v_id is null then select id into v_id from channels where uid = it->>'uid'; end if;
    if v_id is null then
      v_country := (select code from countries where code = upper(it->>'country'));
      if p_publish then perform set_config('mtc.review_bypass', 'on', true); end if;
      insert into channels (uid, number, name, alt_names, network, logo_url, country_code, category_slug, extra_categories,
                            language_code, quality, website, is_published, is_manual)
      values (it->>'uid', (select coalesce(max(number), 0) + 1 from channels), left(it->>'name', 250),
              array(select jsonb_array_elements_text(coalesce(it->'alt', '[]'))),
              nullif(it->>'network', ''), nullif(it->>'logo', ''), v_country,
              coalesce((select slug from categories where slug = it->>'category'), 'general'),
              array(select x from jsonb_array_elements_text(coalesce(it->'extra', '[]')) x where exists (select 1 from categories where slug = x)),
              coalesce((select code from languages where code = it->>'language'), (select language_code from countries where code = v_country)),
              case when it->>'quality' in ('SD', 'HD', 'FHD', '4K') then it->>'quality' end,
              nullif(it->>'website', ''), true, true)
      returning id into v_id;
      perform set_config('mtc.review_bypass', 'off', true);
      v_new := v_new + 1;
    else
      v_merged := v_merged + 1;
    end if;
    select coalesce(max(priority) + 1, 0) into v_pr from streams where channel_id = v_id;
    insert into streams (channel_id, url, quality, priority, status, response_ms, last_checked_at)
    select v_id, s->>'url', nullif(s->>'quality', ''), v_pr + o::int - 1,
           case when s->>'status' in ('online', 'offline') then s->>'status' else 'unknown' end,
           nullif(s->>'ms', '')::int, case when s->>'status' in ('online', 'offline') then now() end
    from jsonb_array_elements(coalesce(it->'streams', '[]')) with ordinality as t(s, o)
    where s->>'url' ~ '^https://' and length(s->>'url') <= 2000
    on conflict (url) do nothing;
    get diagnostics n = row_count;
    v_links := v_links + n;
  end loop;
  return jsonb_build_object('created', v_new, 'merged', v_merged, 'streams', v_links);
end $$;

revoke execute on function public.admin_iptv_add(jsonb, boolean) from public, anon;
grant execute on function public.admin_iptv_add(jsonb, boolean) to authenticated;

commit;
notify pgrst, 'reload schema';
