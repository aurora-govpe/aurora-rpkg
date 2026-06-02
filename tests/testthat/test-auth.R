# Unit tests for the JWT-cookie auth helpers ----------------------------------

test_that("jwt token round-trips and rejects tampering/expiry/absence", {
  skip_if_not_installed("jose")
  auth <- aurora_auth_jwt(secret = "test-secret", expiry = 3600L)

  tok <- aurora_jwt_token(auth, list(user = "alice", secretaria = "Demo"))
  payload <- aurora_jwt_decode(auth, tok)
  expect_identical(payload$user, "alice")
  expect_identical(payload$secretaria, "Demo")

  # wrong secret -> NULL
  expect_null(aurora_jwt_decode(aurora_auth_jwt(secret = "other"), tok))
  # absent -> NULL
  expect_null(aurora_jwt_decode(auth, NULL))
  expect_null(aurora_jwt_decode(auth, ""))
  # expired -> NULL
  expired <- aurora_jwt_token(aurora_auth_jwt(secret = "test-secret", expiry = -10L),
                              list(user = "x"))
  expect_null(aurora_jwt_decode(auth, expired))
})

test_that("aurora_jwt_guard aborts on bad token and returns payload on good", {
  skip_if_not_installed("jose")
  auth <- aurora_auth_jwt(secret = "test-secret", expiry = 3600L)
  fake_req <- function(tok = NULL) {
    list2env(list(cookies = if (!is.null(tok)) list(token = tok) else list()))
  }

  tok <- aurora_jwt_token(auth, list(user = "alice"))
  expect_identical(aurora_jwt_guard(auth, fake_req(tok))$user, "alice")

  # missing/invalid -> a reqres HTTP problem condition (401)
  expect_error(aurora_jwt_guard(auth, fake_req(NULL)), class = "reqres_problem")
  expect_error(aurora_jwt_guard(auth, fake_req("garbage")), class = "reqres_problem")
})

test_that("auth cookie helpers set the expected attributes", {
  skip_if_not_installed("reqres")
  skip_if_not_installed("fiery")
  auth <- aurora_auth_jwt(secret = "s", expiry = 100L)
  mk <- function() reqres::Response$new(reqres::Request$new(fiery::fake_request("http://x/")))
  # reqres stores cookies separately; as_list() serialises them into headers.
  set_cookie_hdr <- function(res) {
    h <- res$as_list()$headers
    paste(unlist(h[tolower(names(h)) == "set-cookie"]), collapse = " ")
  }

  res <- mk()
  aurora_set_auth_cookie(auth, res, "TOK", secure = FALSE)
  joined <- set_cookie_hdr(res)
  expect_match(joined, "token=TOK")
  expect_match(joined, "HttpOnly")
  expect_match(joined, "SameSite=Lax")   # dev default

  res2 <- mk()
  aurora_set_auth_cookie(auth, res2, "TOK", secure = TRUE)
  expect_match(set_cookie_hdr(res2), "Secure")

  res3 <- mk()
  aurora_clear_auth_cookie(auth, res3)
  expect_match(set_cookie_hdr(res3), "Max-Age=0")
})

test_that("non-scheme inputs are rejected", {
  expect_error(aurora_jwt_token(list()), "aurora_auth_jwt")
  expect_error(aurora_jwt_decode("nope", "tok"), "aurora_auth_jwt")
})

# Integration test against the auth template -----------------------------------

# Pull a named cookie out of the (possibly multiple) Set-Cookie response headers.
.cookie_from <- function(res, name) {
  h <- res$headers
  sc <- unlist(h[names(h) == "set-cookie"], use.names = FALSE)
  hit <- grep(paste0("^", name, "="), sc, value = TRUE)
  if (length(hit)) sub(";.*$", "", hit[[1]]) else NA_character_
}

test_that("auth template gates /api/*, logs in, and logs out", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("jose")
  skip_if_not_installed("sodium")
  skip_if_not_installed("fiery")

  parent <- withr::local_tempdir()
  app_dir <- fs::path(parent, "authapp")
  aurora_create_app(app_dir, template = "auth")
  pa <- aurora_app(app_dir, rebuild_ui = FALSE)$api

  post_json <- function(path, body) {
    pa$test_request(fiery::fake_request(
      paste0("http://x", path), method = "post",
      content = body, headers = list(Content_Type = "application/json")))
  }
  get_with <- function(path, cookie = NULL) {
    h <- if (!is.null(cookie)) list(Cookie = cookie) else list()
    pa$test_request(fiery::fake_request(paste0("http://x", path), headers = h))
  }

  # 1. Protected route is gated.
  expect_equal(get_with("/api/me")$status, 401L)

  # 2. Good login -> 200 + token cookie.
  rl <- post_json("/auth/login", '{"user":"admin","pass":"admin123"}')
  expect_equal(rl$status, 200L)
  tok <- .cookie_from(rl, "token")
  expect_true(!is.na(tok) && grepl("^token=", tok))

  # 3. The issued cookie unlocks the protected route.
  rme <- get_with("/api/me", cookie = tok)
  expect_equal(rme$status, 200L)
  body <- if (is.raw(rme$body)) rawToChar(rme$body) else paste(rme$body, collapse = "")
  expect_match(body, "admin")

  # 4. Bad login -> 401.
  expect_equal(post_json("/auth/login", '{"user":"admin","pass":"WRONG"}')$status, 401L)

  # 5. Logout clears the cookie (token=; Max-Age=0).
  rout <- pa$test_request(fiery::fake_request("http://x/auth/logout", method = "post"))
  expect_equal(rout$status, 200L)
  sc <- unlist(rout$headers[names(rout$headers) == "set-cookie"], use.names = FALSE)
  token_sc <- grep("^token=", sc, value = TRUE)
  expect_length(token_sc, 1L)
  expect_match(token_sc, "Max-Age=0", ignore.case = TRUE)
})
