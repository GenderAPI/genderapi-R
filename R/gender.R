item_types <- c("name", "email", "username")
ai_modes <- c("off", "fallback", "always")
item_arg_names <- c("type", "value", "country", "ai_mode", "force_to_genderize", "id")
item_wire_names <- c("type", "value", "country", "id", "forceToGenderize", "options")

#' Build one prediction item
#'
#' Validates the input with the cheap, certain rules of the V2 schema and
#' returns the exact wire object (`type`, `value`, `country`, `id`,
#' `forceToGenderize`, `options$ai_mode`). Invalid input raises a
#' `genderapi_validation_error`; no request is sent. The API performs the
#' authoritative checks (email syntax, country membership, trial limits).
#'
#' @param type One of `"name"`, `"email"` or `"username"`.
#' @param value The name, email address or username: 1 to 254 characters,
#'   not only whitespace, no control characters.
#' @param country Optional ISO 3166-1 alpha-2 code in upper case, such as
#'   `"TR"`. Omit it when unknown.
#' @param ai_mode Optional `"off"`, `"fallback"` or `"always"`. When omitted
#'   the server default applies: `fallback` for single requests and `off` for
#'   batch items. `fallback` costs 1 credit in total; `always` costs 2.
#' @param force_to_genderize `TRUE` to try the dataset first and, if gender
#'   is unknown, infer it from nickname or alias semantics (2 credits in
#'   total in that case). Cannot be combined with `ai_mode` `"off"` or
#'   `"always"`.
#' @param id Optional item id, 1 to 64 characters. In a batch, ids must be
#'   unique and are echoed back in each result.
#'
#' @return A list of class `genderapi_item`.
#' @export
#' @examples
#' genderapi_item("name", "Onur", country = "TR", ai_mode = "off", id = "row-1")
genderapi_item <- function(type, value, country = NULL, ai_mode = NULL,
                           force_to_genderize = FALSE, id = NULL) {
  if (!is_string(type) || !type %in% item_types) {
    validation_abort("`type` must be one of \"name\", \"email\" or \"username\".")
  }
  if (!is_string(value)) {
    validation_abort("`value` must be a single string.")
  }
  if (!validUTF8(enc2utf8(value))) {
    validation_abort("`value` must be valid UTF-8 text.")
  }
  if (!grepl("\\S", value, perl = TRUE) || nchar(value, type = "chars") > 254L) {
    validation_abort("`value` must contain 1 to 254 characters and not only whitespace.")
  }
  if (grepl("[\\x00-\\x1f\\x7f]", value, perl = TRUE)) {
    validation_abort("`value` must not contain control characters.")
  }
  if (!is.null(country) && (!is_string(country) || !grepl("^[A-Z]{2}$", country))) {
    validation_abort("`country` must be an upper-case ISO 3166-1 alpha-2 code such as \"TR\"; omit it when unknown.")
  }
  if (!is.null(ai_mode) && (!is_string(ai_mode) || !ai_mode %in% ai_modes)) {
    validation_abort("`ai_mode` must be \"off\", \"fallback\" or \"always\".")
  }
  if (is.null(force_to_genderize)) force_to_genderize <- FALSE
  if (!is.logical(force_to_genderize) || length(force_to_genderize) != 1L ||
      is.na(force_to_genderize)) {
    validation_abort("`force_to_genderize` must be TRUE or FALSE.")
  }
  if (force_to_genderize && !is.null(ai_mode) && ai_mode != "fallback") {
    validation_abort("`force_to_genderize = TRUE` cannot be combined with `ai_mode` \"off\" or \"always\".")
  }
  if (!is.null(id) && (!is_string(id) || nchar(id, type = "chars") < 1L ||
                       nchar(id, type = "chars") > 64L)) {
    validation_abort("`id` must be a string of 1 to 64 characters.")
  }

  item <- list(type = type, value = enc2utf8(value))
  if (!is.null(country)) item$country <- country
  if (!is.null(id)) item$id <- id
  if (force_to_genderize) item$forceToGenderize <- TRUE
  if (!is.null(ai_mode)) item$options <- list(ai_mode = ai_mode)
  structure(item, class = "genderapi_item")
}

#' Infer gender for one name, email address or username
#'
#' Sends one `POST /gender` request (one billable operation). The request is
#' never retried. A successful `unknown` result is billable and is returned,
#' not raised as an error.
#'
#' `genderapi_name()`, `genderapi_email()` and `genderapi_username()` are
#' shortcuts for `genderapi_gender()` with the matching `type`.
#'
#' @inheritParams genderapi_item
#' @param client A [genderapi_client()].
#'
#' @return A `genderapi_prediction`: the parsed V2 JSON as a list with
#'   `data` (the prediction) and `meta` (`request_id`, `duration_ms`,
#'   `access`, `usage`). All fields are kept as sent, including fields added
#'   by future API versions. JSON `null` becomes `NULL`. Key fields of
#'   `data`: `gender` (`"male"`, `"female"` or `NULL`), `result_status`
#'   (`"identified"` or `"unknown"`), `reason`, `confidence` with
#'   `confidence_kind` (`"observed_frequency"` or `"model_reported"`; not a
#'   calibrated probability), `sample_count`, `source`, `name`, `country`,
#'   `country_source` and `match`. Use [as.data.frame()] for a one-row data
#'   frame.
#'
#' @seealso [genderapi_batch()], [genderapi_error]
#' @export
#' @examples
#' \dontrun{
#' # Sends a request and may consume credits.
#' res <- genderapi_name("Onur", country = "TR")
#' res$data$gender
#' res$data$result_status
#' res$meta$usage$charged_credits
#' as.data.frame(res)
#' }
genderapi_gender <- function(type, value, country = NULL, ai_mode = NULL,
                             force_to_genderize = FALSE, id = NULL,
                             client = genderapi_client()) {
  item <- genderapi_item(type, value, country = country, ai_mode = ai_mode,
                         force_to_genderize = force_to_genderize, id = id)
  body <- genderapi_request(client, "POST", "/gender", unclass(item))
  check_access_mode(client, new_response(body, "genderapi_prediction"))
}

#' @rdname genderapi_gender
#' @export
genderapi_name <- function(value, country = NULL, ai_mode = NULL,
                           force_to_genderize = FALSE, id = NULL,
                           client = genderapi_client()) {
  genderapi_gender("name", value, country = country, ai_mode = ai_mode,
                   force_to_genderize = force_to_genderize, id = id,
                   client = client)
}

#' @rdname genderapi_gender
#' @export
genderapi_email <- function(value, country = NULL, ai_mode = NULL,
                            force_to_genderize = FALSE, id = NULL,
                            client = genderapi_client()) {
  genderapi_gender("email", value, country = country, ai_mode = ai_mode,
                   force_to_genderize = force_to_genderize, id = id,
                   client = client)
}

#' @rdname genderapi_gender
#' @export
genderapi_username <- function(value, country = NULL, ai_mode = NULL,
                               force_to_genderize = FALSE, id = NULL,
                               client = genderapi_client()) {
  genderapi_gender("username", value, country = country, ai_mode = ai_mode,
                   force_to_genderize = force_to_genderize, id = id,
                   client = client)
}

#' Infer gender for a batch of 1 to 50 items
#'
#' Sends one `POST /gender/batch` request with `{"items": [...]}`. Batch
#' items default to `ai_mode = "off"` on the server. The server decides the
#' limit (50 items; 10 on the IP trial). Larger jobs must be split by the
#' caller; the package never retries or splits automatically.
#'
#' A partially successful batch is returned normally (HTTP 200): inspect
#' every item. Each item has `index`, the optional `id`, `charged_credits`
#' and exactly one of `data` (a prediction) or `error` (a problem with
#' `code`). `meta$summary` has `total`, `succeeded`, `identified`, `unknown`
#' and `failed`. When every executed item fails the API answers with an
#' error status; the resulting `genderapi_http_error` keeps the item array in
#' `data`.
#'
#' Retry only failed items, and only once billing is confirmed:
#' resubmitting successful items charges them again.
#'
#' @param items The items: a list of [genderapi_item()] objects, a list of
#'   plain lists using either the argument names of [genderapi_item()] or the
#'   wire names (`type`, `value`, `country`, `id`, `forceToGenderize`,
#'   `options = list(ai_mode = ...)`), or a data frame with columns `type`,
#'   `value` and optionally `country`, `ai_mode`, `force_to_genderize`, `id`
#'   (`NA` means "not set").
#' @inheritParams genderapi_gender
#'
#' @return A `genderapi_batch`: the parsed V2 JSON with `data` (the item
#'   list) and `meta` (including `summary` and `usage`). Use
#'   [as.data.frame()] for one row per item and [genderapi_failed()] for the
#'   failed items.
#' @export
#' @examples
#' items <- list(
#'   genderapi_item("name", "Onur", country = "TR", id = "a"),
#'   genderapi_item("email", "alex@example.com", id = "b")
#' )
#' \dontrun{
#' # Sends a request and may consume credits.
#' res <- genderapi_batch(items)
#' res$meta$summary
#' as.data.frame(res)
#' genderapi_failed(res)
#' }
genderapi_batch <- function(items, client = genderapi_client()) {
  items <- normalize_items(items)
  if (length(items) < 1L || length(items) > 50L) {
    validation_abort("A batch must contain 1 to 50 items; split larger jobs yourself.")
  }
  ids <- unlist(lapply(items, function(item) item$id), use.names = FALSE)
  if (anyDuplicated(ids)) {
    validation_abort("Batch item ids must be unique.")
  }
  payload <- list(items = unname(lapply(items, unclass)))
  body <- genderapi_request(client, "POST", "/gender/batch", payload)
  check_access_mode(client, new_response(body, "genderapi_batch"))
}

normalize_items <- function(items) {
  if (is.data.frame(items)) {
    unknown <- setdiff(names(items), item_arg_names)
    if (length(unknown)) {
      validation_abort(paste0("Unsupported item column(s): ",
                              paste(unknown, collapse = ", "), "."))
    }
    rows <- lapply(seq_len(nrow(items)), function(i) {
      row <- lapply(items[i, , drop = FALSE], function(col) {
        value <- col[[1L]]
        if (is.factor(value)) value <- as.character(value)
        if (length(value) != 1L || is.na(value)) NULL else value
      })
      row[!vapply(row, is.null, logical(1))]
    })
    return(lapply(rows, item_from_list))
  }
  if (inherits(items, "genderapi_item") || !is.list(items) || !is.null(names(items))) {
    validation_abort("`items` must be an unnamed list of items or a data frame.")
  }
  lapply(items, item_from_list)
}

item_from_list <- function(x) {
  if (!is.list(x) || is.null(names(x)) || any(!nzchar(names(x)))) {
    validation_abort("Each batch item must be a named list; use genderapi_item().")
  }
  if (inherits(x, "genderapi_item")) {
    args <- unclass(x)
  } else {
    args <- x
  }
  unknown <- setdiff(names(args), union(item_arg_names, item_wire_names))
  if (length(unknown)) {
    validation_abort(paste0("Unsupported item field(s): ",
                            paste(unknown, collapse = ", "), "."))
  }
  if ("options" %in% names(args)) {
    options <- args$options
    if (!is.list(options) || !identical(names(options), "ai_mode") ||
        "ai_mode" %in% names(args)) {
      validation_abort("`options` must be list(ai_mode = ...), given once.")
    }
    args$ai_mode <- options$ai_mode
    args$options <- NULL
  }
  if ("forceToGenderize" %in% names(args)) {
    if ("force_to_genderize" %in% names(args)) {
      validation_abort("Give either `forceToGenderize` or `force_to_genderize`, not both.")
    }
    args$force_to_genderize <- args$forceToGenderize
    args$forceToGenderize <- NULL
  }
  if (is.null(args$type) || is.null(args$value)) {
    validation_abort("Each batch item needs `type` and `value`.")
  }
  do.call(genderapi_item, args)
}
