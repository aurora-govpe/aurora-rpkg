/* app.js — orchestrator for example 01 */
function doEcho() {
  var m = document.getElementById("msg").value;
  aurora.json("api/echo/say?msg=" + encodeURIComponent(m)).then(function (d) {
    document.getElementById("out").textContent = JSON.stringify(d, null, 2);
  });
}
