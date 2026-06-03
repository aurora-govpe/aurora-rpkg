# Package index

## Scaffolding

Create the canonical app layout and add routes.

- [`aurora_create_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_create_app.md)
  : Scaffold a new aurora app
- [`aurora_add_route()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_add_route.md)
  : Add an API route to an aurora app

## Build & run

Compile the UI, assemble the API, run locally.

- [`aurora_build_ui()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_ui.md)
  : Build the static UI for an aurora app

- [`aurora_app()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_app.md)
  : Assemble an aurora app as a plumber2 API

- [`aurora_run()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_run.md)
  : Run an aurora app locally

- [`aurora_config()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_config.md)
  :

  Read the app's `data/config.yml`, anchored to the app root

- [`aurora_check()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_check.md)
  : Check an aurora app for common problems

## UI

- [`aurora_component()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_component.md)
  : Wire a UI element to a JSON API endpoint

## Serializers

NULL-safe helpers for JSON responses.

- [`aurora_unbox()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_unbox.md)
  : Unbox a scalar for a JSON response, NULL-safe
- [`aurora_geojson()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_geojson.md)
  : Encode an sf object as GeoJSON for a JSON response, NULL-safe
- [`aurora_unique()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_unique.md)
  : Sorted unique non-missing values, for filter options

## Data

Globals-free, hot-reloading data store for handlers.

- [`aurora_data_store()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_store.md)
  : Create a hot-reloading data store
- [`aurora_data_register()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_register.md)
  : Register a dataset in a data store
- [`aurora_data_get()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_get.md)
  : Read a dataset from a store, reloading if the file changed
- [`aurora_data_names()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_data_names.md)
  : Names of the datasets registered in a store

## Deploy

Docker images and ShinyProxy specs.

- [`aurora_dockerfile()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_dockerfile.md)
  : Generate a Dockerfile (and .dockerignore) for an aurora app
- [`aurora_build_image()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_build_image.md)
  : Build (and optionally push) a Docker image for an aurora app
- [`aurora_shinyproxy_yaml()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_shinyproxy_yaml.md)
  : Emit a ShinyProxy app-spec block for an aurora image

## Auth

Optional JWT-cookie authentication scheme.

- [`aurora_auth_jwt()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_auth_jwt.md)
  : JWT-cookie authentication scheme
- [`aurora_jwt_token()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_token.md)
  : Mint a signed JWT for an auth scheme
- [`aurora_jwt_decode()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_decode.md)
  : Decode and verify a JWT
- [`aurora_jwt_guard()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_jwt_guard.md)
  : Guard a request, aborting with 401 unless it carries a valid token
- [`aurora_set_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md)
  [`aurora_clear_auth_cookie()`](https://aurora-govpe.github.io/aurora-rpkg/reference/aurora_set_auth_cookie.md)
  : Set or clear the auth cookie on a response
