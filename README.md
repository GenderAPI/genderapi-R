# genderapi-R

Official R Client for [GenderAPI.io](https://www.genderapi.io) — determine gender from **names**, **emails**, and **usernames** using AI.

---

> ✅ **Get a Free API Key:**  
> [https://app.genderapi.io](https://app.genderapi.io)

---

## 🚀 Installation

Since the package is **not yet on CRAN**, you can install it directly from GitHub using the `{devtools}` package.

> If you don’t have `{devtools}` installed, install it first:

```r
install.packages("devtools")
```

Then, install the genderapi-R package from GitHub:

```r
devtools::install_github("GenderAPI/genderapi-R")
```

Finally, load the package:

```r
library(genderapi)
```

That’s it — you’re ready to use GenderAPI in R!

---

## ⚠️ Required Packages

Please make sure you also have these packages installed:

```r
install.packages(c("httr", "jsonlite"))
```

---

## Example

```r
library(genderapi)

api_key <- "YOUR_API_KEY"

result <- get_gender_by_name(
  api_key = api_key,
  name = "Michael"
)

print(result)
```
---

## 🔗 Load the Library

```r
library(genderapi)
```

---

## 📝 Usage

### 🔹 Get Gender by Name

```r
api_key <- "YOUR_API_KEY"

result <- get_gender_by_name(
  api_key = api_key,
  name = "Michael"
)

print(result)
```

#### With Additional Options

```r
result <- get_gender_by_name(
  api_key = api_key,
  name = "李雷",
  country = "CN",
  askToAI = TRUE,
  forceToGenderize = TRUE
)

print(result)
```

---

### 🔹 Get Gender by Email

```r
result <- get_gender_by_email(
  api_key = api_key,
  email = "michael.smith@example.com"
)

print(result)
```

#### With askToAI

```r
result <- get_gender_by_email(
  api_key = api_key,
  email = "michael.smith@example.com",
  askToAI = TRUE
)

print(result)
```

---

### 🔹 Get Gender by Username

```r
result <- get_gender_by_username(
  api_key = api_key,
  username = "michael_dev"
)

print(result)
```

#### With Additional Options

```r
result <- get_gender_by_username(
  api_key = api_key,
  username = "michael_dev",
  country = "US",
  askToAI = TRUE,
  forceToGenderize = TRUE
)

print(result)
```

---

## 📥 API Parameters

The following parameters are available for the API functions.

### Name Lookup

| Parameter          | Type     | Required | Description |
|--------------------|----------|----------|-------------|
| name               | String   | Yes      | Name to query. |
| country            | String   | No       | Two-letter country code (e.g. `"US"`). Helps narrow down gender detection results by region. |
| askToAI            | Logical  | No       | Default is `FALSE`. If `TRUE`, sends the query directly to AI for maximum accuracy, consuming 3 credits per request. Recommended for non-latin characters or unusual strings. |
| forceToGenderize   | Logical  | No       | Default is `FALSE`. When `TRUE`, analyzes even nicknames, emojis, or unconventional strings instead of returning `NULL` for non-standard names. |

---

### Email Lookup

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| email     | String | Yes      | Email address to query. |
| country   | String | No       | Two-letter country code (e.g. `"US"`). |
| askToAI   | Logical | No      | Default is `FALSE`. |

---

### Username Lookup

| Parameter          | Type     | Required | Description |
|--------------------|----------|----------|-------------|
| username           | String   | Yes      | Username to query. |
| country            | String   | No       | Two-letter country code. |
| askToAI            | Logical  | No       | Default is `FALSE`. |
| forceToGenderize   | Logical  | No       | Default is `FALSE`. |

---

## ✅ API Response

All functions return a list containing the API JSON response.

Example output:

```r
list(
  status = TRUE,
  used_credits = 1,
  remaining_credits = 4999,
  expires = 1743659200,
  q = "michael.smith@example.com",
  name = "Michael",
  gender = "male",
  country = "US",
  total_names = 325,
  probability = 98,
  duration = "4ms"
)
```

---

## 🔎 Response Fields

| Field             | Type               | Description                                         |
|-------------------|--------------------|-----------------------------------------------------|
| status            | Logical            | `TRUE` or `FALSE`. Check errors if FALSE.          |
| used_credits      | Integer            | Credits used for this request.                     |
| remaining_credits | Integer            | Remaining credits on your account.                 |
| expires           | Integer (timestamp)| API key expiration date (in seconds).             |
| q                 | String             | The queried input (name, email, or username).     |
| name              | String             | Name found.                                       |
| gender            | String             | `"male"`, `"female"`, or `"null"`.                |
| country           | String             | Predicted country.                                |
| total_names       | Integer            | Number of data samples behind the prediction.     |
| probability       | Integer            | Likelihood percentage (50–100).                  |
| duration          | String             | Time taken for processing.                        |

---

## ⚠️ Error Handling

If the API returns an error, the response will include:

- `status = FALSE`
- `errno` (integer error code)
- `errmsg` (human-readable message)

Example error response:

```r
list(
  status = FALSE,
  errno = 94,
  errmsg = "invalid or missing key"
)
```

### Common Error Codes

| errno | errmsg                      | Description                                                       |
|-------|-----------------------------|-------------------------------------------------------------------|
| 50    | access denied               | Unauthorized IP Address or Referrer. Check your access privileges. |
| 90    | invalid country code        | Check supported country codes. [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) |
| 91    | name not set \|\| email not set | Missing `name` or `email` parameter.         |
| 92    | too many names \|\| too many emails | Limit is 100 for names, 50 for emails in one request.     |
| 93    | limit reached               | Your API key credits are exhausted.                            |
| 94    | invalid or missing key      | The API key cannot be found.                                      |
| 99    | API key has expired         | Renew your API key.                                       |

---

## 💻 Troubleshooting

- If you see CORS errors or connectivity issues, check your internet connection or any network firewall.
- Ensure your API key is correctly typed and active.
- Check that required R packages are installed:
    ```r
    install.packages(c("httr", "jsonlite"))
    ```

---

## 🔗 Live Test Pages

You can test gender detection directly on GenderAPI.io:

- **Determine gender from a name:**  
  [https://www.genderapi.io](https://www.genderapi.io)

- **Determine gender from an email address:**  
  [https://www.genderapi.io/determine-gender-from-email](https://www.genderapi.io/determine-gender-from-email)

- **Determine gender from a username:**  
  [https://www.genderapi.io/determine-gender-from-username](https://www.genderapi.io/determine-gender-from-username)

---

## 📚 Detailed API Documentation

Full API reference available at:

[https://www.genderapi.io/api-documentation](https://www.genderapi.io/api-documentation)

---

## ⚖️ License

MIT License

```
