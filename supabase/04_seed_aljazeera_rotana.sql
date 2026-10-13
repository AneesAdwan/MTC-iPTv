-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — إضافة قناتَي الجزيرة وروتانا (مرة واحدة)
-- شغّله في: Supabase Dashboard → SQL Editor → New query → الصق → Run
-- uid يطابق tvg-id من iptv-org ليعمل جدول البث (EPG) تلقائيًا.
-- ملاحظة: روابط البث عامة وقد تتغيّر — عدّلها لاحقًا من لوحة الإدارة إن لزم.
-- ════════════════════════════════════════════════════════════════════════════
begin;
set local mtc.review_bypass = 'on';  -- ننشرهما مباشرةً دون انتظار المراجعة

-- الجزيرة (العربية) — الرقم = أول رقم متاح (يتجنّب التعارض مع القنوات الحالية)
insert into public.channels (uid, number, name, alt_names, network, country_code, category_slug, language_code, quality, is_published, is_featured, is_manual)
select 'AlJazeera.qa', (select coalesce(max(number), 0) + 1 from public.channels), 'الجزيرة',
       array['Al Jazeera','Al Jazeera Arabic','aljazeera'], 'Al Jazeera', 'qa', 'news', 'ara', 'HD', true, true, true
on conflict (uid) do update set is_published = true, is_featured = true, hidden_reason = null;

insert into public.streams (channel_id, url, label, quality, priority, is_active, status)
select id, 'https://live-hls-web-aja.getaj.net/AJA/index.m3u8', 'AJA', 'HD', 0, true, 'unknown'
from public.channels where uid = 'AlJazeera.qa'
on conflict (url) do nothing;

-- روتانا سينما (السعودية) — الرقم = أول رقم متاح
insert into public.channels (uid, number, name, alt_names, network, country_code, category_slug, language_code, quality, is_published, is_featured, is_manual)
select 'RotanaCinema.sa', (select coalesce(max(number), 0) + 1 from public.channels), 'روتانا سينما',
       array['Rotana Cinema','Rotana','rotanacinema'], 'Rotana', 'sa', 'movies', 'ara', 'HD', true, false, true
on conflict (uid) do update set is_published = true, hidden_reason = null;

insert into public.streams (channel_id, url, label, quality, priority, is_active, status)
select id, 'https://rotana.ercdn.net/rotanacinemaksa/playlist.m3u8', 'Rotana', 'HD', 0, true, 'unknown'
from public.channels where uid = 'RotanaCinema.sa'
on conflict (url) do nothing;

-- اجعل الجزيرة هي القناة الرئيسية (hero)
update public.site_settings
   set value = jsonb_build_object('channel_id', (select id from public.channels where uid = 'AlJazeera.qa'))
 where key = 'hero';

commit;
notify pgrst, 'reload schema';
