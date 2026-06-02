# Auth gate: a header-route handler on /api/* runs before the request body is
# received and before any /api endpoint. It rejects unauthenticated requests
# with 401; otherwise it returns plumber2::Next to continue the chain. Public
# routes (/auth/*, /) are unaffected. See aurora_jwt_guard().

#* @any /api/*
#* @header
function(request) {
  aurora::aurora_jwt_guard(auth, request)
  plumber2::Next
}
