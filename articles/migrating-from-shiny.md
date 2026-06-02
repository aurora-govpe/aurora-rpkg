# Migrating from Shiny (and plumber v1)

Two audiences land here: people coming from **Shiny** (reactive server)
and people porting a **plumber v1** API (aurora targets plumber2 only).
This covers both shifts.

## From Shiny: the mental-model shift

| Shiny | aurora |
|----|----|
| Reactive server holds state per user | Stateless: state lives in the client or an external store |
| `ui <- fluidPage(...)` | `build_ui()` returns an htmltools/bslib tag, compiled to static HTML |
| `server <- function(input, output) {...}` | `routers/*.R` — plumber2 handlers returning JSON |
| `reactive()` / `observe()` | JS `fetch` (`aurora.json(...)`) + DOM updates in `app.js` |
| `input$x` | request `query` / `body` / path params |
| `output$y <- render*()` | a JSON response a handler returns |
| `renderPlot`/`renderDT` widgets | client-side libraries (ECharts, MapLibre, DataTables) fed by `/api` |
| shinyapps.io / Connect, sticky sessions | Docker / ShinyProxy, horizontally scalable |

What you keep: the bslib UI transfers almost verbatim. What changes:
server logic becomes JSON endpoints, and you write some JavaScript to
render. What you gain: no per-user R process, trivial horizontal
scaling, CDN-cacheable UI.

A reactive value that recomputed when an input changed becomes: a DOM
event → `aurora.json("api/...")` → update the DOM. Read-only datasets
that you loaded once at app start map onto
[`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md)
(see
[`vignette("aurora")`](https://aurora-govpe.github.io/aurora-rpkg/articles/aurora.md)).

## From plumber v1: it is not a find-and-replace

plumber2 is API-incompatible with plumber. The five changes that
actually bite:

### 1. Query params no longer bind to named handler args

Only **path** parameters (`<var>` in the annotation) become named
arguments. Read the query string from the reserved `query` argument and
a parsed body from `body`.

``` r

# v1 (BROKEN under plumber2 — msg is always "")
#* @get /api/echo
function(msg = "") list(echo = msg)

# plumber2
#* @get /api/echo
function(query) list(echo = query$msg %||% "")
```

### 2. `req`/`res` become reqres `request`/`response`

The reserved handler arguments are `request`, `response`, `query`,
`body`, `server`, `client_id` — not `req`/`res`. Translation table:

| Need | plumber v1 | plumber2 / reqres |
|----|----|----|
| Path param | named arg (`:var`) | named arg (`<var>`) |
| Query value | named arg | `query$x` |
| Parsed body | `req$body$x` | `body$x` (needs `@parser json`) |
| Request method / path | `req$REQUEST_METHOD` / `req$PATH_INFO` | `request$method` / `request$path` |
| A request header | `req$HTTP_X_FOO` | `request$get_header("X-Foo")` |
| Cookies | parse `req$HTTP_COOKIE` by hand | `request$cookies$name` (auto-parsed) |
| Set status | `res$status <- 401` | `response$status <- 401L` |
| Set header | `res$setHeader(n, v)` | `response$set_header(n, v)` |
| Set / clear cookie | manual `Set-Cookie` | `response$set_cookie(...)` / `response$clear_cookie()` |
| Abort with a code | `res$status <- n; return(...)` | [`reqres::abort_unauthorized()`](https://reqres.data-imaginist.com/reference/abort_http_problem.html) / `abort_bad_request()` |
| Continue / stop chain | `forward()` / [`return()`](https://rdrr.io/r/base/function.html) | return [`plumber2::Next`](https://plumber2.posit.co/reference/Next.html) / [`plumber2::Break`](https://plumber2.posit.co/reference/Next.html) |
| Logging | [`cat()`](https://rdrr.io/r/base/cat.html) | `server$log("message", ...)` |

Note: reqres `set_cookie(same_site=)` wants `"Lax"`/`"Strict"`/`"None"`
(capitalised). length-1 vectors are **not** auto-unboxed by the `json`
serializer, so scalars serialize as 1-element arrays —
[`jsonlite::unbox()`](https://jeroen.r-universe.dev/jsonlite/reference/unbox.html)
them where a scalar is required (or use a dedicated serializer like
`geojson`).

### 3. No `@filter` / `preempt` / `forward()`

Removed. Use a route chain instead: a **header-route** handler
(`@header`) runs before the body and can reject early; return `Next` to
continue or `Break` to stop; throw `reqres::abort_*()` to fail with a
status. aurora’s `auth` template uses exactly this for its `/api/*`
guard (see
[`vignette("auth")`](https://aurora-govpe.github.io/aurora-rpkg/articles/auth.md)).

### 4. `pr_*()` → `api_*()` (not 1:1)

`pr()`/`pr_mount()` → `api()` + `api_parse()`; `pr_static()` →
`api_assets()`; `pr_hook("exit", ...)` → `api_on("end", ...)`. aurora
already does this assembly for you in
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md).

### 5. No mount-prefixing — the path lives in the annotation

v1 mounted a router under a prefix; aurora bakes the full path into the
annotation (`#* @get /api/iniciativas/data`).
[`aurora_add_route()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_add_route.md)
writes it for you; porting a mounted v1 router means rewriting each
annotation to its full path.

## Testing a ported handler

`pa$test_request(fiery::fake_request(url, method=, content=, headers=))`
runs a request through the assembled API without binding a port — handy
for fast, deterministic checks while you port.
