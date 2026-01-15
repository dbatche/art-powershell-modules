function ConvertFrom-PostmanCollection {
    <#
    .SYNOPSIS
        Export Postman collection requests to PowerShell v2 test format
    
    .DESCRIPTION
        Fetches a Postman collection via API and converts requests to PowerShell v2 test format.
        Preserves variables, pre-request scripts, test scripts, and folder structures.
        Supports both full collection export and selective folder export.
    
    .PARAMETER CollectionUid
        Postman collection UID (e.g., "2332132-470e17f8-...")
    
    .PARAMETER ApiKey
        Postman API key (or uses $env:POSTMAN_API_KEY)
    
    .PARAMETER FolderPath
        Optional: Specific folder path to export (e.g., "tripFuelPurchaseId/PUT")
        If not specified, exports entire collection
    
    .PARAMETER OutputFile
        Path to save PowerShell test file (auto-uses 40-test-definitions/)
    
    .PARAMETER IncludeScripts
        Include pre-request and test scripts (default: $true)
    
    .EXAMPLE
        ConvertFrom-PostmanCollection -CollectionUid "2332132-..." -OutputFile "tests-v2.ps1"
        # Export entire collection to PowerShell v2 format
    
    .EXAMPLE
        ConvertFrom-PostmanCollection -CollectionUid "2332132-..." -FolderPath "tripFuelPurchaseId/PUT" -OutputFile "put-tests.ps1"
        # Export specific folder only
    
    .EXAMPLE
        ConvertFrom-PostmanCollection -CollectionUid "2332132-..." -ApiKey $key -OutputFile "tests.ps1" -IncludeScripts:$false
        # Export without scripts (basic format)
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CollectionUid,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [string]$FolderPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$false)]
        [bool]$IncludeScripts = $true
    )
    
    # Use environment variable as fallback for ApiKey
    if (-not $ApiKey) {
        $ApiKey = $env:POSTMAN_API_KEY
    }
    
    if (-not $ApiKey) {
        throw "ApiKey is required. Provide -ApiKey or set `$env:POSTMAN_API_KEY"
    }
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "CONVERTING POSTMAN COLLECTION TO POWERSHELL V2 FORMAT" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
    
    # Fetch collection from Postman API
    Write-Host "Fetching collection from Postman..." -ForegroundColor Yellow
    Write-Host "  Collection UID: $CollectionUid" -ForegroundColor Gray
    
    $headers = @{ 'X-Api-Key' = $ApiKey }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$CollectionUid" -Headers $headers -Method Get
        $collection = $response.collection
    } catch {
        throw "Failed to fetch collection: $($_.Exception.Message)"
    }
    
    Write-Host "  ✓ Fetched: $($collection.info.name)" -ForegroundColor Green
    Write-Host ""
    
    # Helper: Extract variables from URL
    function Get-UrlVariables {
        param([string]$Url)
        
        $variables = @{}
        $matches = [regex]::Matches($Url, '\{\{(\w+)\}\}')
        
        foreach ($match in $matches) {
            $varName = $match.Groups[1].Value
            if ($varName -and $varName -ne 'DOMAIN') {
                $variables[$varName] = $null  # Will be populated later
            }
        }
        
        return $variables
    }
    
    # Helper: Extract query parameters from URL or url.query array
    function Get-QueryParams {
        param($UrlObject, [string]$UrlString)
        
        # First try Postman url.query array format
        if ($UrlObject -and $UrlObject.query) {
            $params = @{}
            foreach ($param in $UrlObject.query) {
                $params[$param.key] = $param.value
            }
            if ($params.Count -gt 0) {
                return $params
            }
        }
        
        # Fallback to parsing query string from URL
        if ($UrlString -match '\?(.+)$') {
            $queryString = $matches[1]
            $params = @{}
            
            foreach ($pair in $queryString -split '&') {
                if ($pair -match '([^=]+)=(.*)') {
                    $params[$matches[1]] = $matches[2]
                }
            }
            
            if ($params.Count -gt 0) {
                return $params
            }
        }
        
        return $null
    }
    
    # Helper: Convert Postman request to PowerShell v2 test
    function ConvertTo-PowerShellTest {
        param($Request, $IncludeScripts)
        
        # Extract method
        $method = $Request.request.method
        
        # Extract URL (handle both string and object formats)
        $urlObject = $Request.request.url
        $url = if ($urlObject -is [string]) {
            $urlObject
        } else {
            $urlObject.raw
        }
        
        # Clean URL (remove query string)
        $baseUrl = $url -replace '\?.*$', ''
        
        # Get variables from URL
        $variables = Get-UrlVariables -Url $baseUrl
        
        # Get query parameters (check both url.query array and URL string)
        $queryParams = Get-QueryParams -UrlObject $urlObject -UrlString $url
        
        # Parse body
        $body = if ($Request.request.body.raw) {
            try {
                $Request.request.body.raw | ConvertFrom-Json
            } catch {
                $Request.request.body.raw
            }
        } else {
            $null
        }
        
        # Build base test object - ALWAYS include all v2 fields for consistency
        $test = @{
            Name = $Request.name
            Method = $method
            Url = $baseUrl
            ExpectedStatus = 200  # Default, will be overridden by test script analysis
            Body = $body  # Can be null
            Variables = if ($variables.Count -gt 0) { $variables } else { $null }
            QueryParams = $queryParams  # Can be null
            PreRequestScript = $null  # Will be populated below
            TestScript = $null  # Will be populated below
        }
        
        # Extract scripts if requested
        if ($IncludeScripts) {
            # Pre-request script
            $preRequestEvent = $Request.event | Where-Object { $_.listen -eq 'prerequest' }
            if ($preRequestEvent -and $preRequestEvent.script.exec) {
                $preScript = $preRequestEvent.script.exec -join "`n"
                if ($preScript.Trim()) {
                    $test.PreRequestScript = @{
                        Type = "Inline"
                        Content = $preScript
                    }
                }
            }
            # If no pre-request script, PreRequestScript stays $null (already set)
            
            # Test script
            $testEvent = $Request.event | Where-Object { $_.listen -eq 'test' }
            if ($testEvent -and $testEvent.script.exec) {
                $testScriptContent = $testEvent.script.exec -join "`n"
                
                # Detect utils.* function calls
                $utilsCalls = @()
                if ($testScriptContent -match 'utils\.validateFieldValuesIfCode') {
                    $utilsCalls += "validateFieldValues"
                }
                if ($testScriptContent -match 'utils\.validateJsonSchemaIfCode') {
                    $utilsCalls += "validateJsonSchema"
                }
                if ($testScriptContent -match 'utils\.validateSelectParameter') {
                    $utilsCalls += "validateSelectParameter"
                }
                if ($testScriptContent -match 'tm_utils\.testInvalidDbValueResponse') {
                    $utilsCalls += "testInvalidDbValue"
                }
                if ($testScriptContent -match 'tm_utils\.testInvalidBusinessLogicResponse') {
                    $utilsCalls += "testInvalidBusinessLogic"
                }
                
                # Try to extract expected status from test script
                if ($testScriptContent -match 'pm\.response\.to\.have\.status\((\d+)\)' -or
                    $testScriptContent -match 'utils\.testStatusCode\((\d+)\)') {
                    $test.ExpectedStatus = [int]$matches[1]
                }
                
                if ($utilsCalls.Count -gt 0) {
                    $test.TestScript = @{
                        Type = "Utils"
                        Utils = $utilsCalls
                        RawScript = $testScriptContent
                    }
                } elseif ($testScriptContent.Trim()) {
                    $test.TestScript = @{
                        Type = "Inline"
                        Content = $testScriptContent
                    }
                }
            }
            # If no test script, TestScript stays $null (already set)
        }
        
        return $test
    }
    
    # Helper: Recursively find all requests in collection/folder
    function Get-AllRequests {
        param($Items, $PathPrefix = "")
        
        $requests = @()
        
        foreach ($item in $Items) {
            $currentPath = if ($PathPrefix) { "$PathPrefix/$($item.name)" } else { $item.name }
            
            if ($item.request) {
                # This is a request
                $requests += @{
                    Request = $item
                    Path = $currentPath
                }
            }
            
            if ($item.item) {
                # This is a folder, recurse
                $requests += Get-AllRequests -Items $item.item -PathPrefix $currentPath
            }
        }
        
        return $requests
    }
    
    # Get all requests from collection
    Write-Host "Extracting requests..." -ForegroundColor Yellow
    $allRequests = Get-AllRequests -Items $collection.item
    
    # Filter by folder path if specified
    if ($FolderPath) {
        Write-Host "  Filtering by folder: $FolderPath" -ForegroundColor Gray
        $allRequests = $allRequests | Where-Object { $_.Path -like "$FolderPath/*" }
    }
    
    Write-Host "  ✓ Found $($allRequests.Count) requests" -ForegroundColor Green
    Write-Host ""
    
    # Convert each request
    Write-Host "Converting to PowerShell v2 format..." -ForegroundColor Yellow
    $tests = @()
    
    foreach ($req in $allRequests) {
        $test = ConvertTo-PowerShellTest -Request $req.Request -IncludeScripts $IncludeScripts
        $tests += $test
        Write-Host "  ✓ $($test.Name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  Total converted: $($tests.Count)" -ForegroundColor Green
    Write-Host ""
    
    # Build output file content
    Write-Host "Building PowerShell file..." -ForegroundColor Yellow
    
    # Helper: Convert test object to PowerShell code
    function ConvertTo-PowerShellCode {
        param($Test, $Indent = "    ")
        
        $lines = @()
        $lines += "$Indent@{"
        # Escape apostrophes in Name
        $escapedName = $Test.Name -replace "'", "''"
        $lines += "$Indent    Name = '$escapedName'"
        $lines += "$Indent    Method = '$($Test.Method)'"
        $lines += "$Indent    Url = '$($Test.Url)'"
        $lines += "$Indent    ExpectedStatus = $($Test.ExpectedStatus)"
        
        # Body
        if ($Test.ContainsKey('Body') -and $null -ne $Test.Body) {
            $bodyJson = $Test.Body | ConvertTo-Json -Depth 10 -Compress
            $lines += "$Indent    Body = '$bodyJson'  # TODO: Convert to hashtable"
        } else {
            $lines += "$Indent    Body = @{}"
        }
        
        # Variables - ALWAYS include, keep variable names even if no default value
        if ($Test.Variables -and $Test.Variables.Count -gt 0) {
            $varLines = @()
            foreach ($key in $Test.Variables.Keys) {
                $val = $Test.Variables[$key]
                # Keep variable name, use empty string if no default value
                if ($null -eq $val) {
                    $varLines += "$key = ''"  # Empty string, can be set at runtime
                } elseif ($val -is [int] -or $val -is [double]) {
                    $varLines += "$key = $val"
                } else {
                    $varLines += "$key = '$val'"
                }
            }
            $lines += "$Indent    Variables = @{ $($varLines -join '; ') }"
        } else {
            $lines += "$Indent    Variables = @{}"
        }
        
        # Query params
        if ($Test.QueryParams -and $Test.QueryParams.Count -gt 0) {
            $paramLines = @()
            foreach ($key in $Test.QueryParams.Keys) {
                $paramLines += "'$key' = '$($Test.QueryParams[$key])'"
            }
            $lines += "$Indent    QueryParams = @{ $($paramLines -join '; ') }"
        } else {
            $lines += "$Indent    QueryParams = @{}"
        }
        
        # Pre-request script - Use empty string if none
        if ($Test.PreRequestScript) {
            $lines += "$Indent    PreRequestScript = @{"
            $lines += "$Indent        Type = '$($Test.PreRequestScript.Type)'"
            if ($Test.PreRequestScript.Content) {
                $escaped = $Test.PreRequestScript.Content -replace "'", "''"
                $lines += "$Indent        Content = @'"
                $lines += $Test.PreRequestScript.Content
                $lines += "'@"
            }
            $lines += "$Indent    }"
        } else {
            $lines += "$Indent    PreRequestScript = ''"
        }
        
        # Test script - Use empty string if none
        if ($Test.TestScript) {
            $lines += "$Indent    TestScript = @{"
            $lines += "$Indent        Type = '$($Test.TestScript.Type)'"
            
            if ($Test.TestScript.Utils) {
                $utilsList = ($Test.TestScript.Utils | ForEach-Object { "'$_'" }) -join ", "
                $lines += "$Indent        Utils = @($utilsList)"
            }
            
            if ($Test.TestScript.Content -or $Test.TestScript.RawScript) {
                $scriptContent = if ($Test.TestScript.RawScript) { $Test.TestScript.RawScript } else { $Test.TestScript.Content }
                $escaped = $scriptContent -replace "'", "''"
                $lines += "$Indent        RawScript = @'"
                $lines += $scriptContent
                $lines += "'@"
            }
            
            $lines += "$Indent    }"
        } else {
            $lines += "$Indent    TestScript = ''"
        }
        
        $lines += "$Indent}"
        
        return $lines -join "`n"
    }
    
    # Build file content
    $fileLines = @()
    $fileLines += "# PowerShell Test Definitions (v2 Format)"
    $fileLines += "# Exported from Postman collection: $($collection.info.name)"
    $fileLines += "# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    if ($FolderPath) {
        $fileLines += "# Folder: $FolderPath"
    }
    $fileLines += ""
    $fileLines += "@("
    
    $testCode = $tests | ForEach-Object { ConvertTo-PowerShellCode -Test $_ }
    $fileLines += $testCode -join ",`n"
    
    $fileLines += ")"
    
    # Smart path detection for output
    $outputPath = if ($OutputFile -notmatch '[\\/]') {
        $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
        $testsFolder = Join-Path $moduleRoot "40-test-definitions"
        if (-not (Test-Path $testsFolder)) {
            New-Item -ItemType Directory -Path $testsFolder -Force | Out-Null
        }
        Join-Path $testsFolder $OutputFile
    } else {
        $OutputFile
    }
    
    # Save to file
    $fileLines -join "`n" | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Host "✓ Exported to: $outputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Tests exported: $($tests.Count)" -ForegroundColor Yellow
    Write-Host "  Format: v2" -ForegroundColor Yellow
    
    $withVars = ($tests | Where-Object { $_.Variables }).Count
    $withPreScript = ($tests | Where-Object { $_.PreRequestScript }).Count
    $withTestScript = ($tests | Where-Object { $_.TestScript }).Count
    
    if ($IncludeScripts) {
        Write-Host "  With variables: $withVars" -ForegroundColor Gray
        Write-Host "  With pre-request scripts: $withPreScript" -ForegroundColor Gray
        Write-Host "  With test scripts: $withTestScript" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    return $outputPath
}

