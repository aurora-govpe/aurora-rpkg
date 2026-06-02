/* app.js — orchestrator. App-authored glue: wires the DOM to feature code and
 * the aurora runtime (window.aurora from core.js). */
document.addEventListener("DOMContentLoaded", function () {
  var el = document.getElementById("health");
  if (!el) return;
  aurora.json("health")
    .then(function (d) { el.textContent = "API: " + d.status; })
    .catch(function () { el.textContent = "API indisponivel"; });
});
