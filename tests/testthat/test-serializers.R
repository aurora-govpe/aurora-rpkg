# Tests for the JSON serialization helpers -------------------------------------

test_that("aurora_unbox unboxes scalars and is NULL-safe", {
  expect_s3_class(aurora_unbox("x"), "scalar")
  expect_null(aurora_unbox(NULL))
  expect_null(aurora_unbox(character(0)))
  # An unboxed scalar serializes as a JSON scalar, not a 1-element array.
  expect_identical(as.character(jsonlite::toJSON(aurora_unbox("x"))), "\"x\"")
})

test_that("aurora_unique returns sorted unique non-NA, empty-safe", {
  expect_identical(aurora_unique(c("b", "a", NA, "a")), c("a", "b"))
  expect_identical(aurora_unique(NULL), character(0))
  expect_identical(aurora_unique(character(0)), character(0))
})

test_that("aurora_geojson is NULL/non-sf safe", {
  expect_null(aurora_geojson(NULL))
  expect_null(aurora_geojson(data.frame(x = 1)))
})

test_that("aurora_geojson encodes an sf object", {
  skip_if_not_installed("sf")
  skip_if_not_installed("geojsonsf")
  pts <- sf::st_as_sf(
    data.frame(id = 1, lon = -34.9, lat = -8.05),
    coords = c("lon", "lat"), crs = 4326
  )
  gj <- aurora_geojson(pts)
  expect_s3_class(gj, "scalar")
  expect_match(as.character(gj), "FeatureCollection")
})
