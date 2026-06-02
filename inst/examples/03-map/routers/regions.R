# A GeoJSON API route. The handler returns an sf object and the `geojson`
# serializer emits a valid FeatureCollection (scalars correctly unboxed).
# app.js fetches this and adds it to a MapLibre map as a source + layer.

#* Regions as GeoJSON
#* @get /api/regions/geojson
#* @serializer geojson
function() {
  square <- function(x, y, s = 1) {
    sf::st_polygon(list(matrix(
      c(x, y,  x + s, y,  x + s, y + s,  x, y + s,  x, y),
      ncol = 2, byrow = TRUE
    )))
  }
  sf::st_sf(
    name  = c("Sertao", "Agreste", "Mata"),
    value = c(120, 200, 170),
    geometry = sf::st_sfc(
      square(-40.5, -8.5), square(-38.5, -8.2), square(-35.5, -8.0),
      crs = 4326
    )
  )
}
