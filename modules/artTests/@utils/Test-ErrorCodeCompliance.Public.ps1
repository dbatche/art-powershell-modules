function Test-ErrorCodeCompliance {
    <#
    .SYNOPSIS
        Validates that API error responses contain the expected error codes
    
    .DESCRIPTION
        Compares ExpectedErrorCode in test definitions against ActualErrorCodes in test results.
        Can analyze test results from Run-ApiTests output or from saved log files.
        Provides detailed reporting on error code matches and mismatches.
    
    .PARAMETER TestResults
        Test results from Run-ApiTests (array of result objects)
    
    .PARAMETER LogFile
        Path to a test log file (JSON) from Run-ApiTests
    
    .PARAMETER ShowOnlyFailures
        Only show tests where error code validation failed
    
    .PARAMETER OutputFormat
        Output format: 'Table' (default), 'List', or 'Object'
    
    .EXAMPLE
        $results = Run-ApiTests -RequestsFile "my-tests.ps1" -Token $token
        Test-ErrorCodeCompliance -TestResults $results
        # Validates error codes in test results
    
    .EXAMPLE
        Test-ErrorCodeCompliance -LogFile "test-results.json"
        # Validates error codes from a saved log file
    
    .EXAMPLE
        Test-ErrorCodeCompliance -TestResults $results -ShowOnlyFailures
        # Shows only tests with error code mismatches
    
    .OUTPUTS
        Array of error code validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [array]$TestResults,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowOnlyFailures,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Table', 'List', 'Object')]
        [string]$OutputFormat = 'Table'
    )
    
    # Load results from log file if provided
    if ($LogFile) {
        if (-not (Test-Path $LogFile)) {
            throw "Log file not found: $LogFile"
        }
        
        $logData = Get-Content $LogFile -Raw | ConvertFrom-Json
        $TestResults = $logData.Results
    }
    
    if (-not $TestResults -or $TestResults.Count -eq 0) {
        Write-Warning "No test results to validate"
        return
    }
    
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "ERROR CODE COMPLIANCE VALIDATION" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
    
    # Filter to tests that have ExpectedErrorCode
    $testsWithErrorCodes = $TestResults | Where-Object { $_.ExpectedErrorCode }
    
    if ($testsWithErrorCodes.Count -eq 0) {
        Write-Host "No tests have ExpectedErrorCode defined" -ForegroundColor Yellow
        Write-Host "To use error code validation, add ExpectedErrorCode to your test definitions" -ForegroundColor Gray
        return
    }
    
    Write-Host "Analyzing $($testsWithErrorCodes.Count) tests with expected error codes..." -ForegroundColor Gray
    Write-Host ""
    
    # Validate each test
    $validationResults = @()
    
    foreach ($test in $testsWithErrorCodes) {
        $errorCodeMatch = $false
        $matchDetails = ""
        
        if ($test.ActualErrorCodes -and $test.ActualErrorCodes.Count -gt 0) {
            # Check if expected code is in actual codes array
            if ($test.ActualErrorCodes -contains $test.ExpectedErrorCode) {
                $errorCodeMatch = $true
                $matchDetails = "Found in response"
            } else {
                $errorCodeMatch = $false
                $matchDetails = "Not found (got: $($test.ActualErrorCodes -join ', '))"
            }
        } else {
            $errorCodeMatch = $false
            $matchDetails = "No error codes in response"
        }
        
        $validationResults += [pscustomobject]@{
            Name              = $test.Name
            HttpStatus        = "$($test.ActualStatus)"
            HttpStatusMatch   = $test.Result
            ExpectedErrorCode = $test.ExpectedErrorCode
            ActualErrorCodes  = if ($test.ActualErrorCodes) { $test.ActualErrorCodes -join ', ' } else { '(none)' }
            ErrorCodeMatch    = if ($errorCodeMatch) { '✔' } else { '✘' }
            Details           = $matchDetails
        }
    }
    
    # Filter if requested
    if ($ShowOnlyFailures) {
        $validationResults = $validationResults | Where-Object { $_.ErrorCodeMatch -eq '✘' }
    }
    
    # Output results
    if ($OutputFormat -eq 'Object') {
        return $validationResults
    } elseif ($OutputFormat -eq 'List') {
        $validationResults | Format-List
    } else {
        # Table format
        $validationResults | Format-Table -AutoSize -Wrap
    }
    
    # Summary statistics
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    
    $totalTests = $testsWithErrorCodes.Count
    $errorCodeMatches = ($validationResults | Where-Object { $_.ErrorCodeMatch -eq '✔' }).Count
    $errorCodeMismatches = ($validationResults | Where-Object { $_.ErrorCodeMatch -eq '✘' }).Count
    $httpStatusMatches = ($testsWithErrorCodes | Where-Object { $_.Result -eq '✔' }).Count
    
    Write-Host ""
    Write-Host "Total Tests with Error Codes: $totalTests" -ForegroundColor White
    Write-Host ""
    Write-Host "HTTP Status Code Validation:" -ForegroundColor Yellow
    Write-Host "  ✔ Passed: $httpStatusMatches" -ForegroundColor Green
    Write-Host "  ✘ Failed: $($totalTests - $httpStatusMatches)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Code Validation:" -ForegroundColor Yellow
    Write-Host "  ✔ Matched: $errorCodeMatches" -ForegroundColor Green
    Write-Host "  ✘ Mismatched: $errorCodeMismatches" -ForegroundColor Red
    Write-Host ""
    
    $errorCodePassRate = if ($totalTests -gt 0) { 
        [math]::Round(($errorCodeMatches / $totalTests) * 100, 1) 
    } else { 0 }
    
    $color = if ($errorCodePassRate -eq 100) { 'Green' } 
             elseif ($errorCodePassRate -ge 80) { 'Yellow' } 
             else { 'Red' }
    
    Write-Host "Error Code Pass Rate: $errorCodePassRate% ($errorCodeMatches/$totalTests)" -ForegroundColor $color
    Write-Host ""
    
    return $validationResults
}

