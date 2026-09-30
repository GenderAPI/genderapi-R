#' Defunct V1 functions
#'
#' The V1 functions of genderapi 1.x were removed in 2.0.0 because the V2
#' API uses different routes, request fields and responses. Calling one of
#' them raises an error that names the replacement:
#'
#' | 1.x | 2.0.0 |
#' | --- | --- |
#' | `get_gender_by_name()` | [genderapi_name()] |
#' | `get_gender_by_email()` | [genderapi_email()] |
#' | `get_gender_by_username()` | [genderapi_username()] |
#' | `get_gender_by_name_bulk()`, `get_gender_by_email_bulk()`, `get_gender_by_username_bulk()` | [genderapi_batch()] |
#'
#' The 1.x releases remain on CRAN's archive and on the `v1` branch of the
#' repository.
#'
#' @param ... Ignored.
#' @name genderapi-defunct
#' @keywords internal
NULL

v1_defunct <- function(old, new) {
  .Defunct(new = new, package = "genderapi", msg = paste0(
    "`", old, "()` was removed in genderapi 2.0.0 (V2 API). Use `", new,
    "()` instead; see ?`genderapi-defunct` for the migration table."
  ))
}

#' @rdname genderapi-defunct
#' @export
get_gender_by_name <- function(...) v1_defunct("get_gender_by_name", "genderapi_name")

#' @rdname genderapi-defunct
#' @export
get_gender_by_email <- function(...) v1_defunct("get_gender_by_email", "genderapi_email")

#' @rdname genderapi-defunct
#' @export
get_gender_by_username <- function(...) v1_defunct("get_gender_by_username", "genderapi_username")

#' @rdname genderapi-defunct
#' @export
get_gender_by_name_bulk <- function(...) v1_defunct("get_gender_by_name_bulk", "genderapi_batch")

#' @rdname genderapi-defunct
#' @export
get_gender_by_email_bulk <- function(...) v1_defunct("get_gender_by_email_bulk", "genderapi_batch")

#' @rdname genderapi-defunct
#' @export
get_gender_by_username_bulk <- function(...) v1_defunct("get_gender_by_username_bulk", "genderapi_batch")
