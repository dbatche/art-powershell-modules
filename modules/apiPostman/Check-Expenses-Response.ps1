# Check the structure of the expenses API response
param(
    [string]$Domain = "https://tde-truckmate.tmwcloud.com/fin/finance",
    [string]$ApiKey = "9ade1b0487df4d67dcdc501eaa317b91"
)

$headers = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $ApiKey"
}

Write-Host "`n🔍 Checking expenses API response structure..." -ForegroundColor Cyan
Write-Host ""

$url = "$Domain/apInvoices/2/expenses"
Write-Host "URL: $url" -ForegroundColor Gray
Write-Host ""

$response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "FULL RESPONSE" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
$response | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "TOP-LEVEL PROPERTIES" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$response.PSObject.Properties | ForEach-Object {
    Write-Host "  • $($_.Name): $($_.Value)" -ForegroundColor White
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "CHECKING FOR PAGINATION FIELDS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""

# Check for expected pagination fields
$paginationFields = @("totalItems", "pageIndex", "pageSize", "offset", "limit", "count")

foreach ($field in $paginationFields) {
    if ($response.PSObject.Properties.Name -contains $field) {
        Write-Host "  ✅ $field : $($response.$field)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $field : NOT FOUND" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "ANALYSIS" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

if ($response.totalItems) {
    Write-Host "✅ Response HAS 'totalItems' field" -ForegroundColor Green
} else {
    Write-Host "❌ Response MISSING 'totalItems' field" -ForegroundColor Red
    Write-Host "   This is why the test 'response includes totalItems field' is failing!" -ForegroundColor Yellow
}

if ($response.pageIndex -ne $null) {
    Write-Host "✅ Response HAS 'pageIndex' field: $($response.pageIndex)" -ForegroundColor Green
    
    if ($response.pageIndex -eq 0) {
        Write-Host "   ✅ pageIndex IS 0" -ForegroundColor Green
    } else {
        Write-Host "   ❌ pageIndex is NOT 0 (actual: $($response.pageIndex))" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Response MISSING 'pageIndex' field" -ForegroundColor Red
    Write-Host "   This is why the test 'pageIndex eq 0' is failing!" -ForegroundColor Yellow
}

Write-Host ""
