-- ════════════════════════════════════════════════════════════════════════════
-- MTC-iPTv — التحقق من الترحيل (§24.4) — نسخة «استعلام واحد»
-- محرّر Supabase يعرض نتيجة آخر استعلام فقط، فهذه النسخة تجمع الأقسام الستة في جدول واحد.
-- للقراءة فقط: لا يعدّل أي شيء. انسخ الملف كاملًا ← SQL Editor ← Run ← Export ← CSV.
-- ════════════════════════════════════════════════════════════════════════════
with
counts as (
  select '1_counts'::text as section, t.table_name::text as item,
         (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from public.%I', t.table_name), false, true, '')))[1]::text::bigint as value
  from information_schema.tables t
  where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
),
anomalies as (
  select '2_anomaly', 'channels_without_streams', count(*) from channels c where not exists (select 1 from streams s where s.channel_id = c.id)
  union all select '2_anomaly', 'published_without_active_stream', count(*) from channels c where c.is_published and not exists (select 1 from streams s where s.channel_id = c.id and s.is_active)
  union all select '2_anomaly', 'duplicate_chains', count(*) from channels a join channels b on b.id = a.duplicate_of where b.duplicate_of is not null
  union all select '2_anomaly', 'duplicate_self', count(*) from channels a where a.duplicate_of = a.id
  union all select '2_anomaly', 'published_with_hidden_reason', count(*) from channels where is_published and hidden_reason is not null
  union all select '2_anomaly', 'streams_with_credentials', count(*) from streams where url ~* '/(live|movie|series)/[^/]+/[^/]+/\d+' or url ~* '[?&](username|password|token)=' or url ~ '://[^/@]+@'
  union all select '2_anomaly', 'epg_id_shared', count(*) from (select coalesce(epg_id, regexp_replace(uid, '@.*$', '')) k from channels group by 1 having count(*) > 1) x
  union all select '2_anomaly', 'arabic_names', count(*) from channels where name ~ '[؀-ۿ]'
  union all select '2_anomaly', 'manual_channels', count(*) from channels where is_manual
  union all select '2_anomaly', 'prefer_app_channels', count(*) from channels where prefer_app
),
dist as (
  select '3_hidden_reason', coalesce(hidden_reason, '(null)'), count(*) from channels group by 2
  union all select '3_stream_status', status, count(*) from streams group by 2
  union all select '3_stream_active', is_active::text, count(*) from streams group by 2
  union all select '3_source_status', status, count(*) from playlist_sources group by 2
  union all select '3_settings_key', key, 1 from site_settings
),
views as (
  select '4_public_view', 'catalog_rows', count(*) from catalog
  union all select '4_public_view', 'catalog_streams_rows', count(*) from catalog_streams
  union all select '4_public_view', 'catalog_hash',
    ('x' || substr(md5(string_agg(id::text || '|' || coalesce(number::text, '') || '|' || name, ',' order by id)), 1, 15))::bit(60)::bigint from catalog
  union all select '4_public_view', 'catalog_streams_hash',
    ('x' || substr(md5(string_agg(id::text || '|' || url, ',' order by id)), 1, 15))::bit(60)::bigint from catalog_streams
),
hashes as (
  select '5_hash', 'channels.uid+name+number',
    ('x' || substr(md5(string_agg(uid || '|' || name || '|' || coalesce(number::text, ''), ',' order by uid)), 1, 15))::bit(60)::bigint from channels
  union all select '5_hash', 'streams.url+channel', ('x' || substr(md5(string_agg(url || '|' || channel_id::text, ',' order by url)), 1, 15))::bit(60)::bigint from streams
  union all select '5_hash', 'published_ids', ('x' || substr(md5(string_agg(id::text, ',' order by id)), 1, 15))::bit(60)::bigint from channels where is_published
),
orphans as (
  select '6_orphan', 'streams_without_channel', count(*) from streams s where not exists (select 1 from channels c where c.id = s.channel_id)
  union all select '6_orphan', 'reports_without_channel', count(*) from reports r where not exists (select 1 from channels c where c.id = r.channel_id)
  union all select '6_orphan', 'channels_bad_country', count(*) from channels c where c.country_code is not null and not exists (select 1 from countries x where x.code = c.country_code)
  union all select '6_orphan', 'channels_bad_category', count(*) from channels c where c.category_slug is not null and not exists (select 1 from categories x where x.slug = c.category_slug)
)
select * from counts
union all select * from anomalies
union all select * from dist
union all select * from views
union all select * from hashes
union all select * from orphans
order by 1, 2;
