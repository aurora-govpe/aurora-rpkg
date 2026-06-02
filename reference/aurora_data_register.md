# Register a dataset in a data store

Register a dataset in a data store

## Usage

``` r
aurora_data_register(store, name, path, reader = NULL)
```

## Arguments

- store:

  An
  [`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md).

- name:

  Dataset name used in
  [`aurora_data_get()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_get.md).

- path:

  File path (resolved against the store's `dir`).

- reader:

  Optional reader function `function(path)`. If `NULL`, inferred from
  the file extension.

## Value

The store, invisibly.
