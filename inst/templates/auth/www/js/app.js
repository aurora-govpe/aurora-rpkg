/* app.js — auth orchestration. Uses the thin window.aurora runtime (core.js).
 * Login/logout are plain fetches (login deliberately bypasses aurora.fetch,
 * which throws on the 401 a failed login returns). The 401 hook reveals the
 * login overlay whenever any /api call finds the session missing/expired. */
document.addEventListener("DOMContentLoaded", function () {
  var overlay = document.getElementById("login-overlay");
  var content = document.getElementById("app-content");
  var who = document.getElementById("whoami");
  var err = document.getElementById("login-error");

  function showLogin() {
    overlay.style.display = "flex";
    if (content) content.style.display = "none";
  }
  function showApp(user) {
    overlay.style.display = "none";
    if (content) content.style.display = "block";
    if (who && user) who.textContent = user;
  }

  // Any /api 401 (e.g. session expiry) brings back the login overlay.
  aurora.onUnauthorized = showLogin;

  // Probe the session on load: if the cookie is valid, reveal the app.
  aurora.json("api/me")
    .then(function (d) { showApp(d.user); })
    .catch(function () { /* not logged in — overlay stays */ });

  window.auroraLogin = function () {
    err.textContent = "";
    var body = JSON.stringify({
      user: document.getElementById("user").value,
      pass: document.getElementById("pass").value
    });
    fetch(aurora.url("auth/login"), {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: body
    })
      .then(function (r) { return r.json().then(function (d) { return { ok: r.ok, d: d }; }); })
      .then(function (res) {
        if (res.ok) showApp(res.d.user);
        else err.textContent = res.d.error || "Falha no login.";
      })
      .catch(function () { err.textContent = "Erro de conexão."; });
  };

  window.auroraLogout = function () {
    fetch(aurora.url("auth/logout"), { method: "POST", credentials: "include" })
      .then(showLogin)
      .catch(showLogin);
  };
});
