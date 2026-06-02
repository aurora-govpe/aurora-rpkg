# A protected endpoint. It lives under /api, so the @header guard in guard.R has
# already verified the token by the time this runs. We re-decode the cookie to
# return the current user (header-route handlers don't pass data downstream).

#* Who am I — returns the logged-in user from the token.
#* @get /api/me
#* @serializer json
function(request) {
  payload <- aurora::aurora_jwt_decode(auth, request$cookies[[auth$cookie]])
  list(
    user       = payload$user,
    secretaria = payload$secretaria
  )
}
