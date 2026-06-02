# 03-map — MapLibre + a GeoJSON API route

Demonstrates aurora's pattern for maps: a static `bslib` UI loads
[MapLibre GL JS](https://maplibre.org/) (via CDN), and the app's `app.js`
fetches a GeoJSON `FeatureCollection` from a `/api` route and adds it as a map
source + layer. No reactive server, no API key (base map is OpenStreetMap
raster tiles).

## Run

```r
aurora::aurora_run("inst/examples/03-map")
```

## How it works

- `routers/regions.R` — `GET /api/regions/geojson` returns an `sf` object; the
  `#* @serializer geojson` emits a valid GeoJSON `FeatureCollection` (scalar
  fields are correctly unboxed, unlike the plain `json` serializer).
- `build_ui.R` — loads MapLibre GL JS and uses `aurora_component()` to emit the
  map container wired to the endpoint via `data-endpoint`.
- `www/js/app.js` — initialises the map, `aurora.json(el.dataset.endpoint)`,
  then `addSource`/`addLayer`.

Requires the `sf` package (for the GeoJSON route).

## Note on the `mapgl` R package

[`mapgl`](https://walker-data.com/mapgl/) wraps the same MapLibre GL JS for R,
but as an htmlwidget that **bakes the data in at build time**. That suits
R-driven maps, but aurora's model is a static shell + data fetched from `/api`
at runtime — so this example drives MapLibre GL JS directly. Use `mapgl` in
`build_ui.R` instead if you want a fully R-authored, build-time-baked map.
