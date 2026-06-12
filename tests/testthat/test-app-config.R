test_that("read_config defaults engine and name from convention", {
  d <- withr::local_tempdir()
  fs::file_create(fs::path(d, "build_ui.R"))
  cfg <- read_config(d)
  expect_identical(cfg$engine, "plumber2")
  expect_identical(cfg$routers, "routers")
  expect_true(nzchar(cfg$name))
})

test_that("read_config honours optional _aurora.yml overrides", {
  d <- withr::local_tempdir()
  fs::file_create(fs::path(d, "build_ui.R"))
  yaml::write_yaml(list(name = "custom", engine = "plumber2"),
                   fs::path(d, "_aurora.yml"))
  expect_identical(read_config(d)$name, "custom")
})

test_that("read_config rejects non-plumber2 engines", {
  d <- withr::local_tempdir()
  fs::file_create(fs::path(d, "build_ui.R"))
  yaml::write_yaml(list(engine = "shiny"), fs::path(d, "_aurora.yml"))
  expect_error(read_config(d), "plumber2")
})

test_that("assert_is_app rejects non-app directories", {
  d <- withr::local_tempdir()
  expect_error(read_config(d), "does not look like an aurora app")
})

test_that("create_app scaffolds the canonical layout", {
  skip_if_not_installed("bslib")
  parent <- withr::local_tempdir()
  app <- fs::path(parent, "demo")
  aurora_create_app(app, template = "minimal")

  expect_true(fs::file_exists(fs::path(app, "api.R")))
  expect_true(fs::file_exists(fs::path(app, "build_ui.R")))
  expect_true(fs::file_exists(fs::path(app, "routers", "health.R")))
  expect_true(fs::dir_exists(fs::path(app, "helpers")))
  expect_true(fs::dir_exists(fs::path(app, "ui_modules")))
  expect_true(fs::file_exists(fs::path(app, "www", "js", "core.js")))
  expect_true(fs::file_exists(fs::path(app, "www", "js", "app.js")))
  expect_true(fs::file_exists(fs::path(app, "data", "config.yml")))
  expect_true(fs::file_exists(fs::path(app, "_brand.yml")))

  # the un-hidden template `dockerignore` is restored to its real name,
  # and the asset dirs exist without shipped .gitkeep placeholders
  expect_true(fs::file_exists(fs::path(app, ".dockerignore")))
  expect_false(fs::file_exists(fs::path(app, "dockerignore")))
  expect_true(fs::dir_exists(fs::path(app, "www", "images")))

  expect_identical(read_config(app)$name, "demo")
})

test_that("add_route writes a mounted router file", {
  parent <- withr::local_tempdir()
  app <- fs::path(parent, "demo2")
  aurora_create_app(app, template = "minimal")

  aurora_add_route("widgets", dir = app)
  rf <- fs::path(app, "routers", "widgets.R")
  expect_true(fs::file_exists(rf))
  txt <- readLines(rf)
  expect_true(any(grepl("@get /api/widgets/data", txt, fixed = TRUE)))
})

test_that("abort_app_file names the file and hints a missing package", {
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, c("helpers", "routers", "www")))
  writeLines("library(nonexistentpkg123)", fs::path(app, "helpers", "setup.R"))
  writeLines(
    c("#* @get /health", "function() list(ok = TRUE)"),
    fs::path(app, "routers", "health.R")
  )

  err <- tryCatch(
    aurora_app(app, rebuild_ui = FALSE),
    error = function(e) e
  )
  expect_s3_class(err, "rlang_error")
  msg <- cli::ansi_strip(conditionMessage(err))
  expect_match(msg, "helper")
  expect_match(msg, "setup.R", fixed = TRUE)
  expect_match(msg, "nonexistentpkg123", fixed = TRUE)
  expect_match(msg, "install.packages", fixed = TRUE)
})

test_that("aurora_config reads data/config.yml anchored to the app dir", {
  skip_if_not_installed("config")
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, "data"))
  writeLines(c("default:", "  foo: bar", "  app_name: myapp"),
             fs::path(app, "data", "config.yml"))
  # Resolves via `dir`, not the (different) current working directory.
  expect_identical(aurora_config("foo", dir = app), "bar")
})

test_that("read_config name falls back to config.yml app_name", {
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, c("routers", "data", "www")))
  writeLines(c("#* @get /h", "function() 1"), fs::path(app, "routers", "h.R"))
  writeLines(c("default:", "  app_name: from_config"),
             fs::path(app, "data", "config.yml"))
  expect_identical(read_config(app)$name, "from_config")
})

test_that("aurora_app(attach=TRUE) attaches declared packages", {
  skip_if_not_installed("tibble")
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, c("helpers", "routers", "www")))
  writeLines(c("#* @get /h", "function() 1"), fs::path(app, "routers", "h.R"))
  writeLines("x <- 1", fs::path(app, "helpers", "s.R"))
  writeLines(c("name: demo", "attach: true", "packages:", "  - tibble"),
             fs::path(app, "_aurora.yml"))

  was_attached <- "package:tibble" %in% search()
  withr::defer(if (!was_attached && "package:tibble" %in% search())
    detach("package:tibble", character.only = TRUE))

  aurora_app(app, rebuild_ui = FALSE)
  expect_true("package:tibble" %in% search())
})

test_that("aurora_app(attach=TRUE) errors helpfully on a missing declared package", {
  app <- withr::local_tempdir()
  fs::dir_create(fs::path(app, c("helpers", "routers", "www")))
  writeLines(c("#* @get /h", "function() 1"), fs::path(app, "routers", "h.R"))
  writeLines(c("name: demo", "attach: true", "packages:", "  - nonexistentpkg999"),
             fs::path(app, "_aurora.yml"))
  err <- tryCatch(aurora_app(app, rebuild_ui = FALSE), error = function(e) e)
  expect_s3_class(err, "rlang_error")
  expect_match(cli::ansi_strip(conditionMessage(err)), "nonexistentpkg999")
})
