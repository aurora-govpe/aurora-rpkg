# aurora — current state (resume here)

_Last updated 2026-06-01: Phases 0-4 + Phase 2 (deploy) + Phase 6 (check/CI)
done. `R CMD check` 0 errors / 0 warnings / 1 note; 99 tests pass. Remaining:
`0.1.0` release, a real `docker build` validation, minor verifications (see
"Next actions"). Update this on every task._

## Layout decision (important)
The package now follows **convention, not a manifest** (ADR-007). `aurora_app()`
assembles from the fixed layout in `dev/ARCHITECTURE.md`. `_aurora.yml` is
optional (overrides `name`/`engine`/`auth`).

## Implemented (exists in R/, tested where noted)
- `read_config()` / `assert_is_app()` / `router_files()` / `helper_files()` —
  `R/app-config.R` (tested)
- `aurora_create_app()` — `R/create-app.R` (tested; scaffolds canonical layout,
  injects `www/js/core.js`, first build)
- `aurora_build_ui()` — `R/build-ui.R` (sources root `build_ui.R`)
- `aurora_app()` + `print.aurora_app()` — `R/app.R` (sources helpers/, parses routers/, serves www/)
- `aurora_run()` — `R/run.R`
- `aurora_add_route()` — `R/add-route.R` (tested; writes to `routers/`, mount in annotation)
- `aurora_dockerfile()` + `detect_packages()` — `R/dockerfile.R` (CMD `Rscript api.R`; writes `.dockerignore`)
- `aurora_build_image()` — `R/build-image.R`
- `aurora_auth_jwt()` + `aurora_jwt_token/decode/guard`, `aurora_set/clear_auth_cookie`
  — `R/auth.R` (WIRED, tested; ADR-010)
- `aurora_component()` — `R/component.R` (thin JS contract; ADR-009; tested)
- `aurora_data_store()` + `_register/_get/_names` — `R/data-store.R` (hot-reload; tested)
- Runtime: `inst/runtime/core.js` (thin; copied to `www/js/core.js`)
- Template: `inst/templates/minimal/` (full canonical layout; ships `_brand.yml`
  and uses `bs_theme(version = 5, brand = TRUE)` — see Theming below)
- Examples: `inst/examples/01-hello`, `02-dashboard-echarts` (canonical layout)

## Stubbed / partial (do not assume these work)
- `aurora_app()` only WARNS if `auth:` is in the optional manifest (auth is wired
  in the app's annotated files, not via the manifest — see ADR-010).
- `sysdeps = "auto"` falls back to a default deb list if `pak::pkg_sysreqs()`
  shape differs — verify `pkg_sysreqs(pkgs)$packages$system_packages`.
- Template `dashboard` does NOT exist (`minimal` and `auth` do).
- `data/config.yml` is scaffolded but aurora does not yet expose it to handlers.

(Now DONE since the early notes above: `aurora_auth_jwt` wired, `auth` template,
`watch = TRUE` live reload, `aurora_component`, `aurora_data_store`, brand.yml.)

## Runtime verification ✅ (DONE 2026-06-01, plumber2 0.2.0 / reqres 1.2.0)
All four are confirmed against a live API via `pa$test_request(fake_request())`
(see `dev/PLUMBER2-NOTES.md` "Resolved"):
1. ✅ Asset vs router ordering — `/api/*` and `/health` win; `/` serves
   `index.html`; `/lib/<bslib>` → 200. No `api_statics(except=)` needed.
2. ✅ Helper visibility — `sys.source(globalenv())` handlers resolve helpers.
3. ✅ `api_parse(pa, file)` returns the api for piping.
4. ✅ `save_html()` puts bslib `lib/` under `www/lib/`, served at `/`.

### 🔴 New blocker found: query params don't bind to named handler args
plumber2 only binds **path** `<var>` to named args; query is the reserved
`query` arg, body is `body`, request/response are reqres objects (`request`/
`response`, NOT `req`/`res`). This broke `01-hello` (`function(msg="")`) — FIXED.
Full v1→v2 map + reqres translation table: `dev/MIGRATION-V1-V2.md`.

## Theming via brand.yml ✅ DONE (2026-06-01, ADR-011)
- Minimal template ships `_brand.yml` and uses `bs_theme(version = 5, brand = TRUE)`;
  bslib auto-discovers `_brand.yml` at build time and bakes the theme into
  `www/index.html`. aurora builds no theming layer; the file is convention only.
  `_brand.yml` is orthogonal to `_aurora.yml` (no `brand` key in the manifest).
  Requires bslib >= 0.9.0 + Bootstrap 5. `create_app` test asserts `_brand.yml` exists.
- Known caveat: **logos are NOT auto-applied** by bslib UIs — put files in
  `www/images/` and embed them manually in `build_ui.R`.
- Build path fix (required for brand): `aurora_build_ui()` now runs `build_ui()`
  + `save_html()` with the app dir as the working directory (`setwd`/`on.exit`,
  absolute paths), because `bs_theme(brand = TRUE)` discovers `_brand.yml`
  relative to cwd and `sys.source(chdir=TRUE)` only holds during sourcing, not
  when `build_ui()` is later called. (`R/build-ui.R`.)
- Deps: `brand.yml` package is required by bslib for `brand = TRUE` (added to
  Suggests alongside `bslib (>= 0.9.0)`).
- **CSS bundling confirmed**: the brand primary compiles into
  `www/lib/bootstrap-5.3.8/bootstrap.min.css` (served at `/`, already 200). Still
  🔴 to verify with a WEB-FONT brand: confirm `save_html()` emits/bundles the web
  fonts brand.yml pulls into `www/` so they resolve served statically at `/`
  (the starter uses `system-ui`, which doesn't exercise web fonts). Ties to the
  (resolved) `save_html` `lib/` question above.

## Telemetry / OpenTelemetry ✅ core wiring DONE (2026-06-01, ADR-008)
- `aurora_app(otel=)` / `aurora_run(otel=)` wire `api_logger(logger_otel())`.
  Resolution: explicit arg > `_aurora.yml: otel:` > env `AURORA_OTEL` > FALSE
  (`resolve_otel()`/`as_flag()` in `R/app-config.R`). Default OFF; safe no-op
  until the `otel` pkg is enabled. Tested in `test-otel.R` (suite: 29 PASS, 0 FAIL).
- Docs: `vignettes/telemetry.Rmd` (knits clean; listed in `_pkgdown.yml`) covers
  what's automatic, the 3 ways to enable, exporter env setup (defers to
  otel/otelsdk), and the custom-span pattern. `vignettes/aurora.Rmd` stale layout
  refs (ui/ui.R, routes/, www/aurora) fixed to the canonical layout.

## JS integration ✅ DONE (2026-06-01, ADR-009) — thin contract
- Decided among 3 prototypes (`dev/prototypes/js-contracts/`): chose Option 2
  (thin). `aurora_component(endpoint, ..., id, tag)` in `R/component.R` emits an
  htmltools element with `data-endpoint` (+ extra attrs); ships NO rendering JS;
  `core.js` untouched. App JS reads `el.dataset.endpoint` + `aurora.json()`.
  Tested (`test-component.R`). Example 02 converted to use it. Exported + pkgdown.

## Phase 1 ✅ DONE — watch=TRUE live reload (2026-06-01)
- `aurora_run(watch=TRUE, watch_interval=1)` polls UI sources via `later` and
  rebuilds `www/index.html` on change (`R/watch.R`: `start_ui_watcher`,
  `watch_tick`, `ui_watch_files`, `route_watch_files`, `mtime_snapshot`).
  Router/helper changes log a restart advisory (plumber2 can't hot-swap routes
  in a running server). `later` added to Suggests. Tested (`test-watch.R`) +
  smoke-tested via `later::run_now()` (the poll fires and rebuilds). Phase 1
  acceptance met: scaffold → `aurora_run()` serves UI + `/health` JSON.

## Auth template ✅ DONE (2026-06-01, ADR-010) — Phase 3 auth
- `inst/templates/auth/`: JWT-cookie login gating `/api/*`. Wiring is 100%
  annotation-based (a `@header @any /api/*` guard + public `/auth/login`+`/logout`),
  so `aurora_app()` is untouched (ADR-003). Demo store (admin/admin123, sodium).
- `R/auth.R` rewritten: `aurora_auth_jwt()` (scheme) + `aurora_jwt_token`,
  `aurora_jwt_decode`, `aurora_jwt_guard`, `aurora_set_auth_cookie`,
  `aurora_clear_auth_cookie`. Wraps jose + reqres. NOT fireproof (ADR-010: needs
  firesale datastore, returns 400/403 not 401, targets upstream IdPs).
- `aurora_create_app(template = "auth")` ships. jose/sodium/reqres in Suggests.
- Tested end-to-end (`test-auth.R`): gate 401, login→cookie→/api/me 200, bad→401,
  logout clears cookie. Full suite: 74 PASS / 0 FAIL.
- Gotchas hit (now in LESSONS): `plumber2::Next` must be namespaced; reqres
  `same_site` capitalised; cookies live outside `$headers` (use `as_list()`).

## Data store ✅ DONE (2026-06-01) — Phase 3 complete
- `aurora_data_store(..., dir, readers)` + `aurora_data_register/get/names`
  (`R/data-store.R`). Globals-free, self-contained store; `aurora_data_get()`
  lazily re-reads on file mtime change (hot-reload). Readers by extension
  (rds/csv/parquet via nanoparquet). Define in a `helpers/*.R`, read in handlers.
- Path contract: relative paths resolve against cwd at read time (= app dir in
  the canonical `Rscript api.R` deployment); pass absolute `dir` otherwise. Used
  `fs::path_abs(path, start=dir)` (LESSONS: `fs::path` doesn't collapse abs paths).
- Tested (`test-data-store.R`, 13 checks) + smoke-tested hot-reload through the
  live API. Full suite: 88 PASS / 0 FAIL.

## Phase 6 hardening ▶ in progress (2026-06-01)
- `R CMD check`: **0 errors / 0 warnings**, 1 NOTE (intentional template dotfiles).
  Fixes: non-ASCII in R/ escaped (`ã`, code `—`; roxygen/comments use
  `--`), `nanoparquet`+`fiery` added to Suggests, `.Rbuildignore` for `.claude` +
  stray top-level `ARCHITECTURE.md`/`STATE.md` (stale dup of dev/) + example
  `www/lib`+`index.html` build artifacts, Rd Lost-braces in `aurora_component`.
- CI: R-CMD-check matrix workflow added. `NEWS.md` rewritten for Phases 0–3.
- Suite still 88 PASS / 0 FAIL after the non-ASCII edits.
- Gotcha (LESSONS-worthy): `\u` escapes work in R **string literals** but NOT in
  roxygen `#'` text — they leak into `.Rd` as an unknown `\u` macro (WARNING).
  Use plain ASCII (`--`) in roxygen/comments.

## Examples (Phase 5)
- `01-hello`, `02-dashboard-echarts`, and now `03-map` (MapLibre GL JS + a
  `@serializer geojson` `/api/regions/geojson` route over `sf`; `mapgl` noted as
  the R-native alternative in its README). `04-auth` is covered by the `auth`
  template. Examples stay on a bslib `preset` (not brand) by design.

## Phase 4 ✅ DONE (2026-06-01) — site & docs
- Vignettes: `aurora` (expanded), `deploy` (expanded), `auth` (new),
  `migrating-from-shiny` (rewritten, absorbs the v1->v2 reqres table), `telemetry`.
  `vignettes/articles/gallery.Rmd` lists examples 01/02/03 (screenshots deferred).
- `_pkgdown.yml` reference groups + articles + gallery; `pkgdown::build_site()`
  builds clean (sitrep all ok). CI: `.github/workflows/pkgdown.yaml` → Pages.
- Site polished: brand-matched bslib theme (primary `#2c3e50`, Jost font),
  `development: mode: auto`, README refreshed as the home page. pkgdown renders
  root `CLAUDE.md` (agent manual) as an unlinked page — the workflow `rm`s it
  before deploy. `docs/` is gitignored (CI deploys to gh-pages).
- Cleanup: removed stray root `ARCHITECTURE.md`/`STATE.md` (stale dup of dev/;
  pkgdown was reading them); DESCRIPTION URL now includes the pages URL.
- `R CMD check` still 0/0/1; suite 88/0.

## Phase 2 deploy ✅ aurora_shinyproxy_yaml() DONE (2026-06-01)
- `aurora_shinyproxy_yaml(image, dir, id, display_name, description, port, env,
  wrap, write, file)` in `R/shinyproxy.R` — emits a ShinyProxy `proxy.specs`
  entry (or full `proxy: specs:` snippet with `wrap = TRUE`). id/display-name
  default from the app name; `display_name` follows `id`. Tested (`test-shinyproxy.R`,
  11 checks). Deploy vignette + pkgdown updated. Suite 99/0; check 0/0/1.

## Release 0.1.0 ▶ prepped (2026-06-01)
- `DESCRIPTION` `Version: 0.1.0`; `NEWS.md` finalized as `# aurora 0.1.0` (first
  release). Pre-flight all green: document clean, 99 tests pass, `R CMD check`
  0 errors / 0 warnings / 1 note (template dotfiles). Checklist: `dev/RELEASE.md`.
- NOT done (needs a real git checkout — this sandbox isn't a git repo): the
  `git tag v0.1.0` + push, enabling GitHub Pages, and the GitHub Release. After
  tagging, bump to `0.1.0.9000` and add a new NEWS dev heading (see RELEASE.md).

## Package logo ✅ DONE (2026-06-01)
- `man/figures/logo.svg` (hex sticker from the user); referenced in README title;
  favicons generated (`pkgdown::build_favicons()`); shows in the pkgdown navbar.
  Site rebuilt clean with the logo.

## Dockerfile validation ✅ DONE (2026-06-02) — built + ran + served
Validated a generated debian Dockerfile via real `docker build --platform
linux/amd64` (Docker 29.4.3; aurora from the local 0.1.0 tarball since it isn't
on GitHub yet). Final container: boots ~2s, `GET /health` 200 JSON, `GET /` 200
(static UI), `GET /lib/<bslib>.css` 200 — with NO bslib/shiny in the image.
Bugs found and fixed in `R/dockerfile.R` / `R/run.R` / minimal template:
- Missing `brand.yml` for `bs_theme(brand=TRUE)` (UI build only — see below).
- Source-compile failures → expanded `default_sysdeps` (harfbuzz/fribidi/
  freetype/png/tiff/jpeg) AND set PPM `repos` + `HTTPUserAgent` in `Rprofile.site`
  so PPM serves binaries. (PPM is amd64-only → build `--platform linux/amd64`.)
- `fs` binary needs runtime `libuv` → added `libuv1-dev` (Debian) / `libuv`(-dev)
  (Alpine).
- 🔴 Architecture fix: **bslib `page_*()` require shiny**, so the container now
  serves the PREBUILT UI and does NOT rebuild (`AURORA_REBUILD_UI=false`;
  `aurora_run(rebuild_ui=NULL)` resolves the env). `aurora_dockerfile()` installs
  RUNTIME deps only (routers/+helpers/+api.R, not build_ui/ui_modules), so no
  bslib/shiny/brand.yml in the image. Build the UI before the image.
Note: the GitHub-source install line (`pak::pak('segpr-ndgr/aurora')`) is the one
bit not validated locally (aurora unpublished); validation used the tarball.

## Next actions (pick up here)
0.1.0 prepped (tag pending a real checkout). Remaining:
- Finish Dockerfile validation: HTTPUserAgent binary fix + confirm container serves.
- Phase 6 release: tag `0.1.0` (push to GitHub so CI + pkgdown run); optional
  real-port `httr2` integration test.
- Gallery screenshots (need a headless browser + running apps).
- Verify brand.yml **web-font** bundling via `save_html()` (CSS already confirmed).
- Optional: `dashboard` template; DBI-backed data-store reader; expose
  `data/config.yml` to handlers.

## How to regenerate derived files
```r
devtools::document()   # man/ + NAMESPACE from roxygen
```
