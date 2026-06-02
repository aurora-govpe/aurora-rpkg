# UI partials returning htmltools tags, sourced by build_ui.R when needed.
ui_sobre <- function() {
  htmltools::div(
    htmltools::h4("Sobre"),
    htmltools::p("Partial de exemplo. Importe em build_ui.R com source().")
  )
}
