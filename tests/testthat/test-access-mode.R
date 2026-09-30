test_that("a key with an ip_trial response raises genderapi_access_mode_error", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- tryCatch(genderapi_name("Onur", country = "TR", client = fake_client("dataset")),
                genderapi_error = function(e) e)
  expect_s3_class(e, "genderapi_access_mode_error")
  expect_s3_class(e, "genderapi_error")
  expect_identical(e$code, "unexpected_access_mode")
  expect_identical(e$access_mode, "ip_trial")
  expect_identical(e$access_reason, "api_key_missing")
  expect_identical(e$status, 200L)
  expect_identical(e$request_id, "11111111-1111-4111-8111-111111111111")
  expect_identical(
    conditionMessage(e),
    paste0("Expected API-key access but the response reports access mode \"ip_trial\". ",
           "Check your API key; this request may have consumed IP-trial credits.")
  )
  expect_false(grepl(test_key, conditionMessage(e), fixed = TRUE))
  expect_s3_class(e$result, "genderapi_prediction")
  fx <- read_fixture("gender-dataset")
  expect_identical(unclass(e$result)[c("data", "meta")], fx[c("data", "meta")])
  expect_identical(e$result$meta$usage$charged_credits, 1L)
  log <- request_log()
  expect_length(log, 1)
  expect_identical(log[[1]]$authorization, paste("Bearer", test_key))
})

test_that("without a key an ip_trial response is returned normally", {
  skip_if_not_installed("webfakes")
  res <- genderapi_name("Onur", client = fake_client("dataset", api_key = NULL))
  expect_s3_class(res, "genderapi_prediction")
  expect_identical(res$meta$access$mode, "ip_trial")
})

test_that("require_api_key_access = FALSE returns the ip_trial response", {
  skip_if_not_installed("webfakes")
  reset_log()
  res <- genderapi_name("Onur", client = fake_client("dataset", require_api_key_access = FALSE))
  expect_identical(res$meta$access$mode, "ip_trial")
  expect_identical(res$data$gender, "male")
  expect_length(request_log(), 1)
  expect_error(genderapi_client(require_api_key_access = NA), class = "genderapi_validation_error")
  expect_error(genderapi_client(require_api_key_access = "no"), class = "genderapi_validation_error")
})

test_that("api_key access and responses without access metadata pass", {
  skip_if_not_installed("webfakes")
  res <- genderapi_name("Onur", client = fake_client("dataset-key"))
  expect_identical(res$meta$access$mode, "api_key")
  expect_s3_class(genderapi_name("Onur", client = fake_client("echo")), "genderapi_prediction")
})

test_that("a batch with top-level ip_trial access raises", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- tryCatch(genderapi_batch(list(genderapi_item("name", "Onur")),
                                client = fake_client("batch")),
                genderapi_error = function(e) e)
  expect_s3_class(e, "genderapi_access_mode_error")
  expect_identical(e$access_mode, "ip_trial")
  expect_s3_class(e$result, "genderapi_batch")
  expect_identical(e$result$meta$summary$failed, 1L)
  expect_length(request_log(), 1)
})

test_that("usage and phone validation are checked too", {
  skip_if_not_installed("webfakes")
  expect_error(genderapi_usage(client = fake_client("usage")),
               class = "genderapi_access_mode_error")
  expect_error(genderapi_validate_phone("+902125550101", client = fake_client("phone")),
               class = "genderapi_access_mode_error")
})

test_that("capabilities and the error catalog are never checked", {
  skip_if_not_installed("webfakes")
  # Unauthenticated endpoints: a dataset-shaped ip_trial body must not raise.
  expect_s3_class(genderapi_capabilities(client = fake_client("dataset")),
                  "genderapi_capabilities")
  expect_s3_class(genderapi_error_catalog(client = fake_client("dataset")),
                  "genderapi_error_catalog")
})
