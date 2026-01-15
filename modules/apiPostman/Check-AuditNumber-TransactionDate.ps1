# Check for invoices with non-null auditNumber or transactionDate
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

Write-Host "`n🔍 Searching for invoices with non-null auditNumber or transactionDate..." -ForegroundColor Cyan
Write-Host ""

# Fetch a large sample with only the fields we need
$query = "$Domain/apInvoices?`$select=apInvoiceId,auditNumber,transactionDate&`$top=200"
Write-Host "Fetching 200 invoices..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $query -Method Get -Headers $headers
    
    Write-Host "✅ Fetched $($response.apInvoices.Count) invoices" -ForegroundColor Green
    Write-Host ""
    
    # Find invoices with non-null values
    $withAuditNumber = $response.apInvoices | Where-Object { 
        $_.auditNumber -and $_.auditNumber -ne "" -and $_.auditNumber -ne "null" 
    }
    
    $withTransactionDate = $response.apInvoices | Where-Object { 
        $_.transactionDate -and $_.transactionDate -ne "" -and $_.transactionDate -ne "null" 
    }
    
    # Results for auditNumber
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "AUDIT NUMBER RESULTS" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    if ($withAuditNumber.Count -gt 0) {
        Write-Host "✅ Found $($withAuditNumber.Count) invoice(s) with non-null auditNumber" -ForegroundColor Green
        Write-Host ""
        $withAuditNumber | Select-Object -First 10 | ForEach-Object {
            Write-Host "  Invoice $($_.apInvoiceId): auditNumber = '$($_.auditNumber)'" -ForegroundColor White
        }
    } else {
        Write-Host "❌ No invoices with non-null auditNumber found" -ForegroundColor Red
    }
    
    # Results for transactionDate
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "TRANSACTION DATE RESULTS" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    if ($withTransactionDate.Count -gt 0) {
        Write-Host "✅ Found $($withTransactionDate.Count) invoice(s) with non-null transactionDate" -ForegroundColor Green
        Write-Host ""
        $withTransactionDate | Select-Object -First 10 | ForEach-Object {
            Write-Host "  Invoice $($_.apInvoiceId): transactionDate = '$($_.transactionDate)'" -ForegroundColor White
        }
    } else {
        Write-Host "❌ No invoices with non-null transactionDate found" -ForegroundColor Red
    }
    
    # Sample data structure
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Gray
    Write-Host "SAMPLE DATA (first invoice)" -ForegroundColor Gray
    Write-Host "=" * 80 -ForegroundColor Gray
    Write-Host ""
    $response.apInvoices[0] | ConvertTo-Json | Write-Host -ForegroundColor DarkGray
    
    # Summary
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total invoices checked: $($response.apInvoices.Count)" -ForegroundColor White
    Write-Host "With auditNumber: $($withAuditNumber.Count) ($([math]::Round(($withAuditNumber.Count / $response.apInvoices.Count) * 100, 1))%)" -ForegroundColor White
    Write-Host "With transactionDate: $($withTransactionDate.Count) ($([math]::Round(($withTransactionDate.Count / $response.apInvoices.Count) * 100, 1))%)" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# If we want to check more invoices
Write-Host "Would you like to check more invoices? (Checking larger samples...)" -ForegroundColor Yellow
Write-Host ""

# Check across different ID ranges
$rangesToCheck = @(1, 500, 1000, 1500)
$moreWithAudit = @()
$moreWithTransaction = @()

foreach ($startId in $rangesToCheck) {
    Write-Host "Checking around invoice ID $startId..." -ForegroundColor Gray
    
    try {
        $rangeQuery = "$Domain/apInvoices?`$select=apInvoiceId,auditNumber,transactionDate&`$filter=apInvoiceId ge $startId&`$top=50"
        $rangeResponse = Invoke-RestMethod -Uri $rangeQuery -Method Get -Headers $headers
        
        $rangeWithAudit = $rangeResponse.apInvoices | Where-Object { 
            $_.auditNumber -and $_.auditNumber -ne "" -and $_.auditNumber -ne "null" 
        }
        
        $rangeWithTransaction = $rangeResponse.apInvoices | Where-Object { 
            $_.transactionDate -and $_.transactionDate -ne "" -and $_.transactionDate -ne "null" 
        }
        
        if ($rangeWithAudit.Count -gt 0) {
            Write-Host "  ✅ Found $($rangeWithAudit.Count) with auditNumber" -ForegroundColor Green
            $moreWithAudit += $rangeWithAudit
        }
        
        if ($rangeWithTransaction.Count -gt 0) {
            Write-Host "  ✅ Found $($rangeWithTransaction.Count) with transactionDate" -ForegroundColor Green
            $moreWithTransaction += $rangeWithTransaction
        }
        
    } catch {
        Write-Host "  ✗ Error checking range" -ForegroundColor Red
    }
}

if ($moreWithAudit.Count -gt 0 -or $moreWithTransaction.Count -gt 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "EXTENDED SEARCH RESULTS" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    
    if ($moreWithAudit.Count -gt 0) {
        Write-Host ""
        Write-Host "Additional invoices with auditNumber:" -ForegroundColor Yellow
        $moreWithAudit | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Invoice $($_.apInvoiceId): '$($_.auditNumber)'" -ForegroundColor White
        }
    }
    
    if ($moreWithTransaction.Count -gt 0) {
        Write-Host ""
        Write-Host "Additional invoices with transactionDate:" -ForegroundColor Yellow
        $moreWithTransaction | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Invoice $($_.apInvoiceId): '$($_.transactionDate)'" -ForegroundColor White
        }
    }
}

Write-Host ""
