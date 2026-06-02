# aurora — implementation plan

> **Layout note (ADR-007):** aurora follows the team's canonical, convention-based
> layout (`routers/`, `ui_modules/`, `helpers/`, root `api.R` + `build_ui.R`,
> `www/js/core.js` + `app.js`, `data/config.yml`). No required manifest.

Phased roadmap. Each phase has a goal, tasks, and an acceptance criterion. Check
items off as you complete them and keep `dev/STATE.md` in sync.

## Phase 0 — Foundation  ✅ (done)
Goal: installable package skeleton, conventions, manifest parser.
- [x] DESCRIPTION / NAMESPACE / .Rbuildignore / LICENSE
- [x] `%||%`, cli logging conventions
- [x] `_aurora.yml` reader + validator (`R/manifest.R`)
Acceptance: `devtools::load_all()` succeeds; manifest tests pass.

## Phase 1 — Dev loop (MVP)  ✅ (DONE)
Goal: create → build UI → run locally.
- [x] `aurora_create_app()` (+ `minimal` template)
- [x] `aurora_build_ui()` (bslib → save_html)
- [x] `aurora_app()` (manifest → plumber2 `api()`)
- [x] `aurora_run()` (assemble + `api_run()`)
- [x] `aurora_add_route()` (writes to `routers/`; path embeds `mount`)
- [x] Verify asset/route ordering against a real `api_run()` (DONE — see
      PLUMBER2-NOTES "Resolved"; validated via `test_request`)
- [x] `watch = TRUE` live reload — `later` poll of mtimes rebuilds the static UI
      on `build_ui.R`/`ui_modules/` change (`R/watch.R`); router/helper changes
      log a restart advisory (not hot-swappable). Tested + smoke-tested.
Acceptance: scaffold an app, `aurora_run()` serves UI + `/health` returns JSON. ✅

## Phase 2 — Deploy
Goal: one-command containerisation.
- [x] `aurora_dockerfile()` (sysdeps auto via pak; package scan)
- [x] `aurora_build_image()` (docker CLI wrapper)
- [x] `aurora_shinyproxy_yaml()` — emits the `proxy.specs` block (id/display-name/
      container-image/port/container-env; `wrap`/`write` options). Tested.
- [ ] Validate a generated Dockerfile with a real `docker build` (needs Docker)
- [ ] Optional `packages:` field in `_aurora.yml` to pin prod deps (see BACKLOG)
Acceptance: generated image runs and serves the app on the exposed port.

## Phase 2.5 — Telemetry / OpenTelemetry (requested)
Goal: make instrumentation a one-liner for aurora apps. plumber2 already wires
the HTTP semantic conventions automatically through reqres/fiery/routr (request
spans in `request$otel`, per-route subspans, the `http.server.*` metrics); the
gap is opt-in wiring + ergonomics, not reimplementation. See
`vignette("otel", "plumber2")`.
- [x] `otel`/`logger_otel` support flag: `aurora_run(otel = TRUE)` / `aurora_app(otel=)`
  (or `_aurora.yml: otel: true` / `AURORA_OTEL` env) → `api_logger(logger_otel())`.
  Precedence arg > manifest > env > FALSE (`resolve_otel()`). OFF by default;
  safe no-op until otel is enabled. ADR-008. Tested (`test-otel.R`).
- [x] Document the env setup the `otel` R package needs to actually export
      (`OTEL_*` exporter vars, `OTEL_ENV=dev`, defer to otel/otelsdk) —
      `vignettes/telemetry.Rmd`.
- [x] Document custom-span pattern in handlers (`otel::start_local_active_span()`,
      picks up the active routr subspan) — stay thin per ADR-002, no wrapper.
      `vignettes/telemetry.Rmd`.
- [ ] Make `server$log(...)` the logging convention in scaffolded routes/helpers
      (current minimal template has no `cat()`, so nothing to migrate yet).
Acceptance: a flag turns on otel logging; an example shows a custom span; docs
explain exporter setup. Needs a short ADR (telemetry is opt-in, thin, native).

## Phase 3 — Batteries (auth + data)  ✅ (DONE)
Goal: reproduce the app_aurora_novo capabilities as opt-in modules.
- [x] `auth` template: JWT-via-cookie login/logout routes + `@header` guard on
      `/api/*` (`inst/templates/auth/`). Change-password not included (easy to add
      following the login route). Tested (`test-auth.R`) incl. full login flow.
- [x] Wire `aurora_auth_jwt()` to a real guard — done via a `@header` guard +
      `reqres::abort_unauthorized()` (NOT fireproof; see ADR-010 for why).
      Helpers: `aurora_jwt_token/decode/guard`, `aurora_set/clear_auth_cookie`.
- [~] `core.js`: session-expiry handled via the existing `onUnauthorized` hook
      (app.js shows the login overlay on 401). Login/logout kept in the template's
      app.js, NOT core.js, to keep the runtime thin (ADR-002).
- [x] `aurora_data_store()`: hot-reload of RDS/parquet/csv, globals-free
      (`R/data-store.R`: `aurora_data_store`/`_register`/`_get`/`_names`).
      `aurora_data_get()` re-reads on mtime change. Tested + smoke-tested through
      the live API. Generalises `carregar_bases()` without `<<-`.
Acceptance: `auth` template app logs in, protects `/api/*`; data store hot-reloads. ✅

## Phase 4 — Site & docs  ✅ (DONE)
Goal: a real pkgdown site with a gallery.
- [x] Vignettes: `aurora` (get started, expanded), `migrating-from-shiny`
      (rewritten; absorbs `dev/MIGRATION-V1-V2.md` reqres table), `deploy`
      (expanded: env vars, proxy, ShinyProxy), `auth` (new), `telemetry`.
      All `eval = FALSE`; knit clean and build in `R CMD check`.
- [x] `_pkgdown.yml` reference grouping (Scaffolding/Build&run/UI/Data/Auth/
      Deploy) + Articles + Gallery menu.
- [x] Gallery: `vignettes/articles/gallery.Rmd` lists the 3 examples (01/02/03)
      with run instructions + key files. (Screenshots deferred — need a headless
      browser + running apps; text+links for now.)
- [x] `pkgdown::build_site()` builds clean (sitrep all ✔, 5 articles + gallery +
      21 reference pages). CI: `.github/workflows/pkgdown.yaml` → GitHub Pages.
Acceptance: site builds clean; gallery shows >= 3 examples. ✅

## Phase 5 — Examples
Goal: worked apps that teach the pattern (live in `inst/examples/`).
- [x] `01-hello` (echo route + minimal UI)
- [x] `02-dashboard-echarts` (JSON route + ECharts via fetch)
- [x] `03-map` — MapLibre GL JS (CDN) + `GET /api/regions/geojson`
      (`@serializer geojson` over an `sf` object). `aurora_component()` wires the
      map container; `app.js` fetches + `addSource`/`addLayer`. OSM raster base
      (no API key). README notes `mapgl` as the R-native (build-time-baked)
      alternative. Verified: UI builds, route returns a valid FeatureCollection.
- [~] `04-auth`: effectively covered by the `auth` template
      (`inst/templates/auth/`); a dedicated example is optional.
Acceptance: each example runs with `aurora_run()` pointed at its dir. ✅ (01/02/03)

## Phase 6 — Hardening & release  (in progress)
Goal: ready for internal use / CRAN-ish quality.
- [x] `R CMD check` clean: **0 errors / 0 warnings** / 1 NOTE (intentional template
      dotfiles `.dockerignore`/`.gitkeep`). Fixed: non-ASCII in R/ (→ `\u`/`--`),
      undeclared `nanoparquet`/`fiery` (→ Suggests), stray top-level docs +
      `.claude` + example build artifacts (→ `.Rbuildignore`), Rd Lost-braces.
- [x] GitHub Actions: R-CMD-check **matrix** (ubuntu release/devel/oldrel, macOS,
      windows) — `.github/workflows/R-CMD-check.yaml`.
- [~] Integration tests: covered in-process via `pa$test_request(fake_request())`
      across routing/auth/data/otel suites (88 checks). Real-port `httr2` boot
      deferred (flaky in CI; in-process is equivalent for our assertions).
- [x] `NEWS.md` maintained — finalized as `# aurora 0.1.0` (first release,
      2026-06-01); `DESCRIPTION` `Version: 0.1.0`. Release checklist in
      `dev/RELEASE.md`.
Acceptance: green CI; check clean; tagged `0.1.0`. (check ✅; version+NEWS ✅;
  the actual `git tag v0.1.0` + push must run in a real checkout — this sandbox
  isn't a git repo. See `dev/RELEASE.md`.)
