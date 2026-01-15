# Demo: Using Test-ContractCompliance with existing test logs
# This shows how to validate API responses against OpenAPI schemas

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "CONTRACT COMPLIANCE VALIDATION DEMO" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

# Load the validation function
. .\Test-ContractCompliance.ps1

# Example 1: Simple validation with a mock schema
Write-Host "`nExample 1: Validating a tripFuelPurchase response" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Gray

# Mock response from API
$response = @{
    tripFuelPurchaseId = 66
    fuelTaxId = 2
    purchaseSequence = 57
    receipt = "False"
    fuelStationCity = "TestCity"
    driverId1 = "DRIVER001"
    odometer = 50000
}

# Schema definition (from OpenAPI spec)
$schema = @{
    tripFuelPurchaseId = @{ Type = 'integer'; ReadOnly = $true }
    fuelTaxId = @{ Type = 'integer'; Required = $true }
    purchaseSequence = @{ Type = 'integer'; ReadOnly = $true }
    receipt = @{ Type = 'string'; Required = $true }
    fuelStationCity = @{ Type = 'string'; MaxLength = 50 }
    driverId1 = @{ Type = 'string'; MaxLength = 10 }
    odometer = @{ Type = 'integer'; Minimum = 0; Maximum = 9999999 }
}

$result1 = Test-ContractCompliance -Response $response -Schema $schema

# Example 2: Validation with errors
Write-Host "`n`nExample 2: Validating with constraint violations" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Gray

$badResponse = @{
    tripFuelPurchaseId = 67
    # fuelTaxId = missing (required!)
    receipt = "False"
    fuelStationCity = "ThisCityNameIsWayTooLongAndExceedsTheMaximumLengthOf50Characters"
    driverId1 = "VERYLONGDRIVERID" # Exceeds maxLength 10
    odometer = -100 # Below minimum
}

$result2 = Test-ContractCompliance -Response $badResponse -Schema $schema

# Example 3: Request validation (checking read-only fields)
Write-Host "`n`nExample 3: Validating a request (checking read-only fields)" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Gray

$requestBody = @{
    tripFuelPurchaseId = 999  # Read-only! Shouldn't be in request
    fuelTaxId = 2
    receipt = "True"
    fuelStationCity = "Boston"
}

$result3 = Test-ContractCompliance -Response $requestBody -Schema $schema -IsRequest

# Example 4: Validating from actual test log
Write-Host "`n`nExample 4: Validating from test log file" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Gray

$logFile = Get-ChildItem "contract-test-FINAL-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($logFile) {
    Write-Host "Loading test log: $($logFile.Name)" -ForegroundColor Cyan
    $log = Get-Content $logFile.FullName | ConvertFrom-Json
    
    # Find a successful POST test
    $successTest = $log.Results | Where-Object { $_.Method -eq 'POST' -and $_.ActualStatus -eq 201 } | Select-Object -First 1
    
    if ($successTest) {
        Write-Host "Validating test: $($successTest.Name)" -ForegroundColor Cyan
        
        # Parse the response (handle quoted JSON bug)
        try {
            $testResponse = $successTest.Body | ConvertFrom-Json
            
            # If it's a wrapper with array, extract first item
            if ($testResponse.tripFuelPurchases) {
                $actualResponse = $testResponse.tripFuelPurchases[0]
            } else {
                $actualResponse = $testResponse
            }
            
            $result4 = Test-ContractCompliance -Response $actualResponse -Schema $schema
            
        } catch {
            Write-Host "  ⚠ Could not parse response (known API bug: quoted JSON)" -ForegroundColor Yellow
            Write-Host "  Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠ No successful POST tests found in log" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ No contract test log files found" -ForegroundColor Yellow
}

# Summary
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "VALIDATION RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""
Write-Host "Example 1 (Valid response):    $($result1.Summary)" -ForegroundColor $(if ($result1.IsValid) { 'Green' } else { 'Red' })
Write-Host "Example 2 (Invalid response):  $($result2.Summary)" -ForegroundColor $(if ($result2.IsValid) { 'Green' } else { 'Red' })
Write-Host "Example 3 (Request w/ RO):     $($result3.Summary)" -ForegroundColor $(if ($result3.IsValid) { 'Green' } else { 'Red' })

Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Integrate with Analyze-TestLog.ps1 to auto-validate all responses" -ForegroundColor Yellow
Write-Host "2. Extract schemas from OpenAPI spec using Analyze-OpenApiSchema.Public.ps1" -ForegroundColor Yellow
Write-Host "3. Add compliance reporting to test runs" -ForegroundColor Yellow
Write-Host ""

