/* OPTION 2 — what the APP AUTHOR writes (JS side). aurora ships none of this.
 * Full control, full responsibility. ~14 lines per feature. */
document.addEventListener("DOMContentLoaded", function () {
  var el = document.getElementById("vendas");
  aurora.json(el.dataset.endpoint).then(function (d) {
    var chart = echarts.init(el);
    chart.setOption({
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: d.categories },
      yAxis: { type: "value" },
      series: [{ type: "bar", data: d.values }]
    });
    window.addEventListener("resize", function () { chart.resize(); });
  });
});
