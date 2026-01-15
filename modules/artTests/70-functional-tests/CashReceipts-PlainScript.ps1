# Plain PowerShell Script Tests - No Framework
# Just regular PowerShell code that you can run directly

# Import modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue

# Setup environment variables quietly
Setup-EnvironmentVariables -Quiet

# Initialize test tracking (now using module function)
Initialize-TestResults

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "CASH RECEIPTS API TESTS" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""


# Test 1: Get collection
Write-Host "[1] Testing: Get cash receipts collection..." #-ForegroundColor Yellow
$receipts = Get-CashReceipts -Limit 5
Test-Result "Get cash receipts collection" `
    -Passed ($receipts -isnot [string]) `
    -Message $(if ($receipts -is [string]) { "Got error: $($receipts.Substring(0, 100))" })


# Test 2: Get single item
Write-Host "[2] Testing: Get single cash receipt..." -ForegroundColor Yellow
$firstReceipt = if ($receipts -is [array]) { $receipts[0] } else { $receipts }
$receiptId = $firstReceipt.cashReceiptId
$singleReceipt = Get-CashReceipts -CashReceiptId $receiptId
Test-Result "Get single cash receipt by ID" `
    -Passed (($singleReceipt -isnot [string]) -and ($singleReceipt.cashReceiptId -eq $receiptId))


# Test 3: Verify properties
Write-Host "[3] Testing: Verify cash receipt has required properties..." #-ForegroundColor Yellow
$hasRequiredProps = ($singleReceipt.cashReceiptId -ne $null) -and 
                    ($singleReceipt.clientId -ne $null) -and
                    ($singleReceipt.checkAmount -ne $null)
Test-Result "Cash receipt has required properties" -Passed $hasRequiredProps


# Test 4: Update with valid data (find an unposted receipt)
Write-Host "[4] Testing: Update cash receipt with valid data..." #-ForegroundColor Yellow
$unpostedReceipts = Get-CashReceipts -Filter "transactionPosted eq False" -Limit 1
if ($unpostedReceipts -is [string] -or -not $unpostedReceipts) {
    # Fallback: try with the first receipt anyway
    $unpostedReceipts = $firstReceipt
}
$unpostedReceipt = if ($unpostedReceipts -is [array]) { $unpostedReceipts[0] } else { $unpostedReceipts }
$unpostedId = $unpostedReceipt.cashReceiptId
$originalAmount = $unpostedReceipt.checkAmount
$newAmount = $originalAmount + 10.50

$updateResult = Set-CashReceipt -CashReceiptId $unpostedId -CashReceipt @{
    checkAmount = $newAmount
}
$updateSuccess = ($updateResult -isnot [string]) -and ($updateResult.checkAmount -eq $newAmount)
Test-Result "Update cash receipt with valid amount" `
    -Passed $updateSuccess `
    -Message $(if (-not $updateSuccess) { "Expected amount: $newAmount, Got: $($updateResult.checkAmount)" })


# Test 5: Update with invalid data (should fail)
Write-Host "[5] Testing: Update with invalid data (negative amount)..." #-ForegroundColor Yellow
$errorResult = Set-CashReceipt -CashReceiptId $receiptId -CashReceipt @{
    checkAmount = -100
} 2>$null
$errorHandled = ($errorResult -is [string]) -and ($errorResult -match '"status"\s*:\s*400')
Test-Result "Reject negative amount" `
    -Passed $errorHandled `
    -Message $(if (-not $errorHandled) { "Expected 400 error, got: $($errorResult.GetType().Name)" })


# Test 6: Get with expand
Write-Host "[6] Testing: Get with expand parameter..." # -ForegroundColor Yellow
$expandResult = Get-CashReceipts -CashReceiptId $receiptId -Expand "invoices"
$expandSuccess = ($expandResult -isnot [string]) -and 
                 ($expandResult.PSObject.Properties.Name -contains 'invoices')
Test-Result "Get with expand parameter" -Passed $expandSuccess


# Test 7: Performance check
Write-Host "[7] Testing: Performance check..." #-ForegroundColor Yellow
$elapsed = Measure-Command {
    Get-CashReceipts -Limit 10 | Out-Null
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

