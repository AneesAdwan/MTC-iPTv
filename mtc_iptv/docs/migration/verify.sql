-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — التحقق من الترحيل (§24.4)
-- يُشغَّل مرتين: قبل الترحيل وبعده، وتُقارن النتائج. للقراءة فقط: لا يعدّل أي شيء.
-- التشغيل: Supabase → SQL Editor (بحساب المالك) أو  psql -f verify.sql
-- ════════════════════════════════════════════════════════════════════════════

-- 1) أعداد السجلات لكل جدول
select 'counts' as section, t.table_name as item,
       (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from public.%I', t.table_name), false, true, '')))[1]::text::bigint as value
from information_schema.tables t
where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
order by t.table_name;

-- 2) الحالات الشاذة (inventory.md §8)
select 'anomaly' as section, item, value from (
  select 'channels_without_streams' as item, count(*) as value
    from channels c where not exists (select 1 from streams s where s.channel_id = c.id)
  union all select 'published_without_active_stream', count(*)
    from channels c where c.is_published and not exists (select 1 from streams s where s.channel_id = c.id and s.is_active)
  union all select 'duplicate_chains', count(*)
    from channels a join channels b on b.id = a.duplicate_of where b.duplicate_of is not null
  union all select 'duplicate_self_or_missing', count(*)
    from channels a where a.duplicate_of = a.id
  union all select 'published_with_hidden_reason', count(*)
    from channels where is_published and hidden_reason is not null
  union all select 'streams_with_credentials', count(*)
    from streams where url ~* '/(live|movie|series)/[^/]+/[^/]+/\d+' or url ~* '[?&](username|password|token)=' or url ~ '://[^/@]+@'
  union all select 'epg_id_shared', count(*) from (
    select coalesce(epg_id, regexp_replace(uid, '@.*$', '')) k from channels group by 1 having count(*) > 1) x
  union all select 'arabic_names', count(*)
    from channels where name ~ '[؀-ۿ]'
  union all select 'manual_channels', count(*)
    from channels where is_manual
  union all select 'prefer_app_channels', count(*)
    from channels where prefer_app
) a;

-- 3) التوزيعات
select 'hidden_reason' as section, coalesce(hidden_reason, '(null)') as item, count(*) as value from channels group by 2
union all select 'stream_status', status, count(*) from streams group by 2
union all select 'stream_active', is_active::text, count(*) from streams group by 2
union all select 'source_status', status, count(*) from playlist_sources group by 2
union all select 'settings_keys', key, 1 from site_settings
order by 1, 2;

-- 4) الواجهات العامة: يجب أن تبقى متطابقة قبل الترحيل وبعده
select 'public_view' as section, 'catalog_rows' as item, count(*) as value from catalog
union all select 'public_view', 'catalog_streams_rows', count(*) from catalog_streams
union all select 'public_view', 'catalog_hash',
  ('x' || substr(md5(string_agg(id::text || '|' || coalesce(number::text,'') || '|' || name, ',' order by id)), 1, 15))::bit(60)::bigint from catalog
union all select 'public_view', 'catalog_streams_hash',
  ('x' || substr(md5(string_agg(id::text || '|' || url, ',' order by id)), 1, 15))::bit(60)::bigint from catalog_streams;

-- 5) بصمات الأعمدة الأساسية (يجب أن تتطابق بعد الترحيل)
select 'hash' as section, 'channels.uid+name+number' as item,
  ('x' || substr(md5(string_agg(uid || '|' || name || '|' || coalesce(number::text, ''), ',' order by uid)), 1, 15))::bit(60)::bigint as value from channels
union all select 'hash', 'streams.url+channel', ('x' || substr(md5(string_agg(url || '|' || channel_id::text, ',' order by url)), 1, 15))::bit(60)::bigint from streams
union all select 'hash', 'published_ids', ('x' || substr(md5(string_agg(id::text, ',' order by id)), 1, 15))::bit(60)::bigint from channels where is_published;

-- 6) سلامة المفاتيح الأجنبية (يجب أن تكون كلها صفرًا)
select 'orphan' as section, item, value from (
  select 'streams_without_channel' as item, count(*) as value from streams s where not exists (select 1 from channels c where c.id = s.channel_id)
  union all select 'reports_without_channel', count(*) from reports r where not exists (select 1 from channels c where c.id = r.channel_id)
  union all select 'channels_bad_country', count(*) from channels c where c.country_code is not null and not exists (select 1 from countries x where x.code = c.country_code)
  union all select 'channels_bad_category', count(*) from channels c where c.category_slug is not null and not exists (select 1 from categories x where x.slug = c.category_slug)
) o;
