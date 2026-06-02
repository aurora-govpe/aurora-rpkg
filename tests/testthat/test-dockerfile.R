make_app <- function(brand = TRUE) {
  d <- withr::local_tempdir(.local_envir = parent.frame())
  fs::dir_create(fs::path(d, "routers"))
  fs::dir_create(fs::path(d, "www"))
  writeLines("ok", fs::path(d, "www", "index.html"))   # prebuilt UI
  writeLines("library(bslib)\nbuild_ui <- function() htmltools::tagList()", fs::path(d, "build_ui.R"))
  if (brand) writeLines("meta:\n  name: t", fs::path(d, "_brand.yml"))
  d
}

test_that("debian flavor (default) targets rocker + PPM binaries", {
  d <- make_app()
  df <- aurora_dockerfile(d, write = FALSE)
  expect_match(df, "FROM rocker/r-ver", fixed = TRUE)
  expect_match(df, "packagemanager.posit.co", fixed = TRUE)
  expect_match(df, "HTTPUserAgent", fixed = TRUE)
  expect_match(df, "install.packages(c('plumber2'", fixed = TRUE)
  expect_match(df, "pak::pak('segpr-ndgr/aurora')", fixed = TRUE)
  expect_match(df, "CMD [\"Rscript\", \"api.R\"]", fixed = TRUE)
})

test_that("alpine flavor targets r-minimal + installr", {
  d <- make_app()
  df <- aurora_dockerfile(d, flavor = "alpine", write = FALSE)
  expect_match(df, "FROM rhub/r-minimal", fixed = TRUE)
  expect_match(df, "installr -d", fixed = TRUE)
  expect_match(df, "-t \"", fixed = TRUE)        # temporary build deps
  expect_match(df, "-a \"", fixed = TRUE)        # runtime libs
  expect_no_match(df, "gdal")                    # geo not in the baseline
  expect_match(df, "plumber2", fixed = TRUE)
  expect_match(df, "segpr-ndgr/aurora", fixed = TRUE)
  expect_match(df, "Rcppcore/Rcpp", fixed = TRUE) # musl workaround
  expect_no_match(df, "packagemanager.posit.co")  # no PPM on alpine
})

test_that("runtime image excludes UI build deps and does not rebuild the UI", {
  df <- aurora_dockerfile(make_app(brand = TRUE), write = FALSE)
  # The container serves the prebuilt UI; UI build deps are not installed.
  expect_match(df, "AURORA_REBUILD_UI=false", fixed = TRUE)
  expect_no_match(df, "'bslib'")       # not in install.packages (UI build-time)
  expect_no_match(df, "'brand.yml'")   # UI build-time only
})

test_that("base and sysdeps can be overridden; flavor is validated", {
  d <- make_app()
  df <- aurora_dockerfile(d, base = "my/base:1", sysdeps = c("libfoo-dev"), write = FALSE)
  expect_match(df, "FROM my/base:1", fixed = TRUE)
  expect_match(df, "libfoo-dev", fixed = TRUE)
  expect_no_match(df, "libgdal-dev")  # defaults replaced by explicit sysdeps
  expect_error(aurora_dockerfile(d, flavor = "nope", write = FALSE))
})

test_that("writing produces Dockerfile + .dockerignore", {
  d <- make_app()
  out <- aurora_dockerfile(d)
  expect_true(fs::file_exists(out))
  expect_true(fs::file_exists(fs::path(d, ".dockerignore")))
})
