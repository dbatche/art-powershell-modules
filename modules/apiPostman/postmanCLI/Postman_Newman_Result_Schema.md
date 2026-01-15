# Postman Newman Result Schema

## Overview
This document describes the JSON structure output by Newman (Postman CLI) when using the `--reporter-json-structure newman` option.

**File Type**: JSON  
**Reporter**: `postman collection run <collection-id> --reporters json --reporter-json-structure newman --reporter-json-export <filename>`

**Key Difference from Native Format**: This format is more compact and organized differently, focusing on structured stats and organized execution data.

**Last Updated**: October 3, 2025 - Based on Finance apInvoices test run (65 requests)

---

## Top-Level Structure

The file contains four main sections:

1. **`collection`** - The complete Postman collection definition
2. **`environment`** - Environment variables used during execution
3. **`globals`** - Global variables used during execution
4. **`run`** - Execution results and statistics

---

## `collection` (object)
The complete Postman collection that was executed, including:
- Collection metadata (`_` object with `postman_id`)
- `item` array - All requests and folders in the collection
  - Each item contains: `id`, `name`, `request`, `response`, `event`, `protocolProfileBehavior`

This is the full collection definition as stored in Postman.

---

## `environment` (object)
Environment variables that were active during the run, including:
- Variable names and values
- Environment metadata

---

## `globals` (object)
Global variables that were active during the run.

---

## `run` (object)
The execution results and statistics. This is the primary section for analysis.

### Top-Level Properties

| Property | Type | Description |
|----------|------|-------------|
| `stats` | object | Aggregate statistics (see below) |
| `timings` | object | Timing and performance metrics (see below) |
| `executions` | array | Detailed execution data for each request (e.g. 65 items for 65 requests) |
| `transfers` | object | Data transfer statistics |
| `failures` | array | All failures that occurred during execution (e.g. 214 failures) |
| `error` | null/object | Run-level error (if any) |

---

## `run.stats` (object)
Comprehensive statistics broken down by category.

### `stats.iterations` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Total iterations executed |
| `pending` | int | Iterations pending |
| `failed` | int | Failed iterations |

### `stats.items` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Total collection items |
| `pending` | int | Items pending |
| `failed` | int | Failed items |

### `stats.scripts` (object)
**Combined count of all scripts (pre-request + test)**

| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Total scripts executed |
| `pending` | int | Scripts pending |
| `failed` | int | Failed scripts |

### `stats.prerequests` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Pre-request scripts executed |
| `pending` | int | Pre-requests pending |
| `failed` | int | Failed pre-requests |

### `stats.requests` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | HTTP requests executed |
| `pending` | int | Requests pending |
| `failed` | int | Failed requests |

### `stats.tests` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Test scripts executed |
| `pending` | int | Tests pending |
| `failed` | int | Failed tests |

### `stats.assertions` (object)
**Key metric for test/assertion counts**

| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Total assertions/tests executed |
| `pending` | int | Assertions pending |
| `failed` | int | Failed assertions |

### `stats.testScripts` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Test scripts executed |
| `pending` | int | Test scripts pending |
| `failed` | int | Failed test scripts |

### `stats.prerequestScripts` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Pre-request scripts executed |
| `pending` | int | Pre-request scripts pending |
| `failed` | int | Failed pre-request scripts |

### `stats.responses` (object)
| Property | Value | Description |
|----------|-------|-------------|
| `total` | int | Total responses received |
| `pending` | int | Responses pending |
| `failed` | int | Failed responses |
| `totalResponseTime` | int | Cumulative response time (milliseconds) |

---

## `run.timings` (object)
Performance and timing statistics.

| Property | Type | Description |
|----------|------|-------------|
| `responseAverage` | double | Average response time (milliseconds) |
| `responseMin` | int | Minimum response time (milliseconds) |
| `responseMax` | int | Maximum response time (milliseconds) |
| `responseSd` | double | Response time standard deviation |
| `dnsAverage` | double | Average DNS lookup time |
| `dnsMin` | int | Minimum DNS lookup time |
| `dnsMax` | int | Maximum DNS lookup time |
| `dnsSd` | double | DNS lookup time standard deviation |
| `firstByteAverage` | double | Average time to first byte |
| `firstByteMin` | int | Minimum time to first byte |
| `firstByteMax` | int | Maximum time to first byte |
| `firstByteSd` | double | Time to first byte standard deviation |
| `started` | int64 | Unix timestamp (milliseconds) when run started |
| `completed` | int64 | Unix timestamp (milliseconds) when run completed |

---

## `run.executions` (array)
Array of execution objects - one per request executed.

**Example**: 65 items for a collection run with 65 requests.

### Each execution object contains:

| Property | Type | Description |
|----------|------|-------------|
| `cursor` | object | Execution position info (position, iteration, length, cycles, ref, scriptId) |
| `item` | object | The collection item that was executed |
| `request` | object | The HTTP request that was sent |
| `id` | string (UUID) | Unique identifier for this execution |
| `prerequestScript` | array | Pre-request script execution results (including errors) |
| `response` | object | HTTP response received (id, status, code, header, stream, cookie, responseTime, responseSize, downloadedBytes) |
| `testScript` | array | Test script execution results (including errors and test results) |

#### `execution.cursor` (object)
Position and iteration information.

| Property | Type | Description |
|----------|------|-------------|
| `position` | int | Position in execution order (0-based) |
| `iteration` | int | Iteration number (0-based) |
| `length` | int | Total number of items |
| `cycles` | int | Number of cycles/iterations |
| `empty` | bool | Whether cursor is empty |
| `eof` | bool | End of file |
| `bof` | bool | Beginning of file |
| `cr` | bool | Carriage return |
| `ref` | string (UUID) | Reference ID |
| `httpRequestId` | string (UUID) | HTTP Request ID (Newman format) |

#### `execution.response.stream` (object)
Response body stored as byte array (same as Native format).

```json
{
  "type": "Buffer",
  "data": [123, 34, ...]  // Array of byte values
}
```

#### `execution.testScript` (array)
Contains test script execution details, including:
- Individual test results
- Test names and pass/fail status
- Any errors encountered

#### `execution.prerequestScript` (array)
Contains pre-request script execution details, including any errors.

---

## `run.transfers` (object)
Data transfer statistics.

| Property | Type | Description |
|----------|------|-------------|
| `responseTotal` | int | Total bytes transferred in responses |

---

## `run.failures` (array)
Detailed information about all failures during execution.

**Example**: 214 failures for a run with script errors.

### Each failure object contains:

| Property | Type | Description |
|----------|------|-------------|
| `error` | object | Error details (type, name, message, checksum, id, timestamp, stacktrace) |
| `at` | string | Where error occurred (e.g., "prerequest-script", "test-script") |
| `source` | object | The collection item where failure occurred |
| `parent` | object | Parent folder/collection info |
| `cursor` | object | Execution position when failure occurred |

#### `failure.error` (object)

| Property | Type | Description |
|----------|------|-------------|
| `type` | string | Error type (e.g., "Error") |
| `name` | string | Error name (e.g., "TypeError", "AssertionError") |
| `message` | string | Error message |
| `checksum` | string | MD5 hash of error for deduplication |
| `id` | string (UUID) | Unique error ID |
| `timestamp` | int64 | Unix timestamp when error occurred |
| `stacktrace` | array | Stack trace (if available) |

---

## Key Differences from Native Format

| Aspect | Newman Structure | Native Structure |
|--------|------------------|------------------|
| **Top-level** | 4 objects: collection, environment, globals, run | 1 object: run |
| **Stats location** | `run.stats` (structured by category) | `run.summary` (flat structure) |
| **Assertions count** | `run.stats.assertions.total` | `run.summary.tests.executed` |
| **Failures** | Dedicated `run.failures` array | Embedded in executions |
| **Collection def** | Included in `collection` | Not included |
| **Environment** | Included in `environment` | Not included |
| **File size** | Larger due to full collection/env (~5.87MB for 65 requests) | Smaller for partial runs (~2.12MB for 65 requests) |
| **Execution details** | More structured | More verbose |

---

## File Size Considerations

The Newman structure format can vary in size compared to the native format:
- **Newman structure** (Oct 3, 2025): ~5.87MB for 65 requests (apInvoices only)
- **Native format** (Oct 3, 2025): ~2.12MB for same run

**Note**: The Newman structure includes the full collection definition, environment, and globals sections, which adds overhead. For smaller, filtered collections, the native format may be more compact. For larger, full collections, the difference may vary.

Both formats include full response bodies as byte arrays in `stream` objects.

---

## Use Cases

### Quick Statistics
Access `run.stats` for immediate aggregate metrics without parsing execution details.

### Failure Analysis
Use `run.failures` array to quickly identify all errors and their locations.

### Assertion Comparison
Compare `run.stats.assertions.total` between runs to detect changes in test counts.

### Environment Debugging
Review `environment` and `globals` sections to verify variable values used during execution.

### Execution Flow
Use `executions[].cursor` to understand execution order and iteration flow.

---

## Schema Version
This schema is based on Newman (Postman CLI) output with `--reporter-json-structure newman` as of October 2025.

