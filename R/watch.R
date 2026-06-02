# Live-reload watcher for aurora_run(watch = TRUE) ------------------------------
#
# The aurora UI is static HTML, so "watch" means: poll the UI source files and
# rebuild www/index.html when they change (the developer then refreshes the
# browser). Routers/helpers cannot be hot-swapped into a running plumber2/fiery
# server, so a change there logs an advisory to restart rather than pretending
# to reload. Polling runs on the `later` event loop, which httpuv services
# inside `plumber2::api_run()`.

# UI source files whose change triggers a static rebuild.
ui_watch_files <- function(cfg, dir) {
  files <- fs::path(dir, cfg$build_ui)
  mods <- fs::path(dir, cfg$ui_modules)
  if (fs::dir_exists(mods)) {
    files <- c(files, fs::dir_ls(mods, glob = "*.R", type = "file"))
  }
  files[fs::file_exists(files)]
}

# Router + helper files: a change here needs a server restart (not hot-reloaded).
route_watch_files <- function(cfg) {
  c(router_files(cfg), helper_files(cfg))
}

# Named numeric snapshot of modification times (named by path). A changed set of
# files (added/removed) or any changed mtime makes the snapshot non-identical.
mtime_snapshot <- function(files) {
  if (length(files) == 0) return(stats::setNames(numeric(0), character(0)))
  stats::setNames(as.numeric(fs::file_info(files)$modification_time), files)
}

# One watch cycle: rebuild the UI if its sources changed; warn if routes did.
# Pure-ish (effects: UI rebuild + logging); returns the updated state list so the
# scheduler can carry it forward. Factored out so it is unit-testable without a
# running server.
watch_tick <- function(app, state) {
  cfg <- app$config
  dir <- app$dir

  cur_ui <- mtime_snapshot(ui_watch_files(cfg, dir))
  if (!identical(cur_ui, state$ui)) {
    state$ui <- cur_ui
    tryCatch({
      aurora_build_ui(dir)
      cli::cli_alert_success("watch: rebuilt UI \u2014 refresh the browser.")
    }, error = function(e) {
      cli::cli_alert_danger("watch: UI rebuild failed: {conditionMessage(e)}")
    })
  }

  cur_routes <- mtime_snapshot(route_watch_files(cfg))
  if (!identical(cur_routes, state$routes)) {
    state$routes <- cur_routes
    cli::cli_alert_warning(
      "watch: {.path routers/}/{.path helpers/} changed \u2014 restart {.fn aurora_run} to apply (routes are not hot-reloaded)."
    )
  }

  state
}

# Schedule the recurring watcher on the `later` loop. The first tick establishes
# baselines; subsequent ticks fire every `interval` seconds while the server runs.
start_ui_watcher <- function(app, interval = 1) {
  rlang::check_installed("later", reason = "for aurora_run(watch = TRUE)")
  cfg <- app$config
  dir <- app$dir

  state <- new.env(parent = emptyenv())
  state$value <- list(
    ui     = mtime_snapshot(ui_watch_files(cfg, dir)),
    routes = mtime_snapshot(route_watch_files(cfg))
  )

  poll <- function() {
    state$value <- watch_tick(app, state$value)
    later::later(poll, interval)
  }
  later::later(poll, interval)

  cli::cli_alert_info(
    "watch: rebuilding UI on changes to {.path {cfg$build_ui}} and {.path {cfg$ui_modules}/} (every {interval}s)."
  )
  invisible(state)
}
