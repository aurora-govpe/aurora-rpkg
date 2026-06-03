# aurora 0.1.2

## Fixes
- Alpine Dockerfiles now install `tzdata` whenever `aurora_dockerfile(tz = )` is
  set (the default). Alpine ships no timezone database, so `ENV TZ` previously
  fell back to UTC; with `tzdata` the timezone (e.g. `America/Recife`) resolves
  in the OS, R, and DB drivers.

# aurora 0.1.1

Hardening and ergonomics distilled from migrating and containerizing a real app.

## New
- `aurora_config()` reads `data/config.yml` anchored to the app root (no cwd pitfall).
- `aurora_check()` lints an app: UI code in runtime helpers, packages used but
  undeclared in `_aurora.yml`, missing prebuilt UI.
- JSON serializer helpers `aurora_unbox()` / `aurora_geojson()` / `aurora_unique()`
  (NULL-safe unbox / sf -> GeoJSON / sorted-unique).
- `aurora_app(attach = )` / `_aurora.yml: attach:` attaches the declared runtime
  `packages:` before sourcing helpers, so handlers can call them unqualified.
- `aurora_run(on_exit = )` runs a cleanup function when the server stops (e.g.
  `pool::poolClose()`), on plumber2's `"end"` lifecycle event.
- `aurora_dockerfile(tz = )` bakes `ENV TZ` (default `America/Recife`); the
  default `aurora_source` is pinned to a release tag for reproducible builds.

## Fixes
- Helpers are sourced with the app directory as the working directory, so
  app-root-relative paths (`config::get("data/config.yml")`, `readRDS("data/x.rds")`)
  resolve as they did under the plumber-v1 entrypoint.
- Helper/router/UI-builder load failures name the offending file and hint a
  missing package, instead of a bare `loadNamespace` error.
- Alpine Dockerfiles get per-package system deps (`sf` -> gdal/geos/proj,
  `RPostgres` -> libpq, ...) plus gfortran/libgfortran; `.dockerignore` excludes
  `data/`.

## Docs
- Refreshed README and pkgdown home; modern bslib theme keyed to the logo
  (Inter + Jost + JetBrains Mono, warm palette, light/dark switch); package authors.

# aurora 0.1.0

First release (2026-06-01). A complete dev loop, theming, UI↔API wiring, opt-in
auth/data/telemetry, Docker/ShinyProxy generation, three worked examples, and a
pkgdown site. `R CMD check` is clean (0 errors / 0 warnings).

## Dev loop
- `aurora_create_app()` (templates: `minimal`, `auth`), `aurora_build_ui()`,
  `aurora_app()`, `aurora_run()`, `aurora_add_route()`.
- `aurora_run(watch = TRUE)`: live-reload rebuilds the static UI when
  `build_ui.R`/`ui_modules/` change (polls via `later`).

## Theming
- Theming via **brand.yml**: the `minimal` template ships `_brand.yml` and uses
  `bs_theme(version = 5, brand = TRUE)`; bslib bakes the theme into the static
  HTML at build time. aurora builds no theming layer.

## UI ↔ API
- `aurora_component()`: thin helper emitting an element wired to a JSON endpoint
  via `data-endpoint`; app JS renders. No rendering JS shipped.

## Auth (opt-in)
- JWT-cookie scheme `aurora_auth_jwt()` + `aurora_jwt_token()`,
  `aurora_jwt_decode()`, `aurora_jwt_guard()`, `aurora_set_auth_cookie()`,
  `aurora_clear_auth_cookie()`. The `auth` template gates `/api/*` with a
  `@header` guard and `reqres::abort_unauthorized()`.

## Data
- `aurora_data_store()` + `aurora_data_register()`, `aurora_data_get()`,
  `aurora_data_names()`: globals-free store that hot-reloads a dataset when its
  file changes on disk.

## Telemetry
- OpenTelemetry logging via `aurora_run(otel = TRUE)` / `aurora_app(otel=)` /
  `AURORA_OTEL` — wires `api_logger(logger_otel())`, off by default.

## Deploy
- `aurora_dockerfile()` with a `flavor` argument: `"debian"` (default;
  `rocker/r-ver` + Posit Package Manager binaries) or `"alpine"` (`rhub/r-minimal`
  + `installr`, a tiny source-built image). `aurora_build_image()` and
  `aurora_shinyproxy_yaml()` (emits a ShinyProxy `proxy.specs` block).

See the package website for the full reference and articles.
