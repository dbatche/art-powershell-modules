function Update-TestDefinition {
    <#
    .SYNOPSIS
        Update specific fields in PowerShell test definition files
    
    .DESCRIPTION
        Modifies test definitions in v2 format PowerShell files.
        Can update variables, query params, scripts, body, expected status, etc.
        Useful for setting variable values, customizing tests, batch updates.
    
    .PARAMETER TestFile
        Path to test file (auto-checks 40-test-definitions/)
    
    .PARAMETER TestName
        Name of test to update (supports regex)
    
    .PARAMETER SetVariables
        Hashtable of variable values to set
        Example: @{ fuelTaxId = 2; tripFuelPurchaseId = 42 }
    
    .PARAMETER SetQueryParams
        Hashtable of query parameters to set
        Example: @{ '$select' = 'field1,field2' }
    
    .PARAMETER SetBody
        New body value (hashtable or string)
    
    .PARAMETER SetExpectedStatus
        New expected status code
    
    .PARAMETER SetExpectedErrorCode
        New expected error code (e.g., 'missingRequiredField', 'invalidInteger')
    
    .PARAMETER SetUrl
        New URL (for changing endpoints)
    
    .PARAMETER WhatIf
        Preview changes without applying
    
    .EXAMPLE
        Update-TestDefinition -TestFile "tests.ps1" -TestName "minimal" -SetVariables @{ fuelTaxId = 2 }
        # Set variable value for test matching "minimal"
    
    .EXAMPLE
        Update-TestDefinition -TestFile "tests.ps1" -TestName "select" -SetQueryParams @{ '$select' = 'field1,field2,field3' }
        # Update query parameters
    
    .EXAMPLE
        Update-TestDefinition -TestFile "tests.ps1" -TestName ".*" -SetVariables @{ fuelTaxId = 2 } -WhatIf
        # Preview setting variable for ALL tests
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestFile,
        
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$SetVariables,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$SetQueryParams,
        
        [Parameter(Mandatory=$false)]
        [object]$SetBody,
        
        [Parameter(Mandatory=$false)]
        [int]$SetExpectedStatus,
        
        [Parameter(Mandatory=$false)]
        [string]$SetExpectedErrorCode,
        
        [Parameter(Mandatory=$false)]
        [string]$SetUrl
    )
    
    # Smart input path detection
    $testPath = if (Test-Path $TestFile) {
        $TestFile
    } elseif ($TestFile -notmatch '[\\/]') {
        $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
        $defaultPath = Join-Path $moduleRoot "40-test-definitions" $TestFile
        if (Test-Path $defaultPath) {
            $defaultPath
        } else {
            throw "Test file not found: $TestFile (tried current dir and 40-test-definitions/)"
        }
    } else {
        throw "Test file not found: $TestFile"
    }
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "UPDATING TEST DEFINITIONS" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "File: $testPath" -ForegroundColor Yellow
    Write-Host "Filter: $TestName" -ForegroundColor Gray
    if ($WhatIfPreference) {
        Write-Host "Mode: PREVIEW (WhatIf)" -ForegroundColor Magenta
    }
    Write-Host ""
    
    # Load tests
    try {
        $tests = . $testPath
    } catch {
        throw "Failed to load test file: $($_.Exception.Message)"
    }
    
    if (-not $tests -or $tests.Count -eq 0) {
        throw "No tests found in file"
    }
    
    # Find matching tests
    $matchingTests = $tests | Where-Object { $_.Name -match $TestName }
    
    if ($matchingTests.Count -eq 0) {
        Write-Host "❌ No tests match: $TestName" -ForegroundColor Red
        return
    }
    
    Write-Host "Found $($matchingTests.Count) matching test(s):" -ForegroundColor Cyan
    $matchingTests | ForEach-Object { Write-Host "  • $($_.Name)" -ForegroundColor Gray }
    Write-Host ""
    
    # Track changes
    $changeCount = 0
    
    # Apply updates
    foreach ($test in $matchingTests) {
        $changes = @()
        
        # Update Variables
        if ($SetVariables) {
            foreach ($varKey in $SetVariables.Keys) {
                if (-not $test.ContainsKey('Variables')) {
                    $test.Variables = @{}
                } elseif (-not $test.Variables) {
                    $test.Variables = @{}
                }
                
                $oldValue = $test.Variables[$varKey]
                $newValue = $SetVariables[$varKey]
                
                if ($oldValue -ne $newValue) {
                    $test.Variables[$varKey] = $newValue
                    $changes += "Variables.$varKey`: '$oldValue' -> '$newValue'"
                }
            }
        }
        
        # Update QueryParams
        if ($SetQueryParams) {
            foreach ($paramKey in $SetQueryParams.Keys) {
                if (-not $test.ContainsKey('QueryParams')) {
                    $test.QueryParams = @{}
                } elseif (-not $test.QueryParams) {
                    $test.QueryParams = @{}
                }
                
                $oldValue = $test.QueryParams[$paramKey]
                $newValue = $SetQueryParams[$paramKey]
                
                if ($oldValue -ne $newValue) {
                    $test.QueryParams[$paramKey] = $newValue
                    $changes += "QueryParams.$paramKey`: '$oldValue' -> '$newValue'"
                }
            }
        }
        
        # Update Body
        if ($PSBoundParameters.ContainsKey('SetBody')) {
            $test.Body = $SetBody
            $changes += "Body updated"
        }
        
        # Update ExpectedStatus
        if ($PSBoundParameters.ContainsKey('SetExpectedStatus')) {
            $oldStatus = $test.ExpectedStatus
            $test.ExpectedStatus = $SetExpectedStatus
            $changes += "ExpectedStatus: $oldStatus -> $SetExpectedStatus"
        }
        
        # Update ExpectedErrorCode
        if ($PSBoundParameters.ContainsKey('SetExpectedErrorCode')) {
            $oldCode = $test.ExpectedErrorCode
            $test.ExpectedErrorCode = $SetExpectedErrorCode
            $changes += "ExpectedErrorCode: '$oldCode' -> '$SetExpectedErrorCode'"
        }
        
        # Update URL
        if ($SetUrl) {
            $oldUrl = $test.Url
            $test.Url = $SetUrl
            $changes += "Url: $oldUrl -> $SetUrl"
        }
        
        if ($changes.Count -gt 0) {
            Write-Host "Test: $($test.Name)" -ForegroundColor Yellow
            foreach ($change in $changes) {
                Write-Host "  ✓ $change" -ForegroundColor Green
            }
            $changeCount++
        }
    }
    
    Write-Host ""
    
    if ($changeCount -eq 0) {
        Write-Host "No changes made" -ForegroundColor Yellow
        return
    }
    
    if ($WhatIfPreference) {
        Write-Host "PREVIEW MODE - No changes saved" -ForegroundColor Magenta
        return
    }
    
    # Save back to file
    Write-Host "Saving changes..." -ForegroundColor Cyan
    
    # Helper: Convert test to PowerShell code (reuse from ConvertFrom-PostmanCollection logic)
    function ConvertTo-TestCode {
        param($Test)
        
        $lines = @()
        $lines += "    @{"
        $lines += "        Name = '$($Test.Name -replace "'", "''")'"
        $lines += "        Method = '$($Test.Method)'"
        $lines += "        Url = '$($Test.Url)'"
        $lines += "        ExpectedStatus = $($Test.ExpectedStatus)"
        
        if ($Test.ContainsKey('ExpectedErrorCode') -and $Test.ExpectedErrorCode) {
            $lines += "        ExpectedErrorCode = '$($Test.ExpectedErrorCode)'"
        }
        
        # Handle RawBody or Body
        if ($Test.ContainsKey('RawBody') -and $Test.RawBody) {
            $rawBodyLiteral = "'$($Test.RawBody -replace "'", "''")'"  # Escape single quotes
            $lines += "        RawBody = $rawBodyLiteral"
        } elseif ($Test.ContainsKey('Body') -and $Test.Body) {
            # Use ConvertTo-PowerShellLiteral to preserve hashtable format
            # (avoids double-encoding bug when Run-ApiTests reads the file)
            $bodyLiteral = ConvertTo-PowerShellLiteral -Object $Test.Body
            $lines += "        Body = $bodyLiteral"
        }
        
        if ($Test.ContainsKey('Variables') -and $Test.Variables -and $Test.Variables.Count -gt 0) {
            $varPairs = @()
            foreach ($key in $Test.Variables.Keys) {
                $val = $Test.Variables[$key]
                if ($val -is [int] -or $val -is [double]) {
                    $varPairs += "$key = $val"
                } else {
                    $varPairs += "$key = '$val'"
                }
            }
            $lines += "        Variables = @{ $($varPairs -join '; ') }"
        }
        
        if ($Test.ContainsKey('QueryParams') -and $Test.QueryParams -and $Test.QueryParams.Count -gt 0) {
            $paramPairs = @()
            foreach ($key in $Test.QueryParams.Keys) {
                $paramPairs += "'$key' = '$($Test.QueryParams[$key])'"
            }
            $lines += "        QueryParams = @{ $($paramPairs -join '; ') }"
        }
        
        if ($Test.ContainsKey('PreRequestScript') -and $Test.PreRequestScript) {
            $lines += "        PreRequestScript = @{"
            $lines += "            Type = '$($Test.PreRequestScript.Type)'"
            if ($Test.PreRequestScript.Content) {
                $lines += "            Content = @'"
                $lines += $Test.PreRequestScript.Content
                $lines += "'@"
            }
            $lines += "        }"
        }
        
        if ($Test.ContainsKey('TestScript') -and $Test.TestScript) {
            $lines += "        TestScript = @{"
            $lines += "            Type = '$($Test.TestScript.Type)'"
            if ($Test.TestScript.Utils) {
                $utilsList = ($Test.TestScript.Utils | ForEach-Object { "'$_'" }) -join ", "
                $lines += "            Utils = @($utilsList)"
            }
            if ($Test.TestScript.RawScript) {
                $lines += "            RawScript = @'"
                $lines += $Test.TestScript.RawScript
                $lines += "'@"
            }
            $lines += "        }"
        }
        
        $lines += "    }"
        
        return $lines -join "`n"
    }
    
    # Build file content
    $fileContent = @()
    $fileContent += "# PowerShell Test Definitions (v2 Format)"
    $fileContent += "# Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $fileContent += ""
    $fileContent += "@("
    
    $testCode = $tests | ForEach-Object { ConvertTo-TestCode -Test $_ }
    $fileContent += $testCode -join ",`n"
    
    $fileContent += ")"
    
    $fileContent -join "`n" | Set-Content -Path $testPath -Encoding UTF8
    
    Write-Host "✓ Saved $changeCount change(s) to file" -ForegroundColor Green
    Write-Host ""
    
    return $testPath
}

