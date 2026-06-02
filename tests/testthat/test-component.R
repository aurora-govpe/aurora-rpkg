test_that("aurora_component emits an element wired to the endpoint", {
  html <- as.character(aurora_component("api/sales/data", id = "vendas"))
  expect_match(html, "data-endpoint=\"api/sales/data\"", fixed = TRUE)
  expect_match(html, "id=\"vendas\"", fixed = TRUE)
  expect_match(html, "^<div", )
})

test_that("aurora_component passes through extra attributes and tag", {
  html <- as.character(
    aurora_component("api/x", id = "t", tag = "table",
                     class = "table", `data-page-size` = "25")
  )
  expect_match(html, "^<table", )
  expect_match(html, "class=\"table\"", fixed = TRUE)
  expect_match(html, "data-page-size=\"25\"", fixed = TRUE)
})

test_that("aurora_component omits id when not supplied", {
  html <- as.character(aurora_component("api/x"))
  expect_false(grepl("id=", html, fixed = TRUE))
})

test_that("aurora_component validates endpoint", {
  expect_error(aurora_component(""), "non-empty string")
  expect_error(aurora_component(c("a", "b")), "non-empty string")
  expect_error(aurora_component(123), "non-empty string")
})
