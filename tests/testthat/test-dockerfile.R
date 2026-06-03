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
  expect_match(df, "pak::pak('aurora-govpe/aurora-rpkg@v0.1.1')", fixed = TRUE)
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
  expect_match(df, "aurora-govpe/aurora-rpkg", fixed = TRUE)
  expect_match(df, "Rcppcore/Rcpp", fixed = TRUE) # musl workaround
  expect_no_match(df, "packagemanager.posit.co")  # no PPM on alpine
})

test_that("packages: in _aurora.yml pins runtime deps over source scanning", {
  d <- make_app(brand = FALSE)
  # a router that ::-uses something the scan would otherwise pick up
  writeLines("#* @get /api/x\nfunction() dplyr::tibble(a = 1)", fs::path(d, "routers", "x.R"))
  yaml::write_yaml(list(name = "p", packages = c("jsonlite", "DBI")),
                   fs::path(d, "_aurora.yml"))
  df <- aurora_dockerfile(d, write = FALSE)
  expect_match(df, "'jsonlite'", fixed = TRUE)
  expect_match(df, "'DBI'", fixed = TRUE)
  expect_match(df, "'plumber2'", fixed = TRUE)   # always added
  expect_no_match(df, "'dplyr'")                 # scan suppressed by the pin
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

test_that("aurora_dockerfile bakes ENV TZ (default America/Recife), omits on NULL", {
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, c("routers", "www")))
  writeLines(c("#* @get /h", "function() 1"), fs::path(app, "routers", "h.R"))
  writeLines("<!doctype html>", fs::path(app, "www", "index.html"))
  writeLines(c("name: demo", "packages:", "  - cli"), fs::path(app, "_aurora.yml"))

  for (fl in c("debian", "alpine")) {
    df <- aurora_dockerfile(app, flavor = fl, write = FALSE)
    expect_match(df, "ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Recife", fixed = TRUE)
    df2 <- aurora_dockerfile(app, flavor = fl, tz = "UTC", write = FALSE)
    expect_match(df2, "TZ=UTC", fixed = TRUE)
    df3 <- aurora_dockerfile(app, flavor = fl, tz = NULL, write = FALSE)
    expect_false(grepl("TZ=", df3, fixed = TRUE))
  }
})
