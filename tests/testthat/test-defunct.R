test_that("V1 functions are defunct and name their replacement", {
  expect_error(get_gender_by_name("x", "Michael"), "genderapi_name")
  expect_error(get_gender_by_email_bulk(), "genderapi_batch")
})

test_that("defunct V1 functions explain how to keep using 1.x", {
  pin <- 'remotes::install_version("genderapi", "1.0.3")'
  stubs <- list(get_gender_by_name, get_gender_by_email, get_gender_by_username,
                get_gender_by_name_bulk, get_gender_by_email_bulk,
                get_gender_by_username_bulk)
  for (stub in stubs) {
    e <- tryCatch(stub(), error = function(e) e)
    expect_s3_class(e, "defunctError")
    expect_match(conditionMessage(e), "To keep using the V1 API, install genderapi 1.x", fixed = TRUE)
    expect_match(conditionMessage(e), pin, fixed = TRUE)
  }
})
