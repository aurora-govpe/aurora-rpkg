# Add an API route to an aurora app

Generates an annotated plumber2 route file under `routers/`. Because
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
parses every file in `routers/`, no manifest update is needed. The
handler's URL embeds the `mount` prefix directly in its annotation, so
there is no runtime path injection.

## Usage

``` r
aurora_add_route(name, mount = NULL, dir = ".")
```

## Arguments

- name:

  Route name; becomes `routers/<name>.R`.

- mount:

  URL prefix for the route. Defaults to `/api/<name>`.

- dir:

  App directory (canonical aurora layout).

## Value

The created route file path, invisibly.
