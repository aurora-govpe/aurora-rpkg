# Read a dataset from a store, reloading if the file changed

Returns the named dataset, re-reading from disk if its modification time
has advanced since the last read (hot reload), otherwise returning the
cached value.

## Usage

``` r
aurora_data_get(store, name)
```

## Arguments

- store:

  An
  [`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md).

- name:

  Registered dataset name.

## Value

The dataset as returned by its reader.
