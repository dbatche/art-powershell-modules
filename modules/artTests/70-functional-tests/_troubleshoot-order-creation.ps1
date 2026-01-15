# Simple step-by-step order creation troubleshooting script
# Just run commands and see what happens!

Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force
Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
Setup-EnvironmentVariables -Quiet

Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
Write-Host "STEP-BY-STEP ORDER CREATION" -ForegroundColor Cyan
Write-Host "$('=' * 80)`n" -ForegroundColor Cyan

# ============================================================================
# STEP 1: Create Order
# ============================================================================
Write-Host "[1] Creating Order..." -ForegroundColor Yellow
Write-Host ""

$timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")

New-Order -Body @{
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
} -Type "Q"

Write-Host ""
Write-Host "👆 If you see an orderId above, copy it for the next step" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 2: Add Detail to Order
# ============================================================================
Write-Host "[2] Adding Detail to Order..." -ForegroundColor Yellow
Write-Host "    (Paste the orderId from step 1 below)" -ForegroundColor DarkGray
Write-Host ""

# User needs to provide the orderId here
# Set-Order -OrderId ??? -Updates @{ details = @( @{ items = 10; weight = 1000; weightUnits = "LB" } ) }

Write-Host "Run this command with your order ID:" -ForegroundColor Yellow
Write-Host "Set-Order -OrderId YOUR_ORDER_ID -Updates @{ details = @( @{ items = 10; weight = 1000; weightUnits = 'LB' } ) }" -ForegroundColor Green
Write-Host ""
Write-Host "Then retrieve it to see the detail ID:" -ForegroundColor Yellow
Write-Host "Get-Order -OrderId YOUR_ORDER_ID -Expand 'details'" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 3: Add Barcode to Detail
# ============================================================================
Write-Host "[3] Adding Barcode to Detail..." -ForegroundColor Yellow
Write-Host "    (Use orderId and detailId from previous steps)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Run this command with your IDs:" -ForegroundColor Yellow
Write-Host "New-OrderDetailBarcode -OrderId YOUR_ORDER_ID -OrderDetailId YOUR_DETAIL_ID -Barcodes @( @{ altBarcode1 = 'TEST-BARCODE'; weight = 100.5; weightUnits = 'LB' } )" -ForegroundColor Green
Write-Host ""

Write-Host "$('=' * 80)" -ForegroundColor Cyan
