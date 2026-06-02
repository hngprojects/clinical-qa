# MVP Regression Suite — API Test Collection

A complete regression test suite for the **ClinSight API MVP**, covering all critical authentication and core feature endpoints.

---

##  Table of Contents

- [Test Coverage](#test-coverage)
- [Environment Variables](#environment-variables)
- [Test Cases Breakdown](#test-cases-breakdown)
  - [1. Auth — Signup](#1-auth--signup)
  - [2. Auth — Login](#2-auth--login)
  - [3. Auth — Forgot Password](#3-auth--forgot-password)
  - [4. Auth — Logout](#4-auth--logout)
  - [5. Guest Sessions](#5-guest-sessions)
  - [6. Lab Results — Upload](#6-lab-results--upload)
  - [7. AI Interpretations](#7-ai-interpretations)
- [Running the Collection](#running-the-collection)
- [Expected Workflow Order](#expected-workflow-order)
- [Notes](#notes)
- [Troubleshooting](#troubleshooting)

---

## Test Coverage

| Module | Test Cases |
|---|---|
| Auth — Signup | 8 |
| Auth — Login | 7 |
| Auth — Forgot Password | 4 |
| Auth — Logout | 3 |
| Guest Sessions | 11 |
| Lab Results — Upload | 4 |
| AI Interpretations | 4 |
| **Total** | **41** |

---

## Environment Variables

Before running the collection, ensure the following variables are configured in your Postman environment:

| Variable | Description | Example Value |
|---|---|---|
| `base_url` | API base URL | `https://api.staging.clinsight.hng14.com` |
| `test_email` | Registered test user email | `user@example.com` |
| `test_password` | Valid test user password | `Password123!` |
| `wrong_password` | Invalid password for negative tests | `WRONGPass1@` |
| `invalid_email` | Malformed email format | `user@gmail` |
| `invalid_UUID` | Invalid UUID format | `invalid-uuid-123` |
| `non_existent_case_id` | UUID not in system | `00000000-0000-0000-0000-000000000000` |

> **Note:** Variables like `access_token`, `guestSessionId`, `created_case_id`, and `created_lab_result_id` are automatically set during test execution.

---

## Test Cases Breakdown

### 1. Auth — Signup

**Endpoint:** `POST /api/v1/auth/signup`

| Test | Expected Status | Description |
|---|---|---|
| ✅ Successful Signup | `201` / `429` | Valid credentials with random email |
| ❌ Duplicate Email | `401` / `429` | Existing email registration |
| ❌ Invalid Email Format | `422` | Malformed email address |
| ❌ Password Below Minimum | `422` | Short password (< min length) |
| ❌ Password Mismatch | `422` | `confirm_password` ≠ `password` |
| ❌ Missing Required Fields | `422` | Empty request body |
| ❌ Missing Email Field | `422` | No email in request |

---

### 2. Auth — Login

**Endpoint:** `POST /api/v1/auth/login`

| Test | Expected Status | Description |
|---|---|---|
| ✅ Successful Login | `200` | Valid credentials, returns `access_token` |
| ❌ Wrong Password | `401` | Invalid password |
| ❌ Non-existent Email | `422` | Email not registered |
| ❌ Missing Email Field | `422` | No email in request |
| ❌ Missing Password Field | `422` | No password in request |
| ⚠️ Empty Credentials | `4xx` | Empty email and password |
| ❌ Unverified Email Account | `404` | Unverified account login |

---

### 3. Auth — Forgot Password

**Endpoint:** `POST /api/v1/auth/forgot-password`

| Test | Expected Status | Description |
|---|---|---|
| ✅ Registered email | `200` | Valid existing email |
| ✅ Non-registered email | `200` | Anti-enumeration (still returns 200) |
| ❌ Invalid email format | `422` | Malformed email |
| ⚠️ Empty body | `422` | No data sent |

---

### 4. Auth — Logout

**Endpoint:** `POST /api/v1/auth/logout`

| Test | Expected Status | Description |
|---|---|---|
| ✅ Valid token | `200` | Successful logout |
| ❌ No token | `401` | Missing Authorization header |
| ⚠️ Revoked token | `401` | Already used/invalidated token |

---

### 5. Guest Sessions

#### Create Guest Session — `POST /api/v1/guest-session`

| Test | Expected Status | Description |
|---|---|---|
| ✅ With device fingerprint | `201` | Valid fingerprint header |
| ✅ Without fingerprint | `201` | Auto-generates session |
| ✅ Same fingerprint | `201` | Returns existing session |
| ✅ Different fingerprint | `201` | Creates new session |
| ⚠️ Empty string fingerprint | `200` / `201` | Handles gracefully |
| ⚠️ Very long fingerprint | `201` | Stress test |

#### Get Guest Session (Me) — `GET /api/v1/guest-session/me`

| Test | Expected Status | Description |
|---|---|---|
| ✅ Valid active session | `200` | Returns session details |
| ❌ Missing header | `401` | No `x-guest-session-id` |
| ❌ Invalid / non-existent ID | `401` | UUID not found |
| ❌ Empty string ID | `401` | Empty header value |
| ❌ Malformed (non-UUID) | `401` | Invalid UUID format |

---

### 6. Lab Results — Upload

**Endpoint:** `POST /api/v1/upload`

> ⚠️ Requires a `lab_result.jpeg` file in the working directory. See [Running the Collection](#running-the-collection).

| Test | Expected Status | Description |
|---|---|---|
| ✅ Guest user with valid file | `201` | Uploads image/file successfully |
| ❌ No file attached | `422` | Empty formdata |
| ❌ No guest session | `401` | Missing session header |
| ❌ Wrong content type | `422` | JSON instead of multipart |

---

### 7. AI Interpretations

**Endpoint:** `GET /api/v1/cases/{case_id}/interpretations`

| Test | Expected Status | Description |
|---|---|---|
| ❌ Invalid `case_id` format | `422` | Non-UUID format |
| ❌ Case ID not found | `200` / `404` | Empty or 404 response |
| ✅ Get AI Interpretations | `200` | Retrieves interpretations for created case |

---

## Running the Collection

### Prerequisites

- [Postman](https://www.postman.com/downloads/) (latest version) or [Newman](https://www.npmjs.com/package/newman) (CLI)
- A `lab_result.jpeg` file in the working directory for upload tests

### Via Postman Desktop

1. Import the `regression.json` collection
2. Set up your environment variables
3. Run the collection in order (folders are sequenced)

### Via Newman (CLI)

```bash
newman run regression.json \
  --environment your-env.json \
  --reporters cli,json \
  --reporter-json-export test-results.json
```

### Via Newman with File Upload Support

```bash
newman run regression.json \
  --folder "6. LAB RESULTS - UPLOAD" \
  --globals '{"guestSessionId": "your-session-id"}' \
  --working-dir ./test-files
```

> 💡 Place `lab_result.jpeg` inside the `./test-files` directory (or whichever folder you pass to `--working-dir`).

---

## Expected Workflow Order

For a complete regression run, execute folders in this order:

```
1. AUTH - SIGNUP          →  Create test user (first run only)
2. AUTH - LOGIN           →  Get access_token
3. AUTH - FORGOT PASSWORD →  Test password reset flow
4. AUTH - LOGOUT          →  Test session termination
5. GUEST SESSIONS         →  Create and validate guest sessions
6. LAB RESULTS - UPLOAD   →  Upload medical lab reports
7. AI INTERPRETATIONS     →  Get AI analysis results
```

---

## Notes

| Topic | Detail |
|---|---|
| **Rate Limiting** | Some tests accept `429` responses as valid outcomes |
| **Session Persistence** | Guest session IDs are automatically stored and reused across requests |
| **File Upload** | Requires `lab_result.jpeg` in the Newman working directory |
| **Anti-Enumeration** | Forgot password returns `200` even for non-existent emails — this is intentional security behaviour |

---

## Troubleshooting

| Issue | Solution |
|---|---|
| `401 Unauthorized` | Check `test_email` / `test_password` are valid and the account is verified |
| `422 Validation Error` | Verify email and password meet format requirements |
| Upload test fails | Ensure `lab_result.jpeg` exists in the `--working-dir` path |
| Guest session fails | Run **Create Guest Session** first to set the `guestSessionId` variable |
| Token expired | Re-run the **Login** test to get a fresh `access_token` |

---

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Happy path — expected to succeed |
| ❌ | Negative test — expected to return an error response |
| ⚠️ | Edge case — behaviour may vary; tests validate graceful handling |