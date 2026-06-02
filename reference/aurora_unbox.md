# Unbox a scalar for a JSON response, NULL-safe

Wraps
[`jsonlite::unbox()`](https://jeroen.r-universe.dev/jsonlite/reference/unbox.html)
so a length-1 value serializes as a JSON scalar instead of a 1-element
array, while `NULL`/empty input returns `NULL` (which serializes as JSON
`null` or is dropped) instead of `[]`. The `[]` case is a common
footgun: a frontend doing `if (x)` or `x[0]` misbehaves on an empty
array where it expected a scalar or null.

## Usage

``` r
aurora_unbox(x)
```

## Arguments

- x:

  A length-1 value, or `NULL`/length-0.

## Value

`jsonlite::unbox(x)` for a scalar, or `NULL`.

## Examples

``` r
aurora_unbox("2026-06-02")
#> [x] "2026-06-02"
aurora_unbox(NULL)
#> NULL
```
