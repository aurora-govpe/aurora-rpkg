#* Echo a message back as JSON
#*
#* Note: in plumber2 query-string values are NOT bound to named handler
#* arguments (only path `<var>` params are). Read them from the reserved
#* `query` argument instead. See dev/MIGRATION-V1-V2.md.
#* @get /api/echo/say
#* @query msg The message to echo back
#* @serializer json
function(query) {
  msg <- query$msg
  if (is.null(msg)) msg <- ""
  list(echo = msg, length = nchar(msg), time = format(Sys.time()))
}
