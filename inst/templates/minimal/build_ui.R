# Defines build_ui(), returning an htmltools tag. aurora_build_ui() sources this
# file, calls build_ui(), and writes www/index.html. Source ui_modules/ here as
# needed (e.g. source("ui_modules/ui_sobre.R")).

library(bslib)
library(htmltools)

build_ui <- function() {
  # Theming comes from _brand.yml (brand = TRUE), auto-discovered by bslib at
  # build time. Logos are NOT auto-applied: put files in www/images/ and embed
  # them here manually, e.g. tags$img(src = "images/logo.png", height = 32).
  #
  # Note: use page_fillable / page_sidebar / page_fluid for stateless apps.
  # bslib's page_navbar()/nav_panel() require the shiny package, which an aurora
  # app does not install (it is stateless). Build a navbar with plain tags if you
  # need one.
  page <- page_fillable(
    title = "aurora \u00b7 minimal",
    theme = bs_theme(version = 5, brand = TRUE),
    card(
      card_header("Bem-vindo ao aurora"),
      card_body(
        p("UI est\u00e1tica (bslib) servida pelo plumber2, sem servidor reativo."),
        p(class = "text-muted", id = "health", "verificando /health ...")
      )
    )
  )

  tagList(
    page,
    tags$link(rel = "stylesheet", href = "style.css"),
    tags$script(src = "js/core.js"),   # aurora runtime (basics: fetch, auth)
    tags$script(src = "js/app.js")     # app orchestrator
  )
}
