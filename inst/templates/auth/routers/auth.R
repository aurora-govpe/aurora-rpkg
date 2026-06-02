# Public authentication routes (NOT under /api, so the guard does not gate them).

# `%||%` fallback so this router is self-contained.
`%||%` <- function(x, y) if (is.null(x)) y else x

#* Login: verify credentials, issue the JWT cookie.
#* @post /auth/login
#* @parser json
#* @serializer json
function(request, response, body = NULL) {
  user <- body$user %||% ""
  pass <- body$pass %||% ""

  u <- find_user(user)
  ok <- !is.null(u) &&
    tryCatch(sodium::password_verify(u$hash, pass), error = function(e) FALSE)

  if (!isTRUE(ok)) {
    response$status <- 401L
    return(list(error = "Usuário ou senha inválidos."))
  }

  token <- aurora::aurora_jwt_token(auth, list(
    user       = u$name,
    secretaria = u$secretaria
  ))
  aurora::aurora_set_auth_cookie(auth, response, token, secure = secure_cookies)

  list(user = u$name, secretaria = u$secretaria)
}

#* Logout: clear the auth cookie.
#* @post /auth/logout
#* @serializer json
function(response) {
  aurora::aurora_clear_auth_cookie(auth, response, secure = secure_cookies)
  list(status = "ok")
}
