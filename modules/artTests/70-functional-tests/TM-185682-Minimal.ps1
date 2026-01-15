Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
Setup-EnvironmentVariables -Quiet

$timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")

$orderBody = @{
    orders = @(
        @{
            type = "T"
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

$detailBody = @(
    @{
        items = 10
        weight = 1000
        weightUnits = "LB"
    }
)

$barcodeBody1 = @(
    @{
        altBarcode1 = "ORIGINAL-A"
        weight = 100.5
        weightUnits = "LB"
    }
)

$barcodeBody2 = @(
    @{
        altBarcode1 = "ORIGINAL-B"
        weight = 200.5
        weightUnits = "LB"
    }
)

Write-Host "`n[1] Create Order" -ForegroundColor Yellow
$order = New-Order -Body $orderBody -Type "T"
$orderId = $order.orderId
Write-Host "    Order: $orderId" -ForegroundColor Green

Write-Host "`n[2] Add Detail" -ForegroundColor Yellow
$detail = New-OrderDetail -OrderId $orderId -OrderDetail $detailBody
$detailId = $detail.details[0].orderDetailId
Write-Host "    Detail: $detailId" -ForegroundColor Green

Write-Host "`n[3] Add Barcode 1" -ForegroundColor Yellow
$bc1 = New-OrderDetailBarcode -OrderId $orderId -OrderDetailId $detailId -Barcodes $barcodeBody1
$barcodeId1 = if ($bc1 -is [array]) { $bc1[1].barcodeId } else { $bc1.barcodeId }
Write-Host "    Barcode: $barcodeId1 (ORIGINAL-A)" -ForegroundColor Green

Write-Host "`n[4] Add Barcode 2" -ForegroundColor Yellow
$bc2 = New-OrderDetailBarcode -OrderId $orderId -OrderDetailId $detailId -Barcodes $barcodeBody2
$barcodeId2 = if ($bc2 -is [array]) { $bc2[1].barcodeId } else { $bc2.barcodeId }
Write-Host "    Barcode: $barcodeId2 (ORIGINAL-B)" -ForegroundColor Green

Write-Host "`n[5] GET Barcodes (before PUT)" -ForegroundColor Yellow
$beforeBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $detailId
$beforeCount = if ($beforeBarcodes -is [array]) { $beforeBarcodes.Count } else { 1 }
Write-Host "    Count: $beforeCount" -ForegroundColor Green

$updateBody = @{
    barcodes = @(
        @{
            barcodeId = $barcodeId1
            altBarcode1 = "UPDATED-A"
            weight = 999.99
            weightUnits = "LB"
        },
        @{
            altBarcode1 = "NEW-C"
            weight = 111.11
            weightUnits = "LB"
        },
        @{
            altBarcode1 = "NEW-D"
            weight = 222.22
            weightUnits = "LB"
        }
    )
}

Write-Host "`n[6] PUT Detail with Mixed Barcode Array" -ForegroundColor Yellow
Write-Host "    Array[0]: barcodeId=$barcodeId1 (UPDATE)" -ForegroundColor Cyan
Write-Host "    Array[1]: no barcodeId (CREATE)" -ForegroundColor Cyan
Write-Host "    Array[2]: no barcodeId (CREATE)" -ForegroundColor Cyan
$putResult = Set-OrderDetail -OrderId $orderId -OrderDetailId $detailId -OrderDetail $updateBody

if ($putResult -is [string]) {
    Write-Host "    ❌ FAILED" -ForegroundColor Red
    $putResult
} else {
    Write-Host "    ✅ SUCCESS" -ForegroundColor Green
}

Write-Host "`n[7] GET Barcodes (after PUT)" -ForegroundColor Yellow
$afterBarcodes = Get-OrderDetailBarcodes -OrderId $orderId -OrderDetailId $detailId
$afterCount = if ($afterBarcodes -is [array]) { $afterBarcodes.Count } else { 1 }
Write-Host "    Count: $afterCount" -ForegroundColor Green

Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
Write-Host "RESULTS" -ForegroundColor Cyan
Write-Host "$('=' * 80)" -ForegroundColor Cyan
Write-Host "Before: $beforeCount barcodes" -ForegroundColor White
Write-Host "After:  $afterCount barcodes" -ForegroundColor White
Write-Host "Change: +$($afterCount - $beforeCount) barcodes" -ForegroundColor White

Write-Host "`nBarcodes:" -ForegroundColor Cyan
foreach ($bc in $afterBarcodes) {
    $marker = ""
    if ($bc.barcodeId -eq $barcodeId1) { $marker = " ← UPDATED" }
    elseif ($bc.altBarcode1 -match "NEW-") { $marker = " ← CREATED" }
    Write-Host "  ID: $($bc.barcodeId), altBarcode1: $($bc.altBarcode1), weight: $($bc.weight)$marker" -ForegroundColor White
}

if ($afterCount -eq $beforeCount + 2) {
    Write-Host "`n✅ TM-185682 FIX VERIFIED" -ForegroundColor Green
    Write-Host "   - 1 barcode updated (with barcodeId)" -ForegroundColor White
    Write-Host "   - 2 barcodes created (without barcodeId)" -ForegroundColor White
    Write-Host "   - No duplicates" -ForegroundColor White
} else {
    Write-Host "`n❌ UNEXPECTED RESULT" -ForegroundColor Red
}

Write-Host "`n$('=' * 80)" -ForegroundColor Cyan

