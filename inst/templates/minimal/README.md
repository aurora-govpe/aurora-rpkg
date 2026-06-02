# aurora app (minimal template)

Canonical layout: `api.R`, `build_ui.R`, `helpers/`, `routers/`, `ui_modules/`,
`www/js/{core.js,app.js}`, `data/config.yml`.

```r
aurora::aurora_run(".")     # serves the UI + /health at http://127.0.0.1:8000
```

- `build_ui.R` — defines `build_ui()`; edit your bslib layout (source `ui_modules/`).
- `routers/health.R` — example plumber2 route (`GET /health`).
- `helpers/` — functions sourced before routers (available to handlers).
- `www/js/core.js` — aurora runtime; `www/js/app.js` — your orchestrator.

Add a route:

```r
aurora::aurora_add_route("iniciativas")   # -> routers/iniciativas.R, /api/iniciativas/data
```
