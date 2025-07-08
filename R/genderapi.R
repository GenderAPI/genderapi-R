#' Get Gender by Name
#'
#' @param api_key Your GenderAPI.io API key.
#' @param name Name string to check.
#' @param country Optional two-letter country code (e.g. "US").
#' @param askToAI Logical. TRUE to force AI lookup, FALSE by default.
#' @param forceToGenderize Logical. TRUE to force analysis of nicknames.
#'
#' @return A list with gender prediction result.
#' @export
get_gender_by_name <- function(api_key, name, country = NULL, askToAI = FALSE, forceToGenderize = FALSE) {
  url <- "https://api.genderapi.io/api"

  payload <- list(
    name = name,
    country = country,
    askToAI = askToAI,
    forceToGenderize = forceToGenderize
  )


  payload <- payload[!sapply(payload, is.null)]


  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(200, 404)) {
    return(httr::content(res, as = "parsed"))
  } else {
    stop(paste("Unknown error. HTTP status:", status))
  }
}

#' Get Gender by Email
#'
#' @param api_key Your GenderAPI.io API key.
#' @param email Email string to check.
#' @param country Optional two-letter country code (e.g. "US").
#' @param askToAI Logical. TRUE to force AI lookup, FALSE by default.
#'
#' @return A list with gender prediction result.
#' @export
get_gender_by_email <- function(api_key, email, country = NULL, askToAI = FALSE) {
  url <- "https://api.genderapi.io/api/email"

  payload <- list(
    email = email,
    country = country,
    askToAI = askToAI
  )
  payload <- payload[!sapply(payload, is.null)]

  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(200, 404)) {
    return(httr::content(res, as = "parsed"))
  } else {
    stop(paste("Unknown error. HTTP status:", status))
  }
}

#' Get Gender by Username
#'
#' @param api_key Your GenderAPI.io API key.
#' @param username Username string to check.
#' @param country Optional two-letter country code (e.g. "US").
#' @param askToAI Logical. TRUE to force AI lookup, FALSE by default.
#' @param forceToGenderize Logical. TRUE to force analysis of nicknames.
#'
#' @return A list with gender prediction result.
#' @export
get_gender_by_username <- function(api_key, username, country = NULL, askToAI = FALSE, forceToGenderize = FALSE) {
  url <- "https://api.genderapi.io/api/username"

  payload <- list(
    username = username,
    country = country,
    askToAI = askToAI,
    forceToGenderize = forceToGenderize
  )
  payload <- payload[!sapply(payload, is.null)]

  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(500, 502, 503, 504, 408)) {
    stop(paste("Server-side error or timeout. HTTP status:", status))
  } else {
    content_text <- httr::content(res, as = "text", encoding = "UTF-8")

    if (nchar(content_text) == 0) {
      stop("Response content is empty.")
    }

    parsed <- tryCatch({
      jsonlite::fromJSON(content_text)
    }, error = function(e) {
      stop("Response content is not valid JSON.")
    })

    return(parsed)
  }
}

#' Get Gender by Name (Bulk)
#'
#' @param api_key Your GenderAPI.io API key.
#' @param data A list of named lists. Each list can have:
#'    - name (string, required)
#'    - country (string, optional)
#'    - id (string or integer, optional)
#'
#' @return A list with bulk gender prediction results.
#' @export
get_gender_by_name_bulk <- function(api_key, data) {
  if (!is.list(data) || length(data) == 0) {
    stop("`data` must be a non-empty list of records.")
  }

  if (length(data) > 100) {
    stop("Bulk name lookup cannot exceed 100 records.")
  }

  url <- "https://api.genderapi.io/api/name/multi/country"

  payload <- list(
    data = data
  )

  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(500, 502, 503, 504, 408)) {
    stop(paste("Server-side error or timeout. HTTP status:", status))
  } else {
    content_text <- httr::content(res, as = "text", encoding = "UTF-8")

    if (nchar(content_text) == 0) {
      stop("Response content is empty.")
    }

    parsed <- tryCatch({
      jsonlite::fromJSON(content_text, simplifyVector = FALSE)
    }, error = function(e) {
      stop("Response content is not valid JSON.")
    })

    return(parsed)
  }
}


#' Get Gender by Email (Bulk)
#'
#' @param api_key Your GenderAPI.io API key.
#' @param data A list of named lists. Each list can have:
#'    - email (string, required)
#'    - country (string, optional)
#'    - id (string or integer, optional)
#'
#' @return A list with bulk gender prediction results.
#' @export
get_gender_by_email_bulk <- function(api_key, data) {
  if (!is.list(data) || length(data) == 0) {
    stop("`data` must be a non-empty list of records.")
  }

  if (length(data) > 50) {
    stop("Bulk email lookup cannot exceed 50 records.")
  }

  url <- "https://api.genderapi.io/api/email/multi/country"

  payload <- list(
    data = data
  )

  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(500, 502, 503, 504, 408)) {
    stop(paste("Server-side error or timeout. HTTP status:", status))
  } else {
    content_text <- httr::content(res, as = "text", encoding = "UTF-8")

    if (nchar(content_text) == 0) {
      stop("Response content is empty.")
    }

    parsed <- tryCatch({
      jsonlite::fromJSON(content_text, simplifyVector = FALSE)
    }, error = function(e) {
      stop("Response content is not valid JSON.")
    })

    return(parsed)
  }
}


#' Get Gender by Username (Bulk)
#'
#' @param api_key Your GenderAPI.io API key.
#' @param data A list of named lists. Each list can have:
#'    - username (string, required)
#'    - country (string, optional)
#'    - id (string or integer, optional)
#'
#' @return A list with bulk gender prediction results.
#' @export
get_gender_by_username_bulk <- function(api_key, data) {
  if (!is.list(data) || length(data) == 0) {
    stop("`data` must be a non-empty list of records.")
  }

  if (length(data) > 50) {
    stop("Bulk username lookup cannot exceed 50 records.")
  }

  url <- "https://api.genderapi.io/api/username/multi/country"

  payload <- list(
    data = data
  )

  res <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(payload, auto_unbox = TRUE)
  )

  status <- httr::status_code(res)

  if (status %in% c(500, 502, 503, 504, 408)) {
    stop(paste("Server-side error or timeout. HTTP status:", status))
  } else {
    content_text <- httr::content(res, as = "text", encoding = "UTF-8")

    if (nchar(content_text) == 0) {
      stop("Response content is empty.")
    }

    parsed <- tryCatch({
      jsonlite::fromJSON(content_text, simplifyVector = FALSE)
    }, error = function(e) {
      stop("Response content is not valid JSON.")
    })

    return(parsed)
  }
}
