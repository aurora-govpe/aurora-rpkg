# Deploying aurora apps

Because an aurora app is stateless, deployment is the boring, scalable
kind: a container that serves static assets plus JSON routes. Run as
many replicas as you like behind a load balancer — there are no sticky
sessions to worry about.

## Build an image

The static UI is compiled at build time and shipped as `www/index.html`;
the container **serves** it and does not rebuild it, so the runtime
image installs no UI dependencies (bslib, and transitively shiny). Build
the UI before the image:

``` r

library(aurora)

aurora_build_ui("meu_app")   # compile www/index.html (needs bslib; run on dev/CI)

# Generate a Dockerfile (+ .dockerignore). It installs only the runtime deps
# your routers/helpers need, plus plumber2 and aurora.
aurora_dockerfile("meu_app")

# Build (and optionally push) the image using the docker CLI.
aurora_build_image("meu_app", tag = "org/meu_app:latest", push = TRUE)
```

The generated Dockerfile pulls R packages as prebuilt **binaries** from
Posit Package Manager, so builds are fast and need no compiler toolchain
at run time.

[`aurora_build_image()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_image.md)
targets **`linux/amd64` by default** (it passes `--platform linux/amd64`
to `docker build`). Production servers are almost always x86-64, and an
image built natively on an Apple Silicon machine is arm64 — it fails
there with `exec format error`. The default also matches Posit Package
Manager, which only serves amd64 Linux binaries. Building the amd64
image on an arm64 Mac works via emulation (enable Rosetta in Docker
Desktop); it is slower, but the image runs everywhere you deploy. To
build for the host architecture instead — e.g. deploying to an arm64
server — pass `platform = NULL`, or any explicit target like
`platform = "linux/arm64"`.

[`aurora_dockerfile()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_dockerfile.md)
writes a Dockerfile whose entry point is `Rscript api.R`, so the
container and local development share one assembly path. Key arguments:

- `flavor` — `"debian"` (default) or `"alpine"` (see below).
- `base` — base image; `NULL` resolves per flavor (`rocker/r-ver` /
  `rhub/r-minimal`).
- `sysdeps` — `"auto"` uses a curated default set covering the
  plumber2 + bslib baseline plus common TLS/curl/db/geo/graphics needs;
  pass a vector to override.
- `port` — exposed port (default `8000`).

### Choosing a flavor

|  | `debian` (default) | `alpine` |
|----|----|----|
| Base | `rocker/r-ver` | `rhub/r-minimal` |
| R packages | **binaries** from Posit Package Manager (fast) | **compiled** from source via `installr` (slower) |
| Image size | larger | tiny (~25 MB base) |
| Arch | amd64 binaries (arm64 compiles) | builds natively on amd64 **and** arm64 |
| Best for | heavy/geo apps, fast CI, broad compatibility | size-sensitive / edge deploys, simple deps |

``` r

aurora_dockerfile("meu_app", flavor = "alpine")
```

The `alpine` flavor compiles everything (no CRAN binaries on Alpine) and
uses `installr -d -t "<build deps>" -a "<runtime libs>"`. aurora ships
defaults that cover the plumber2 + bslib baseline; for extra system
libraries (e.g. GDAL/GEOS for `sf`) pass them via `sysdeps`. Note that
aurora’s baseline still pulls a non-trivial tree (httpuv, the fiery
stack, roxygen2, the graphics packages), so even a small app compiles a
fair amount on Alpine — the win is final image size.

## Publishing to a registry

`aurora_build_image(push = TRUE)` publishes after a successful build.
The **tag chooses the registry** — that is how Docker addresses images,
so no extra argument is needed:

``` r

# Docker Hub (the default registry)
aurora_build_image("meu_app", tag = "myorg/meu_app:latest", push = TRUE)

# GitHub Container Registry
aurora_build_image("meu_app", tag = "ghcr.io/myorg/meu_app:latest", push = TRUE)
```

Authenticate once with the docker CLI before pushing — aurora
deliberately does not wrap registry login (credential helpers and tokens
belong to the docker config, not to an R session):

``` sh
docker login                                  # Docker Hub
echo "$GITHUB_PAT" | docker login ghcr.io -u <user> --password-stdin
```

For a private app, create the repository as **private** on the registry
(on Docker Hub, free accounts default new repositories to public).

## Runtime configuration (environment variables)

The generated `api.R` reads its bind address and port from the
environment, and aurora features are env-toggleable, so the **same
image** runs in dev and prod:

| Variable | Used for |
|----|----|
| `AURORA_HOST` / `AURORA_PORT` | bind address / port (`api.R`) |
| `AURORA_OTEL` | enable OpenTelemetry logging ([`vignette("telemetry")`](https://aurora-govpe.github.io/aurora-rpkg/articles/telemetry.md)) |
| `AURORA_JWT_SECRET` | signing secret for the `auth` template |
| `AURORA_ENV=prod` | `Secure; SameSite=Strict` auth cookies (behind HTTPS) |

Never bake secrets into the image — inject them at run time:

``` sh
docker run -p 8000:8000 \
  -e AURORA_JWT_SECRET="$(openssl rand -hex 32)" \
  -e AURORA_ENV=prod \
  org/meu_app:latest
```

## Sharing assets across apps (`statics:`)

When several apps on a server share the same static files (a logo,
common JS libraries, a stylesheet), keep one copy in a server-side
directory, mount it as a read-only volume, and declare it in
`_aurora.yml` under `statics:` – a map of URL prefix to directory:

``` yaml
# _aurora.yml
statics:
  /assets: /srv/aurora-shared
```

[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
serves that directory at the prefix (in addition to `www/` at `/`), so
the app references the files by URL:

``` html
<img src="/assets/logo.png">
<script src="/assets/lib/echarts.min.js"></script>
```

``` sh
docker run -p 8000:8000 \
  -v ./data:/app/data:ro \
  -v /srv/aurora-shared:/srv/aurora-shared:ro \
  org/meu_app:latest
```

Update the shared directory once and every app picks it up. Relative
paths resolve against the app root; a missing directory (e.g. a volume
that was not mounted) is skipped with a warning so the app still starts.
The root path `/` is reserved for the app’s own `www/` – mount shared
files under a sub-path, or simply drop them in a sub-folder of `www/`
(also served, no config needed) if they don’t need to be shared across
apps.

## Behind a reverse proxy / load balancer

Serve the app under a path prefix or a subdomain via your proxy (nginx,
Traefik, an ingress). The runtime resolves API paths against the page’s
base path, so an app served under `/meu_app/` still calls its routes
correctly. Run multiple replicas freely — state lives in the client
(cookies) or an external store, not in the R process (see
[`vignette("aurora")`](https://aurora-govpe.github.io/aurora-rpkg/articles/aurora.md)
on
[`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md)).

## ShinyProxy

ShinyProxy launches the container like any Docker-backed app.
[`aurora_shinyproxy_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_shinyproxy_yaml.md)
emits the `proxy.specs` entry for you:

``` r

aurora_shinyproxy_yaml(
  image = "org/meu_app:latest",
  dir   = "meu_app",              # defaults id / display-name from the app name
  env   = list(AURORA_ENV = "prod")
)
#> - id: meu_app
#>   display-name: meu_app
#>   container-image: org/meu_app:latest
#>   port: 8000
#>   container-env:
#>     AURORA_ENV: prod
```

Paste that under `proxy.specs` in your ShinyProxy config, or pass
`wrap = TRUE` for a complete `proxy: specs:` snippet (and `write = TRUE`
to save it to a file).

## Ruscker

[Ruscker](https://github.com/StrategicProjects/ruscker) is a reverse
proxy and container orchestrator (a lightweight ShinyProxy alternative)
that reads the same `application.yml` schema and adds fields for
stateless APIs and replica pools. Because an aurora app *is* a stateless
‘plumber2’ API,
[`aurora_ruscker_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_ruscker_yaml.md)
emits a `type: api` spec: Ruscker load-balances a replica pool of the
container rather than running one container per session.

``` r

aurora_ruscker_yaml(
  image = "org/meu_app:latest",
  dir   = "meu_app",              # defaults id / display-name from the app name
  rate_limit = "100/min",         # optional proxy-side throttle
  cors  = TRUE,                   # optional permissive CORS headers
  env   = list(AURORA_ENV = "prod")
)
#> - id: meu_app
#>   display-name: meu_app
#>   container-image: org/meu_app:latest
#>   type: api
#>   api:
#>     port: 8000
#>     docs-path: /__docs__
#>     health-path: /__healthz__
#>     rate-limit: 100/min
#>     cors: yes
#>   min-replicas: 0
#>   max-replicas: 3
#>   container-env:
#>     AURORA_ENV: prod
```

`min_replicas` defaults to `0` (spawn on demand); raise it to keep
instances warm, and set `max_replicas` for the auto-scale ceiling. As
with ShinyProxy, `wrap = TRUE` emits a full `proxy: specs:` snippet and
`write = TRUE` saves it.

## Checklist

Strong `AURORA_JWT_SECRET` injected at run time (if using auth).

`AURORA_ENV=prod` and HTTPS terminated at the proxy.

Image rebuilt after dependency changes (sysdeps are resolved at build).

Health check wired to a public route (e.g. `/health`).
