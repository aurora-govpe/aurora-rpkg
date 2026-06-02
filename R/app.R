#' Assemble an aurora app as a plumber2 API
#'
#' Convention-based assembly: builds the UI (optional), sources `helpers/*.R`,
#' parses every `routers/*.R` into a \pkg{plumber2} API, and serves the `www/`
#' directory at `/`. No `_aurora.yml` is required; an optional manifest only
#' overrides a few keys.
#'
#' Each handler's URL is taken verbatim from its `#* @get /...` annotation, so
#' the route prefix is embedded by [aurora_add_route()] at scaffold time -- there
#' is no runtime path injection here.
#'
#' @param dir App directory (canonical aurora layout).
#' @param rebuild_ui Whether to rebuild the static UI before assembling.
#' @param host,port Bind address/port baked into the API object. Usually
#'   overridden by [aurora_run()].
#' @param otel Wire OpenTelemetry logging (`api_logger(logger_otel())`) so logs
#'   join \pkg{plumber2}'s automatic request spans and metrics. `NULL` (default)
#'   resolves from `_aurora.yml` (`otel:`) then the `AURORA_OTEL` environment
#'   variable, falling back to `FALSE`. Wiring is a no-op until the \pkg{otel}
#'   package is enabled in the environment, so it is safe to leave on.
#' @param verbose Emit a per-step \pkg{cli} log (one line per sourced helper /
#'   parsed router, otel wiring). `NULL` (default) resolves from
#'   `options(aurora.verbose)` then the `AURORA_VERBOSE` env var, falling back to
#'   `FALSE` (quiet: a single assembly-summary line). Errors and warnings always
#'   print.
#'
#' @return An object of class `aurora_app`.
#' @export
aurora_app <- function(dir = ".", rebuild_ui = TRUE,
                       host = "127.0.0.1", port = 8000L, otel = NULL,
                       verbose = NULL) {
  rlang::check_installed("plumber2", reason = "to assemble an aurora app")
  verbose <- aurora_is_verbose(verbose)
  cfg <- read_config(dir)

  if (isTRUE(rebuild_ui)) aurora_build_ui(dir)

  # Source helpers first so handlers in routers/ can call them. Run them with the
  # app directory as the working directory (NOT chdir into helpers/) so that
  # app-root-relative paths inside a helper -- e.g. config::get("data/config.yml")
  # or readRDS("data/x.rds") -- resolve exactly as they did under the v1
  # entrypoint, where the process cwd was the app root. (LESSONS: helpers are
  # app-root-relative, not helpers/-relative.)
  helpers <- helper_files(cfg)
  if (length(helpers) > 0) {
    owd <- getwd()
    on.exit(setwd(owd), add = TRUE)
    setwd(dir)
    for (f in helpers) {
      if (verbose) cli::cli_alert_info("Sourcing helper {.path {fs::path_rel(f, dir)}}")
      tryCatch(
        sys.source(f, envir = globalenv(), chdir = FALSE),
        error = function(e) abort_app_file(f, dir, e, what = "helper")
      )
    }
    setwd(owd)
  }

  static_dir <- fs::path(dir, cfg$static)
  if (!fs::dir_exists(static_dir)) {
    cli::cli_abort("Static directory {.path {cfg$static}} not found.")
  }

  pa <- plumber2::api(host = host, port = as.integer(port))

  # Routers first; assets are the catch-all and are added last.
  routers <- router_files(cfg)
  if (length(routers) == 0) {
    cli::cli_alert_warning("No router files found in {.path {cfg$routers}/}.")
  }
  for (f in routers) {
    if (verbose) cli::cli_alert_info("Parsing router {.path {fs::path_rel(f, dir)}}")
    pa <- tryCatch(
      plumber2::api_parse(pa, f),
      error = function(e) abort_app_file(f, dir, e, what = "router")
    )
  }

  pa <- plumber2::api_assets(pa, "/", static_dir)

  if (resolve_otel(cfg, otel)) {
    if (verbose) cli::cli_alert_info(
      "OpenTelemetry logging enabled ({.fn logger_otel}); export depends on the {.pkg otel} package being enabled."
    )
    pa <- plumber2::api_logger(pa, plumber2::logger_otel())
  }

  if (!is.null(cfg$auth)) {
    cli::cli_alert_warning(
      "Manifest declares {.field auth} but auth wiring is experimental and not applied yet. See {.fn aurora_auth_jwt}."
    )
  }

  # Quiet mode: one concise summary instead of the per-file lines above.
  if (!verbose) {
    cli::cli_alert_success(
      "Assembled {.pkg {cfg$name}}: {length(routers)} router{?s}, {length(helpers)} helper{?s}."
    )
  }

  structure(
    list(api = pa, config = cfg, dir = fs::path_abs(dir),
         host = host, port = as.integer(port)),
    class = "aurora_app"
  )
}

#' @export
print.aurora_app <- function(x, ...) {
  cfg <- x$config
  n_routers <- length(router_files(cfg))
  n_helpers <- length(helper_files(cfg))
  cli::cli_h2("aurora app: {cfg$name}")
  cli::cli_ul(c(
    "engine: {.pkg {cfg$engine}}",
    "dir: {.path {x$dir}}",
    "routers: {n_routers} | helpers: {n_helpers}",
    "static: {.path {cfg$static}}",
    "bind: {.url http://{x$host}:{x$port}}"
  ))
  invisible(x)
}
