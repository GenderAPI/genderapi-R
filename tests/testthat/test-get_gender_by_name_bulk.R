test_that("get_gender_by_name_bulk works", {
  result <- get_gender_by_name_bulk(
    api_key = "DUMMY_API_KEY",
    data = list(
      list(name = "Andrea", country = "DE", id = "123"),
      list(name = "andrea", country = "IT", id = "456"),
      list(name = "james", country = "US", id = "789")
    )
  )

  expect_type(result, "list")
})
