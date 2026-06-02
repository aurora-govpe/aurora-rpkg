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
  cfg$name <- cfg$name %||% config_app_name(dir) %||% fs::path_file(fs::path_abs(dir))
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

# Best-effort read of `app_name` from data/config.yml (the config-package file)
# to use as the app name when `_aurora.yml` declares none -- removes the one
# field that otherwise duplicates between the two files. Returns NULL if absent.
config_app_name <- function(dir) {
  f <- fs::path(dir, aurora_layout$config)
  if (!fs::file_exists(f)) return(NULL)
  y <- tryCatch(yaml::read_yaml(f), error = function(e) NULL)
  if (is.null(y)) return(NULL)
  (y$default %||% list())$app_name %||% y$app_name
}

#' Read the app's `data/config.yml`, anchored to the app root
#'
#' Thin wrapper over [config::get()] that resolves `data/config.yml` relative to
#' the **app directory** (an absolute path), instead of the \pkg{config} package's
#' default search from the current working directory. This avoids the cwd pitfall
#' where a helper or handler is evaluated with a working directory other than the
#' app root and `config::get()` cannot find the file.
#'
#' `data/config.yml` (app runtime config: DB credentials, environment profiles,
#' service URLs) is intentionally separate from `_aurora.yml` (aurora wiring); see
#' the project decision records. This helper just makes reading it robust.
#'
#' @param value Config value to read; `NULL` (default) returns the whole active
#'   configuration as a list.
#' @param ... Passed to [config::get()].
#' @param dir App directory (used to locate `data/config.yml`).
#' @param file Explicit path to the config file; overrides `dir` when supplied.
#' @param config Active configuration name; defaults to the `R_CONFIG_ACTIVE`
#'   environment variable or `"default"`.
#'
#' @return The requested config value (or the whole config list).
#' @export
aurora_config <- function(value = NULL, ..., dir = ".", file = NULL,
                          config = Sys.getenv("R_CONFIG_ACTIVE", "default")) {
  rlang::check_installed("config", reason = "to read {.path data/config.yml}")
  f <- file %||% fs::path_abs(fs::path(dir, aurora_layout$config))
  if (!fs::file_exists(f)) {
    cli::cli_abort(c(
      "Config file {.path {f}} not found.",
      i = "aurora expects {.path data/config.yml}; pass {.arg dir} or {.arg file}."
    ))
  }
  config::get(value = value, ..., file = f, config = config, use_parent = FALSE)
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

# Re-raise an error from sourcing/parsing an app file with the offending file
# path and an actionable hint (notably for a missing R package), instead of the
# bare `loadNamespace(x): there is no package called 'config'` that R produces.
abort_app_file <- function(file, dir, e, what = "file", call = NULL) {
  rel <- tryCatch(fs::path_rel(file, dir), error = function(.) basename(file))
  msg <- conditionMessage(e)
  bullets <- c("aurora could not load {what} {.path {rel}}.", "x" = msg)
  # Match the package name between the quotes R uses in "there is no package
  # called 'x'" (straight or fancy quotes). The fancy quotes are written as
  # \u2018/\u2019 so the source stays ASCII (R CMD check flags non-ASCII string
  # literals as a WARNING).
  pkg <- regmatches(
    msg,
    regexpr("(?<=called [\u2018'\"`])[^\u2019'\"`]+", msg, perl = TRUE)
  )
  if (length(pkg) == 1L && nzchar(pkg)) {
    bullets <- c(bullets,
      "i" = "The R package {.pkg {pkg}} is not installed.",
      "i" = "Install the app's runtime dependencies (e.g. {.code install.packages(\"{pkg}\")}); see {.field packages} in {.file _aurora.yml}."
    )
  }
  cli::cli_abort(bullets, call = call)
}

# Resolve whether to attach the app's declared runtime packages before sourcing
# helpers, by precedence: explicit `attach` arg > `_aurora.yml: attach:` > env
# AURORA_ATTACH > FALSE. See ADR-012.
resolve_attach <- function(cfg, attach = NULL) {
  if (!is.null(attach)) return(isTRUE(attach))
  if (!is.null(cfg$attach)) return(as_flag(cfg$attach))
  as_flag(Sys.getenv("AURORA_ATTACH", ""), default = FALSE)
}

# Whether to emit verbose, per-step cli logs (e.g. one line per sourced helper /
# parsed router). Errors, warnings, and key successes always print regardless.
# Precedence: explicit `verbose` arg > option(aurora.verbose) > env
# AURORA_VERBOSE > FALSE (quiet -- a single assembly summary line).
aurora_is_verbose <- function(verbose = NULL) {
  if (!is.null(verbose)) return(isTRUE(verbose))
  opt <- getOption("aurora.verbose")
  if (!is.null(opt)) return(isTRUE(opt))
  as_flag(Sys.getenv("AURORA_VERBOSE", ""), default = FALSE)
}
