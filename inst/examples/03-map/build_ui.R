library(bslib)
library(htmltools)

build_ui <- function() {
  tagList(
    tags$head(
      tags$link(rel = "stylesheet",
                href = "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css"),
      tags$script(src = "https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js")
    ),
    page_fillable(
      theme = bs_theme(version = 5, preset = "flatly"),
      card(
        full_screen = TRUE,
        card_header("Regioes (GeoJSON via /api)"),
        # aurora_component wires the map container to its API endpoint;
        # app.js reads data-endpoint, fetches, and draws the layer.
        card_body(aurora::aurora_component("api/regions/geojson", id = "map",
                                           style = "height: 520px;"))
      )
    ),
    tags$script(src = "js/core.js"),
    tags$script(src = "js/app.js")
  )
}
