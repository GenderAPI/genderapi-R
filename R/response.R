#' Convert GenderAPI results to a data frame
#'
#' Flattens a prediction (one row) or a batch (one row per item, in
#' submission order) into a data frame. JSON `null` becomes `NA`.
#' `confidence` is copied unchanged; it is not converted into a percentage
#' or probability. The original list keeps every field, including fields not
#' shown here.
#'
#' Columns: `index`, `id`, `charged_credits` (batch only), `input_type`,
#' `input_value`, `gender`, `result_status`, `reason`, `confidence`,
#' `confidence_kind`, `sample_count`, `source`, `name`, `country`,
#' `country_source`, `match_name`, `match_method`, `match_scope`,
#' `match_country`, and for batches `error_status`, `error_code`,
#' `error_detail`.
#'
#' @param x A `genderapi_prediction` or `genderapi_batch`.
#' @param row.names,optional Ignored; present for compatibility with the
#'   generic.
#' @param ... Ignored.
#' @return A data frame.
#' @name as.data.frame.genderapi
#' @examples
#' res <- structure(
#'   list(data = list(gender = NULL, result_status = "unknown",
#'                    reason = "not_found", confidence = NULL,
#'                    confidence_kind = NULL, source = "none"),
#'        meta = list()),
#'   class = c("genderapi_prediction", "genderapi_response")
#' )
#' as.data.frame(res)
NULL

#' @rdname as.data.frame.genderapi
#' @export
as.data.frame.genderapi_prediction <- function(x, row.names = NULL, optional = FALSE, ...) {
  as.data.frame(prediction_row(x$data), stringsAsFactors = FALSE)
}

#' @rdname as.data.frame.genderapi
#' @export
as.data.frame.genderapi_batch <- function(x, row.names = NULL, optional = FALSE, ...) {
  batch_frame(x$data)
}

batch_frame <- function(rows) {
  if (!length(rows)) {
    empty <- c(list(index = integer(), id = character(), charged_credits = integer()),
               lapply(prediction_row(NULL), function(v) v[0]),
               list(error_status = integer(), error_code = character(),
                    error_detail = character()))
    return(as.data.frame(empty, stringsAsFactors = FALSE))
  }
  frames <- lapply(rows, function(row) {
    error <- if (is.list(row$error)) row$error else NULL
    as.data.frame(c(
      list(index = as_int(row$index), id = as_chr(row$id),
           charged_credits = as_int(row$charged_credits)),
      prediction_row(if (is.list(row$data)) row$data else NULL),
      list(error_status = as_int(error$status), error_code = as_chr(error$code),
           error_detail = as_chr(error$detail))
    ), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, frames)
  rownames(out) <- NULL
  out
}

prediction_row <- function(d) {
  input <- if (is.list(d$input)) d$input else NULL
  match <- if (is.list(d$match)) d$match else NULL
  list(
    input_type = as_chr(input$type),
    input_value = as_chr(input$value),
    gender = as_chr(d$gender),
    result_status = as_chr(d$result_status),
    reason = as_chr(d$reason),
    confidence = as_num(d$confidence),
    confidence_kind = as_chr(d$confidence_kind),
    sample_count = as_int(d$sample_count),
    source = as_chr(d$source),
    name = as_chr(d$name),
    country = as_chr(d$country),
    country_source = as_chr(d$country_source),
    match_name = as_chr(match$name),
    match_method = as_chr(match$method),
    match_scope = as_chr(match$scope),
    match_country = as_chr(match$country)
  )
}

as_chr <- function(x) if (is.null(x) || length(x) != 1L || is.list(x)) NA_character_ else as.character(x)
as_num <- function(x) if (is.null(x) || length(x) != 1L || !is.numeric(x)) NA_real_ else as.numeric(x)
as_int <- function(x) if (is.null(x) || length(x) != 1L || !is.numeric(x)) NA_integer_ else as.integer(x)

#' Failed items of a batch
#'
#' Returns the items that carry an `error` instead of `data`. Works on a
#' `genderapi_batch` (partial success) and on the `genderapi_http_error`
#' raised when every executed item failed. Retry failed items only after
#' billing is confirmed, and never resubmit successful items: they would be
#' charged again.
#'
#' @param x A `genderapi_batch` or a `genderapi_http_error` from
#'   [genderapi_batch()].
#' @return A list of items, each with `index`, optional `id`,
#'   `charged_credits` and `error` (a problem with `code`, `status`, `detail`
#'   and `action`). An empty list when nothing failed.
#' @export
#' @examples
#' res <- structure(
#'   list(data = list(
#'     list(index = 0L, id = "a", charged_credits = 1L,
#'          data = list(gender = "male", result_status = "identified")),
#'     list(index = 1L, id = "b", charged_credits = 0L,
#'          error = list(code = "ai_upstream_error", status = 502L))
#'   ), meta = list()),
#'   class = c("genderapi_batch", "genderapi_response")
#' )
#' genderapi_failed(res)
genderapi_failed <- function(x) {
  rows <- x$data
  if (!is.list(rows) || is_json_object(rows)) return(list())
  Filter(function(row) is.list(row) && !is.null(row$error), rows)
}

#' @export
print.genderapi_response <- function(x, ...) {
  cat("<", class(x)[[1L]], ">\n", sep = "")
  print_body(x)
  print_meta(x$meta)
  invisible(x)
}

#' @export
print.genderapi_prediction <- function(x, ...) {
  d <- x$data
  cat("<genderapi_prediction>\n")
  status <- as_chr(d$result_status)
  if (identical(status, "identified")) {
    cat("  result:  identified, gender ", as_chr(d$gender), "\n", sep = "")
    cat("  confidence: ", format(as_num(d$confidence)), " (", as_chr(d$confidence_kind),
        "; not a calibrated probability)\n", sep = "")
  } else {
    cat("  result:  ", if (is.na(status)) "?" else status,
        ", gender NULL, reason ", as_chr(d$reason), "\n", sep = "")
  }
  cat("  source:  ", as_chr(d$source), "\n", sep = "")
  print_meta(x$meta)
  invisible(x)
}

#' @export
print.genderapi_batch <- function(x, ...) {
  s <- x$meta$summary
  cat("<genderapi_batch>\n")
  if (is.list(s)) {
    cat("  items: ", as_int(s$total), " total, ", as_int(s$succeeded), " succeeded (",
        as_int(s$identified), " identified, ", as_int(s$unknown), " unknown), ",
        as_int(s$failed), " failed\n", sep = "")
  } else {
    cat("  items: ", length(x$data), "\n", sep = "")
  }
  print_meta(x$meta)
  cat("  Use as.data.frame() for rows and genderapi_failed() for failed items.\n")
  invisible(x)
}

print_body <- function(x) {
  d <- x$data
  if (is_json_object(d)) {
    for (n in names(d)) {
      v <- d[[n]]
      shown <- if (is.null(v)) "NULL" else if (is.list(v)) "<list>" else paste(format(v), collapse = ", ")
      cat("  ", n, ": ", shown, "\n", sep = "")
    }
  } else if (is.null(d)) {
    cat("  fields: ", paste(names(x), collapse = ", "), "\n", sep = "")
  }
}

print_meta <- function(meta) {
  if (!is.list(meta)) return(invisible())
  u <- meta$usage
  if (is.list(u)) {
    cat("  billing: ", as_chr(u$billing_status), ", charged ", as_int(u$charged_credits),
        ", remaining ", as_int(u$remaining_credits), "\n", sep = "")
  }
  if (is.list(meta$access)) cat("  access:  ", as_chr(meta$access$mode), "\n", sep = "")
  if (!is.null(meta$request_id)) cat("  request_id: ", as_chr(meta$request_id), "\n", sep = "")
  invisible()
}
