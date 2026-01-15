# Scenario-Based Test Script - TM-180953 Finance POST /cashReceipts/{cashReceiptId}/invoices
# Emphasis on validating return JSON structure per Jira note

# Import modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue

# Setup environment variables quietly
Setup-EnvironmentVariables -Quiet

# Initialize test tracking with log file
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Initialize-TestResults -LogFile "cashreceipts-post-test-data-$timestamp.json"

# Header
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "CASH RECEIPTS POST TESTS (TM-180953)" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan


# ============================================================================
# SCENARIO 1: POST /cashReceipts/{cashReceiptId}/invoices (valid)
# ============================================================================
Start-TestScenario "POST /cashReceipts/{cashReceiptId}/invoices (valid)" -Description "Add invoice to cash receipt"

# First, get a cash receipt to work with
$cashReceipts = Get-CashReceipts -Filter "transactionPosted eq False" -Limit 1
$cashReceipt = if ($cashReceipts -is [array]) { $cashReceipts[0] } else { $cashReceipts }
$cashReceiptId = $cashReceipt.cashReceiptId

Write-TestInfo "Using cash receipt ID: $cashReceiptId"
Write-TestInfo -Data @{
    cashReceiptId = $cashReceiptId
    originalAmount = $cashReceipt.checkAmount
}

# Create invoice payload
$testInvoice = @{
    orderId = 444  # Using known test order
    clientId = "05124973"
    paymentAmount = 100.00
}

Write-TestInfo "Adding invoice for order: $($testInvoice.orderId)"
Write-TestInfo -Data @{
    orderId = $testInvoice.orderId
    paymentAmount = $testInvoice.paymentAmount
}

$invoiceResult = New-CashReceiptInvoice -CashReceiptId $cashReceiptId -Invoices @($testInvoice)

# Critical: Validate return JSON structure (per Jira note)
Test-Assertion "Returns data (not error string)" -Passed ($invoiceResult -isnot [string])

if ($invoiceResult -isnot [string]) {
    # Check if result is array or single object
    $invoice = if ($invoiceResult -is [array]) { $invoiceResult[0] } else { $invoiceResult }
    
    Write-TestInfo "Invoice created - ID: $($invoice.invoiceId)"
    
    # Validate JSON structure - critical properties
    Test-Assertion "Has invoiceId property" -Passed ($invoice.invoiceId -ne $null)
    Test-Assertion "Has cashReceiptId property" -Passed ($invoice.cashReceiptId -eq $cashReceiptId)
    Test-Assertion "Has detailLineId property" -Passed ($invoice.detailLineId -ne $null)
    
    # Validate data integrity
    Test-Assertion "Returns correct clientId" -Passed ($invoice.clientId -eq $testInvoice.clientId) `
        -Message "Expected: $($testInvoice.clientId), Got: $($invoice.clientId)"
    
    Test-Assertion "Returns correct paymentAmount" -Passed ($invoice.paymentAmount -eq $testInvoice.paymentAmount) `
        -Message "Expected: $($testInvoice.paymentAmount), Got: $($invoice.paymentAmount)"
    
    # Check nullable fields are present (even if null)
    Test-Assertion "Has billNumber property (nullable)" -Passed ($invoice.PSObject.Properties.Name -contains 'billNumber')
    Test-Assertion "Has writeOffAmount property (nullable)" -Passed ($invoice.PSObject.Properties.Name -contains 'writeOffAmount')
    
    Write-TestInfo -Data @{
        invoiceId = $invoice.invoiceId
        detailLineId = $invoice.detailLineId
        billNumber = $invoice.billNumber
        returnedPaymentAmount = $invoice.paymentAmount
        returnedWriteOffAmount = $invoice.writeOffAmount
    }
} else {
    $apiError = $invoiceResult | ConvertFrom-Json
    Write-TestInfo "Error: $($apiError.errors[0].code)"
}


# ============================================================================
# SCENARIO 2: POST /cashReceipts/{cashReceiptId}/invoices (invalid cashReceiptId)
# ============================================================================
Start-TestScenario "POST /cashReceipts/{cashReceiptId}/invoices (invalid ID)" -Description "Reject invalid cash receipt ID"

$expectedErrorCode = "invalidInteger"  # Expected for non-numeric ID

Write-TestInfo -Data @{
    invalidId = "ABC"
    expectedError = $expectedErrorCode
}

$invalidIdResult = New-CashReceiptInvoice -CashReceiptId 'ABC' -Invoices @(@{ orderId = 444 })

if ($invalidIdResult -is [string]) {
    $apiError = $invalidIdResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    
    Write-TestInfo "Error returned: $errorCode (HTTP $errorStatus)"
    Write-TestInfo -Data @{ errorCode = $errorCode; httpStatus = $errorStatus }
}

Test-Assertion "Returns error [$expectedErrorCode]" -Passed ($invalidIdResult -is [string]) `
    -Message "Expected error but request succeeded"

Test-Assertion "Returns 400 status" -Passed ($invalidIdResult -match '"status"\s*:\s*400')


# ============================================================================
# SCENARIO 3: POST /cashReceipts/{cashReceiptId}/invoices (invalid orderId)
# ============================================================================
Start-TestScenario "POST /cashReceipts/{cashReceiptId}/invoices (invalid orderId)" -Description "Reject invalid order ID"

$expectedOrderErrorCode = "invalidInteger"  # Expected for non-numeric orderId

Write-TestInfo -Data @{
    cashReceiptId = $cashReceiptId
    invalidOrderId = "XYZ"
    expectedError = $expectedOrderErrorCode
}

$invalidOrderResult = New-CashReceiptInvoice -CashReceiptId $cashReceiptId -Invoices @(@{ orderId = 'XYZ' })

if ($invalidOrderResult -is [string]) {
    $apiError = $invalidOrderResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    
    Write-TestInfo "Error returned: $errorCode (HTTP $errorStatus)"
    Write-TestInfo -Data @{ errorCode = $errorCode; httpStatus = $errorStatus }
}

Test-Assertion "Returns error [$expectedOrderErrorCode]" -Passed ($invalidOrderResult -is [string]) `
    -Message "Expected error but request succeeded"

Test-Assertion "Returns 400 status" -Passed ($invalidOrderResult -match '"status"\s*:\s*400')


# ============================================================================
# SCENARIO 4: POST /cashReceipts/{cashReceiptId}/invoices (missing required field)
# ============================================================================
Start-TestScenario "POST /cashReceipts/{cashReceiptId}/invoices (missing orderId)" -Description "Reject missing required field"

$expectedMissingFieldError = "missingRequiredField"  # Expected for missing orderId

Write-TestInfo -Data @{
    cashReceiptId = $cashReceiptId
    missingField = "orderId"
    expectedError = $expectedMissingFieldError
}

$missingFieldResult = New-CashReceiptInvoice -CashReceiptId $cashReceiptId -Invoices @(@{ clientId = "TEST" })

if ($missingFieldResult -is [string]) {
    $apiError = $missingFieldResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    
    Write-TestInfo "Error returned: $errorCode (HTTP $errorStatus)"
    Write-TestInfo -Data @{ errorCode = $errorCode; httpStatus = $errorStatus }
}

Test-Assertion "Returns error [$expectedMissingFieldError]" -Passed ($missingFieldResult -is [string]) `
    -Message "Expected error but request succeeded"

Test-Assertion "Returns 400 status" -Passed ($missingFieldResult -match '"status"\s*:\s*400')


# ============================================================================
# SCENARIO 5: POST /cashReceipts/{cashReceiptId}/invoices (multiple invoices)
# ============================================================================
Start-TestScenario "POST /cashReceipts/{cashReceiptId}/invoices (multiple)" -Description "Add multiple invoices at once"

$multipleInvoices = @(
    @{ orderId = 444; paymentAmount = 50.00 }
    @{ orderId = 444; paymentAmount = 75.00; writeOffAmount = 5.00 }
)

Write-TestInfo "Adding $($multipleInvoices.Count) invoices"
Write-TestInfo -Data @{
    cashReceiptId = $cashReceiptId
    invoiceCount = $multipleInvoices.Count
}

$multiResult = New-CashReceiptInvoice -CashReceiptId $cashReceiptId -Invoices $multipleInvoices

Test-Assertion "Returns data (not error string)" -Passed ($multiResult -isnot [string])

if ($multiResult -isnot [string]) {
    Test-Assertion "Returns multiple invoices" -Passed ($multiResult -is [array] -and $multiResult.Count -eq $multipleInvoices.Count) `
        -Message "Expected: $($multipleInvoices.Count), Got: $($multiResult.Count)"
    
    # Validate first invoice structure
    if ($multiResult -is [array] -and $multiResult.Count -gt 0) {
        $firstInv = $multiResult[0]
        Test-Assertion "First invoice has invoiceId" -Passed ($firstInv.invoiceId -ne $null)
        Test-Assertion "First invoice has paymentAmount" -Passed ($firstInv.paymentAmount -eq 50.00)
        
        Write-TestInfo -Data @{
            firstInvoiceId = $firstInv.invoiceId
            secondInvoiceId = if ($multiResult.Count -gt 1) { $multiResult[1].invoiceId } else { $null }
        }
    }
}


# Summary
Show-TestSummary -ShowFailedTests

# Exit with appropriate code for CI/CD
if ($script:failed -gt 0) {
    exit 1
}

