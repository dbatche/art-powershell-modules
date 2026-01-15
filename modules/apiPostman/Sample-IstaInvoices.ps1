# Sample invoices to find how common ista records are
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

Write-Host "`n🔍 Sampling 100 invoices to find ista frequency..." -ForegroundColor Cyan
Write-Host ""

$query = "$Domain/apInvoices?`$expand=ista&`$top=100"
$response = Invoke-RestMethod -Uri $query -Method Get -Headers $headers

$withIsta = $response.apInvoices | Where-Object { $_.ista -and $_.ista.Count -gt 0 }

Write-Host "✅ Sampled 100 invoices" -ForegroundColor Green
Write-Host "   Found: $($withIsta.Count) invoices with ista records" -ForegroundColor Yellow
Write-Host "   Frequency: $([math]::Round(($withIsta.Count / 100) * 100, 1))%" -ForegroundColor Cyan
Write-Host ""

if ($withIsta.Count -gt 0) {
    Write-Host "Invoice IDs with ista (first 10):" -ForegroundColor Yellow
    $withIsta | Select-Object -First 10 | ForEach-Object {
        Write-Host "  • Invoice $($_.apInvoiceId): $($_.ista.Count) ista record(s), istaIds: $($_.ista.istaId -join ', ')" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✅ RECOMMENDED PRE-REQUEST STRATEGY:" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""
    Write-Host "With $([math]::Round(($withIsta.Count / 100) * 100, 1))% of invoices having ista records," -ForegroundColor White
    Write-Host "fetching $top=50 invoices should usually find at least one with ista." -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️ No invoices with ista found in this sample!" -ForegroundColor Yellow
    Write-Host "   Try sampling from a different offset or invoice range" -ForegroundColor Gray
}

Write-Host ""
