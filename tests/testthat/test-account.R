test_that("usage is a GET with auth", {
  skip_if_not_installed("webfakes")
  reset_log()
  u <- genderapi_usage(client = fake_client("usage-key"))
  expect_s3_class(u, "genderapi_usage")
  expect_identical(u$data$remaining_credits, 9L)
  expect_identical(u$meta$usage$billing_status, "not_charged")
  expect_identical(u$meta$usage$resets_at, "2026-09-26T12:00:00.000Z")
  expect_identical(u$meta$access$mode, "api_key")
  r <- request_log()[[1]]
  expect_identical(r$method, "GET")
  expect_identical(r$rest, "/usage")
  expect_identical(r$authorization, paste("Bearer", test_key))
  expect_output(print(u), "not_charged")
})

test_that("phone validation posts number and country", {
  skip_if_not_installed("webfakes")
  reset_log()
  p <- genderapi_validate_phone("+90 (212) 555-01-01", country = "TR", client = fake_client("phone-key"))
  expect_s3_class(p, "genderapi_phone")
  expect_false(p$data$valid)
  expect_null(p$data$e164)
  r <- request_log()[[1]]
  expect_identical(r$rest, "/phone/validate")
  expect_identical(jsonlite::fromJSON(r$body, simplifyVector = FALSE),
                   list(number = "+90 (212) 555-01-01", country = "TR"))
})

test_that("capabilities and error catalog are unauthenticated GETs", {
  skip_if_not_installed("webfakes")
  reset_log()
  caps <- genderapi_capabilities(client = fake_client("caps"))
  expect_identical(caps$version, "2.0.0")
  cat <- genderapi_error_catalog(client = fake_client("errors"))
  expect_identical(cat$invalid_api_key$action, "check_credentials")
  log <- request_log()
  expect_identical(vapply(log, `[[`, "", "rest"), c("", "/errors"))
  expect_true(all(vapply(log, function(r) is.null(r$authorization), logical(1))))
  expect_true(all(vapply(log, function(r) r$method == "GET", logical(1))))
})
