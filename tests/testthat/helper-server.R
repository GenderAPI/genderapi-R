# Local fake GenderAPI V2 server (webfakes). No test talks to the real API.
# Base URLs look like <server>/s/<scenario>/api/v2; the scenario decides the
# response. Every request is logged so tests can count calls (no retries,
# no redirects followed, no request for client-side validation errors).
# The fixtures report meta.access.mode "ip_trial" (no key). A scenario name
# ending in "-key" (e.g. "usage-key") serves the same fixture with
# meta.access.mode "api_key", as the real server does for a valid key.

fixture_dir <- normalizePath(test_path("fixtures"))
test_key <- "0123456789abcdef01234567"

fake_app <- function() {
  app <- webfakes::new_app()
  app$locals$fixture_dir <- fixture_dir
  app$locals$log <- list()

  app$get("/__log", function(req, res) {
    res$set_type("application/json")
    res$send(jsonlite::toJSON(app$locals$log, auto_unbox = TRUE, null = "null"))
  })
  app$post("/__reset", function(req, res) {
    app$locals$log <- list()
    res$send_status(204L)
  })

  app$all(webfakes::new_regexp("^/s/(?<scenario>[^/]+)/api/v2(?<rest>.*)$"), function(req, res) {
    body_text <- if (is.raw(req$.body)) rawToChar(req$.body) else ""
    app$locals$log[[length(app$locals$log) + 1L]] <- list(
      method = toupper(req$method),
      path = req$path,
      query = req$query_string,
      scenario = req$params$scenario,
      rest = req$params$rest,
      authorization = req$get_header("Authorization"),
      content_type = req$get_header("Content-Type"),
      accept = req$get_header("Accept"),
      user_agent = req$get_header("User-Agent"),
      body = body_text
    )
    scenario <- req$params$scenario
    key_mode <- grepl("-key$", scenario)
    scenario <- sub("-key$", "", scenario)
    fixture <- function(name) {
      text <- paste(readLines(file.path(app$locals$fixture_dir, paste0(name, ".json")),
                              encoding = "UTF-8", warn = FALSE), collapse = "\n")
      if (key_mode) {
        text <- gsub('"mode": "ip_trial",\\s*"reason": "api_key_missing"',
                     '"mode": "api_key", "reason": null', text, perl = TRUE)
      }
      text
    }
    reply <- function(status, text, type = "application/json", headers = list()) {
      res$set_status(status)
      res$set_header("Content-Type", type)
      res$set_header("X-Request-ID", "hdr-req-1")
      for (n in names(headers)) res$set_header(n, headers[[n]])
      res$send(text)
    }
    problem <- function(status, code, action, billing = "not_charged", charged = 0) {
      jsonlite::toJSON(list(
        type = paste0("urn:genderapi:problem:", code),
        title = gsub("_", " ", code),
        status = status,
        detail = paste("Synthetic", code),
        code = code,
        documentation = "https://api.genderapi.io/api/v2/errors",
        action = action,
        meta = list(
          request_id = "body-meta-req-1",
          duration_ms = 3,
          access = list(mode = "api_key", reason = NULL),
          usage = list(charged_credits = charged, remaining_credits = NULL,
                       billing_status = billing)
        )
      ), auto_unbox = TRUE, null = "null")
    }
    switch(
      scenario,
      dataset = reply(200L, fixture("gender-dataset")),
      alias = reply(200L, fixture("gender-alias-ai")),
      unknown = reply(200L, fixture("gender-unknown")),
      extra = {
        x <- jsonlite::fromJSON(fixture("gender-dataset"), simplifyVector = FALSE)
        x$data$future_field <- list(nested = TRUE)
        x$meta$future_meta <- "x"
        x$top_level_extra <- 1
        reply(200L, jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"),
              type = "application/json; charset=utf-8")
      },
      batch = reply(200L, fixture("batch-partial")),
      batchfailed = reply(502L, fixture("batch-502-all-failed"), "application/problem+json"),
      usage = reply(200L, fixture("usage")),
      phone = reply(200L, fixture("phone")),
      caps = reply(200L, '{"version":"2.0.0","limits":{"batch_max_items":50},"ai":{"available":true}}'),
      errors = reply(200L, jsonlite::toJSON(list(
        invalid_api_key = list(code = "invalid_api_key", http_statuses = list(401),
                               action = "check_credentials")), auto_unbox = TRUE)),
      e401 = reply(401L, problem(401L, "invalid_api_key", "check_credentials"),
                   "application/problem+json"),
      e403 = reply(403L, fixture("gender-403-insufficient"), "application/problem+json"),
      e422 = reply(422L, fixture("gender-422-validation"), "application/problem+json"),
      e429 = reply(429L, problem(429L, "rate_limit_exceeded", "wait_then_retry"),
                   "application/problem+json", list(`Retry-After` = "7")),
      e502 = reply(502L, problem(502L, "ai_upstream_error", "inspect_billing_before_retry",
                                 billing = "confirmed"), "application/problem+json"),
      e502html = reply(502L, "<html><body>502 Bad Gateway</body></html>", "text/html"),
      e503 = reply(503L, fixture("gender-503-unconfirmed"), "application/problem+json"),
      notjson = reply(200L, "OK", "text/plain"),
      jsonarray = reply(200L, "[1,2]"),
      redirect = {
        res$set_status(302L)
        res$set_header("Location", "/s/dataset/api/v2/gender")
        res$send("")
      },
      slow = {
        Sys.sleep(3)
        reply(200L, fixture("gender-dataset"))
      },
      echo = reply(200L, jsonlite::toJSON(list(
        data = list(gender = NULL, result_status = "unknown", reason = "not_found",
                    confidence = NULL, confidence_kind = NULL, source = "none"),
        meta = list(request_id = "echo-1")
      ), auto_unbox = TRUE, null = "null")),
      reply(404L, problem(404L, "not_found", "correct_request"), "application/problem+json")
    )
  })
  app
}

fake_server <- local({
  server <- NULL
  function() {
    if (is.null(server)) {
      server <<- webfakes::new_app_process(fake_app(), opts = webfakes::server_opts(num_threads = 3))
    }
    server
  }
})

fake_client <- function(scenario, api_key = test_key, timeout = 5, ...) {
  url <- sub("/+$", "", fake_server()$url())
  genderapi_client(api_key = api_key,
                   base_url = paste0(url, "/s/", scenario, "/api/v2"),
                   timeout = timeout, ...)
}

reset_log <- function() {
  curl::curl_fetch_memory(fake_server()$url("/__reset"),
                          handle = curl::new_handle(customrequest = "POST"))
  invisible()
}

request_log <- function() {
  res <- curl::curl_fetch_memory(fake_server()$url("/__log"))
  jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE)
}

read_fixture <- function(name) {
  jsonlite::fromJSON(file.path(fixture_dir, paste0(name, ".json")), simplifyVector = FALSE)
}
