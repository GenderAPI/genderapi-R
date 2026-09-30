#' Read credit usage (free)
#'
#' Sends `GET /usage`. This read is not billed. `data` holds
#' `remaining_credits` (can be negative or `NULL`), `expires_at`, and for
#' the IP trial `resets_at`, `limit` and `period_seconds`; `meta$access$mode`
#' shows whether the key or the IP trial was used.
#'
#' @inheritParams genderapi_gender
#' @return A `genderapi_usage` list with `data` and `meta`.
#' @export
#' @examples
#' \dontrun{
#' u <- genderapi_usage()
#' u$data$remaining_credits
#' u$meta$access$mode
#' }
genderapi_usage <- function(client = genderapi_client()) {
  new_response(genderapi_request(client, "GET", "/usage"), "genderapi_usage")
}

#' Validate a phone number
#'
#' Sends one `POST /phone/validate` request. It costs 1 credit, including
#' for invalid numbers, and is never retried.
#'
#' @param number Phone number, 3 to 32 characters of digits, spaces,
#'   parentheses and hyphens with an optional leading `+`.
#' @param country Optional upper-case ISO 3166-1 alpha-2 code used for
#'   numbers without an international prefix.
#' @inheritParams genderapi_gender
#' @return A `genderapi_phone` list. `data` has `valid`, `possible`, `e164`,
#'   `country` and `country_calling_code`.
#' @export
#' @examples
#' \dontrun{
#' genderapi_validate_phone("+90 212 555 01 01")$data$valid
#' }
genderapi_validate_phone <- function(number, country = NULL,
                                     client = genderapi_client()) {
  if (!is_string(number) || nchar(number) < 3L || nchar(number) > 32L ||
      !grepl("^\\+?[0-9 ()-]+$", number)) {
    validation_abort("`number` must be 3 to 32 characters: digits, spaces, parentheses, hyphens and an optional leading +.")
  }
  if (!is.null(country) && (!is_string(country) || !grepl("^[A-Z]{2}$", country))) {
    validation_abort("`country` must be an upper-case ISO 3166-1 alpha-2 code such as \"TR\"; omit it when unknown.")
  }
  payload <- list(number = number)
  if (!is.null(country)) payload$country <- country
  new_response(genderapi_request(client, "POST", "/phone/validate", payload),
               "genderapi_phone")
}

#' Read API capabilities and the error catalog
#'
#' `genderapi_capabilities()` sends `GET /` (deployment version, limits and
#' AI availability). `genderapi_error_catalog()` sends `GET /errors`, the
#' public catalog of stable error codes, HTTP statuses and recommended
#' actions. Both are unauthenticated: no API key is sent.
#'
#' @inheritParams genderapi_gender
#' @return The parsed JSON object as a list of class `genderapi_response`.
#' @export
#' @examples
#' \dontrun{
#' genderapi_capabilities()
#' catalog <- genderapi_error_catalog()
#' }
genderapi_capabilities <- function(client = genderapi_client()) {
  new_response(genderapi_request(client, "GET", "", auth = FALSE),
               "genderapi_capabilities")
}

#' @rdname genderapi_capabilities
#' @export
genderapi_error_catalog <- function(client = genderapi_client()) {
  new_response(genderapi_request(client, "GET", "/errors", auth = FALSE),
               "genderapi_error_catalog")
}
