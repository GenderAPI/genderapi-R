test_that("V1 functions are defunct and name their replacement", {
  expect_error(get_gender_by_name("x", "Michael"), "genderapi_name")
  expect_error(get_gender_by_email_bulk(), "genderapi_batch")
})
