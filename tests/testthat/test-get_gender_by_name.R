test_that("get_gender_by_name works", {
  result <- get_gender_by_name(
    api_key = "DUMMY_API_KEY",
    name = "Michael"
  )

  # Sonuç bir liste mi?
  expect_type(result, "list")
})