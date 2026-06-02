# Example 02 — dashboard with ECharts

The real pattern: an R router returns JSON (`GET /api/sales/data`); the app's
`app.js` renders an ECharts bar chart from it. aurora ships only `core.js`;
ECharts is a CDN script in `build_ui.R`.

```r
aurora::aurora_run(system.file("examples/02-dashboard-echarts", package = "aurora"))
```
