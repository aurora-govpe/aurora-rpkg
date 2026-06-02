# JSON serialization helpers ----------------------------------------------------
#
# Route handlers repeatedly need to guard the same footguns when turning R values
# into a JSON response: a scalar must be `jsonlite::unbox()`ed or it serializes as
# a 1-element array; a NULL/empty value should become JSON `null` (or be omitted)
# rather than `[]` (which trips frontends that test truthiness or index `[0]`);
# and an `sf` object must go through a geojson encoder. These wrap those patterns
# so handlers don't reinvent them (and get the NULL handling right).

#' Unbox a scalar for a JSON response, NULL-safe
#'
#' Wraps [jsonlite::unbox()] so a length-1 value serializes as a JSON scalar
#' instead of a 1-element array, while `NULL`/empty input returns `NULL` (which
#' serializes as JSON `null` or is dropped) instead of `[]`. The `[]` case is a
#' common footgun: a frontend doing `if (x)` or `x[0]` misbehaves on an empty
#' array where it expected a scalar or null.
#'
#' @param x A length-1 value, or `NULL`/length-0.
#'
#' @return `jsonlite::unbox(x)` for a scalar, or `NULL`.
#' @export
#' @examples
#' aurora_unbox("2026-06-02")
#' aurora_unbox(NULL)
aurora_unbox <- function(x) {
  if (is.null(x) || length(x) == 0) return(NULL)
  jsonlite::unbox(x)
}

#' Encode an sf object as GeoJSON for a JSON response, NULL-safe
#'
#' Returns an unboxed GeoJSON string for an \pkg{sf} object, or `NULL` if the
#' input is `NULL` or not an `sf` object (so an absent layer serializes as JSON
#' `null`, not `[]` or an error).
#'
#' @param x An \pkg{sf} object, or `NULL`.
#'
#' @return An unboxed GeoJSON string, or `NULL`.
#' @export
aurora_geojson <- function(x) {
  if (is.null(x) || !inherits(x, "sf")) return(NULL)
  rlang::check_installed("geojsonsf", reason = "to encode sf objects as GeoJSON")
  jsonlite::unbox(geojsonsf::sf_geojson(x))
}

#' Sorted unique non-missing values, for filter options
#'
#' Convenience for building dropdown/filter option lists from a column:
#' sorted, unique, with `NA` dropped. Returns an empty character vector for
#' `NULL`/empty input (serializes as `[]`, the right shape for an empty list).
#'
#' @param x A vector, or `NULL`.
#'
#' @return The sorted unique non-`NA` values.
#' @export
#' @examples
#' aurora_unique(c("b", "a", NA, "a"))
aurora_unique <- function(x) {
  if (is.null(x) || length(x) == 0) return(character(0))
  sort(unique(x[!is.na(x)]))
}
