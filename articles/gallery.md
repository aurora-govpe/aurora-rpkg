# Gallery

Worked example apps ship in the package under `inst/examples/`. Run any
of them by pointing
[`aurora_run()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_run.md)
at its directory:

``` r

library(aurora)
aurora_run(system.file("examples", "02-dashboard-echarts", package = "aurora"))
```

## 01-hello

The smallest possible app: a bslib card, one input, and an echo
endpoint. Shows the request/response loop and that query strings are
read from the `query` argument.

- Route: `GET /api/echo/say` (reads `query$msg`)
- UI → API: `aurora.json("api/echo/say?msg=...")` in `app.js`

## 02-dashboard-echarts

A bar chart fed by a JSON route — the canonical “dashboard” shape.

- Route: `GET /api/sales/data` → `{ categories, values }`
- UI → API: `aurora_component("api/sales/data", id = "chart")` in
  `build_ui.R`; `app.js` reads `data-endpoint`, fetches, and renders
  with [ECharts](https://echarts.apache.org/) (via CDN)

## 03-map

A MapLibre map driven by a GeoJSON route — the geospatial shape.

- Route: `GET /api/regions/geojson` returns an `sf` object via
  `#* @serializer geojson` (a valid `FeatureCollection`)
- UI → API:
  [`aurora_component()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_component.md)
  wires the map container; `app.js` initialises [MapLibre GL
  JS](https://maplibre.org/) (OpenStreetMap base, no API key) and adds
  the fetched GeoJSON as a source + layer

## The pattern they share

Static bslib UI (compiled at build time) + thin `window.aurora`
runtime + app-authored `app.js` that fetches from `/api/*` and renders
with the client library of your choice. No reactive server; scales like
an API.
