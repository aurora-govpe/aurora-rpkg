make_docker_app <- function() {
  d <- withr::local_tempdir(.local_envir = parent.frame())
  writeLines("FROM scratch", fs::path(d, "Dockerfile"))
  d
}

# Capture the system2() calls aurora_build_image() would make, without docker.
local_fake_docker <- function(calls = new.env(), .env = parent.frame()) {
  calls$log <- list()
  testthat::local_mocked_bindings(
    Sys.which = function(...) "/usr/bin/docker",
    system2 = function(command, args, ...) {
      calls$log <- c(calls$log, list(c(command, args)))
      0L
    },
    .package = "aurora",
    .env = .env
  )
  calls
}

test_that("aurora_build_image() targets linux/amd64 by default", {
  d <- make_docker_app()
  calls <- local_fake_docker()
  aurora_build_image(d, tag = "org/app:latest")
  args <- calls$log[[1]]
  expect_equal(args[1:2], c("docker", "build"))
  i <- which(args == "--platform")
  expect_length(i, 1)
  expect_equal(args[i + 1], "linux/amd64")
})

test_that("platform = NULL builds for the host architecture", {
  d <- make_docker_app()
  calls <- local_fake_docker()
  aurora_build_image(d, tag = "org/app:latest", platform = NULL)
  expect_false("--platform" %in% calls$log[[1]])
})

test_that("a custom platform is passed through", {
  d <- make_docker_app()
  calls <- local_fake_docker()
  aurora_build_image(d, tag = "org/app:latest", platform = "linux/arm64")
  args <- calls$log[[1]]
  expect_equal(args[which(args == "--platform") + 1], "linux/arm64")
})

test_that("an invalid platform aborts early", {
  d <- make_docker_app()
  calls <- local_fake_docker()
  expect_error(
    aurora_build_image(d, tag = "org/app:latest", platform = "amd64"),
    "platform"
  )
  expect_error(
    aurora_build_image(d, tag = "org/app:latest", platform = c("a/b", "c/d")),
    "platform"
  )
  expect_length(calls$log, 0)
})

test_that("push = TRUE pushes after the build", {
  d <- make_docker_app()
  calls <- local_fake_docker()
  aurora_build_image(d, tag = "org/app:latest", push = TRUE)
  expect_length(calls$log, 2)
  expect_equal(calls$log[[2]][1:2], c("docker", "push"))
})

test_that("a missing Dockerfile aborts with a hint", {
  d <- withr::local_tempdir()
  calls <- local_fake_docker()
  expect_error(aurora_build_image(d, tag = "org/app:latest"), "Dockerfile")
})
