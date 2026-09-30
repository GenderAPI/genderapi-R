#' genderapi: Official 'GenderAPI.io' V2 Client
#'
#' Server-side R client for the 'GenderAPI.io' V2 API
#' (`https://api.genderapi.io/api/v2`). It infers gender from names, email
#' addresses and usernames, runs batches of up to 50 items, reads the free
#' usage endpoint and validates phone numbers.
#'
#' Results are inferences, not verified identity, and can be `unknown`
#' (`gender` is `NULL`). `confidence` is returned exactly as the API sends it
#' and is not a calibrated probability; read it together with
#' `confidence_kind`.
#'
#' @section Safety rules:
#' * Every prediction or phone request is sent exactly once. The package
#'   never retries automatically, not even after HTTP 429, a timeout or a lost
#'   response: a request whose response was lost may still have been billed.
#' * Redirects are never followed, so the API key is never forwarded to
#'   another host. A 3xx response raises a `genderapi_redirect_error`.
#' * The default timeout is 10 seconds (see [genderapi_client()]).
#' * The base URL must use HTTPS; plain HTTP is accepted only for
#'   `localhost`, `127.0.0.1` and `[::1]` (local tests).
#' * Loading the package or creating a client never sends a request.
#' * The API key is sent only in the `Authorization: Bearer` header, never in
#'   a URL, and is never printed. Keep keys on the server; never embed them
#'   in browser code or in documents shared with end users.
#'
#' @section API key and IP trial:
#' The key is taken from the `api_key` argument of [genderapi_client()] or
#' from the `GENDERAPI_API_KEY` environment variable. Without a key the
#' server applies its shared IP trial (10 credits per 24 hours for all
#' clients behind the same public IP); the package does not implement any
#' trial logic itself. Check `meta$access$mode` in every response.
#'
#' @seealso <https://www.genderapi.io/api-documentation>,
#'   <https://www.genderapi.io/docs/v2/responses>,
#'   <https://www.genderapi.io/docs/v2/errors-and-retries>
#' @keywords internal
"_PACKAGE"
