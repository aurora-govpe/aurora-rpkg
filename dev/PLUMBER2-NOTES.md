# plumber2 API notes (the bits aurora depends on)

Captured during the design session from the official docs. **Verify against the
installed version** (`packageVersion("plumber2")`) before relying on exact
signatures — these are notes, not a contract.

Sources:
- https://plumber2.posit.co/articles/programmatic-usage.html
- https://plumber2.posit.co/articles/annotations.html
- https://plumber2.posit.co/reference/api.html
- https://cran.r-project.org/web/packages/plumber2/ (refman PDF)
- Tidyverse blog: 0.1.0 (2025-09), 0.2.0 (2026-01)

## Creation / running
- `api(..., host = "127.0.0.1", port = 8080, doc_type = "rapidoc",
   doc_path = "__docs__", ...)` — `...` are plumber files/dirs or a `_server.yml`.
  Empty `api()` builds an object you add to programmatically.
- `api_parse(api, ...)` — parse & attach annotated files after creation.
- `api_run(api, ...)` — start the server (fiery loop).
- `is_plumber_api(x)`.

## Static files
- `api_assets(api, at, path)` — serve files **as a standard route** (goes through
  the router). e.g. `api() |> api_assets("/", "./www")`.
- `api_statics(api, at, path, except = character(0))` — serve files **directly**
  (httpuv level, faster), with `except` paths that fall through to the router.
  Consider this for the SPA if asset/route ordering becomes a problem.

## Routing model
- Handler URL comes from its annotation (`#* @get /path/<var>` — note plumber2
  uses `<var>` in annotations; routr-level uses `:var`).
- `@routeName` names the route in the stack (ordering), NOT a URL prefix.
- Files parsed in alphanumeric order; order affects route precedence.
- `api_add_route(api, name, route, root = NULL, after = NULL)` for programmatic
  routes; `root` prepends to URLs. (We deliberately avoid relying on `root` —
  see ADR-005.)

## Auth (≥ 0.2.0)
- Annotation: `#* @authGuard <name>` with a guard expression, terminated by `_API`.
- Programmatic: `api() |> api_auth_guard(fireproof::guard_key(key_name=, validate=))`.
- The `fireproof` plugin provides guards. This is what `aurora_auth_jwt()` should
  wrap in Phase 3 instead of a hand-rolled filter.

## Server-side storage
- `api_datastore(api, storr::driver_environment())` via the `firesale` plugin;
  list-like interface over a storr KV store (redis/LMDB/DBI/env backends).

## Docs
- Auto-generated from annotations. Programmatic: `api_doc_add()`,
  `api_doc_setting(api, doc_type, doc_path)`. Types: rapidoc/redoc/swagger/NULL.

## Resolved against plumber2 0.2.0 (VALIDATED 2026-06-01, see STATE.md)
- ✅ `api_parse(pa, file)` returns the api for piping. `aurora_app()` chains fine.
- ✅ Asset/route ordering: routers parsed first, `api_assets("/", www)` last.
  `/api/*` and `/health` win; `/` serves `www/index.html`; `/lib/<bslib asset>`
  → 200. No need to switch to `api_statics(except=)`.
- ✅ Helper visibility: `sys.source(helpers/*.R, globalenv())` before
  `api_parse()` works — parsed handlers resolve those functions at request time.
- ✅ `save_html()` writes bslib's `lib/` under `www/lib/` (relative), served at `/`.
- 🔴 **Query params do NOT bind to named handler args** — only path `<var>` do.
  Use the reserved `query` arg. `@query` is doc-only. Reserved handler args:
  `query`, `body`, `request`, `response`, `server`, `client_id`. (Full table in
  `dev/MIGRATION-V1-V2.md`.)
- Test without a server: `pa$test_request(fiery::fake_request(...))` (`content`
  defaults to `""`, must be character).

## Still open
- Exact return shape of `pak::pkg_sysreqs()` used by `aurora_dockerfile()`.
