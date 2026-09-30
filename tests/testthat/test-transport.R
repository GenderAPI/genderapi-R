test_that("redirects are rejected, not followed", {
  skip_if_not_installed("webfakes")
  reset_log()
  e <- tryCatch(genderapi_name("Onur", client = fake_client("redirect")),
                genderapi_error = function(e) e)
  expect_s3_class(e, "genderapi_redirect_error")
  expect_identical(e$status, 302L)
  expect_identical(e$location, "/s/dataset/api/v2/gender")
  log <- request_log()
  expect_length(log, 1)
  expect_identical(log[[1]]$scenario, "redirect")
})

test_that("timeouts raise a transport error once, without retry", {
  skip_if_not_installed("webfakes")
  reset_log()
  started <- Sys.time()
  e <- tryCatch(genderapi_name("Onur", client = fake_client("slow", timeout = 0.5)),
                genderapi_error = function(e) e)
  expect_s3_class(e, "genderapi_transport_error")
  expect_identical(e$code, "timeout")
  expect_match(conditionMessage(e), "billed", fixed = TRUE)
  expect_lt(as.numeric(difftime(Sys.time(), started, units = "secs")), 2.8)
  expect_length(request_log(), 1)
})

test_that("connection failures raise a transport error", {
  e <- tryCatch(genderapi_name("Onur", client = genderapi_client(
    api_key = NULL, base_url = "http://127.0.0.1:1/api/v2", timeout = 2)),
    genderapi_error = function(e) e)
  expect_s3_class(e, "genderapi_transport_error")
  expect_identical(e$code, "transport_error")
})
