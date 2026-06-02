# Convention-first app configuration --------------------------------------------
#
# The canonical aurora app layout is fixed by convention:
#   api.R            entry point
#   build_ui.R       defines build_ui()
#   helpers/         *.R sourced before routers are parsed
#   routers/         plumber2 annotated route files
#   ui_modules/      ui_*.R partials sourced by build_ui.R
#   www/             static assets (js/core.js = runtime, js/app.js = orchestrator)
#   data/config.yml  config (config package)
#
# An optional `_aurora.yml` overrides only a few keys (name, engine, auth).
# Convention is the source of truth; the manifest is not required.

# Fixed convention paths, relative to the app directory.
aurora_layout <- list(
  build_ui   = "build_ui.R",
  output     = "www/index.html",
  static     = "www",
  routers    = "routers",
  helpers    = "helpers",
  ui_modules = "ui_modules",
  runtime_js = "www/js/core.js",
  app_js     = "www/js/app.js",
  config     = "data/config.yml"
)

aurora_manifest_path <- function(dir = ".") {
  fs::path(dir, "_aurora.yml")
}

# Resolve the effective config for an app: convention defaults, optionally
# overridden by `_aurora.yml`. Returns a list including `dir`, `name`, `engine`.
read_config <- function(dir = ".") {
  assert_is_app(dir)
  cfg <- aurora_layout
  man <- aurora_manifest_path(dir)
  if (fs::file_exists(man)) {
    user <- yaml::read_yaml(man) %||% list()
    cfg <- utils::modifyList(cfg, user)
  }
  cfg$name <- cfg$name %||% fs::path_file(fs::path_abs(dir))
  cfg$engine <- cfg$engine %||% "plumber2"
  if (!identical(cfg$engine, "plumber2")) {
    cli::cli_abort(c(
      "Unsupported engine {.val {cfg$engine}}.",
      i = "aurora targets {.pkg plumber2} only."
    ))
  }
  cfg$dir <- dir
  cfg
}

# An app directory must look like one: at least a build_ui.R or a routers/ dir.
assert_is_app <- function(dir) {
  has_build <- fs::file_exists(fs::path(dir, aurora_layout$build_ui))
  has_routers <- fs::dir_exists(fs::path(dir, aurora_layout$routers))
  if (!has_build && !has_routers) {
    cli::cli_abort(c(
      "{.path {dir}} does not look like an aurora app.",
      i = "Expected {.file build_ui.R} or a {.path routers/} directory.",
      i = "Scaffold one with {.fn aurora_create_app}."
    ))
  }
  invisible(dir)
}

# Absolute paths to the router files, in parse (alphanumeric) order.
router_files <- function(cfg) {
  dir <- fs::path(cfg$dir, cfg$routers)
  if (!fs::dir_exists(dir)) return(character(0))
  sort(fs::dir_ls(dir, glob = "*.R", type = "file"))
}

# Absolute paths to helper files, sourced before routers are parsed.
helper_files <- function(cfg) {
  dir <- fs::path(cfg$dir, cfg$helpers)
  if (!fs::dir_exists(dir)) return(character(0))
  sort(fs::dir_ls(dir, glob = "*.R", type = "file"))
}

# Coerce a character/logical/NULL to a single logical (for env/manifest flags).
as_flag <- function(x, default = FALSE) {
  if (is.null(x)) return(default)
  if (is.logical(x)) return(isTRUE(x))
  isTRUE(tolower(as.character(x)) %in% c("true", "1", "yes", "on"))
}

# Resolve whether OpenTelemetry logging should be wired, by precedence:
# explicit `otel` arg > `_aurora.yml: otel:` > env `AURORA_OTEL` > FALSE.
# Turning this on wires `api_logger(logger_otel())`; actual span/metric export
# still depends on the `otel` package being enabled in the environment.
resolve_otel <- function(cfg, otel = NULL) {
  if (!is.null(otel)) return(as_flag(otel))
  if (!is.null(cfg$otel)) return(as_flag(cfg$otel))
  as_flag(Sys.getenv("AURORA_OTEL", ""), default = FALSE)
}
