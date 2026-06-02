#' Build (and optionally push) a Docker image for an aurora app
#'
#' Thin wrapper around the `docker` CLI. Requires a `Dockerfile` (see
#' [aurora_dockerfile()]) and a working Docker installation on `PATH`.
#'
#' @param dir App directory (build context).
#' @param tag Image tag, e.g. `"myorg/myapp:latest"`.
#' @param push Whether to `docker push` after a successful build.
#' @param dockerfile Path to the Dockerfile relative to `dir`.
#'
#' @return The image `tag`, invisibly.
#' @export
aurora_build_image <- function(dir = ".", tag, push = FALSE,
                               dockerfile = "Dockerfile") {
  if (Sys.which("docker") == "") {
    cli::cli_abort(c(
      "{.code docker} was not found on the {.envvar PATH}.",
      i = "Install Docker, or build the image on a machine that has it."
    ))
  }
  df <- fs::path(dir, dockerfile)
  if (!fs::file_exists(df)) {
    cli::cli_abort(c(
      "No {.path {dockerfile}} in {.path {dir}}.",
      i = "Generate one with {.fn aurora_dockerfile}."
    ))
  }

  cli::cli_alert_info("Building image {.val {tag}} ...")
  status <- system2("docker", c("build", "-f", shQuote(df), "-t", shQuote(tag), shQuote(dir)))
  if (!identical(status, 0L)) {
    cli::cli_abort("{.code docker build} failed (exit status {status}).")
  }
  cli::cli_alert_success("Built {.val {tag}}")

  if (isTRUE(push)) {
    cli::cli_alert_info("Pushing {.val {tag}} ...")
    pstatus <- system2("docker", c("push", shQuote(tag)))
    if (!identical(pstatus, 0L)) {
      cli::cli_abort("{.code docker push} failed (exit status {pstatus}).")
    }
    cli::cli_alert_success("Pushed {.val {tag}}")
  }

  invisible(tag)
}
