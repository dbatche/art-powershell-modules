# Find all invoices with ista by checking ID ranges
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

Write-Host "`n🔍 Searching for ALL invoices with ista records..." -ForegroundColor Cyan
Write-Host ""

# Strategy: Check specific ID ranges
$rangesToCheck = @(
    @(1, 200),     # First 200
    @(200, 400),   # Mid range
    @(400, 600),
    @(600, 800),
    @(800, 1000),
    @(1000, 1200),
    @(1200, 1400),
    @(1400, 1571)  # Up to max
)

$foundInvoices = @()
$totalChecked = 0

foreach ($range in $rangesToCheck) {
    $start = $range[0]
    $end = $range[1]
    
    Write-Host "Checking invoice IDs $start to $end..." -ForegroundColor Yellow
    
    # Check every 10th ID in this range (sampling)
    for ($id = $start; $id -le $end; $id += 10) {
        $totalChecked++
        
        try {
            $istaResponse = Invoke-RestMethod -Uri "$Domain/apInvoices/$id/ista" -Method Get -Headers $headers -ErrorAction Stop
            
            if ($istaResponse.ista -and $istaResponse.ista.Count -gt 0) {
                Write-Host "  ✅ Invoice $id has $($istaResponse.ista.Count) ista record(s)" -ForegroundColor Green
                
                $foundInvoices += [PSCustomObject]@{
                    InvoiceId = $id
                    IstaCount = $istaResponse.ista.Count
                    IstaIds = $istaResponse.ista.istaId -join ", "
                }
            }
        } catch {
            # Silently skip 404s and other errors
        }
        
        # Progress indicator
        if (($totalChecked % 50) -eq 0) {
            Write-Host "  Checked $totalChecked IDs so far..." -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "RESULTS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""
Write-Host "Total IDs checked: $totalChecked" -ForegroundColor Cyan
Write-Host "Invoices with ista: $($foundInvoices.Count)" -ForegroundColor Green
Write-Host ""

if ($foundInvoices.Count -gt 0) {
    Write-Host "All invoices with ista records:" -ForegroundColor Green
    $foundInvoices | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✅ RECOMMENDATION:" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""
    Write-Host "Since ista records are rare, use a FALLBACK strategy:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Try to find an invoice with ista dynamically (search first 100)" -ForegroundColor White
    Write-Host "2. If not found, use known working values as fallback:" -ForegroundColor White
    Write-Host "     AP_INVOICE_ID: $($foundInvoices[0].InvoiceId)" -ForegroundColor Cyan
    Write-Host "     istaId: $(($foundInvoices[0].IstaIds -split ', ')[0])" -ForegroundColor Cyan
    Write-Host ""
    
} else {
    Write-Host "⚠️ No invoices with ista found in sampled ranges!" -ForegroundColor Yellow
}

Write-Host ""
