# Build (and optionally push) a Docker image for an aurora app

Thin wrapper around the `docker` CLI. Requires a `Dockerfile` (see
[`aurora_dockerfile()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_dockerfile.md))
and a working Docker installation on `PATH`.

## Usage

``` r
aurora_build_image(
  dir = ".",
  tag,
  push = FALSE,
  dockerfile = "Dockerfile",
  platform = "linux/amd64"
)
```

## Arguments

- dir:

  App directory (build context).

- tag:

  Image tag, e.g. `"myorg/myapp:latest"`.

- push:

  Whether to `docker push` after a successful build.

- dockerfile:

  Path to the Dockerfile relative to `dir`.

- platform:

  Target platform passed to `docker build --platform`. Defaults to
  `"linux/amd64"` so images built on Apple Silicon run on the usual
  x86-64 servers. Use `NULL` to build for the host architecture.

## Value

The image `tag`, invisibly.
