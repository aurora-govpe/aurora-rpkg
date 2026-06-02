# OPTION 2 — Thin. The ONLY thing aurora ships (R side): a generic helper that
# emits an element carrying its endpoint as a data-attribute. aurora ships NO
# rendering JS; core.js stays exactly as it is today (just the fetch wrapper).

#' Emit a container element wired to a JSON endpoint.
#'
#' Pure markup convenience — the app's own feature JS reads `dataset.endpoint`
#' (and any extra data-* you pass) and renders however it likes.
#'
#' @param id Element id.
#' @param endpoint API path the feature JS will fetch.
#' @param ... Extra attributes (e.g. `style`, more `data-*`).
#' @param tag HTML tag to emit.
aurora_component <- function(id, endpoint, ..., tag = "div") {
  htmltools::tag(tag, c(list(id = id, `data-endpoint` = endpoint), list(...)))
}
