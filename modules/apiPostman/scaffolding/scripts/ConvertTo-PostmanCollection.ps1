# ConvertTo-PostmanCollection.ps1
# Converts PowerShell test files to Postman collection format

param(
    [Parameter(Mandatory=$true)]
    [string[]]$TestFiles,
    
    [Parameter(Mandatory=$true)]
    [string]$CollectionName,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = "{{DOMAIN}}",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "postman-collection.json"
)

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "CONVERTING POWERSHELL TESTS TO POSTMAN COLLECTION" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# Load all tests from files
$allTests = @()
foreach ($testFile in $TestFiles) {
    if (Test-Path $testFile) {
        Write-Host "Loading: $testFile" -ForegroundColor Yellow
        $tests = . $testFile
        Write-Host "  ✓ Loaded $($tests.Count) tests" -ForegroundColor Green
        $allTests += $tests
    } else {
        Write-Warning "Test file not found: $testFile"
    }
}

Write-Host ""
Write-Host "Total tests loaded: $($allTests.Count)" -ForegroundColor Cyan
Write-Host ""

# Helper: Convert PowerShell test to Postman request
function ConvertTo-PostmanRequest {
    param($Test, $BaseUrl)
    
    # Build URL
    $url = if ($Test.Url -match '^https?://') {
        $Test.Url
    } else {
        "$BaseUrl$($Test.Url)"
    }
    
    # Convert body to JSON string (must be string, not object)
    $bodyRaw = if ($null -eq $Test.Body) {
        ""
    } elseif ($Test.Body -is [string]) {
        $Test.Body
    } elseif ($Test.Body -is [array] -and $Test.Body.Count -eq 0) {
        # Empty array - convert to JSON string "[]"
        "[]"
    } else {
        # Convert to JSON string and ensure it's a string
        [string]($Test.Body | ConvertTo-Json -Depth 10 -Compress)
    }
    
    # Create test script
    $testScript = @(
        "pm.test('Status code is $($Test.ExpectedStatus)', function () {",
        "    pm.response.to.have.status($($Test.ExpectedStatus));",
        "});"
    )
    
    # Add JSON validation for success responses
    if ($Test.ExpectedStatus -ge 200 -and $Test.ExpectedStatus -lt 400) {
        $testScript += @(
            "",
            "if (pm.response.code === $($Test.ExpectedStatus)) {",
            "    pm.test('Response is valid JSON', function () {",
            "        pm.response.to.be.json;",
            "    });",
            "}"
        )
    }
    
    # Create Postman request object
    return @{
        name = $Test.Name
        request = @{
            method = $Test.Method
            header = @()
            body = @{
                mode = "raw"
                raw = $bodyRaw
                options = @{
                    raw = @{
                        language = "json"
                    }
                }
            }
            url = $url  # Just use the simple string format
        }
        event = @(
            @{
                listen = "test"
                script = @{
                    exec = $testScript
                    type = "text/javascript"
                }
            }
        )
    }
}

# Group tests by method and expected status
Write-Host "Organizing tests..." -ForegroundColor Cyan

$groupedTests = @{}

foreach ($test in $allTests) {
    $method = $test.Method
    $status = $test.ExpectedStatus
    
    # Skip non-POST/PUT methods (e.g., GET verification tests)
    if ($method -notin @('POST', 'PUT')) {
        Write-Host "  Skipping $method test: $($test.Name)" -ForegroundColor DarkGray
        continue
    }
    
    # Determine folder based on status code
    $statusFolder = if ($status -ge 200 -and $status -lt 300) {
        if ($method -eq 'POST') { "201" } else { "200" }
    } elseif ($status -eq 404) {
        "404"
    } else {
        "4xx"
    }
    
    # Skip 404 tests as requested
    if ($statusFolder -eq "404") {
        Write-Host "  Skipping 404 test: $($test.Name)" -ForegroundColor DarkGray
        continue
    }
    
    $key = "$method/$statusFolder"
    
    if (-not $groupedTests.ContainsKey($key)) {
        $groupedTests[$key] = @()
    }
    
    $groupedTests[$key] += $test
}

Write-Host ""
foreach ($key in $groupedTests.Keys | Sort-Object) {
    Write-Host "  $key`: $($groupedTests[$key].Count) tests" -ForegroundColor Gray
}
Write-Host ""

# Build collection structure
Write-Host "Building Postman collection structure..." -ForegroundColor Cyan

$collectionItems = @()

# Build POST folder
$postTests = $groupedTests.Keys | Where-Object { $_ -like "POST/*" }
if ($postTests) {
    $postFolderItems = @()
    
    foreach ($key in ($postTests | Sort-Object)) {
        $folderName = $key -replace 'POST/', ''
        $tests = $groupedTests[$key]
        
        $folderItems = @()
        foreach ($test in $tests) {
            $folderItems += ConvertTo-PostmanRequest -Test $test -BaseUrl $BaseUrl
        }
        
        $postFolderItems += @{
            name = $folderName
            item = $folderItems
        }
    }
    
    $collectionItems += @{
        name = "POST tripFuelPurchases"
        item = $postFolderItems
    }
}

# Build PUT folder
$putTests = $groupedTests.Keys | Where-Object { $_ -like "PUT/*" }
if ($putTests) {
    $putFolderItems = @()
    
    foreach ($key in ($putTests | Sort-Object)) {
        $folderName = $key -replace 'PUT/', ''
        $tests = $groupedTests[$key]
        
        $folderItems = @()
        foreach ($test in $tests) {
            $folderItems += ConvertTo-PostmanRequest -Test $test -BaseUrl $BaseUrl
        }
        
        $putFolderItems += @{
            name = $folderName
            item = $folderItems
        }
    }
    
    $collectionItems += @{
        name = "PUT tripFuelPurchases"
        item = $putFolderItems
    }
}

# Create final collection
$collection = @{
    info = @{
        name = $CollectionName
        description = "Auto-generated from PowerShell test files. Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    item = $collectionItems
}

# Save to file
$collection | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "✓ Collection created" -ForegroundColor Green
Write-Host "  File: $OutputFile" -ForegroundColor Gray
Write-Host "  Total folders: $($collectionItems.Count)" -ForegroundColor Gray
Write-Host "  Total tests: $($allTests.Count - ($groupedTests['POST/404'] + $groupedTests['PUT/404']).Count)" -ForegroundColor Gray
Write-Host ""

return $OutputFile

