#' Emit a ShinyProxy app-spec block for an aurora image
#'
#' Generates the YAML spec entry that goes under `proxy.specs` in a ShinyProxy
#' configuration, pointing at a built aurora image (see [aurora_build_image()]).
#' aurora apps are ordinary Docker-backed apps from ShinyProxy's point of view:
#' the spec just needs the image and the port the app listens on.
#'
#' @param image Container image tag, e.g. `"org/meu_app:latest"` (required).
#' @param dir App directory, used only to default `id`/`display_name` from the
#'   app name.
#' @param id Spec id. Defaults to the app name.
#' @param display_name Human-facing name. Defaults to the app name.
#' @param description Optional one-line description.
#' @param port Port the app listens on inside the container (the aurora default
#'   is `8000`).
#' @param env Optional named list/vector of `container-env` variables, e.g.
#'   `list(AURORA_ENV = "prod")`.
#' @param wrap If `TRUE`, wrap the entry under `proxy: specs:` so the output is a
#'   complete, paste-ready snippet. If `FALSE` (default), emit just the
#'   `- id: ...` list item to add under your existing `proxy.specs`.
#' @param write If `TRUE`, also write the YAML to `file`.
#' @param file Output path. Required when `write = TRUE` (there is no default
#'   path -- pass an explicit location, e.g. one under [tempdir()]); `NULL`
#'   otherwise.
#'
#' @return The YAML block as a single string, invisibly.
#' @export
#' @examples
#' cat(aurora_shinyproxy_yaml(image = "org/meu_app:latest", id = "meu_app"))
aurora_shinyproxy_yaml <- function(image,
                                   dir = ".",
                                   id = NULL,
                                   display_name = NULL,
                                   description = NULL,
                                   port = 8000L,
                                   env = NULL,
                                   wrap = FALSE,
                                   write = FALSE,
                                   file = NULL) {
  if (missing(image) || !is.character(image) || length(image) != 1L || !nzchar(image)) {
    cli::cli_abort(c(
      "{.arg image} must be a single non-empty image tag.",
      i = "Build one with {.fn aurora_build_image}, e.g. {.val org/meu_app:latest}."
    ))
  }
  name <- tryCatch(read_config(dir)$name, error = function(e) fs::path_file(fs::path_abs(dir)))
  id <- id %||% name
  display_name <- display_name %||% id

  spec <- list(
    id               = id,
    `display-name`   = display_name,
    description      = description,
    `container-image` = image,
    port             = as.integer(port)
  )
  spec <- spec[!vapply(spec, is.null, logical(1))]
  if (length(env) > 0) spec[["container-env"]] <- as.list(env)

  obj <- if (isTRUE(wrap)) list(proxy = list(specs = list(spec))) else list(spec)
  yaml <- yaml::as.yaml(obj, indent = 2)

  if (isTRUE(write)) {
    if (is.null(file) || !is.character(file) || length(file) != 1L || !nzchar(file)) {
      cli::cli_abort(c(
        "{.arg file} must be an explicit output path when {.code write = TRUE}.",
        i = "There is no default path; pass e.g. {.code file = file.path(tempdir(), \"shinyproxy-app.yml\")}."
      ))
    }
    writeLines(yaml, file)
    cli::cli_alert_success("Wrote ShinyProxy spec to {.path {file}}")
  }
  cli::cli_alert_info("ShinyProxy spec for {.val {id}} (image {.val {image}}, port {.val {port}})")

  invisible(yaml)
}
