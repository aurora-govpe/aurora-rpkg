# OPTION 1 — Component helpers (MEDIUM). What aurora WOULD ship (R side).
# aurora owns a small set of renderers; the R helper emits a div + data-*.
# The app author writes NO JavaScript for the common case.

#' Emit an ECharts component bound to a JSON endpoint.
#'
#' @param id Element id (also the JS handle).
#' @param endpoint API path returning `{ <x>: [...], <y>: [...] }`.
#' @param x,y Names of the response fields for the category axis / series.
#' @param type Chart type handled by the shipped renderer.
#' @param height CSS height.
#' @param ... Extra attributes passed through to the `<div>`.
aurora_echart <- function(id, endpoint, x, y,
                          type = c("bar", "line"),
                          height = "360px", ...) {
  type <- match.arg(type)
  htmltools::tags$div(
    id = id,
    class = "aurora-component",
    `data-aurora`   = "echart",
    `data-endpoint` = endpoint,
    `data-x`        = x,
    `data-y`        = y,
    `data-type`     = type,
    style = paste0("height:", height, ";"),
    ...
  )
}

#' Emit a DataTables table bound to a JSON endpoint (same idea, different kind).
aurora_table <- function(id, endpoint, ...) {
  htmltools::tags$table(
    id = id,
    class = "aurora-component table table-striped",
    `data-aurora`   = "table",
    `data-endpoint` = endpoint,
    ...
  )
}
