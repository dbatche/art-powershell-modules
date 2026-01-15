# List all environments and their DOMAIN/AP_INVOICE_ID values
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`n📋 Listing environments and their variables..." -ForegroundColor Cyan

$envs = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers).environments

Write-Host "`nFound $($envs.Count) environments" -ForegroundColor Yellow
Write-Host ""

foreach ($env in $envs) {
    try {
        $fullEnv = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments/$($env.uid)" -Headers $headers).environment
        
        $domainVar = $fullEnv.values | Where-Object { $_.key -eq "DOMAIN" }
        $apInvoiceIdVar = $fullEnv.values | Where-Object { $_.key -eq "AP_INVOICE_ID" }
        $istaIdVar = $fullEnv.values | Where-Object { $_.key -eq "istaId" }
        
        if ($domainVar -or $apInvoiceIdVar -or $istaIdVar) {
            Write-Host "Environment: $($env.name)" -ForegroundColor Cyan
            Write-Host "  UID: $($env.uid)" -ForegroundColor Gray
            
            if ($domainVar) {
                Write-Host "  DOMAIN: $($domainVar.value)" -ForegroundColor White
            }
            if ($apInvoiceIdVar) {
                Write-Host "  AP_INVOICE_ID: $($apInvoiceIdVar.value)" -ForegroundColor White
            }
            if ($istaIdVar) {
                Write-Host "  istaId: $($istaIdVar.value)" -ForegroundColor White
            }
            Write-Host ""
        }
    } catch {
        Write-Host "  Error fetching $($env.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "`nTo test manually, provide the values:" -ForegroundColor Yellow
Write-Host "  .\Test-IstaEndpoint.ps1 -Domain 'https://your-api.com' -ApInvoiceId '123' -IstaId '2'" -ForegroundColor White
Write-Host ""
