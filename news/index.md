# Changelog

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
  into the static HTML at build time. aurora builds no theming layer
  (ADR-011).

### UI ↔︎ API

- [`aurora_component()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_component.md):
  thin helper emitting an element wired to a JSON endpoint via
  `data-endpoint`; app JS renders. No rendering JS shipped (ADR-009).

### Auth (opt-in)

- JWT-cookie scheme
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md) +
  [`aurora_jwt_token()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_token.md),
  [`aurora_jwt_decode()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_decode.md),
  [`aurora_jwt_guard()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_guard.md),
  [`aurora_set_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md),
  [`aurora_clear_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md).
  The `auth` template gates `/api/*` with a `@header` guard and
  [`reqres::abort_unauthorized()`](https://reqres.data-imaginist.com/reference/abort_http_problem.html)
  (ADR-010).

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
  `api_logger(logger_otel())`, off by default (ADR-008).

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
