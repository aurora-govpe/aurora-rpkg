/* aurora runtime (thin) — shipped by the aurora R package.
 * Provides a small fetch wrapper that always sends credentials and exposes an
 * onUnauthorized hook. No app-specific logic lives here. */
(function (global) {
  "use strict";

  var basePath = global.location.pathname.replace(/\/$/, "");

  var aurora = {
    basePath: basePath,

    // Resolve an API path against the app base path.
    url: function (path) {
      if (/^https?:\/\//.test(path)) return path;
      if (path.charAt(0) === "/") return basePath + path;
      return basePath + "/" + path;
    },

    // Hook invoked on a 401 response. Apps override this (e.g. show a modal).
    onUnauthorized: function () {
      console.warn("[aurora] unauthorized (401)");
    },

    // fetch wrapper: includes cookies, routes 401s through onUnauthorized.
    fetch: function (path, options) {
      options = options || {};
      options.credentials = options.credentials || "include";
      return fetch(aurora.url(path), options).then(function (res) {
        if (res.status === 401) {
          try { aurora.onUnauthorized(res); } catch (e) { /* noop */ }
          throw new Error("aurora: unauthorized");
        }
        return res;
      });
    },

    // Convenience: fetch and parse JSON.
    json: function (path, options) {
      return aurora.fetch(path, options).then(function (res) { return res.json(); });
    }
  };

  global.aurora = aurora;
})(window);
