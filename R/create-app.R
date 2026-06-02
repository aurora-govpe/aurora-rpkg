#' Scaffold a new aurora app
#'
#' Creates the canonical aurora layout from a bundled template: `api.R`,
#' `build_ui.R`, `helpers/`, `routers/`, `ui_modules/`, `www/` (with `style.css`
#' and `js/app.js`), `data/config.yml`, and `.dockerignore`. The JS runtime is
#' copied fresh into `www/js/core.js`. A first UI build is attempted so the app
#' is immediately runnable.
#'
#' @param path Directory to create. Must not exist or must be empty.
#' @param template Bundled template: `"minimal"` (bare app) or `"auth"`
#'   (JWT-cookie login gating `/api/*`). `"dashboard"` is planned.
#' @param engine Web engine. Only `"plumber2"` is supported.
#'
#' @return The app path, invisibly.
#' @export
aurora_create_app <- function(path,
                              template = c("minimal", "dashboard", "auth"),
                              engine = "plumber2") {
  template <- rlang::arg_match(template)
  if (!identical(engine, "plumber2")) {
    cli::cli_abort("aurora targets {.pkg plumber2} only; got engine {.val {engine}}.")
  }

  tmpl_dir <- system.file("templates", template, package = "aurora")
  if (!nzchar(tmpl_dir) || !fs::dir_exists(tmpl_dir)) {
    cli::cli_abort(c(
      "Template {.val {template}} is not available yet.",
      i = "Available templates: {.val minimal}, {.val auth}."
    ))
  }

  if (fs::dir_exists(path)) {
    if (length(fs::dir_ls(path)) > 0) {
      cli::cli_abort("Directory {.path {path}} already exists and is not empty.")
    }
    fs::dir_delete(path)
  }
  fs::dir_copy(tmpl_dir, path)

  # Inject the (always current) JS runtime as www/js/core.js.
  runtime <- system.file("runtime", "core.js", package = "aurora")
  fs::dir_create(fs::path(path, "www", "js"))
  fs::file_copy(runtime, fs::path(path, "www", "js", "core.js"), overwrite = TRUE)

  # Set the app name in the optional manifest (created if absent).
  man <- aurora_manifest_path(path)
  m <- if (fs::file_exists(man)) yaml::read_yaml(man) else list(engine = "plumber2")
  m$name <- fs::path_file(fs::path_abs(path))
  yaml::write_yaml(m, man)

  cli::cli_alert_success("Created aurora app {.pkg {m$name}} at {.path {path}}.")

  ok <- tryCatch({ aurora_build_ui(path); TRUE },
                 error = function(e) {
                   cli::cli_alert_warning("Skipped initial UI build: {conditionMessage(e)}")
                   FALSE
                 })

  cli::cli_h3("Next steps")
  cli::cli_ul(c(
    "Edit the UI in {.path build_ui.R} (+ {.path ui_modules/})",
    "Add helpers in {.path helpers/}",
    "Add API routes with {.run aurora::aurora_add_route()} (writes to {.path routers/})",
    "Run locally with {.run aurora::aurora_run()}"
  ))

  invisible(path)
}
