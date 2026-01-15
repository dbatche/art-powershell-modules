# Scenario-Based Testing Guide

## Overview

This guide explains the enhanced testing structure that separates **Scenarios** (actual API calls) from **Assertions** (checks on responses), with improved logging for both troubleshooting and manual data lookups.

## Key Concepts

### Scenarios vs Assertions

**Scenario** = Actual API request under test (GET, PUT, POST, DELETE)
- Represents a real API interaction
- Can have multiple assertions
- Logs key data for manual lookups

**Assertion** = Individual check on the API response
- Properties exist
- Values match expectations
- Error codes are correct
- Performance metrics

### Example Structure

```
Scenario 1: GET /interlinerPayables/{id}
  ✅ Returns single payable
  ✅ Has interlinerPayableId property
  ✅ Has originalAmount property
  ✅ Matches requested ID

Scenario 2: PUT /interlinerPayables/{id} (valid update)
  ✅ Update succeeds
  ✅ Returns updated value
```

## New Functions

### 1. `Initialize-TestResults`

Initialize test tracking with optional JSON log file.

```powershell
# Simple initialization
Initialize-TestResults

# With JSON logging for manual lookups
Initialize-TestResults -LogFile "interliner-test-data.json"
```

### 2. `Start-TestScenario`

Begin a new test scenario (actual API call).

```powershell
Start-TestScenario "GET /interlinerPayables/{id}" -Description "Retrieve single payable"
```

### 3. `Test-Assertion`

Record an assertion within the current scenario.

```powershell
Test-Assertion "Returns single payable" -Passed ($result -isnot [string])
Test-Assertion "Has required properties" -Passed ($result.id -ne $null)
```

### 4. `Write-TestInfo`

Log key data for manual lookups in UI/database.

```powershell
# Simple message
Write-TestInfo "Using payable ID: 9"

# Structured data (logged to JSON)
Write-TestInfo -Data @{
    payableId = 9
    originalAmount = 830
    newAmount = 840.50
}
```

### 5. `Show-TestSummary`

Display summary and write JSON log file.

```powershell
Show-TestSummary -ShowFailedTests
```

### 6. `Invoke-TestApiCall`

Wrapper for API calls that captures stderr to log file.

```powershell
# Instead of 2>$null (loses errors)
$result = Set-InterlinerPayable ... 2>$null

# Use this (logs errors to file)
$result = Invoke-TestApiCall {
    Set-InterlinerPayable ...
}
```

## Complete Example

```powershell
# Import modules
Import-Module artTests -Force -WarningAction SilentlyContinue
Import-Module artFinance -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

# Initialize with logging
Initialize-TestResults -LogFile "test-data.json"

# Scenario 1: GET collection
Start-TestScenario "GET /interlinerPayables" -Description "Retrieve collection"

$payables = Get-InterlinerPayables -Limit 5

Test-Assertion "Returns data without error" -Passed ($payables -isnot [string])
Test-Assertion "Returns array" -Passed ($payables -is [array])

Write-TestInfo -Data @{ count = $payables.Count }

# Scenario 2: PUT update
Start-TestScenario "PUT /interlinerPayables/{id}" -Description "Update valid field"

$payableId = $payables[0].interlinerPayableId
$newExtras = 100.50

Write-TestInfo "Updating payable ID: $payableId"
Write-TestInfo -Data @{
    payableId = $payableId
    newExtras = $newExtras
}

$result = Invoke-TestApiCall {
    Set-InterlinerPayable -InterlinerPayableId $payableId -InterlinerPayable @{
        adjustedExtras = $newExtras
    }
}

Test-Assertion "Update succeeds" -Passed ($result -isnot [string])
Test-Assertion "Returns updated value" -Passed ($result.adjustedExtras -eq $newExtras)

# Summary
Show-TestSummary -ShowFailedTests
```

## Output

### Console Output
```
================================================================================
INTERLINER PAYABLES API TESTS
================================================================================

[1] GET /interlinerPayables
    Retrieve collection
    ✅ Returns data without error
    ✅ Returns array

[2] PUT /interlinerPayables/{id}
    Update valid field
    ℹ️  Updating payable ID: 9
    ✅ Update succeeds
    ✅ Returns updated value

================================================================================
TEST SUMMARY
================================================================================
Scenarios: 2
Assertions: 4
Passed: 4
Failed: 0

Test data logged to: test-data.json
```

### JSON Log File (test-data.json)
```json
{
  "startTime": "2025-10-17 10:08:37",
  "endTime": "2025-10-17 10:08:43",
  "duration": 5.8,
  "scenarios": [
    {
      "name": "GET /interlinerPayables",
      "description": "Retrieve collection",
      "keyData": {
        "count": 5
      },
      "assertions": [
        {"name": "Returns data without error", "passed": true},
        {"name": "Returns array", "passed": true}
      ]
    },
    {
      "name": "PUT /interlinerPayables/{id}",
      "description": "Update valid field",
      "keyData": {
        "payableId": 9,
        "newExtras": 100.50
      },
      "assertions": [
        {"name": "Update succeeds", "passed": true},
        {"name": "Returns updated value", "passed": true}
      ]
    }
  ],
  "totalAssertions": 4,
  "passed": 4,
  "failed": 0
}
```

## Stderr Handling (Stream 2)

### Problem
The `2>$null` redirection suppresses `Write-Error` output completely, losing valuable troubleshooting information.

### Solutions

**Option 1: Direct redirection to log file**
```powershell
$result = Set-InterlinerPayable ... 2>> "test-errors.log"
```

**Option 2: Using helper function (recommended)**
```powershell
$result = Invoke-TestApiCall {
    Set-InterlinerPayable ...
}
```

Both capture stderr to a log file for later review while keeping console output clean.

## Two-Tier Logging

### Tier 1: HTTP Details (Troubleshooting)
Use PowerShell's built-in verbose preference:
```powershell
$VerbosePreference = 'Continue'
.\MyTest.ps1
```

Shows:
- HTTP method and URL
- Request/response sizes
- Content types

### Tier 2: Key Data (Manual Lookups)
Use `Write-TestInfo` with JSON logging:
```powershell
Write-TestInfo -Data @{
    payableId = 9
    originalAmount = 830
}
```

Logged to JSON file for:
- Looking up records in UI
- Database queries
- Audit trails

## Migration Guide

### Old Style (Test-Result)
```powershell
Initialize-TestResults

Write-Host "[1] Testing: Get payable..."
$payable = Get-InterlinerPayables -Limit 1
Test-Result "Get payable" -Passed ($payable -isnot [string])

Show-TestSummary
```

### New Style (Scenarios)
```powershell
Initialize-TestResults -LogFile "test-data.json"

Start-TestScenario "GET /interlinerPayables" -Description "Retrieve payable"
$payable = Get-InterlinerPayables -Limit 1
Write-TestInfo -Data @{ count = 1 }

Test-Assertion "Returns data" -Passed ($payable -isnot [string])
Test-Assertion "Has ID" -Passed ($payable.interlinerPayableId -ne $null)

Show-TestSummary -ShowFailedTests
```

## Benefits

✅ **Clear Structure** - Scenarios (API calls) separated from assertions (checks)  
✅ **Better Logging** - JSON file with key data for manual lookups  
✅ **Error Capture** - Stderr logged to file instead of suppressed  
✅ **Multiple Assertions** - Test multiple aspects of each API call  
✅ **Troubleshooting** - Verbose mode shows HTTP details  
✅ **CI/CD Ready** - Structured output and exit codes  

## See Also

- `InterlinerPayables-Scenario.ps1` - Full example
- `_stderr-examples.ps1` - Stderr handling demonstration
- `CashReceipts-PlainScript.ps1` - Old style (still valid)

