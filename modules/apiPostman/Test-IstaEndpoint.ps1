# Test the ista endpoint to see what's actually there
param(
    [string]$Domain = "",
    [string]$ApInvoiceId = "",
    [string]$IstaId = "2"
)

Write-Host "`n🔍 Testing ista endpoint..." -ForegroundColor Cyan

# First, let's get the environment/collection variables
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

# Get environments to find DOMAIN and AP_INVOICE_ID
Write-Host "`nFetching environments for variables..." -ForegroundColor Yellow

try {
    $envs = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers).environments
    
    # Look for common environment names
    $testEnv = $envs | Where-Object { $_.name -like "*test*" -or $_.name -like "*QA*" -or $_.name -like "*Backup*" } | Select-Object -First 1
    
    if ($testEnv) {
        Write-Host "Using environment: $($testEnv.name)" -ForegroundColor Green
        
        $fullEnv = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments/$($testEnv.uid)" -Headers $headers).environment
        
        $domainVar = $fullEnv.values | Where-Object { $_.key -eq "DOMAIN" }
        $apInvoiceIdVar = $fullEnv.values | Where-Object { $_.key -eq "AP_INVOICE_ID" }
        
        if ($domainVar -and -not $Domain) {
            $Domain = $domainVar.value
            Write-Host "  DOMAIN: $Domain" -ForegroundColor Gray
        }
        
        if ($apInvoiceIdVar -and -not $ApInvoiceId) {
            $ApInvoiceId = $apInvoiceIdVar.value
            Write-Host "  AP_INVOICE_ID: $ApInvoiceId" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "Could not fetch environments: $($_.Exception.Message)" -ForegroundColor Yellow
}

# If still not set, prompt
if (-not $Domain) {
    $Domain = Read-Host "Enter DOMAIN (e.g., https://api.example.com)"
}

if (-not $ApInvoiceId) {
    $ApInvoiceId = Read-Host "Enter AP_INVOICE_ID"
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "Testing Endpoints:" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

# Test 1: Get the parent AP Invoice to see if it exists
Write-Host "`n1️⃣ Testing parent apInvoice..." -ForegroundColor Cyan
$apInvoiceUrl = "$Domain/apInvoices/$ApInvoiceId"
Write-Host "   URL: $apInvoiceUrl" -ForegroundColor Gray

try {
    $apInvoiceResponse = Invoke-RestMethod -Uri $apInvoiceUrl -Method Get -Headers @{ "Accept" = "application/json" }
    Write-Host "   ✅ AP Invoice exists!" -ForegroundColor Green
    Write-Host "   Response preview:" -ForegroundColor Gray
    $apInvoiceResponse | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
} catch {
    Write-Host "   ❌ AP Invoice NOT found!" -ForegroundColor Red
    Write-Host "   Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   This is likely your problem - the parent invoice doesn't exist anymore!" -ForegroundColor Yellow
    exit 1
}

# Test 2: Get all ista records for this invoice
Write-Host "`n2️⃣ Testing ista collection..." -ForegroundColor Cyan
$istaCollectionUrl = "$Domain/apInvoices/$ApInvoiceId/ista"
Write-Host "   URL: $istaCollectionUrl" -ForegroundColor Gray

try {
    $istaCollectionResponse = Invoke-RestMethod -Uri $istaCollectionUrl -Method Get -Headers @{ "Accept" = "application/json" }
    Write-Host "   ✅ ista collection accessible!" -ForegroundColor Green
    
    if ($istaCollectionResponse.ista) {
        Write-Host "   Found $($istaCollectionResponse.ista.Count) ista record(s):" -ForegroundColor Green
        $istaCollectionResponse.ista | ForEach-Object {
            Write-Host "     • istaId: $($_.istaId)" -ForegroundColor White
        }
        
        # Check if istaId 2 exists
        $ista2 = $istaCollectionResponse.ista | Where-Object { $_.istaId -eq 2 }
        if ($ista2) {
            Write-Host "   ✅ istaId 2 EXISTS in the collection" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ istaId 2 NOT FOUND in the collection!" -ForegroundColor Yellow
            Write-Host "   Available istaIds: $($istaCollectionResponse.ista.istaId -join ', ')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ⚠️ No ista records found (empty collection)" -ForegroundColor Yellow
        Write-Host "   Response structure:" -ForegroundColor Gray
        $istaCollectionResponse | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White
    }
} catch {
    Write-Host "   ❌ Cannot access ista collection!" -ForegroundColor Red
    Write-Host "   Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Get specific ista record (istaId 2)
Write-Host "`n3️⃣ Testing specific istaId: $IstaId..." -ForegroundColor Cyan
$istaUrl = "$Domain/apInvoices/$ApInvoiceId/ista/$IstaId"
Write-Host "   URL: $istaUrl" -ForegroundColor Gray

try {
    $istaResponse = Invoke-RestMethod -Uri $istaUrl -Method Get -Headers @{ "Accept" = "application/json" }
    Write-Host "   ✅ istaId $IstaId exists!" -ForegroundColor Green
    Write-Host "   Full Response:" -ForegroundColor Gray
    $istaResponse | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White
    
    # Check the structure
    Write-Host "`n   Response Structure Analysis:" -ForegroundColor Cyan
    if ($istaResponse.istaId) {
        Write-Host "     ✅ $.istaId exists: $($istaResponse.istaId)" -ForegroundColor Green
    } else {
        Write-Host "     ❌ $.istaId NOT FOUND at root level!" -ForegroundColor Red
        Write-Host "     Available properties:" -ForegroundColor Yellow
        $istaResponse.PSObject.Properties | ForEach-Object {
            Write-Host "       • $($_.Name): $($_.Value)" -ForegroundColor White
        }
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "   ❌ istaId $IstaId NOT found!" -ForegroundColor Red
    Write-Host "   Status: $statusCode" -ForegroundColor Red
    
    if ($statusCode -eq 404) {
        Write-Host ""
        Write-Host "   🎯 ROOT CAUSE IDENTIFIED:" -ForegroundColor Yellow
        Write-Host "   The test is trying to validate istaId=2, but it doesn't exist!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   SOLUTIONS:" -ForegroundColor Green
        Write-Host "   1. Update the test to use a valid istaId" -ForegroundColor White
        Write-Host "   2. Create an ista record with istaId=2" -ForegroundColor White
        Write-Host "   3. Skip validation when the record doesn't exist" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""
