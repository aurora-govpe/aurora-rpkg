# App "doctor" -------------------------------------------------------------------
#
# Static checks that catch the migration pitfalls aurora learned from porting a
# real plumber-v1 app: UI code living in runtime helpers (which forces the UI
# stack into the runtime image), packages used but not declared in _aurora.yml,
# and a missing prebuilt UI. Runs at dev/scaffold time instead of failing later
# in a container.

# Packages that never need declaring (base + recommended-ish + aurora's own).
check_base_pkgs <- c(
  "base", "stats", "utils", "methods", "graphics", "grDevices", "datasets",
  "tools", "grid", "splines", "parallel", "compiler", "tcltk", "stats4",
  "plumber2", "aurora"
)

# UI/build-time tokens that should not appear in runtime helpers/routers.
check_ui_tokens <- c(
  "library(shiny", "library(bslib", "library(sass", "library(htmltools",
  "shiny::", "bslib::", "htmltools::", "bs_theme", "page_navbar",
  "page_fillable", "page_sidebar", "nav_panel", "nav_menu", "actionLink"
)

# Extract package names referenced via `pkg::` and `library()/require()` in R
# source, ignoring full-line comments.
scan_pkg_refs <- function(files) {
  if (length(files) == 0) return(character(0))
  txt <- unlist(lapply(files, readLines, warn = FALSE, encoding = "UTF-8"))
  txt <- txt[!grepl("^\\s*#", txt)]
  if (length(txt) == 0) return(character(0))
  colons <- unlist(regmatches(
    txt, gregexpr("[A-Za-z][A-Za-z0-9.]*(?=:::?)", txt, perl = TRUE)
  ))
  libs_raw <- unlist(regmatches(
    txt, gregexpr("\\b(?:library|require)\\(\\s*[\"']?[A-Za-z0-9.]+", txt, perl = TRUE)
  ))
  libs <- sub("^.*\\(\\s*[\"']?", "", libs_raw)
  unique(c(colons, libs))
}

#' Check an aurora app for common problems
#'
#' Static "doctor" for the canonical layout. Reports issues that otherwise
#' surface late (often only when building or running the container):
#'
#' * **UI code in runtime helpers** -- \pkg{shiny}/\pkg{bslib}/\pkg{htmltools}
#'   usage in `helpers/` (sourced at request time) pulls the UI stack into the
#'   runtime image. UI code belongs in `build_ui.R`/`ui_modules/` (build time).
#' * **Undeclared packages** -- packages referenced in `routers/`/`helpers/` but
#'   absent from `_aurora.yml` `packages:` (when that list is present), so the
#'   image would miss them.
#' * **Missing prebuilt UI** -- no `www/index.html` (the container serves it and
#'   does not rebuild).
#'
#' @param dir App directory (canonical aurora layout).
#'
#' @return Invisibly, a data frame of findings (`level`, `message`); also printed
#'   via \pkg{cli}.
#' @export
aurora_check <- function(dir = ".") {
  assert_is_app(dir)
  cfg <- read_config(dir)
  findings <- list()
  add <- function(level, message) {
    findings[[length(findings) + 1]] <<- list(level = level, message = message)
  }

  helpers <- helper_files(cfg)
  routers <- router_files(cfg)

  # 1. UI code in runtime helpers.
  for (f in helpers) {
    lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
    hit <- check_ui_tokens[vapply(check_ui_tokens, function(tok)
      any(grepl(tok, lines, fixed = TRUE)), logical(1))]
    if (length(hit) > 0) {
      add("warning", paste0(
        "UI code in runtime helper {.path ", fs::path_rel(f, dir), "} (",
        paste(hit, collapse = ", "),
        ") -- move it to {.path build_ui.R}/{.path ui_modules/} so the runtime ",
        "image needs no shiny/bslib. See ADR-014."
      ))
    }
  }

  # 2. Packages referenced but not declared in _aurora.yml packages:.
  if (length(cfg$packages) > 0) {
    used <- scan_pkg_refs(c(routers, helpers))
    undeclared <- setdiff(used, c(cfg$packages, check_base_pkgs))
    # UI tokens are reported by check 1; don't double-flag shiny/bslib here.
    undeclared <- setdiff(undeclared, c("shiny", "bslib", "sass", "htmltools", "bsicons"))
    if (length(undeclared) > 0) {
      add("warning", paste0(
        "Packages used in routers/helpers but missing from {.file _aurora.yml} ",
        "{.field packages}: ", paste(undeclared, collapse = ", "),
        ". Add them or the image will miss them."
      ))
    }
  } else {
    add("info", "No {.field packages} list in {.file _aurora.yml}; deps are scanned from source for the image (less reproducible).")
  }

  # 3. Prebuilt UI present?
  if (!fs::file_exists(fs::path(dir, cfg$output))) {
    add("warning", paste0(
      "No ", cfg$output, " -- build it with {.fn aurora_build_ui} ",
      "(the container serves it, it does not rebuild)."
    ))
  }

  # Report.
  cli::cli_h2("aurora check: {cfg$name}")
  if (length(findings) == 0) {
    cli::cli_alert_success("No issues found.")
  } else {
    for (fd in findings) {
      switch(fd$level,
        warning = cli::cli_alert_warning(fd$message),
        info = cli::cli_alert_info(fd$message),
        cli::cli_alert_danger(fd$message)
      )
    }
  }

  out <- if (length(findings) == 0) {
    data.frame(level = character(0), message = character(0))
  } else {
    data.frame(
      level = vapply(findings, `[[`, character(1), "level"),
      message = vapply(findings, `[[`, character(1), "message")
    )
  }
  invisible(out)
}
