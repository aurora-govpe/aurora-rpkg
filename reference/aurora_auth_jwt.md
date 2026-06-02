# JWT-cookie authentication scheme

aurora's auth is *pluggable* and never baked into
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)'s
core path. This is the one provided scheme: a stateless JSON Web Token
signed with jose (HMAC) and delivered as an `HttpOnly` cookie. It is the
plumber2 translation of the reference app's v1 `@filter` JWT scheme.

## Usage

``` r
aurora_auth_jwt(
  secret = Sys.getenv("AURORA_JWT_SECRET"),
  cookie = "token",
  expiry = 28800L
)
```

## Arguments

- secret:

  Secret used to sign/verify tokens (string or raw). Prefer supplying it
  via an environment variable rather than hardcoding.

- cookie:

  Name of the cookie carrying the token.

- expiry:

  Token lifetime in seconds.

## Value

An object of class `aurora_auth_jwt`.

## Details

The companion helpers operate on the scheme object:

- [`aurora_jwt_token()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_token.md)
  mints a signed token (at login).

- [`aurora_set_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md)
  /
  [`aurora_clear_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md)
  manage the cookie.

- [`aurora_jwt_guard()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_guard.md)
  is the gate: call it from a `@header` handler on `/api/*` and it
  rejects unauthenticated requests with a `401`.

Auth is wired entirely in your app's annotated router files (a `@header`
guard + public `/auth/*` routes), so
[`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
needs no auth knowledge. See the `auth` template
([`aurora_create_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_create_app.md)).

## Examples

``` r
auth <- aurora_auth_jwt(secret = "dev-only-secret")
tok <- aurora_jwt_token(auth, list(user = "alice"))
aurora_jwt_decode(auth, tok)$user
#> [1] "alice"
```
