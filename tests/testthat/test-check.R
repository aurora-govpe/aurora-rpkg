# Tests for aurora_check() (the app doctor) ------------------------------------

make_app <- function(parent) {
  app <- fs::path(parent, "app")
  fs::dir_create(fs::path(app, c("helpers", "routers", "www")))
  writeLines(c("#* @get /health", "function() list(ok = TRUE)"),
             fs::path(app, "routers", "health.R"))
  writeLines("<!doctype html><title>x</title>", fs::path(app, "www", "index.html"))
  app
}

test_that("aurora_check flags UI code in a runtime helper", {
  app <- make_app(withr::local_tempdir())
  writeLines(c("link <- shiny::icon('github')", "th <- bslib::bs_theme()"),
             fs::path(app, "helpers", "navbar.R"))
  res <- aurora_check(app)
  expect_true(any(res$level == "warning"))
  expect_true(any(grepl("navbar.R", res$message)))
})

test_that("aurora_check flags packages not declared in _aurora.yml", {
  app <- make_app(withr::local_tempdir())
  writeLines(c("#* @get /api/x", "function() glue::glue('hi')"),
             fs::path(app, "routers", "x.R"))
  writeLines(c("name: demo", "packages:", "  - cli"),
             fs::path(app, "_aurora.yml"))
  res <- aurora_check(app)
  expect_true(any(grepl("glue", res$message)))
})

test_that("aurora_check is clean for a tidy app", {
  app <- make_app(withr::local_tempdir())
  writeLines("x <- 1", fs::path(app, "helpers", "utils.R"))
  writeLines(c("name: demo", "packages:", "  - cli"),
             fs::path(app, "_aurora.yml"))
  res <- aurora_check(app)
  expect_false(any(res$level == "warning"))
})
