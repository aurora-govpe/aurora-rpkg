# Migration map: plumber v1 → plumber2

Why this doc exists: the team's reference app (`app_aurora_novo`) is written in
**plumber v1**, but aurora targets **plumber2 only** (ADR-001). Porting a v1 app
(or authoring new aurora routes) is NOT a find-and-replace. This is the
idiom-by-idiom map, **validated empirically** against plumber2 0.2.0 / reqres
1.2.0 / routr 2.0.0 (see `dev/STATE.md` "Runtime verification"), and
cross-checked with plumber2's own `vignette("migration")`.

Doubles as the source for the future `migrating-from-shiny`/migration vignette.

## The five changes that actually bite

### 1. 🔴 Query params no longer bind to named handler args (VALIDATED)
In v1, a handler `function(msg = "")` received `?msg=` from the query string. In
**plumber2 this does not happen** — only **path parameters** (`<var>` in the
annotation) bind to named args. Query and body are separate reserved args.

```r
# v1 (BROKEN under plumber2 — msg is always "")
#* @get /api/echo
function(msg = "") list(echo = msg)

# plumber2 — read from the `query` arg
#* @get /api/echo
function(query) list(echo = query$msg %||% "")
```

The `@query msg` annotation is **documentation only** — it does NOT create the
binding (verified). This bit our own example `01-hello` (now fixed).

### 2. 🔴 `req` / `res` → reqres `request` / `response` (different objects + names)
plumber2 handler reserved argument names are **`request`, `response`, `query`,
`body`, `server`, `client_id`** — not `req`/`res`. The objects are reqres
classes with a different API. Full translation table below.

### 3. 🔴 No `@filter` / `preempt` / `forward()`
Removed entirely. Replacements:
- **Auth/early rejection** → a **header route** handler (runs before the body is
  even received) or `api_auth_guard()` (`fireproof`). Return `Break` to stop the
  chain and respond now; return `Next` (or anything that isn't `Break`) to
  continue. `plumber::forward()` is gone.
- **Body/query/cookie parsing** → automatic via reqres (no filter needed).
- **Error abort** → throw `reqres::abort_*()` (e.g. `abort_unauthorized()`,
  `abort_bad_request()`): stops handling, sets the response, logs it.

```r
# v1 auth filter
#* @filter protegerAPI
function(req, res) {
  if (grepl("^/api/", req$PATH_INFO)) {
    token <- get_token_from_cookie(req$HTTP_COOKIE)
    if (is.null(token)) { res$status <- 401; return(list(error="...")) }
  }
  plumber::forward()
}

# plumber2 — a guard, or a header-route handler that aborts early
#* @any /api/<path>
function(request) {
  token <- request$cookies$token
  if (is.null(token)) reqres::abort_unauthorized("Sessão ausente.")
  Next
}
```

### 4. `pr_*()` → `api_*()` (not 1:1)
`pr()`+`pr_mount()` → `api()` + `api_parse()`. `pr_static()` →
`api_assets()`/`api_statics()`. `pr_hook("exit", …)` → fiery lifecycle event
(`api_on()`). `pr_set_api_spec()` → `api_doc_add()`/`api_doc_setting()`.
**aurora already does the `api()`/`api_parse()`/`api_assets()` part** in
`aurora_app()`; this is mostly relevant when reading the v1 reference app.

### 5. No mount-prefixing — path lives in the annotation (ADR-005)
v1: `pr_mount("/api/iniciativas", pr("routers/iniciativas.R"))` + handler
`#* @get /data` → URL `/api/iniciativas/data`. aurora bans runtime prefixing, so
the **annotation carries the full path**: `#* @get /api/iniciativas/data`.
Porting a mounted v1 router means rewriting each annotation to the full path.

## reqres translation table (handler authors)

| Need | plumber v1 | plumber2 / reqres (VALIDATED) |
|---|---|---|
| Path param | named arg matching `:var` | named arg matching `<var>` |
| Query value | named arg (e.g. `msg`) | `query$msg` (reserved arg `query`) |
| Parsed body | `req$body$x` | `body$x` (reserved arg `body`; needs `@parser json`/etc.) |
| Raw body | `req$postBody` | `request$body_raw` |
| Request method | `req$REQUEST_METHOD` | `request$method` |
| Request path | `req$PATH_INFO` | `request$path` |
| Full URL | — | `request$url` |
| A request header | `req$HTTP_X_FOO` | `request$get_header("X-Foo")` (or `request$headers$x_foo`) |
| All cookies | parse `req$HTTP_COOKIE` by hand | `request$cookies$name` (auto-parsed, URL-decoded) |
| Encrypted session | plumber session | `request$session` (set via `api_session_cookie()`) |
| Set status | `res$status <- 401` | `response$status <- 401L` |
| Set header | `res$setHeader(n, v)` | `response$set_header(n, v)` |
| Set cookie | `res$setCookie(...)` / manual `Set-Cookie` | `response$set_cookie(name, value, http_only=, secure=, same_site=, max_age=, path=, expires=, encode=)` |
| Clear cookie | manual `Max-Age=0` | `response$clear_cookie(name)` |
| Abort with code | `res$status <- n; return(list(error=))` | `reqres::abort_unauthorized()` / `abort_bad_request()` / `abort_http_problem()` |
| Continue chain | `plumber::forward()` | return `Next` (or any non-`Break` value) |
| Stop chain now | `return(...)` | return `Break` |
| Logging | `cat()` | `server$log("message", ...)` (reserved arg `server`) |
| Server datastore | globals / `<<-` | `server` + `api_datastore()` |

Cookie note: `set_cookie()` uses `same_site = "strict"|"lax"|"none"`,
`http_only = TRUE`, `secure = TRUE` (the dev/prod flag split the reference app
did by hand with raw `Set-Cookie` strings).

## Serializer / unbox

plumber2 serializes via `@serializer json` (jsonlite). Length-1 vectors are
**not** auto-unboxed — a scalar still serializes as a 1-element array
(`{"status":["ok"]}`), exactly like v1. So the reference app's `jsonlite::unbox`
/ `safe_unbox` / `safe_geojson` guards remain relevant. Candidate for exported
helpers (`aurora_unbox`, `aurora_geojson`) — see BACKLOG.

## Testing without a server

`pa$test_request(fiery::fake_request(url, method=, content=, headers=))` runs a
request through the assembled API **without binding a port** — use it for fast,
deterministic integration tests (and it's how the runtime verification above was
done). `content` must be a character string (`""` default, not `NULL`).
