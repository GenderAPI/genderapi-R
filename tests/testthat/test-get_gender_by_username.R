test_that("get_gender_by_username works", {
  result <- get_gender_by_username(
    api_key = "DUMMY_API_KEY",
    username = "michael_dev"
  )

  expect_type(result, "list")
})