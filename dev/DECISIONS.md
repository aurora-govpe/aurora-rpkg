# Architecture Decision Records (ADRs)

Lightweight log. Format: context → decision → consequences. Append, never edit
history; supersede with a new ADR if a decision changes.

## ADR-001 — Target plumber2 only
- Context: the reference app used plumber v1; plumber2 (CRAN, ≥0.2.0) is a
  rewrite on fiery/routr with native auth and roxygen2 annotations.
- Decision: aurora targets plumber2 exclusively. No v1 compatibility shim.
- Consequences: cleaner code; we rely on `api_*` verbs and native auth. Apps
  written for plumber v1 must be migrated (document this in the migration vignette).

## ADR-002 — Thin JS runtime (Option A)
- Context: hiding all JS (declarative R→JS bindings) would be a second framework
  inside the package and risks never shipping the MVP.
- Decision: ship only a thin runtime (`core.js`: credentialed `fetch` +
  `onUnauthorized`). Feature rendering (charts/tables/maps) stays in app JS.
- Consequences: developers write some JS; lower aurora maintenance surface.
  Declarative bindings remain a possible future (see BACKLOG), gated behind a new ADR.

## ADR-003 — Pluggable auth
- Context: not every app needs login; the reference app's JWT+Postgres scheme is
  one of many.
- Decision: auth is never in `aurora_app()`'s core path. `aurora_auth_jwt()` is
  one optional scheme; the `auth` template wires it. Apps without auth carry no
  `RPostgres`/`sodium` dependency.
- Consequences: core stays light; auth schemes are swappable and wrap plumber2's
  native guards.

## ADR-004 — `_aurora.yml` sits above plumber2's `_server.yml`
- Context: plumber2 has its own `_server.yml`. We need higher-level concepts
  (UI build step, deploy, route mounts).
- Decision: `_aurora.yml` is aurora's manifest. `aurora_app()` reads it and makes
  `api()` calls programmatically; it does not emit `_server.yml`.
- Consequences: one source of truth at the aurora layer; we can adopt
  `_server.yml` later for plumber2-native settings if needed.

## ADR-005 — Mount applied at scaffold time; no runtime path injection
- Context: in plumber2 a handler's URL comes from its own annotation. Injecting a
  prefix programmatically would mean relying on `api_parse`/`api_add_route`
  internals we are unsure about.
- Decision: `aurora_add_route()` writes the `mount` prefix directly into the
  generated `#* @get <mount>/...` annotation. `aurora_app()` does no injection.
- Consequences: robust and explicit; the route file is the truth. Renaming a
  mount means editing the annotation (or re-scaffolding).

## ADR-006 — UI is static HTML via save_html
- Context: the stateless model forbids a reactive server.
- Decision: `ui/ui.R` defines `build_ui()` returning an htmltools tag;
  `aurora_build_ui()` writes it with `htmltools::save_html()`.
- Consequences: no per-user R process; trivially cacheable/CDN-able UI;
  interactivity is the app JS calling `/api/*`.

## ADR-007 — Convention-first layout; manifest optional (supersedes ADR-004)
- Context: the team's real apps (app_aurora_novo) use a fixed-folder layout with
  hand-authored `api.R`/`build_ui.R` and NO manifest:
  `data/config.yml`, `helpers/`, `routers/`, `ui_modules/`, `www/js/{core.js,app.js}`,
  `.dockerignore`, `Dockerfile`, `api.R`, `build_ui.R`.
- Decision: aurora adopts this exact layout as its contract. Convention is the
  source of truth; `_aurora.yml` becomes OPTIONAL and only overrides `name`,
  `engine`, `auth`. `aurora_app()` parses all `routers/*.R`, sources all
  `helpers/*.R`, and serves `www/`. The root `api.R` is a thin shim that calls
  `aurora::aurora_run(".")` (host/port from env), used as the container CMD too.
- Consequences: reverses ADR-004 ("manifest is the source of truth"). Folder
  names are now fixed (`routers/` not `routes/`; `ui_modules/`; `helpers/`).
  `aurora_add_route()` no longer edits a manifest. ADR-005 (mount in annotation)
  still holds. ADR-002 split clarified: `core.js` = aurora runtime basics,
  `app.js` = app orchestrator.

## ADR-008 — Telemetry is opt-in, thin, native (OpenTelemetry)
- Context: the team wants telemetry integrated with plumber2. plumber2 already
  implements the HTTP OpenTelemetry semantic conventions automatically through
  reqres/fiery/routr: a request span (`request$otel`), per-route subspans, and
  the `http.server.*` metrics — no aurora code reimplements any of this.
- Decision: aurora's only job is **opt-in wiring + ergonomics**, mirroring the
  thin-runtime stance of ADR-002. `aurora_app(otel=)` / `aurora_run(otel=)` wire
  `api_logger(plumber2::logger_otel())` so logs join the spans/metrics. The flag
  resolves by precedence: explicit arg > `_aurora.yml: otel:` > env
  `AURORA_OTEL` > `FALSE`. Default OFF (zero overhead). aurora does NOT own
  exporter configuration — that stays in the `otel` package's environment setup
  (documented, not wrapped). Custom spans in handlers use
  `otel::start_local_active_span()` directly (documented pattern, not a wrapper)
  unless a future need justifies a thin helper.
- Consequences: telemetry is one flag; wiring is a safe no-op until the `otel`
  package is enabled, so it can be left on in production images. Scaffolded
  routes/helpers should log via `server$log(...)` (a reserved handler arg) rather
  than `cat()` so logs are otel-collectable.

## ADR-009 — JS integration is a thin R markup helper, no shipped renderer
- Context: Step 3a evaluated three contracts for wiring bslib UI to `/api/*`
  (prototypes in `dev/prototypes/js-contracts/`): (1) component helpers + a
  shipped hydration runtime, (2) a thin R helper that only emits `data-endpoint`
  with no shipped JS, (3) a declarative R→JS charting DSL.
- Decision: adopt **Option 2 (thin)**. aurora ships `aurora_component()` — an
  htmltools helper that emits an element carrying `data-endpoint` (+ any extra
  attributes). It ships NO rendering JavaScript; `core.js` is unchanged. The
  app's feature JS reads `element.dataset.endpoint`, fetches via
  `aurora.json()`, and renders.
- Consequences: fully honours ADR-002 (thin runtime) — aurora owns zero
  rendering/charting surface and no per-library DSL to maintain. Apps keep total
  control of (and responsibility for) their feature JS. Rejected Option 1
  (would add an optional renderer layer aurora must maintain + secure) and
  Option 3 (would make aurora a rendering framework, partially reversing
  ADR-002). If a higher-level layer is ever wanted, Option 1 remains reachable
  on top of this helper without reversing anything — it would need its own ADR.

## ADR-010 — JWT-cookie auth via a header-route guard + reqres abort (not fireproof)
- Context: Phase 3 needed to reproduce the reference app's stateless JWT-cookie
  auth on plumber2. Two native paths were prototyped: (a) a fireproof guard
  (`api_auth_guard` + `guard_key(cookie=TRUE, validate=)`), and (b) a `@header`
  route handler on `/api/*` that validates the cookie with \pkg{jose} and calls
  `reqres::abort_unauthorized()`.
- Decision: adopt (b). `aurora_auth_jwt()` returns a scheme object; companion
  helpers (`aurora_jwt_token`, `aurora_jwt_decode`, `aurora_jwt_guard`,
  `aurora_set_auth_cookie`, `aurora_clear_auth_cookie`) wrap jose + reqres. The
  `auth` template wires it entirely in annotated files: a `@header` `@any /api/*`
  guard + public `/auth/login`+`/auth/logout` routes. `aurora_app()` is never
  touched (ADR-003 honoured).
- Why not fireproof (a): (1) its guards target upstream IdPs / shared static keys
  / bearer headers, not self-issued cookie JWTs with signature+expiry checks;
  (2) it requires the `firesale` datastore plugin (`api_datastore` + `storr`),
  which would force a change to `aurora_app()`'s core path or an opt-in datastore
  just to support auth; (3) it returns `400`/`403` for missing/invalid keys,
  whereas the SPA login flow (and the reference app) need a clean, uniform `401`
  for both absent and expired sessions (cookie expiry manifests as "absent").
  Path (b) gives full status control, needs no datastore/fireproof/storr, is the
  migration-guide-endorsed replacement for v1 `@filter`, and stays stateless.
- Consequences: auth apps add only `jose` + `sodium`; non-auth apps add nothing.
  `aurora_auth_jwt()` graduated from an experimental spec stub to a working
  scheme. The `@header` guard must return `plumber2::Next` (it is namespaced
  because plumber2 is not attached during aurora's assembly).

## ADR-011 — Adopt brand.yml for theming (pairs with ADR-006)
(Numbered 011 because 008–010 were taken this session; the task brief referred to
it as "ADR-008" against an earlier state.)
- Context: aurora always uses bslib for the UI (ADR-006), and bslib >= 0.9.0
  consumes brand.yml (https://posit-dev.github.io/brand-yml/) natively.
- Decision: recognise `_brand.yml` by **convention**. The template uses
  `bs_theme(version = 5, brand = TRUE)` and ships a starter `_brand.yml`; bslib
  auto-discovers it and resolves the theme at **build time**, baking it into the
  static `index.html`. aurora builds **no** theming layer — same lean-on-the-
  ecosystem rationale as not shipping chart bindings (ADR-009). `_brand.yml` is
  orthogonal to `_aurora.yml`; **no `brand` key** is added to the manifest (rely
  on bslib auto-discovery; an explicit `bs_theme(brand = "path")` is only for a
  shared/remote brand file).
- Consequences: replaces bespoke per-app theme code (e.g. the reference app's
  `helpers/custom_theme.R`); org-wide consistency via one portable file that also
  themes Quarto. Caveats: requires bslib >= 0.9.0 and Bootstrap 5; **logos are
  manual** (files in `www/images/`, embedded in `build_ui.R`); verify font/CSS
  bundling via `save_html()` (see STATE, ties to the `lib/` question).
