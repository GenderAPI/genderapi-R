test_that("partial batch success is returned, not raised", {
  skip_if_not_installed("webfakes")
  reset_log()
  items <- list(
    genderapi_item("name", "Onur", country = "TR", id = "known"),
    genderapi_item("name", "zzzxxyy", id = "missing"),
    list(type = "name", value = "Alex", id = "failed", options = list(ai_mode = "always"))
  )
  res <- genderapi_batch(items, client = fake_client("batch", api_key = NULL))
  expect_s3_class(res, "genderapi_batch")
  expect_identical(res$meta$summary,
                   list(total = 3L, succeeded = 2L, identified = 1L, unknown = 1L, failed = 1L))
  expect_identical(res$meta$usage$charged_credits, 2L)
  failed <- genderapi_failed(res)
  expect_length(failed, 1)
  expect_identical(failed[[1]]$id, "failed")
  expect_identical(failed[[1]]$error$code, "ai_upstream_error")
  expect_identical(failed[[1]]$charged_credits, 0L)
  for (row in res$data) expect_true(xor(is.null(row$data), is.null(row$error)))
  df <- as.data.frame(res)
  expect_identical(df$index, 0:2)
  expect_identical(df$id, c("known", "missing", "failed"))
  expect_identical(df$gender, c("male", NA, NA))
  expect_identical(df$result_status, c("identified", "unknown", NA))
  expect_identical(df$error_code, c(NA, NA, "ai_upstream_error"))
  expect_identical(df$charged_credits, c(1L, 1L, 0L))
  expect_output(print(res), "1 failed")

  log <- request_log()
  expect_length(log, 1)
  expect_identical(log[[1]]$rest, "/gender/batch")
  sent <- jsonlite::fromJSON(log[[1]]$body, simplifyVector = FALSE)
  expect_identical(names(sent), "items")
  expect_identical(sent$items[[1]], list(type = "name", value = "Onur", country = "TR", id = "known"))
  expect_identical(sent$items[[3]], list(type = "name", value = "Alex", id = "failed",
                                         options = list(ai_mode = "always")))
})

test_that("a single-item batch is still sent as an array", {
  skip_if_not_installed("webfakes")
  reset_log()
  genderapi_batch(list(genderapi_item("name", "Onur")), client = fake_client("batch", api_key = NULL))
  sent <- request_log()[[1]]$body
  expect_identical(sent, '{"items":[{"type":"name","value":"Onur"}]}')
})

test_that("data frames are accepted as batch input", {
  skip_if_not_installed("webfakes")
  reset_log()
  df <- data.frame(type = c("name", "email"), value = c("Onur", "a@example.com"),
                   country = c("TR", NA), id = c("a", "b"), ai_mode = c(NA, "off"),
                   stringsAsFactors = FALSE)
  genderapi_batch(df, client = fake_client("batch", api_key = NULL))
  sent <- jsonlite::fromJSON(request_log()[[1]]$body, simplifyVector = FALSE)$items
  expect_identical(sent[[1]], list(type = "name", value = "Onur", country = "TR", id = "a"))
  expect_identical(sent[[2]], list(type = "email", value = "a@example.com", id = "b",
                                   options = list(ai_mode = "off")))
})

test_that("an all-failed batch raises an HTTP error that keeps data", {
  skip_if_not_installed("webfakes")
  e <- tryCatch(genderapi_batch(list(genderapi_item("name", "Alex", ai_mode = "always")),
                                client = fake_client("batchfailed")),
                genderapi_http_error = function(e) e)
  expect_s3_class(e, "genderapi_http_error")
  expect_identical(e$status, 502L)
  expect_identical(e$code, "ai_upstream_error")
  expect_identical(e$action, "inspect_billing_before_retry")
  expect_identical(e$billing_status, "confirmed")
  expect_length(e$data, 1)
  expect_identical(e$data[[1]]$error$code, "ai_upstream_error")
  expect_length(genderapi_failed(e), 1)
  expect_identical(e$body$meta$summary$failed, 1L)
})
