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
