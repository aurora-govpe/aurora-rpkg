#' JWT-cookie authentication scheme
#'
#' aurora's auth is *pluggable* and never baked into [aurora_app()]'s core path.
#' This is the one provided scheme: a stateless JSON Web Token
#' signed with \pkg{jose} (HMAC) and delivered as an `HttpOnly` cookie. It is the
#' plumber2 translation of the reference app's v1 `@filter` JWT scheme.
#'
#' The companion helpers operate on the scheme object:
#' * [aurora_jwt_token()] mints a signed token (at login).
#' * [aurora_set_auth_cookie()] / [aurora_clear_auth_cookie()] manage the cookie.
#' * [aurora_jwt_guard()] is the gate: call it from a `@header` handler on
#'   `/api/*` and it rejects unauthenticated requests with a `401`.
#'
#' Auth is wired entirely in your app's annotated router files (a `@header`
#' guard + public `/auth/*` routes), so `aurora_app()` needs no auth knowledge.
#' See the `auth` template ([aurora_create_app()]).
#'
#' @param secret Secret used to sign/verify tokens (string or raw). Prefer
#'   supplying it via an environment variable rather than hardcoding.
#' @param cookie Name of the cookie carrying the token.
#' @param expiry Token lifetime in seconds.
#'
#' @return An object of class `aurora_auth_jwt`.
#' @export
#' @examples
#' auth <- aurora_auth_jwt(secret = "dev-only-secret")
#' tok <- aurora_jwt_token(auth, list(user = "alice"))
#' aurora_jwt_decode(auth, tok)$user
aurora_auth_jwt <- function(secret = Sys.getenv("AURORA_JWT_SECRET"),
                            cookie = "token",
                            expiry = 28800L) {
  if (!nzchar(secret %||% "")) {
    cli::cli_warn(c(
      "No JWT secret supplied.",
      i = "Set {.envvar AURORA_JWT_SECRET} or pass {.arg secret} explicitly."
    ))
  }
  structure(
    list(secret = secret, cookie = cookie, expiry = as.integer(expiry)),
    class = "aurora_auth_jwt"
  )
}

#' @export
print.aurora_auth_jwt <- function(x, ...) {
  cli::cli_h3("aurora JWT-cookie auth scheme")
  cli::cli_ul(c(
    "cookie: {.val {x$cookie}}",
    "expiry: {x$expiry}s",
    "secret: {if (nzchar(x$secret %||% '')) 'set' else cli::col_red('NOT set')}"
  ))
  invisible(x)
}

is_auth_jwt <- function(x) inherits(x, "aurora_auth_jwt")

assert_auth_jwt <- function(auth, call = rlang::caller_env()) {
  if (!is_auth_jwt(auth)) {
    cli::cli_abort("{.arg auth} must be an {.cls aurora_auth_jwt} object from {.fn aurora_auth_jwt}.",
                   call = call)
  }
}

#' Mint a signed JWT for an auth scheme
#'
#' Signs `claims` (plus an `exp` expiry computed from the scheme) with HMAC.
#'
#' @param auth An [aurora_auth_jwt()] scheme.
#' @param claims A named list of claims to embed (e.g. `list(user = "alice")`).
#'
#' @return The signed token as a string.
#' @export
aurora_jwt_token <- function(auth, claims = list()) {
  assert_auth_jwt(auth)
  rlang::check_installed("jose", reason = "to sign JWTs")
  exp <- as.numeric(Sys.time()) + auth$expiry
  claim <- do.call(jose::jwt_claim, c(claims, list(exp = exp)))
  jose::jwt_encode_hmac(claim, secret = auth$secret)
}

#' Decode and verify a JWT
#'
#' Returns the payload if the signature is valid and the token has not expired;
#' otherwise `NULL` (never throws).
#'
#' @param auth An [aurora_auth_jwt()] scheme.
#' @param token The token string (e.g. `request$cookies$token`).
#'
#' @return The decoded payload list, or `NULL`.
#' @export
aurora_jwt_decode <- function(auth, token) {
  assert_auth_jwt(auth)
  rlang::check_installed("jose", reason = "to verify JWTs")
  if (is.null(token) || !nzchar(token)) return(NULL)
  payload <- tryCatch(jose::jwt_decode_hmac(token, secret = auth$secret),
                      error = function(e) NULL)
  if (is.null(payload)) return(NULL)
  if (!is.null(payload$exp) && as.numeric(Sys.time()) > payload$exp) return(NULL)
  payload
}

#' Guard a request, aborting with 401 unless it carries a valid token
#'
#' Reads the scheme's cookie from `request`, verifies it, and -- if invalid or
#' absent -- stops handling with a `401 Unauthorized` via
#' [reqres::abort_unauthorized()]. On success it returns the payload invisibly.
#' Use it inside a `@header` handler on `/api/*`, returning [plumber2::Next] to
#' continue:
#'
#' ```r
#' #* @any /api/*
#' #* @header
#' function(request) {
#'   aurora_jwt_guard(auth, request)
#'   plumber2::Next
#' }
#' ```
#'
#' @param auth An [aurora_auth_jwt()] scheme.
#' @param request The reqres request object (the `request` handler argument).
#'
#' @return The decoded payload, invisibly (or aborts).
#' @export
aurora_jwt_guard <- function(auth, request) {
  assert_auth_jwt(auth)
  rlang::check_installed("reqres", reason = "to reject unauthorised requests")
  token <- request$cookies[[auth$cookie]]
  payload <- aurora_jwt_decode(auth, token)
  if (is.null(payload)) {
    reqres::abort_unauthorized("Sess\u00e3o ausente ou expirada.")
  }
  invisible(payload)
}

#' Set or clear the auth cookie on a response
#'
#' [aurora_set_auth_cookie()] writes an `HttpOnly` cookie carrying the token (at
#' login); [aurora_clear_auth_cookie()] removes it (at logout). In production
#' (HTTPS) pass `secure = TRUE` for `Secure; SameSite=Strict`; in development the
#' default uses `SameSite=Lax` so it works over plain HTTP on a different port.
#'
#' @param auth An [aurora_auth_jwt()] scheme.
#' @param response The reqres response object (the `response` handler argument).
#' @param token The token string from [aurora_jwt_token()].
#' @param secure Whether to set `Secure` + `SameSite=Strict` (use behind HTTPS).
#'
#' @return The response, invisibly.
#' @export
aurora_set_auth_cookie <- function(auth, response, token, secure = FALSE) {
  assert_auth_jwt(auth)
  response$set_cookie(
    auth$cookie, token,
    path = "/", http_only = TRUE, secure = secure,
    same_site = if (isTRUE(secure)) "Strict" else "Lax",
    max_age = auth$expiry
  )
  invisible(response)
}

#' @rdname aurora_set_auth_cookie
#' @export
aurora_clear_auth_cookie <- function(auth, response, secure = FALSE) {
  assert_auth_jwt(auth)
  # Overwrite with an immediately-expiring cookie using matching attributes.
  response$set_cookie(
    auth$cookie, "",
    path = "/", http_only = TRUE, secure = secure,
    same_site = if (isTRUE(secure)) "Strict" else "Lax",
    max_age = 0
  )
  invisible(response)
}
