# Changelog

## aurora 0.1.1

Hardening and ergonomics distilled from migrating and containerizing a
real app.

### New

- [`aurora_config()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_config.md)
  reads `data/config.yml` anchored to the app root (no cwd pitfall).
- [`aurora_check()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_check.md)
  lints an app: UI code in runtime helpers, packages used but undeclared
  in `_aurora.yml`, missing prebuilt UI.
- JSON serializer helpers
  [`aurora_unbox()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_unbox.md)
  /
  [`aurora_geojson()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_geojson.md)
  /
  [`aurora_unique()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_unique.md)
  (NULL-safe unbox / sf -\> GeoJSON / sorted-unique).
- `aurora_app(attach = )` / `_aurora.yml: attach:` attaches the declared
  runtime `packages:` before sourcing helpers, so handlers can call them
  unqualified.
- `aurora_run(on_exit = )` runs a cleanup function when the server stops
  (e.g. `pool::poolClose()`), on plumber2’s `"end"` lifecycle event.
- `aurora_dockerfile(tz = )` bakes `ENV TZ` (default `America/Recife`);
  the default `aurora_source` is pinned to a release tag for
  reproducible builds.

### Fixes

- Helpers are sourced with the app directory as the working directory,
  so app-root-relative paths (`config::get("data/config.yml")`,
  `readRDS("data/x.rds")`) resolve as they did under the plumber-v1
  entrypoint.
- Helper/router/UI-builder load failures name the offending file and
  hint a missing package, instead of a bare `loadNamespace` error.
- Alpine Dockerfiles get per-package system deps (`sf` -\>
  gdal/geos/proj, `RPostgres` -\> libpq, …) plus gfortran/libgfortran;
  `.dockerignore` excludes `data/`.

### Docs

- Refreshed README and pkgdown home; modern bslib theme keyed to the
  logo (Inter + Jost + JetBrains Mono, warm palette, light/dark switch);
  package authors.

## aurora 0.1.0

First release (2026-06-01). A complete dev loop, theming, UI↔︎API wiring,
opt-in auth/data/telemetry, Docker/ShinyProxy generation, three worked
examples, and a pkgdown site. `R CMD check` is clean (0 errors / 0
warnings).

### Dev loop

- [`aurora_create_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_create_app.md)
  (templates: `minimal`, `auth`),
  [`aurora_build_ui()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_ui.md),
  [`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md),
  [`aurora_run()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_run.md),
  [`aurora_add_route()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_add_route.md).
- `aurora_run(watch = TRUE)`: live-reload rebuilds the static UI when
  `build_ui.R`/`ui_modules/` change (polls via `later`).

### Theming

- Theming via **brand.yml**: the `minimal` template ships `_brand.yml`
  and uses `bs_theme(version = 5, brand = TRUE)`; bslib bakes the theme
  into the static HTML at build time. aurora builds no theming layer.

### UI ↔︎ API

- [`aurora_component()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_component.md):
  thin helper emitting an element wired to a JSON endpoint via
  `data-endpoint`; app JS renders. No rendering JS shipped.

### Auth (opt-in)

- JWT-cookie scheme
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md) +
  [`aurora_jwt_token()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_token.md),
  [`aurora_jwt_decode()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_decode.md),
  [`aurora_jwt_guard()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_guard.md),
  [`aurora_set_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md),
  [`aurora_clear_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md).
  The `auth` template gates `/api/*` with a `@header` guard and
  [`reqres::abort_unauthorized()`](https://reqres.data-imaginist.com/reference/abort_http_problem.html).

### Data

- [`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md) +
  [`aurora_data_register()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_register.md),
  [`aurora_data_get()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_get.md),
  [`aurora_data_names()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_names.md):
  globals-free store that hot-reloads a dataset when its file changes on
  disk.

### Telemetry

- OpenTelemetry logging via `aurora_run(otel = TRUE)` /
  `aurora_app(otel=)` / `AURORA_OTEL` — wires
  `api_logger(logger_otel())`, off by default.

### Deploy

- [`aurora_dockerfile()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_dockerfile.md)
  with a `flavor` argument: `"debian"` (default; `rocker/r-ver` + Posit
  Package Manager binaries) or `"alpine"` (`rhub/r-minimal`
  - `installr`, a tiny source-built image).
    [`aurora_build_image()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_image.md)
    and
    [`aurora_shinyproxy_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_shinyproxy_yaml.md)
    (emits a ShinyProxy `proxy.specs` block).

See the package website for the full reference and articles.
