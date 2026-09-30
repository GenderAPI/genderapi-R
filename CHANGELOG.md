# Changelog

## 2.0.0 - 2026-09-30

### Breaking

- The package now targets the GenderAPI.io **V2** API (`https://api.genderapi.io/api/v2`). The V1 request fields, routes and flat responses are no longer used.
- `get_gender_by_name()`, `get_gender_by_email()`, `get_gender_by_username()` and the three `*_bulk()` functions are defunct; calling them raises an error that names the replacement and how to install 1.x (`remotes::install_version("genderapi", "1.0.3")`). See "Migrating from 1.x" in the README.
- Responses are the parsed V2 JSON (`data`, `meta`). `probability` is replaced by `confidence` plus `confidence_kind`, `used_credits` by `meta$usage$charged_credits`.
- HTTP errors are raised as structured `genderapi_http_error` conditions instead of plain `stop()` messages or returned lists.
- Requires R >= 4.1. `httr` is replaced by `curl` and `jsonlite`.

### Added

- `genderapi_client()` with the `GENDERAPI_API_KEY` environment variable, a configurable timeout (default 10 s) and an HTTPS-only base URL (plain HTTP only for localhost tests).
- `genderapi_gender()`, `genderapi_name()`, `genderapi_email()`, `genderapi_username()`, `genderapi_item()`, `genderapi_batch()` (1-50 items, list or data frame input), `genderapi_usage()`, `genderapi_validate_phone()`, `genderapi_capabilities()`, `genderapi_error_catalog()`, `genderapi_failed()` and `as.data.frame()` methods.
- Client-side validation of the cheap V2 schema rules before any request.
- Condition classes `genderapi_validation_error`, `genderapi_http_error`, `genderapi_redirect_error`, `genderapi_transport_error` and `genderapi_response_error`, exposing `status`, `code`, `detail`, `action`, `errors`, `request_id`, `retry_after` and `billing_status`.
- Works without a key: the server applies its shared IP trial.
- `genderapi_client(require_api_key_access = TRUE)`: when a key is set, a successful prediction, batch, usage or phone response whose `meta$access$mode` is not `"api_key"` raises `genderapi_access_mode_error` (`code` `unexpected_access_mode`, fields `access_mode`, `access_reason`, `result`, `status`, `request_id`). The request has already been processed and may have consumed IP-trial credits; it is not retried. Set `require_api_key_access = FALSE` to opt out.

### Safety

- No automatic retries of any request, including after 429 or a timeout.
- Redirects are never followed.
- The API key is sent only in the `Authorization: Bearer` header and never printed.

### V1 availability

- 1.x (V1 API) stays available and installable indefinitely; no deprecation or shutdown is planned. To keep using it, pin 1.x: `remotes::install_version("genderapi", "1.0.3")`. The source stays on the `v1` branch.

## 1.0.3

- V1 API client. Still available and installable; see the `v1` branch.
