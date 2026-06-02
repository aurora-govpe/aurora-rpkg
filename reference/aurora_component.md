# Wire a UI element to a JSON API endpoint

A thin markup helper: emits an htmltools element carrying its API
endpoint as a `data-endpoint` attribute (plus any extra attributes you
pass). Your app's feature JavaScript reads `element.dataset.endpoint`,
fetches it with the `window.aurora` runtime (`aurora.json(...)`), and
renders however it likes.

## Usage

``` r
aurora_component(endpoint, ..., id = NULL, tag = "div")
```

## Arguments

- endpoint:

  API path the feature JS will fetch, e.g. `"api/sales/data"`. Resolved
  against the app base path by `aurora.url()` in the runtime.

- ...:

  Passed to the underlying htmltools tag. Named arguments become
  attributes (e.g. `class`, `style`, or extra `data-*` attributes such
  as `"data-page-size" = "25"`); unnamed arguments become child tags.

- id:

  Element id, so your JS can find it (`document.getElementById`).
  Optional but recommended.

- tag:

  HTML tag name to emit. Defaults to `"div"`.

## Value

An htmltools tag.

## Details

aurora deliberately ships no rendering JavaScript: this keeps the
runtime thin (see the design invariants in `CLAUDE.md` / ADR-002 and
ADR-009) and leaves charts, tables, and maps fully under the app's
control. Use it to avoid hand-writing the `data-*` plumbing on every
element.

## Examples

``` r
aurora_component("api/sales/data", id = "vendas", style = "height:360px;")
#> <div id="vendas" data-endpoint="api/sales/data" style="height:360px;"></div>
```
