test_that("get_gender_by_email_bulk works", {
  result <- get_gender_by_email_bulk(
    api_key = "DUMMY_API_KEY",
    data = list(
      list(email = "john@example.com", country = "US", id = "abc123"),
      list(email = "maria@domain.de", country = "DE", id = "def456")
    )
  )

  expect_type(result, "list")
})
