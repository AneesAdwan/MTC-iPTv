-- التراجع عن 0007 (سلة المحذوفات). يُشغَّل يدويًا (SQL Editor / psql) فقط إن لزم، ثم يُحذف صفه من
-- supabase_migrations.schema_migrations. القنوات التي في السلة تبقى مخفية (لا تُحذف ولا تُنشر).
begin;
drop function if exists public.admin_trash(uuid[], text);
drop function if exists public.admin_restore(uuid[]);
drop function if exists public.admin_trash_purge(uuid[], integer);
drop index if exists public.channels_trashed_idx;
alter table public.channels drop column if exists trashed_at, drop column if exists trashed_by,
                            drop column if exists trash_reason, drop column if exists trash_prev;
-- admin_review_apply: يعود لتعريف baseline (يحذف عند reject/merge) — لا نعيده عمدًا؛ النسخة الآمنة تبقى.
commit;
notify pgrst, 'reload schema';
