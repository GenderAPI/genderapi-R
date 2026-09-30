# genderapi (R) 2.0.0

Official GenderAPI.io V2 client for R. It calls the V2 API at `https://api.genderapi.io/api/v2` to infer gender from names, email addresses and usernames, run batches, read credit usage and validate phone numbers.

Results are inferences, not verified identity. They can be `unknown` (`gender` is `NULL`). `confidence` is not a calibrated probability.

> **Version 2.0.0 is a breaking release.** The 1.x functions (`get_gender_by_name()` and friends) used the V1 API and are now defunct. 1.x (V1) is in maintenance on the [`v1` branch](https://github.com/GenderAPI/genderapi-R/tree/v1); the V1 API itself remains available. See [Migrating from 1.x](#migrating-from-1x).

- API documentation: <https://www.genderapi.io/api-documentation>
- V2 guides: [authentication](https://www.genderapi.io/docs/v2/authentication), [request parameters](https://www.genderapi.io/docs/v2/request-parameters), [AI options](https://www.genderapi.io/docs/v2/ai-options), [responses](https://www.genderapi.io/docs/v2/responses), [batch](https://www.genderapi.io/docs/v2/batch), [credits and usage](https://www.genderapi.io/docs/v2/credits-and-usage), [errors and retries](https://www.genderapi.io/docs/v2/errors-and-retries), [phone validation](https://www.genderapi.io/docs/v2/phone-validation), [migration](https://www.genderapi.io/docs/v2/migration)
- Machine-readable: [OpenAPI](https://api.genderapi.io/api/v2/openapi.json), [error catalog](https://api.genderapi.io/api/v2/errors)

## Installation

```r
install.packages("genderapi")          # from CRAN, once 2.0.0 is published there

# or the development version from this branch
# install.packages("remotes")
remotes::install_github("GenderAPI/genderapi-R", ref = "v2")
```

Requires R >= 4.1 and the `curl` and `jsonlite` packages.

## Quick start

Set the key in the server environment (for example in `~/.Renviron` or your deployment secrets), not in code:

```sh
GENDERAPI_API_KEY=your_api_key
```

```r
library(genderapi)

# Single prediction (one billable operation)
res <- genderapi_name("Onur", country = "TR")
res$data$gender            # "male", "female" or NULL
res$data$result_status     # "identified" or "unknown"
res$data$confidence        # 0-1, read with res$data$confidence_kind
res$meta$usage             # billing_status, charged_credits, remaining_credits, ...
as.data.frame(res)         # one row, NULL becomes NA

genderapi_email("alex@example.com")
genderapi_username("prenses", force_to_genderize = TRUE)

# Batch of 1-50 items (one billable operation)
items <- list(
  genderapi_item("name", "Onur", country = "TR", id = "row-1"),
  genderapi_item("email", "alex@example.com", id = "row-2"),
  genderapi_item("username", "prenses", ai_mode = "fallback", id = "row-3")
)
batch <- genderapi_batch(items)
batch$meta$summary         # total, succeeded, identified, unknown, failed
as.data.frame(batch)       # one row per item, in submission order
genderapi_failed(batch)    # items that carry an error instead of data

# A data frame works too (columns type, value, country, ai_mode, force_to_genderize, id)
genderapi_batch(data.frame(type = "name", value = c("Onur", "Ayse"), id = c("a", "b")))

# Usage (free)
u <- genderapi_usage()
u$data$remaining_credits
u$meta$access$mode         # "api_key" or "ip_trial"
```

Other functions: `genderapi_gender(type, value, ...)` (the generic form of the three shortcuts), `genderapi_validate_phone(number, country = NULL)` (1 credit, including invalid numbers), `genderapi_capabilities()` and `genderapi_error_catalog()` (public, no key sent).

## Public API

| Function | HTTP |
| --- | --- |
| `genderapi_client(api_key, base_url, timeout, user_agent)` | none (never sends a request) |
| `genderapi_gender(type, value, country, ai_mode, force_to_genderize, id, client)` | `POST /gender` |
| `genderapi_name()`, `genderapi_email()`, `genderapi_username()` | `POST /gender` |
| `genderapi_item(type, value, country, ai_mode, force_to_genderize, id)` | none (builds and validates a batch item) |
| `genderapi_batch(items, client)` | `POST /gender/batch` |
| `genderapi_usage(client)` | `GET /usage` (free) |
| `genderapi_validate_phone(number, country, client)` | `POST /phone/validate` |
| `genderapi_capabilities(client)` | `GET /` (no auth) |
| `genderapi_error_catalog(client)` | `GET /errors` (no auth) |
| `genderapi_failed(x)`, `as.data.frame(x)` | none (helpers for results) |

Every request function takes `client = genderapi_client()` as its last argument, so the environment variable is enough for most scripts.

## Options

```r
client <- genderapi_client(
  api_key = Sys.getenv("GENDERAPI_API_KEY"),   # default; NULL or "" means no key
  timeout = 10                                 # seconds, default 10
)
genderapi_name("Onur", client = client)
```

Request fields (sent with their exact V2 wire names):

| Argument | Wire field | Rules |
| --- | --- | --- |
| `type` | `type` | `"name"`, `"email"` or `"username"` |
| `value` | `value` | 1 to 254 characters, not only whitespace, no control characters |
| `country` | `country` | optional upper-case ISO 3166-1 alpha-2 code, such as `"TR"`; omit when unknown |
| `ai_mode` | `options.ai_mode` | optional `"off"`, `"fallback"` or `"always"`. Server default: `fallback` for single requests, `off` for batch items |
| `force_to_genderize` | `forceToGenderize` | `TRUE` tries the dataset first, then nickname-aware AI. Not combinable with `ai_mode` `"off"` or `"always"` |
| `id` | `id` | optional, 1 to 64 characters, unique within a batch |

These cheap checks run before any request; a failure raises `genderapi_validation_error` and nothing is sent. The API performs the authoritative validation (email syntax, country membership, trial batch limit).

Tariffs (decided by the server): dataset results and automatic AI fallback cost 1 credit in total, including unknown results; `ai_mode = "always"` costs 2; `force_to_genderize = TRUE` costs 1 when the dataset resolves the gender and 2 in total when AI is used. A positive starting balance is enough, so a 2-credit request can leave the balance at -1.

## Response fields

Functions return the parsed V2 JSON as a list, with every field kept (including fields added later) and JSON `null` as `NULL`.

Prediction `data`:

| Field | Meaning |
| --- | --- |
| `gender` | `"male"`, `"female"` or `NULL` |
| `result_status` | `"identified"` or `"unknown"` (an inference status, not identity verification) |
| `reason` | `NULL` when identified; `not_found`, `no_name_candidate`, `ambiguous` or `insufficient_evidence` |
| `confidence`, `confidence_kind` | 0-1 score and its kind: `observed_frequency` (dataset share) or `model_reported` (AI score, not calibrated). Returned unchanged; not a percentage |
| `sample_count` | dataset sample size; `NULL` for AI |
| `source` | `dataset`, `ai` or `none` |
| `name`, `country`, `country_source` | returned name, country and where the country came from (`dataset`, `ai_association` or `NULL`) |
| `match` | `name`, `method` (`normalized`, `token`, `substring`, `model_inference`), `scope` (`country`, `global`), `country` |
| `input` | echo of the submitted input |

`meta`:

| Field | Meaning |
| --- | --- |
| `request_id`, `duration_ms` | reference for support and timing |
| `access$mode` | `api_key`, `ip_trial` or `unauthenticated`; `access$reason` explains trial access |
| `usage$billing_status` | `not_charged`, `confirmed` or `unconfirmed` |
| `usage$charged_credits` | credits charged by this operation; `NULL` when unconfirmed |
| `usage$remaining_credits` | balance at completion; can be negative or `NULL` |
| `usage$resets_at`, `limit`, `period_seconds` | IP-trial window, `NULL` otherwise |
| `summary` (batch) | `total`, `succeeded`, `identified`, `unknown`, `failed` |

Batch `data` is a list of items with `index`, the optional `id`, `charged_credits` and exactly one of `data` (a prediction) or `error` (a problem with `code`).

## Errors

All errors inherit from `genderapi_error`:

| Class | When | Useful fields |
| --- | --- | --- |
| `genderapi_validation_error` | client-side input check failed; no request sent | message |
| `genderapi_http_error` | HTTP 400 or higher | `status`, `code`, `title`, `detail`, `action`, `errors` (validation pointers), `request_id`, `retry_after`, `billing_status`, `usage`, `data` (all-failed batch items), `body`, `raw`, `headers` |
| `genderapi_redirect_error` | HTTP 3xx; not followed | `status`, `location` |
| `genderapi_transport_error` | network failure or timeout (`code` is `timeout` or `transport_error`) | message |
| `genderapi_response_error` | 2xx without a JSON object | `status`, `raw` |

```r
res <- tryCatch(
  genderapi_name("Onur"),
  genderapi_http_error = function(e) {
    if (identical(e$code, "rate_limit_exceeded")) message("Wait ", e$retry_after, " s")
    if (identical(e$billing_status, "unconfirmed")) message("Contact support with ", e$request_id)
    NULL
  }
)
```

Match on `code`, never on the human-readable `detail`. `request_id` comes from the problem body, `meta$request_id` or the `X-Request-ID` header. Error bodies can contain the submitted input: do not log them wholesale.

Common statuses: 401 invalid key, 403 insufficient credits or restricted key, 422 invalid fields (see `errors`), 429 rate or concurrency limit (see `retry_after`), 502 provider failure, 503 dependency unavailable or billing reconciliation required, 504 prediction timeout.

## Billing and no-retry rules

- **The package never retries.** Not after a timeout, a lost response, a 5xx or a 429. A request whose response was lost may still have been processed and billed; check `genderapi_usage()` before sending it again.
- **429:** wait for `retry_after` seconds. The next request is a new operation with normal charges.
- **`billing_status == "unconfirmed"` or `action == "contact_support"`:** contact support with `request_id` before retrying.
- **Prediction failures (502/503/504):** inspect `billing_status` and fix the cause before sending another request.
- **Partial batch success is not an error.** Retry only the failed items (`genderapi_failed()`), and only once billing is confirmed. Resubmitting successful items charges them again.
- **Redirects are never followed**, so the key is never forwarded to another host.
- The default timeout is 10 seconds (`genderapi_client(timeout = ...)`).

## IP trial (no key)

Without a key the package sends no `Authorization` header and the server applies its shared IP trial: 10 credits per 24 hours, shared by every client behind the same public IP, with at most 10 items per batch. The package has no client-side trial logic. Missing, malformed or unknown keys may fall back to the trial; disabled, expired or restricted keys do not. Check `meta$access$mode` to see which access mode was used.

## Server-side only

Use this package on servers, in scheduled jobs or in your own analysis environment. Never embed an API key in browser code, a Shiny UI sent to clients, a shared notebook or a document. The key is sent only in the `Authorization: Bearer` header, never in a URL, and printing a client does not show it. The base URL must use HTTPS; `http://` is accepted only for `localhost`, `127.0.0.1` and `[::1]` for local tests.

## Migrating from 1.x

| 1.x (V1) | 2.0.0 (V2) |
| --- | --- |
| `get_gender_by_name(api_key, name, ...)` | `genderapi_name(value, ...)` or `genderapi_gender("name", value, ...)` |
| `get_gender_by_email(api_key, email, ...)` | `genderapi_email(value, ...)` |
| `get_gender_by_username(api_key, username, ...)` | `genderapi_username(value, ...)` |
| `get_gender_by_*_bulk(api_key, data)` | `genderapi_batch(items)` (1-50 mixed items) |
| `api_key` argument on every call | `genderapi_client(api_key = ...)` or `GENDERAPI_API_KEY` |
| V1 routes `/api`, `/api/email`, `/api/username`, `/api/*/multi/country` | `POST /api/v2/gender` with `type` and `value`; `POST /api/v2/gender/batch` with `items` |
| `askToAI = TRUE` | `ai_mode = "always"` (2 credits) or `"fallback"` (the single-request default) |
| `forceToGenderize` (name, username) | `force_to_genderize` for all three types; dataset first, then nickname-aware AI |
| flat response fields | `data` for the result, `meta` for access and billing |
| `probability` (percentage) | `data$confidence` (0-1) plus `data$confidence_kind`; not a calibrated probability |
| `total_names` | `data$sample_count` (nullable; `NULL` for AI) |
| `q`, `duration` | `data$input`, `meta$duration_ms` |
| `status` / `errno` in the body | HTTP status plus problem `code`, `action` and `errors` in `genderapi_http_error` |
| `used_credits` | `meta$usage$charged_credits` (plus `billing_status`) |
| `remaining_credits`, `expires` | `meta$usage$remaining_credits`; `genderapi_usage()` for `expires_at`/`resets_at` |
| `httr` dependency | `curl` + `jsonlite` |

V1 and V2 share the same key and credit balance. Changing only the URL is not enough: V2 uses a different request and response contract.

## Development

```r
install.packages(c("curl", "jsonlite", "testthat", "webfakes", "roxygen2"))
roxygen2::roxygenise()
testthat::test_local()
```

```sh
R CMD build .
R CMD check --as-cran --no-manual genderapi_2.0.0.tar.gz
```

Tests run against a local fake server (`webfakes`); they never call the real API and never spend credits.

## Releasing to CRAN (manual)

CRAN has no token-based publishing, so a CRAN release requires a **manual submission** by the maintainer. The `publish` GitHub workflow, triggered by a `v*` tag, only builds the source tarball, runs `R CMD check --as-cran` and attaches the tarball as a workflow artifact; it does not submit anything.

1. Update `Version` in `DESCRIPTION` and `CHANGELOG.md`, then run the check above with no errors or warnings.
2. Submit `genderapi_<version>.tar.gz` at <https://cran.r-project.org/submit.html> (or `devtools::submit_cran()`).
3. CRAN sends the confirmation link to the maintainer email in `DESCRIPTION` (`Authors@R`, role `cre`: currently onurozturk1980@gmail.com). Only that address can confirm the submission; change the `cre` entry first if the maintainer changes.
4. After acceptance, tag the release (`v<version>`).

## License

MIT. See [LICENSE](LICENSE).
