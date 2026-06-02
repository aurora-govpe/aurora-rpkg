# Build the static UI for an aurora app

Sources the app's `build_ui.R` (root), which must define a `build_ui()`
function returning an htmltools tag, and writes the rendered HTML to
`www/index.html` via
[`htmltools::save_html()`](https://rstudio.github.io/htmltools/reference/save_html.html).
Author the layout with bslib; ship static HTML.

## Usage

``` r
aurora_build_ui(dir = ".")
```

## Arguments

- dir:

  App directory (canonical aurora layout).

## Value

The output file path, invisibly.
