# Detect R package dependencies by scanning app source files.
# scope = "runtime" scans only what the SERVER needs (routers/, helpers/, api.R)
# — not build_ui.R / ui_modules/, which are UI build-time only (bslib etc.). The
# static UI is compiled before the image is built and shipped as www/index.html,
# so the runtime image needs no UI dependencies. scope = "all" scans everything.
detect_packages <- function(dir, scope = c("runtime", "all")) {
  scope <- match.arg(scope)
  src_dirs <- if (scope == "all") c("helpers", "routers", "ui_modules") else c("helpers", "routers")
  root_files <- if (scope == "all") c("build_ui.R", "api.R") else "api.R"
  files <- character(0)
  for (d in src_dirs) {
    dd <- fs::path(dir, d)
    if (fs::dir_exists(dd)) files <- c(files, fs::dir_ls(dd, recurse = TRUE, glob = "*.R", type = "file"))
  }
  for (f in root_files) {
    ff <- fs::path(dir, f)
    if (fs::file_exists(ff)) files <- c(files, ff)
  }
  if (length(files) == 0) return(character(0))
  txt <- unlist(lapply(files, readLines, warn = FALSE, encoding = "UTF-8"))
  lib <- regmatches(txt, regexpr("(?<=library\\()[A-Za-z0-9.]+", txt, perl = TRUE))
  ns  <- unlist(regmatches(txt, gregexpr("[A-Za-z0-9.]+(?=::)", txt, perl = TRUE)))
  pkgs <- unique(c(lib, ns))
  setdiff(pkgs, c("", "base", "stats", "utils", "methods", "aurora"))
}

# Conservative default Debian system deps, used when {pak} sysreqs resolution is
# unavailable. Covers TLS/curl/db/geo plus the graphics+text stack that plumber2's
# dependency tree (systemfonts/textshaping/ragg/svglite, via roxygen2) needs when
# any package is built from source.
default_sysdeps <- c(
  "libssl-dev", "libcurl4-openssl-dev", "libpq-dev", "libgdal-dev",
  "libgeos-dev", "libproj-dev", "libsodium-dev", "libudunits2-dev",
  "libfontconfig1-dev", "libcairo2-dev",
  "libharfbuzz-dev", "libfribidi-dev", "libfreetype6-dev",
  "libpng-dev", "libtiff5-dev", "libjpeg-dev",
  # libuv: the fs package's PPM binary links it at runtime (fs is a core aurora
  # dependency, so the container won't even start without it).
  "libuv1-dev"
)

# Posit Package Manager binary repo (jammy = the rocker/r-ver default base). Set
# it in Rprofile.site so EVERY R invocation — install.packages AND pak's
# subprocess — pulls prebuilt binaries instead of compiling from source.
# NOTE: PPM ships amd64 Linux binaries only; an arm64 build compiles from source.
ppm_jammy <- "https://packagemanager.posit.co/cran/__linux__/jammy/latest"

# Alpine (r-minimal) deps for the aurora baseline (plumber2 + bslib). r-minimal
# has no CRAN binaries — everything compiles — and omits the graphics stack, so
# these cover TLS/curl/sodium/xml + fonts/graphics. App-specific deps (e.g. geo)
# are added from `pkg_sysreqs(sysreqs_platform = "alpine")` or passed via `sysdeps`.
default_alpine_build <- c(
  "linux-headers", "cmake", "openssl-dev", "curl-dev", "libsodium-dev",
  "libxml2-dev", "icu-dev", "zlib-dev",
  "fontconfig-dev", "freetype-dev", "harfbuzz-dev", "fribidi-dev", "cairo-dev",
  "libpng-dev", "tiff-dev", "jpeg-dev", "libwebp-dev", "libuv-dev",
  # plumber2 -> routr -> waysign is a Rust package; Alpine has no CRAN binaries
  # so it must compile, which needs the Rust toolchain (build-time only).
  "rust", "cargo",
  # gfortran: r-minimal's build base has no Fortran compiler, but common CRAN
  # deps ship Fortran (e.g. KernSmooth, pulled by sf -> classInt). Build-time;
  # the compiled .so links libgfortran at runtime (see default_alpine_runtime).
  "gfortran"
)
default_alpine_runtime <- c(
  "libssl3", "libcurl", "libsodium", "libxml2", "icu-libs", "zlib",
  "fontconfig", "freetype", "harfbuzz", "fribidi", "cairo",
  # libwebpmux provides libwebpmux.so.3, which ragg (a plumber2 dep) links at
  # runtime; keep it in -a or installr's -t cleanup removes it and plumber2 won't load.
  "libpng", "tiff", "libjpeg-turbo", "libwebpmux", "libuv",
  # libgfortran: runtime lib for any package compiled with gfortran (KernSmooth,
  # etc.); without it the compiled .so fails to load after the -t cleanup.
  "libgfortran"
)

# Alpine system libraries required by SPECIFIC R packages when compiled from
# source. `pkg_sysreqs()` proved unreliable on this host (see dev/LESSONS.md), so
# the common heavy packages -- geospatial (sf/terra/...) and database drivers --
# are curated here. Keys are package names; values list the build (`-t`) and
# runtime (`-a`) Alpine packages. Matched against the app's runtime package set.
alpine_pkg_sysdeps <- list(
  sf          = list(build = c("gdal-dev", "geos-dev", "proj-dev", "sqlite-dev"),
                     runtime = c("gdal", "geos", "proj", "sqlite-libs")),
  terra       = list(build = c("gdal-dev", "geos-dev", "proj-dev", "sqlite-dev"),
                     runtime = c("gdal", "geos", "proj", "sqlite-libs")),
  lwgeom      = list(build = c("gdal-dev", "geos-dev", "proj-dev", "sqlite-dev"),
                     runtime = c("gdal", "geos", "proj", "sqlite-libs")),
  units       = list(build = "udunits-dev", runtime = "udunits"),
  RPostgres   = list(build = "postgresql-dev", runtime = "libpq"),
  RPostgreSQL = list(build = "postgresql-dev", runtime = "libpq"),
  RMariaDB    = list(build = "mariadb-dev", runtime = "mariadb-connector-c"),
  RMySQL      = list(build = "mariadb-dev", runtime = "mariadb-connector-c"),
  RSQLite     = list(build = "sqlite-dev", runtime = "sqlite-libs"),
  V8          = list(build = "v8-dev", runtime = "v8")
)

# Add package-specific Alpine libraries to a build/runtime dep set.
# `which` is "build" or "runtime".
augment_alpine_sysdeps <- function(deps, pkgs, which) {
  extra <- unlist(lapply(pkgs, function(p) alpine_pkg_sysdeps[[p]][[which]]))
  unique(c(deps, extra))
}

# --- Dockerfile bodies (one per flavor) ---------------------------------------

dockerfile_debian <- function(name, base, sysdeps, pkg_vec, port, aurora_source) {
  sys_lines <- paste0("    ", sysdeps, " \\", collapse = "\n")
  glue::glue(
    "# Generated by aurora::aurora_dockerfile() for app '{name}' (flavor: debian)",
    "# Serves the prebuilt static UI (www/index.html); does NOT rebuild it, so no",
    "# UI build deps (bslib/shiny) are installed. Build the UI before this image.",
    "FROM {base}",
    "",
    "ENV LANG=C.UTF-8 LC_ALL=C.UTF-8",
    "ENV AURORA_HOST=0.0.0.0 AURORA_PORT={port} AURORA_REBUILD_UI=false",
    "",
    "# Make Posit Package Manager serve Linux BINARIES to every R invocation",
    "# (install.packages and pak's subprocess) so nothing compiles from source.",
    "# The HTTPUserAgent header is what makes PPM return binaries, not source.",
    "RUN Rprofile=\"$(R RHOME)/etc/Rprofile.site\" \\",
    "    && echo 'options(repos = c(CRAN = \"{ppm_jammy}\"))' >> \"$Rprofile\" \\",
    "    && echo 'options(HTTPUserAgent = sprintf(\"R/%s R (%s)\", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> \"$Rprofile\"",
    "",
    "RUN apt-get update && apt-get install -y \\",
    "{sys_lines}",
    "    && rm -rf /var/lib/apt/lists/*",
    "",
    "RUN R -e \"install.packages(c({pkg_vec}))\"",
    "",
    "RUN R -e \"if (!requireNamespace('pak', quietly = TRUE)) install.packages('pak'); \\",
    "    pak::pak('{aurora_source}')\"",
    "",
    "WORKDIR /app",
    "COPY . /app",
    "",
    "EXPOSE {port}",
    "CMD [\"Rscript\", \"api.R\"]",
    "",
    .sep = "\n"
  )
}

dockerfile_alpine <- function(name, base, build_deps, runtime_deps, pkgs, port, aurora_source) {
  # installr (pak-based) compiles from source; -t adds build deps temporarily,
  # -a keeps runtime libs, -d adds compilers temporarily. Rcppcore/Rcpp is the
  # usual musl workaround the r-minimal examples apply.
  install_pkgs <- paste(c(pkgs, aurora_source, "Rcppcore/Rcpp"), collapse = " ")
  glue::glue(
    "# Generated by aurora::aurora_dockerfile() for app '{name}' (flavor: alpine)",
    "# r-minimal compiles all R packages from source (no CRAN binaries) for a tiny",
    "# final image. Builds are slower; tune the -t/-a system deps below as needed.",
    "# Serves the prebuilt static UI (www/index.html); does NOT rebuild it.",
    "FROM {base}",
    "",
    "ENV LANG=C.UTF-8 LC_ALL=C.UTF-8",
    "ENV AURORA_HOST=0.0.0.0 AURORA_PORT={port} AURORA_REBUILD_UI=false",
    "",
    "RUN installr -d \\",
    "    -t \"{paste(build_deps, collapse = ' ')}\" \\",
    "    -a \"{paste(runtime_deps, collapse = ' ')}\" \\",
    "    {install_pkgs}",
    "",
    "WORKDIR /app",
    "COPY . /app",
    "",
    "EXPOSE {port}",
    "CMD [\"Rscript\", \"api.R\"]",
    "",
    .sep = "\n"
  )
}

#' Generate a Dockerfile (and .dockerignore) for an aurora app
#'
#' Writes a Dockerfile that installs system deps, R packages (incl. \pkg{plumber2}
#' and \pkg{aurora}), copies the app, and runs `api.R`. The image suits plain
#' Docker or a ShinyProxy container. A `.dockerignore` is written if absent.
#'
#' Two flavors:
#' * `"debian"` (default) — `rocker/r-ver`; installs R packages as **binaries**
#'   from Posit Package Manager (fast builds; amd64). Best for heavy/geo apps and
#'   fast CI. Larger image.
#' * `"alpine"` — `rhub/r-minimal`; a tiny image (~25 MB base) that **compiles**
#'   every package from source via `installr` (no CRAN binaries; builds are
#'   slower). Best when image size matters or you need native arm64. Tune the
#'   Alpine build/runtime system deps via `sysdeps` if your packages need more.
#'
#' Runtime R packages are detected by scanning `routers/`, `helpers/`, and
#' `api.R`. To pin them explicitly (reproducible images), set a `packages:` list
#' in `_aurora.yml`; `plumber2` and `aurora` are always added.
#'
#' @param dir App directory.
#' @param flavor Base-image flavor: `"debian"` (rocker + PPM binaries) or
#'   `"alpine"` (r-minimal + source builds).
#' @param base Base Docker image. `NULL` (default) resolves per `flavor`:
#'   `rocker/r-ver:4.4.1` (debian) or `rhub/r-minimal` (alpine).
#' @param sysdeps `"auto"` uses a curated default set of system packages for the
#'   flavor (covers the plumber2 + bslib baseline plus common TLS/curl/db/geo/
#'   graphics needs); or pass a character vector to set them explicitly. For
#'   `"alpine"` this is the **build** (`-t`) set; runtime libs use a curated
#'   default. (`pkg_sysreqs()` auto-resolution proved unreliable, so aurora ships
#'   comprehensive defaults instead — extra `-dev` packages are build-time only.)
#' @param port Port exposed and bound (via the `AURORA_PORT` env var).
#' @param aurora_source pak/remotes spec used to install aurora in the image.
#'   Pin a tag or commit for reproducible builds (e.g.
#'   `"aurora-govpe/aurora-rpkg@v0.1.0"`): an unpinned moving ref (a branch)
#'   interacts badly with Docker's layer cache, which can silently keep an old
#'   commit on rebuild.
#' @param write Write the file (`TRUE`) or return its text (`FALSE`).
#'
#' @return The Dockerfile path (if written) or its contents, invisibly.
#' @export
aurora_dockerfile <- function(dir = ".",
                              flavor = c("debian", "alpine"),
                              base = NULL,
                              sysdeps = "auto",
                              port = 8000L,
                              aurora_source = "aurora-govpe/aurora-rpkg",
                              write = TRUE) {
  flavor <- rlang::arg_match(flavor)
  cfg <- read_config(dir)

  # Runtime deps only: the container serves the prebuilt static UI and does not
  # rebuild it, so UI build deps (bslib, brand.yml, transitively shiny) are not
  # installed — only what routers/helpers and plumber2 need at request time.
  # An explicit `packages:` list in _aurora.yml pins the runtime deps (instead of
  # scanning the source), for reproducible production images.
  runtime_pkgs <- if (length(cfg$packages) > 0) cfg$packages else detect_packages(dir, scope = "runtime")
  pkgs <- setdiff(unique(c("plumber2", runtime_pkgs)), "aurora")
  if (!fs::file_exists(fs::path(dir, "www", "index.html"))) {
    cli::cli_alert_warning(c(
      "No {.path www/index.html} found.",
      i = "Build the UI before the image: {.run aurora::aurora_build_ui()} (the container serves it, it does not rebuild)."
    ))
  }

  if (flavor == "debian") {
    base <- base %||% "rocker/r-ver:4.4.1"
    sysdeps <- if (identical(sysdeps, "auto")) default_sysdeps else sysdeps
    pkg_vec <- paste0("'", pkgs, "'", collapse = ", ")
    df <- dockerfile_debian(cfg$name, base, sysdeps, pkg_vec, port, aurora_source)
    n_sys <- length(sysdeps)
  } else {
    base <- base %||% "rhub/r-minimal"
    if (identical(sysdeps, "auto")) {
      # Curated base set + libraries required by specific packages (sf -> gdal/
      # geos/proj, RPostgres -> libpq, ...) so geospatial/DB apps build out of box.
      build_deps <- augment_alpine_sysdeps(default_alpine_build, pkgs, "build")
      runtime_deps <- augment_alpine_sysdeps(default_alpine_runtime, pkgs, "runtime")
    } else {
      build_deps <- sysdeps
      runtime_deps <- default_alpine_runtime
    }
    df <- dockerfile_alpine(cfg$name, base, build_deps, runtime_deps, pkgs, port, aurora_source)
    n_sys <- length(build_deps)
  }

  if (!isTRUE(write)) return(invisible(df))

  out <- fs::path(dir, "Dockerfile")
  writeLines(df, out)
  cli::cli_alert_success(
    "Wrote {.path Dockerfile} ({.val {flavor}}; {length(pkgs)} R package{?s}, {n_sys} system dep{?s})."
  )

  di <- fs::path(dir, ".dockerignore")
  if (!fs::file_exists(di)) {
    writeLines(c(
      ".Rproj.user", ".Rhistory", ".RData", "*.Rproj", "docs/", "dev/", ".git/",
      "# App data + config are mounted/injected at runtime, not baked into the",
      "# image -- keeps DB credentials and ETL data out of the layers.",
      "data/"
    ), di)
    cli::cli_alert_success("Wrote {.path .dockerignore}.")
    cli::cli_alert_info("{.path data/} is excluded -- mount it at runtime (e.g. {.code -v ./data:/app/data:ro}).")
  }

  # Reproducibility: a moving ref (a branch) interacts badly with Docker's layer
  # cache -- a rebuild reuses the cached install layer and silently keeps the old
  # commit. Nudge toward pinning a tag/commit.
  if (!grepl("@", aurora_source)) {
    cli::cli_alert_info(c(
      "aurora is installed from {.val {aurora_source}} (unpinned ref)."
    ))
    cli::cli_alert_info("For reproducible builds, pin a tag/commit: {.code aurora_source = \"{aurora_source}@<tag>\"}.")
  }

  invisible(out)
}
