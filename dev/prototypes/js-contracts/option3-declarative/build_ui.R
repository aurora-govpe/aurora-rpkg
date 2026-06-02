# OPTION 3 — what the APP AUTHOR writes. No feature JS; the chart config lives
# entirely in R and is interpreted by aurora's shipped runtime.
library(bslib)
library(htmltools)
source("aurora-helpers.R")  # in real life: provided by the aurora package

build_ui <- function() {
  tagList(
    page_fillable(
      theme = bs_theme(version = 5, preset = "flatly"),
      card(
        card_header("Vendas por mês"),
        card_body(
          aurora_echart_declarative("vendas", endpoint = "api/sales/data",
                                    x = "categories", y = "values", type = "bar")
        )
      )
    ),
    tags$script(src = "https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"),
    tags$script(src = "js/core.js"),
    tags$script(src = "js/aurora-declarative.js")   # shipped by aurora
  )
}
