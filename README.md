# genderapi-R

> This R package is a legacy V1 client for GenderAPI.io. Its methods, request fields and response examples use the V1 contract. Use the [V1 API documentation](https://www.genderapi.io/api-documentation/v1) for this package. For a new integration, see the [V2 documentation](https://www.genderapi.io/api-documentation). V2 uses a different request and response format; changing the base URL alone does not migrate this client. Results are inferences and may be unresolved. They do not verify a person's identity.

Official R Client for [GenderAPI.io](https://www.genderapi.io) — determine gender from **names**, **emails**, and **usernames** using AI, including **bulk operations** for high-volume analysis.

---

> ✅ **Get a Free API Key:**  
> [https://app.genderapi.io](https://app.genderapi.io)

---

## 🚀 Installation

The package is now available on **CRAN**. Install it with:

```r
install.packages("genderapi")
```

Then load the package:

```r
library(genderapi)
```


---

## ⚠️ Required Packages

Make sure you have these installed:

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

### 🔹 Get Gender by Name (Bulk)

Lookup up to **100 names** in a single request.

```r
data <- list(
  list(name = "Andrea", country = "DE", id = "123"),
  list(name = "andrea", country = "IT", id = "456"),
  list(name = "james", country = "US", id = "789")
)

result <- get_gender_by_name_bulk(
  api_key = api_key,
  data = data
)

print(result)
```

---

### 🔹 Get Gender by Email (Bulk)

Lookup up to **50 emails** in a single request.

```r
data <- list(
  list(email = "john@example.com", country = "US", id = "abc123"),
  list(email = "maria@domain.de", country = "DE", id = "def456")
)

result <- get_gender_by_email_bulk(
  api_key = api_key,
  data = data
)

print(result)
```

---

### 🔹 Get Gender by Username (Bulk)

Lookup up to **50 usernames** in a single request.

```r
data <- list(
  list(username = "cooluser", country = "US", id = "u001"),
  list(username = "maria2025", country = "DE", id = "u002")
)

result <- get_gender_by_username_bulk(
  api_key = api_key,
  data = data
)

print(result)
```

---

## 📥 API Parameters

Below are the parameters accepted by each function.

### Name Lookup

| Parameter          | Type     | Required | Description |
|--------------------|----------|----------|-------------|
| name               | String   | Yes      | Name to query. |
| country            | String   | No       | Two-letter country code (e.g. `"US"`). |
| askToAI            | Logical  | No       | Defaults to `FALSE`. Enables the legacy AI option. Supported single lookups with this option use a 2-credit tariff. This does not guarantee higher accuracy or a resolved result. Ordinary lookups and batch requests follow their V1 billing rules; inspect the returned `used_credits` value. |
| forceToGenderize   | Logical  | No       | Default is `FALSE`. When `TRUE`, allows interpretation of nickname-like or unconventional inputs where supported by this V1 method. A result may still be unresolved; the option does not verify identity. |

---

### Name Lookup (Bulk)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| data | List of named lists | Yes | Each item contains `name` (required), `country` (optional), and `id` (optional). Max 100 records. |

---

### Email Lookup

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| email     | String | Yes      | Email address to query. |
| country   | String | No       | Two-letter country code. |
| askToAI   | Logical | No      | Defaults to `FALSE`. Enables the legacy AI option. Supported single lookups with this option use a 2-credit tariff. This does not guarantee higher accuracy or a resolved result. Ordinary lookups and batch requests follow their V1 billing rules; inspect the returned `used_credits` value. |

---

### Email Lookup (Bulk)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| data | List of named lists | Yes | Each item contains `email` (required), `country` (optional), and `id` (optional). Max 50 records. |

---

### Username Lookup

| Parameter          | Type     | Required | Description |
|--------------------|----------|----------|-------------|
| username           | String   | Yes      | Username to query. |
| country            | String   | No       | Two-letter country code. |
| askToAI            | Logical  | No       | Defaults to `FALSE`. Enables the legacy AI option. Supported single lookups with this option use a 2-credit tariff. This does not guarantee higher accuracy or a resolved result. Ordinary lookups and batch requests follow their V1 billing rules; inspect the returned `used_credits` value. |
| forceToGenderize   | Logical  | No       | Default is `FALSE`. When `TRUE`, allows interpretation of nickname-like or unconventional inputs where supported by this V1 method. A result may still be unresolved; the option does not verify identity. |

---

### Username Lookup (Bulk)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| data | List of named lists | Yes | Each item contains `username` (required), `country` (optional), and `id` (optional). Max 50 records. |

---

## ✅ API Response

All functions return a list representing the JSON response.

Single lookup example:

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

Bulk lookup example:

```r
list(
  status = TRUE,
  used_credits = 3,
  remaining_credits = 7265,
  expires = 1717069765,
  names = list(
    list(
      name = "andrea",
      q = "Andrea",
      gender = "female",
      country = "DE",
      total_names = 644,
      probability = 88,
      id = "123"
    ),
    list(
      name = "andrea",
      q = "andrea",
      gender = "male",
      country = "IT",
      total_names = 13537,
      probability = 98,
      id = "456"
    )
  ),
  duration = "5ms"
)
```

---

## 🔎 Response Fields

| Field             | Type               | Description                                         |
|-------------------|--------------------|-----------------------------------------------------|
| status            | Logical            | `TRUE` or `FALSE`. Indicates success.              |
| used_credits      | Integer            | Credits used for the request.                     |
| remaining_credits | Integer            | Credits left.                                     |
| expires           | Integer            | Unix timestamp of account expiry.                 |
| q                 | String             | Original query input.                             |
| name              | String             | Found name.                                       |
| gender            | String             | `"male"`, `"female"`, or `"null"`.                |
| country           | String             | Predicted country code.                           |
| total_names       | Integer            | Number of records used in prediction.             |
| probability       | Integer            | Confidence (50–100).                              |
| duration          | String             | Processing time.                                  |

---

## ⚠️ Error Handling

If an error occurs, the API returns:

```r
list(
  status = FALSE,
  errno = 94,
  errmsg = "invalid or missing key"
)
```

Common error codes:

| errno | errmsg                      | Description |
|-------|-----------------------------|-------------------------------------------------|
| 50    | access denied               | Unauthorized IP or referrer.                   |
| 90    | invalid country code        | Invalid country code.                          |
| 91    | name not set \|\| email not set | Missing input field.                      |
| 92    | too many names \|\| too many emails | Exceeded bulk limits.                |
| 93    | limit reached               | API key credits exhausted.                     |
| 94    | invalid or missing key      | Invalid API key.                               |
| 99    | API key has expired         | Renew your key.                                |

---

## 💻 Troubleshooting

- Check internet connection.
- Ensure your API key is correct.
- Confirm required R packages are installed:
    ```r
    install.packages(c("httr", "jsonlite"))
    ```

---

## 🔗 Live Test Pages

- **Gender by name:** [https://www.genderapi.io](https://www.genderapi.io)
- **Gender by email:** [https://www.genderapi.io/determine-gender-from-email](https://www.genderapi.io/determine-gender-from-email)
- **Gender by username:** [https://www.genderapi.io/determine-gender-from-username](https://www.genderapi.io/determine-gender-from-username)

---

## 📚 Detailed API Documentation

For the complete V1 API reference used by this package, visit:

[https://www.genderapi.io/api-documentation/v1](https://www.genderapi.io/api-documentation/v1)

For a new integration, use the V2 documentation instead (different request and response format; this client is not a V2 client):

[https://www.genderapi.io/api-documentation](https://www.genderapi.io/api-documentation)

---

## ⚖️ License

MIT License
