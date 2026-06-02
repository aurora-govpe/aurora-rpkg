# Sorted unique non-missing values, for filter options

Convenience for building dropdown/filter option lists from a column:
sorted, unique, with `NA` dropped. Returns an empty character vector for
`NULL`/empty input (serializes as `[]`, the right shape for an empty
list).

## Usage

``` r
aurora_unique(x)
```

## Arguments

- x:

  A vector, or `NULL`.

## Value

The sorted unique non-`NA` values.

## Examples

``` r
aurora_unique(c("b", "a", NA, "a"))
#> [1] "a" "b"
```
