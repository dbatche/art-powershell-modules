# Extract method names from TMS API Utils library
Write-Host "`n📚 Extracting TMS API Utils methods..." -ForegroundColor Cyan
Write-Host ""

# Download the JavaScript properly
$url = "https://tms-api-utils.tmwcloud.com/"
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$jsContent = $response.Content

# Save it properly
$jsContent | Out-File "postmanAPI/tms-api-utils.js" -Encoding utf8 -NoNewline
Write-Host "✓ Downloaded and saved JavaScript ($($jsContent.Length) chars)" -ForegroundColor Green
Write-Host ""

# Search for method assignment patterns
# Pattern: something.methodName = function
$pattern1 = '\.(\w+)\s*=\s*function'
$matches1 = [regex]::Matches($jsContent, $pattern1)

Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "METHOD ASSIGNMENTS (pattern: .methodName = function)" -ForegroundColor Yellow  
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""

$allMethods = @{}
foreach ($match in $matches1) {
    $methodName = $match.Groups[1].Value
    if ($methodName.Length -gt 3) {  # Filter out single letters
        if (-not $allMethods.ContainsKey($methodName)) {
            $allMethods[$methodName] = 0
        }
        $allMethods[$methodName]++
    }
}

# Filter to likely public method names
$publicMethods = $allMethods.Keys | Where-Object {
    $_ -match '^(validate|test|perform|get|set|delete|confirm|create|update|check|generate|extract)' -or
    $_ -match '(Pagination|Schema|Response|Code|Field|Parameter|Value|Property|Error)$'
} | Sort-Object

Write-Host "Found $($publicMethods.Count) potential public methods:" -ForegroundColor Cyan
Write-Host ""

foreach ($method in $publicMethods) {
    Write-Host "  • $method (found $($allMethods[$method]) time(s))" -ForegroundColor White
}

# Specifically search for our known methods
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host "SEARCHING FOR KNOWN METHODS" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Yellow
Write-Host ""

$knownMethods = @(
    "validatePagination",
    "validateJsonSchema",
    "validateJsonSchemaIfCode",
    "validateSelectParameter",
    "validateExpandParameter",
    "validateFieldValuesIfCode",
    "testStatusCode",
    "testInvalidBusinessLogicResponse",
    "testInvalidDBValueResponse",
    "testErrorCode",
    "testMissingRequiredFieldResponse",
    "performFilterAssertion"
)

foreach ($method in $knownMethods) {
    $escap = [regex]::Escape($method)
    if ($jsContent -match $escap) {
        $count = ([regex]::Matches($jsContent, $escap)).Count
        Write-Host "  ✓ $method (found $count time(s))" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $method (not found)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "💡 Recommendation: Check the source repository or documentation for complete API list" -ForegroundColor Yellow
Write-Host ""
