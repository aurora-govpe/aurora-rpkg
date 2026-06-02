# Guard a request, aborting with 401 unless it carries a valid token

Reads the scheme's cookie from `request`, verifies it, and – if invalid
or absent – stops handling with a `401 Unauthorized` via
[`reqres::abort_unauthorized()`](https://reqres.data-imaginist.com/reference/abort_http_problem.html).
On success it returns the payload invisibly. Use it inside a `@header`
handler on `/api/*`, returning
[plumber2::Next](https://plumber2.posit.co/reference/Next.html) to
continue:

## Usage

``` r
aurora_jwt_guard(auth, request)
```

## Arguments

- auth:

  An
  [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md)
  scheme.

- request:

  The reqres request object (the `request` handler argument).

## Value

The decoded payload, invisibly (or aborts).

## Details

    #* @any /api/*
    #* @header
    function(request) {
      aurora_jwt_guard(auth, request)
      plumber2::Next
    }
