function Run-ApiTests {
    <#
    .SYNOPSIS
        Execute API tests from a test script and log results
    
    .DESCRIPTION
        Runs API tests defined in a PowerShell script file using Invoke-RestMethod.
        Supports request body serialization, JSON validation, and comprehensive logging.
        Compatible with contract-generated tests from New-ContractTests.
    
    .PARAMETER BaseUrl
        Base URL of the API (default: http://localhost:8199)
    
    .PARAMETER Service
        Optional service path to append to base URL (e.g., 'tm', 'finance')
    
    .PARAMETER Token
        Bearer token for authentication
    
    .PARAMETER RequestsFile
        Path to PowerShell script containing test definitions (@() array of hashtables).
        If just a filename, searches in 40-test-definitions/ folder.
    
    .PARAMETER Requests
        Direct array of request hashtables (alternative to RequestsFile)
    
    .PARAMETER LogFile
        Optional custom path to save test results as JSON (auto-generates if not specified)
    
    .PARAMETER NoLog
        Skip saving test results to log file
    
    .PARAMETER FilterType
        Filter tests by type ('Contract', 'Functional', 'Manual', etc.)
    
    .PARAMETER ValidateJson
        Run JSON validation on successful responses (requires Test-ValidJson.ps1)
    
    .EXAMPLE
        Run-ApiTests -RequestsFile "requests.ps1" -Token $token
        # Run tests with authentication (auto-saves log to 50-test-results/)
    
    .EXAMPLE
        Run-ApiTests -RequestsFile "requests.ps1" -Token $token -NoLog
        # Run tests without saving log file
    
    .EXAMPLE
        Run-ApiTests -RequestsFile "requests.ps1" -LogFile "custom-name.json"
        # Run tests with custom log filename
    
    .EXAMPLE
        Run-ApiTests -RequestsFile "contract-tests.ps1" -ValidateJson
        # Run contract tests with JSON validation (log auto-saved)
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory=$false)]
        [string]$Service,
        
        [Parameter(Mandatory=$false)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$RequestsFile = "$PSScriptRoot\requests.ps1",
        
        [Parameter(Mandatory=$false)]
        [array]$Requests,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoLog,
        
        [Parameter(Mandatory=$false)]
        [string]$FilterType,
        
        [Parameter(Mandatory=$false)]
        [switch]$ValidateJson
    )

    # Use environment variables as fallback (try service-specific first, then generic)
    if (-not $BaseUrl) {
        $BaseUrl = $env:DOMAIN
    }
    if (-not $Token) {
        $Token = $env:TRUCKMATE_API_KEY
    }

    # Load request array from file or use provided array
    if ($Requests) {
        $requestArray = $Requests
    } elseif ($RequestsFile) {
        # Smart input path detection for RequestsFile
        $requestsPath = if (Test-Path $RequestsFile) {
            $RequestsFile
        } elseif ($RequestsFile -notmatch '[\\/]') {
            # Just a filename - try default folder
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $defaultPath = Join-Path $moduleRoot "40-test-definitions" $RequestsFile
            if (Test-Path $defaultPath) {
                $defaultPath
            } else {
                throw "Requests file not found: $RequestsFile (tried current dir and 40-test-definitions/)"
            }
        } else {
            if (-not (Test-Path $RequestsFile)) {
                throw "Requests file not found: $RequestsFile"
            }
            $RequestsFile
        }
        
        $requestArray = . $requestsPath
    } else {
        throw "Must provide either -Requests or -RequestsFile parameter"
    }
    
    if (-not ($requestArray -and $requestArray.Count)) { 
        throw 'No requests loaded.' 
    }
    
    # Filter by Type if specified
    $originalCount = $requestArray.Count
    if ($FilterType) {
        $requestArray = $requestArray | Where-Object { $_.Type -eq $FilterType }
        if (-not $requestArray) {
            Write-Warning "No tests found with Type = '$FilterType'"
            return
        }
        Write-Host "`nFiltered to Type = '$FilterType': $($requestArray.Count) of $originalCount tests`n" -ForegroundColor Cyan
    }

    # Load Test-ValidJson if validation is requested
    if ($ValidateJson) {
        $testValidJsonPath = Join-Path $PSScriptRoot 'Test-ValidJson.ps1'
        if (Test-Path $testValidJsonPath) {
            . $testValidJsonPath
        } else {
            Write-Warning "Test-ValidJson.ps1 not found. JSON validation will be skipped."
            $ValidateJson = $false
        }
    }

    $basePath = $BaseUrl.TrimEnd('/')
    if ($Service) { $basePath = "$basePath/$($Service.Trim('/'))" }

    # Determine log file path upfront (for header display)
    $logPath = $null
    if (-not $NoLog) {
        if ($LogFile) {
            # Custom log file specified
            $logPath = if ($LogFile -notmatch '[\\/]') {
                $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
                $resultsFolder = Join-Path $moduleRoot "50-test-results"
                if (-not (Test-Path $resultsFolder)) {
                    New-Item -ItemType Directory -Path $resultsFolder -Force | Out-Null
                }
                Join-Path $resultsFolder $LogFile
            } else {
                $LogFile
            }
        } else {
            # Auto-generate log filename based on RequestsFile and timestamp
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $resultsFolder = Join-Path $moduleRoot "50-test-results"
            if (-not (Test-Path $resultsFolder)) {
                New-Item -ItemType Directory -Path $resultsFolder -Force | Out-Null
            }
            
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $testFileName = if ($RequestsFile) {
                [System.IO.Path]::GetFileNameWithoutExtension($requestsPath)
            } else {
                'test-run'
            }
            $logPath = Join-Path $resultsFolder "$testFileName-$timestamp.json"
        }
    }

    # Pre-flight check: Get API version
    $apiVersion = $null
    $versionCheckPath = Join-Path $PSScriptRoot 'Get-ApiVersion.Public.ps1'
    if (Test-Path $versionCheckPath) {
        . $versionCheckPath
        $apiVersion = Get-ApiVersion -BaseUrl $basePath -Token $Token -Quiet
        
        Write-Host ""
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host "API TEST RUN" -ForegroundColor Cyan
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host "  Base URL: $basePath" -ForegroundColor Gray
        Write-Host "  Total Tests: $($requestArray.Count)" -ForegroundColor Gray
        
        if ($apiVersion.Success) {
            Write-Host "  API Version: $($apiVersion.Version)" -ForegroundColor Yellow
            if ($apiVersion.Debug) {
                Write-Host "  Debug Mode: $($apiVersion.Debug)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  API Status: ⚠ Version check failed" -ForegroundColor Red
            Write-Host "  Warning: Tests may fail if API is down" -ForegroundColor Yellow
        }
        
        # Show log file path if saving results
        if ($logPath) {
            Write-Host "  Output File: $logPath" -ForegroundColor Cyan
        }
        
        Write-Host ("=" * 80) -ForegroundColor Cyan
        Write-Host ""
    }

    $headers = @{}
    if ($Token) { $headers.Authorization = "Bearer $Token" }

    $allResults = @()

    foreach ($req in $requestArray) {
        if (-not ($req.Method -and $req.Url)) { continue }

        # V2 FORMAT SUPPORT: Handle variable substitution and query params
        $processedUrl = $req.Url
        
        # Remove {{DOMAIN}} since we use BaseUrl
        $processedUrl = $processedUrl -replace '\{\{DOMAIN\}\}/?', ''
        
        # Substitute {{variables}} if test has Variables (v2 format)
        if ($req.ContainsKey('Variables') -and $req.Variables) {
            foreach ($varKey in $req.Variables.Keys) {
                $varValue = $req.Variables[$varKey]
                if ($varValue) {
                    $processedUrl = $processedUrl -replace "\{\{$varKey\}\}", $varValue
                }
            }
        }
        
        # Append QueryParams if test has them (v2 format)
        if ($req.ContainsKey('QueryParams') -and $req.QueryParams -and $req.QueryParams.Count -gt 0) {
            $queryPairs = @()
            foreach ($paramKey in $req.QueryParams.Keys) {
                $queryPairs += "$paramKey=$($req.QueryParams[$paramKey])"
            }
            $queryString = $queryPairs -join '&'
            
            # Add to URL (use -match to find actual ? character, not -like which treats ? as wildcard)
            if ($processedUrl -match '\?') {
                $processedUrl += "&$queryString"
            } else {
                $processedUrl += "?$queryString"
            }
        }

        $uri = if ($processedUrl -match '^https?://') {
            $processedUrl
        } else {
            $rel = $processedUrl.TrimStart('/')
            "$basePath/$rel"
        }

        # Handle RawBody (for malformed JSON tests) or Body (for normal tests)
        $bodyJson = if ($req.ContainsKey('RawBody') -and $null -ne $req.RawBody) {
            # RawBody: Use as-is without JSON conversion (for malformed JSON tests)
            $req.RawBody
        } elseif ($null -ne $req.Body) { 
            # Body: Convert hashtable/array to JSON (normal behavior)
            # For arrays, use -AsArray to prevent single-element unwrapping
            # For hashtables/objects, serialize normally
            if ($req.Body -is [array]) {
                $req.Body | ConvertTo-Json -Depth 10 -AsArray
            } else {
                $req.Body | ConvertTo-Json -Depth 10
            }
        } else { $null }

        try {
            $status = $null
            $resp = Invoke-RestMethod -Method $req.Method -Uri $uri `
                     -Headers $headers -Body $bodyJson -ContentType 'application/json' `
                     -StatusCodeVariable status -SkipHttpErrorCheck -ErrorAction Stop
            $actualStatus = $status
            $actualBody   = $resp  # parsed or raw
            $responseError = $null
        } catch {
            $errResp      = $_.Exception.Response
            $actualStatus = if ($errResp) { $errResp.StatusCode.value__ } else { 'ERR' }
            $actualBody   = $_.Exception.Message
            $responseError = $_.Exception.Message
        }

        # Convert body to string for validation and logging
        $bodyString = if ($actualBody -is [string]) { 
            $actualBody 
        } else { 
            $actualBody | ConvertTo-Json -Depth 10 -Compress 
        }
        
        # Validate JSON if requested and status indicates success
        $jsonValid = $null
        $jsonError = $null
        if ($ValidateJson -and $actualStatus -ge 200 -and $actualStatus -lt 400 -and $bodyString) {
            $jsonValid = Test-ValidJson -JsonString $bodyString
            if (-not $jsonValid) {
                # Try to get detailed error
                try {
                    [System.Text.Json.JsonDocument]::Parse($bodyString) | Out-Null
                } catch {
                    $jsonError = $_.Exception.Message
                }
            }
        }
        
        # Extract error codes from response (for error code validation)
        $actualErrorCodes = @()
        if ($actualStatus -ge 400 -and $bodyString) {
            try {
                $errorResponse = $bodyString | ConvertFrom-Json
                if ($errorResponse.errors -and $errorResponse.errors.Count -gt 0) {
                    $actualErrorCodes = $errorResponse.errors | ForEach-Object { $_.code } | Where-Object { $_ }
                }
            } catch {
                # If we can't parse the error response, that's okay - just leave empty
            }
        }

        $result = [pscustomobject]@{
            Result            = if ($actualStatus -eq $req.ExpectedStatus) { '✔' } else { '✘' }
            Name              = $req.Name
            Method            = $req.Method
            Url               = $uri
            ExpectedStatus    = $req.ExpectedStatus
            ActualStatus      = $actualStatus
            Type              = if ($req.ContainsKey('Type')) { $req.Type } else { $null }
            ExpectedErrorCode = if ($req.ContainsKey('ExpectedErrorCode')) { $req.ExpectedErrorCode } else { $null }
            ActualErrorCodes  = $actualErrorCodes
            Body              = $bodyString
            BodyPreview       = if ($bodyString.Length -gt 100) { $bodyString.Substring(0, 100) + '...' } else { $bodyString }
            RequestBody       = $bodyJson
            JsonValid         = $jsonValid
            JsonError         = $jsonError
            ResponseError     = $responseError
            Timestamp         = Get-Date -Format 'o'
        }
        
        $allResults += $result
        
        # Output to pipeline (for immediate viewing)
        $result
    }

    # Save to log file if requested
    if ($logPath) {
        $testRunData = @{
            Timestamp = Get-Date -Format 'o'
            BaseUrl = $BaseUrl
            Service = $Service
            RequestsFile = $RequestsFile
            TotalTests = $allResults.Count
            Passed = ($allResults | Where-Object { $_.Result -eq '✔' }).Count
            Failed = ($allResults | Where-Object { $_.Result -eq '✘' }).Count
        }
        
        # Add API version if available
        if ($apiVersion -and $apiVersion.Success) {
            $testRunData.ApiVersion = $apiVersion.Version
            $testRunData.ApiDebug = $apiVersion.Debug
        }
        
        $logData = @{
            TestRun = $testRunData
            Results = $allResults
        }
        
        $logData | ConvertTo-Json -Depth 20 | Set-Content -Path $logPath -Encoding UTF8
        Write-Host "`n✓ Test results saved to: $logPath" -ForegroundColor Green
    }
}

