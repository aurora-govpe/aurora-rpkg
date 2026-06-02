# Assemble an aurora app as a plumber2 API

Convention-based assembly: builds the UI (optional), sources
`helpers/*.R`, parses every `routers/*.R` into a plumber2 API, and
serves the `www/` directory at `/`. No `_aurora.yml` is required; an
optional manifest only overrides a few keys.

## Usage

``` r
aurora_app(
  dir = ".",
  rebuild_ui = TRUE,
  host = "127.0.0.1",
  port = 8000L,
  otel = NULL,
  verbose = NULL,
  attach = NULL
)
```

## Arguments

- dir:

  App directory (canonical aurora layout).

- rebuild_ui:

  Whether to rebuild the static UI before assembling.

- host, port:

  Bind address/port baked into the API object. Usually overridden by
  [`aurora_run()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_run.md).

- otel:

  Wire OpenTelemetry logging (`api_logger(logger_otel())`) so logs join
  plumber2's automatic request spans and metrics. `NULL` (default)
  resolves from `_aurora.yml` (`otel:`) then the `AURORA_OTEL`
  environment variable, falling back to `FALSE`. Wiring is a no-op until
  the otel package is enabled in the environment, so it is safe to leave
  on.

- verbose:

  Emit a per-step cli log (one line per sourced helper / parsed router,
  otel wiring). `NULL` (default) resolves from `options(aurora.verbose)`
  then the `AURORA_VERBOSE` env var, falling back to `FALSE` (quiet: a
  single assembly-summary line). Errors and warnings always print.

- attach:

  Attach the runtime packages declared in `_aurora.yml` (`packages:`)
  before sourcing helpers, so helpers and handlers can use their
  functions unqualified (mirrors a plumber-v1
  [`library()`](https://rdrr.io/r/base/library.html) block). `NULL`
  (default) resolves from `_aurora.yml` (`attach:`) then
  `AURORA_ATTACH`, falling back to `FALSE`. Off by default to keep
  assembly thin; the `packages:` list is the runtime set (no
  `shiny`/`bslib`), so it is safe to enable. See ADR-012.

## Value

An object of class `aurora_app`.

## Details

Each handler's URL is taken verbatim from its `#* @get /...` annotation,
so the route prefix is embedded by
[`aurora_add_route()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_add_route.md)
at scaffold time – there is no runtime path injection here.
