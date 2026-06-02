# Helpers are sourced before the routers are parsed, so functions defined here
# are available to handlers in routers/. Keep app-wide utilities here
# (db connections, config access, formatting, themes...).

app_name <- function() "minimal"
