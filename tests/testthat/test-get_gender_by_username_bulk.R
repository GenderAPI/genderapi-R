test_that("get_gender_by_username_bulk works", {
  result <- get_gender_by_username_bulk(
    api_key = "DUMMY_API_KEY",
    data = list(
      list(username = "cooluser", country = "US", id = "u001"),
      list(username = "maria2025", country = "DE", id = "u002")
    )
  )

  expect_type(result, "list")
})
