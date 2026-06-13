# cran-comments

## Submission

First submission of aurora to CRAN (version 0.1.9).

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
  Expected for a first submission.

* Possibly misspelled words in DESCRIPTION: "Dockerfiles", "UI". These are
  not misspellings -- "Dockerfile(s)" is the standard name of Docker's build
  recipe file, and "UI" is the usual abbreviation for user interface.

The URL flagged by an earlier win-builder run
(https://aurora-govpe.github.io/aurora-rpkg, a 301 redirect) has been corrected
to the canonical form with a trailing slash.

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
