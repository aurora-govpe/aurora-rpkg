# Encode an sf object as GeoJSON for a JSON response, NULL-safe

Returns an unboxed GeoJSON string for an sf object, or `NULL` if the
input is `NULL` or not an `sf` object (so an absent layer serializes as
JSON `null`, not `[]` or an error).

## Usage

``` r
aurora_geojson(x)
```

## Arguments

- x:

  An sf object, or `NULL`.

## Value

An unboxed GeoJSON string, or `NULL`.
