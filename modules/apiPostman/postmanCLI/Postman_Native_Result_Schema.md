# Postman Native Result Schema

## Overview
This document describes the JSON structure output by Newman (Postman CLI) when running collections with the JSON reporter.

**File Type**: JSON  
**Reporter**: `newman run --reporters json --reporter-json-export <filename>`

---

## Top-Level Structure

The file contains a single root object with one property:

### `run` (object)
Contains all execution data for the collection run.

---

## `run.meta` (object)
Metadata about the collection and execution timing.

| Property | Type | Description |
|----------|------|-------------|
| `collectionId` | string (UUID) | Unique identifier for the collection |
| `collectionName` | string | Human-readable name of the collection |
| `started` | int64 | Unix timestamp (milliseconds) when run started |
| `completed` | int64 | Unix timestamp (milliseconds) when run completed |
| `duration` | int64 | Total duration in milliseconds |

---

## `run.summary` (object)
Aggregate statistics for the entire run.

### `summary.iterations` (object)
| Property | Type | Description |
|----------|------|-------------|
| `executed` | int64 | Number of iterations executed |
| `errors` | int64 | Number of iteration errors |

### `summary.executedRequests` (object)
| Property | Type | Description |
|----------|------|-------------|
| `executed` | int64 | Number of HTTP requests executed |
| `errors` | int64 | Number of request errors |

### `summary.prerequestScripts` (object)
| Property | Type | Description |
|----------|------|-------------|
| `executed` | int64 | Number of pre-request scripts executed |
| `errors` | int64 | Number of pre-request script errors |

### `summary.postresponseScripts` (object)
| Property | Type | Description |
|----------|------|-------------|
| `executed` | int64 | Number of post-response scripts executed |
| `errors` | int64 | Number of post-response script errors |

### `summary.tests` (object)
**Key metric for assertion counts**

| Property | Type | Description |
|----------|------|-------------|
| `executed` | int64 | Total number of tests/assertions executed |
| `passed` | int64 | Number of tests that passed |
| `failed` | int64 | Number of tests that failed |
| `skipped` | int64 | Number of tests that were skipped |

### `summary.timeStats` (object)
Response time statistics across all requests.

| Property | Type | Description |
|----------|------|-------------|
| `responseAverage` | double | Average response time in milliseconds |
| `responseMin` | int64 | Minimum response time in milliseconds |
| `responseMax` | int64 | Maximum response time in milliseconds |
| `responseStandardDeviation` | double | Standard deviation of response times |

---

## `run.executions` (array)
Array of execution objects - one per request executed in the collection.

**This is where the detailed per-request data lives.**

### Each execution object contains:

#### `iterationCount` (int64)
The iteration number (0-based).

#### `requestExecuted` (object)
Details about the request that was executed.

| Property | Type | Description |
|----------|------|-------------|
| `id` | string (UUID) | Unique identifier for this request |
| `name` | string | Human-readable request name |
| `url` | object | URL details (protocol, host, path, query parameters) |
| `method` | string | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `headers` | array | Request headers sent |
| `auth` | object | Authentication details used |

#### `response` (object)
Details about the HTTP response received.

| Property | Type | Description |
|----------|------|-------------|
| `id` | string (UUID) | Unique identifier for this response |
| `_details` | object | Internal response details |
| `status` | string | HTTP status text (e.g., "OK") |
| `code` | int64 | HTTP status code (e.g., 200) |
| `headers` | array | Response headers received |
| `stream` | object | **Response body as byte array** (see below) |
| `cookies` | array | Cookies received |
| `responseTime` | int64 | Response time in milliseconds |
| `responseSize` | int64 | Response size in bytes |
| `downloadedBytes` | int64 | Number of bytes downloaded |

##### `response.stream` (object)
The response body stored as a byte array.

```json
{
  "type": "Buffer",
  "data": [123, 34, 118, ...]  // Array of byte values (ASCII/UTF-8)
}
```

**Note**: This makes files very large. Each character becomes a number in the array.

#### `tests` (array)
Array of test/assertion results for this request.

Each test object contains:

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Name of the test/assertion |
| `status` | string | Result: "passed" or "failed" |

**Example**:
```json
{
  "name": "Content-Type response header is present",
  "status": "passed"
}
```

#### `errors` (array)
Array of any errors that occurred during this request execution.

---

## `run.runError`
Any run-level errors. Typically `null` if no errors occurred.

---

## File Size Considerations

Newman JSON report files are **extremely large** due to:
- Full response bodies stored as byte arrays in `stream` objects
- Detailed request/response headers
- Complete execution history

**Example**: A collection with ~700 requests can produce a **73+ MB** JSON file with **4+ million lines**.

### Reducing File Size

To generate smaller reports, consider:
1. Using custom reporters that exclude response bodies
2. Processing the file to extract only summary data
3. Using `--suppress-exit-code` and other Newman flags (though JSON reporter always includes full data)

---

## Use Cases

### Quick Summary Analysis
Extract `run.meta` and `run.summary` for high-level metrics without parsing the entire file.

### Detailed Comparison
Compare `run.executions` arrays between two runs to identify:
- Missing or added requests
- Changed test counts per request
- Different test results

### Test Inventory
Iterate through `executions[].tests[]` to get a complete list of all tests/assertions in the collection.

---

## Schema Version
This schema is based on Newman (Postman CLI) output as of October 2025.

