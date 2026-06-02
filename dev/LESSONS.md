# Lessons learned

Distilled from (a) reverse-engineering the reference app `app_aurora_novo`,
(b) researching plumber2, and (c) building this skeleton. Append new lessons as
you hit them.

## From the reference app (app_aurora_novo)

- **The core trick:** build a `bslib` UI (`page_navbar`, `nav_panel`, `card`,
  `value_box`...) and write it to disk with `htmltools::save_html()`. You get
  Bootstrap/bslib polish with zero reactive server. This is the whole value prop.
- **Stateless auth:** JWT signed with `jose`, delivered as an `HttpOnly` cookie,
  validated in a plumber filter on `^/api/`. Dev vs prod cookie flags differ
  (`Secure; SameSite=Strict` in prod, `SameSite=Lax` in dev). Passwords hashed
  with `sodium::password_store()` / `password_verify()`.
- **Hot-reload data:** a `carregar_bases()` function reads RDS into globals with
  `<<-`, and a filter compares `file.info(...)$mtime` to a stored timestamp to
  reload when an ETL rewrites the files. Generalise this as `aurora_data_store()`
  but avoid `<<-`/globals — prefer an environment handed to handlers.
- **Frontend is vanilla JS per feature:** `core.js` (auth/fetch boilerplate),
  then `iniciativas.js`, `receitas.js`, `relatorios.js`. Libraries via CDN:
  ECharts, DataTables, MapLibre, bootstrap-select. aurora ships only the `core`
  equivalent (`core.js`); feature JS stays in the app.
- **Serializer safety:** when emitting JSON from sf/data, guard against
  `jsonlite::unbox(NULL)` (it crashes plumber). Keep `safe_unbox`/`safe_geojson`
  helpers in mind for the data-store/serializer helpers later.
- **Dockerfile reality:** rocker base + a long apt list (gdal/geos/proj/sodium/
  cairo/fontconfig/udunits) + posit package manager binaries. The team builds and
  pushes `hugoavmedeiros/aurora_novo-api:latest`. `aurora_dockerfile()` should
  reproduce this but resolve sysdeps automatically.

## From plumber2 research (verify against installed version)

- plumber2 is a **rewrite on `fiery` + `routr`**, API-incompatible with plumber.
  Annotations are parsed by **roxygen2** (multi-line tags, first line = title).
- Key verbs: `api()` (create; takes files/dirs or a `_server.yml`),
  `api_parse(api, ...)` (add files), `api_assets(at, path)` (serve via a route),
  `api_statics(at, path, except=)` (serve directly, httpuv-level),
  `api_run()`, `api_add_route()`, `api_doc_add()/api_doc_setting()`.
- **Auth is native (≥0.2.0):** `api_auth_guard()` + the `fireproof` plugin
  (`guard_key(...)`). Prefer wrapping this over hand-rolling a JWT filter.
- **Server-side storage:** `api_datastore(storr::driver_environment())` via the
  `firesale` plugin (storr-backed; redis/LMDB/DBI backends). Relevant to the
  data-store work and to any per-app shared state.
- Defaults: `host="127.0.0.1"`, `port=8080`, `doc_type="rapidoc"`,
  `doc_path="__docs__"`. plumber2 also has a native `_server.yml`; our
  `_aurora.yml` sits ABOVE it (UI build + deploy + routes), and `aurora_app()`
  translates to `api()` calls rather than emitting `_server.yml`.

## From verifying the runtime against a live plumber2 (0.2.0)

- 🔴 **Query string does NOT bind to named handler args in plumber2** (it did in
  v1). Only path `<var>` params bind. Read query via the reserved `query` arg
  (`query$msg`); body via `body`; request/response via `request`/`response`
  (reqres objects), not `req`/`res`. The `@query` annotation is documentation
  only. This silently broke `01-hello` (now fixed). Full map in
  `dev/MIGRATION-V1-V2.md`.
- The 4 STATE.md "must verify" items all PASSED: route precedence (`/api/*` and
  `/health` beat the `/` catch-all), helper visibility via `sys.source` into
  `globalenv()`, `api_parse` piping, and bslib `lib/` served at `/`.
- Use `pa$test_request(fiery::fake_request(...))` for server-less integration
  tests. `fake_request(content=)` must be a character string — passing `NULL`
  errors; default to `""`.
- plumber2 does NOT auto-unbox length-1 vectors — `list(status="ok")`
  serializes as `{"status":["ok"]}`. The reference app's `jsonlite::unbox`
  guards still apply.

## From validating the alpine (r-minimal) Dockerfile flavor

- The curated Alpine `-t`/`-a` names are correct (all apk packages resolve). The
  plumber2 baseline needs, beyond TLS/curl/sodium/xml: `icu-dev` (stringi via
  roxygen2), `zlib-dev`, `cmake` (nanonext), `libuv-dev` (fs), the graphics stack
  (fontconfig/freetype/harfbuzz/fribidi/cairo/png/tiff/jpeg), and — non-obvious —
  **`rust` + `cargo`**: `plumber2 -> routr -> waysign` is a Rust package, and with
  no CRAN binaries on Alpine it must compile (build-time only). On debian/PPM
  these all arrive as binaries, so the issue is Alpine-specific.
- `pak`'s `local::<tarball>` reader breaks on Alpine (busybox `tar`): "Line
  starting 'aurora/DESCRIPTION ...' is malformed". Affects LOCAL tarballs only;
  the published GitHub install path is unaffected. For local validation, install
  aurora via `install.packages(repos = NULL)` (R's own untar) after its deps.

## From validating a generated Dockerfile with a real `docker build`

- **PPM needs `HTTPUserAgent`, not just `repos`, to serve Linux binaries.**
  Setting `options(repos = PPM "__linux__/jammy")` alone still returns *source*
  packages — PPM only sends prebuilt binaries when the request's `HTTPUserAgent`
  identifies the R version + platform. Without it, the whole plumber2 tree
  compiles from source (slow) and fails where sysdeps are missing. Set BOTH in
  `Rprofile.site` so `install.packages` and pak's subprocess get binaries.
- 🔴 **PPM only ships amd64 (x86_64) Linux binaries — NOT arm64.** On Apple
  Silicon, a native `docker build` is arm64, so PPM serves source and everything
  compiles regardless of the `HTTPUserAgent` (the diagnostic showed
  `aarch64-...-linux-gnu` + `installing *source* package`). Build for the real
  production target with `docker build --platform linux/amd64` (emulated on a
  Mac) to get binaries — that's also what amd64 CI does natively. The generated
  Dockerfile is correct; only the build *platform* changes whether it compiles.
- **plumber2's dependency tree needs the graphics/text sysdeps** when built from
  source: `textshaping`/`systemfonts`/`ragg`/`svglite` (pulled via roxygen2)
  require `libharfbuzz-dev`, `libfribidi-dev`, `libfreetype6-dev`, `libpng-dev`,
  `libtiff5-dev`, `libjpeg-dev`. A failure there cascades to `reqres`/`routr`/
  `fiery`/`plumber2` "not available". Added these to `default_sysdeps`.
- **`brand.yml` won't be auto-detected.** `detect_packages()` scans for
  `library()`/`::`, but `bs_theme(brand = TRUE)` references no package — add
  `brand.yml` to the image when the app ships a `_brand.yml`.
- 🔴 **bslib's `page_*()` functions REQUIRE shiny.** `page_fillable`/`page_navbar`/
  etc. call `shiny::bootstrapPage()` / `getFromNamespace("p_randomInt","shiny")`
  unconditionally — building any aurora UI needs shiny installed. But aurora is
  stateless and ships no shiny. Resolution: the **container serves the prebuilt
  `www/index.html` and does NOT rebuild the UI** (`AURORA_REBUILD_UI=false`), so
  bslib/shiny/brand.yml are build-time-only (dev/CI), never installed in the
  runtime image. `aurora_dockerfile()` scans **runtime** deps only (routers/ +
  helpers/ + api.R), not `build_ui.R`/`ui_modules/`. Build the UI before the image.
- 🔴 **`fs`'s PPM binary links system `libuv` at runtime** — without `libuv1`
  (Debian) / `libuv` (Alpine) the container fails at startup with
  `unable to load ... fs.so: libuv.so.1: cannot open shared object file`. `fs` is
  a core aurora dependency, so this blocks EVERY image. Build-time `-dev` sysdeps
  don't cover it; added `libuv1-dev`/`libuv-dev` to the defaults. To find missing
  runtime libs fast, `ldd` every installed `*.so` in the built image and grep
  `not found` (ignore `libR.so` — a false positive when run outside R).
- A backgrounded `docker build ... &` inside a wrapper makes the wrapper exit 0
  immediately while docker keeps running detached — the "exit 0" is the wrapper's,
  not docker's. Run `docker build` as the foreground of the background task so its
  real exit code is reported.

## From getting R CMD check clean (Phase 6)

- `\uXXXX` escapes work in R **string literals** (ASCII source, correct runtime
  char) but NOT in roxygen `#'` text — they pass through to the generated `.Rd`
  as an unknown `\u` macro → `checking Rd files ... WARNING`. In roxygen/comments
  use plain ASCII (`--` for an em-dash); reserve `\uXXXX` for code strings.
- `::`-calls behind `rlang::check_installed()` (e.g. `nanoparquet::`) still count
  as a dependency to R CMD check — declare the package in Suggests or you get
  `'::' import not declared`. Same for packages used only in tests (`fiery::`).
- Don't commit example build artifacts: `aurora_build_ui()` writes `www/lib/`
  (bslib) with very long filenames → `non-portable file paths` NOTE. `.Rbuildignore`
  `inst/examples/*/www/lib` and `index.html` (they're regenerated by `aurora_run`).
- Template dotfiles (`.dockerignore`, `.gitkeep`) trip the `hidden files` NOTE;
  it's intentional and acceptable for shipped templates.

## From building aurora_data_store()

- `fs::path(".", "/abs/path")` does NOT collapse to the absolute path — it
  yields `"./abs/path"`, which then fails to resolve. To resolve a path that may
  be relative-or-absolute against a base, use `fs::path_abs(path, start = dir)`
  (absolute `path` is returned unchanged; relative is resolved against `start`).
- Data-path contract: relative dataset paths resolve against the **process
  working directory at read time**. The canonical deployment runs from the app
  dir (`Rscript api.R` / `aurora_run()` there), so `"data/x.rds"` works — same as
  the reference app's bare `readRDS("data/...")`. Pass an absolute `dir` if cwd
  can't be relied on. (Helpers are `sys.source`d with `chdir` to `helpers/`, so
  don't anchor data paths to the sourcing cwd.)

## From adopting brand.yml for theming (ADR-011)

- Theming is `_brand.yml` consumed by bslib via `bs_theme(version = 5, brand = TRUE)`;
  needs **bslib >= 0.9.0** and works best with **Bootstrap 5**. With `brand = TRUE`
  bslib errors if no `_brand.yml` is discoverable; the default `NULL` auto-discovers
  without erroring — the template ships `_brand.yml`, so `TRUE` is safe there.
- **Logos are NOT auto-applied** by bslib/Shiny UIs. Logo files go in `www/images/`
  and must be embedded manually in `build_ui.R` (`tags$img(src = "images/logo.png")`).
- 🔴 To verify: brand.yml may pull **web fonts / bundled CSS**. Confirm
  `htmltools::save_html()` emits those into `www/` so they resolve when served
  statically at `/` (same family of question as where `save_html()` puts `lib/`).

## From building the auth template (Phase 3)

- **`@header` + `@any /api/*` is the plumber2 way to gate a path** before the
  body arrives. The handler must return `plumber2::Next` to continue — and it
  must be NAMESPACED (`plumber2::Next`), because plumber2 isn't attached during
  aurora's assembly, so a bare `Next` in a parsed handler is "object not found"
  → 500. (The abort paths worked while only the valid path 500'd — a tell.)
- **fireproof guards require the `firesale` datastore plugin** (`api_datastore`
  + `storr`); without it `api_parse` of an `@authGuard` block aborts with "The
  fireproof plugin requires the following plugin: firesale". And `guard_key`
  returns `400`/`403`, not `401`. We went with a `@header` guard + jose +
  `reqres::abort_unauthorized()` instead (ADR-010) — clean 401, no datastore.
- **reqres `set_cookie(same_site=)` wants `"Lax"`/`"Strict"`/`"None"` (capitalised)**;
  lowercase errors → 500. `"None"` also requires `secure=TRUE`.
- **reqres stores cookies outside `$headers`** until serialisation. To read a
  cookie back from a bare `Response` in a test, use `res$as_list()$headers`
  (or `res$has_cookie(name)`), not `res$get_header("Set-Cookie")`. A response can
  carry MULTIPLE `set-cookie` headers (fiery's `fiery_id` + yours); `[["set-cookie"]]`
  returns only the first — filter `names(h) == "set-cookie"`.
- **Exported helpers must be `document()`-ed before `aurora::fn` works under
  `load_all`** — a router calling `aurora::aurora_jwt_guard` 500s with "not an
  exported object" until NAMESPACE is regenerated.

## From building the skeleton

- `htmltools::HTML()` effectively takes a single string — build multi-line JS
  with `paste(..., sep="\n")` then wrap once.
- Don't use `\\`+newline string continuation inside `cli` messages: it prints a
  literal backslash. Use one string, or split into two cli calls.
- `fs::dir_copy(src, dst)` nests `src` under `dst` when `dst` already exists.
  To copy CONTENTS to top level, ensure `dst` doesn't pre-exist.
- Shell brace expansion (`mkdir -p a/{b,c}`) is not portable across the sandbox
  shell — expand paths explicitly.
- Generate route files with `sprintf()`, not `glue()`: handler bodies contain
  `{ }` which fight glue's delimiters.

## From aligning to the team's canonical layout

- The reference app uses **convention, not a manifest**: fixed `routers/`,
  `ui_modules/`, `helpers/` dirs and root `api.R`/`build_ui.R`. aurora follows
  this (ADR-007). Don't reintroduce a required manifest.
- `build_ui.R` in the reference app was a *script* that built AND saved the HTML.
  We standardised it to **define `build_ui()`** (a function) so aurora controls
  the output path and it stays testable. Same filename, slightly stricter contract.
- JS split: **`core.js`** = basics/login (aurora-shipped, `window.aurora`);
  **`app.js`** = orchestrator (app-authored). Keep aurora's edits to `core.js`.
- Handlers in `routers/*.R` need helper functions: `sys.source()` `helpers/*.R`
  into the global env *before* `api_parse()`. The reference app leaned on globals
  (`<<-`); prefer sourcing into global at assembly over `<<-` inside helpers.
  A cleaner env-injection approach is in BACKLOG.
- Container entry is `Rscript api.R`, and `api.R` reads `AURORA_HOST`/
  `AURORA_PORT` from the environment (Dockerfile sets them) so local dev and the
  container share one assembly path.
