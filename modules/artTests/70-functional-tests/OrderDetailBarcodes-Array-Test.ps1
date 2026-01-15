# TM-185682: Duplicate Barcode ID with PUT - ACTUAL SCENARIO
# Tests PUT /orders/{orderId}/details/{orderDetailId} with barcodes array
#
# SCENARIO:
# 1. Order detail originally has 2 barcodes
# 2. PUT request includes 3 barcode objects in array:
#    - Item 1: HAS barcodeId from original → should UPDATE existing barcode
#    - Item 2: NO barcodeId → should CREATE new barcode
#    - Item 3: NO barcodeId → should CREATE new barcode
# 3. Expected result: 4 total barcodes (1 untouched, 1 updated, 2 new)
#
# KEY QUESTION: Does including barcodeId in the array properly identify which 
# barcode to update, or does it cause duplicates/errors?

param(
    [int]$OrderId,           # Optional: Order ID to test against
    [int]$OrderDetailId,     # Optional: Order detail ID
    [string]$LogFile = "orderbarcodes-array-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Import required modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

Initialize-TestResults -LogFile $LogFile

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682: PUT /orders/{orderId}/details/{detailId} WITH BARCODES ARRAY" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# SETUP: Find or use specified order detail with barcodes
# ============================================================================
Write-Host "🔍 SETUP: Finding order detail with barcodes..." -ForegroundColor Yellow
Write-Host ""

if (-not $OrderId) {
    # Find an order with details and barcodes (not cancelled)
    Write-Host "   Searching for active order with details..." -ForegroundColor DarkGray
    $orders = Find-Orders -Filter "cancelled eq False" -Limit 10 -Expand "details"
    
    $orderWithBarcodes = $null
    foreach ($order in $orders) {
        if ($order.details -and $order.details.Count -gt 0) {
            foreach ($detail in $order.details) {
                # Check if this detail has barcodes
                $barcodes = Get-OrderDetailBarcodes -OrderId $order.orderId -OrderDetailId $detail.orderDetailId
                if ($barcodes -and $barcodes.Count -ge 1) {
                    $OrderId = $order.orderId
                    $OrderDetailId = $detail.orderDetailId
                    $orderWithBarcodes = @{
                        Order = $order
                        Detail = $detail
                        Barcodes = $barcodes
                    }
                    break
                }
            }
            if ($orderWithBarcodes) { break }
        }
    }
    
    if (-not $orderWithBarcodes) {
        Write-Host "❌ Could not find order detail with barcodes" -ForegroundColor Red
        Write-Host "   Please provide -OrderId and -OrderDetailId parameters" -ForegroundColor Yellow
        exit 1
    }
} else {
    # Get the specified order detail
    $order = Get-Order -OrderId $OrderId -Expand "details"
    $detail = $order.details | Where-Object { $_.orderDetailId -eq $OrderDetailId } | Select-Object -First 1
    
    if (-not $detail) {
        Write-Host "❌ Order detail $OrderDetailId not found in order $OrderId" -ForegroundColor Red
        exit 1
    }
    
    # Get existing barcodes
    $barcodes = Get-OrderDetailBarcodes -OrderId $OrderId -OrderDetailId $OrderDetailId
    
    $orderWithBarcodes = @{
        Order = $order
        Detail = $detail
        Barcodes = $barcodes
    }
}

$originalBarcodes = $orderWithBarcodes.Barcodes
$originalBarcodeCount = if ($originalBarcodes -is [array]) { $originalBarcodes.Count } else { 1 }

Write-Host "✅ Found test data:" -ForegroundColor Green
Write-Host "   Order ID: $OrderId" -ForegroundColor White
Write-Host "   Detail ID: $OrderDetailId" -ForegroundColor White
Write-Host "   Original barcode count: $originalBarcodeCount" -ForegroundColor White

if ($originalBarcodeCount -gt 0) {
    $firstBarcode = if ($originalBarcodes -is [array]) { $originalBarcodes[0] } else { $originalBarcodes }
    Write-Host "   First barcode ID: $($firstBarcode.barcodeId)" -ForegroundColor White
    Write-Host "   First barcode altBarcode1: $($firstBarcode.altBarcode1)" -ForegroundColor White
}

Write-Host ""
Write-TestInfo "Test setup complete" -Data @{
    orderId = $OrderId
    orderDetailId = $OrderDetailId
    originalBarcodeCount = $originalBarcodeCount
}

# ============================================================================
# SCENARIO 1: GET baseline - Current state of detail and barcodes
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{orderDetailId} (baseline)" `
    -Description "Capture current state before making changes"

$baselineDetail = Get-OrderDetail -OrderId $OrderId -OrderDetailId $OrderDetailId
$baselineBarcodes = Get-OrderDetailBarcodes -OrderId $OrderId -OrderDetailId $OrderDetailId

Test-Assertion "Retrieved order detail" -Passed ($baselineDetail -isnot [string])
Test-Assertion "Retrieved barcodes" -Passed ($baselineBarcodes -isnot [string])

$baselineBarcodeCount = if ($baselineBarcodes -is [array]) { $baselineBarcodes.Count } else { 1 }
Write-TestInfo "Baseline barcode count: $baselineBarcodeCount" -Data @{ baselineBarcodeCount = $baselineBarcodeCount }

# ============================================================================
# SCENARIO 2: PUT /orders/{orderId}/details/{detailId} with barcodes array
# ============================================================================
Start-TestScenario "PUT /orders/{orderId}/details/{orderDetailId} (with barcodes array)" `
    -Description "TM-185682: Update detail with mixed barcode array (with/without IDs)"

# Build the barcodes array for the PUT request
$putBarcodes = @()

# Item 1: Include existing barcodeId to UPDATE
if ($baselineBarcodes) {
    $existingBarcode = if ($baselineBarcodes -is [array]) { $baselineBarcodes[0] } else { $baselineBarcodes }
    $putBarcodes += @{
        barcodeId = $existingBarcode.barcodeId  # ← KEY: includes barcodeId
        altBarcode1 = "UPDATED-$(Get-Date -Format 'HHmmss')"
        weight = 999.99
        weightUnits = "LB"
    }
    Write-TestInfo "Barcode 1: Includes barcodeId $($existingBarcode.barcodeId) → should UPDATE" -Data @{
        operation = "update"
        barcodeId = $existingBarcode.barcodeId
    }
}

# Item 2: NO barcodeId → should CREATE new
$putBarcodes += @{
    # NO barcodeId field
    altBarcode1 = "NEW-A-$(Get-Date -Format 'HHmmss')"
    weight = 111.11
    weightUnits = "LB"
}
Write-TestInfo "Barcode 2: No barcodeId → should CREATE new" -Data @{ operation = "create" }

# Item 3: NO barcodeId → should CREATE new
$putBarcodes += @{
    # NO barcodeId field
    altBarcode1 = "NEW-B-$(Get-Date -Format 'HHmmss')"
    weight = 222.22
    weightUnits = "LB"
}
Write-TestInfo "Barcode 3: No barcodeId → should CREATE new" -Data @{ operation = "create" }

# Build the PUT request body
$putBody = @{
    barcodes = $putBarcodes
}

Write-Host ""
Write-Host "   📤 Sending PUT with barcodes array:" -ForegroundColor Cyan
Write-Host "      - 1 barcode WITH barcodeId (update)" -ForegroundColor White
Write-Host "      - 2 barcodes WITHOUT barcodeId (create)" -ForegroundColor White
Write-Host ""

# Execute the PUT
$putResult = Set-OrderDetail -OrderId $OrderId -OrderDetailId $OrderDetailId -OrderDetail $putBody

if ($putResult -is [string]) {
    # Error occurred
    $apiError = $putResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    $errorTitle = if ($apiError.errors[0].title) { $apiError.errors[0].title } else { "" }
    $errorDescription = if ($apiError.errors[0].description) { $apiError.errors[0].description } else { "" }
    
    Write-Host ""
    Write-Host "   ❌ ERROR DETAILS:" -ForegroundColor Red
    Write-Host "      Code: $errorCode" -ForegroundColor Yellow
    Write-Host "      Status: HTTP $errorStatus" -ForegroundColor Yellow
    if ($errorTitle) {
        Write-Host "      Title: $errorTitle" -ForegroundColor Yellow
    }
    if ($errorDescription) {
        Write-Host "      Description: $errorDescription" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "   📄 Full Error JSON:" -ForegroundColor Cyan
    Write-Host $putResult -ForegroundColor DarkGray
    Write-Host ""
    
    Write-TestInfo "❌ ERROR returned: $errorCode (HTTP $errorStatus)" -Data @{ 
        errorCode = $errorCode
        httpStatus = $errorStatus
        errorTitle = $errorTitle
        errorDescription = $errorDescription
        fullError = $putResult
        tm185682 = "error_occurred"
    }
    
    Test-Assertion "PUT request failed [TM-185682: Possible duplicate issue?]" -Passed $false `
        -Message "Got error: $errorCode - $errorDescription"
} else {
    Write-TestInfo "✅ PUT request succeeded" -Data @{ tm185682 = "no_error" }
    Test-Assertion "PUT request succeeded" -Passed $true
}

# ============================================================================
# SCENARIO 3: GET after PUT - Verify the results
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{orderDetailId}/barcodes (after PUT)" `
    -Description "Verify barcode count and changes after PUT"

Start-Sleep -Milliseconds 500  # Brief pause to ensure data consistency

$afterBarcodes = Get-OrderDetailBarcodes -OrderId $OrderId -OrderDetailId $OrderDetailId

if ($afterBarcodes -is [string]) {
    Test-Assertion "Retrieved barcodes after PUT" -Passed $false
} else {
    Test-Assertion "Retrieved barcodes after PUT" -Passed $true
    
    $afterBarcodeCount = if ($afterBarcodes -is [array]) { $afterBarcodes.Count } else { 1 }
    Write-TestInfo "After PUT: $afterBarcodeCount barcodes" -Data @{ afterBarcodeCount = $afterBarcodeCount }
    
    Write-Host ""
    Write-Host "   📊 RESULTS:" -ForegroundColor Cyan
    Write-Host "      Before: $baselineBarcodeCount barcodes" -ForegroundColor White
    Write-Host "      After:  $afterBarcodeCount barcodes" -ForegroundColor White
    Write-Host "      Change: +$($afterBarcodeCount - $baselineBarcodeCount) barcodes" -ForegroundColor White
    Write-Host ""
    
    # Expected: If baseline had N barcodes, and we sent 3 in PUT (1 update + 2 new)
    # We should have N + 2 total (the untouched originals + 1 updated + 2 new)
    $expectedCount = $baselineBarcodeCount + 2
    
    Test-Assertion "Barcode count increased by 2" -Passed ($afterBarcodeCount -eq $expectedCount) `
        -Message "Expected $expectedCount, got $afterBarcodeCount"
    
    # Verify the updated barcode
    if ($putBarcodes[0].barcodeId) {
        $updatedBarcode = $afterBarcodes | Where-Object { $_.barcodeId -eq $putBarcodes[0].barcodeId } | Select-Object -First 1
        
        if ($updatedBarcode) {
            $weightMatches = $updatedBarcode.weight -eq 999.99
            Test-Assertion "Existing barcode was UPDATED (not duplicated)" -Passed $weightMatches `
                -Message "Expected weight 999.99, got $($updatedBarcode.weight)"
            
            $altBarcodeMatches = $updatedBarcode.altBarcode1 -match "^UPDATED-"
            Test-Assertion "Updated barcode has new altBarcode1" -Passed $altBarcodeMatches
            
            Write-TestInfo "✅ Barcode $($putBarcodes[0].barcodeId) was updated (not duplicated)" -Data @{
                barcodeId = $putBarcodes[0].barcodeId
                operation = "updated"
                tm185682 = "correct_behavior"
            }
        } else {
            Test-Assertion "Found updated barcode in results" -Passed $false `
                -Message "BarcodeId $($putBarcodes[0].barcodeId) not found after PUT"
            
            Write-TestInfo "⚠️ Updated barcode not found - possible duplicate?" -Data @{
                barcodeId = $putBarcodes[0].barcodeId
                tm185682 = "possible_bug"
            }
        }
    }
    
    # Verify new barcodes were created
    $newBarcodes = $afterBarcodes | Where-Object { 
        $_.altBarcode1 -match "^NEW-[AB]-" 
    }
    $newBarcodeCount = if ($newBarcodes) { if ($newBarcodes -is [array]) { $newBarcodes.Count } else { 1 } } else { 0 }
    
    Test-Assertion "2 new barcodes were created" -Passed ($newBarcodeCount -eq 2) `
        -Message "Expected 2 new, found $newBarcodeCount"
    
    # Display all barcodes
    Write-Host ""
    Write-Host "   📋 ALL BARCODES AFTER PUT:" -ForegroundColor Cyan
    foreach ($barcode in $afterBarcodes) {
        $marker = ""
        if ($barcode.barcodeId -eq $putBarcodes[0].barcodeId) {
            $marker = " ← UPDATED"
        } elseif ($barcode.altBarcode1 -match "^NEW-") {
            $marker = " ← NEWLY CREATED"
        }
        Write-Host "      ID: $($barcode.barcodeId), altBarcode1: $($barcode.altBarcode1), weight: $($barcode.weight)$marker" -ForegroundColor White
    }
    Write-Host ""
}

# ============================================================================
# CLEANUP: Optionally remove test barcodes
# ============================================================================
Write-Host ""
Write-Host "🧹 CLEANUP: Test barcodes created" -ForegroundColor Yellow
Write-Host "   Note: Not automatically deleting. Use DELETE tests to clean up if needed." -ForegroundColor DarkGray
Write-Host ""

# Show summary
Show-TestSummary -ShowFailedTests

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682 CONCLUSION" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

if ($putResult -is [string]) {
    Write-Host "❌ TM-185682: BUG CONFIRMED" -ForegroundColor Red
    Write-Host "   PUT with barcodes array (including barcodeId) returned an error" -ForegroundColor White
    Write-Host "   This may be the duplicate barcode issue reported in TM-185682" -ForegroundColor White
} elseif ($afterBarcodeCount -eq $expectedCount) {
    Write-Host "✅ TM-185682: WORKING AS DESIGNED" -ForegroundColor Green
    Write-Host "   - Including barcodeId in array UPDATES existing barcode" -ForegroundColor White
    Write-Host "   - Omitting barcodeId in array CREATES new barcodes" -ForegroundColor White
    Write-Host "   - No duplicates were created" -ForegroundColor White
    Write-Host "   - This is correct RESTful behavior" -ForegroundColor White
} else {
    Write-Host "⚠️ TM-185682: UNEXPECTED BEHAVIOR" -ForegroundColor Yellow
    Write-Host "   Barcode count does not match expected" -ForegroundColor White
    Write-Host "   Expected: $expectedCount, Got: $afterBarcodeCount" -ForegroundColor White
    Write-Host "   Review test log for details" -ForegroundColor White
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan

