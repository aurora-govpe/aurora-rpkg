library(bslib)
library(htmltools)

build_ui <- function() {
  page <- page_fillable(
    theme = bs_theme(version = 5, preset = "flatly"),
    card(
      card_header("aurora \u00b7 hello"),
      card_body(
        tags$input(id = "msg", class = "form-control mb-2", value = "ola mundo"),
        tags$button("Echo", id = "go", class = "btn btn-primary", onclick = "doEcho()"),
        tags$pre(id = "out", class = "mt-3 p-2 bg-light")
      )
    )
  )
  tagList(page, tags$script(src = "js/core.js"), tags$script(src = "js/app.js"))
}
