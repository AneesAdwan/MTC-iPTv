# Production pre-check — SuperAdmin Phase 2.1 (2026-10-17)

Read-only. Every number below came from a single `select` run with
`supabase db query --linked` (aggregates and catalog metadata only; no user data, no secrets).
Nothing was written to production. Plan reference: `docs/plans/admin-rebuild-2026-10.md` §9.1, §9.2, Appendix B م-15 / م-16.

## Migrations already applied in production

`20261015000000, 20261015000100, 20261015000200, 20261016000300, 20261016000400, 20261016000500, 20261016000700`
(the same set as `supabase/migrations/` before this phase). New in this phase, **not applied**:
`20261017000800_admin_session_proof.sql`, `20261017000900_stream_source_attributions.sql`.

## Streams and sources (§9.2)

| Metric | Value |
|---|---|
| `streams` total | **921** |
| with `source_id` | **527** |
| without `source_id` (manual / file import / iptv-org add) | **394** |
| `source_id` pointing to a missing source | 0 |
| `playlist_sources` | **2** (both `is_active`) |
| exact duplicate `url` | 0 (unique constraint) |

Backfill expectation: `stream_source_attributions` will receive **527** rows (one per stream with `source_id`).

### Duplicates after URL normalization

| Normalization | Groups | Rows |
|---|---|---|
| `lower(scheme://host)` + path with trailing `/` trimmed (the planned `url_norm`) | **0** | 0 |
| looser: also ignore scheme and port | 6 | 12 |

The 6 looser groups: 4 differ only by `http` vs `https`, the rest by port; **all 6 span different
channels**, 1 spans two sources. They are *not* merged by the migration (different scheme/port can be a
different server). They are a candidate list for the decisions center later, not a migration blocker.

## SQL functions that reference `streams.source_id`

`pg_proc.prosrc ILIKE '%source_id%'` in schema `public` (all `SECURITY DEFINER`, owner `postgres`):

| Function | What it does with `source_id` | Phase 2.3 action |
|---|---|---|
| `admin_import(uuid, jsonb, boolean)` | inserts streams with `source_id`; on URL conflict keeps the first source (`coalesce`) — م-15 | also upserts an attribution for `p_source` for every URL in the batch (present = true, last_seen = now()); signature unchanged |
| `admin_cleanup(text)` | `refresh_counts` counts streams by `source_id` | counts from attributions (`present`) |
| `admin_finish_import(uuid, text[])` | **deletes** a source's streams that vanished + orphan channels | legacy/banned → now raises; replacement `admin_source_sync_finish` (present = false, never deletes) |
| `admin_delete_source(uuid)` | **deletes** all a source's streams + orphan channels + the source | legacy/banned → now raises; replacement `admin_source_remove` (detach + disable) |

App code (`mtc_iptv/lib`) never calls `admin_finish_import` / `admin_delete_source` / `admin_merge`.
The published legacy web panel `asadmin/admin.js` **does** call all three (lines 200, 2147, 882/894/1183) — see
"behaviour changes" in the phase report.

The temporary SuperAdmin (`mtc_iptv/lib/data/admin/admin_repository.dart`) also reads/writes
`streams.source_id` **directly** through REST: `matchingCatalog()`, `sourceStreams()`, `markSourceImported()`,
and `removeSource()` (`update streams set source_id = null` then `delete from playlist_sources`).

## `auth.sessions` from a `SECURITY DEFINER` function (§9.1)

| Check | Value |
|---|---|
| `auth.sessions` owner | `supabase_auth_admin` |
| RLS on `auth.sessions` | on (bypassed: `postgres` has `rolbypassrls = true`) |
| `postgres` USAGE on schema `auth` | yes |
| `postgres` SELECT / DELETE on `auth.sessions` | yes / yes |
| owner of `public.is_admin()` | `postgres` |
| columns used | `id`, `user_id`, `aal` (enum `auth.aal_level`), `not_after` (all present) |

So a `SECURITY DEFINER` function owned by `postgres` can read and delete `auth.sessions` — required by the
new `is_admin()` and `admin_session_revoke()`.

Admin footprint: 1 row in `admin_users`; 3 `auth.sessions` rows for that user, all `aal2` and not expired.
After the migration each of them stays admin as long as the device's JWT carries the matching `session_id`
(GoTrue always puts it in the token), so nobody is logged out by the migration itself.

RLS policies calling `is_admin()`: 11 (they get the stricter check automatically). Policies still on the legacy
`is_mtc_admin()` (no MFA): 12 — `channels`, `streams`, `playlist_sources`, `site_settings`, reference tables, `reports`.
Out of scope here; listed for the later RLS hardening step.

## JWT expiry (§9.1 "10 minutes")

Not a database setting. Production: Supabase Dashboard → Authentication → Sessions / JWT expiry (project config).
Local: `supabase/config.toml` → `[auth] jwt_expiry = 3600`. Inactivity timeout / time-box: `[auth.sessions]`
(`timebox`, `inactivity_timeout`; commented out locally). The new `is_admin()` already rejects a revoked or deleted
session immediately, independent of the JWT lifetime; shortening the expiry is a separate owner step.
