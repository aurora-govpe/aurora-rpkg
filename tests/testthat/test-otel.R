test_that("resolve_otel defaults to FALSE without arg/manifest/env", {
  withr::local_envvar(c(AURORA_OTEL = ""))
  expect_false(resolve_otel(list(), NULL))
})

test_that("resolve_otel honours precedence: arg > manifest > env", {
  withr::local_envvar(c(AURORA_OTEL = "true"))
  # explicit arg wins over everything
  expect_false(resolve_otel(list(otel = TRUE), FALSE))
  # manifest wins over env
  expect_true(resolve_otel(list(otel = "true"), NULL))
  # env used when neither arg nor manifest set
  expect_true(resolve_otel(list(), NULL))
})

test_that("aurora_is_verbose resolves arg > option > env > FALSE", {
  withr::local_options(aurora.verbose = NULL)
  withr::local_envvar(AURORA_VERBOSE = "")
  expect_false(aurora_is_verbose())            # default quiet
  expect_true(aurora_is_verbose(TRUE))         # explicit arg

  withr::local_options(aurora.verbose = TRUE)
  expect_true(aurora_is_verbose())             # option
  expect_false(aurora_is_verbose(FALSE))       # arg overrides option

  withr::local_options(aurora.verbose = NULL)
  withr::local_envvar(AURORA_VERBOSE = "yes")
  expect_true(aurora_is_verbose())             # env
})

test_that("as_flag coerces common truthy strings", {
  expect_true(as_flag("yes"))
  expect_true(as_flag("1"))
  expect_true(as_flag(TRUE))
  expect_false(as_flag("off"))
  expect_false(as_flag(NULL))
  expect_true(as_flag(NULL, default = TRUE))
})

test_that("aurora_app(otel = TRUE) wires the logger and still serves", {
  skip_if_not_installed("plumber2")
  skip_if_not_installed("bslib")
  skip_if_not_installed("fiery")

  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "otelapp")
  aurora_create_app(app_dir, template = "minimal")

  app <- aurora_app(app_dir, rebuild_ui = FALSE, otel = TRUE)
  expect_true(plumber2::is_plumber_api(app$api))

  # The wired logger must be a safe no-op when otel export is off: a request
  # still routes and responds.
  res <- app$api$test_request(fiery::fake_request("http://x/health"))
  expect_equal(res$status, 200L)
})
