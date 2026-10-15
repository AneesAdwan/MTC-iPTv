-- تراجع 0005: يحذف ما أضافه فقط (لا يمس أي جدول قديم).
begin;
delete from public.scheduled_tasks where key in ('telemetry_rollup', 'alerts');
drop function if exists public.admin_alerts_scan();
drop function if exists public.admin_alert_raise(text, text, text, text, jsonb, text, text);
drop table if exists public.admin_alerts;
drop function if exists public.admin_telemetry_rollup(date);
drop function if exists public.telemetry_forget(uuid);
drop function if exists public.telemetry_ingest(uuid, text, text, text, jsonb, text);
drop view if exists public.stream_viewer_stats_7d;
drop table if exists public.playback_stats_daily;
drop table if exists public.playback_events;
drop table if exists public.installations;
delete from supabase_migrations.schema_migrations where version = '20261016000400';
notify pgrst, 'reload schema';
commit;
