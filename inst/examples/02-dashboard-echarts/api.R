aurora::aurora_run(".",
  host = Sys.getenv("AURORA_HOST", "127.0.0.1"),
  port = as.integer(Sys.getenv("AURORA_PORT", "8000")))
