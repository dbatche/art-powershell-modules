# Test if we can get invoice count and pagination info
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

Write-Host "`n🔍 Testing invoice count and pagination..." -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

# Test 1: Check if $count parameter is supported
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 1: Using `$count=true parameter" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query1 = "$Domain/apInvoices?`$count=true&`$top=1"
Write-Host "URL: $query1" -ForegroundColor Gray
Write-Host ""

try {
    $response1 = Invoke-RestMethod -Uri $query1 -Method Get -Headers $headers
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response structure:" -ForegroundColor Cyan
    
    # Check for OData count
    if ($response1.'@odata.count') {
        Write-Host "  Total invoices: $($response1.'@odata.count')" -ForegroundColor Green
    } elseif ($response1.count) {
        Write-Host "  Total invoices: $($response1.count)" -ForegroundColor Green
    } elseif ($response1.'@count') {
        Write-Host "  Total invoices: $($response1.'@count')" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No count field found in response" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Available properties:" -ForegroundColor Gray
        $response1.PSObject.Properties | ForEach-Object {
            Write-Host "    • $($_.Name): $($_.Value)" -ForegroundColor DarkGray
        }
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Try just $count endpoint
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 2: Using `$count endpoint directly" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query2 = "$Domain/apInvoices/`$count"
Write-Host "URL: $query2" -ForegroundColor Gray
Write-Host ""

try {
    $response2 = Invoke-RestMethod -Uri $query2 -Method Get -Headers $headers
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Total invoices: $response2" -ForegroundColor White
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check pagination info (nextLink)
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 3: Check pagination info" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query3 = "$Domain/apInvoices?`$top=10"
Write-Host "URL: $query3" -ForegroundColor Gray
Write-Host ""

try {
    $response3 = Invoke-RestMethod -Uri $query3 -Method Get -Headers $headers
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Returned $($response3.apInvoices.Count) invoices" -ForegroundColor Cyan
    
    if ($response3.'@odata.nextLink') {
        Write-Host "  nextLink: $($response3.'@odata.nextLink')" -ForegroundColor Green
    } elseif ($response3.nextLink) {
        Write-Host "  nextLink: $($response3.nextLink)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ No nextLink found (might mean < 10 total records or pagination not supported)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "All response properties:" -ForegroundColor Gray
    $response3.PSObject.Properties | Where-Object { $_.Name -ne 'apInvoices' } | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.Value)" -ForegroundColor DarkGray
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Strategy - Get max ID from recent invoices
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 4: Alternative - Find max apInvoiceId" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query4 = "$Domain/apInvoices?`$top=100&`$select=apInvoiceId&`$orderby=apInvoiceId desc"
Write-Host "URL: $query4" -ForegroundColor Gray
Write-Host ""

try {
    $response4 = Invoke-RestMethod -Uri $query4 -Method Get -Headers $headers
    
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    
    if ($response4.apInvoices -and $response4.apInvoices.Count -gt 0) {
        $maxId = ($response4.apInvoices | Measure-Object -Property apInvoiceId -Maximum).Maximum
        $minId = ($response4.apInvoices | Measure-Object -Property apInvoiceId -Minimum).Minimum
        
        Write-Host "  Max invoice ID (from top 100): $maxId" -ForegroundColor Green
        Write-Host "  Min invoice ID (from top 100): $minId" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Range: $minId to $maxId" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  💡 Strategy: Sample random IDs between $minId and $maxId to find invoices with ista" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host ""
