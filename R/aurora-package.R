#' @keywords internal
"_PACKAGE"

# Internal null-coalescing operator used throughout the package.
`%||%` <- function(x, y) if (is.null(x)) y else x

# Thin wrappers over base so tests can mock the docker CLI
# (testthat::local_mocked_bindings() cannot rebind base directly; a plain
# copy of the closure trips R CMD check's .Internal scan).
system2 <- function(...) base::system2(...)
Sys.which <- function(...) base::Sys.which(...)
