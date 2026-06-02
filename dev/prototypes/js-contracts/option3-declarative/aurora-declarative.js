/* OPTION 3 — what aurora WOULD ship: an interpreter for declared specs.
 * Apps call aurora.declare(spec) (emitted from R); on load we fetch each
 * endpoint and resolve "$.field" markers against the response, then render. */
(function (global) {
  "use strict";

  var specs = [];
  aurora.declare = function (spec) { specs.push(spec); };

  // Walk the option tree, replacing "$.field" strings with data[field].
  function resolve(node, data) {
    if (typeof node === "string" && node.slice(0, 2) === "$.") {
      return data[node.slice(2)];
    }
    if (Array.isArray(node)) {
      return node.map(function (n) { return resolve(n, data); });
    }
    if (node && typeof node === "object") {
      var out = {};
      Object.keys(node).forEach(function (k) { out[k] = resolve(node[k], data); });
      return out;
    }
    return node;
  }

  var kinds = {
    echart: function (el, spec, data) {
      var chart = echarts.init(el);
      chart.setOption(resolve(spec.option, data));
      global.addEventListener("resize", function () { chart.resize(); });
    }
  };

  document.addEventListener("DOMContentLoaded", function () {
    specs.forEach(function (spec) {
      var el = document.getElementById(spec.id);
      var render = kinds[spec.kind];
      if (!el || !render) { console.warn("[aurora] cannot render", spec); return; }
      aurora.json(spec.endpoint).then(function (d) {
        try { render(el, spec, d); } catch (e) { console.error("[aurora] declare", e); }
      });
    });
  });
})(window);
