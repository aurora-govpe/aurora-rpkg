test_that("aurora_ruscker_yaml emits a valid type: api spec entry", {
  y <- aurora_ruscker_yaml(image = "org/app:latest", id = "demo",
                           description = "An aurora app", port = 8000L)
  parsed <- yaml::yaml.load(y)            # a list with one spec
  spec <- parsed[[1]]
  expect_identical(spec$id, "demo")
  expect_identical(spec$`display-name`, "demo")
  expect_identical(spec$`container-image`, "org/app:latest")
  expect_identical(spec$type, "api")
  expect_identical(spec$description, "An aurora app")
  expect_identical(spec$api$port, 8000L)
  expect_identical(spec$api$`docs-path`, "/__docs__")
  expect_identical(spec$api$`health-path`, "/__healthz__")
  expect_identical(spec$`min-replicas`, 0L)
  expect_identical(spec$`max-replicas`, 3L)
})

test_that("optional api keys (rate-limit, cors) are dropped unless supplied", {
  spec <- yaml::yaml.load(aurora_ruscker_yaml(image = "org/app:latest", id = "d"))[[1]]
  expect_null(spec$api$`rate-limit`)
  expect_null(spec$api$cors)

  spec2 <- yaml::yaml.load(aurora_ruscker_yaml(
    image = "org/app:latest", id = "d", rate_limit = "100/min", cors = TRUE
  ))[[1]]
  expect_identical(spec2$api$`rate-limit`, "100/min")
  expect_true(spec2$api$cors)
})

test_that("wrap = TRUE produces a complete proxy.specs snippet", {
  y <- aurora_ruscker_yaml(image = "org/app:latest", id = "demo", wrap = TRUE)
  parsed <- yaml::yaml.load(y)
  expect_identical(parsed$proxy$specs[[1]]$id, "demo")
  expect_identical(parsed$proxy$specs[[1]]$type, "api")
})

test_that("container-env is included when supplied", {
  y <- aurora_ruscker_yaml(image = "org/app:latest", id = "demo",
                           env = list(AURORA_ENV = "prod"))
  spec <- yaml::yaml.load(y)[[1]]
  expect_identical(spec$`container-env`$AURORA_ENV, "prod")
})

test_that("replica counts are emitted and validated", {
  spec <- yaml::yaml.load(aurora_ruscker_yaml(
    image = "org/app:latest", id = "d", min_replicas = 1L, max_replicas = 5L
  ))[[1]]
  expect_identical(spec$`min-replicas`, 1L)
  expect_identical(spec$`max-replicas`, 5L)

  expect_error(
    aurora_ruscker_yaml(image = "org/app:latest", min_replicas = 3L, max_replicas = 1L),
    "max_replicas"
  )
  expect_error(
    aurora_ruscker_yaml(image = "org/app:latest", min_replicas = -1L),
    "min_replicas"
  )
})

test_that("cors must be a single logical when supplied", {
  expect_error(aurora_ruscker_yaml(image = "org/app:latest", cors = "yes"), "cors")
})

test_that("id/display-name default from the app name", {
  skip_if_not_installed("bslib")
  parent <- withr::local_tempdir()
  app <- fs::path(parent, "meuapp")
  aurora_create_app(app, template = "minimal")
  y <- aurora_ruscker_yaml(image = "org/x:latest", dir = app)
  spec <- yaml::yaml.load(y)[[1]]
  expect_identical(spec$id, "meuapp")
})

test_that("write = TRUE writes the file", {
  d <- withr::local_tempdir()
  aurora_ruscker_yaml(image = "org/app:latest", id = "demo", dir = d,
                      write = TRUE, file = "ruscker.yml")
  expect_true(fs::file_exists(fs::path(d, "ruscker.yml")))
})

test_that("a missing/empty image is rejected", {
  expect_error(aurora_ruscker_yaml(), "image")
  expect_error(aurora_ruscker_yaml(image = ""), "image")
})
