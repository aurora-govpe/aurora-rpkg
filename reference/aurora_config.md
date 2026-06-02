# Read the app's `data/config.yml`, anchored to the app root

Thin wrapper over
[`config::get()`](https://rstudio.github.io/config/reference/get.html)
that resolves `data/config.yml` relative to the **app directory** (an
absolute path), instead of the config package's default search from the
current working directory. This avoids the cwd pitfall where a helper or
handler is evaluated with a working directory other than the app root
and
[`config::get()`](https://rstudio.github.io/config/reference/get.html)
cannot find the file.

## Usage

``` r
aurora_config(
  value = NULL,
  ...,
  dir = ".",
  file = NULL,
  config = Sys.getenv("R_CONFIG_ACTIVE", "default")
)
```

## Arguments

- value:

  Config value to read; `NULL` (default) returns the whole active
  configuration as a list.

- ...:

  Passed to
  [`config::get()`](https://rstudio.github.io/config/reference/get.html).

- dir:

  App directory (used to locate `data/config.yml`).

- file:

  Explicit path to the config file; overrides `dir` when supplied.

- config:

  Active configuration name; defaults to the `R_CONFIG_ACTIVE`
  environment variable or `"default"`.

## Value

The requested config value (or the whole config list).

## Details

`data/config.yml` (app runtime config: DB credentials, environment
profiles, service URLs) is intentionally separate from `_aurora.yml`
(aurora wiring); see the project decision records. This helper just
makes reading it robust.
