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

  if (status %in% c(200, 404)) {
    return(httr::content(res, as = "parsed"))
  } else {
    stop(paste("Unknown error. HTTP status:", status))
  }
}