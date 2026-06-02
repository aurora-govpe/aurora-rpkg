#' Build the static UI for an aurora app
#'
#' Sources the app's `build_ui.R` (root), which must define a `build_ui()`
#' function returning an \pkg{htmltools} tag, and writes the rendered HTML to
#' `www/index.html` via [htmltools::save_html()]. Author the layout with
#' \pkg{bslib}; ship static HTML.
#'
#' @param dir App directory (canonical aurora layout).
#'
#' @return The output file path, invisibly.
#' @export
aurora_build_ui <- function(dir = ".") {
  cfg <- read_config(dir)
  build_file <- fs::path_abs(fs::path(dir, cfg$build_ui))
  output <- fs::path_abs(fs::path(dir, cfg$output))

  if (!fs::file_exists(build_file)) {
    cli::cli_abort("UI build file {.path {cfg$build_ui}} not found in {.path {dir}}.")
  }

  # Source in an isolated env, chdir so source('ui_modules/...') etc. resolve.
  env <- new.env(parent = globalenv())
  sys.source(build_file, envir = env, chdir = TRUE)

  if (!is.function(env$build_ui)) {
    cli::cli_abort(c(
      "{.path {cfg$build_ui}} must define a function {.fn build_ui}.",
      i = "It should return an {.pkg htmltools} tag (or tagList)."
    ))
  }

  # Run the build with the app dir as the working directory so bslib can
  # auto-discover `_brand.yml` (brand = TRUE) and any relative assets resolve.
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)

  ui <- env$build_ui()
  fs::dir_create(fs::path_dir(output))
  htmltools::save_html(ui, file = output)

  cli::cli_alert_success("Built UI {.path {cfg$output}}")
  invisible(output)
}
