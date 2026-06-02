/* app.js — MapLibre GL JS + a GeoJSON /api route.
 * Uses the thin aurora runtime: reads the endpoint from data-endpoint and
 * fetches with aurora.json(). Base map is OpenStreetMap raster tiles (no API
 * key needed). */
document.addEventListener("DOMContentLoaded", function () {
  var el = document.getElementById("map");

  var map = new maplibregl.Map({
    container: el,
    style: {
      version: 8,
      sources: {
        osm: {
          type: "raster",
          tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
          tileSize: 256,
          attribution: "© OpenStreetMap contributors"
        }
      },
      layers: [{ id: "osm", type: "raster", source: "osm" }]
    },
    center: [-38.0, -8.2],
    zoom: 6
  });

  map.on("load", function () {
    aurora.json(el.dataset.endpoint).then(function (geojson) {
      map.addSource("regions", { type: "geojson", data: geojson });
      map.addLayer({
        id: "regions-fill",
        type: "fill",
        source: "regions",
        paint: { "fill-color": "#2c3e50", "fill-opacity": 0.45 }
      });
      map.addLayer({
        id: "regions-line",
        type: "line",
        source: "regions",
        paint: { "line-color": "#2c3e50", "line-width": 1.5 }
      });
    });
  });
});
