#' Emit a Ruscker app-spec block for an aurora image
#'
#' Generates the YAML spec entry that goes under `proxy.specs` in a
#' [Ruscker](https://github.com/StrategicProjects/ruscker) configuration,
#' pointing at a built aurora image (see [aurora_build_image()]). Ruscker is a
#' reverse proxy and container orchestrator (a lightweight ShinyProxy
#' alternative) that reads the ShinyProxy `application.yml` schema and adds its
#' own fields. An aurora app is a *stateless* 'plumber2' API, so this emits a
#' `type: api` spec -- Ruscker load-balances a replica pool of the container
#' instead of running one container per session (contrast
#' [aurora_shinyproxy_yaml()], which emits the interactive Docker-backed spec).
#'
#' @param image Container image tag, e.g. `"org/meu_app:latest"` (required).
#' @param dir App directory, used only to default `id`/`display_name` from the
#'   app name.
#' @param id Spec id. Defaults to the app name.
#' @param display_name Human-facing name. Defaults to the app name.
#' @param description Optional one-line description.
#' @param port Port the app listens on inside the container, emitted as
#'   `api.port` (the aurora default is `8000`).
#' @param docs_path OpenAPI/Swagger UI location, emitted as `api.docs-path`.
#'   Defaults to `"/__docs__"` (the 'plumber2'/aurora default).
#' @param health_path Readiness-check endpoint, emitted as `api.health-path`.
#'   Defaults to `"/__healthz__"`.
#' @param rate_limit Optional per-IP throttle, emitted as `api.rate-limit`,
#'   e.g. `"100/min"`. Omitted when `NULL`.
#' @param cors Optional logical; when not `NULL`, emitted as `api.cors` to toggle
#'   Ruscker's permissive CORS headers.
#' @param min_replicas Always-running instances, emitted as `min-replicas`.
#'   Defaults to `0` (spawn on demand).
#' @param max_replicas Auto-scale ceiling, emitted as `max-replicas`. Defaults
#'   to `3`.
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
#' @seealso [aurora_shinyproxy_yaml()] for the interactive ShinyProxy spec.
#' @export
#' @examples
#' cat(aurora_ruscker_yaml(image = "org/meu_app:latest", id = "meu_app"))
aurora_ruscker_yaml <- function(image,
                                dir = ".",
                                id = NULL,
                                display_name = NULL,
                                description = NULL,
                                port = 8000L,
                                docs_path = "/__docs__",
                                health_path = "/__healthz__",
                                rate_limit = NULL,
                                cors = NULL,
                                min_replicas = 0L,
                                max_replicas = 3L,
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
  if (!is.null(cors) && !(is.logical(cors) && length(cors) == 1L && !is.na(cors))) {
    cli::cli_abort("{.arg cors} must be a single {.code TRUE}/{.code FALSE} or {.code NULL}.")
  }
  min_replicas <- as.integer(min_replicas)
  max_replicas <- as.integer(max_replicas)
  if (anyNA(c(min_replicas, max_replicas)) || min_replicas < 0L || max_replicas < min_replicas) {
    cli::cli_abort(c(
      "{.arg min_replicas}/{.arg max_replicas} must be non-negative with {.arg max_replicas} >= {.arg min_replicas}.",
      i = "Got {.val {min_replicas}} and {.val {max_replicas}}."
    ))
  }
  name <- tryCatch(read_config(dir)$name, error = function(e) fs::path_file(fs::path_abs(dir)))
  id <- id %||% name
  display_name <- display_name %||% id

  api <- list(
    port           = as.integer(port),
    `docs-path`    = docs_path,
    `health-path`  = health_path,
    `rate-limit`   = rate_limit,
    cors           = cors
  )
  api <- api[!vapply(api, is.null, logical(1))]

  spec <- list(
    id                = id,
    `display-name`    = display_name,
    description       = description,
    `container-image` = image,
    type              = "api",
    api               = api,
    `min-replicas`    = min_replicas,
    `max-replicas`    = max_replicas
  )
  spec <- spec[!vapply(spec, is.null, logical(1))]
  if (length(env) > 0) spec[["container-env"]] <- as.list(env)

  obj <- if (isTRUE(wrap)) list(proxy = list(specs = list(spec))) else list(spec)
  yaml <- yaml::as.yaml(obj, indent = 2)

  if (isTRUE(write)) {
    if (is.null(file) || !is.character(file) || length(file) != 1L || !nzchar(file)) {
      cli::cli_abort(c(
        "{.arg file} must be an explicit output path when {.code write = TRUE}.",
        i = "There is no default path; pass e.g. {.code file = file.path(tempdir(), \"ruscker-app.yml\")}."
      ))
    }
    writeLines(yaml, file)
    cli::cli_alert_success("Wrote Ruscker spec to {.path {file}}")
  }
  cli::cli_alert_info("Ruscker {.code type: api} spec for {.val {id}} (image {.val {image}}, port {.val {port}})")

  invisible(yaml)
}
