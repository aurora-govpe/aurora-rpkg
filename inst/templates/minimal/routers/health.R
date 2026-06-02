#* Healthcheck
#* @get /health
#* @serializer json
function() {
  list(
    status  = "ok",
    service = "aurora",
    time    = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}
