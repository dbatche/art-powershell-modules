# ============================================================================
# Setup
# ============================================================================
$VerbosePreference = 'SilentlyContinue'

Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
Setup-EnvironmentVariables -Quiet

# ============================================================================
# Header
# ============================================================================
Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
Write-Host "TM-185682 - PUT /orders/{orderId}/details/{orderDetailId}" -ForegroundColor Cyan
Write-Host "`n"
Write-Host "Verify: Update existing barcode (with barcodeId) + Create new (without barcodeId)" -ForegroundColor Cyan
Write-Host "$('=' * 80)`n" -ForegroundColor Cyan

$timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")

# ============================================================================
# Create Order
# ============================================================================
Write-Host "New-Order" -ForegroundColor Cyan
$order = New-Order -Body @{
    orders = @(
        @{
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
} 4>$null

$order | Format-Table orderId, billNumber, startZone, endZone, status

# ============================================================================
# Add Detail
# ============================================================================
Write-Host "New-OrderDetail" -ForegroundColor Cyan
$detail = New-OrderDetail -OrderId $order.orderId -OrderDetail @(
    @{
        weight = 1000
        weightUnits = "LB"
    }
) 4>$null

$detail.details | Format-Table orderDetailId, items, weight, weightUnits

# ============================================================================
# Add Barcodes (Initial State)
# ============================================================================
Write-Host "New-OrderDetailBarcode (x2)" -ForegroundColor Cyan
$barcodes = New-OrderDetailBarcode -OrderId $order.orderId -OrderDetailId $detail.details[0].orderDetailId -Barcodes @(
    @{ altBarcode1 = "ORIGINAL-A"; weight = 100.5; weightUnits = "LB" }
    @{ altBarcode1 = "ORIGINAL-B"; weight = 200.5; weightUnits = "LB" }
) 4>$null

$barcodes | Format-Table barcodeId, altBarcode1, weight, weightUnits

$barcodeId1 = $barcodes[0].barcodeId

# ============================================================================
# Test: Update 1 Existing + Create 2 New Barcodes
# ============================================================================
Write-Host "Set-OrderDetail (update 1 barcode, create 2 new)" -ForegroundColor Cyan
$result = Set-OrderDetail -OrderId $order.orderId -OrderDetailId $detail.details[0].orderDetailId -OrderDetail @{
    barcodes = @(
        @{ barcodeId = $barcodeId1; altBarcode1 = "UPDATED-A"; weight = 999.99; weightUnits = "LB" },
        @{ altBarcode1 = "NEW-C"; weight = 111.11; weightUnits = "LB" },
        @{ altBarcode1 = "NEW-D"; weight = 222.22; weightUnits = "LB" }
    )
} 4>$null

$result.barcodes | Format-Table barcodeId, altBarcode1, weight, weightUnits
