test_that("constructing a client makes no request and hides the key", {
  skip_if_not_installed("webfakes")
  reset_log()
  client <- fake_client("dataset")
  expect_s3_class(client, "genderapi_client")
  out <- paste(capture.output(print(client)), collapse = "\n")
  expect_false(grepl(test_key, out, fixed = TRUE))
  expect_match(out, "set (hidden)", fixed = TRUE)
  expect_false(grepl(test_key, paste(capture.output(str(client)), collapse = "\n"), fixed = TRUE))
  expect_length(request_log(), 0)
})

test_that("the key comes from GENDERAPI_API_KEY and is optional", {
  withr_env <- Sys.getenv("GENDERAPI_API_KEY", unset = NA)
  on.exit(if (is.na(withr_env)) Sys.unsetenv("GENDERAPI_API_KEY") else Sys.setenv(GENDERAPI_API_KEY = withr_env))
  Sys.setenv(GENDERAPI_API_KEY = "env-key-123")
  expect_identical(genderapi:::client_key(genderapi_client()), "env-key-123")
  Sys.setenv(GENDERAPI_API_KEY = " env-key-123\n")
  expect_identical(genderapi:::client_key(genderapi_client()), "env-key-123")
  Sys.unsetenv("GENDERAPI_API_KEY")
  expect_null(genderapi:::client_key(genderapi_client()))
  expect_null(genderapi:::client_key(genderapi_client(api_key = NULL)))
  expect_match(paste(capture.output(print(genderapi_client(api_key = ""))), collapse = ""),
               "IP trial", fixed = TRUE)
})

test_that("defaults: HTTPS production URL, 10 s timeout, versioned user agent", {
  client <- genderapi_client(api_key = NULL)
  expect_identical(client$base_url, "https://api.genderapi.io/api/v2")
  expect_identical(client$timeout, 10)
  expect_identical(client$user_agent, paste0("genderapi-r/", packageVersion("genderapi")))
  expect_identical(client$user_agent, "genderapi-r/2.0.0")
})

test_that("plain HTTP is rejected except for local test hosts", {
  expect_error(genderapi_client(base_url = "http://api.genderapi.io/api/v2"),
               class = "genderapi_validation_error")
  expect_error(genderapi_client(base_url = "http://localhost.example.com/api/v2"),
               class = "genderapi_validation_error")
  expect_error(genderapi_client(base_url = "ftp://api.genderapi.io"),
               class = "genderapi_validation_error")
  expect_error(genderapi_client(base_url = "https://api.genderapi.io/api/v2?key=x"),
               class = "genderapi_validation_error")
  expect_error(genderapi_client(base_url = "https://user:pw@api.genderapi.io/api/v2"),
               class = "genderapi_validation_error")
  expect_identical(genderapi_client(base_url = "http://127.0.0.1:8080/api/v2/")$base_url,
                   "http://127.0.0.1:8080/api/v2")
  expect_silent(genderapi_client(base_url = "http://localhost:1234/api/v2"))
  expect_silent(genderapi_client(base_url = "http://[::1]:1234/api/v2"))
  expect_silent(genderapi_client(base_url = "https://staging.example.com/api/v2"))
})

test_that("invalid client options are rejected", {
  expect_error(genderapi_client(timeout = 0), class = "genderapi_validation_error")
  expect_error(genderapi_client(timeout = -1), class = "genderapi_validation_error")
  expect_error(genderapi_client(timeout = "10"), class = "genderapi_validation_error")
  expect_error(genderapi_client(api_key = "abc\ndef"), class = "genderapi_validation_error")
  expect_error(genderapi_client(api_key = 123), class = "genderapi_validation_error")
  expect_error(genderapi_name("Onur", client = list()), class = "genderapi_validation_error")
})
