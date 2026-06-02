# Run an aurora app locally

Rebuilds the UI (optional), assembles the
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
from convention, and starts the plumber2 server. Development-time
equivalent of `shiny::runApp()`. The generated `api.R` calls this
function, so local dev and container entry share one assembly path.

## Usage

``` r
aurora_run(
  dir = ".",
  port = 8000L,
  host = "127.0.0.1",
  rebuild_ui = NULL,
  watch = FALSE,
  watch_interval = 1,
  otel = NULL
)
```

## Arguments

- dir:

  App directory (canonical aurora layout).

- port:

  Port to bind.

- host:

  Host/interface to bind.

- rebuild_ui:

  Whether to rebuild the static UI before running. `NULL` (default)
  resolves from the `AURORA_REBUILD_UI` environment variable (default
  `TRUE` locally). Containers set it to `FALSE`: the UI is compiled at
  build time and shipped as `www/index.html`, so the runtime image
  serves it without the UI build dependencies (bslib, and transitively
  shiny).

- watch:

  Live-reload for development. When `TRUE`, aurora polls the UI source
  files (`build_ui.R` and `ui_modules/`) and rebuilds the static
  `www/index.html` on change – refresh the browser to see it. Changes to
  `routers/`/`helpers/` are detected but cannot be hot-swapped into a
  running server, so they log an advisory to restart. Requires the later
  package.

- watch_interval:

  Polling interval in seconds when `watch = TRUE`.

- otel:

  Enable OpenTelemetry logging. Passed to
  [`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md);
  `NULL` (default) resolves from `_aurora.yml` then the `AURORA_OTEL`
  env var.

## Value

The result of
[`plumber2::api_run()`](https://plumber2.posit.co/reference/api_run.html),
invisibly.
