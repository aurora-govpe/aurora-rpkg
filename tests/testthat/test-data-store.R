test_that("aurora_data_store registers and reads datasets", {
  d <- withr::local_tempdir()
  f <- fs::path(d, "sales.rds")
  saveRDS(data.frame(x = 1:3), f)

  store <- aurora_data_store(sales = f)
  expect_s3_class(store, "aurora_data_store")
  expect_identical(aurora_data_names(store), "sales")
  expect_equal(aurora_data_get(store, "sales")$x, 1:3)
})

test_that("aurora_data_get hot-reloads when the file mtime advances", {
  d <- withr::local_tempdir()
  f <- fs::path(d, "data.rds")
  saveRDS(data.frame(v = 1L), f)
  store <- aurora_data_store(d = f)

  expect_equal(aurora_data_get(store, "d")$v, 1L)

  # Rewrite with new content and a newer mtime; next get must reflect it.
  saveRDS(data.frame(v = 99L), f)
  fs::file_touch(f, modification_time = Sys.time() + 5)
  expect_equal(aurora_data_get(store, "d")$v, 99L)
})

test_that("aurora_data_get caches when the file is unchanged", {
  d <- withr::local_tempdir()
  f <- fs::path(d, "data.rds")
  saveRDS(data.frame(v = 1L), f)
  reads <- 0L
  store <- aurora_data_store(d = f)
  aurora_data_register(store, "d", f, reader = function(path) { reads <<- reads + 1L; readRDS(path) })

  aurora_data_get(store, "d")
  aurora_data_get(store, "d")
  expect_equal(reads, 1L)   # second call served from cache
})

test_that("readers are inferred from extension and overridable", {
  d <- withr::local_tempdir()
  csv <- fs::path(d, "t.csv")
  utils::write.csv(data.frame(a = 1:2, b = c("x", "y")), csv, row.names = FALSE)
  store <- aurora_data_store(t = csv)
  expect_equal(nrow(aurora_data_get(store, "t")), 2L)

  # custom reader overrides inference
  store2 <- aurora_data_store()
  aurora_data_register(store2, "raw", csv, reader = function(path) readLines(path))
  expect_true(length(aurora_data_get(store2, "raw")) >= 1)
})

test_that("aurora_data_store validates inputs", {
  expect_error(aurora_data_store("data/x.rds"), "must be named")
  d <- withr::local_tempdir()
  store <- aurora_data_store()
  expect_error(aurora_data_register(store, "x", fs::path(d, "x.weird")),
               "No reader registered")
  expect_error(aurora_data_get(store, "missing"), "Unknown dataset")
  expect_error(aurora_data_names("nope"), "aurora_data_store")
})

test_that("aurora_data_get errors clearly when the file is gone", {
  d <- withr::local_tempdir()
  f <- fs::path(d, "g.rds")
  saveRDS(1, f)
  store <- aurora_data_store(g = f)
  aurora_data_get(store, "g")
  fs::file_delete(f)
  expect_error(aurora_data_get(store, "g"), "not found")
})

test_that("data store resolves paths at register time (immune to cwd changes)", {
  d <- withr::local_tempdir()
  fs::dir_create(fs::path(d, "data"))
  saveRDS(data.frame(x = 1:3), fs::path(d, "data", "s.rds"))

  old <- setwd(d)
  store <- aurora_data_store(s = "data/s.rds")  # dir = "." -> anchored to d
  setwd(old)                                      # move cwd away from the app

  expect_equal(nrow(aurora_data_get(store, "s")), 3L)  # still reads correctly
})
