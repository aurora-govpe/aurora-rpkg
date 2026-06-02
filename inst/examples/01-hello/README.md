# Example 01 — hello

Smallest aurora app: one router (`GET /api/echo/say?msg=`) + a UI that calls it
via `aurora.json()`. Canonical layout: `api.R`, `build_ui.R`, `routers/`, `www/js/`.

```r
aurora::aurora_run(system.file("examples/01-hello", package = "aurora"))
```
