#' @keywords internal
"_PACKAGE"

# Internal null-coalescing operator used throughout the package.
`%||%` <- function(x, y) if (is.null(x)) y else x

# Namespace copies of base functions so tests can mock the docker CLI
# (testthat::local_mocked_bindings() cannot rebind base directly).
system2 <- base::system2
Sys.which <- base::Sys.which
