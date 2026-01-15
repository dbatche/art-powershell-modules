# Test OData query to find invoices with ista records
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

Write-Host "`n🔍 Testing OData query for invoices with ista..." -ForegroundColor Cyan
Write-Host ""

# Set up headers with Bearer token
$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

# Test 1: Try the any() filter
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 1: Using `$filter=ista/any()" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query1 = "$Domain/apInvoices?`$expand=ista&`$filter=ista/any()&`$top=1&`$select=apInvoiceId"
Write-Host "URL: $query1" -ForegroundColor Gray
Write-Host ""

try {
    $response1 = Invoke-RestMethod -Uri $query1 -Method Get -Headers $headers
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    $response1 | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
    
    if ($response1.apInvoices -and $response1.apInvoices.Count -gt 0) {
        $invoice = $response1.apInvoices[0]
        Write-Host ""
        Write-Host "Found Invoice:" -ForegroundColor Green
        Write-Host "  apInvoiceId: $($invoice.apInvoiceId)" -ForegroundColor White
        if ($invoice.ista) {
            Write-Host "  ista records: $($invoice.ista.Count)" -ForegroundColor White
            $invoice.ista | ForEach-Object {
                Write-Host "    • istaId: $($_.istaId)" -ForegroundColor Cyan
            }
        }
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*any()*" -or $_.Exception.Message -like "*filter*") {
        Write-Host ""
        Write-Host "⚠️ The any() function might not be supported" -ForegroundColor Yellow
        Write-Host "Trying alternative approach..." -ForegroundColor Yellow
    }
}

# Test 2: Alternative - expand and let Postman filter
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 2: Using `$expand=ista without filter (let client filter)" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query2 = "$Domain/apInvoices?`$expand=ista&`$top=10&`$select=apInvoiceId"
Write-Host "URL: $query2" -ForegroundColor Gray
Write-Host ""

try {
    $response2 = Invoke-RestMethod -Uri $query2 -Method Get -Headers $headers
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host ""
    
    if ($response2.apInvoices) {
        Write-Host "Found $($response2.apInvoices.Count) invoices (top 10)" -ForegroundColor Cyan
        
        # Find invoices with ista records
        $invoicesWithIsta = $response2.apInvoices | Where-Object { $_.ista -and $_.ista.Count -gt 0 }
        
        if ($invoicesWithIsta) {
            Write-Host "Invoices with ista records: $($invoicesWithIsta.Count)" -ForegroundColor Green
            Write-Host ""
            
            $invoicesWithIsta | Select-Object -First 3 | ForEach-Object {
                Write-Host "  Invoice: $($_.apInvoiceId)" -ForegroundColor White
                Write-Host "    ista count: $($_.ista.Count)" -ForegroundColor Gray
                $_.ista | Select-Object -First 2 | ForEach-Object {
                    Write-Host "      • istaId: $($_.istaId)" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Host "⚠️ No invoices with ista records found in first 10 results" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Just get ista collection directly
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 3: Query /apInvoices/{id}/ista directly" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$testInvoiceId = 2  # Try a few common IDs
$foundWorking = $false

foreach ($id in 2, 5, 10, 1, 3) {
    $query3 = "$Domain/apInvoices/$id/ista?`$top=1"
    Write-Host "Trying: $query3" -ForegroundColor Gray
    
    try {
        $response3 = Invoke-RestMethod -Uri $query3 -Method Get -Headers $headers
        
        if ($response3.ista -and $response3.ista.Count -gt 0) {
            Write-Host "  ✅ Found ista records!" -ForegroundColor Green
            Write-Host "    apInvoiceId: $id" -ForegroundColor White
            Write-Host "    istaId: $($response3.ista[0].istaId)" -ForegroundColor Cyan
            $foundWorking = $true
            break
        } else {
            Write-Host "  ⚠️ No ista records" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ Invoice $id not found or no access" -ForegroundColor Red
    }
}

if (-not $foundWorking) {
    Write-Host ""
    Write-Host "⚠️ Could not find any working invoice with ista records" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host ""
