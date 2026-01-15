# Check invoice 2 for various sub-resources
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91",
    [int]$InvoiceId = 2
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

Write-Host "`n🔍 Checking sub-resources for invoice $InvoiceId..." -ForegroundColor Cyan
Write-Host ""

# List of sub-resources to check
$subResources = @("ista", "expenses", "apDriverDeductions")

foreach ($subResource in $subResources) {
    $url = "$Domain/apInvoices/$InvoiceId/$subResource"
    
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "Checking: $subResource" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "URL: $url" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
        
        # Check if the response has the sub-resource as a property
        if ($response.$subResource) {
            $count = $response.$subResource.Count
            Write-Host "✅ SUCCESS - Found $count record(s)" -ForegroundColor Green
            Write-Host ""
            
            if ($count -gt 0) {
                Write-Host "Records:" -ForegroundColor Cyan
                $response.$subResource | Select-Object -First 3 | ForEach-Object {
                    Write-Host "  $($_ | ConvertTo-Json -Compress)" -ForegroundColor White
                }
                
                if ($count > 3) {
                    Write-Host "  ... and $($count - 3) more" -ForegroundColor Gray
                }
            } else {
                Write-Host "Empty collection (no records)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ Response doesn't contain expected '$subResource' property" -ForegroundColor Yellow
            Write-Host "Response structure:" -ForegroundColor Gray
            $response | ConvertTo-Json -Depth 2 | Write-Host -ForegroundColor DarkGray
        }
        
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        
        if ($statusCode -eq 404) {
            Write-Host "❌ NOT FOUND (404) - Endpoint doesn't exist or no access" -ForegroundColor Red
        } else {
            Write-Host "❌ FAILED - Status: $statusCode" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SUMMARY for Invoice $InvoiceId" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

foreach ($subResource in $subResources) {
    $url = "$Domain/apInvoices/$InvoiceId/$subResource"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        
        if ($response.$subResource) {
            $count = $response.$subResource.Count
            if ($count -gt 0) {
                Write-Host "✅ $subResource : $count record(s)" -ForegroundColor Green
            } else {
                Write-Host "⚪ $subResource : 0 records (empty)" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "❌ $subResource : Not available" -ForegroundColor Red
    }
}

Write-Host ""
