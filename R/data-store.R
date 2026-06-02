# Hot-reloading, globals-free data store ----------------------------------------
#
# The reference app loaded RDS files into globals with `<<-` and reloaded them by
# comparing `file.info()$mtime` inside a request filter. This generalises that
# into a self-contained store object handed to handlers (no globals, no `<<-`):
# `aurora_data_get()` checks the file mtime on each access and transparently
# re-reads it if an external process (e.g. an ETL) rewrote it. Read-only data in
# memory is safe in the stateless model -- each process holds its own copy.

# Built-in readers keyed by lowercase file extension.
default_data_readers <- function() {
  list(
    rds = function(path) readRDS(path),
    csv = function(path) utils::read.csv(path, stringsAsFactors = FALSE),
    parquet = function(path) {
      rlang::check_installed("nanoparquet", reason = "to read .parquet data")
      nanoparquet::read_parquet(path)
    }
  )
}

is_data_store <- function(x) inherits(x, "aurora_data_store")

assert_data_store <- function(store, call = rlang::caller_env()) {
  if (!is_data_store(store)) {
    cli::cli_abort("{.arg store} must be an {.cls aurora_data_store} from {.fn aurora_data_store}.",
                   call = call)
  }
}

#' Create a hot-reloading data store
#'
#' Registers named datasets backed by files on disk and hands them to route
#' handlers without globals or `<<-`. Each [aurora_data_get()] checks the file's
#' modification time and transparently re-reads it if an external process (e.g.
#' an ETL job) has rewritten it -- the stateless equivalent of the reference
#' app's `carregar_bases()` mtime trick.
#'
#' Define the store once in a `helpers/*.R` file (sourced before routers are
#' parsed) and read from it in handlers:
#'
#' ```r
#' # helpers/data.R
#' store <- aurora_data_store(sales = "data/sales.rds", dir = ".")
#'
#' # routers/sales.R
#' #* @get /api/sales
#' #* @serializer json
#' function() aurora_data_get(store, "sales")
#' ```
#'
#' @param ... Named file paths to register (e.g. `sales = "data/sales.rds"`).
#'   The reader is inferred from the file extension.
#' @param dir Base directory that relative dataset paths are resolved against.
#'   Resolved to an absolute path **once, when the store is created** (not at read
#'   time), so later changes to the working directory cannot break reads. Defaults
#'   to `"."`; since the store is normally created while a `helpers/*.R` file is
#'   sourced (cwd = app root), relative paths like `"data/x.rds"` anchor to the
#'   app root. Absolute dataset paths are used as-is regardless of `dir`.
#' @param readers Named list of reader functions keyed by lowercase file
#'   extension, merged over (and overriding) the built-ins (`rds`, `csv`,
#'   `parquet`).
#'
#' @return An object of class `aurora_data_store`.
#' @export
#' @examples
#' f <- tempfile(fileext = ".rds")
#' saveRDS(data.frame(x = 1:3), f)
#' store <- aurora_data_store(demo = f)
#' aurora_data_get(store, "demo")
aurora_data_store <- function(..., dir = ".", readers = list()) {
  paths <- list(...)
  if (length(paths) > 0 && (is.null(names(paths)) || any(!nzchar(names(paths))))) {
    cli::cli_abort("All datasets passed to {.fn aurora_data_store} must be named.")
  }
  store <- new.env(parent = emptyenv())
  # Anchor to an absolute base now, so reads are immune to later cwd changes.
  store$dir <- fs::path_abs(dir)
  store$readers <- utils::modifyList(default_data_readers(), readers)
  store$registry <- list()
  store$cache <- new.env(parent = emptyenv())
  store <- structure(store, class = "aurora_data_store")
  for (nm in names(paths)) aurora_data_register(store, nm, paths[[nm]])
  store
}

#' Register a dataset in a data store
#'
#' @param store An [aurora_data_store()].
#' @param name Dataset name used in [aurora_data_get()].
#' @param path File path (resolved against the store's `dir`).
#' @param reader Optional reader function `function(path)`. If `NULL`, inferred
#'   from the file extension.
#'
#' @return The store, invisibly.
#' @export
aurora_data_register <- function(store, name, path, reader = NULL) {
  assert_data_store(store)
  if (is.null(reader)) {
    ext <- tolower(fs::path_ext(path))
    reader <- store$readers[[ext]]
    if (is.null(reader)) {
      cli::cli_abort(c(
        "No reader registered for extension {.val {ext}} (dataset {.val {name}}).",
        i = "Pass {.arg reader} or supply one via {.arg readers} in {.fn aurora_data_store}."
      ))
    }
  }
  # Resolve to an absolute path now (against the store's anchored dir) so reads
  # don't depend on the working directory at request time. Keep the original
  # `path` for messages.
  store$registry[[name]] <- list(
    path = path,
    abs = fs::path_abs(path, start = store$dir),
    reader = reader
  )
  invisible(store)
}

#' Read a dataset from a store, reloading if the file changed
#'
#' Returns the named dataset, re-reading from disk if its modification time has
#' advanced since the last read (hot reload), otherwise returning the cached
#' value.
#'
#' @param store An [aurora_data_store()].
#' @param name Registered dataset name.
#'
#' @return The dataset as returned by its reader.
#' @export
aurora_data_get <- function(store, name) {
  assert_data_store(store)
  entry <- store$registry[[name]]
  if (is.null(entry)) {
    cli::cli_abort(c(
      "Unknown dataset {.val {name}}.",
      i = "Registered: {.val {names(store$registry)}}."
    ))
  }
  abs <- entry$abs
  if (!fs::file_exists(abs)) {
    cli::cli_abort("Data file {.path {entry$path}} not found for dataset {.val {name}}.")
  }
  mtime <- as.numeric(fs::file_info(abs)$modification_time)
  cached <- store$cache[[name]]
  if (is.null(cached) || !identical(cached$mtime, mtime)) {
    store$cache[[name]] <- list(value = entry$reader(abs), mtime = mtime)
  }
  store$cache[[name]]$value
}

#' Names of the datasets registered in a store
#'
#' @param store An [aurora_data_store()].
#' @return A character vector of dataset names.
#' @export
aurora_data_names <- function(store) {
  assert_data_store(store)
  names(store$registry)
}

#' @export
print.aurora_data_store <- function(x, ...) {
  cli::cli_h3("aurora data store")
  cli::cli_ul(c(
    "dir: {.path {x$dir}}",
    "datasets: {if (length(x$registry)) paste(names(x$registry), collapse = ', ') else 'none'}"
  ))
  invisible(x)
}
