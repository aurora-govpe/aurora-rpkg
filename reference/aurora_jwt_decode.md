# Decode and verify a JWT

Returns the payload if the signature is valid and the token has not
expired; otherwise `NULL` (never throws).

## Usage

``` r
aurora_jwt_decode(auth, token)
```

## Arguments

- auth:

  An
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md)
  scheme.

- token:

  The token string (e.g. `request$cookies$token`).

## Value

The decoded payload list, or `NULL`.
