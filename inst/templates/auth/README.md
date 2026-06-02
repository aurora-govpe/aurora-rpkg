# aurora `auth` template

A stateless, JWT-cookie-protected aurora app. The UI is a `bslib` page with a
login overlay; the API gates everything under `/api/*` behind a signed token.

## How auth is wired (no aurora_app changes)

Everything lives in your annotated files — `aurora_app()` stays auth-agnostic:

- **`helpers/auth_setup.R`** — defines the scheme `auth <- aurora_auth_jwt(...)`,
  the dev/prod cookie flag, and a demo user store (`find_user()`). Replace the
  store with your database.
- **`routers/guard.R`** — a `@header` handler on `/api/*` that calls
  `aurora_jwt_guard(auth, request)`; unauthenticated requests get `401`, valid
  ones continue (`plumber2::Next`). Runs before any `/api` endpoint and before
  the request body is even received.
- **`routers/auth.R`** — public `POST /auth/login` (verifies with
  `sodium::password_verify`, issues the cookie via `aurora_set_auth_cookie()`)
  and `POST /auth/logout`.
- **`routers/me.R`** — an example protected endpoint (`GET /api/me`).
- **`www/js/app.js`** — reveals the app when `GET /api/me` succeeds, shows the
  login overlay on any `401` (via `aurora.onUnauthorized`), and posts
  login/logout.

## Run

```r
aurora::aurora_run(".")   # http://127.0.0.1:8000  — log in with admin / admin123
```

## Production checklist

- Set a strong `AURORA_JWT_SECRET` (never commit it).
- Set `AURORA_ENV=prod` behind HTTPS so cookies use `Secure; SameSite=Strict`.
- Replace the demo `find_user()` store with your real user table.

Requires the `jose` and `sodium` packages.
