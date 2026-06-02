# Create a hot-reloading data store

Registers named datasets backed by files on disk and hands them to route
handlers without globals or `<<-`. Each
[`aurora_data_get()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_get.md)
checks the file's modification time and transparently re-reads it if an
external process (e.g. an ETL job) has rewritten it – the stateless
equivalent of the reference app's `carregar_bases()` mtime trick.

## Usage

``` r
aurora_data_store(..., dir = ".", readers = list())
```

## Arguments

- ...:

  Named file paths to register (e.g. `sales = "data/sales.rds"`). The
  reader is inferred from the file extension.

- dir:

  Base directory that relative paths are resolved against, at read time.
  Defaults to `"."` (the process working directory). In the canonical
  deployment the app is launched from its own directory
  (`Rscript api.R`, or
  [`aurora_run()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_run.md)
  from the app dir), so relative paths like `"data/x.rds"` resolve
  correctly. Pass an absolute path if you cannot rely on the working
  directory. Absolute dataset paths are used as-is regardless of `dir`.

- readers:

  Named list of reader functions keyed by lowercase file extension,
  merged over (and overriding) the built-ins (`rds`, `csv`, `parquet`).

## Value

An object of class `aurora_data_store`.

## Details

Define the store once in a `helpers/*.R` file (sourced before routers
are parsed) and read from it in handlers:

    # helpers/data.R
    store <- aurora_data_store(sales = "data/sales.rds", dir = ".")

    # routers/sales.R
    #* @get /api/sales
    #* @serializer json
    function() aurora_data_get(store, "sales")

## Examples

``` r
f <- tempfile(fileext = ".rds")
saveRDS(data.frame(x = 1:3), f)
store <- aurora_data_store(demo = f)
aurora_data_get(store, "demo")
#>   x
#> 1 1
#> 2 2
#> 3 3
```
