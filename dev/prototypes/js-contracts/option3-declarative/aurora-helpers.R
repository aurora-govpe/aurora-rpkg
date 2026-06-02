# OPTION 3 — Declarative bindings (BROAD). aurora owns a charting DSL: the R
# helper expresses the FULL ECharts option tree, with "$.field" markers meaning
# "bind this to that field of the JSON response". aurora serialises the spec and
# its runtime interprets it. The app author writes no JS — but aurora now owns
# (and must version/secure) a config language.

#' Declare an ECharts component fully from R.
#'
#' @param id,endpoint,height As in the other options.
#' @param x,y Response field names; emitted as `$.x` / `$.y` binding markers.
#' @param type ECharts series type.
#' @param tooltip Whether to add an axis tooltip.
aurora_echart_declarative <- function(id, endpoint, x, y,
                                      type = "bar", tooltip = TRUE,
                                      height = "360px") {
  option <- list(
    tooltip = if (tooltip) list(trigger = "axis") else NULL,
    xAxis   = list(type = "category", data = paste0("$.", x)),
    yAxis   = list(type = "value"),
    series  = list(list(type = type, data = paste0("$.", y)))
  )
  spec <- list(id = id, kind = "echart", endpoint = endpoint, option = option)
  htmltools::tagList(
    htmltools::tags$div(id = id, style = paste0("height:", height, ";")),
    htmltools::tags$script(htmltools::HTML(paste0(
      "aurora.declare(",
      jsonlite::toJSON(spec, auto_unbox = TRUE, null = "null"),
      ");"
    )))
  )
}
