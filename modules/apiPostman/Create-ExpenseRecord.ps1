# Create an expense record for apInvoice 2
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

Write-Host "`n📝 Creating expense record for invoice $InvoiceId..." -ForegroundColor Cyan
Write-Host ""

# Create the expense record payload (as array)
$expenseRecord = @'
[
    {
        "expenseGlAccount": "00-5000",
        "expenseQuantity": 121
    }
]
'@

Write-Host "Request body:" -ForegroundColor Yellow
$expenseRecord | Write-Host -ForegroundColor White
Write-Host ""

$postUrl = "$Domain/apInvoices/$InvoiceId/expenses"
Write-Host "POST URL: $postUrl" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $postUrl -Method Post -Headers $headers -Body $expenseRecord
    
    Write-Host "✅ SUCCESS! expense record created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
    
    if ($response.expenses) {
        $expense = $response.expenses[0]
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "✅ CREATED EXPENSE RECORD:" -ForegroundColor Green
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host "apInvoiceId: $InvoiceId" -ForegroundColor White
        Write-Host "expenseId: $($expense.expenseId)" -ForegroundColor White
        Write-Host "expenseGlAccount: $($expense.expenseGlAccount)" -ForegroundColor White
        Write-Host "expenseQuantity: $($expense.expenseQuantity)" -ForegroundColor White
        Write-Host "=" * 80 -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 You can now use these values in your tests:" -ForegroundColor Yellow
        Write-Host "   AP_INVOICE_ID = $InvoiceId" -ForegroundColor Cyan
        Write-Host "   expenseId = $($expense.expenseId)" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Verify by fetching it back
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "VERIFICATION: Fetching the record back..." -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    $verifyUrl = "$Domain/apInvoices/$InvoiceId/expenses"
    $verifyResponse = Invoke-RestMethod -Uri $verifyUrl -Method Get -Headers $headers
    
    if ($verifyResponse.expenses -and $verifyResponse.expenses.Count -gt 0) {
        Write-Host "✅ Verified! Invoice $InvoiceId now has $($verifyResponse.expenses.Count) expense record(s)" -ForegroundColor Green
        Write-Host ""
        $verifyResponse.expenses | ForEach-Object {
            Write-Host "  • expenseId: $($_.expenseId), GL Account: $($_.expenseGlAccount), Qty: $($_.expenseQuantity)" -ForegroundColor White
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
}

Write-Host ""
