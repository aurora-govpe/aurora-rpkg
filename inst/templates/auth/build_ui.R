library(bslib)
library(htmltools)

build_ui <- function() {
  # Login overlay — shown until app.js confirms a session (via GET /api/me).
  login_overlay <- tags$div(
    id = "login-overlay",
    class = "aurora-login-overlay",
    tags$div(
      class = "card shadow p-4 aurora-login-card",
      tags$h4("Entrar", class = "mb-3"),
      tags$div(class = "mb-2",
        tags$label("Usuário", `for` = "user", class = "form-label"),
        tags$input(type = "text", id = "user", class = "form-control", value = "admin")),
      tags$div(class = "mb-3",
        tags$label("Senha", `for` = "pass", class = "form-label"),
        tags$input(type = "password", id = "pass", class = "form-control", value = "admin123")),
      tags$button("Entrar", id = "login-go", class = "btn btn-primary w-100",
                  onclick = "auroraLogin()"),
      tags$div(id = "login-error", class = "text-danger small mt-2"),
      tags$div(class = "text-muted small mt-3", "Demo: admin / admin123")
    )
  )

  # Protected content — hidden until authenticated.
  content <- tags$div(
    id = "app-content", style = "display:none;",
    card(
      card_header("Área protegida"),
      card_body(
        tags$p(tags$span("Olá, "), tags$strong(id = "whoami", "")),
        tags$button("Sair", class = "btn btn-outline-secondary btn-sm",
                    onclick = "auroraLogout()")
      )
    )
  )

  tagList(
    tags$head(tags$link(rel = "stylesheet", href = "style.css")),
    page_fillable(
      theme = bs_theme(version = 5, preset = "flatly"),
      login_overlay,
      content
    ),
    tags$script(src = "js/core.js"),
    tags$script(src = "js/app.js")
  )
}
