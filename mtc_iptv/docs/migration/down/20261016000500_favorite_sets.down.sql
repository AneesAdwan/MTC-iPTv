-- تراجع 0006: يحذف جدول المفضلة المتزامنة ودواله فقط.
begin;
drop function if exists public.admin_favsets_purge();
drop function if exists public.fav_delete(text, text);
drop function if exists public.fav_put(text, text, jsonb);
drop function if exists public.fav_get(text);
drop function if exists public.fav_create(jsonb);
drop function if exists public._fav_clean(jsonb);
drop function if exists public._fav_hash(text);
drop table if exists public.favorite_sets;
delete from supabase_migrations.schema_migrations where version = '20261016000500';
notify pgrst, 'reload schema';
commit;
