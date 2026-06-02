#' @keywords internal
"_PACKAGE"

# Internal null-coalescing operator used throughout the package.
`%||%` <- function(x, y) if (is.null(x)) y else x
