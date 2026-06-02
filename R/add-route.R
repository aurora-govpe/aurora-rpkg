#' Add an API route to an aurora app
#'
#' Generates an annotated \pkg{plumber2} route file under `routers/`. Because
#' `aurora_app()` parses every file in `routers/`, no manifest update is needed.
#' The handler's URL embeds the `mount` prefix directly in its annotation, so
#' there is no runtime path injection.
#'
#' @param name Route name; becomes `routers/<name>.R`.
#' @param mount URL prefix for the route. Defaults to `/api/<name>`.
#' @param dir App directory (canonical aurora layout).
#'
#' @return The created route file path, invisibly.
#' @export
aurora_add_route <- function(name, mount = NULL, dir = ".") {
  cfg <- read_config(dir)
  mount <- mount %||% paste0("/api/", name)

  routers_dir <- fs::path(dir, cfg$routers)
  fs::dir_create(routers_dir)
  file_abs <- fs::path(routers_dir, paste0(name, ".R"))
  if (fs::file_exists(file_abs)) {
    cli::cli_abort("Route file {.path {fs::path_rel(file_abs, dir)}} already exists.")
  }

  tmpl <- paste(
    "#* %s route",
    "#* @get %s/data",
    "#* @serializer json",
    "function() {",
    "  list(message = \"Hello from %s\")",
    "}",
    "",
    sep = "\n"
  )
  writeLines(sprintf(tmpl, name, mount, name), file_abs)

  cli::cli_alert_success(
    "Added router {.path {cfg$routers}/{name}.R} mounted at {.url {mount}/data}"
  )
  invisible(file_abs)
}
