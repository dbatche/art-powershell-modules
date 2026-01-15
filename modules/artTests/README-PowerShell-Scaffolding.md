# PowerShell API Test Scaffolding

**Date**: October 9, 2025  
**Author**: Doug Batchelor + AI Assistant

## Why PowerShell Over Postman for TDD?

### The Problem with Postman
- ❌ Postman API doesn't support creating requests programmatically
- ❌ Manual creation required before automation
- ❌ Slow iteration cycle
- ❌ Can't quickly generate full test coverage

### The PowerShell Solution
- ✅ **Fully automated** - generate tests from templates
- ✅ **Instant execution** - run 39 tests in seconds
- ✅ **Simple format** - hashtables, no complex DSL
- ✅ **Fast iteration** - edit file, re-run, done
- ✅ **Great discovery** - reveals validation gaps and bugs immediately

## Quick Start

### 1. Generate Test File
```powershell
# Copy template and customize
cp requests_finance_fuelTaxes.ps1 requests_finance_YOUR_ENDPOINT.ps1
# Edit: Update endpoint name, resource IDs, fields
```

### 2. Run Tests
```powershell
$baseUrl = "https://tde-truckmate.tmwcloud.com/fin/finance"
$token = "9ade1b0487df4d67dcdc501eaa317b91"

.\Run-ApiTests-IRM.ps1 `
    -BaseUrl $baseUrl `
    -Token $token `
    -RequestsFile ".\requests_finance_YOUR_ENDPOINT.ps1" |
    Format-Table
```

### 3. Analyze Results
```powershell
# Show only failures
$results | Where-Object { $_.Result -eq '✘' } | Format-Table

# Group by status code
$results | Group-Object ActualStatus | Select-Object Name, Count
```

## Test Template Structure

### Complete Endpoint Coverage
```powershell
@(
    # ========== GET Tests - Main Collection ==========
    @{ Name = 'GET all items'; Method = 'GET'; Url = '/items'; ExpectedStatus = 200 },
    @{ Name = 'GET items - pagination'; Method = 'GET'; Url = '/items?limit=10'; ExpectedStatus = 200 },
    
    # ========== GET Tests - Individual Item ==========
    @{ Name = 'GET items/1'; Method = 'GET'; Url = '/items/1'; ExpectedStatus = 200 },
    @{ Name = 'GET items - nonexistent'; Method = 'GET'; Url = '/items/999999'; ExpectedStatus = 404 },
    
    # ========== POST Tests - Success Cases ==========
    @{ Name = 'POST - minimal fields'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 201;
       Body = @( @{ field1 = 'value1'; field2 = 100 } ) },
    
    @{ Name = 'POST - all fields'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 201;
       Body = @( @{ field1 = 'value1'; field2 = 100; field3 = 'optional' } ) },
    
    @{ Name = 'POST - multiple items'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 201;
       Body = @( 
           @{ field1 = 'item1'; field2 = 100 },
           @{ field1 = 'item2'; field2 = 200 }
       ) },
    
    # ========== POST Tests - Validation ==========
    @{ Name = 'POST - not an array'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 400;
       Body = @{ field1 = 'value1' } },  # Note: NOT wrapped in @()
    
    @{ Name = 'POST - negative value'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 400;
       Body = @( @{ field1 = 'value1'; field2 = -100 } ) },
    
    @{ Name = 'POST - missing required field'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 400;
       Body = @( @{ field1 = 'value1' } ) },
    
    @{ Name = 'POST - invalid data type'; 
       Method = 'POST'; 
       Url = '/items'; 
       ExpectedStatus = 400;
       Body = @( @{ field1 = 'value1'; field2 = 'not-a-number' } ) },
    
    # ========== PUT Tests (if supported) ==========
    # Note: Requires actual IDs from POST results
    # @{ Name = 'PUT - update fields'; 
    #    Method = 'PUT'; 
    #    Url = '/items/1'; 
    #    ExpectedStatus = 200;
    #    Body = @{ field1 = 'updated' } },
    
    # ========== Query Parameter Tests ==========
    @{ Name = 'Filter - equals'; Method = 'GET'; Url = '/items?$filter=field1 eq ''value'''; ExpectedStatus = 200 },
    @{ Name = 'Select - specific fields'; Method = 'GET'; Url = '/items?$select=field1,field2'; ExpectedStatus = 200 },
    @{ Name = 'limit - negative'; Method = 'GET'; Url = '/items?limit=-10'; ExpectedStatus = 400 },
    @{ Name = 'offset - negative'; Method = 'GET'; Url = '/items?offset=-5'; ExpectedStatus = 400 },
    
    # ========== Edge Cases ==========
    @{ Name = 'Edge - empty array'; Method = 'POST'; Url = '/items'; ExpectedStatus = 400; Body = @() },
    @{ Name = 'Edge - very large value'; Method = 'POST'; Url = '/items'; ExpectedStatus = 201; Body = @( @{ field1 = 'test'; field2 = 99999 } ) },
    @{ Name = 'Edge - very long string'; Method = 'POST'; Url = '/items'; ExpectedStatus = 201; Body = @( @{ field1 = 'A' * 200; field2 = 100 } ) }
)
```

## Key Learnings

### 1. PowerShell Array Serialization Bug
**Problem**: `ConvertTo-Json` unwraps single-element arrays into objects

```powershell
# ❌ WRONG - Single element becomes an object
@( @{ field = 'value' } ) | ConvertTo-Json
# Output: { "field": "value" }  <-- NOT an array!

# ✅ CORRECT - Use -AsArray parameter
@( @{ field = 'value' } ) | ConvertTo-Json -AsArray
# Output: [{ "field": "value" }]  <-- Proper array!
```

**Solution in `Run-ApiTests-IRM.ps1`**:
```powershell
$bodyJson = if ($null -ne $req.Body) { 
    if ($req.Body -is [array]) {
        $req.Body | ConvertTo-Json -Depth 10 -AsArray
    } else {
        $req.Body | ConvertTo-Json -Depth 10
    }
} else { $null }
```

### 2. Test Organization Patterns

| Test Category | Purpose | Count (typical) |
|---------------|---------|-----------------|
| **GET Collection** | Basic retrieval, pagination, filters | 5-10 |
| **GET Individual** | Item retrieval, 404 handling | 2-4 |
| **POST Success** | Minimal, all fields, multiple items | 3-5 |
| **POST Validation** | Invalid data, types, business rules | 10-15 |
| **Query Params** | limit, offset, filter, select | 5-8 |
| **Edge Cases** | Boundary values, special characters | 3-5 |
| **Total** | Comprehensive coverage | **30-50** |

### 3. POST Test Body Patterns

**For POST collection endpoints (always arrays)**:
```powershell
# Single item (note: wrapped in @())
Body = @( @{ field = 'value' } )

# Multiple items
Body = @( @{ field = 'A' }, @{ field = 'B' } )

# Invalid: Not an array (test this!)
Body = @{ field = 'value' }  # No @() wrapper

# Invalid: Empty array (test this!)
Body = @()
```

**For PUT individual endpoints (objects)**:
```powershell
# Single object (no @() wrapper)
Body = @{ field = 'value' }
```

## Example: fuelTaxes/tripFuelPurchases Results

### Test Run Summary
- **Total Tests**: 39
- **Execution Time**: ~15 seconds
- **Pass Rate**: 64% (25 passed, 14 failed)

### What We Discovered
✅ **Working Correctly**:
- POST endpoint accepts valid data (201)
- Rejects non-array bodies (400)
- Rejects empty arrays (400)
- Rejects volume as string (400)
- Validates string length (400 for 200+ chars)

❌ **Validation Gaps** (accepting invalid data):
- Invalid date formats (should be 400, got 201)
- Negative volumes and amounts (should be 400, got 201)
- Empty fuel type (should be 400, got 201)
- Missing required fields (should be 400, got 201)
- Invalid data types for amounts (should be 400, got 201)
- Invalid vendor IDs (should be 400, got 201)
- Zero volumes (should be 400, got 201)

🐛 **API Bugs**:
- GET with expand returns 500 error
- Invalid parent ID returns 200 (empty array) instead of 404
- Query param validation missing (offset=string, limit=99999)

## Advantages Over Postman

| Feature | PowerShell | Postman |
|---------|-----------|---------|
| **Generate tests** | ✅ Fully automated | ❌ Manual creation required |
| **Execution speed** | ✅ 15s for 39 tests | 🟡 30-45s with CLI |
| **Iteration cycle** | ✅ Edit file → Run | 🟡 Edit UI → Export → Run |
| **Version control** | ✅ Simple .ps1 files | 🟡 Large JSON files |
| **Test coverage** | ✅ Easy to add 50+ tests | 🟡 Manual work for each |
| **Debugging** | ✅ PowerShell debugger | 🟡 Console logs only |
| **CI/CD** | ✅ Native Windows support | ✅ Good with CLI |
| **Reporting** | ✅ Custom PowerShell output | ✅ Rich HTML reports |

## When to Use Each

### Use PowerShell for:
- ✅ **Early TDD** - Scaffold tests before implementation
- ✅ **Quick validation** - Is the endpoint working? What validations exist?
- ✅ **Rapid iteration** - Testing fixes during development
- ✅ **Discovery** - Understanding API behavior and edge cases
- ✅ **Validation gap analysis** - Finding missing business rules

### Use Postman for:
- ✅ **Comprehensive test suites** - Once tests are proven
- ✅ **Rich test scripts** - Complex assertions and chained requests
- ✅ **Team collaboration** - Shared collections and environments
- ✅ **Documentation** - Examples and API documentation
- ✅ **CI/CD pipelines** - Mature, stable test execution

## Best Practice: Hybrid Approach

1. **Phase 1: PowerShell Discovery** (Day 1)
   - Generate comprehensive test scaffold
   - Run tests to discover behavior
   - Identify validation gaps and bugs
   - Document findings

2. **Phase 2: Postman Formalization** (Day 2-3)
   - Create Postman requests (manually, one-time)
   - Port PowerShell tests to Postman
   - Add rich assertions and test scripts
   - Set up collection-level scripts

3. **Phase 3: Ongoing** (Maintenance)
   - Use Postman for CI/CD execution
   - Use PowerShell for quick checks
   - Update both as API evolves

## Next Steps

1. **Create scaffolding generator** - Script to auto-generate test files from OpenAPI spec
2. **Enhance runner** - Add setup/teardown, data-driven tests, better reporting
3. **Add validation helpers** - Common assertions (schema validation, field value checks)
4. **Create templates** - For GET, POST, PUT, DELETE patterns
5. **Document patterns** - For sub-resources, nested objects, file uploads

---

**Files Created**:
- `requests_finance_fuelTaxes.ps1` - Comprehensive test suite (39 tests)
- `Run-ApiTests-IRM.ps1` - Enhanced runner with `-AsArray` fix
- `README-PowerShell-Scaffolding.md` - This documentation

**Key Success**: Validated POST endpoint and discovered 9 validation gaps in under 30 minutes! 🚀

