# Functional Tests (PowerShell-Native)

This folder contains **functional tests** that use PowerShell wrapper functions instead of raw HTTP URLs.

## Why This Format?

### Traditional Contract Tests (`40-test-definitions`)
```powershell
@{
    Name = "Update cash receipt"
    Method = "PUT"
    Url = "https://api.example.com/finance/cashReceipts/12345"
    Body = @{ checkAmount = 100 }
    ExpectedStatus = 200
}
```

### New Functional Tests (`70-functional-tests`)
```powershell
@{
    Name = "Update cash receipt - valid amount"
    Setup = {
        $receipts = Get-CashReceipts -Limit 1
        $script:receiptId = $receipts[0].cashReceiptId
    }
    Test = {
        Set-CashReceipt -CashReceiptId $script:receiptId -CashReceipt @{
            checkAmount = 100
        }
    }
    Assert = {
        param($result)
        $result -isnot [string]  # Success if not an error string
    }
    ExpectedOutcome = "Success - Updates checkAmount"
    Cleanup = {
        Remove-Variable -Name receiptId -Scope Script
    }
}
```

## Benefits

✅ **PowerShell-native** - Uses wrapper functions with IntelliSense  
✅ **Flexible** - Can chain operations (GET then PUT)  
✅ **Less brittle** - No manual URL construction  
✅ **Better error handling** - Functions already handle errors consistently  
✅ **Test data setup** - Can query for valid test data before each test  
✅ **Cleanup support** - Built-in cleanup scriptblock  

## Test Definition Format

```powershell
@{
    Name = "Test name"
    Description = "What this test validates"
    
    # Optional: Run before test to set up test data
    Setup = {
        $script:myVar = Get-SomeData
    }
    
    # Required: The actual test to execute
    Test = {
        Invoke-SomeFunction -Param $script:myVar
    }
    
    # Optional: Validate the result
    Assert = {
        param($result)
        $result.someProperty -eq "expectedValue"
    }
    
    ExpectedOutcome = "Human-readable expected result"
    
    # Optional: Clean up after test
    Cleanup = {
        Remove-Variable -Name myVar -Scope Script
    }
}
```

## Running Tests

```powershell
# Setup (one-time per session)
Import-Module artTests -Force
Import-Module artFinance -Force
Setup-EnvironmentVariables -Quiet  # Set API URLs and tokens without verbose output

# Run all tests in a file
Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1"

# Run without logging
Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1" -NoLog

# Stop on first failure
Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1" -StopOnFailure

# Custom log file
Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1" -LogFile "my-results.json"
```

**Tip:** Use `Setup-EnvironmentVariables -Quiet` to suppress verbose output when running tests.

## Example Tests

See `cashReceipts-functional-tests.ps1` for examples including:
- Simple GET operations
- GET with filters and expand
- PUT operations with validation
- Error case testing (negative amounts)
- Multi-step tests (query then update)

## Comparison with Contract Tests

| Feature | Contract Tests | Functional Tests |
|---------|---------------|------------------|
| Format | URL + Method + Body | PowerShell functions |
| Setup | Manual (hard-coded IDs) | Dynamic (query for data) |
| Error handling | Manual parsing | Built-in to functions |
| Chaining | Not supported | Supported via Setup |
| Cleanup | Not supported | Built-in Cleanup block |
| Runner | `Run-ApiTests` | `Invoke-FunctionalTests` |
| Use case | API contract validation | End-to-end scenarios |

## Future Ideas

- Auto-generation from contracts (similar to `New-ContractTests`)
- Parameterized tests (run same test with multiple data sets)
- Test dependencies (Test B requires Test A to pass)
- Performance metrics (track API response times)
- Data-driven tests (load test data from CSV/JSON)

