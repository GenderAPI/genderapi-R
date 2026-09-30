#' GenderAPI error conditions
#'
#' All errors raised by this package inherit from `genderapi_error`, so they
#' can be caught with `tryCatch(..., genderapi_error = function(e) ...)`.
#' More specific classes:
#'
#' * `genderapi_validation_error`: the input failed a client-side check.
#'   No request was sent and nothing was billed.
#' * `genderapi_http_error`: the API answered with HTTP 400 or higher. Fields:
#'   `status`, `code`, `title`, `detail`, `action`, `errors` (validation
#'   pointers), `documentation`, `request_id` (from the body, `meta$request_id`
#'   or the `X-Request-ID` header), `retry_after` (the `Retry-After` header as
#'   a string), `billing_status`, `usage` (`meta$usage`), `meta`, `data` (the
#'   item array of an all-failed batch), `body` (parsed JSON or `NULL`),
#'   `raw` (the response text) and `headers`.
#' * `genderapi_redirect_error`: the API answered with a 3xx redirect. It was
#'   not followed, so the key was not forwarded. Fields: `status`,
#'   `location`, `headers`.
#' * `genderapi_transport_error`: no usable response (network error or
#'   timeout). `code` is `"timeout"` or `"transport_error"`. The request may
#'   still have been processed and billed.
#' * `genderapi_response_error`: a 2xx response that is not a JSON object.
#'   `code` is `"invalid_response"`.
#'
#' The package never retries. After a 429 wait for `retry_after` seconds; the
#' next request is a new, billable operation. When `billing_status` is
#' `"unconfirmed"` or `action` is `"contact_support"`, contact support with
#' `request_id` before sending the request again. Match on `code`, never on
#' the human-readable `detail`. See [genderapi_error_catalog()].
#'
#' Error bodies can contain the submitted input. Do not log them wholesale.
#'
#' @name genderapi_error
#' @examples
#' client <- genderapi_client(api_key = NULL)
#' e <- tryCatch(genderapi_name("", client = client), genderapi_error = function(e) e)
#' class(e)
#' conditionMessage(e)
NULL

genderapi_abort <- function(message, class, ...) {
  cnd <- structure(
    class = c(class, "genderapi_error", "error", "condition"),
    list(message = message, call = NULL, ...)
  )
  stop(cnd)
}

validation_abort <- function(message) {
  genderapi_abort(message, "genderapi_validation_error",
                  code = "client_validation_error")
}

transport_abort <- function(e, path) {
  timed_out <- inherits(e, "curl_error_operation_timedout") ||
    grepl("Timeout was reached", conditionMessage(e), fixed = TRUE)
  if (!nzchar(path)) path <- "/"
  code <- if (timed_out) "timeout" else "transport_error"
  what <- if (timed_out) "timed out" else "failed without a usable response"
  genderapi_abort(
    paste0(
      "GenderAPI request to ", path, " ", what, " (", conditionMessage(e), "). ",
      "It may still have been processed and billed. The request was not retried; ",
      "check genderapi_usage() before sending it again."
    ),
    "genderapi_transport_error",
    code = code, status = NULL, parent = e
  )
}

redirect_abort <- function(status, headers, raw_text) {
  location <- header_value(headers, "location")
  genderapi_abort(
    paste0(
      "GenderAPI answered with HTTP ", status, " (redirect). Redirects are never ",
      "followed so the API key is not forwarded; check `base_url`."
    ),
    "genderapi_redirect_error",
    code = "redirect_not_followed", status = status, location = location,
    headers = headers, raw = raw_text
  )
}

response_abort <- function(status, headers, raw_text, path) {
  genderapi_abort(
    paste0(
      "GenderAPI returned HTTP ", status, " for ", path, " without a JSON object. ",
      "The request may have been processed and billed; do not retry automatically."
    ),
    "genderapi_response_error",
    code = "invalid_response", status = status,
    request_id = header_value(headers, "x-request-id"),
    headers = headers, raw = raw_text
  )
}

http_abort <- function(status, headers, body, raw_text) {
  problem <- if (is_json_object(body)) body else list()
  meta <- if (is_json_object(problem$meta)) problem$meta else NULL
  usage <- if (!is.null(meta) && is_json_object(meta$usage)) meta$usage else NULL
  request_id <- first_string(meta$request_id, problem$request_id,
                             header_value(headers, "x-request-id"))
  retry_after <- header_value(headers, "retry-after")
  code <- if (is_string(problem$code)) problem$code else NULL
  detail <- if (is_string(problem$detail)) problem$detail else NULL
  billing_status <- if (is_string(usage$billing_status)) usage$billing_status else NULL
  action <- if (is_string(problem$action)) problem$action else NULL

  msg <- paste0("GenderAPI HTTP ", status,
                if (!is.null(code)) paste0(" (", code, ")") else "",
                if (!is.null(detail)) paste0(": ", detail) else "", ".")
  hints <- character()
  if (status == 429) {
    hints <- c(hints, paste0(
      "Wait ", if (!is.null(retry_after)) paste0(retry_after, " s (Retry-After) ") else "",
      "before another request; it will be a new, billable operation."
    ))
  }
  if (identical(billing_status, "unconfirmed") || identical(action, "contact_support")) {
    hints <- c(hints, "Billing is unconfirmed or needs support: contact support with the request ID; do not retry automatically.")
  } else if (identical(action, "inspect_billing_before_retry")) {
    hints <- c(hints, "Inspect billing_status before sending another request.")
  }
  if (!is.null(billing_status)) hints <- c(hints, paste0("billing_status: ", billing_status, "."))
  if (!is.null(request_id)) hints <- c(hints, paste0("request_id: ", request_id, "."))
  if (length(hints)) msg <- paste(c(msg, hints), collapse = " ")

  genderapi_abort(
    msg, "genderapi_http_error",
    status = status,
    code = code,
    title = if (is_string(problem$title)) problem$title else NULL,
    detail = detail,
    action = action,
    errors = problem$errors,
    documentation = if (is_string(problem$documentation)) problem$documentation else NULL,
    request_id = request_id,
    retry_after = retry_after,
    billing_status = billing_status,
    usage = usage,
    meta = meta,
    data = problem$data,
    body = body,
    raw = raw_text,
    headers = headers
  )
}

header_value <- function(headers, name) {
  value <- headers[[name]]
  if (is.null(value) || !length(value)) return(NULL)
  value <- trimws(value[[length(value)]])
  if (nzchar(value)) value else NULL
}

first_string <- function(...) {
  for (x in list(...)) {
    if (is_string(x) && nzchar(x)) return(x)
  }
  NULL
}
