# Entry point.
#   Local dev : aurora::aurora_run(".")  (or source this file)
#   Container : Rscript api.R            (host/port come from env)
#
# Assembly is convention-based: aurora builds the UI from build_ui.R, sources
# helpers/, parses routers/, and serves www/. No hand-wiring needed here.

aurora::aurora_run(
  ".",
  host = Sys.getenv("AURORA_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("AURORA_PORT", "8000"))
)
