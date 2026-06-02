library(bslib)
library(htmltools)

build_ui <- function() {
  page <- page_fillable(
    theme = bs_theme(version = 5, preset = "flatly"),
    card(
      full_screen = TRUE,
      card_header("Vendas por mes"),
      # aurora_component() wires the element to its API endpoint via
      # data-endpoint; app.js reads it and renders. No rendering JS is shipped
      # by aurora (thin contract, ADR-009).
      card_body(aurora::aurora_component("api/sales/data", id = "chart",
                                         style = "height: 360px;"))
    )
  )
  tagList(
    page,
    tags$script(src = "https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"),
    tags$script(src = "js/core.js"),
    tags$script(src = "js/app.js")
  )
}
