# Architecture

## The pattern

```
BUILD TIME
  build_ui.R  ──build_ui()──►  aurora_build_ui()  ──►  www/index.html (+ lib/)

RUN TIME
  Browser ◄────────────────► plumber2 server (aurora_app)
  (www/js/core.js + app.js)     │
                                ├─ api_assets("/", www)   → serves the static UI
                                └─ routers/*.R (parsed)   → JSON  (/api/*, /health...)
                                        │
                                        ├─ helpers/*.R sourced first (utils, db...)
                                        ├─ data store (RDS/parquet, hot-reload)  [Phase 3]
                                        └─ Postgres (auth, logs)                 [Phase 3]
```

Why it competes with Shiny: **stateless**. No WebSocket, no per-user R process,
no sticky sessions. Scales horizontally behind a load balancer / ShinyProxy /
plain Docker. R only runs when a route is called.

## Canonical app layout (the contract)

```
<app>/
├── api.R            # entry point: aurora::aurora_run("."), host/port from env
├── build_ui.R       # defines build_ui() -> htmltools tag; sources ui_modules/
├── helpers/         # *.R sourced before routers are parsed
├── routers/         # plumber2 annotated handlers; URL = annotation path
├── ui_modules/      # ui_*.R partials
├── www/
│   ├── js/core.js   # aurora runtime (window.aurora: fetch + auth basics)
│   ├── js/app.js    # orchestrator (app-authored)
│   ├── style.css
│   └── images/
├── data/config.yml  # config (config package)
├── _brand.yml       # optional: visual brand (color/type/logo), consumed by bslib
├── .dockerignore
└── Dockerfile       # generated
```

`_aurora.yml` is optional (overrides `name`/`engine`/`auth` only). Convention is
the source of truth (ADR-007).

## Theming (brand.yml)

Theming is a `_brand.yml` file (https://posit-dev.github.io/brand-yml/) consumed
natively by bslib via `bs_theme(version = 5, brand = TRUE)`. bslib auto-discovers
`_brand.yml` in the app dir (or `_brand/`, `brand/`, parent dirs) at **build
time** and bakes the theme into `www/index.html` — no runtime cost, consistent
with the static UI model (ADR-006). aurora builds no theming layer; it only
recognises the file by convention (ADR-011).

`_brand.yml` is **orthogonal** to `_aurora.yml`: brand = visual identity
(color/type/logo); `_aurora.yml` = app wiring (name/engine/auth). There is no
`brand` key in `_aurora.yml`. **Logos are not auto-applied** by bslib UIs — put
files in `www/images/` and embed them manually in `build_ui.R`
(e.g. `tags$img(src = "images/logo.png", height = 32)`).

## Request lifecycle (runtime)
1. Browser GETs `/` → plumber2 serves `www/index.html` (bslib-built UI).
2. The page loads `www/js/core.js` (runtime) then `www/js/app.js` (orchestrator).
3. `app.js` calls `aurora.json('api/...')` (credentialed fetch from core.js).
4. plumber2 routes `/api/...` to the matching handler in `routers/` → JSON.
5. (Phase 3) An auth guard validates the cookie/JWT before `/api/*`.

## `aurora_app()` assembly order
1. `aurora_build_ui()` (optional) — sources `build_ui.R`, writes `www/index.html`.
2. `sys.source()` each `helpers/*.R` into the global env (so handlers see them).
3. `api(host, port)`.
4. for each `routers/*.R` (alphanumeric): `api_parse(pa, file)` — paths from annotations.
5. `api_assets(pa, "/", www)` — catch-all static, added AFTER routers.
6. (Phase 3) optional `api_auth_guard(...)` from the auth scheme.

See `dev/STATE.md` for ordering/sourcing caveats to verify on a live server.

## core.js vs app.js (mirrors app_aurora_novo)
- `core.js` = aurora-shipped basics: `window.aurora.fetch/json`, `onUnauthorized`,
  (Phase 3) login/logout/session-expiry. Updated by aurora; do not hand-edit in apps.
- `app.js` = app-authored orchestrator: wires the DOM, calls feature code, uses
  `window.aurora`. Per-feature JS (charts/tables/maps) sits alongside it.
