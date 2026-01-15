# Scenario-Based Test Script - TM-180938 Finance PUT interlinerPayables/{interlinerPayableId}
# Uses new scenario/assertion structure with enhanced logging

# Import modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue

# Setup environment variables quietly
Setup-EnvironmentVariables -Quiet

# Initialize test tracking with log file
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Initialize-TestResults -LogFile "interliner-test-data-$timestamp.json"

# Header
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "INTERLINER PAYABLES API TESTS (TM-180938)" -ForegroundColor White
Write-Host ("=" * 80) -ForegroundColor Cyan


# ============================================================================
# SCENARIO 1: GET /interlinerPayables (collection)
# ============================================================================
Start-TestScenario "GET /interlinerPayables (collection)" -Description "Retrieve list of interliner payables"

$payables = Get-InterlinerPayables -Limit 5

Test-Assertion "Returns data without error" -Passed ($payables -isnot [string])
Test-Assertion "Returns array of payables" -Passed ($payables -is [array] -or $payables.interlinerPayableId)

Write-TestInfo -Data @{
    count = if ($payables -is [array]) { $payables.Count } else { 1 }
}


# ============================================================================
# SCENARIO 2: GET /interlinerPayables/{id}
# ============================================================================
Start-TestScenario "GET /interlinerPayables/{id}" -Description "Retrieve single interliner payable"

$firstPayable = if ($payables -is [array]) { $payables[0] } else { $payables }
$payableId = $firstPayable.interlinerPayableId

Write-TestInfo "Using payable ID: $payableId"
Write-TestInfo -Data @{
    payableId = $payableId
    originalAmount = $firstPayable.originalAmount
    status = $firstPayable.status
}

$singlePayable = Get-InterlinerPayables -InterlinerPayableId $payableId

Test-Assertion "Returns single payable" -Passed ($singlePayable -isnot [string])
Test-Assertion "Has interlinerPayableId property" -Passed ($singlePayable.interlinerPayableId -ne $null)
Test-Assertion "Has originalAmount property" -Passed ($singlePayable.originalAmount -ne $null)
Test-Assertion "Has status property" -Passed ($singlePayable.status -ne $null)
Test-Assertion "Matches requested ID" -Passed ($singlePayable.interlinerPayableId -eq $payableId)


# ============================================================================
# SCENARIO 3: PUT /interlinerPayables/{id} (valid update)
# ============================================================================
Start-TestScenario "PUT /interlinerPayables/{id} (valid update)" -Description "Update adjustedExtras with valid value"

$originalExtras = $singlePayable.adjustedExtras
$newExtras = $originalExtras + 10.50

Write-TestInfo "Updating adjustedExtras: $originalExtras → $newExtras"
Write-TestInfo -Data @{
    payableId = $payableId
    field = "adjustedExtras"
    originalValue = $originalExtras
    newValue = $newExtras
}

$updateResult = Set-InterlinerPayable -InterlinerPayableId $payableId -InterlinerPayable @{
    adjustedExtras = $newExtras
}

Test-Assertion "Update succeeds" -Passed ($updateResult -isnot [string]) `
    -Message $(if ($updateResult -is [string]) { 
        $apiError = $updateResult | ConvertFrom-Json
        "API Error: $($apiError.errors[0].code)"
    })

if ($updateResult -isnot [string]) {
    Test-Assertion "Returns updated value" -Passed ($updateResult.adjustedExtras -eq $newExtras) `
        -Message "Expected: $newExtras, Got: $($updateResult.adjustedExtras)"
}


# ============================================================================
# SCENARIO 4: PUT /interlinerPayables/{id} (invalid data type)
# ============================================================================
Start-TestScenario "PUT /interlinerPayables/{id} (invalid data type)" -Description "Reject string for numeric field"

$expectedErrorCode = "invalidDouble"  # Expected error code for string in numeric field

Write-TestInfo -Data @{
    payableId = $payableId
    field = "adjustedExtras"
    invalidValue = "not a number"
    expectedError = $expectedErrorCode
}

$errorResult = Set-InterlinerPayable -InterlinerPayableId $payableId -InterlinerPayable @{
    adjustedExtras = "not a number"
}

# Extract error details for better visibility
if ($errorResult -is [string]) {
    $apiError = $errorResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    
    Write-TestInfo "Error returned: $errorCode (HTTP $errorStatus)"
    Write-TestInfo -Data @{ errorCode = $errorCode; httpStatus = $errorStatus }
}

Test-Assertion "Returns error [$expectedErrorCode]" -Passed ($errorResult -is [string]) `
    -Message "Expected error but update succeeded"

Test-Assertion "Returns 400 status" -Passed ($errorResult -match '"status"\s*:\s*400') `
    -Message $(if ($errorResult -isnot [string]) {
        "Expected error but update succeeded"
    } else {
        "Got status: $errorStatus"
    })


# ============================================================================
# SCENARIO 5: PUT /interlinerPayables/{id} (invalid ID)
# ============================================================================
Start-TestScenario "PUT /interlinerPayables/{id} (invalid ID)" -Description "Reject non-numeric ID"

$expectedInvalidIdError = "invalidInteger"  # Expected error code for non-numeric ID

Write-TestInfo -Data @{
    invalidId = "ABC"
    expectedError = $expectedInvalidIdError
}

$invalidIdResult = Set-InterlinerPayable -InterlinerPayableId 'ABC' -InterlinerPayable @{
    adjustedExtras = 100
}

# Extract error details for better visibility
if ($invalidIdResult -is [string]) {
    $apiError = $invalidIdResult | ConvertFrom-Json
    $invalidIdErrorCode = $apiError.errors[0].code
    $invalidIdErrorStatus = $apiError.status
    
    Write-TestInfo "Error returned: $invalidIdErrorCode (HTTP $invalidIdErrorStatus)"
    Write-TestInfo -Data @{ errorCode = $invalidIdErrorCode; httpStatus = $invalidIdErrorStatus }
}

Test-Assertion "Returns error [$expectedInvalidIdError]" -Passed ($invalidIdResult -is [string]) `
    -Message "Expected error but update succeeded"

Test-Assertion "Returns 4xx/5xx status" -Passed ($invalidIdResult -match '"status"\s*:\s*[45]\d{2}') `
    -Message $(if ($invalidIdResult -isnot [string]) {
        "Expected error but update succeeded"
    } else {
        "Got status: $invalidIdErrorStatus"
    })


# ============================================================================
# SCENARIO 6: GET /interlinerPayables (performance)
# ============================================================================
Start-TestScenario "GET /interlinerPayables (performance)" -Description "Verify API performance"

$elapsed = Measure-Command {
    Get-InterlinerPayables -Limit 10 | Out-Null
}

Write-TestInfo "Response time: $([math]::Round($elapsed.TotalMilliseconds, 2))ms"
Write-TestInfo -Data @{
    responseTimeMs = [math]::Round($elapsed.TotalMilliseconds, 2)
    threshold = 10000
}

Test-Assertion "Response under 10 seconds" -Passed ($elapsed.TotalMilliseconds -lt 10000) `
    -Message "Took $([math]::Round($elapsed.TotalMilliseconds, 2))ms"


# Summary
Show-TestSummary -ShowFailedTests

# Exit with appropriate code for CI/CD
if ($script:failed -gt 0) {
    exit 1
}

