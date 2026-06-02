# Set or clear the auth cookie on a response

`aurora_set_auth_cookie()` writes an `HttpOnly` cookie carrying the
token (at login); `aurora_clear_auth_cookie()` removes it (at logout).
In production (HTTPS) pass `secure = TRUE` for
`Secure; SameSite=Strict`; in development the default uses
`SameSite=Lax` so it works over plain HTTP on a different port.

## Usage

``` r
aurora_set_auth_cookie(auth, response, token, secure = FALSE)

aurora_clear_auth_cookie(auth, response, secure = FALSE)
```

## Arguments

- auth:

  An
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md)
  scheme.

- response:

  The reqres response object (the `response` handler argument).

- token:

  The token string from
  [`aurora_jwt_token()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_token.md).

- secure:

  Whether to set `Secure` + `SameSite=Strict` (use behind HTTPS).

## Value

The response, invisibly.
