# inst/examples

Runnable aurora apps in the canonical layout (`api.R`, `build_ui.R`, `routers/`,
`helpers/`, `ui_modules/`, `www/js/{core.js,app.js}`). Run any with:

```r
aurora::aurora_run(system.file("examples/<name>", package = "aurora"))
```

- `01-hello` — minimal echo router + UI.
- `02-dashboard-echarts` — JSON router + ECharts in `app.js`.

Planned (dev/PLAN.md Phase 5): `03-leaflet-map`, `04-auth`.
