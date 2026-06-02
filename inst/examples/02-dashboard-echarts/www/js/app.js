/* app.js — orchestrator for example 02 (ECharts).
 * Reads the endpoint from the element's data-endpoint (set by
 * aurora_component() in build_ui.R), so the API path lives in one place. */
document.addEventListener("DOMContentLoaded", function () {
  var el = document.getElementById("chart");
  var chart = echarts.init(el);
  aurora.json(el.dataset.endpoint).then(function (d) {
    chart.setOption({
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: d.categories },
      yAxis: { type: "value" },
      series: [{ type: "bar", data: d.values }]
    });
  });
  window.addEventListener("resize", function () { chart.resize(); });
});
