# Catalog methods from tms-api-utils JavaScript library
param(
    [string]$Url = "https://tms-api-utils.tmwcloud.com/"
)

Write-Host "`n📚 Cataloging TMS API Utils methods..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Fetching JavaScript from: $Url" -ForegroundColor Gray
Write-Host ""

try {
    # Download the JavaScript content
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    $jsContent = $response.Content
    
    Write-Host "✓ Downloaded $($jsContent.Length) characters" -ForegroundColor Green
    Write-Host ""
    
    # Pattern 1: Look for l.methodName=function or tm_utils.methodName=function
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "SEARCHING FOR METHOD DEFINITIONS" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    # Find utils methods (pattern: l.methodName=function)
    $utilsPattern = 'l\.(\w+)=function'
    $utilsMatches = [regex]::Matches($jsContent, $utilsPattern)
    $utilsMethods = $utilsMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    
    Write-Host "Utils Methods (l.*):" -ForegroundColor Cyan
    if ($utilsMethods.Count -gt 0) {
        $utilsMethods | ForEach-Object {
            Write-Host "  • utils.$_" -ForegroundColor White
        }
    } else {
        Write-Host "  (none found with this pattern)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Find tm_utils methods (pattern: various possibilities)
    $tmUtilsPattern1 = 'tm_utils\.(\w+)=function'
    $tmUtilsPattern2 = '"tm_utils",\s*"(\w+)"'
    $tmUtilsPattern3 = 'tm_utils\["(\w+)"\]'
    
    $tmUtilsMatches1 = [regex]::Matches($jsContent, $tmUtilsPattern1)
    $tmUtilsMethods = $tmUtilsMatches1 | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    
    Write-Host "TM_Utils Methods:" -ForegroundColor Cyan
    if ($tmUtilsMethods.Count -gt 0) {
        $tmUtilsMethods | ForEach-Object {
            Write-Host "  • tm_utils.$_" -ForegroundColor White
        }
    } else {
        Write-Host "  (none found with this pattern)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "ALTERNATIVE SEARCH - LOOKING FOR KNOWN METHODS" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    # Search for known method names we've seen in the collection
    $knownUtilsMethods = @(
        "testStatusCode",
        "validateJsonSchema",
        "validateJsonSchemaIfCode",
        "validatePagination",
        "validateSelectParameter",
        "validateExpandParameter",
        "validateFieldValuesIfCode",
        "performFilterAssertion",
        "getRandomProperties",
        "deleteCheckId",
        "confirmResourceDeleted"
    )
    
    $knownTmUtilsMethods = @(
        "testInvalidBusinessLogicResponse",
        "testInvalidDBValueResponse",
        "testErrorCode",
        "testStatusCode",
        "testMissingRequiredFieldResponse",
        "validatePagination"
    )
    
    Write-Host "Known utils methods (checking presence):" -ForegroundColor Cyan
    foreach ($method in $knownUtilsMethods) {
        $pattern = "(\w+\.$method|$method\s*[:=]\s*function|['\`"]$method['\`"])"
        if ($jsContent -match $pattern) {
            Write-Host "  ✓ utils.$method" -ForegroundColor Green
        } else {
            Write-Host "  ? utils.$method (not found)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Known tm_utils methods (checking presence):" -ForegroundColor Cyan
    foreach ($method in $knownTmUtilsMethods) {
        $pattern = "(tm_utils\.$method|$method\s*[:=]\s*function|['\`"]$method['\`"])"
        if ($jsContent -match $pattern) {
            Write-Host "  ✓ tm_utils.$method" -ForegroundColor Green
        } else {
            Write-Host "  ? tm_utils.$method (not found)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "SEARCHING FOR 'validatePagination' SPECIFICALLY" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    # Find all occurrences of validatePagination
    $validatePaginationPattern = '(\w+)\.validatePagination'
    $validatePaginationMatches = [regex]::Matches($jsContent, $validatePaginationPattern)
    
    if ($validatePaginationMatches.Count -gt 0) {
        Write-Host "Found validatePagination references:" -ForegroundColor Cyan
        $validatePaginationMatches | ForEach-Object {
            $obj = $_.Groups[1].Value
            Write-Host "  • $obj.validatePagination" -ForegroundColor White
        } | Select-Object -Unique
    } else {
        Write-Host "No validatePagination references found" -ForegroundColor Yellow
    }
    
    # Check for the actual function definition
    Write-Host ""
    Write-Host "Searching for validatePagination function definition..." -ForegroundColor Cyan
    
    $funcDefPattern = 'validatePagination\s*[:=]\s*function'
    if ($jsContent -match $funcDefPattern) {
        Write-Host "✓ Found function definition for validatePagination" -ForegroundColor Green
        
        # Try to extract some context
        $context = [regex]::Match($jsContent, "(.{50})validatePagination\s*[:=]\s*function(.{200})")
        if ($context.Success) {
            Write-Host ""
            Write-Host "Context snippet:" -ForegroundColor Gray
            Write-Host $context.Value -ForegroundColor DarkGray
        }
    } else {
        Write-Host "✗ Function definition not found with this pattern" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "JavaScript bundle size: $($jsContent.Length) chars" -ForegroundColor White
    Write-Host "Utils methods found: $($utilsMethods.Count)" -ForegroundColor White
    Write-Host "TM_Utils methods found: $($tmUtilsMethods.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 The code is minified/browserified, making full extraction difficult." -ForegroundColor Yellow
    Write-Host "   Consider checking if there's an un-minified version or source maps available." -ForegroundColor Yellow
    Write-Host ""
    
    # Save the JS content for manual inspection
    $outputFile = "postmanAPI/tms-api-utils-bundle.js"
    $jsContent | Out-File $outputFile -Encoding utf8
    Write-Host "📄 Saved full JavaScript bundle to: $outputFile" -ForegroundColor Cyan
    Write-Host "   You can search this file manually for method definitions" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "❌ Error fetching or parsing JavaScript:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
