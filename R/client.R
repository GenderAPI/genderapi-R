default_base_url <- "https://api.genderapi.io/api/v2"

#' Create a GenderAPI.io V2 client
#'
#' A client holds the API key, base URL, timeout and user agent. Creating a
#' client never sends a request. Every request function takes a `client`
#' argument that defaults to `genderapi_client()`, so setting the
#' `GENDERAPI_API_KEY` environment variable is enough for most scripts.
#'
#' Without a key (`api_key` is `NULL` or empty and `GENDERAPI_API_KEY` is
#' unset) requests are sent without an `Authorization` header and the server
#' applies its shared IP trial (10 credits per 24 hours per public IP).
#' The package has no client-side trial logic; `meta$access$mode` in each
#' response tells you which access mode the server used.
#'
#' When a key is set, the package by default checks that each successful
#' authenticated response reports `meta$access$mode == "api_key"`. If the
#' server answered through another mode (usually `"ip_trial"` because the key
#' was not recognized), a `genderapi_access_mode_error` is raised. The request
#' has already been processed and may have consumed IP-trial credits; the
#' full result is in the error's `result` field. It is never retried. Set
#' `require_api_key_access = FALSE` to return such responses normally.
#'
#' Keep keys server-side. Never put a key in browser code, a URL, a log or a
#' document shared with end users. Printing a client never shows the key.
#'
#' @param api_key API key string. Defaults to the `GENDERAPI_API_KEY`
#'   environment variable. `NULL` or `""` means no key (IP trial).
#' @param base_url API base URL. Keep the default in production. HTTPS is
#'   required; `http://` is accepted only for `localhost`, `127.0.0.1` and
#'   `[::1]` so that tests can use a local fake server.
#' @param timeout Total request timeout in seconds (default 10). A timed-out
#'   request is not retried and may still have been billed.
#' @param user_agent Optional `User-Agent` header. Defaults to
#'   `genderapi-r/<version>`.
#' @param require_api_key_access `TRUE` (default) to raise a
#'   `genderapi_access_mode_error` when a key is set but a successful
#'   response reports an access mode other than `"api_key"`. Applies to
#'   predictions, batches, usage and phone validation, never to
#'   [genderapi_capabilities()] or [genderapi_error_catalog()]. Has no effect
#'   without a key. See [genderapi_error].
#'
#' @return An object of class `genderapi_client`.
#' @export
#' @examples
#' # No request is sent here.
#' client <- genderapi_client(api_key = NULL, timeout = 5)
#' client
genderapi_client <- function(api_key = Sys.getenv("GENDERAPI_API_KEY", ""),
                             base_url = default_base_url,
                             timeout = 10,
                             user_agent = NULL,
                             require_api_key_access = TRUE) {
  if (!is.null(api_key)) {
    if (!is_string(api_key)) {
      validation_abort("`api_key` must be a single string or NULL.")
    }
    api_key <- trimws(api_key)
    if (!nzchar(api_key)) {
      api_key <- NULL
    } else if (grepl("[[:space:][:cntrl:]]", api_key)) {
      validation_abort("`api_key` must not contain whitespace or control characters.")
    }
  }
  base_url <- check_base_url(base_url)
  if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) ||
      !is.finite(timeout) || timeout <= 0) {
    validation_abort("`timeout` must be a single positive number of seconds.")
  }
  if (is.null(user_agent)) {
    user_agent <- paste0("genderapi-r/", package_version_string())
  } else if (!is_string(user_agent) || grepl("[[:cntrl:]]", user_agent)) {
    validation_abort("`user_agent` must be a single string without control characters.")
  }
  if (!is.logical(require_api_key_access) || length(require_api_key_access) != 1L ||
      is.na(require_api_key_access)) {
    validation_abort("`require_api_key_access` must be TRUE or FALSE.")
  }
  auth <- new.env(parent = emptyenv())
  auth$key <- api_key
  structure(
    list(base_url = base_url, timeout = as.numeric(timeout),
         user_agent = user_agent,
         require_api_key_access = require_api_key_access, auth = auth),
    class = "genderapi_client"
  )
}

#' @export
print.genderapi_client <- function(x, ...) {
  cat("<genderapi_client>\n")
  cat("  base_url:   ", x$base_url, "\n", sep = "")
  cat("  timeout:    ", format(x$timeout), " s\n", sep = "")
  cat("  user_agent: ", x$user_agent, "\n", sep = "")
  cat("  api_key:    ",
      if (is.null(client_key(x))) "not set (server applies the IP trial)" else "set (hidden)",
      "\n", sep = "")
  invisible(x)
}

client_key <- function(client) client$auth$key

# Raises a genderapi_access_mode_error when a key is configured, the check is
# enabled and the successful response reports another access mode. `res` is the
# complete classed result that would otherwise be returned.
check_access_mode <- function(client, res) {
  if (is.null(client_key(client)) || !isTRUE(client$require_api_key_access)) {
    return(res)
  }
  meta <- res$meta
  access <- if (is_json_object(meta) && is_json_object(meta$access)) meta$access else NULL
  if (is.null(access) || is.null(access$mode) || identical(access$mode, "api_key")) {
    return(res)
  }
  access_mode_abort(res, access)
}

check_client <- function(client) {
  if (!inherits(client, "genderapi_client")) {
    validation_abort("`client` must be created with genderapi_client().")
  }
  client
}

check_base_url <- function(base_url) {
  if (!is_string(base_url) || !nzchar(base_url) || grepl("[[:space:][:cntrl:]]", base_url)) {
    validation_abort("`base_url` must be a single URL string.")
  }
  base_url <- sub("/+$", "", base_url)
  if (grepl("?", base_url, fixed = TRUE) || grepl("#", base_url, fixed = TRUE) ||
      grepl("@", base_url, fixed = TRUE)) {
    validation_abort("`base_url` must not contain a query, fragment or credentials.")
  }
  https <- grepl("^https://[^/]+", base_url, ignore.case = TRUE)
  local_http <- grepl("^http://(localhost|127\\.0\\.0\\.1|\\[::1\\])(:[0-9]+)?(/|$)",
                      base_url, ignore.case = TRUE)
  if (!https && !local_http) {
    validation_abort(paste0(
      "`base_url` must use https://. Plain http:// is allowed only for ",
      "localhost, 127.0.0.1 and [::1] (local tests)."
    ))
  }
  base_url
}

package_version_string <- function() {
  as.character(utils::packageVersion("genderapi"))
}

# One HTTP attempt. Never retried, never follows redirects.
genderapi_request <- function(client, method, path, body = NULL, auth = TRUE) {
  check_client(client)
  url <- paste0(client$base_url, path)
  headers <- list(
    Accept = "application/json, application/problem+json",
    `User-Agent` = client$user_agent
  )
  key <- client_key(client)
  if (auth && !is.null(key)) {
    headers$Authorization <- paste("Bearer", key)
  }
  handle <- curl::new_handle()
  timeout_ms <- max(1L, as.integer(ceiling(client$timeout * 1000)))
  curl::handle_setopt(
    handle,
    followlocation = FALSE,
    timeout_ms = timeout_ms,
    connecttimeout_ms = timeout_ms,
    netrc = 0L
  )
  if (identical(method, "POST")) {
    json <- enc2utf8(as.character(jsonlite::toJSON(
      body, auto_unbox = TRUE, null = "null", na = "null", digits = NA
    )))
    headers$`Content-Type` <- "application/json"
    headers$Expect <- ""
    curl::handle_setopt(handle, post = TRUE, copypostfields = json)
  } else {
    curl::handle_setopt(handle, httpget = TRUE)
  }
  curl::handle_setheaders(handle, .list = headers)

  res <- tryCatch(
    curl::curl_fetch_memory(url, handle = handle),
    error = function(e) transport_abort(e, path)
  )
  handle_response(res, path)
}

handle_response <- function(res, path) {
  status <- res$status_code
  headers <- tryCatch(curl::parse_headers_list(res$headers),
                      error = function(e) list())
  headers$`set-cookie` <- NULL
  raw_text <- rawToChar(res$content)
  Encoding(raw_text) <- "UTF-8"
  content_type <- tolower(if (is.null(res$type)) "" else res$type)
  body <- NULL
  if (grepl("json", content_type, fixed = TRUE) && nzchar(raw_text)) {
    body <- tryCatch(jsonlite::fromJSON(raw_text, simplifyVector = FALSE),
                     error = function(e) NULL)
  }

  if (status >= 300 && status < 400) {
    redirect_abort(status, headers, raw_text)
  }
  if (status >= 400) {
    http_abort(status, headers, body, raw_text)
  }
  if (status < 200 || !is_json_object(body)) {
    response_abort(status, headers, raw_text, path)
  }
  structure(body, http = list(status = status, headers = headers))
}

new_response <- function(body, class) {
  structure(body, class = c(class, "genderapi_response"))
}

is_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

is_json_object <- function(x) {
  is.list(x) && !is.null(names(x)) && all(nzchar(names(x)))
}
