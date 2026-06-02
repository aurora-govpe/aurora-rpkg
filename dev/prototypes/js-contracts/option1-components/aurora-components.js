/* OPTION 1 — what aurora WOULD ship as www/js/aurora-components.js
 * A tiny hydration runtime: scans [data-aurora], fetches each endpoint via the
 * core.js fetch wrapper, and hands the data to a registered renderer.
 * Apps can register their own renderers; built-ins cover the common cases. */
(function (global) {
  "use strict";

  var renderers = {};
  function register(kind, fn) { renderers[kind] = fn; }

  // --- built-in renderers (aurora-maintained) ---
  register("echart", function (el, data) {
    var chart = echarts.init(el);
    chart.setOption({
      tooltip: { trigger: "axis" },
      xAxis: { type: "category", data: data[el.dataset.x] },
      yAxis: { type: "value" },
      series: [{ type: el.dataset.type || "bar", data: data[el.dataset.y] }]
    });
    global.addEventListener("resize", function () { chart.resize(); });
    return chart;
  });

  register("table", function (el, data) {
    // expects { columns: [...], rows: [[...], ...] }. Built with safe DOM methods
    // (textContent), never innerHTML — aurora ships this, so it owns its safety.
    var cell = function (tag, text) {
      var c = document.createElement(tag);
      c.textContent = text == null ? "" : String(text);
      return c;
    };
    var thead = document.createElement("thead");
    var htr = document.createElement("tr");
    data.columns.forEach(function (c) { htr.appendChild(cell("th", c)); });
    thead.appendChild(htr);
    var tbody = document.createElement("tbody");
    data.rows.forEach(function (r) {
      var tr = document.createElement("tr");
      r.forEach(function (v) { tr.appendChild(cell("td", v)); });
      tbody.appendChild(tr);
    });
    el.replaceChildren(thead, tbody);
  });

  // --- hydration ---
  function hydrate(root) {
    (root || document).querySelectorAll("[data-aurora]").forEach(function (el) {
      var kind = el.getAttribute("data-aurora");
      var fn = renderers[kind];
      if (!fn) { console.warn("[aurora] no renderer for", kind); return; }
      aurora.json(el.dataset.endpoint).then(function (d) {
        try { fn(el, d); } catch (e) { console.error("[aurora] render", kind, e); }
      });
    });
  }

  aurora.components = { register: register, hydrate: hydrate };
  document.addEventListener("DOMContentLoaded", function () { hydrate(); });
})(window);
