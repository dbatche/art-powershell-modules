# Contract Tests - Organized by API

This folder contains **contract-based tests** that validate API behavior against the OpenAPI specification, focusing on **4xx error handling** (input validation before database calls).

## ⚠️ IMPORTANT: Tests Must Be Contract-Driven

**Contract tests must be based on the OpenAPI specification, not arbitrary edge cases.**

### For AI Assistants Reading This

When creating contract tests:

1. **ALWAYS check the OpenAPI spec first** using:
   ```powershell
   Analyze-OpenApiSchema -SpecFile "finance-openapi-*.json" -SchemaName "UpdateApInvoiceDto"
   ```

2. **Only test what the contract specifies**:
   - ✅ **DO test**: Required fields (missing required field)
   - ✅ **DO test**: Field types (string when number expected)
   - ✅ **DO test**: Enum values (invalid enum value)
   - ✅ **DO test**: Min/Max constraints (if specified in spec)
   - ✅ **DO test**: Pattern/Format validation (if specified)
   - ✅ **DO test**: Query parameters (like `$select`, `$filter` if in spec)
   - ❌ **DON'T test**: Arbitrary edge cases not in contract (e.g., large numbers if no `maximum` specified)
   - ❌ **DON'T test**: Negative numbers if no `minimum` specified
   - ❌ **DON'T test**: Unknown/typo field names (APIs typically ignore these)

3. **Test structure based on OpenAPI elements**:

   **Path Parameters:**
   - Non-existent ID (404)
   - Invalid type (string when number expected)

   **Request Body:**
   - Missing required fields
   - Wrong field types
   - Invalid enum values
   - Min/max violations (if specified)
   - Pattern violations (if specified)

   **Query Parameters:**
   - Invalid `$select` fields
   - Invalid `$filter` syntax
   - Invalid `$orderby` fields
   - Out-of-range `limit`/`offset`

4. **Example - What to test for a field**:
   ```json
   "vendorBillAmount": {
     "type": "number",
     "format": "double",
     "minimum": 0,
     "maximum": 999999.99
   }
   ```
   **Tests needed:**
   - ✅ String instead of number (type validation)
   - ✅ Negative value (minimum violation)
   - ✅ Value > 999999.99 (maximum violation)

   ```json
   "invoiceNumber": {
     "type": "string",
     "maxLength": 50,
     "pattern": "^[A-Z0-9-]+$"
   }
   ```
   **Tests needed:**
   - ✅ String > 50 chars (maxLength violation)
   - ✅ Invalid characters (pattern violation)
   - ✅ Number instead of string (type validation)

   ```json
   "status": {
     "type": "string",
     "enum": ["pending", "approved", "rejected"]
   }
   ```
   **Tests needed:**
   - ✅ Invalid enum value ("invalid_status")
   - ✅ Wrong type (number instead of string)

5. **Check for query parameters in the spec**:
   - If endpoint supports `$select`, test invalid field names
   - If endpoint supports `$filter`, test invalid syntax
   - If endpoint supports `$orderby`, test invalid fields
   - If endpoint has `limit`/`offset`, test negative/out-of-range values

### Related Documentation

- [Contract Testing Guide](../../README-Contract-Testing.md)
- [API Function Creation Guide](../../@documentation/API-Function-Creation-Guide.md)

## Structure

```
50-contract-tests/
├── finance/
│   ├── apInvoices/
│   │   ├── Set-ApInvoice-Contract.ps1    ← PUT tests
│   │   ├── New-ApInvoice-Contract.ps1    ← POST tests (future)
│   │   └── Get-ApInvoices-Contract.ps1   ← GET tests (future)
│   ├── cashReceipts/
│   └── checks/
├── tm/
│   ├── orders/
│   └── trips/
└── masterdata/
    ├── clients/
    └── vendors/
```

## Naming Convention

- `{FunctionName}-Contract.ps1` - Manual/exploratory contract test script
- `{FunctionName}-Contract.Tests.ps1` - Pester version with assertions

## Test Focus: 4xx Errors

These tests validate **controller-level validation** (before DB calls):

### Common 4xx Scenarios

1. **404 - Resource Not Found**
   - Non-existent ID
   - Deleted resource

2. **400 - Bad Request**
   - Invalid field types
   - Invalid field values
   - Unknown/typo field names
   - Missing required fields
   - Invalid format (dates, enums, etc.)

3. **401/403 - Authentication/Authorization**
   - Invalid token
   - Insufficient permissions

## Workflow

### 1. Initial Exploration (Manual Script)
```powershell
# Run the plain script to see actual API responses
.\Set-ApInvoice-Contract.ps1
```

### 2. Review Results
- Check actual error codes returned
- Compare against OpenAPI spec
- Document expected vs actual behavior

### 3. Check OpenAPI Spec
```powershell
Analyze-OpenApiSchema -SpecFile finance-openapi-*.json -SchemaName 'UpdateApInvoiceDto'
```

### 4. Convert to Pester Tests
Once you know expected behavior, create assertions:
```powershell
Describe "Set-ApInvoice Contract Tests" {
    It "Returns 404 for non-existent apInvoiceId" {
        $result = Set-ApInvoice -ApInvoiceId 999999999 -ApInvoice $invoice
        $error = $result | ConvertFrom-Json
        $error.error.status | Should -Be 404
        $error.error.errors[0].code | Should -Be "resourceNotFound"
    }
}
```

## Related Documentation

- [Contract Testing Guide](../../README-Contract-Testing.md)
- [API Function Creation Guide](../../@documentation/API-Function-Creation-Guide.md)

## Benefits of This Structure

✅ **Organized by API** - Easy to find tests for specific APIs  
✅ **Mirrors module structure** - Familiar hierarchy  
✅ **Separate from module code** - Keeps modules clean  
✅ **Clear naming** - `{Function}-Contract.ps1` convention  
✅ **Scalable** - Easy to add new APIs/resources

