# cran-comments

## Submission

First submission of aurora to CRAN (version 0.1.7).

aurora is a scaffolding and deployment toolkit for stateless web apps on top
of 'plumber2': the UI ('bslib') is compiled to static HTML at build time and
'plumber2' serves it alongside JSON API routes.

## Test environments

- Local: macOS (Apple Silicon), R release
- GitHub Actions:
  - ubuntu-latest: R release, R devel, R oldrel-1
  - windows-latest: R release
  - macos-latest: R release
<!-- TODO before submitting: run devtools::check_win_devel() and
     devtools::check_mac_release() and record the results here. -->

## R CMD check results

0 errors | 0 warnings | 0 notes

(`R CMD check --as-cran`.)

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
