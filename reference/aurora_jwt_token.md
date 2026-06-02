# Mint a signed JWT for an auth scheme

Signs `claims` (plus an `exp` expiry computed from the scheme) with
HMAC.

## Usage

``` r
aurora_jwt_token(auth, claims = list())
```

## Arguments

- auth:

  An
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md)
  scheme.

- claims:

  A named list of claims to embed (e.g. `list(user = "alice")`).

## Value

The signed token as a string.
