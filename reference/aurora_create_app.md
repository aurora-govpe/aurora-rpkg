# Scaffold a new aurora app

Creates the canonical aurora layout from a bundled template: `api.R`,
`build_ui.R`, `helpers/`, `routers/`, `ui_modules/`, `www/` (with
`style.css` and `js/app.js`), `data/config.yml`, and `.dockerignore`.
The JS runtime is copied fresh into `www/js/core.js`. A first UI build
is attempted so the app is immediately runnable.

## Usage

``` r
aurora_create_app(
  path,
  template = c("minimal", "dashboard", "auth"),
  engine = "plumber2"
)
```

## Arguments

- path:

  Directory to create. Must not exist or must be empty.

- template:

  Bundled template: `"minimal"` (bare app) or `"auth"` (JWT-cookie login
  gating `/api/*`). `"dashboard"` is planned.

- engine:

  Web engine. Only `"plumber2"` is supported.

## Value

The app path, invisibly.
