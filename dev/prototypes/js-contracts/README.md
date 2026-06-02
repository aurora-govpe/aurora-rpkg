# JS integration contract — three prototypes (Step 3a)

> **DECISION (2026-06-01): Option 2 (thin) was chosen** and is now implemented as
> `aurora_component()` (`R/component.R`), with example 02 converted to it. See
> ADR-009. This doc keeps all three prototypes + the original recommendation as
> the rationale record; the recommendation below favoured Option 1, but the team
> opted for the thinnest contract (aurora ships zero rendering JS). Option 1
> remains reachable on top of `aurora_component()` later without reversing
> anything, should that ever be wanted.

Goal: decide how far aurora goes in helping apps wire `bslib` UI to `/api/*`
JSON without making the developer hand-write `fetch` + render glue for every
feature. All three prototypes render the **same** thing — an ECharts bar chart
from `api/sales/data` (like `inst/examples/02-dashboard-echarts`) — so the only
variable is the contract. Files are runnable; the emitted HTML below is real
output (`Rscript` over each `build_ui.R`).

The decision matters because it touches **ADR-002 (thin JS runtime)**. Note up
front: the rendering JS in Option 1/3 would live in a SEPARATE, opt-in file
(`aurora-components.js` / `aurora-declarative.js`), NOT in `core.js`. `core.js`
stays the minimal fetch+auth wrapper either way, so "thin core" survives; what
changes is whether aurora *also ships an optional renderer layer*.

---

## The same chart, three ways

### Option 1 — Component helpers (MEDIUM)
aurora ships `aurora_echart()`/`aurora_table()` (R) **and** a small hydration
runtime that scans `[data-aurora]`, fetches, and calls a registered renderer.

**App author R:**
```r
aurora_echart("vendas", endpoint = "api/sales/data",
              x = "categories", y = "values", type = "bar")
```
**App author JS:** *none.*
**Emitted HTML:**
```html
<div id="vendas" class="aurora-component" data-aurora="echart"
     data-endpoint="api/sales/data" data-x="categories" data-y="values"
     data-type="bar" style="height:360px;"></div>
```
aurora ships `aurora-components.js` (~45 lines) with built-in `echart`/`table`
renderers + `aurora.components.register(kind, fn)` for app-defined ones.

### Option 2 — Thin R helper only (THIN)
aurora ships only a generic markup helper. No rendering JS; `core.js` unchanged.

**App author R:**
```r
aurora_component("vendas", endpoint = "api/sales/data", style = "height:360px;")
```
**App author JS (app.js, ~14 lines per feature):**
```js
var el = document.getElementById("vendas");
aurora.json(el.dataset.endpoint).then(function (d) {
  var chart = echarts.init(el);
  chart.setOption({ tooltip:{trigger:"axis"},
    xAxis:{type:"category",data:d.categories}, yAxis:{type:"value"},
    series:[{type:"bar",data:d.values}] });
});
```
**Emitted HTML:**
```html
<div id="vendas" data-endpoint="api/sales/data" style="height:360px;"></div>
```

### Option 3 — Declarative bindings (BROAD)
aurora owns a config DSL: R expresses the full ECharts option tree with
`$.field` binding markers; aurora's runtime resolves them against the response.

**App author R:**
```r
aurora_echart_declarative("vendas", endpoint = "api/sales/data",
                          x = "categories", y = "values", type = "bar")
```
**App author JS:** *none.*
**Emitted HTML:**
```html
<div id="vendas" style="height:360px;"></div>
<script>aurora.declare({"id":"vendas","kind":"echart","endpoint":"api/sales/data",
  "option":{"tooltip":{"trigger":"axis"},
  "xAxis":{"type":"category","data":"$.categories"},"yAxis":{"type":"value"},
  "series":[{"type":"bar","data":"$.values"}]}});</script>
```
aurora ships `aurora-declarative.js` — a recursive spec interpreter.

---

## Trade-offs

| | Opt 1 — components | Opt 2 — thin | Opt 3 — declarative |
|---|---|---|---|
| App JS per feature | none (common case) | ~14 lines | none |
| App R verbosity | low | lowest | medium (full option tree) |
| What aurora owns in JS | a renderer registry + built-ins | nothing (core.js only) | a config-language interpreter |
| Flexibility / escape hatch | `register()` custom kinds; or drop to a raw div (= Opt 2) | total — it's your JS | low: limited to what the DSL serialises; custom = extend the DSL |
| Custom chart options (e.g. dataZoom, legend, color) | pass extra `data-*` or register a renderer | trivial (it's your setOption) | must teach the DSL every ECharts feature |
| Security surface | aurora owns renderer safety (built with safe DOM, no innerHTML) | app owns it | aurora owns it + arbitrary spec from R |
| ADR-002 impact | additive (opt-in file); core stays thin → **extends** ADR-002 | none → **honours** ADR-002 | partially **reverses** ADR-002 (aurora becomes a rendering framework) |
| Maintenance for aurora | medium (a few renderers) | ~zero | high (DSL must chase each lib's full API) |
| Failure mode | "no renderer for kind" → register one | none | "DSL can't express X" → recurring pressure to grow the DSL |

## Recommendation

**Option 1 (component helpers) — and it subsumes Option 2 as its escape hatch.**

Reasoning:
- It directly delivers the user's stated goal ("facilitar integração com JS"):
  the common dashboard case (chart/table from an endpoint) becomes **zero JS**.
- It keeps `core.js` thin (ADR-002): the renderer layer is a separate, optional
  `aurora-components.js`. An app that wants none of it just doesn't load it.
- The escape hatch is built in and cheap: any element WITHOUT `data-aurora` is
  yours to render in `app.js` (literally Option 2), and
  `aurora.components.register("myKind", fn)` adds a renderer without forking
  aurora. So flexibility is never lost — you opt up or down per component.
- It avoids Option 3's trap: a DSL means aurora must serialise and re-implement
  each JS library's full surface (ECharts has hundreds of options); every app
  need that the DSL can't express becomes pressure on aurora's maintainers. The
  prototype's `$.field` resolver is cute for a bar chart and a tar pit for a real
  chart.

Suggested scope for the first real cut: ship `aurora_echart()` + `aurora_table()`
(R) and `aurora-components.js` with `echart` + `table` renderers and a public
`register()`. Wire it into `aurora_create_app()` (copy `aurora-components.js`
alongside `core.js`) and convert `inst/examples/02-dashboard-echarts` to it as
the worked example. Needs a new ADR (extends ADR-002: "thin core + optional
component layer"). DO NOT put any of this in `core.js`.

## Files
- `option1-components/` — `aurora-helpers.R`, `aurora-components.js`, `build_ui.R`
- `option2-thin/` — `aurora-helpers.R`, `build_ui.R`, `app.js`
- `option3-declarative/` — `aurora-helpers.R`, `aurora-declarative.js`, `build_ui.R`
