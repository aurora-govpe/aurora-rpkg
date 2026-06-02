# Backlog / open questions / future ideas

Not scheduled. Promote to `dev/PLAN.md` with an ADR when picked up.

## Open product questions
- Dockerfile debian flavor hardcodes the PPM `jammy` repo + Ubuntu sysdep names;
  if `base` is changed to a non-jammy image they mismatch. Derive the Ubuntu
  codename (and PPM URL) from `base`, or validate/warn on mismatch.
- `pkg_sysreqs()` proved unreliable at generate time (returned empty for sf on
  this host) — aurora uses curated default sysdeps instead. Revisit if pak
  sysreqs resolution becomes dependable.

- `packages:` field in `_aurora.yml` to pin prod deps explicitly (vs scanning
  `library()`/`::`). Likely yes for reproducible images — needs ADR.
- Default port: keep 8000 (team habit) or align with plumber2's 8080?
- Should `aurora_create_app()` also `git init` and write a `.gitignore`?

## Future capabilities
- **Option B — declarative R→JS bindings.** A way to declare "this div renders a
  bar chart from /api/x" in R and have aurora emit the JS. Big scope; would be a
  sub-package. Gated behind a new ADR (would partially reverse ADR-002).
- ~~**Component helpers.**~~ RESOLVED 2026-06-01 (ADR-009): shipped the THIN
  variant `aurora_component(endpoint, ..., id, tag)` (emits `data-endpoint`, no
  rendering JS). The richer "typed renderer" middle ground (Option 1:
  `aurora_echart()` + a shipped hydration runtime) was prototyped
  (`dev/prototypes/js-contracts/`) but NOT adopted; it can be layered on top of
  `aurora_component()` later behind a new ADR if wanted.
- ~~**`aurora_data_store()` design.**~~ DONE 2026-06-01 (`R/data-store.R`).
  Self-contained store object (no globals/`<<-`); hot-reload via **lazy mtime
  check on `aurora_data_get()`** (simpler than `later` polling and stateless-
  friendly); pluggable readers by extension (rds/csv/parquet via `nanoparquet`).
  Future: DBI-backed readers; eager preload option.
- **Serializer helpers.** `safe_unbox`, `safe_geojson` (sf → geojson) as exported
  utilities so route authors don't reinvent the NULL-unbox guard.
- **`aurora_shinyproxy_yaml()`** plus a Helm/compose generator.
- **Auth schemes beyond JWT:** header API key (fireproof guard_key), OAuth/SSO.
- **Live reload** for `watch=TRUE`: rebuild UI + reload routes on file change.
- **Testing helpers:** `aurora_test_server()` that boots an app on a random port
  for `httr2` integration tests, with teardown.
