# Extra static mounts declared in _aurora.yml (statics:) -- ADR-018.

test_that("resolve_statics returns empty when none declared", {
  expect_identical(resolve_statics(list(), "."), list())
})

test_that("resolve_statics maps URL prefixes to resolved dirs", {
  dir <- "/srv/app"
  st <- resolve_statics(list(statics = list("/assets" = "/srv/shared",
                                            "docs" = "extra-docs")), dir)
  expect_length(st, 2L)
  expect_equal(st[[1]]$at, "/assets")
  expect_equal(as.character(st[[1]]$path), "/srv/shared")   # absolute kept as-is
  expect_equal(st[[2]]$at, "/docs")                         # leading slash added
  expect_equal(as.character(st[[2]]$path),
               as.character(fs::path_abs("extra-docs", start = dir)))  # relative -> app root
})

test_that("resolve_statics rejects a non-map or unnamed statics", {
  expect_error(resolve_statics(list(statics = c("a", "b")), "."), "map of URL prefix")
  expect_error(resolve_statics(list(statics = list("x")), "."), "map of URL prefix")
})

test_that("resolve_statics forbids mounting at /", {
  expect_error(resolve_statics(list(statics = list("/" = "/srv/x")), "."), "cannot mount at")
})

test_that("a declared statics dir is served at its prefix", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("fiery")

  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "stapp")
  aurora_create_app(app_dir, template = "minimal")

  # a server-side shared dir + a manifest mounting it at /assets
  shared <- fs::path(parent, "shared")
  fs::dir_create(shared)
  writeLines("SHARED-OK", fs::path(shared, "ping.txt"))
  man <- fs::path(app_dir, "_aurora.yml")
  y <- yaml::read_yaml(man)
  y$statics <- list("/assets" = shared)
  yaml::write_yaml(y, man)

  pa <- aurora_app(app_dir, rebuild_ui = FALSE)$api
  r <- pa$test_request(fiery::fake_request("http://x/assets/ping.txt"))
  expect_equal(r$status, 200L)                     # the mounted file is found
  # test_request resolves an asset to its file path (served verbatim over HTTP)
  body <- if (is.raw(r$body)) rawToChar(r$body) else paste(r$body, collapse = "")
  expect_match(body, "ping\\.txt$")
})

test_that("a missing statics dir is skipped with a warning, app still assembles", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("fiery")

  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "stapp2")
  aurora_create_app(app_dir, template = "minimal")
  man <- fs::path(app_dir, "_aurora.yml")
  y <- yaml::read_yaml(man)
  y$statics <- list("/assets" = fs::path(parent, "does-not-exist"))
  yaml::write_yaml(y, man)

  expect_warning(
    pa <- aurora_app(app_dir, rebuild_ui = FALSE)$api,
    "not found"
  )
  # the app still serves its own UI at /
  r <- pa$test_request(fiery::fake_request("http://x/"))
  expect_equal(r$status, 200L)
})
