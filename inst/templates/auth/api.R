# Entry point.
#   Local dev : aurora::aurora_run(".")
#   Container : Rscript api.R   (host/port from env)
#
# Auth is wired entirely in the annotated router files (a @header guard on
# /api/* plus public /auth/* routes), so nothing auth-specific is needed here.
# Set AURORA_JWT_SECRET in the environment for a real secret.

aurora::aurora_run(
  ".",
  host = Sys.getenv("AURORA_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("AURORA_PORT", "8000"))
)
