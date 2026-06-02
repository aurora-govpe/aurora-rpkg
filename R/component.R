#' Wire a UI element to a JSON API endpoint
#'
#' A thin markup helper: emits an \pkg{htmltools} element carrying its API
#' endpoint as a `data-endpoint` attribute (plus any extra attributes you pass).
#' Your app's feature JavaScript reads `element.dataset.endpoint`, fetches it
#' with the `window.aurora` runtime (`aurora.json(...)`), and renders however it
#' likes.
#'
#' aurora deliberately ships no rendering JavaScript: this keeps the runtime thin
#' (see the design invariants in `CLAUDE.md` / ADR-002 and ADR-009) and leaves
#' charts, tables, and maps fully under the app's control. Use it to avoid
#' hand-writing the `data-*` plumbing on every element.
#'
#' @param endpoint API path the feature JS will fetch, e.g. `"api/sales/data"`.
#'   Resolved against the app base path by `aurora.url()` in the runtime.
#' @param ... Passed to the underlying \pkg{htmltools} tag. Named arguments
#'   become attributes (e.g. `class`, `style`, or extra `data-*` attributes such
#'   as `"data-page-size" = "25"`); unnamed arguments become child tags.
#' @param id Element id, so your JS can find it (`document.getElementById`).
#'   Optional but recommended.
#' @param tag HTML tag name to emit. Defaults to `"div"`.
#'
#' @return An \pkg{htmltools} tag.
#' @export
#' @examples
#' aurora_component("api/sales/data", id = "vendas", style = "height:360px;")
aurora_component <- function(endpoint, ..., id = NULL, tag = "div") {
  if (!is.character(endpoint) || length(endpoint) != 1L || !nzchar(endpoint)) {
    cli::cli_abort(c(
      "{.arg endpoint} must be a single non-empty string.",
      i = "It is the API path your feature JS will fetch, e.g. {.val api/sales/data}."
    ))
  }
  if (!is.character(tag) || length(tag) != 1L || !nzchar(tag)) {
    cli::cli_abort("{.arg tag} must be a single non-empty string (an HTML tag name).")
  }
  htmltools::tag(tag, c(list(id = id, `data-endpoint` = endpoint), list(...)))
}
