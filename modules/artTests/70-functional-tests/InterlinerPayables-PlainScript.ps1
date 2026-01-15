# Plain PowerShell Script Tests - No Framework
# Testing: TM-180938 Finance - PUT interlinerPayables/{interlinerPayableId}
# Just regular PowerShell code that you can run directly

# Import modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue

# Setup environment variables quietly
Setup-EnvironmentVariables -Quiet

# Initialize test tracking (now using module function)
Initialize-TestResults

# Header
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "INTERLINER PAYABLES API TESTS (TM-180938)" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""


# Test 1: Get collection
Write-Host "[1] Testing: Get interliner payables collection..." -ForegroundColor Yellow
$payables = Get-InterlinerPayables -Limit 5
Test-Result "Get interliner payables collection" `
    -Passed ($payables -isnot [string]) `
    -Message $(if ($payables -is [string]) { "Got error: $($payables.Substring(0, [Math]::Min(100, $payables.Length)))" })

# Test 2: Get single item
Write-Host "[2] Testing: Get single interliner payable..." -ForegroundColor Yellow
$firstPayable = if ($payables -is [array]) { $payables[0] } else { $payables }
$payableId = $firstPayable.interlinerPayableId
$singlePayable = Get-InterlinerPayables -InterlinerPayableId $payableId
Test-Result "Get single interliner payable by ID" `
    -Passed (($singlePayable -isnot [string]) -and ($singlePayable.interlinerPayableId -eq $payableId))

# Test 3: Verify properties
Write-Host "[3] Testing: Verify interliner payable has required properties..."
$hasRequiredProps = ($singlePayable.interlinerPayableId -ne $null) -and 
                    ($singlePayable.originalAmount -ne $null) -and
                    ($singlePayable.status -ne $null)
Test-Result "Interliner payable has required properties" -Passed $hasRequiredProps

# Test 4: Update with valid data (using adjustedExtras field)
Write-Host "[4] Testing: Update interliner payable with valid data..."
$originalExtras = $singlePayable.adjustedExtras
$newExtras = $originalExtras + 10.50

$updateResult = Set-InterlinerPayable -InterlinerPayableId $payableId -InterlinerPayable @{
    adjustedExtras = $newExtras
} 2>$null

$updateSuccess = ($updateResult -isnot [string]) -and ($updateResult.adjustedExtras -eq $newExtras)
Test-Result "Update interliner payable adjustedExtras" `
    -Passed $updateSuccess `
    -Message $(if (-not $updateSuccess) { 
        if ($updateResult -is [string]) {
            "API Error: $($updateResult | ConvertFrom-Json | Select-Object -ExpandProperty errors | Select-Object -First 1 -ExpandProperty code)"
        } else {
            "Expected adjustedExtras: $newExtras, Got: $($updateResult.adjustedExtras)"
        }
    })

# Test 5: Update with invalid data type (should fail - string for numeric field)
Write-Host "[5] Testing: Update with invalid data type (string for adjustedExtras)..."
$errorResult = Set-InterlinerPayable -InterlinerPayableId $payableId -InterlinerPayable @{
    adjustedExtras = "not a number"
} 2>$null
$errorHandled = ($errorResult -is [string]) -and ($errorResult -match '"status"\s*:\s*400')
Test-Result "Reject invalid data type for adjustedExtras" `
    -Passed $errorHandled `
    -Message $(if (-not $errorHandled) { 
        if ($errorResult -is [string]) {
            "Expected 400 error, got error: $($errorResult | ConvertFrom-Json | Select-Object -ExpandProperty status)"
        } else {
            "Expected 400 error, but update succeeded: $($errorResult.GetType().Name)"
        }
    })

# Test 6: Update with invalid ID (should fail)
Write-Host "[6] Testing: Update with invalid ID..."
$invalidIdResult = Set-InterlinerPayable -InterlinerPayableId 'ABC' -InterlinerPayable @{
    adjustedExtras = 100
} 2>$null
$invalidIdHandled = ($invalidIdResult -is [string]) -and ($invalidIdResult -match '"status"\s*:\s*[45]\d{2}')
Test-Result "Reject invalid ID" `
    -Passed $invalidIdHandled `
    -Message $(if (-not $invalidIdHandled) { "Expected 4xx/5xx error, got: $($invalidIdResult.GetType().Name)" })

# Test 7: Performance check
Write-Host "[7] Testing: Performance check..."
$elapsed = Measure-Command {
    Get-InterlinerPayables -Limit 10 | Out-Null
}
$perfOk = $elapsed.TotalMilliseconds -lt 10000
Test-Result "Performance under 10 seconds" `
    -Passed $perfOk `
    -Message "Took $([math]::Round($elapsed.TotalMilliseconds, 2))ms"


# Summary (now using module function)
Show-TestSummary -ShowFailedTests

# Exit with appropriate code for CI/CD
if ($script:failed -gt 0) {
    exit 1
}

