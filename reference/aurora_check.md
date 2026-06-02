# Check an aurora app for common problems

Static "doctor" for the canonical layout. Reports issues that otherwise
surface late (often only when building or running the container):

## Usage

``` r
aurora_check(dir = ".")
```

## Arguments

- dir:

  App directory (canonical aurora layout).

## Value

Invisibly, a data frame of findings (`level`, `message`); also printed
via cli.

## Details

- **UI code in runtime helpers** – shiny/bslib/htmltools usage in
  `helpers/` (sourced at request time) pulls the UI stack into the
  runtime image. UI code belongs in `build_ui.R`/`ui_modules/` (build
  time).

- **Undeclared packages** – packages referenced in `routers/`/`helpers/`
  but absent from `_aurora.yml` `packages:` (when that list is present),
  so the image would miss them.

- **Missing prebuilt UI** – no `www/index.html` (the container serves it
  and does not rebuild).
