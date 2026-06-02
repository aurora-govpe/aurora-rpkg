#' Run an aurora app locally
#'
#' Rebuilds the UI (optional), assembles the [aurora_app()] from convention, and
#' starts the \pkg{plumber2} server. Development-time equivalent of
#' `shiny::runApp()`. The generated `api.R` calls this function, so local dev
#' and container entry share one assembly path.
#'
#' @param dir App directory (canonical aurora layout).
#' @param port Port to bind.
#' @param host Host/interface to bind.
#' @param rebuild_ui Whether to rebuild the static UI before running. `NULL`
#'   (default) resolves from the `AURORA_REBUILD_UI` environment variable
#'   (default `TRUE` locally). Containers set it to `FALSE`: the UI is compiled
#'   at build time and shipped as `www/index.html`, so the runtime image serves
#'   it without the UI build dependencies (bslib, and transitively shiny).
#' @param watch Live-reload for development. When `TRUE`, aurora polls the UI
#'   source files (`build_ui.R` and `ui_modules/`) and rebuilds the static
#'   `www/index.html` on change -- refresh the browser to see it. Changes to
#'   `routers/`/`helpers/` are detected but cannot be hot-swapped into a running
#'   server, so they log an advisory to restart. Requires the \pkg{later}
#'   package.
#' @param watch_interval Polling interval in seconds when `watch = TRUE`.
#' @param otel Enable OpenTelemetry logging. Passed to [aurora_app()]; `NULL`
#'   (default) resolves from `_aurora.yml` then the `AURORA_OTEL` env var.
#' @param verbose Per-step \pkg{cli} logging. Passed to [aurora_app()]; `NULL`
#'   (default) resolves from `options(aurora.verbose)` then `AURORA_VERBOSE`.
#' @param attach Attach the `_aurora.yml` `packages:` before sourcing helpers.
#'   Passed to [aurora_app()]; `NULL` (default) resolves from `_aurora.yml`
#'   (`attach:`) then `AURORA_ATTACH`. See ADR-012.
#' @param on_exit Optional cleanup function `function()` run when the server
#'   stops (registered on plumber2's `"cleanup"` lifecycle event). Use it to
#'   release resources opened in a helper -- e.g. `pool::poolClose(con_base)` --
#'   replacing the v1 `pr_hook("exit", ...)`. Errors in the handler are reported
#'   but do not block shutdown.
#'
#' @return The result of [plumber2::api_run()], invisibly.
#' @export
aurora_run <- function(dir = ".", port = 8000L, host = "127.0.0.1",
                       rebuild_ui = NULL, watch = FALSE, watch_interval = 1,
                       otel = NULL, verbose = NULL, attach = NULL,
                       on_exit = NULL) {
  if (is.null(rebuild_ui)) {
    rebuild_ui <- as_flag(Sys.getenv("AURORA_REBUILD_UI", "true"), default = TRUE)
  }
  app <- aurora_app(dir, rebuild_ui = rebuild_ui, host = host, port = port,
                    otel = otel, verbose = verbose, attach = attach)

  if (!is.null(on_exit)) {
    if (!is.function(on_exit)) {
      cli::cli_abort("{.arg on_exit} must be a function (called when the server stops).")
    }
    # plumber2/fiery fires "end" when the server stops; "cleanup" is registered
    # too as a fallback. A once-guard keeps on_exit from running twice if both
    # fire. (Verified: api_stop() triggers "end", not "cleanup".)
    done <- FALSE
    handler <- function(...) {
      if (done) return(invisible(NULL))
      done <<- TRUE
      tryCatch(on_exit(), error = function(e) cli::cli_warn(c(
        "{.arg on_exit} handler failed during shutdown.",
        "x" = conditionMessage(e)
      )))
    }
    plumber2::api_on(app$api, "end", handler)
    plumber2::api_on(app$api, "cleanup", handler)
  }

  if (isTRUE(watch)) start_ui_watcher(app, interval = watch_interval)

  cli::cli_alert_success("Starting {.pkg {app$config$name}} on {.url http://{host}:{port}}")
  cli::cli_alert_info("API docs at {.url http://{host}:{port}/__docs__}")
  invisible(plumber2::api_run(app$api, host = host, port = as.integer(port)))
}
