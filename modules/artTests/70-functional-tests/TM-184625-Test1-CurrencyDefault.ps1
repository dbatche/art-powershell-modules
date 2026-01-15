# ============================================================================
# TM-184625 - Test 1: Default Currency based on bill to profile
# ============================================================================
# This test verifies that when creating an order with a caller that has a 
# USD currency profile, the order's currencyCode is automatically set to USD
# (no thirdPartyClient billing scenario)
# ============================================================================

$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# Suppress verbose output
Import-Module artTests -Force -WarningAction SilentlyContinue 4>$null
Import-Module artTM -Force -WarningAction SilentlyContinue 4>$null
Import-Module artMasterData -Force -WarningAction SilentlyContinue 4>$null

# Setup environment variables
Setup-EnvironmentVariables -Quiet

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "TM-184625 - Test 1: Default Currency from Bill-To Profile" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Cyan

# ============================================================================
# SETUP: Find a suitable USD currency client
# ============================================================================
Write-Host "`n[1] Finding USD currency client..." -ForegroundColor White

$filter = "isInactive eq False and clientIsBillTo eq True and clientIsCaller eq True "
$filter += "and creditHold eq False and currency eq 'USD' and thirdPartyClient eq null"

$clients = Find-Clients -Filter $filter -Select "clientId,name,currency,thirdPartyClient" -Limit 1

if (-not $clients -or $clients.Count -eq 0) {
    Write-Host "ERROR: No suitable USD currency client found" -ForegroundColor Red
    exit 1
}

$usdClient = $clients[0]
Write-Host "   Found: $($usdClient.name) (ID: $($usdClient.clientId), Currency: $($usdClient.currency))" -ForegroundColor Green

# ============================================================================
# TEST: Create order with USD client and verify currency
# ============================================================================
Write-Host "`n[2] Creating order with USD client..." -ForegroundColor White

# Random order type (T, P, or Q)
$randomType = Get-Random -InputObject @('T', 'P', 'Q')

# Generate timestamps (format: yyyy-MM-ddThh:mm:ss per API spec)
$now = [DateTime]::UtcNow
$pickUpBy = $now.AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss")
$deliverBy = $now.AddDays(2).ToString("yyyy-MM-ddTHH:mm:ss")

# Create order
$orderBody = @{
    orders = @(
        @{
            pickUpBy = $pickUpBy
            pickUpByEnd = $pickUpBy
            deliverBy = $deliverBy
            deliverByEnd = $deliverBy
            startZone = "BCVAN"
            endZone = "ABCAL"
            caller = @{
                clientId = $usdClient.clientId
            }
        }
    )
}

$result = artTM\New-Order `
    -Type $randomType `
    -Body $orderBody `
    -Select "webStatus,orderId,billNumber,currencyCode,billTo,billToCode"

if ($result -is [string]) {
    Write-Host "   ERROR: API returned an error" -ForegroundColor Red
    $errorDetails = $result | ConvertFrom-Json
    Write-Host "   Status: $($errorDetails.status)" -ForegroundColor Red
    Write-Host "   Title: $($errorDetails.title)" -ForegroundColor Red
    foreach ($err in $errorDetails.errors) {
        Write-Host "   - $($err.code): $($err.description)" -ForegroundColor Red
    }
    exit 1
}

$order = $result[0]

# Get full order details with caller info
$orderWithCaller = artTM\Get-Order -OrderId $order.orderId -Expand "caller" -ErrorAction Continue 2>$null

# Check if we got an error (functions return JSON string on error)
if ($orderWithCaller -is [string]) {
    Write-Host "   ❌ Error getting order details:" -ForegroundColor Red
    $apiError = $orderWithCaller | ConvertFrom-Json
    Write-Host "   Status: $($apiError.error.status)" -ForegroundColor Yellow
    Write-Host "   Message: $($apiError.error.message)" -ForegroundColor Yellow
    if ($apiError.error.errors) {
        Write-Host "   Details:" -ForegroundColor Yellow
        $apiError.error.errors | ForEach-Object {
            Write-Host "     • [$($_.code)] $($_.message)" -ForegroundColor Gray
        }
    }
    Write-Host "   Full Error JSON:" -ForegroundColor Yellow
    Write-Host $orderWithCaller -ForegroundColor Gray
    exit 1
}

Write-Host "   Order Created: #$($orderWithCaller.billNumber) (ID: $($orderWithCaller.orderId), Type: $randomType)" -ForegroundColor Green
Write-Host "   Bill To: $($orderWithCaller.billToCode) - $($orderWithCaller.billTo)" -ForegroundColor Gray
Write-Host "   Caller: $($orderWithCaller.caller.clientCode) - $($orderWithCaller.caller.name)" -ForegroundColor Gray

# ============================================================================
# VALIDATION
# ============================================================================
Write-Host "`n[3] Validating currency code..." -ForegroundColor White

if ($order.currencyCode -eq "USD") {
    Write-Host "   ✓ PASS: Currency code is USD (matches bill-to profile)" -ForegroundColor Green
    $testPassed = $true
} else {
    Write-Host "   ✗ FAIL: Expected currency code 'USD' but got '$($order.currencyCode)'" -ForegroundColor Red
    $testPassed = $false
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
if ($testPassed) {
    Write-Host "TEST PASSED" -ForegroundColor Green
} else {
    Write-Host "TEST FAILED" -ForegroundColor Red
    exit 1
}
Write-Host ("=" * 80) -ForegroundColor Cyan

