# Authentication

Auth in aurora is **pluggable and opt-in** — it is never baked into
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md).
aurora ships one scheme: a stateless **JWT delivered as an `HttpOnly`
cookie**, signed with [jose](https://cran.r-project.org/package=jose).
It stays stateless (the token is self-contained, so any replica can
validate it) and is wired entirely in your app’s annotated files.

## Scaffold

``` r

library(aurora)
aurora_create_app("meu_app", template = "auth")
aurora_run("meu_app")   # log in with admin / admin123
```

## How it is wired

Three pieces, all in the app —
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
needs no auth knowledge:

**1. The scheme (a helper).** `helpers/auth_setup.R` defines the scheme
and your user lookup:

``` r

auth <- aurora_auth_jwt(secret = Sys.getenv("AURORA_JWT_SECRET", "dev-only"))
secure_cookies <- identical(Sys.getenv("AURORA_ENV"), "prod")
find_user <- function(name) ...   # your DB / store; passwords hashed with sodium
```

**2. The gate (a header route).** `routers/guard.R` runs before every
`/api/*` handler — and before the request body is even received —
rejecting anyone without a valid token with a clean `401`:

``` r

#* @any /api/*
#* @header
function(request) {
  aurora_jwt_guard(auth, request)   # 401 via reqres::abort_unauthorized() if invalid
  plumber2::Next                    # otherwise continue the chain
}
```

**3. Public login/logout (not under `/api`, so the gate ignores them).**

``` r

#* @post /auth/login
#* @parser json
#* @serializer json
function(request, response, body = NULL) {
  u <- find_user(body$user)
  if (is.null(u) || !sodium::password_verify(u$hash, body$pass %||% "")) {
    response$status <- 401L
    return(list(error = "Usuario ou senha invalidos."))
  }
  token <- aurora_jwt_token(auth, list(user = u$name))
  aurora_set_auth_cookie(auth, response, token, secure = secure_cookies)
  list(user = u$name)
}

#* @post /auth/logout
#* @serializer json
function(response) {
  aurora_clear_auth_cookie(auth, response, secure = secure_cookies)
  list(status = "ok")
}
```

## The frontend

The cookie is `HttpOnly`, so JavaScript never touches the token.
`app.js` simply probes `GET /api/me` on load (reveal the app on
success), posts to `/auth/login` / `/auth/logout`, and shows the login
overlay whenever any `/api` call returns `401` via the runtime’s
`aurora.onUnauthorized` hook.

## Helpers

| Function | Purpose |
|----|----|
| `aurora_auth_jwt(secret, cookie, expiry)` | define the scheme |
| `aurora_jwt_token(auth, claims)` | mint a signed token (login) |
| `aurora_jwt_decode(auth, token)` | verify; returns payload or `NULL` |
| `aurora_jwt_guard(auth, request)` | gate: `401` unless valid (use in a `@header` route) |
| [`aurora_set_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md) / [`aurora_clear_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md) | manage the cookie |

## Why not a fireproof guard?

plumber2’s native `api_auth_guard()` + `fireproof` guards target
upstream identity providers (OAuth/OIDC) or shared static keys, require
the `firesale` datastore plugin, and return `400`/`403`. A self-issued
JWT-cookie session needs a uniform `401` for both absent and expired
sessions (cookie expiry looks like “absent”) and no extra infrastructure
— so aurora uses a `@header` guard +
[`reqres::abort_unauthorized()`](https://reqres.data-imaginist.com/reference/abort_http_problem.html),
the migration-endorsed replacement for v1 filters.

## Production checklist

- Set a strong `AURORA_JWT_SECRET` (never commit it).
- Set `AURORA_ENV=prod` behind HTTPS for `Secure; SameSite=Strict`
  cookies.
- Replace the demo `find_user()` with your real, `sodium`-hashed user
  store.
