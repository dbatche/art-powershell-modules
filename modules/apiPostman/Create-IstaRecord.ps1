# Create an ista record for apInvoice 2
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91",
    [int]$InvoiceId = 2
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
    "Content-Type" = "application/json"
}

Write-Host "`n📝 Creating ista record for invoice $InvoiceId..." -ForegroundColor Cyan
Write-Host ""

# Create the ista record payload (must be an array)
$istaRecord = @(
    @{
        istaCode = "ISTA1"
        istaReference = ""
        istaProvince = ""
        partsAmount = 0
        laborAmount = 0
        otherAmount = 0
        equipmentId = ""
        powerUnitId = ""
        trailerId = ""
    }
) | ConvertTo-Json -AsArray

Write-Host "Request body:" -ForegroundColor Yellow
$istaRecord | Write-Host -ForegroundColor White
Write-Host ""

$postUrl = "$Domain/apInvoices/$InvoiceId/ista"
Write-Host "POST URL: $postUrl" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $postUrl -Method Post -Headers $headers -Body $istaRecord
    
    Write-Host "✅ SUCCESS! ista record created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
    
    if ($response.istaId) {
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "✅ CREATED ista RECORD:" -ForegroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "apInvoiceId: $InvoiceId" -ForegroundColor White
        Write-Host "istaId: $($response.istaId)" -ForegroundColor White
        Write-Host "istaCode: $($response.istaCode)" -ForegroundColor White
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 You can now use these values in your tests:" -ForegroundColor Yellow
        Write-Host "   AP_INVOICE_ID = $InvoiceId" -ForegroundColor Cyan
        Write-Host "   istaId = $($response.istaId)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Verify by fetching it back
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "VERIFICATION: Fetching the record back..." -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    $verifyUrl = "$Domain/apInvoices/$InvoiceId/ista"
    $verifyResponse = Invoke-RestMethod -Uri $verifyUrl -Method Get -Headers $headers
    
    if ($verifyResponse.ista -and $verifyResponse.ista.Count -gt 0) {
        Write-Host "✅ Verified! Invoice $InvoiceId now has $($verifyResponse.ista.Count) ista record(s)" -ForegroundColor Green
        Write-Host ""
        $verifyResponse.ista | ForEach-Object {
            Write-Host "  • istaId: $($_.istaId), istaCode: $($_.istaCode)" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.ErrorDetails.Message) {
        Write-Host ""
        Write-Host "Details:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message -ForegroundColor White
    }
    
    # Check if the invoice exists first
    Write-Host ""
    Write-Host "Checking if invoice $InvoiceId exists..." -ForegroundColor Yellow
    
    try {
        $invoiceCheck = Invoke-RestMethod -Uri "$Domain/apInvoices/$InvoiceId" -Method Get -Headers $headers
        Write-Host "✓ Invoice $InvoiceId exists" -ForegroundColor Green
    } catch {
        Write-Host "✗ Invoice $InvoiceId does NOT exist" -ForegroundColor Red
        Write-Host "  Try creating an ista record on invoice 100 instead (known to exist)" -ForegroundColor Yellow
    }
}

Write-Host ""
