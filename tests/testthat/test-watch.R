test_that("ui_watch_files collects build_ui.R and ui_modules/*.R", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("shiny")
  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "w1")
  aurora_create_app(app_dir, template = "minimal")
  fs::file_create(fs::path(app_dir, "ui_modules", "ui_extra.R"))

  cfg <- read_config(app_dir)
  files <- ui_watch_files(cfg, app_dir)
  expect_true(any(grepl("build_ui.R$", files)))
  expect_true(any(grepl("ui_modules/ui_extra.R$", files)))
})

test_that("mtime_snapshot reflects changes and added/removed files", {
  d <- withr::local_tempdir()
  f1 <- fs::path(d, "a.R"); fs::file_create(f1)
  s1 <- mtime_snapshot(f1)
  expect_named(s1, as.character(f1))

  # adding a file changes the snapshot's shape
  f2 <- fs::path(d, "b.R"); fs::file_create(f2)
  s2 <- mtime_snapshot(c(f1, f2))
  expect_false(identical(s1, s2))

  expect_identical(mtime_snapshot(character(0)),
                   stats::setNames(numeric(0), character(0)))
})

test_that("watch_tick rebuilds the UI when a UI source changes", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("shiny")
  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "w2")
  aurora_create_app(app_dir, template = "minimal")

  app <- aurora_app(app_dir, rebuild_ui = TRUE, port = 8000L)
  index <- fs::path(app_dir, "www", "index.html")
  expect_true(fs::file_exists(index))

  state <- list(
    ui     = mtime_snapshot(ui_watch_files(app$config, app_dir)),
    routes = mtime_snapshot(route_watch_files(app$config))
  )

  # No change -> no rebuild: index mtime stays.
  before <- fs::file_info(index)$modification_time
  state <- watch_tick(app, state)
  expect_equal(fs::file_info(index)$modification_time, before)

  # Touch a UI source so its mtime advances, then tick -> rebuild happens.
  bu <- fs::path(app_dir, "build_ui.R")
  fs::file_touch(bu, modification_time = Sys.time() + 2)
  state <- watch_tick(app, state)
  # State picked up the new mtime (so a subsequent identical tick won't rebuild).
  expect_true(state$ui[[bu]] >= as.numeric(before))
})

test_that("watch_tick picks up a router change without rebuilding the UI", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("shiny")
  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "w3")
  aurora_create_app(app_dir, template = "minimal")
  app <- aurora_app(app_dir, rebuild_ui = TRUE, port = 8000L)

  index <- fs::path(app_dir, "www", "index.html")
  ui_before <- fs::file_info(index)$modification_time
  state <- list(
    ui     = mtime_snapshot(ui_watch_files(app$config, app_dir)),
    routes = mtime_snapshot(route_watch_files(app$config))
  )

  hf <- fs::path(app_dir, "routers", "health.R")
  fs::file_touch(hf, modification_time = Sys.time() + 2)
  state <- watch_tick(app, state)

  # The route change is recorded in state...
  expect_true(state$routes[[hf]] >= as.numeric(ui_before))
  # ...and a router change does NOT trigger a static UI rebuild.
  expect_equal(fs::file_info(index)$modification_time, ui_before)
})
