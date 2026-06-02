# Release checklist

Cutting an aurora release. `0.1.0` is the first tag.

## Pre-flight (all green before tagging)
- [ ] `devtools::document()` — `man/` + `NAMESPACE` regenerated, no diff left.
- [ ] `devtools::test()` — all pass.
- [ ] `devtools::check()` — **0 errors / 0 warnings**. One NOTE is expected
      (hidden template dotfiles `.dockerignore`/`.gitkeep`); it is intentional.
- [ ] `pkgdown::build_site()` builds clean (sitrep all ok).
- [ ] `DESCRIPTION` `Version:` matches the tag (no `.9000` dev suffix).
- [ ] `NEWS.md` top heading is the release version with a dated summary.

## Tag & publish (run in a real git checkout — this sandbox isn't one)
```sh
git add -A && git commit -m "aurora 0.1.0"
git tag v0.1.0
git push origin main --tags
```
- [ ] On GitHub: enable Pages (Settings → Pages → source: `gh-pages` branch).
- [ ] The `pkgdown` workflow deploys the site; the `R-CMD-check` matrix runs.
- [ ] Create a GitHub Release from the `v0.1.0` tag (paste the `NEWS.md` section).

## After the tag
- [ ] Bump `DESCRIPTION` to the next dev version (`0.1.0.9000`) and add a new
      `# aurora 0.1.0.9000 (development)` heading to `NEWS.md`.
- [ ] (Optional) Pin the Dockerfile install to the tag: pass
      `aurora_dockerfile(aurora_source = "segpr-ndgr/aurora@v0.1.0")` for
      reproducible images.

## Not blocking 0.1.0 (tracked in dev/PLAN.md / BACKLOG.md)
- Real `docker build` validation of a generated Dockerfile (needs Docker).
- Gallery screenshots; brand.yml web-font bundling check.
- `dashboard` template; DBI-backed data-store reader; expose `data/config.yml`.
