-- ROLLBACK of migration 20261015000100_phase2_foundation (§24.7 level 2).
-- Removes ONLY what 0002 added; the baseline schema and all legacy data stay untouched.
-- Run manually (SQL Editor / psql) only if 0002 must be undone, then delete its row from
-- supabase_migrations.schema_migrations. Tested in the rehearsal (docs/migration/rehearsal-*.md).
begin;

drop function if exists public.admin_task_acquire(text, text, integer);
drop function if exists public.admin_task_finish(text, text, text);
drop table if exists public.task_runs, public.scheduled_tasks;

drop function if exists public.catalog_changes(bigint, integer);
drop trigger if exists zz_tombstone on public.channels;
drop trigger if exists zz_tombstone on public.streams;
drop function if exists public.catalog_tombstone();
drop table if exists public.catalog_tombstones;

do $$
declare t text;
begin
  foreach t in array array['channels','streams','playlist_sources','site_settings','categories','countries','languages','admin_users','channel_field_provenance'] loop
    if to_regclass('public.' || t) is not null then
      execute format('drop trigger if exists zz_audit on public.%I', t);
    end if;
  end loop;
end $$;
drop function if exists public.audit_row();
drop function if exists public.audit_clean(jsonb);
drop table if exists public.audit_logs;

drop table if exists public.channel_field_provenance;

drop trigger if exists streams_zz_compat on public.streams;
drop function if exists public.streams_zz_compat();
drop index if exists public.streams_rev_idx;
alter table public.streams
  drop column if exists catalog_rev, drop column if exists health_score, drop column if exists health_reason,
  drop column if exists health_state, drop column if exists has_credentials, drop column if exists protocol,
  drop column if exists kodi_props, drop column if exists headers, drop column if exists referrer, drop column if exists user_agent;

drop trigger if exists channels_zz_compat on public.channels;
drop function if exists public.channels_zz_compat();
drop index if exists public.channels_rev_idx;
drop index if exists public.channels_state_idx;
alter table public.channels
  drop column if exists catalog_rev, drop column if exists parental_locked, drop column if exists epg_offset_minutes,
  drop column if exists family_key, drop column if exists merged_into, drop column if exists publish_state,
  drop column if exists name_en, drop column if exists name_ar;

drop sequence if exists public.catalog_rev_seq;
drop function if exists public.url_protocol(text);
drop function if exists public.url_has_credentials(text);
drop function if exists public.mask_credentials(text);
drop function if exists public.admin_status();
drop function if exists public.is_admin();

commit;
notify pgrst, 'reload schema';
