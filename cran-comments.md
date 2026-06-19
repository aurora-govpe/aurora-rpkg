# cran-comments

## Submission

Resubmission of aurora to CRAN (version 0.1.12), addressing the three points
raised by Benjamin Altmann in the manual review of 0.1.11:

1. **References in DESCRIPTION.** aurora is a scaffolding/deployment toolkit and
   does not implement a published statistical method, so there is no
   methods reference to cite. The Description field now includes an auto-linked
   reference to the underlying web framework it builds on,
   <https://plumber2.posit.co/> (no space after `https:`).

2. **Writing to the user's home filespace / default paths.** The two functions
   that can write a file, `aurora_shinyproxy_yaml()` and `aurora_ruscker_yaml()`,
   no longer carry a default output path: `file` now defaults to `NULL` and an
   explicit path is required when `write = TRUE` (they also default to
   `write = FALSE`, returning the YAML as a string). No function writes to
   `getwd()` or the home filespace by default. All examples build strings/HTML
   or write under `tempdir()`; all tests write under `withr::local_tempdir()`;
   all vignette code chunks are `eval = FALSE`.

3. **Modifying `.GlobalEnv`.** Package code no longer touches the global
   environment. `aurora_app()` previously sourced an app's `helpers/*.R` into
   `.GlobalEnv` so its 'plumber2' route handlers could resolve them; it now
   sources them into a dedicated environment and parses each router with that
   environment as the handler-lookup parent, so nothing is assigned in
   `.GlobalEnv`.

aurora is a scaffolding and deployment toolkit for stateless web apps on top
of 'plumber2': the UI ('bslib') is compiled to static HTML at build time and
'plumber2' serves it alongside JSON API routes.

## Test environments

- Local: macOS (Apple Silicon), R 4.6 -- 0 errors | 0 warnings | 0 notes
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

No URLs redirect.

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
</content>
