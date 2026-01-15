# Extended test to find invoices with ista records
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

Write-Host "`n🔍 Extended search for invoices with ista records..." -ForegroundColor Cyan
Write-Host ""

# Set up headers with Bearer token
$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

# Test 1: Get more invoices with expand
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 1: Fetching 50 invoices with `$expand=ista" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow

$query = "$Domain/apInvoices?`$expand=ista&`$top=50"
Write-Host "URL: $query" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $query -Method Get -Headers $headers
    
    if ($response.apInvoices) {
        Write-Host "✅ Fetched $($response.apInvoices.Count) invoices" -ForegroundColor Green
        Write-Host ""
        
        # Find invoices with ista
        $withIsta = @()
        foreach ($invoice in $response.apInvoices) {
            if ($invoice.ista -and $invoice.ista.Count -gt 0) {
                $withIsta += $invoice
            }
        }
        
        if ($withIsta.Count -gt 0) {
            Write-Host "🎉 Found $($withIsta.Count) invoice(s) with ista records!" -ForegroundColor Green
            Write-Host ""
            
            # Show first 5
            $withIsta | Select-Object -First 5 | ForEach-Object {
                Write-Host "  Invoice ID: $($_.apInvoiceId)" -ForegroundColor Cyan
                Write-Host "    ista count: $($_.ista.Count)" -ForegroundColor White
                
                $_.ista | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      • istaId: $($_.istaId)" -ForegroundColor Yellow
                    
                    # Show all properties of first ista record
                    if ($_.PSObject.Properties.Count -gt 0) {
                        Write-Host "        Properties:" -ForegroundColor Gray
                        $_.PSObject.Properties | ForEach-Object {
                            Write-Host "          $($_.Name): $($_.Value)" -ForegroundColor DarkGray
                        }
                    }
                }
                Write-Host ""
            }
            
            # Recommend values
            $firstInvoice = $withIsta[0]
            $firstIsta = $firstInvoice.ista[0]
            
            Write-Host "=" * 80 -ForegroundColor Green
            Write-Host "✅ RECOMMENDED VALUES FOR YOUR TEST:" -ForegroundColor Green
            Write-Host "=" * 80 -ForegroundColor Green
            Write-Host "AP_INVOICE_ID: $($firstInvoice.apInvoiceId)" -ForegroundColor White
            Write-Host "istaId: $($firstIsta.istaId)" -ForegroundColor White
            Write-Host "=" * 80 -ForegroundColor Green
            Write-Host ""
            
        } else {
            Write-Host "⚠️ No invoices with ista records found in first 50" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Showing sample invoice structure:" -ForegroundColor Cyan
            $response.apInvoices[0] | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
        
    } else {
        Write-Host "⚠️ No invoices returned" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Try specific invoice IDs (broader range)
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "TEST 2: Checking specific invoice IDs for ista" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""

$idsToTry = @(1, 2, 3, 5, 10, 15, 20, 25, 50, 100, 200, 500, 1000)
$foundIds = @()

foreach ($id in $idsToTry) {
    Write-Host "Checking invoice $id..." -ForegroundColor Gray -NoNewline
    
    try {
        $istaResponse = Invoke-RestMethod -Uri "$Domain/apInvoices/$id/ista" -Method Get -Headers $headers
        
        if ($istaResponse.ista -and $istaResponse.ista.Count -gt 0) {
            Write-Host " ✅ Has $($istaResponse.ista.Count) ista record(s)" -ForegroundColor Green
            
            $foundIds += [PSCustomObject]@{
                ApInvoiceId = $id
                IstaCount = $istaResponse.ista.Count
                IstaIds = $istaResponse.ista.istaId -join ", "
            }
        } else {
            Write-Host " Empty" -ForegroundColor DarkGray
        }
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Host " Not found" -ForegroundColor DarkGray
        } else {
            Write-Host " Error: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        }
    }
}

if ($foundIds.Count -gt 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✅ Found $($foundIds.Count) invoices with ista:" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    $foundIds | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "⚠️ No invoices with ista found in tested IDs" -ForegroundColor Yellow
}

# Test 3: Get a specific ista record details
if ($foundIds.Count -gt 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "TEST 3: Getting detailed ista record structure" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    
    $testInvoiceId = $foundIds[0].ApInvoiceId
    $testIstaId = ($foundIds[0].IstaIds -split ", ")[0]
    
    $detailUrl = "$Domain/apInvoices/$testInvoiceId/ista/$testIstaId"
    Write-Host "URL: $detailUrl" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $detailResponse = Invoke-RestMethod -Uri $detailUrl -Method Get -Headers $headers
        
        Write-Host "✅ SUCCESS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Full ista record structure:" -ForegroundColor Cyan
        $detailResponse | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
        
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host ""
