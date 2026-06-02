# Emit a ShinyProxy app-spec block for an aurora image

Generates the YAML spec entry that goes under `proxy.specs` in a
ShinyProxy configuration, pointing at a built aurora image (see
[`aurora_build_image()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_image.md)).
aurora apps are ordinary Docker-backed apps from ShinyProxy's point of
view: the spec just needs the image and the port the app listens on.

## Usage

``` r
aurora_shinyproxy_yaml(
  image,
  dir = ".",
  id = NULL,
  display_name = NULL,
  description = NULL,
  port = 8000L,
  env = NULL,
  wrap = FALSE,
  write = FALSE,
  file = "shinyproxy-app.yml"
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

  Port the app listens on inside the container (the aurora default is
  `8000`).

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

  Output path used when `write = TRUE`.

## Value

The YAML block as a single string, invisibly.

## Examples

``` r
cat(aurora_shinyproxy_yaml(image = "org/meu_app:latest", id = "meu_app"))
#> ℹ ShinyProxy spec for "meu_app" (image "org/meu_app:latest", port 8000)
#> - id: meu_app
#>   display-name: meu_app
#>   container-image: org/meu_app:latest
#>   port: 8000
```
