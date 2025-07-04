test_that("get_gender_by_email works", {
  result <- get_gender_by_email(
    api_key = "DUMMY_API_KEY",
    email = "michael.smith@example.com"
  )

  expect_type(result, "list")
})
