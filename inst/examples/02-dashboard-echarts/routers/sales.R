#* Monthly sales series for the dashboard
#* @get /api/sales/data
#* @serializer json
function() {
  list(
    categories = c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun"),
    values     = c(120, 200, 150, 80, 170, 210)
  )
}
