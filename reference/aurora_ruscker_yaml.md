# Emit a Ruscker app-spec block for an aurora image

Generates the YAML spec entry that goes under `proxy.specs` in a
[Ruscker](https://github.com/StrategicProjects/ruscker) configuration,
pointing at a built aurora image (see
[`aurora_build_image()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_image.md)).
Ruscker is a reverse proxy and container orchestrator (a lightweight
ShinyProxy alternative) that reads the ShinyProxy `application.yml`
schema and adds its own fields. An aurora app is a *stateless*
'plumber2' API, so this emits a `type: api` spec – Ruscker load-balances
a replica pool of the container instead of running one container per
session (contrast
[`aurora_shinyproxy_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_shinyproxy_yaml.md),
which emits the interactive Docker-backed spec).

## Usage

``` r
aurora_ruscker_yaml(
  image,
  dir = ".",
  id = NULL,
  display_name = NULL,
  description = NULL,
  port = 8000L,
  docs_path = "/__docs__",
  health_path = "/__healthz__",
  rate_limit = NULL,
  cors = NULL,
  min_replicas = 0L,
  max_replicas = 3L,
  env = NULL,
  wrap = FALSE,
  write = FALSE,
  file = NULL
)
```

## Arguments

- image:

  Container image tag, e.g. `"org/meu_app:latest"` (required).

- dir:

  App directory, used only to default `id`/`display_name` from the app
  name.

- id:

  Spec id. Defaults to the app name.

- display_name:

  Human-facing name. Defaults to the app name.

- description:

  Optional one-line description.

- port:

  Port the app listens on inside the container, emitted as `api.port`
  (the aurora default is `8000`).

- docs_path:

  OpenAPI/Swagger UI location, emitted as `api.docs-path`. Defaults to
  `"/__docs__"` (the 'plumber2'/aurora default).

- health_path:

  Readiness-check endpoint, emitted as `api.health-path`. Defaults to
  `"/__healthz__"`.

- rate_limit:

  Optional per-IP throttle, emitted as `api.rate-limit`, e.g.
  `"100/min"`. Omitted when `NULL`.

- cors:

  Optional logical; when not `NULL`, emitted as `api.cors` to toggle
  Ruscker's permissive CORS headers.

- min_replicas:

  Always-running instances, emitted as `min-replicas`. Defaults to `0`
  (spawn on demand).

- max_replicas:

  Auto-scale ceiling, emitted as `max-replicas`. Defaults to `3`.

- env:

  Optional named list/vector of `container-env` variables, e.g.
  `list(AURORA_ENV = "prod")`.

- wrap:

  If `TRUE`, wrap the entry under `proxy: specs:` so the output is a
  complete, paste-ready snippet. If `FALSE` (default), emit just the
  `- id: ...` list item to add under your existing `proxy.specs`.

- write:

  If `TRUE`, also write the YAML to `file`.

- file:

  Output path. Required when `write = TRUE` (there is no default path –
  pass an explicit location, e.g. one under
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)); `NULL`
  otherwise.

## Value

The YAML block as a single string, invisibly.

## See also

[`aurora_shinyproxy_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_shinyproxy_yaml.md)
for the interactive ShinyProxy spec.

## Examples

``` r
cat(aurora_ruscker_yaml(image = "org/meu_app:latest", id = "meu_app"))
#> ℹ Ruscker `type: api` spec for "meu_app" (image "org/meu_app:latest", port 8000)
#> - id: meu_app
#>   display-name: meu_app
#>   container-image: org/meu_app:latest
#>   type: api
#>   api:
#>     port: 8000
#>     docs-path: /__docs__
#>     health-path: /__healthz__
#>   min-replicas: 0
#>   max-replicas: 3
```
