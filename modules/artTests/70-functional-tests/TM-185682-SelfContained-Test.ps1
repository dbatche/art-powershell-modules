# TM-185682: Self-Contained Test - Creates its own test order
# Tests PUT /orders/{orderId}/details/{detailId} with barcodes array
#
# SCENARIO:
# 1. POST new order with 1 detail line containing 2 barcodes
# 2. PUT to that detail with 3 barcodes:
#    - Item 1: HAS barcodeId from original → should UPDATE existing
#    - Item 2: NO barcodeId → should CREATE new
#    - Item 3: NO barcodeId → should CREATE new
# 3. Verify: Should have 4 barcodes total (1 untouched, 1 updated, 2 new)

param(
    [string]$LogFile = "tm185682-selfcontained-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Import required modules
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force -WarningAction SilentlyContinue
Setup-EnvironmentVariables -Quiet

Initialize-TestResults -LogFile $LogFile

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682: SELF-CONTAINED TEST - Create Order with Barcodes" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# SCENARIO 1: POST new order with details and barcodes
# ============================================================================
Start-TestScenario "POST /orders (with details and barcodes)" `
    -Description "Create test order with 1 detail containing 2 barcodes"

$timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")

$orderBody = @{
    orders = @(
        @{
            type = "Q"  # Quote type (easier to create for testing)
            pickUpBy = $timestamp
            pickUpByEnd = $timestamp
            deliverBy = $timestamp
            deliverByEnd = $timestamp
            startZone = "BCLAN"
            endZone = "ABCAL"
            caller = @{ 
                clientId = "TM"
            }
            consignee = @{
                clientId = "TMSUPPORT"
            }
            details = @(
                @{
                    items = 10
                    weight = 1000
                    weightUnits = "LB"
                    barcodes = @(
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
                }
            )
        }
    )
}

Write-Host "   📤 Creating order with:" -ForegroundColor Cyan
Write-Host "      - 1 detail line" -ForegroundColor White
Write-Host "      - 2 original barcodes" -ForegroundColor White
Write-Host ""

$createResult = New-Order -Body $orderBody -Type "Q"

if ($createResult -is [string]) {
    # Error occurred
    $apiError = $createResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    
    Write-TestInfo "❌ ERROR creating order: $errorCode (HTTP $errorStatus)" -Data @{ 
        errorCode = $errorCode
        httpStatus = $errorStatus
    }
    
    Test-Assertion "POST order failed" -Passed $false `
        -Message "Cannot proceed with test - order creation failed: $errorCode"
    
    Show-TestSummary
    exit 1
} else {
    Test-Assertion "Order created successfully" -Passed $true
    
    # Extract order and detail IDs
    $createdOrder = if ($createResult.orders) { $createResult.orders[0] } else { $createResult }
    $orderId = $createdOrder.orderId
    $orderDetailId = $createdOrder.details[0].orderDetailId
    
    Write-TestInfo "Created order" -Data @{
        orderId = $orderId
        orderDetailId = $orderDetailId
    }
    
    Write-Host "   ✅ Created Order ID: $orderId" -ForegroundColor Green
    Write-Host "   ✅ Detail ID: $orderDetailId" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# SCENARIO 2: GET created barcodes (baseline)
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{detailId}/barcodes (baseline)" `
    -Description "Retrieve the 2 barcodes we just created"

$baselineBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $orderDetailId

if ($baselineBarcodes -is [string]) {
    Test-Assertion "Retrieved barcodes" -Passed $false
    Write-Host "❌ Cannot continue - failed to retrieve barcodes" -ForegroundColor Red
    Show-TestSummary
    exit 1
} else {
    Test-Assertion "Retrieved barcodes" -Passed $true
    
    $baselineBarcodeCount = if ($baselineBarcodes -is [array]) { $baselineBarcodes.Count } else { 1 }
    Write-TestInfo "Baseline: $baselineBarcodeCount barcodes" -Data @{ 
        baselineBarcodeCount = $baselineBarcodeCount
    }
    
    Test-Assertion "Created 2 barcodes" -Passed ($baselineBarcodeCount -eq 2) `
        -Message "Expected 2, got $baselineBarcodeCount"
    
    Write-Host "   📋 Baseline barcodes:" -ForegroundColor Cyan
    foreach ($bc in $baselineBarcodes) {
        Write-Host "      ID: $($bc.barcodeId), altBarcode1: $($bc.altBarcode1), weight: $($bc.weight)" -ForegroundColor White
    }
    Write-Host ""
}

# ============================================================================
# SCENARIO 3: PUT detail with mixed barcodes array (TM-185682 TEST)
# ============================================================================
Start-TestScenario "PUT /orders/{orderId}/details/{detailId} (TM-185682: mixed barcodes array)" `
    -Description "Update detail with barcodes array containing IDs + new items"

# Build the barcodes array for PUT
$putBarcodes = @()

# Item 1: Include existing barcodeId to UPDATE
$firstBarcodeId = if ($baselineBarcodes -is [array]) { $baselineBarcodes[0].barcodeId } else { $baselineBarcodes.barcodeId }
$putBarcodes += @{
    barcodeId = $firstBarcodeId  # ← KEY: includes barcodeId
    altBarcode1 = "UPDATED-$(Get-Date -Format 'HHmmss')"
    weight = 999.99
    weightUnits = "LB"
}
Write-TestInfo "Barcode 1: barcodeId=$firstBarcodeId → UPDATE" -Data @{
    operation = "update"
    barcodeId = $firstBarcodeId
}

# Item 2: NO barcodeId → CREATE new
$putBarcodes += @{
    altBarcode1 = "NEW-C-$(Get-Date -Format 'HHmmss')"
    weight = 111.11
    weightUnits = "LB"
}
Write-TestInfo "Barcode 2: No barcodeId → CREATE" -Data @{ operation = "create" }

# Item 3: NO barcodeId → CREATE new
$putBarcodes += @{
    altBarcode1 = "NEW-D-$(Get-Date -Format 'HHmmss')"
    weight = 222.22
    weightUnits = "LB"
}
Write-TestInfo "Barcode 3: No barcodeId → CREATE" -Data @{ operation = "create" }

# Build PUT request body
$putBody = @{
    barcodes = $putBarcodes
}

Write-Host "   📤 Sending PUT with barcodes array:" -ForegroundColor Cyan
Write-Host "      - 1 barcode WITH barcodeId=$firstBarcodeId (update)" -ForegroundColor White
Write-Host "      - 2 barcodes WITHOUT barcodeId (create)" -ForegroundColor White
Write-Host "      Expected result: 4 total (1 untouched, 1 updated, 2 new)" -ForegroundColor White
Write-Host ""

$putResult = Set-OrderDetail -OrderId $orderId -OrderDetailId $orderDetailId -OrderDetail $putBody -Expand "barcodes"

if ($putResult -is [string]) {
    # Error occurred - THIS IS THE TM-185682 BUG
    $apiError = $putResult | ConvertFrom-Json
    $errorCode = $apiError.errors[0].code
    $errorStatus = $apiError.status
    $errorMessage = if ($apiError.errors[0].message) { $apiError.errors[0].message } else { "" }
    
    Write-Host "   ❌ PUT FAILED - ERROR RETURNED:" -ForegroundColor Red
    Write-Host "      Code: $errorCode" -ForegroundColor Yellow
    Write-Host "      Status: HTTP $errorStatus" -ForegroundColor Yellow
    if ($errorMessage) {
        Write-Host "      Message: $errorMessage" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-TestInfo "❌ TM-185682 BUG CONFIRMED: $errorCode" -Data @{ 
        errorCode = $errorCode
        httpStatus = $errorStatus
        errorMessage = $errorMessage
        tm185682 = "BUG_CONFIRMED"
    }
    
    Test-Assertion "❌ TM-185682 BUG: PUT with barcodeId in array fails" -Passed $false `
        -Message "Error: $errorCode - $errorMessage"
} else {
    Write-Host "   ✅ PUT succeeded" -ForegroundColor Green
    Write-TestInfo "✅ PUT succeeded (bug NOT reproduced)" -Data @{ tm185682 = "working_as_designed" }
    Test-Assertion "PUT request succeeded" -Passed $true
}

# ============================================================================
# SCENARIO 4: GET barcodes after PUT - Verify results
# ============================================================================
Start-TestScenario "GET /orders/{orderId}/details/{detailId}/barcodes (after PUT)" `
    -Description "Verify barcode count and updates"

Start-Sleep -Milliseconds 500

$afterBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $orderDetailId

if ($afterBarcodes -is [string]) {
    Test-Assertion "Retrieved barcodes after PUT" -Passed $false
} else {
    Test-Assertion "Retrieved barcodes after PUT" -Passed $true
    
    $afterBarcodeCount = if ($afterBarcodes -is [array]) { $afterBarcodes.Count } else { 1 }
    Write-TestInfo "After PUT: $afterBarcodeCount barcodes" -Data @{ 
        afterBarcodeCount = $afterBarcodeCount
    }
    
    Write-Host ""
    Write-Host "   📊 RESULTS:" -ForegroundColor Cyan
    Write-Host "      Before: $baselineBarcodeCount barcodes" -ForegroundColor White
    Write-Host "      After:  $afterBarcodeCount barcodes" -ForegroundColor White
    Write-Host "      Change: +$($afterBarcodeCount - $baselineBarcodeCount)" -ForegroundColor $(if ($afterBarcodeCount -eq 4) { "Green" } else { "Yellow" })
    Write-Host ""
    
    # Expected: 4 total (1 untouched original + 1 updated + 2 new)
    $expectedCount = 4
    
    Test-Assertion "Total barcode count is 4" -Passed ($afterBarcodeCount -eq $expectedCount) `
        -Message "Expected $expectedCount, got $afterBarcodeCount"
    
    # Verify the updated barcode
    $updatedBarcode = $afterBarcodes | Where-Object { $_.barcodeId -eq $firstBarcodeId }
    if ($updatedBarcode) {
        $weightMatches = $updatedBarcode.weight -eq 999.99
        Test-Assertion "Barcode $firstBarcodeId was UPDATED (weight=999.99)" -Passed $weightMatches `
            -Message "Weight: $($updatedBarcode.weight)"
        
        $altBarcodeMatches = $updatedBarcode.altBarcode1 -match "^UPDATED-"
        Test-Assertion "Updated barcode has new altBarcode1" -Passed $altBarcodeMatches
    }
    
    # Verify new barcodes were created
    $newBarcodes = $afterBarcodes | Where-Object { $_.altBarcode1 -match "^NEW-[CD]-" }
    $newBarcodeCount = if ($newBarcodes) { 
        if ($newBarcodes -is [array]) { $newBarcodes.Count } else { 1 } 
    } else { 0 }
    
    Test-Assertion "2 new barcodes were created" -Passed ($newBarcodeCount -eq 2) `
        -Message "Found $newBarcodeCount new barcodes"
    
    # Display all barcodes
    Write-Host ""
    Write-Host "   📋 ALL BARCODES AFTER PUT:" -ForegroundColor Cyan
    foreach ($bc in $afterBarcodes) {
        $marker = ""
        if ($bc.barcodeId -eq $firstBarcodeId) {
            $marker = " ← UPDATED"
        } elseif ($bc.altBarcode1 -match "^NEW-") {
            $marker = " ← NEWLY CREATED"
        } elseif ($bc.altBarcode1 -match "^ORIGINAL-") {
            $marker = " ← UNTOUCHED ORIGINAL"
        }
        Write-Host "      ID: $($bc.barcodeId), altBarcode1: $($bc.altBarcode1), weight: $($bc.weight)$marker" -ForegroundColor White
    }
    Write-Host ""
}

# Show summary
Show-TestSummary -ShowFailedTests

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-185682 FINAL VERDICT" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

if ($putResult -is [string]) {
    Write-Host "❌ TM-185682: BUG CONFIRMED" -ForegroundColor Red
    Write-Host ""
    Write-Host "   The API returns an error when attempting to PUT a detail" -ForegroundColor White
    Write-Host "   with a barcodes array that includes barcodeId fields." -ForegroundColor White
    Write-Host ""
    Write-Host "   Error: $errorCode" -ForegroundColor Yellow
    if ($errorMessage) {
        Write-Host "   Message: $errorMessage" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "   This prevents updating existing barcodes via the detail PUT," -ForegroundColor White
    Write-Host "   which should be valid according to RESTful principles." -ForegroundColor White
} elseif ($afterBarcodeCount -eq 4) {
    Write-Host "✅ TM-185682: WORKING AS DESIGNED" -ForegroundColor Green
    Write-Host ""
    Write-Host "   - Including barcodeId in array UPDATES existing barcode" -ForegroundColor White
    Write-Host "   - Omitting barcodeId in array CREATES new barcodes" -ForegroundColor White
    Write-Host "   - Result: 4 total barcodes (1 untouched, 1 updated, 2 new)" -ForegroundColor White
    Write-Host "   - No duplicates were created" -ForegroundColor White
} else {
    Write-Host "⚠️ TM-185682: UNEXPECTED BEHAVIOR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Barcode count: $afterBarcodeCount (expected 4)" -ForegroundColor White
    Write-Host "   Review test log for details" -ForegroundColor White
}

Write-Host ""
Write-Host "Test order created: Order ID $orderId" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan

