http_error <- function(scenario, fun = function(client) genderapi_name("Onur", client = client)) {
  tryCatch(fun(fake_client(scenario)), genderapi_error = function(e) e)
}

test_that("401 exposes a structured problem", {
  skip_if_not_installed("webfakes")
  e <- http_error("e401")
  expect_s3_class(e, c("genderapi_http_error", "genderapi_error", "error"))
  expect_identical(e$status, 401L)
  expect_identical(e$code, "invalid_api_key")
  expect_identical(e$action, "check_credentials")
  expect_identical(e$title, "invalid api key")
  expect_identical(e$request_id, "body-meta-req-1")
  expect_identical(e$billing_status, "not_charged")
  expect_match(e$raw, "invalid_api_key", fixed = TRUE)
  expect_false(grepl(test_key, conditionMessage(e), fixed = TRUE))
})

test_that("403 insufficient credits", {
  skip_if_not_installed("webfakes")
  e <- http_error("e403")
  expect_identical(e$status, 403L)
  expect_identical(e$code, "insufficient_credits")
  expect_identical(e$action, "add_credits_or_wait_for_reset")
  expect_identical(e$detail, "At least one starting credit is required.")
  expect_identical(e$usage$remaining_credits, 0L)
  expect_identical(e$request_id, "11111111-1111-4111-8111-111111111111")
})

test_that("422 exposes validation pointers", {
  skip_if_not_installed("webfakes")
  e <- http_error("e422", function(client) genderapi_email("not-an-email", client = client))
  expect_identical(e$status, 422L)
  expect_identical(e$code, "validation_error")
  expect_identical(e$errors, list(list(pointer = "/value", message = "Invalid email address.")))
  expect_null(e$usage$remaining_credits)
})

test_that("429 surfaces Retry-After and is not retried", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- http_error("e429")
  expect_identical(e$status, 429L)
  expect_identical(e$code, "rate_limit_exceeded")
  expect_identical(e$retry_after, "7")
  expect_match(conditionMessage(e), "Retry-After", fixed = TRUE)
  expect_length(request_log(), 1)
})

test_that("502 prediction failure is raised once with billing status", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- http_error("e502")
  expect_identical(e$status, 502L)
  expect_identical(e$code, "ai_upstream_error")
  expect_identical(e$billing_status, "confirmed")
  expect_length(request_log(), 1)
})

test_that("non-JSON proxy error keeps the raw body and header request id", {
  skip_if_not_installed("webfakes")
  e <- http_error("e502html")
  expect_s3_class(e, "genderapi_http_error")
  expect_identical(e$status, 502L)
  expect_null(e$code)
  expect_null(e$body)
  expect_match(e$raw, "Bad Gateway", fixed = TRUE)
  expect_identical(e$request_id, "hdr-req-1")
})

test_that("503 unconfirmed billing is reported and never retried", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- http_error("e503")
  expect_identical(e$status, 503L)
  expect_identical(e$code, "billing_reconciliation_required")
  expect_identical(e$action, "contact_support")
  expect_identical(e$billing_status, "unconfirmed")
  expect_null(e$usage$charged_credits)
  expect_match(conditionMessage(e), "contact support", fixed = TRUE)
  expect_match(conditionMessage(e), "11111111-1111-4111-8111-111111111111", fixed = TRUE)
  expect_length(request_log(), 1)
})

test_that("2xx responses that are not a JSON object are errors", {
  skip_if_not_installed("webfakes")
  e <- http_error("notjson")
  expect_s3_class(e, "genderapi_response_error")
  expect_identical(e$code, "invalid_response")
  e <- http_error("jsonarray")
  expect_s3_class(e, "genderapi_response_error")
})
