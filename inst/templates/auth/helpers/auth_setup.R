# Sourced before routers are parsed, so handlers can see `auth`, `find_user`,
# and `secure_cookies`.

# The JWT-cookie scheme. In production set AURORA_JWT_SECRET (and AURORA_ENV=prod
# behind HTTPS); the dev default is intentionally weak.
auth <- aurora::aurora_auth_jwt(
  secret = Sys.getenv("AURORA_JWT_SECRET", "dev-only-change-me"),
  expiry = 8L * 3600L
)

# Use Secure;SameSite=Strict cookies only behind HTTPS (prod).
secure_cookies <- identical(Sys.getenv("AURORA_ENV"), "prod")

# --- Demo user store -----------------------------------------------------------
# Replace this with your real store (a database, an RDS, etc.). Passwords are
# hashed with sodium; here we hash a demo password at startup. Demo login:
#   user: admin   pass: admin123
.users <- local({
  list(
    admin = list(
      name       = "admin",
      hash       = sodium::password_store("admin123"),
      secretaria = "Demonstração"
    )
  )
})

find_user <- function(name) {
  if (is.null(name) || !nzchar(name)) return(NULL)
  .users[[name]]
}
