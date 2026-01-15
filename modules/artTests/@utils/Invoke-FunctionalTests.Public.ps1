function Invoke-FunctionalTests {
    <#
    .SYNOPSIS
        Execute functional tests using PowerShell wrapper functions
    
    .DESCRIPTION
        Runs functional tests defined with Setup/Test/Assert scriptblocks.
        Unlike contract tests which use raw URLs, these tests leverage
        the PowerShell API wrapper functions (Get-CashReceipts, Set-CashReceipt, etc.)
    
    .PARAMETER TestFile
        Path to test definition file (auto-checks 70-functional-tests/ folder)
    
    .PARAMETER Tests
        Direct array of test definitions (alternative to TestFile)
    
    .PARAMETER LogFile
        Optional custom path to save test results as JSON
    
    .PARAMETER NoLog
        Skip saving test results to log file
    
    .PARAMETER StopOnFailure
        Stop executing tests after first failure
    
    .EXAMPLE
        Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1"
    
    .EXAMPLE
        Invoke-FunctionalTests -TestFile "cashReceipts-functional-tests.ps1" -NoLog
    
    .OUTPUTS
        Test results with pass/fail status and detailed information
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$TestFile,
        
        [Parameter(Mandatory=$false)]
        [array]$Tests,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$NoLog,
        
        [Parameter(Mandatory=$false)]
        [switch]$StopOnFailure
    )
    
    # Load tests from file or use provided array
    if ($Tests) {
        $testArray = $Tests
        $testSource = "Direct input"
    } elseif ($TestFile) {
        # Smart input path detection
        $testPath = if (Test-Path $TestFile) {
            $TestFile
        } elseif ($TestFile -notmatch '[\\/]') {
            # Just a filename - try default folder
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $defaultPath = Join-Path $moduleRoot "70-functional-tests" $TestFile
            if (Test-Path $defaultPath) {
                $defaultPath
            } else {
                throw "Test file not found: $TestFile (tried current dir and 70-functional-tests/)"
            }
        } else {
            if (-not (Test-Path $TestFile)) {
                throw "Test file not found: $TestFile"
            }
            $TestFile
        }
        
        Write-Host "Loading functional tests..." -ForegroundColor Cyan
        Write-Host "  File: $testPath" -ForegroundColor Gray
        Write-Host ""
        
        $testArray = . $testPath
        $testSource = $testPath
    } else {
        throw "Must provide either -Tests or -TestFile parameter"
    }
    
    # Determine log path
    $logPath = if (-not $NoLog) {
        if ($LogFile) {
            if ($LogFile -notmatch '[\\/]') {
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
            # Auto-generate log filename
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $resultsFolder = Join-Path $moduleRoot "50-test-results"
            if (-not (Test-Path $resultsFolder)) {
                New-Item -ItemType Directory -Path $resultsFolder -Force | Out-Null
            }
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $baseName = if ($TestFile) {
                [System.IO.Path]::GetFileNameWithoutExtension($TestFile)
            } else {
                "functional-tests"
            }
            Join-Path $resultsFolder "$baseName-$timestamp.json"
        }
    } else {
        $null
    }
    
    # Header
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "FUNCTIONAL TESTS EXECUTION" -ForegroundColor White
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "Tests loaded: $($testArray.Count)" -ForegroundColor Gray
    Write-Host ""
    
    $allResults = @()
    $testNumber = 1
    
    foreach ($test in $testArray) {
        $testName = $test.Name
        $testDescription = $test.Description
        
        Write-Host "[$testNumber/$($testArray.Count)] $testName" -ForegroundColor Yellow
        if ($testDescription) {
            Write-Host "  $testDescription" -ForegroundColor Gray
        }
        
        $testResult = [pscustomobject]@{
            TestNumber = $testNumber
            Name = $testName
            Description = $testDescription
            Result = $null
            Passed = $false
            ActualOutcome = $null
            ExpectedOutcome = $test.ExpectedOutcome
            Error = $null
            SetupError = $null
            Duration = $null
            Timestamp = Get-Date -Format 'o'
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Run setup if provided
            if ($test.Setup) {
                Write-Host "  Running setup..." -ForegroundColor DarkGray
                try {
                    & $test.Setup
                } catch {
                    $testResult.SetupError = $_.Exception.Message
                    Write-Host "  ✘ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
                    $testResult.Result = "SETUP_FAILED"
                    $testResult.Passed = $false
                    $stopwatch.Stop()
                    $testResult.Duration = $stopwatch.ElapsedMilliseconds
                    $allResults += $testResult
                    $testNumber++
                    
                    if ($StopOnFailure) {
                        Write-Host ""
                        Write-Host "Stopping execution due to setup failure" -ForegroundColor Red
                        break
                    }
                    continue
                }
            }
            
            # Run test
            Write-Host "  Executing test..." -ForegroundColor DarkGray
            $testOutput = & $test.Test
            
            # Run assertion
            if ($test.Assert) {
                Write-Host "  Running assertion..." -ForegroundColor DarkGray
                $assertResult = $test.Assert.Invoke($testOutput)
                
                if ($assertResult) {
                    $testResult.Result = "PASS"
                    $testResult.Passed = $true
                    $testResult.ActualOutcome = "Assertion passed"
                    Write-Host "  ✔ PASS" -ForegroundColor Green
                } else {
                    $testResult.Result = "FAIL"
                    $testResult.Passed = $false
                    $testResult.ActualOutcome = "Assertion failed"
                    Write-Host "  ✘ FAIL - Assertion returned false" -ForegroundColor Red
                }
            } else {
                # No assertion - just check if test ran without error
                $testResult.Result = "PASS"
                $testResult.Passed = $true
                $testResult.ActualOutcome = "Test executed successfully (no assertion)"
                Write-Host "  ✔ PASS (no assertion)" -ForegroundColor Green
            }
            
            # Add output preview for debugging
            if ($testOutput) {
                $outputPreview = if ($testOutput -is [string]) {
                    $testOutput.Substring(0, [Math]::Min(200, $testOutput.Length))
                } else {
                    ($testOutput | ConvertTo-Json -Depth 2 -Compress).Substring(0, [Math]::Min(200, ($testOutput | ConvertTo-Json -Depth 2 -Compress).Length))
                }
                $testResult | Add-Member -NotePropertyName OutputPreview -NotePropertyValue $outputPreview
            }
            
        } catch {
            $testResult.Result = "ERROR"
            $testResult.Passed = $false
            $testResult.Error = $_.Exception.Message
            $testResult.ActualOutcome = "Exception: $($_.Exception.Message)"
            Write-Host "  ✘ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            # Run cleanup if provided
            if ($test.Cleanup) {
                try {
                    & $test.Cleanup
                } catch {
                    Write-Host "  ⚠ Cleanup warning: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            $stopwatch.Stop()
            $testResult.Duration = $stopwatch.ElapsedMilliseconds
        }
        
        $allResults += $testResult
        Write-Host ""
        
        $testNumber++
        
        if ($StopOnFailure -and -not $testResult.Passed) {
            Write-Host "Stopping execution due to test failure" -ForegroundColor Red
            break
        }
    }
    
    # Summary
    $passed = ($allResults | Where-Object { $_.Passed }).Count
    $failed = ($allResults | Where-Object { -not $_.Passed }).Count
    $totalDuration = ($allResults | Measure-Object -Property Duration -Sum).Sum
    
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor White
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "Total:    $($allResults.Count)" -ForegroundColor Gray
    Write-Host "Passed:   $passed" -ForegroundColor $(if ($passed -gt 0) { 'Green' } else { 'Gray' })
    Write-Host "Failed:   $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "Duration: $totalDuration ms" -ForegroundColor Gray
    Write-Host ""
    
    # Save to log file
    if ($logPath) {
        $logData = @{
            TestRun = @{
                Timestamp = Get-Date -Format 'o'
                TestSource = $testSource
                TotalTests = $allResults.Count
                Passed = $passed
                Failed = $failed
                Duration = $totalDuration
            }
            Results = $allResults
        }
        
        $logData | ConvertTo-Json -Depth 20 | Set-Content -Path $logPath -Encoding UTF8
        Write-Host "✓ Test results saved to: $logPath" -ForegroundColor Green
        Write-Host ""
    }
    
    # Return results
    return $allResults
}

