-- تراجع 0004: يحذف ما أضافه فقط (لا يمس epg_programmes ولا أي جدول قديم).
-- كلمات مرور Xtream تُحذف من Vault أولًا.
begin;
delete from vault.secrets where id in (select secret_id from public.xtream_accounts);
drop function if exists public.admin_xtream_delete(uuid);
drop function if exists public.admin_xtream_password(uuid);
drop function if exists public.admin_xtream_save(text, text, text, text);
drop table if exists public.xtream_accounts;
drop table if exists public.transform_rules;
drop function if exists public.admin_epg_finish(uuid, text, integer, integer, text);
drop function if exists public.admin_epg_upsert(jsonb);
drop table if exists public.epg_sources;
delete from supabase_migrations.schema_migrations where version = '20261016000300';
commit;
