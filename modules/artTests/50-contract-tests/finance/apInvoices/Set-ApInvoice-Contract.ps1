# ============================================================================
# Contract Test: Set-ApInvoice (PUT /apInvoices/{apInvoiceId})
# ============================================================================
# Purpose: Validate 4xx error handling (contract/input validation)
# Focus: API controller validation BEFORE database calls
# ============================================================================

$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'  # Don't terminate on API errors

# Import modules
Import-Module artTests -Force -WarningAction SilentlyContinue 4>$null
Import-Module artFinance -Force -WarningAction SilentlyContinue 4>$null

# Setup environment
Setup-EnvironmentVariables -Quiet

# Helper function to safely display API errors
function Show-ApiError {
    param([string]$ResultString)
    
    Write-Host "`n  === RAW ERROR JSON ===" -ForegroundColor Red
    Write-Host $ResultString -ForegroundColor Gray
    Write-Host "  === END RAW JSON ===`n" -ForegroundColor Red
    
    try {
        $apiError = $ResultString | ConvertFrom-Json
        
        # Try to extract common fields
        if ($apiError.error) {
            Write-Host "  Status: $($apiError.error.status)" -ForegroundColor Yellow
            
            # Check for errors array (ART API pattern)
            if ($apiError.error.errors -and $apiError.error.errors.Count -gt 0) {
                Write-Host "  Error Count: $($apiError.error.errors.Count)" -ForegroundColor Cyan
                foreach ($err in $apiError.error.errors) {
                    Write-Host "    - Code: $($err.code)" -ForegroundColor Yellow
                    Write-Host "      Title: $($err.title)" -ForegroundColor Gray
                    if ($err.detail) {
                        Write-Host "      Detail: $($err.detail)" -ForegroundColor DarkGray
                    }
                }
            } else {
                # No errors array, show outer title
                Write-Host "  Title: $($apiError.error.title)" -ForegroundColor Yellow
            }
        } elseif ($apiError.status) {
            # Alternative structure
            Write-Host "  Status: $($apiError.status)" -ForegroundColor Yellow
            Write-Host "  Title: $($apiError.title)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  (Could not parse error JSON structure)" -ForegroundColor Red
    }
}

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "Contract Test: Set-ApInvoice (PUT /apInvoices/{apInvoiceId})" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Cyan

# ============================================================================
# Test Data - Get a valid AP Invoice to work with
# ============================================================================
Write-Host "`n[Setup] Getting a valid AP Invoice..." -ForegroundColor White

# Get without $select first to see what fields are available
$existingInvoices = Get-ApInvoices -Limit 1
if ($existingInvoices -is [string]) {
    Write-Host "  Error getting invoices:" -ForegroundColor Red
    Write-Host $existingInvoices -ForegroundColor Gray
    exit 1
}

if (-not $existingInvoices -or $existingInvoices.Count -eq 0) {
    Write-Host "  No AP Invoices found in system. Cannot run tests." -ForegroundColor Red
    Write-Host "  Create at least one AP Invoice first." -ForegroundColor Yellow
    exit 1
}

$testInvoice = $existingInvoices[0]
$testInvoiceId = $testInvoice.apInvoiceId
Write-Host "  Using Invoice ID: $testInvoiceId" -ForegroundColor Green

# Show what fields are actually available
Write-Host "  Available fields:" -ForegroundColor Gray
$testInvoice.PSObject.Properties | Select-Object -First 5 | ForEach-Object {
    Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Gray
}

# ============================================================================
# TEST 1: Invalid ApInvoiceId (Non-existent)
# ============================================================================
Write-Host "`n[Test 1] PUT with non-existent apInvoiceId (999999999)" -ForegroundColor Cyan
Write-Host "Expected: 404 - resourceNotFound" -ForegroundColor Gray

$validInvoice = @{
    vendorId = $testInvoice.vendorId
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = $testInvoice.currencyCode
    vendorBillAmount = 100.00
}

$result = Set-ApInvoice -ApInvoiceId 999999999 -ApInvoice $validInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 2: Invalid ApInvoiceId (String instead of number)
# ============================================================================
Write-Host "`n[Test 2] PUT with invalid apInvoiceId type ('abc')" -ForegroundColor Cyan
Write-Host "Expected: 400 - invalidParameter or typeError" -ForegroundColor Gray

$result = Set-ApInvoice -ApInvoiceId "abc" -ApInvoice $validInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 3: Empty Body
# ============================================================================
Write-Host "`n[Test 3] PUT with empty body" -ForegroundColor Cyan
Write-Host "Expected: 400 - missingRequiredFields (vendorId, vendorBillNumber, vendorBillDate, currencyCode)" -ForegroundColor Gray

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice @{}
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 4: Invalid Field Type (vendorBillAmount as string)
# ============================================================================
Write-Host "`n[Test 4] PUT with invalid field type (vendorBillAmount='not-a-number')" -ForegroundColor Cyan
Write-Host "Expected: 400 - invalidFieldType or typeError" -ForegroundColor Gray

$badTypeInvoice = @{
    vendorId = $testInvoice.vendorId
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = $testInvoice.currencyCode
    vendorBillAmount = "not-a-number"
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $badTypeInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 5: Negative Amount
# ============================================================================
Write-Host "`n[Test 5] PUT with negative vendorBillAmount" -ForegroundColor Cyan
Write-Host "Expected: 400 - invalidFieldValue (if business rule) or Success (if allowed)" -ForegroundColor Gray

$negativeInvoice = @{
    vendorId = $testInvoice.vendorId
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = $testInvoice.currencyCode
    vendorBillAmount = -100.00
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $negativeInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Success - Negative amounts allowed" -ForegroundColor Green
    Write-Host "  Amount: $($result.vendorBillAmount)" -ForegroundColor Gray
}

# ============================================================================
# TEST 6: Missing Required Fields (one at a time)
# ============================================================================
Write-Host "`n[Test 6] PUT missing required field 'vendorId'" -ForegroundColor Cyan
Write-Host "Expected: 400 - missingRequiredField" -ForegroundColor Gray

$missingVendorId = @{
    # vendorId = $testInvoice.vendorId  # MISSING
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = $testInvoice.currencyCode
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $missingVendorId
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 7: Invalid Date Format
# ============================================================================
Write-Host "`n[Test 7] PUT with invalid date format (vendorBillDate='invalid-date')" -ForegroundColor Cyan
Write-Host "Expected: 400 - invalidDateFormat" -ForegroundColor Gray

$invalidDateInvoice = @{
    vendorId = $testInvoice.vendorId
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = "invalid-date"
    currencyCode = $testInvoice.currencyCode
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $invalidDateInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 8: Multiple MaxLength Violations (combined test)
# ============================================================================
Write-Host "`n[Test 8] PUT with multiple maxLength violations simultaneously" -ForegroundColor Cyan
Write-Host "Expected: 400 - array of maxLengthExceeded errors" -ForegroundColor Gray
Write-Host "  vendorId (max 10): 11 chars" -ForegroundColor DarkGray
Write-Host "  vendorBillNumber (max 20): 21 chars" -ForegroundColor DarkGray
Write-Host "  currencyCode (max 3): 4 chars" -ForegroundColor DarkGray
Write-Host "  equipmentId (max 10): 11 chars" -ForegroundColor DarkGray
Write-Host "  trailerId (max 10): 11 chars" -ForegroundColor DarkGray
Write-Host "  payableTerms (max 10): 11 chars" -ForegroundColor DarkGray

$multiMaxLengthInvoice = @{
    vendorId = "A" * 11  # Max 10
    vendorBillNumber = "B" * 21  # Max 20
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = "USDA"  # Max 3
    equipmentId = "E" * 11  # Max 10
    trailerId = "T" * 11  # Max 10
    payableTerms = "P" * 11  # Max 10
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $multiMaxLengthInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# TEST 9: Invalid Enum Value (payableType='invalid')
# ============================================================================
Write-Host "`n[Test 9] PUT with invalid enum value (payableType='invalid')" -ForegroundColor Cyan
Write-Host "Expected: 400 - invalidEnumValue (valid: bill, credit, debit)" -ForegroundColor Gray

$invalidEnumInvoice = @{
    vendorId = $testInvoice.vendorId
    vendorBillNumber = $testInvoice.vendorBillNumber
    vendorBillDate = $testInvoice.vendorBillDate
    currencyCode = $testInvoice.currencyCode
    payableType = "invalid"
}

$result = Set-ApInvoice -ApInvoiceId $testInvoiceId -ApInvoice $invalidEnumInvoice
if ($result -is [string]) {
    Show-ApiError $result
} else {
    Write-Host "  Unexpected Success!" -ForegroundColor Red
    $result | Format-List
}

# ============================================================================
# Summary
# ============================================================================
Write-Host "`n" ("=" * 80) -ForegroundColor Cyan
Write-Host "Contract Testing Summary" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host @"

Completed Contract Tests for PUT /apInvoices/{apInvoiceId}:
  1. Non-existent apInvoiceId (404)
  2. Invalid apInvoiceId type (400)
  3. Empty body (400 - missing all required fields)
  4. Invalid field type - vendorBillAmount as string (400)
  5. Negative amount (400 or success based on business rules)
  6. Missing required field - vendorId (400)
  7. Invalid date format (400)
  8. Multiple maxLength violations - 6 fields simultaneously (400 with error array)
  9. Invalid enum value - payableType (400)

Required Fields (per OpenAPI):
  - vendorId* (string, max 10)
  - vendorBillNumber* (string, max 20)
  - vendorBillDate* (date: yyyy-MM-dd)
  - currencyCode* (string, max 3)

MaxLength Constraints Tested in Test 8:
  - vendorId: 10
  - vendorBillNumber: 20
  - currencyCode: 3
  - equipmentId: 10
  - trailerId: 10
  - payableTerms: 10

Next Steps:
  - Review actual error codes returned above
  - Verify Test 8 returns an array of 6 errors (one per field violation)
  - Document expected vs actual error codes
  - Convert to Pester test with Should assertions
  - Add tests for other required fields (vendorBillNumber, vendorBillDate, currencyCode)

"@ -ForegroundColor White

