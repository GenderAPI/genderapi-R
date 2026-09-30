test_that("genderapi_item builds exact wire fields", {
  item <- genderapi_item("username", "prenses", country = "TR", ai_mode = "fallback",
                         force_to_genderize = TRUE, id = "u-1")
  expect_identical(unclass(item), list(type = "username", value = "prenses", country = "TR",
                                       id = "u-1", forceToGenderize = TRUE,
                                       options = list(ai_mode = "fallback")))
  expect_identical(unclass(genderapi_item("name", "Onur")), list(type = "name", value = "Onur"))
  expect_identical(
    as.character(jsonlite::toJSON(unclass(genderapi_item("email", "a@example.com", ai_mode = "off")),
                                  auto_unbox = TRUE)),
    '{"type":"email","value":"a@example.com","options":{"ai_mode":"off"}}'
  )
})

test_that("invalid input raises a validation error without any request", {
  skip_if_not_installed("webfakes")
  client <- fake_client("dataset")
  reset_log()
  bad <- list(
    list(type = "phone", value = "x"),
    list(type = "name", value = ""),
    list(type = "name", value = "   "),
    list(type = "name", value = strrep("a", 255)),
    list(type = "name", value = "a\tb"),
    list(type = "name", value = "a\u0001b"),
    list(type = "name", value = NA_character_),
    list(type = "name", value = c("a", "b")),
    list(type = "name", value = "Onur", country = "tr"),
    list(type = "name", value = "Onur", country = "TUR"),
    list(type = "name", value = "Onur", ai_mode = "auto"),
    list(type = "name", value = "Onur", force_to_genderize = TRUE, ai_mode = "off"),
    list(type = "name", value = "Onur", force_to_genderize = TRUE, ai_mode = "always"),
    list(type = "name", value = "Onur", force_to_genderize = NA),
    list(type = "name", value = "Onur", force_to_genderize = "yes"),
    list(type = "name", value = "Onur", id = ""),
    list(type = "name", value = "Onur", id = strrep("i", 65))
  )
  for (args in bad) {
    expect_error(do.call(genderapi_gender, c(args, list(client = client))),
                 class = "genderapi_validation_error")
  }
  expect_error(genderapi_validate_phone("abc", client = client), class = "genderapi_validation_error")
  expect_error(genderapi_validate_phone("12", client = client), class = "genderapi_validation_error")
  expect_error(genderapi_validate_phone("+90 555", country = "tr", client = client),
               class = "genderapi_validation_error")
  expect_error(genderapi_batch(list(), client = client), class = "genderapi_validation_error")
  many <- lapply(1:51, function(i) genderapi_item("name", paste0("n", i)))
  expect_error(genderapi_batch(many, client = client), class = "genderapi_validation_error")
  dup <- list(genderapi_item("name", "a", id = "x"), genderapi_item("name", "b", id = "x"))
  expect_error(genderapi_batch(dup, client = client), class = "genderapi_validation_error")
  expect_error(genderapi_batch(list(list(type = "name", value = "a", bogus = 1)), client = client),
               class = "genderapi_validation_error")
  expect_error(genderapi_batch(genderapi_item("name", "a"), client = client),
               class = "genderapi_validation_error")
  expect_error(genderapi_batch(list(list(type = "name", value = "a", ai_mode = "off",
                                         force_to_genderize = TRUE)), client = client),
               class = "genderapi_validation_error")
  expect_length(request_log(), 0)
})

test_that("boundary values are accepted", {
  expect_s3_class(genderapi_item("name", strrep("ç", 254)), "genderapi_item")
  expect_s3_class(genderapi_item("name", "Onur", id = strrep("i", 64)), "genderapi_item")
  expect_s3_class(genderapi_item("name", "Onur", force_to_genderize = TRUE), "genderapi_item")
  expect_s3_class(genderapi_item("name", "Onur", force_to_genderize = TRUE, ai_mode = "fallback"),
                  "genderapi_item")
})
