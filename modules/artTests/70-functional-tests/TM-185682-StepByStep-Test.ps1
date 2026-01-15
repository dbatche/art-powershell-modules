# TM-185682: Step-by-Step Test - Builds order level by level
# Tests PUT /orders/{orderId}/details/{detailId} with barcodes array
#
# STEPS:
# 1. POST /orders (create order)
# 2. POST /orders/{id}/details (create detail)
# 3. POST /orders/{id}/details/{id}/barcodes (create 2 barcodes)
# 4. PUT /orders/{id}/details/{id} with mixed barcodes array:
#    - Item 1: HAS barcodeId → should UPDATE existing
#    - Item 2: NO barcodeId → should CREATE new
#    - Item 3: NO barcodeId → should CREATE new
# 5. Verify: Should have 4 barcodes total

param(
    [string]$LogFile = "tm185682-stepbystep-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Import required modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

Initialize-TestResults -LogFile $LogFile

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682: STEP-BY-STEP TEST" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# Variables to track created resources
$orderId = $null
$orderDetailId = $null
$barcodeIds = @()

# ============================================================================
# STEP 1: Create Order
# ============================================================================
Start-TestScenario "POST /orders" -Description "Create test order (quote type)"

$timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")

$orderBody = @{
    orders = @(
        @{
            type = "Q"
            pickUpBy = $timestamp
            pickUpByEnd = $timestamp
            deliverBy = $timestamp
            deliverByEnd = $timestamp
            startZone = "BCLAN"
            endZone = "ABCAL"
            caller = @{ clientId = "TM" }
            consignee = @{ clientId = "TMSUPPORT" }
        }
    )
}

$createResult = New-Order -Body $orderBody -Type "Q"

if ($createResult -is [string]) {
    Write-Host "❌ Failed to create order" -ForegroundColor Red
    $apiError = $createResult | ConvertFrom-Json
    Write-Host "   Error: $($apiError.errors[0].code)" -ForegroundColor Yellow
    Write-Host "   Message: $($apiError.errors[0].message)" -ForegroundColor Yellow
    Write-Host "   Full error:" -ForegroundColor Yellow
    Write-Host $createResult -ForegroundColor DarkGray
    Show-TestSummary
    exit 1
}

$orderId = if ($createResult.orders) { $createResult.orders[0].orderId } else { $createResult.orderId }
Test-Assertion "Order created" -Passed ($orderId -ne $null)
Write-TestInfo "Created Order ID: $orderId" -Data @{ orderId = $orderId }
Write-Host "   ✅ Order ID: $orderId" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 2: Create Detail Line
# ============================================================================
Start-TestScenario "POST /orders/{orderId}/details" -Description "Add detail line to order"

$detailBody = @(
    @{
        items = 10
        weight = 1000
        weightUnits = "LB"
    }
)

$detailResult = New-OrderDetail -OrderId $orderId -OrderDetail $detailBody

if ($detailResult -is [string]) {
    Write-Host "❌ Failed to create detail" -ForegroundColor Red
    $apiError = $detailResult | ConvertFrom-Json
    Write-Host "   Error: $($apiError.errors[0].code)" -ForegroundColor Yellow
    Write-Host "   Message: $($apiError.errors[0].message)" -ForegroundColor Yellow
    Write-Host "   Description: $($apiError.errors[0].description)" -ForegroundColor Yellow
    Show-TestSummary
    exit 1
}

$orderDetailId = $detailResult.details[0].orderDetailId

Test-Assertion "Detail created" -Passed ($orderDetailId -ne $null)
Write-TestInfo "Created Detail ID: $orderDetailId" -Data @{ orderDetailId = $orderDetailId }
Write-Host "   ✅ Detail ID: $orderDetailId" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 3: Create 2 Barcodes
# ============================================================================
Start-TestScenario "POST /orders/{orderId}/details/{detailId}/barcodes" -Description "Create 2 initial barcodes"

$barcodesBody = @(
    @{
        altBarcode1 = "ORIGINAL-A-$(Get-Date -Format 'HHmmss')"
        weight = 100.5
        weightUnits = "LB"
    },
    @{
        altBarcode1 = "ORIGINAL-B-$(Get-Date -Format 'HHmmss')"
        weight = 200.5
        weightUnits = "LB"
    }
)

$barcodeResult = New-OrderDetailBarcode -OrderId $orderId -OrderDetailId $orderDetailId -Barcodes $barcodesBody

if ($barcodeResult -is [string]) {
    Write-Host "❌ Failed to create barcodes" -ForegroundColor Red
    Show-TestSummary
    exit 1
}

$barcodeIds = if ($barcodeResult -is [array]) {
    $barcodeResult | ForEach-Object { $_.barcodeId }
} else {
    @($barcodeResult.barcodeId)
}

Test-Assertion "2 barcodes created" -Passed ($barcodeIds.Count -eq 2)
Write-TestInfo "Created barcode IDs: $($barcodeIds -join ', ')" -Data @{ 
    barcodeIds = $barcodeIds
    count = $barcodeIds.Count
}
Write-Host "   ✅ Barcode IDs: $($barcodeIds -join ', ')" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 4: GET Baseline Barcodes
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{detailId}/barcodes (baseline)" -Description "Verify 2 barcodes exist"

$baselineBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $orderDetailId

$baselineCount = if ($baselineBarcodes -is [array]) { $baselineBarcodes.Count } else { 1 }
Test-Assertion "Retrieved 2 barcodes" -Passed ($baselineCount -eq 2)
Write-TestInfo "Baseline count: $baselineCount" -Data @{ baselineCount = $baselineCount }

Write-Host "   📋 Baseline barcodes:" -ForegroundColor Cyan
foreach ($bc in $baselineBarcodes) {
    Write-Host "      ID: $($bc.barcodeId), altBarcode1: $($bc.altBarcode1), weight: $($bc.weight)" -ForegroundColor White
}
Write-Host ""

# ============================================================================
# STEP 5: PUT Detail with Mixed Barcodes Array (TM-185682 TEST)
# ============================================================================
Start-TestScenario "PUT /orders/{orderId}/details/{detailId} (TM-185682)" -Description "Update detail with mixed barcodes array"

$putBarcodes = @(
    # Item 1: Include barcodeId to UPDATE
    @{
        barcodeId = $barcodeIds[0]
        altBarcode1 = "UPDATED-$(Get-Date -Format 'HHmmss')"
        weight = 999.99
        weightUnits = "LB"
    },
    # Item 2: No barcodeId to CREATE
    @{
        altBarcode1 = "NEW-C-$(Get-Date -Format 'HHmmss')"
        weight = 111.11
        weightUnits = "LB"
    },
    # Item 3: No barcodeId to CREATE
    @{
        altBarcode1 = "NEW-D-$(Get-Date -Format 'HHmmss')"
        weight = 222.22
        weightUnits = "LB"
    }
)

$putBody = @{ barcodes = $putBarcodes }

Write-Host "   📤 PUT with barcodes array:" -ForegroundColor Cyan
Write-Host "      - Barcode 1: barcodeId=$($barcodeIds[0]) → UPDATE" -ForegroundColor White
Write-Host "      - Barcode 2: No barcodeId → CREATE" -ForegroundColor White
Write-Host "      - Barcode 3: No barcodeId → CREATE" -ForegroundColor White
Write-Host "      Expected: 4 total (1 untouched, 1 updated, 2 new)" -ForegroundColor White
Write-Host ""

Write-TestInfo "Attempting PUT with mixed array" -Data @{
    updateBarcodeId = $barcodeIds[0]
    newBarcodesCount = 2
}

$putResult = Set-OrderDetail -OrderId $orderId -OrderDetailId $orderDetailId -OrderDetail $putBody -Expand "barcodes"

if ($putResult -is [string]) {
    # ERROR - This is the TM-185682 bug
    $apiError = $putResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    $errorMessage = if ($apiError.errors[0].message) { $apiError.errors[0].message } else { "No message provided" }
    
    Write-Host "   ❌ PUT FAILED!" -ForegroundColor Red
    Write-Host "      Error Code: $errorCode" -ForegroundColor Yellow
    Write-Host "      HTTP Status: $errorStatus" -ForegroundColor Yellow
    Write-Host "      Message: $errorMessage" -ForegroundColor Yellow
    Write-Host ""
    
    Write-TestInfo "TM-185682 BUG CONFIRMED" -Data @{
        errorCode = $errorCode
        httpStatus = $errorStatus
        errorMessage = $errorMessage
        tm185682 = "BUG_CONFIRMED"
    }
    
    Test-Assertion "❌ TM-185682 BUG: PUT fails with barcodeId in array" -Passed $false `
        -Message "$errorCode - $errorMessage"
} else {
    Write-Host "   ✅ PUT succeeded" -ForegroundColor Green
    Test-Assertion "PUT succeeded" -Passed $true
    Write-TestInfo "PUT succeeded" -Data @{ tm185682 = "working" }
}

# ============================================================================
# STEP 6: Verify Results
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{detailId}/barcodes (after PUT)" -Description "Verify final barcode count"

Start-Sleep -Milliseconds 500

$afterBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $orderDetailId

if ($afterBarcodes -isnot [string]) {
    $afterCount = if ($afterBarcodes -is [array]) { $afterBarcodes.Count } else { 1 }
    
    Write-Host ""
    Write-Host "   📊 RESULTS:" -ForegroundColor Cyan
    Write-Host "      Before: $baselineCount barcodes" -ForegroundColor White
    Write-Host "      After:  $afterCount barcodes" -ForegroundColor White
    Write-Host "      Change: +$($afterCount - $baselineCount)" -ForegroundColor $(if ($afterCount -eq 4) { "Green" } else { "Yellow" })
    Write-Host ""
    
    Test-Assertion "Total is 4 barcodes" -Passed ($afterCount -eq 4) `
        -Message "Expected 4, got $afterCount"
    
    # Check if the first barcode was updated
    $updatedBarcode = $afterBarcodes | Where-Object { $_.barcodeId -eq $barcodeIds[0] }
    if ($updatedBarcode) {
        $wasUpdated = $updatedBarcode.weight -eq 999.99
        Test-Assertion "Barcode $($barcodeIds[0]) was UPDATED" -Passed $wasUpdated `
            -Message "Weight: $($updatedBarcode.weight)"
    }
    
    # Check for new barcodes
    $newBarcodes = $afterBarcodes | Where-Object { $_.altBarcode1 -match "^NEW-" }
    $newCount = if ($newBarcodes) { 
        if ($newBarcodes -is [array]) { $newBarcodes.Count } else { 1 }
    } else { 0 }
    
    Test-Assertion "2 new barcodes created" -Passed ($newCount -eq 2) `
        -Message "Found $newCount new"
    
    Write-Host "   📋 ALL BARCODES:" -ForegroundColor Cyan
    foreach ($bc in $afterBarcodes) {
        $marker = ""
        if ($bc.barcodeId -eq $barcodeIds[0]) { $marker = " ← UPDATED" }
        elseif ($bc.altBarcode1 -match "^NEW-") { $marker = " ← NEW" }
        elseif ($bc.altBarcode1 -match "^ORIGINAL-") { $marker = " ← ORIGINAL" }
        Write-Host "      ID: $($bc.barcodeId), alt: $($bc.altBarcode1), weight: $($bc.weight)$marker" -ForegroundColor White
    }
    Write-Host ""
    
    Write-TestInfo "Final count: $afterCount" -Data @{ afterCount = $afterCount }
}

# ============================================================================
# Summary
# ============================================================================
Show-TestSummary -ShowFailedTests

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682 VERDICT" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

if ($putResult -is [string]) {
    Write-Host "❌ BUG CONFIRMED" -ForegroundColor Red
    Write-Host ""
    Write-Host "   PUT /orders/{id}/details/{id} with barcodes array fails" -ForegroundColor White
    Write-Host "   when array includes barcodeId fields." -ForegroundColor White
    Write-Host ""
    Write-Host "   Error: $errorCode" -ForegroundColor Yellow
    Write-Host "   Message: $errorMessage" -ForegroundColor Yellow
} elseif ($afterCount -eq 4) {
    Write-Host "✅ WORKING AS DESIGNED" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Successfully updated 1 barcode and created 2 new ones" -ForegroundColor White
} else {
    Write-Host "⚠️  UNEXPECTED RESULT" -ForegroundColor Yellow
    Write-Host "   Expected 4 barcodes, got $afterCount" -ForegroundColor White
}

Write-Host ""
Write-Host "Test Resources Created:" -ForegroundColor Cyan
Write-Host "  Order ID: $orderId" -ForegroundColor White
Write-Host "  Detail ID: $orderDetailId" -ForegroundColor White
Write-Host "  Barcode IDs: $($barcodeIds -join ', ')" -ForegroundColor White
Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan

