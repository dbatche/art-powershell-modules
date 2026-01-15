# Extract unique tm_utils function calls
$jsonPath = "postmanAPI/temp-finance-collection.json"

Write-Host "`n🔍 Searching for tm_utils function usage..." -ForegroundColor Cyan
Write-Host ""

# Read the file and find all tm_utils function calls
$content = Get-Content $jsonPath -Raw

# Extract all tm_utils.functionName patterns
$pattern = 'tm_utils\.(\w+)'
$matches = [regex]::Matches($content, $pattern)

# Get unique function names
$uniqueFunctions = $matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "UNIQUE tm_utils FUNCTIONS FOUND" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""

$uniqueFunctions | ForEach-Object {
    $functionName = $_
    $count = ($matches | Where-Object { $_.Groups[1].Value -eq $functionName }).Count
    Write-Host "  • tm_utils.$functionName" -ForegroundColor Cyan
    Write-Host "    Usage count: $count" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "=" * 80 -ForegroundColor Green
Write-Host "SUMMARY" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""
Write-Host "Total unique tm_utils functions: $($uniqueFunctions.Count)" -ForegroundColor White
Write-Host "Total tm_utils calls: $($matches.Count)" -ForegroundColor White
Write-Host ""

Write-Host "Functions list:" -ForegroundColor Yellow
$uniqueFunctions | ForEach-Object {
    Write-Host "  - tm_utils.$_" -ForegroundColor White
}

Write-Host ""
