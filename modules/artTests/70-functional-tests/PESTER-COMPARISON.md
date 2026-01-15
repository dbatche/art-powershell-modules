# Testing Approaches Comparison

## Test Results Summary

| Approach | Tests | Passed | Failed | Duration | Complexity |
|----------|-------|--------|--------|----------|------------|
| **Plain PowerShell Script** | 7 | 6 | 1 | ~5s | ⭐ Simplest |
| **Custom Framework (`Invoke-FunctionalTests`)** | 5 | 5 | 0 | 9.9s | ⭐⭐ Simple |
| **Pester (Industry Standard)** | 10 | 10 | 0 | 36.7s | ⭐⭐⭐ Full-featured |

## Approach Comparison

### Plain PowerShell Script (No Framework)

**Pros:**
- ✅ **Simplest possible** - Just regular PowerShell
- ✅ **No dependencies** - No framework to learn
- ✅ **Fast execution** - No framework overhead
- ✅ **Easy to understand** - Anyone can read it
- ✅ **Direct execution** - Just run `.\MyTests.ps1`
- ✅ **Flexible** - Do whatever you want
- ✅ **No learning curve** - It's just PowerShell

**Cons:**
- ❌ No structure/organization
- ❌ Manual result tracking
- ❌ No rich assertions
- ❌ No setup/cleanup helpers
- ❌ No test discovery
- ❌ Hard to aggregate results
- ❌ Manual reporting
- ❌ No selective execution
- ❌ No mocking

**Example:**
```powershell
# Import modules
Import-Module artTests -Force -WarningAction SilentlyContinue
Import-Module artFinance -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

# Initialize test tracking (uses module functions)
Initialize-TestResults

# Write tests
Write-Host "[1] Testing: Get cash receipts..."
$receipts = Get-CashReceipts -Limit 5
Test-Result "Get cash receipts" -Passed ($receipts -isnot [string])

# Show summary
Show-TestSummary -ShowFailedTests
```

**Reusable Module Functions:**
The `artTests` module now provides helper functions for plain scripts:
- `Initialize-TestResults` - Initializes test tracking variables
- `Test-Result -TestName "..." -Passed $true/$false -Message "..."` - Records and displays test results
- `Show-TestSummary -ShowFailedTests` - Displays formatted summary with pass/fail counts

These functions eliminate boilerplate while keeping scripts simple.

### Custom Framework (`Invoke-FunctionalTests`)

**Pros:**
- ✅ Simple, lightweight
- ✅ Easy to understand for non-Pester users
- ✅ Custom tailored to our needs
- ✅ Faster execution (less overhead)

**Cons:**
- ❌ No mocking capabilities
- ❌ Limited assertion syntax
- ❌ Manual maintenance required
- ❌ No standard report formats
- ❌ No IDE integration
- ❌ No test discovery
- ❌ No test organization (Describe/Context)

### Pester v5 (Industry Standard)

**Pros:**
- ✅ **Rich assertion syntax** - `Should -Be`, `Should -Contain`, `Should -Match`, etc.
- ✅ **Better test organization** - `Describe`, `Context`, `It` blocks
- ✅ **Mocking support** - Isolate dependencies
- ✅ **Test tagging** - Run subsets (`-Tag "ErrorHandling"`)
- ✅ **Standard reports** - NUnit XML, JUnit, etc.
- ✅ **IDE integration** - VSCode Pester extension
- ✅ **Mature & maintained** - Industry standard since 2011
- ✅ **CI/CD friendly** - Azure DevOps, GitHub Actions, Jenkins
- ✅ **Code coverage** - Built-in coverage analysis
- ✅ **Community support** - Extensive documentation and examples

**Cons:**
- ⚠️ Slightly more verbose
- ⚠️ Learning curve for those unfamiliar
- ⚠️ Heavier framework (slower execution)

## Quick Feature Comparison

| Feature | Plain Script | Custom Framework | Pester |
|---------|-------------|------------------|--------|
| **Simplicity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Speed** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Structure** | ❌ | ✅ | ✅✅ |
| **Assertions** | Manual | Manual | Rich |
| **Setup/Cleanup** | Manual | ✅ | ✅✅ |
| **Reporting** | Manual | Basic | Advanced |
| **CI/CD Integration** | Manual | Manual | ✅✅ |
| **Mocking** | ❌ | ❌ | ✅ |
| **Code Coverage** | ❌ | ❌ | ✅ |
| **IDE Integration** | ❌ | ❌ | ✅ |
| **Learning Curve** | None | Low | Medium |
| **Community Support** | N/A | None | Excellent |

## Code Examples Comparison

### Plain PowerShell Script
```powershell
# Just regular PowerShell
$receipts = Get-CashReceipts -Limit 5
if ($receipts -isnot [string]) {
    Write-Host "✅ PASS" -ForegroundColor Green
    $script:passed++
} else {
    Write-Host "❌ FAIL" -ForegroundColor Red
    $script:failed++
}
```

### Custom Framework
```powershell
@{
    Name = "Update cash receipt - invalid checkAmount (negative)"
    Setup = { $script:id = (Get-CashReceipts -Limit 1).cashReceiptId }
    Test = { Set-CashReceipt -CashReceiptId $script:id -CashReceipt @{ checkAmount = -100 } 2>$null }
    Assert = { param($result) $result -is [string] -and $result -match '"status"\s*:\s*400' }
    ExpectedOutcome = "Fail - Returns 400 validation error"
}
```

### Pester
```powershell
Context "When updating with invalid data" -Tag "ErrorHandling" {
    BeforeAll {
        $script:receiptId = (Get-CashReceipts -Limit 1).cashReceiptId
    }
    
    It "Should reject negative checkAmount" {
        $result = Set-CashReceipt -CashReceiptId $script:receiptId -CashReceipt @{
            checkAmount = -100
        } 2>$null
        
        $result | Should -BeOfType [string]
        $result | Should -Match '"status"\s*:\s*400'
    }
    
    It "Should return validation error with error code" {
        $result = Set-CashReceipt -CashReceiptId $script:receiptId -CashReceipt @{
            checkAmount = -100
        } 2>$null
        
        $errorObj = $result | ConvertFrom-Json
        $errorObj.status | Should -Be 400
        $errorObj.errors | Should -Not -BeNullOrEmpty
        $errorObj.errors[0].code | Should -Not -BeNullOrEmpty
    }
}
```

## Assertion Syntax Comparison

### Custom Framework
```powershell
# Limited - manual checks
param($result)
$result -isnot [string] -and ($null -ne $result.cashReceiptId)
```

### Pester
```powershell
# Rich - expressive assertions
$result | Should -Not -BeOfType [string]
$result.cashReceiptId | Should -Not -BeNullOrEmpty
$result.checkAmount | Should -BeGreaterThan 0
$result.checkDate | Should -Match '^\d{4}-\d{2}-\d{2}'
$result.PSObject.Properties.Name | Should -Contain 'invoices'
```

## Advanced Pester Features

### 1. Tagging for Selective Execution
```powershell
# Run only performance tests
Invoke-Pester -Path "CashReceipts.Tests.ps1" -Tag "Performance"

# Exclude slow tests
Invoke-Pester -Path "CashReceipts.Tests.ps1" -ExcludeTag "Slow"
```

### 2. Mocking Dependencies
```powershell
Describe "Cash Receipts - Mocked" {
    It "Should handle API unavailable" {
        Mock Get-CashReceipts { throw "API Down" }
        
        { Get-CashReceipts } | Should -Throw "API Down"
    }
}
```

### 3. Data-Driven Tests
```powershell
Context "When testing multiple invalid values" {
    It "Should reject <value>" -ForEach @(
        @{ value = -100; reason = "negative" }
        @{ value = 0; reason = "zero" }
        @{ value = 999999999; reason = "too large" }
    ) {
        $result = Set-CashReceipt -CashReceiptId 1 -CashReceipt @{
            checkAmount = $value
        } 2>$null
        
        $result | Should -Match '"status"\s*:\s*400'
    }
}
```

### 4. Code Coverage
```powershell
Invoke-Pester -Path "CashReceipts.Tests.ps1" -CodeCoverage "*.ps1" -CodeCoverageOutputFile "coverage.xml"
```

### 5. CI/CD Integration
```yaml
# Azure Pipelines example
- task: Pester@10
  inputs:
    scriptFolder: '$(System.DefaultWorkingDirectory)/Tests'
    resultsFile: '$(System.DefaultWorkingDirectory)/Test-Results.xml'
    run32Bit: False
```

## Recommendation by Use Case

### Use Plain PowerShell Scripts When:
- ✅ **One-off testing** or exploration
- ✅ **Quick validation** during development
- ✅ Team completely unfamiliar with testing frameworks
- ✅ Need **maximum simplicity**
- ✅ Debugging/troubleshooting
- ✅ Proof of concepts

**Example:** `.\QuickTest-CashReceipts.ps1`

### Use Custom Framework When:
- ✅ Want **some structure** without complexity
- ✅ Need **basic reporting**
- ✅ Team unfamiliar with Pester
- ✅ Simple pass/fail tests with setup/cleanup
- ✅ **Stepping stone** before adopting Pester

**Example:** `Invoke-FunctionalTests -TestFile "tests.ps1"`

### Use Pester When:
- ✅ **Long-term test suite** (RECOMMENDED FOR PRODUCTION)
- ✅ Need **mocking/isolation**
- ✅ **CI/CD pipeline** integration
- ✅ Want **code coverage**
- ✅ Need **standard test reports** (NUnit XML, JUnit)
- ✅ Want **IDE integration** (VSCode Pester extension)
- ✅ **Team collaboration** (industry standard)
- ✅ Need **selective execution** (tags, filters)
- ✅ **Mature, maintained solution**

**Example:** `Invoke-Pester -Path "CashReceipts.Tests.ps1"`

## Migration Path

If you want to adopt Pester gradually:

1. **Keep existing tests** - Both frameworks can coexist
2. **New tests in Pester** - Write new tests using Pester
3. **Migrate incrementally** - Convert custom tests as needed
4. **Share learnings** - Team training on Pester basics

## Conclusion

All three approaches work well! Choose based on your needs:

### 🚀 Quick Answer

1. **Exploring/Debugging?** → **Plain PowerShell Script** (fastest, simplest)
2. **Building a test suite?** → **Pester** (industry standard, full-featured)
3. **In between?** → **Custom Framework** (structured, but lightweight)

### 📊 Progression Path

```
Plain Scripts → Custom Framework → Pester
   (Learn)    →    (Structure)   → (Production)
```

Most teams evolve from plain scripts for exploration, through a custom framework for organization, and ultimately to Pester for production test suites.

### 💡 Final Recommendation

- **For your situation**: All three can coexist!
  - Use **plain scripts** for quick API exploration
  - Use **custom framework** for repeatable functional tests
  - Use **Pester** for comprehensive, production-ready test suites

The beauty is you can mix and match based on the specific testing need. Your API wrapper functions work great with all three approaches! 🎉

