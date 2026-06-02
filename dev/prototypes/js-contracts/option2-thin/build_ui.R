# OPTION 2 — what the APP AUTHOR writes (R side).
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
          aurora_component("vendas", endpoint = "api/sales/data",
                           style = "height:360px;")
        )
      )
    ),
    tags$script(src = "https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"),
    tags$script(src = "js/core.js"),
    tags$script(src = "js/app.js")   # app-authored — see app.js
  )
}
