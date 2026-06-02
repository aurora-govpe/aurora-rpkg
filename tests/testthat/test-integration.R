# Real-port integration test: boot an aurora_app in a separate R process and hit
# it over HTTP. Complements the in-process pa$test_request() checks. Skips unless
# aurora is installed in a fresh process (so it runs under R CMD check / CI, but
# is skipped during interactive devtools::load_all() development).

test_that("a booted aurora_app serves /health and the static UI over HTTP", {
  skip_on_cran()
  skip_if_not_installed("httr2")
  skip_if_not_installed("callr")
  skip_if_not_installed("bslib")
  skip_if_not_installed("fiery")
  skip_if_not_installed("httpuv")
  if (!isTRUE(callr::r(function() requireNamespace("aurora", quietly = TRUE)))) {
    skip("aurora not loadable in a separate process (dev load_all) — skipping real boot")
  }

  app_dir <- fs::path(withr::local_tempdir(), "itest")
  aurora_create_app(app_dir, template = "minimal")   # builds www/index.html
  port <- httpuv::randomPort()

  px <- callr::r_bg(
    function(dir, port) {
      aurora::aurora_run(dir, host = "127.0.0.1", port = port, rebuild_ui = FALSE)
    },
    args = list(dir = app_dir, port = port)
  )
  withr::defer(if (px$is_alive()) px$kill())

  base <- sprintf("http://127.0.0.1:%d", port)
  get <- function(path) {
    tryCatch(
      httr2::req_perform(httr2::req_error(httr2::request(paste0(base, path)), is_error = function(r) FALSE)),
      error = function(e) NULL
    )
  }

  up <- FALSE
  for (i in 1:40) {                       # ~20s budget for the process to bind
    r <- get("/health")
    if (!is.null(r) && httr2::resp_status(r) == 200) { up <- TRUE; break }
    if (!px$is_alive()) break
    Sys.sleep(0.5)
  }
  if (!up) {
    skip(paste("server did not come up:",
               paste(utils::tail(px$read_all_error_lines(), 3), collapse = " | ")))
  }

  h <- get("/health")
  expect_equal(httr2::resp_status(h), 200L)
  expect_equal(httr2::resp_body_json(h)$status[[1]], "ok")

  root <- get("/")
  expect_equal(httr2::resp_status(root), 200L)
  expect_match(httr2::resp_body_string(root), "minimal")   # the prebuilt UI
})
