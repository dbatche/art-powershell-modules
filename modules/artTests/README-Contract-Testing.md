# Contract-Based API Testing with PowerShell

**Date**: October 13, 2025 (Updated)  
**Author**: Doug Batchelor + AI Assistant

## Overview

Moving from manually-crafted tests to **contract-driven tests** based on the OpenAPI specification. This ensures our tests match the actual API contract, not our assumptions.

## Key Discovery

### The "Minimum Fields" Mystery

**Question**: Why do our tests use 5 fields, Postman uses 3, but the API accepts ANY single field?

**Answer**: The OpenAPI contract specifies **NO REQUIRED FIELDS** for POST `/fuelTaxes/{fuelTaxId}/tripFuelPurchases`!

```
Schema: PostFuelTaxTripFuelPurchaseDto
  • Type: array of objects
  • Total Properties: 36
  • Required Fields: NONE ⚠
```

This means:
- ✅ API accepts ANY combination of fields
- ✅ Even a single field works
- ✅ Only constraint: Must be a non-empty array
- ⚠ Our "minimum fields" tests were **arbitrary**, not contractual

## Tools Created

### 1. Get-OpenApiSpecFromUrl (Function)

**Purpose**: Download OpenAPI specification from URL and save to file.

**Features**:
- Fetches OpenAPI spec from any URL
- Supports bearer token authentication
- Saves to timestamped or custom path
- Returns file path for chaining

**Usage**:
```powershell
# Download spec (timestamped file)
$specFile = Get-OpenApiSpecFromUrl -Url "https://api.com/openapi.json" -Token $token

# Download with custom path
$specFile = Get-OpenApiSpecFromUrl -Url "https://api.com/openapi.json" -Token $token -OutputPath "my-api.json"
```

### 2. Get-OpenApiEndpoints (Function) ⭐ NEW!

**Purpose**: Discover all available endpoints and methods in an OpenAPI spec before analyzing specific ones.

**Features**:
- Lists all paths and HTTP methods from spec
- Filter by method type (GET, POST, PUT, etc.)
- Shows operation IDs, summaries, request body status, response codes
- Output formats: Table, List, or Object (for automation)
- Optional save to JSON file

**Usage**:
```powershell
# List all endpoints
Get-OpenApiEndpoints -SpecFile "openapi-visibility.json"

# Filter by POST methods only
Get-OpenApiEndpoints -SpecFile "openapi-finance.json" -Method POST -OutputFormat List

# Get as objects for automation
$endpoints = Get-OpenApiEndpoints -SpecFile "openapi.json" -OutputFormat Object
foreach ($ep in $endpoints | Where-Object { $_.Method -eq 'POST' }) {
    Write-Host "Found POST endpoint: $($ep.Path)"
    # Feed to Analyze-OpenApiSchema...
}

# Save endpoint list to file
Get-OpenApiEndpoints -SpecFile "openapi.json" -OutputFile "endpoints.json"
```

**Output Example**:
```
POST /shipmentStatus
  Summary: Create shipment status
  Operation: PostShipmentStatus
  Tags: Shipment Status
  Request Body: Yes
  Responses: 201, 400, 401, 403

POST /stopStatus
  Summary: Create stop status
  Operation: PostStopStatus
  Tags: Stop Status
  Request Body: Yes
  Responses: 201, 400, 401, 403
```

### 3. Analyze-OpenApiSchema (Function)

**Purpose**: Analyze OpenAPI contracts for specific endpoints.

**Features**:
- Reads from local OpenAPI JSON file
- Resolves `$ref` references automatically
- Extracts request/response schemas
- Identifies required fields, data types, constraints
- Shows all property details (min/max length, patterns, enums, etc.)

**Usage**:
```powershell
# Analyze a specific endpoint
$contract = Analyze-OpenApiSchema `
    -SpecFile $specFile `
    -Path "/fuelTaxes/{fuelTaxId}/tripFuelPurchases" `
    -Method "POST" `
    -OutputFile "contract.json"

# Access contract details
$contract.RequestSchema.Required  # Required fields
$contract.RequestSchema.Properties  # All properties with constraints
$contract.ResponseSchemas['201']  # 201 response schema
```

**Combined Workflow** (Updated with endpoint discovery):
```powershell
# Step 1: Download spec once
$specFile = Get-OpenApiSpecFromUrl -Url $url -Token $token

# Step 2: Discover all available endpoints ⭐ NEW!
Get-OpenApiEndpoints -SpecFile $specFile -OutputFormat List

# Step 3: Analyze specific endpoints (fast, no re-download)
$contract1 = Analyze-OpenApiSchema -SpecFile $specFile -Path "/items" -Method "POST"
$contract2 = Analyze-OpenApiSchema -SpecFile $specFile -Path "/items" -Method "PUT"
$contract3 = Analyze-OpenApiSchema -SpecFile $specFile -Path "/items/{id}" -Method "GET"

# OR: Automate analysis of all POST endpoints
$endpoints = Get-OpenApiEndpoints -SpecFile $specFile -Method POST -OutputFormat Object
foreach ($ep in $endpoints) {
    Write-Host "Analyzing: $($ep.Method) $($ep.Path)"
    $contract = Analyze-OpenApiSchema -SpecFile $specFile -Path $ep.Path -Method $ep.Method
    # Generate tests, execute, validate...
}
```

**Output Example**:
```
Request Body Contract:
  Type: array of object
  Required fields: NONE ⚠
  Total properties: 36

Properties Detail:
  • purchaseDate [REQUIRED]
      Type: string (date-time)
      Pattern: ^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$
  
  • fuelVolume1
      Type: number
      Minimum: 0
  
  • purchaseLocation
      Type: string
      MaxLength: 30
  
  ... (33 more properties)
```

## Three-Stage Contract Testing Architecture

### Stage 1: Generate Tests from Contract ✅ IMPLEMENTED

**Function**: `New-ContractTests` (Public function)

```powershell
# Download spec first
$specFile = Get-OpenApiSpecFromUrl -Url "https://api.com/openapi.json" -Token $token

# Analyze the contract
$contract = Analyze-OpenApiSchema -SpecFile $specFile -Path "/items" -Method "POST"

# Generate comprehensive tests
$tests = New-ContractTests `
    -Contract $contract `
    -BaseUrl "/items" `
    -OutputFile "test-items-POST.ps1" `
    -IncludeSuccessTests $true `
    -IncludeConstraintTests $true `
    -IncludeTypeTests $true `
    -IncludeParameterTests $true `
    -IncludeMalformedJsonTests $true
```

**Generated Test Categories**:
1. **Required Field Tests**
   - Missing each required field → 400 with `missingRequiredField` error code
   - Empty object test (no fields) → 400 with `noValidFields` error code
   - All required fields present → 201
   
2. **Data Type Tests**
   - Invalid types for each property → 400 with `invalidInteger`, `invalidBoolean`, etc.
   - Valid types → 201
   
3. **Constraint Tests**
   - Min/Max length violations → 400 with `invalidMaxLength`, `invalidMinLength`
   - Min/Max value violations → 400 with `invalidMinimum`, `invalidMaximum`
   - Pattern violations → 400 with `invalidFormat`
   - Enum value violations → 400 with `invalidEnum`
   - Within constraints → 201

4. **Query Parameter Tests** ⭐ NEW!
   - Missing required parameters → 400 with `missingRequiredParameter`
   - Invalid enum values → 400 with `invalidEnum`
   - Invalid types → 400 with `invalidInteger`, `invalidBoolean`
   - **Pagination Tests**: negative/decimal/out-of-bounds for `offset`, `limit`, `skip`, `page`
   - **OData Tests**: invalid syntax for `$select`, `$filter`, `$orderBy`

5. **Malformed JSON Tests** ⭐ NEW!
   - Unclosed braces → 400 with `malformedJson`
   - Invalid JSON syntax → 400 with `malformedJson`
   - Non-JSON body → 400 with `malformedJson`
   - Empty string body → 400 with `malformedJson`
   - Null characters → 400 with `malformedJson`
   - Trailing commas → 400 with `malformedJson`

6. **Error Code Validation** ⭐ NEW!
   - Every 400 test includes `ExpectedErrorCode` property
   - Enables granular validation beyond just status codes
   - Validates API returns correct error codes in `errors` array

### Stage 2: Execute Tests ✅ IMPLEMENTED

**Function**: `Run-ApiTests` (Public function)
```powershell
# Run tests with automatic error code extraction
$results = Run-ApiTests `
    -RequestsFile "test-items-POST.ps1" `
    -BaseUrl $env:API_BASEURL `
    -Token $env:TRUCKMATE_API_TOKEN `
    -ValidateJson

# Results automatically include:
# - ExpectedStatus vs ActualStatus
# - ExpectedErrorCode vs ActualErrorCodes (extracted from response body)
# - Request/response bodies
# - Execution time
```

**Features**:
- **Automatic Logging**: Saves to `50-test-results/` with timestamp
- **RawBody Support**: Sends malformed JSON strings for error testing
- **Error Code Extraction**: Automatically extracts error codes from API responses
- **JSON Validation**: Optional validation of response structure

### Stage 3: Validate Contract Compliance ✅ IMPLEMENTED

**Functions**: 
- `Test-ContractCompliance` - Schema validation (existing)
- `Test-ErrorCodeCompliance` - Error code validation (new) ⭐

```powershell
# Validate error codes in test results
Test-ErrorCodeCompliance -LogFile "test-results.json"

# Or validate directly from results
$results = Run-ApiTests -RequestsFile "tests.ps1"
Test-ErrorCodeCompliance -TestResults $results -ShowOnlyFailures
```

**Validation Checks**:
1. **Status Code Validation**
   - ExpectedStatus matches ActualStatus
   - Automatic pass/fail determination

2. **Error Code Validation** ⭐ NEW!
   - ExpectedErrorCode present in ActualErrorCodes array
   - Extracts codes from `errors` array in response body
   - Supports custom error codes (e.g., `invalidDBValue`, `invalidBusinessLogic`)
   - Detailed reporting of matches and mismatches

3. **Schema Validation**
   - Response matches OpenAPI schema
   - All required fields present
   - Data types match contract
   - Constraints satisfied

## Contract Test Categories

### 1. Required Field Tests

**For APIs with required fields**:
```powershell
# Missing required field 'name'
@{ Name = 'POST - missing required field: name';
   Method = 'POST';
   Url = '/items';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'missingRequiredField';  # ⭐ NEW
   Body = @( @{ 
       price = 100.00 
       # name is missing
   } ) }
```

**For tripFuelPurchases (NO required fields)**:
```powershell
# Any single field should work
@{ Name = 'POST - single field (purchaseDate)';
   Method = 'POST';
   Url = '/fuelTaxes/2/tripFuelPurchases';
   ExpectedStatus = 201;
   Body = @( @{ purchaseDate = '2025-01-15T10:00:00' } ) }

# Empty object should fail
@{ Name = 'POST - empty object';
   Method = 'POST';
   Url = '/fuelTaxes/2/tripFuelPurchases';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'noValidFields';  # ⭐ NEW
   Body = @( @{} ) }
```

### 2. Data Type Tests

```powershell
# Volume as string (should be number)
@{ Name = 'POST - invalid type: fuelVolume1';
   Method = 'POST';
   Url = '/fuelTaxes/2/tripFuelPurchases';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'invalidNumber';  # ⭐ NEW
   Body = @( @{ fuelVolume1 = 'not-a-number' } ) }
```

### 3. Constraint Tests

```powershell
# purchaseLocation exceeds maxLength of 30
@{ Name = 'POST - exceeds maxLength: purchaseLocation';
   Method = 'POST';
   Url = '/fuelTaxes/2/tripFuelPurchases';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'invalidMaxLength';  # ⭐ NEW
   Body = @( @{ 
       purchaseLocation = 'A' * 31  # 31 chars, max is 30
   } ) }

# Enum violation
@{ Name = 'POST - invalid enum: purchaseType';
   Method = 'POST';
   Url = '/fuelTaxes/2/tripFuelPurchases';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'invalidEnum';  # ⭐ NEW
   Body = @( @{ 
       purchaseType = 'invalidType'  # Valid: bulk, keyLock, station
   } ) }
```

### 4. Query Parameter Tests ⭐ NEW

```powershell
# Missing required query parameter
@{ Name = 'GET - missing required parameter: sourceType';
   Method = 'GET';
   Url = '/userFieldsData';  # sourceType is required
   ExpectedStatus = 400;
   ExpectedErrorCode = 'missingRequiredParameter';
   Body = $null }

# Invalid pagination value
@{ Name = 'GET - pagination parameter negative: offset';
   Method = 'GET';
   Url = '/orders?offset=-5';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'invalidMinimum';
   Body = $null }

# Invalid OData syntax
@{ Name = 'GET - invalid OData syntax: $filter';
   Method = 'GET';
   Url = '/orders?$filter=invalid syntax here';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'invalidODataSyntax';
   Body = $null }
```

### 5. Malformed JSON Tests ⭐ NEW

```powershell
# Unclosed brace
@{ Name = 'POST - malformed JSON: unclosed brace';
   Method = 'POST';
   Url = '/items';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'malformedJson';
   RawBody = '{ "name": "test"' }  # Missing closing }

# Trailing comma
@{ Name = 'POST - malformed JSON: trailing comma';
   Method = 'POST';
   Url = '/items';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'malformedJson';
   RawBody = '{ "name": "test", }' }  # Trailing comma

# Empty string
@{ Name = 'POST - malformed JSON: empty string';
   Method = 'POST';
   Url = '/items';
   ExpectedStatus = 400;
   ExpectedErrorCode = 'malformedJson';
   RawBody = '' }
```

## Files Created/Updated

### Core Contract Testing Functions ✅
1. **Get-OpenApiSpecFromUrl.Public.ps1** ✅
   - Downloads OpenAPI spec from URL
   - Saves to JSON file (timestamped or custom)
   - Returns file path for chaining

2. **Get-OpenApiEndpoints.Public.ps1** ✅
   - Discovers all endpoints in an OpenAPI spec
   - Filter by method type
   - Output formats: Table, List, Object

3. **Analyze-OpenApiSchema.Public.ps1** ✅
   - Analyzes OpenAPI contracts from file
   - Resolves $ref references
   - Extracts schemas, constraints, required fields, parameters

4. **New-ContractTests.Public.ps1** ✅ FULLY IMPLEMENTED
   - Generates comprehensive contract tests
   - Supports all test categories (required, type, constraint, parameter, malformed)
   - Auto-adds ExpectedErrorCode to all tests
   - Pagination and OData query parameter tests
   - Malformed JSON tests with RawBody

### Test Execution and Validation Functions ✅
5. **Run-ApiTests.Public.ps1** ✅ (Enhanced)
   - Executes tests with RawBody support
   - Auto-extracts error codes from responses
   - Automatic logging to 50-test-results/

6. **Test-ContractCompliance.Public.ps1** ✅
   - Validates responses against OpenAPI schema
   - Checks data types, required fields, constraints

7. **Test-ErrorCodeCompliance.Public.ps1** ✅ NEW!
   - Validates error codes in test results
   - Compares ExpectedErrorCode vs ActualErrorCodes
   - Detailed reporting of matches/mismatches

### Helper Functions ✅
8. **New-ManualTestDefinition.Public.ps1** ✅ (Enhanced)
   - Create/append manual test definitions
   - Supports ExpectedErrorCode
   - Supports RawBody for malformed JSON tests

9. **Update-TestDefinition.Public.ps1** ✅ (Enhanced)
   - Update test definitions in place
   - Supports SetExpectedErrorCode
   - Fixed double-encoding bug

10. **ConvertTo-PowerShellLiteral.Public.ps1** ✅ NEW!
    - Converts objects to PowerShell literal format
    - Shared by New/Update-TestDefinition
    - Prevents double-encoding issues

11. **Repair-OpenApiSpec.ps1** ✅ NEW!
    - Pre-processes OpenAPI specs with case-sensitive duplicate keys
    - Enables parsing by PowerShell without -AsHashtable
    - Recursively cleans JSON structure

### Documentation ✅
12. **README-Contract-Testing.md** ✅
    - This document
    - Contract testing approach
    - Examples and patterns

**Design Pattern**: One function per file with `.Public.ps1` extension for auto-loading by module system.

## Implementation Status

### ✅ COMPLETED (October 9-13, 2025)

All three stages of the contract testing architecture are now fully implemented:

1. ✅ **Contract Test Generation** (New-ContractTests)
   - Required field tests with error codes
   - Data type validation tests
   - Constraint violation tests (min/max length, enums, patterns)
   - Query parameter tests (pagination + OData)
   - Malformed JSON tests (RawBody support)
   - Auto-adds ExpectedErrorCode to all tests

2. ✅ **Test Execution** (Run-ApiTests)
   - RawBody support for malformed JSON
   - Automatic error code extraction from responses
   - Comprehensive logging
   - JSON validation integration

3. ✅ **Contract Compliance Validation**
   - Test-ContractCompliance (schema validation)
   - Test-ErrorCodeCompliance (error code validation)
   - Detailed reporting

### 🔄 Future Enhancements (Optional)

1. **Batch Contract Testing**
   - Auto-generate tests for all endpoints in a spec
   - Generate test coverage report
   - Identify endpoints without tests

2. **Contract Diff Tool**
   - Compare two OpenAPI spec versions
   - Identify breaking changes
   - Auto-generate regression tests for changes

3. **Enhanced Mock Data Generation**
   - Generate realistic test data from schemas
   - Handle complex nested objects
   - Create boundary test case data sets

4. **Test Result Analytics**
   - Historical test result tracking
   - Trend analysis (pass rate over time)
   - Identify flaky tests

5. **Performance Testing Integration**
   - Add response time tracking
   - Performance baseline testing
   - Load test generation from contract

## Benefits of Contract Testing

### Over Manual Test Creation
- ✅ **Accurate**: Tests match actual contract, not assumptions
- ✅ **Complete**: Covers all properties and constraints
- ✅ **Maintainable**: Regenerate when contract changes
- ✅ **Discoverable**: Reveals contract gaps (like "no required fields")

### Over Postman Only
- ✅ **Automated Generation**: Create 100+ tests in seconds
- ✅ **Three-Stage Architecture**: Separate generate/execute/validate
- ✅ **PowerShell Native**: Fits our existing workflow
- ✅ **Contract-First**: OpenAPI spec is source of truth

## Integration with Existing Framework

Contract tests work seamlessly with existing tools:

```powershell
# 0. Download OpenAPI spec (once)
$specFile = Get-OpenApiSpecFromUrl -Url $url -Token $token

# 1. Generate contract tests
.\New-ContractTests.ps1 -SpecFile $specFile -Path "/items" -Method "POST" -OutputFile "tests.ps1"

# 2. Run tests (existing runner)
.\Run-ApiTests-IRM.ps1 -RequestsFile "tests.ps1" -LogFile "log.json" -ValidateJson

# 3. Analyze results (existing analyzer)
.\Analyze-TestLog.ps1 -LogFile "log.json" -ShowFailures -FormatTable

# 4. Validate contract compliance (new)
.\Test-ContractCompliance.ps1 -LogFile "log.json" -ContractFile "contract.json"
```

## Comparison: Manual vs Contract Testing

| Aspect | Manual Tests | Contract Tests |
|--------|-------------|----------------|
| **Creation Time** | Minutes per endpoint | Seconds per endpoint |
| **Accuracy** | Based on assumptions | Based on actual contract |
| **Coverage** | Partial (what we think of) | Complete (all constraints) |
| **Maintenance** | Manual updates needed | Regenerate from contract |
| **Discovery** | Miss edge cases | Reveal contract gaps |
| **Required Fields** | Guessed (5 fields) | Actual (0 fields ⚠) |
| **Error Codes** ⭐ | Manual validation | Auto-validated per test |
| **Malformed JSON** ⭐ | Rarely tested | 6 tests per endpoint |
| **Query Parameters** ⭐ | Often missed | Auto-generated (pagination + OData) |
| **Test Count** | 5-10 per endpoint | 40-100+ per endpoint |

## Real-World Example: tripFuelPurchases

### Before (Manual Testing)
```powershell
# Assumed 5 "required" fields
Body = @( @{
    purchaseDate = '2025-01-15T10:30:00'
    fuelVolume1 = 150.5
    fuelAmount1 = 225.75
    fuelType1 = 'DIESEL'
    purchaseLocation = 'Test Location'
} )
```

### After (Contract Testing)
```powershell
# Contract says: NO required fields!
# Test with 1 field
Body = @( @{ fuelVolume1 = 100.0 } )  # Should work ✓

# Test with 0 fields
Body = @( @{} )  # Should fail (noValidFields) ✓

# Test with all 36 fields
Body = @( @{ 
    # ... all 36 properties with valid values
} )  # Should work ✓
```

## Key Learnings

1. **Never Assume Required Fields** - Always check the contract
2. **OpenAPI is Source of Truth** - Not documentation, not examples
3. **Constraints Matter** - maxLength=30 for purchaseLocation (found it!)
4. **Enums are Contracts** - purchaseType: bulk, keyLock, station only
5. **Contract Gaps are Bugs** - No required fields might be intentional or oversight
6. **Error Codes Matter** ⭐ - Status code alone is insufficient; validate specific error codes
7. **Query Parameters are Part of the Contract** ⭐ - Don't forget required parameters!
8. **Malformed JSON Must Be Tested** ⭐ - API layer should catch JSON errors before business logic

---

## Recent Enhancements (October 13, 2025) ⭐

### 1. Error Code Validation System
- **ExpectedErrorCode** property added to all contract tests
- Automatic extraction of error codes from API responses
- New `Test-ErrorCodeCompliance` function for validation
- Granular validation beyond status codes (e.g., `missingRequiredField` vs `invalidMaxLength`)

### 2. Malformed JSON Testing
- **RawBody** property for sending invalid JSON strings
- 6 malformed JSON tests per POST/PUT/PATCH endpoint
- Tests unclosed braces, trailing commas, null characters, empty strings, etc.

### 3. Query Parameter Testing
- **Missing required parameter** tests for ALL methods (not just GET)
- **Pagination tests**: negative, decimal, out-of-bounds for `offset`, `limit`, `skip`, `page`
- **OData tests**: invalid syntax for `$select`, `$filter`, `$orderBy`
- Discovered special case: `/userFieldsData` with 3 required query parameters on PUT!

### 4. PowerShell Helper Improvements
- Extracted `ConvertTo-PowerShellLiteral` as standalone function
- Fixed double-encoding bug in `Update-TestDefinition`
- Added `SetExpectedErrorCode` parameter to `Update-TestDefinition`
- Enhanced `New-ManualTestDefinition` with `RawBody` and `ExpectedErrorCode` support

### 5. OpenAPI Parsing Enhancements
- Created `Repair-OpenApiSpec.ps1` to handle case-sensitive duplicate keys
- Enables parsing problematic OpenAPI specs with PowerShell

---

## Achievement Summary

**Status**: ✅ **FULLY IMPLEMENTED**  
**Test Coverage**: Achieved **Postman parity** and beyond  
**Validation Levels**: 
- ✅ Status codes (200, 400, 404, etc.)
- ✅ Error codes (`missingRequiredField`, `invalidMaxLength`, etc.)
- ✅ Response schemas (data types, required fields, constraints)

**Impact**: 
- 🚀 Contract-driven testing fully operational
- 🚀 40-100+ tests per endpoint generated in seconds
- 🚀 Comprehensive validation at multiple levels
- 🚀 Automatic error code extraction and validation

