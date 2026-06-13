# cran-comments

## Submission

Resubmission of aurora to CRAN (version 0.1.10).

The previous submission (0.1.9) was flagged by the incoming pre-test for a
moved URL (301): `README.md` linked to `https://posit-dev.github.io/plumber2/`,
which now redirects to `https://plumber2.posit.co/`. The README has been
updated to the canonical target URL.

aurora is a scaffolding and deployment toolkit for stateless web apps on top
of 'plumber2': the UI ('bslib') is compiled to static HTML at build time and
'plumber2' serves it alongside JSON API routes.

## Test environments

- Local: macOS (Apple Silicon), R 4.5 -- 0 errors | 0 warnings | 0 notes
- GitHub Actions: ubuntu-latest (R release, devel, oldrel-1), windows-latest
  (R release), macos-latest (R release) -- all OK
- win-builder (R-devel) -- 1 NOTE (see below)

macOS is covered by the GitHub Actions macos-latest runner and the local
Apple Silicon check above.

## R CMD check results

The only NOTE is from win-builder's CRAN incoming feasibility check:

* New submission / Maintainer: 'Andre Leite <leite@castlab.org>'.
  Expected for a first-time submission.

* Possibly misspelled words in DESCRIPTION: "Dockerfiles", "UI". These are
  not misspellings -- "Dockerfile(s)" is the standard name of Docker's build
  recipe file, and "UI" is the usual abbreviation for user interface.

The 301 URL flagged by the previous incoming pre-test
(https://posit-dev.github.io/plumber2/ in README.md) has been corrected to its
canonical target, https://plumber2.posit.co/. No other URLs redirect.

## Downstream dependencies

There are none: this is a new package.

## Notes for the reviewers

- Functions that drive external tooling (the `docker` CLI in
  `aurora_build_image()`, a running server in `aurora_run()`) fail fast with
  an informative error when the tool is absent and are exercised in tests via
  mocks, not by invoking Docker.
- All examples are self-contained: they build strings/HTML or use
  `tempfile()`; none starts a server, touches the network, or writes
  outside the temp directory.
