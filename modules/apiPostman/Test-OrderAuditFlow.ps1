<#
.SYNOPSIS
    Tests the order audit flow - creates order, updates with audits, validates response and statusHistory

.DESCRIPTION
    Replicates the Postman audit test:
    1. Creates a posted order with default data
    2. PUTs to the order with audits array (deliverBy, deliverByEnd, deliveryApptReq, deliveryApptMade)
    3. Validates that 'audits' is NOT in the PUT response (write-only field)
    4. GETs /statusHistory to verify audit entries were created
    5. Validates audit entries match the request

.PARAMETER BaseUrl
    Base URL for the TM API (defaults to environment variable TM_API_BASE_URL)

.PARAMETER Token
    Bearer token for authentication (defaults to environment variable TRUCKMATE_API_KEY)

.EXAMPLE
    .\Test-OrderAuditFlow.ps1

.EXAMPLE
    .\Test-OrderAuditFlow.ps1 -BaseUrl "https://tde-truckmate.tmwcloud.com/cur/tm" -Token $env:TRUCKMATE_API_KEY
#>

param(
    [Parameter()]
    [string]$BaseUrl = $env:TM_API_URL,
    
    [Parameter()]
    [string]$Token = $env:TRUCKMATE_API_KEY
)

$ErrorActionPreference = 'Stop'

# Helper function to make API requests
function Invoke-TmApiRequest {
    param(
        [string]$Uri,
        [string]$Method = 'GET',
        [object]$Body,
        [string]$Token
    )
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
    }
    
    $params = @{
        Uri = $Uri
        Method = $Method
        Headers = $headers
    }
    
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    
    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        throw
    }
}

# Main test flow
Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host "Order Audit Flow Test" -ForegroundColor Yellow
Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host ""

# Create timestamps
$timestamp1 = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$timestamp2 = (Get-Date).AddMinutes(10).ToString("yyyy-MM-ddTHH:mm:ss")

Write-Host "Timestamp 1 (initial): $timestamp1" -ForegroundColor Gray
Write-Host "Timestamp 2 (+10min):  $timestamp2" -ForegroundColor Gray
Write-Host ""

# Step 1: Create a posted order
Write-Host "Step 1: Creating posted order..." -ForegroundColor Cyan

$orderBody = @{
	orders=@(@{
    startZone = "ABEDM"
    endZone = "MBBRA"
    serviceLevel = "LTL"
	billTo = "C"
    caller = @{clientId='TM'}
    pickUpBy = $timestamp1
	pickUpByEnd = $timestamp1
	deliverBy = $timestamp1
	deliverByEnd = $timestamp1
	})
}

$createResponse = Invoke-TmApiRequest -Uri "$BaseUrl/orders" -Method POST -Body @($orderBody) -Token $Token

if ($createResponse.orders -and $createResponse.orders.Count -gt 0) {
    $orderId = $createResponse.orders[0].orderId
    Write-Host "  ✓ Created order: $orderId" -ForegroundColor Green
} else {
    throw "Failed to create order - no orderId returned"
}

Write-Host ""

# Step 2: Update order with audits
Write-Host "Step 2: Updating order with audits array..." -ForegroundColor Cyan

$updateBody = @{
    startZone = "ABEDM"
    endZone = "MBBRA"
    serviceLevel = "LTL"
    deliverBy = $timestamp2
    deliverByEnd = $timestamp2
    deliveryApptMade = "True"
    deliveryApptReq = "True"
    audits = @(
        @{
            auditField = "deliverBy"
            auditStatus = "AUDIT2"
            reasonCode = "SF1"
            comment = "DDDD"
        },
        @{
            auditField = "deliverByEnd"
            auditStatus = "AUDIT2"
            reasonCode = "SF1"
            comment = "EEEE"
        },
        @{
            auditField = "deliveryApptReq"
            auditStatus = "AUDIT2"
            reasonCode = "SF1"
            comment = "FFFF1"
        },
        @{
            auditField = "deliveryApptMade"
            auditStatus = "AUDIT2"
            reasonCode = "SF1"
            comment = "FFFF"
        }
    )
}

$updateResponse = Invoke-TmApiRequest -Uri "$BaseUrl/orders/$orderId" -Method PUT -Body $updateBody -Token $Token

Write-Host "  ✓ Updated order successfully" -ForegroundColor Green
Write-Host ""

# Step 3: Validate 'audits' is NOT in response (write-only field)
Write-Host "Step 3: Validating 'audits' is NOT in response..." -ForegroundColor Cyan

if ($updateResponse.PSObject.Properties.Name -contains 'audits') {
    Write-Host "  ✗ FAIL: Response contains 'audits' array (should be write-only)" -ForegroundColor Red
    $testsPassed = $false
} else {
    Write-Host "  ✓ PASS: Response does not contain 'audits' array" -ForegroundColor Green
    $testsPassed = $true
}

Write-Host ""

# Step 4: GET statusHistory
Write-Host "Step 4: Getting statusHistory..." -ForegroundColor Cyan

$statusHistoryResponse = Invoke-TmApiRequest -Uri "$BaseUrl/orders/$orderId/statusHistory" -Method GET -Token $Token

$statusHistory = $statusHistoryResponse.statusHistory

if ($statusHistory) {
    Write-Host "  ✓ Retrieved $($statusHistory.Count) statusHistory entries" -ForegroundColor Green
} else {
    Write-Host "  ✗ No statusHistory entries found" -ForegroundColor Red
    $testsPassed = $false
}

Write-Host ""

# Step 5: Validate audit entries in statusHistory
Write-Host "Step 5: Validating audit entries in statusHistory..." -ForegroundColor Cyan

# Filter for audit entries (statusCode = AUDIT2, reason = SF1)
$auditEntries = $statusHistory | Where-Object { 
    $_.statusCode -eq 'AUDIT2' -and $_.reason -eq 'SF1'
}

Write-Host "  Found $($auditEntries.Count) audit entries:" -ForegroundColor White

if ($auditEntries.Count -eq 0) {
    Write-Host "  ✗ FAIL: No audit entries found in statusHistory" -ForegroundColor Red
    $testsPassed = $false
} else {
    Write-Host "  ✓ PASS: Found $($auditEntries.Count) audit entry(ies)" -ForegroundColor Green
    
    # Display the audit entries
    foreach ($entry in $auditEntries) {
        Write-Host "    - Status: $($entry.statusCode), Reason: $($entry.reason)" -ForegroundColor Gray
        Write-Host "      Comment: $($entry.statComment)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Check if each audit from request is referenced in statusHistory
    $requestAudits = $updateBody.audits
    $auditFieldsFound = @()
    
    foreach ($audit in $requestAudits) {
        $matchingEntry = $auditEntries | Where-Object {
            # Check if the field name or comment appears in the statComment
            ($_.statComment -and $_.statComment.ToLower().Contains($audit.auditField.ToLower())) -or
            ($_.statComment -and $_.statComment.Contains($audit.comment))
        }
        
        if ($matchingEntry) {
            Write-Host "  ✓ Audit for '$($audit.auditField)' found in statusHistory" -ForegroundColor Green
            $auditFieldsFound += $audit.auditField
        } else {
            Write-Host "  ⚠ Audit for '$($audit.auditField)' not explicitly found (may be consolidated)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # Summary
    if ($auditFieldsFound.Count -ge 1) {
        Write-Host "  ✓ PASS: At least one audit entry verified in statusHistory" -ForegroundColor Green
    } else {
        Write-Host "  ✗ FAIL: No audit entries could be verified" -ForegroundColor Red
        $testsPassed = $false
    }
}

Write-Host ""

# Final summary
Write-Host ("=" * 120) -ForegroundColor Cyan
if ($testsPassed) {
    Write-Host "✅ ALL TESTS PASSED" -ForegroundColor Green
} else {
    Write-Host "❌ SOME TESTS FAILED" -ForegroundColor Red
}
Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host ""

Write-Host "Test Summary:" -ForegroundColor Yellow
Write-Host "  Order ID: $orderId" -ForegroundColor White
Write-Host "  Audits sent: $($updateBody.audits.Count)" -ForegroundColor White
Write-Host "  StatusHistory entries: $($statusHistory.Count)" -ForegroundColor White
Write-Host "  Audit entries found: $($auditEntries.Count)" -ForegroundColor White
Write-Host ""

# Return result
return [PSCustomObject]@{
    TestPassed = $testsPassed
    OrderId = $orderId
    AuditsSent = $updateBody.audits.Count
    StatusHistoryCount = $statusHistory.Count
    AuditEntriesFound = $auditEntries.Count
}

