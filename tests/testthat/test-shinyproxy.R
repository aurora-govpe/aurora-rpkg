test_that("aurora_shinyproxy_yaml emits a valid spec entry", {
  y <- aurora_shinyproxy_yaml(image = "org/app:latest", id = "demo",
                              description = "An aurora app", port = 8000L)
  parsed <- yaml::yaml.load(y)            # a list with one spec
  spec <- parsed[[1]]
  expect_identical(spec$id, "demo")
  expect_identical(spec$`display-name`, "demo")
  expect_identical(spec$`container-image`, "org/app:latest")
  expect_identical(spec$port, 8000L)
  expect_identical(spec$description, "An aurora app")
})

test_that("wrap = TRUE produces a complete proxy.specs snippet", {
  y <- aurora_shinyproxy_yaml(image = "org/app:latest", id = "demo", wrap = TRUE)
  parsed <- yaml::yaml.load(y)
  expect_identical(parsed$proxy$specs[[1]]$id, "demo")
})

test_that("container-env is included when supplied", {
  y <- aurora_shinyproxy_yaml(image = "org/app:latest", id = "demo",
                              env = list(AURORA_ENV = "prod"))
  spec <- yaml::yaml.load(y)[[1]]
  expect_identical(spec$`container-env`$AURORA_ENV, "prod")
})

test_that("id/display-name default from the app name", {
  skip_if_not_installed("bslib")
  parent <- withr::local_tempdir()
  app <- fs::path(parent, "meuapp")
  aurora_create_app(app, template = "minimal")
  y <- aurora_shinyproxy_yaml(image = "org/x:latest", dir = app)
  spec <- yaml::yaml.load(y)[[1]]
  expect_identical(spec$id, "meuapp")
})

test_that("write = TRUE writes the file", {
  d <- withr::local_tempdir()
  aurora_shinyproxy_yaml(image = "org/app:latest", id = "demo", dir = d,
                         write = TRUE, file = "sp.yml")
  expect_true(fs::file_exists(fs::path(d, "sp.yml")))
})

test_that("a missing/empty image is rejected", {
  expect_error(aurora_shinyproxy_yaml(), "image")
  expect_error(aurora_shinyproxy_yaml(image = ""), "image")
})
