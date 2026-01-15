function Test-Result {
    <#
    .SYNOPSIS
        Records and displays test results for plain PowerShell test scripts
    
    .DESCRIPTION
        Simple test result tracker for plain PowerShell scripts (no framework).
        Tracks pass/fail counts and displays colored output.
        
        Results are stored in script-level variables:
        - $script:passed (count)
        - $script:failed (count)
        - $script:tests (array of test objects)
    
    .PARAMETER TestName
        Name/description of the test
    
    .PARAMETER Passed
        Boolean indicating if test passed ($true) or failed ($false)
    
    .PARAMETER Message
        Optional message to display (usually for failures)
    
    .EXAMPLE
        # Initialize counters at start of test script
        Initialize-TestResults
        
        # Run tests
        $result = Get-CashReceipts -Limit 5
        Test-Result "Get cash receipts" -Passed ($result -isnot [string])
        
        # Show summary
        Show-TestSummary
    
    .EXAMPLE
        # With message
        Test-Result "Update amount" `
            -Passed $false `
            -Message "Expected 100, got 50"
    
    .OUTPUTS
        Displays colored pass/fail message
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$true)]
        [bool]$Passed,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = ""
    )
    
    # Initialize script variables if they don't exist
    if (-not (Get-Variable -Name passed -Scope Script -ErrorAction SilentlyContinue)) {
        $script:passed = 0
        $script:failed = 0
        $script:tests = @()
    }
    
    # Record test result
    $script:tests += [pscustomobject]@{
        Test = $TestName
        Passed = $Passed
        Message = $Message
    }
    
    # Update counters
    if ($Passed) {
        $script:passed++
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
    } else {
        $script:failed++
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "  → $Message" -ForegroundColor Yellow
        }
    }
}

function Initialize-TestResults {
    <#
    .SYNOPSIS
        Initializes test result tracking variables
    
    .DESCRIPTION
        Resets script-level counters for test tracking.
        Call this at the start of your test script.
    
    .PARAMETER LogFile
        Optional path to log file for key test data (JSON format)
    
    .EXAMPLE
        Initialize-TestResults
        
    .EXAMPLE
        Initialize-TestResults -LogFile "interliner-test-data.json"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    $script:passed = 0
    $script:failed = 0
    $script:tests = @()
    $script:scenarios = @()
    $script:currentScenario = $null
    $script:testLogFile = $LogFile
    $script:testStartTime = Get-Date
    $script:testData = @{
        startTime = $script:testStartTime.ToString('yyyy-MM-dd HH:mm:ss')
        scenarios = @()
    }
}

function Start-TestScenario {
    <#
    .SYNOPSIS
        Starts a new test scenario (an actual API call under test)
    
    .PARAMETER Name
        Name of the scenario
        
    .PARAMETER Description
        Optional detailed description
        
    .EXAMPLE
        Start-TestScenario "GET /interlinerPayables/{id}" -Description "Retrieve single payable"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$Description
    )
    
    # Save previous scenario if exists
    if ($script:currentScenario) {
        $script:scenarios += $script:currentScenario
        $script:testData.scenarios += $script:currentScenario
    }
    
    # Start new scenario
    $script:currentScenario = @{
        name = $Name
        description = $Description
        assertions = @()
        keyData = @{}
        startTime = Get-Date
    }
    
    Write-Host ""
    Write-Host "[$($script:scenarios.Count + 1)] $Name" -ForegroundColor Cyan
    if ($Description) {
        Write-Host "    $Description" -ForegroundColor Gray
    }
}

function Test-Assertion {
    <#
    .SYNOPSIS
        Records an assertion within the current scenario
    
    .PARAMETER Name
        Name of the assertion
        
    .PARAMETER Passed
        Whether the assertion passed
        
    .PARAMETER Message
        Optional message (usually for failures)
        
    .EXAMPLE
        Test-Assertion "Returns valid payable" -Passed ($result -isnot [string])
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [bool]$Passed,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = ""
    )
    
    if (-not $script:currentScenario) {
        Write-Warning "Test-Assertion called without Start-TestScenario. Creating default scenario."
        Start-TestScenario "Unnamed Scenario"
    }
    
    # Record assertion
    $assertion = @{
        name = $Name
        passed = $Passed
        message = $Message
    }
    $script:currentScenario.assertions += $assertion
    
    # Update counters
    if ($Passed) {
        $script:passed++
        Write-Host "    ✅ $Name" -ForegroundColor Green
    } else {
        $script:failed++
        Write-Host "    ❌ $Name" -ForegroundColor Red
        if ($Message) {
            Write-Host "       → $Message" -ForegroundColor Yellow
        }
    }
}

function Write-TestInfo {
    <#
    .SYNOPSIS
        Logs key test data for manual lookups (IDs, amounts, etc.)
    
    .PARAMETER Message
        Simple text message to log
        
    .PARAMETER Data
        Hashtable of key data to log
        
    .EXAMPLE
        Write-TestInfo "Using payable ID: 9"
        
    .EXAMPLE
        Write-TestInfo -Data @{ payableId = 9; originalAmount = 830; newAmount = 840.50 }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Data
    )
    
    if (-not $script:currentScenario) {
        Write-Warning "Write-TestInfo called without Start-TestScenario"
        return
    }
    
    # Log message
    if ($Message) {
        Write-Host "    ℹ️  $Message" -ForegroundColor DarkGray
    }
    
    # Store structured data
    if ($Data) {
        foreach ($key in $Data.Keys) {
            $script:currentScenario.keyData[$key] = $Data[$key]
        }
    }
}

function Show-TestSummary {
    <#
    .SYNOPSIS
        Displays test summary with pass/fail counts
    
    .DESCRIPTION
        Shows formatted summary of test results.
        Call this at the end of your test script.
    
    .PARAMETER ShowFailedTests
        If specified, lists all failed tests with their messages
    
    .EXAMPLE
        Show-TestSummary
    
    .EXAMPLE
        Show-TestSummary -ShowFailedTests
    #>
    
    [CmdletBinding()]
    param(
        [switch]$ShowFailedTests
    )
    
    # Save final scenario
    if ($script:currentScenario) {
        $script:scenarios += $script:currentScenario
        $script:testData.scenarios += $script:currentScenario
        $script:currentScenario = $null
    }
    
    # Get script variables (default to 0 if not initialized)
    $passedCount = if (Get-Variable -Name passed -Scope Script -ErrorAction SilentlyContinue) { 
        $script:passed 
    } else { 
        0 
    }
    $failedCount = if (Get-Variable -Name failed -Scope Script -ErrorAction SilentlyContinue) { 
        $script:failed 
    } else { 
        0 
    }
    $testResults = if (Get-Variable -Name tests -Scope Script -ErrorAction SilentlyContinue) { 
        $script:tests 
    } else { 
        @() 
    }
    $scenarioResults = if (Get-Variable -Name scenarios -Scope Script -ErrorAction SilentlyContinue) { 
        $script:scenarios 
    } else { 
        @() 
    }
    
    # Complete test data
    $script:testData.endTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $script:testData.duration = ((Get-Date) - $script:testStartTime).TotalSeconds
    $script:testData.totalAssertions = $passedCount + $failedCount
    $script:testData.passed = $passedCount
    $script:testData.failed = $failedCount
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor White
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "Scenarios: $($scenarioResults.Count)" -ForegroundColor White
    Write-Host "Assertions: $($passedCount + $failedCount)" -ForegroundColor White
    Write-Host "Passed: $passedCount" -ForegroundColor Green
    
    if ($failedCount -gt 0) {
        Write-Host "Failed: $failedCount" -ForegroundColor Red
    } else {
        Write-Host "Failed: $failedCount" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # Optionally show failed tests
    if ($ShowFailedTests -and $failedCount -gt 0) {
        Write-Host "Failed Assertions:" -ForegroundColor Red
        foreach ($scenario in $scenarioResults) {
            $failedAssertions = $scenario.assertions | Where-Object { -not $_.passed }
            if ($failedAssertions) {
                Write-Host "  $($scenario.name):" -ForegroundColor Yellow
                foreach ($assertion in $failedAssertions) {
                    Write-Host "    • $($assertion.name)" -ForegroundColor Yellow
                    if ($assertion.message) {
                        Write-Host "      $($assertion.message)" -ForegroundColor Gray
                    }
                }
            }
        }
        Write-Host ""
    }
    
    # Write log file if specified
    if ($script:testLogFile) {
        try {
            $logPath = if ([System.IO.Path]::IsPathRooted($script:testLogFile)) {
                $script:testLogFile
            } else {
                Join-Path (Get-Location) $script:testLogFile
            }
            
            $script:testData | ConvertTo-Json -Depth 10 | Out-File -FilePath $logPath -Encoding UTF8
            Write-Host "Test data logged to: $logPath" -ForegroundColor DarkGray
            Write-Host ""
        }
        catch {
            Write-Warning "Failed to write log file: $_"
        }
    }
}



