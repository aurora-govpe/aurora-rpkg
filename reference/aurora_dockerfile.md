# Generate a Dockerfile (and .dockerignore) for an aurora app

Writes a Dockerfile that installs system deps, R packages (incl.
plumber2 and aurora), copies the app, and runs `api.R`. The image suits
plain Docker or a ShinyProxy container. A `.dockerignore` is written if
absent.

## Usage

``` r
aurora_dockerfile(
  dir = ".",
  flavor = c("debian", "alpine"),
  base = NULL,
  sysdeps = "auto",
  port = 8000L,
  aurora_source = "aurora-govpe/aurora-rpkg",
  write = TRUE
)
```

## Arguments

- dir:

  App directory.

- flavor:

  Base-image flavor: `"debian"` (rocker + PPM binaries) or `"alpine"`
  (r-minimal + source builds).

- base:

  Base Docker image. `NULL` (default) resolves per `flavor`:
  `rocker/r-ver:4.4.1` (debian) or `rhub/r-minimal` (alpine).

- sysdeps:

  `"auto"` uses a curated default set of system packages for the flavor
  (covers the plumber2 + bslib baseline plus common TLS/curl/db/geo/
  graphics needs); or pass a character vector to set them explicitly.
  For `"alpine"` this is the **build** (`-t`) set; runtime libs use a
  curated default. (`pkg_sysreqs()` auto-resolution proved unreliable,
  so aurora ships comprehensive defaults instead — extra `-dev` packages
  are build-time only.)

- port:

  Port exposed and bound (via the `AURORA_PORT` env var).

- aurora_source:

  pak/remotes spec used to install aurora in the image.

- write:

  Write the file (`TRUE`) or return its text (`FALSE`).

## Value

The Dockerfile path (if written) or its contents, invisibly.

## Details

Two flavors:

- `"debian"` (default) — `rocker/r-ver`; installs R packages as
  **binaries** from Posit Package Manager (fast builds; amd64). Best for
  heavy/geo apps and fast CI. Larger image.

- `"alpine"` — `rhub/r-minimal`; a tiny image (~25 MB base) that
  **compiles** every package from source via `installr` (no CRAN
  binaries; builds are slower). Best when image size matters or you need
  native arm64. Tune the Alpine build/runtime system deps via `sysdeps`
  if your packages need more.
