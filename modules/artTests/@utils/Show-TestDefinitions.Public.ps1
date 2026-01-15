function Show-TestDefinitions {
    <#
    .SYNOPSIS
        Display test definitions from a test script file
    
    .DESCRIPTION
        Loads and displays test definitions from a PowerShell test script file
        without executing them. Useful for reviewing what tests are available,
        understanding test coverage, or selecting specific tests to run.
    
    .PARAMETER TestFile
        Path to test script file (auto-checks 40-test-definitions/ folder).
        If omitted, lists all available test files sorted by last write time.
    
    .PARAMETER OutputFormat
        Output format: 'Table' (default), 'List', or 'Object'
    
    .PARAMETER FilterName
        Filter tests by name (regex supported)
    
    .PARAMETER FilterMethod
        Filter by HTTP method (GET, POST, PUT, DELETE, PATCH)
    
    .PARAMETER FilterStatus
        Filter by expected status code
    
    .PARAMETER ShowBodies
        Show request bodies in output
    
    .EXAMPLE
        Show-TestDefinitions
        # List all available test files sorted by last write time
    
    .EXAMPLE
        Show-TestDefinitions -TestFile "tests.ps1"
        # Show all tests in table format
    
    .EXAMPLE
        Show-TestDefinitions -TestFile "tests.ps1" -OutputFormat List -ShowBodies -ShowDetails
        # Show detailed view with request bodies and full script content
    
    .EXAMPLE
        Show-TestDefinitions -TestFile "tests.ps1" -FilterMethod POST -FilterStatus 201
        # Show only POST tests expecting 201
    
    .EXAMPLE
        $tests = Show-TestDefinitions -TestFile "tests.ps1" -OutputFormat Object
        # Get test objects for programmatic use
    
    .OUTPUTS
        Displays test definitions or returns test objects
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$TestFile,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Table', 'List', 'Object')]
        [string]$OutputFormat = 'Table',
        
        [Parameter(Mandatory=$false)]
        [string]$FilterName,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$FilterMethod,
        
        [Parameter(Mandatory=$false)]
        [int]$FilterStatus,
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowBodies,
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowDetails  # Show full v2 field content (scripts, variables, etc.)
    )
    
    # If no TestFile specified, list available test files
    if (-not $TestFile) {
        $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
        $testDefinitionsFolder = Join-Path $moduleRoot "40-test-definitions"
        
        if (-not (Test-Path $testDefinitionsFolder)) {
            Write-Host "Test definitions folder not found: $testDefinitionsFolder" -ForegroundColor Red
            return
        }
        
        $testFiles = Get-ChildItem -Path $testDefinitionsFolder -Filter "*.ps1" | 
                     Sort-Object LastWriteTime -Descending
        
        if ($testFiles.Count -eq 0) {
            Write-Host "No test files found in: $testDefinitionsFolder" -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host ("=" * 100) -ForegroundColor Cyan
        Write-Host "AVAILABLE TEST FILES" -ForegroundColor White
        Write-Host ("=" * 100) -ForegroundColor Cyan
        Write-Host "Folder: $testDefinitionsFolder" -ForegroundColor Gray
        Write-Host ""
        
        $testFiles | Select-Object `
            @{Label='#';Expression={$testFiles.IndexOf($_)+1}}, `
            Name, `
            @{Label='Size (KB)';Expression={[math]::Round($_.Length/1KB, 2)}}, `
            @{Label='Last Modified';Expression={$_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')}} |
            Format-Table -AutoSize
        
        Write-Host ""
        Write-Host "Total: $($testFiles.Count) test file(s)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "TIP: Use 'Show-TestDefinitions -TestFile <filename>' to view test details" -ForegroundColor DarkGray
        return
    }
    
    # Smart input path detection
    $testPath = if (Test-Path $TestFile) {
        $TestFile
    } elseif ($TestFile -notmatch '[\\/]') {
        # Just a filename - try default folder
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
    
    # Load test definitions
    if ($OutputFormat -ne 'Object') {
        Write-Host "Loading test definitions..." -ForegroundColor Cyan
        Write-Host "  File: $testPath" -ForegroundColor Gray
    }
    
    try {
        $tests = . $testPath
    } catch {
        throw "Failed to load test file: $($_.Exception.Message)"
    }
    
    if (-not $tests -or $tests.Count -eq 0) {
        throw "No tests found in file"
    }
    
    if ($OutputFormat -ne 'Object') {
        Write-Host "✓ Loaded $($tests.Count) test(s)" -ForegroundColor Green
        Write-Host ""
    }
    
    # Apply filters
    $filteredTests = $tests
    
    if ($FilterName) {
        $filteredTests = $filteredTests | Where-Object { $_.Name -match $FilterName }
    }
    
    if ($FilterMethod) {
        $filteredTests = $filteredTests | Where-Object { $_.Method -eq $FilterMethod }
    }
    
    if ($FilterStatus) {
        $filteredTests = $filteredTests | Where-Object { $_.ExpectedStatus -eq $FilterStatus }
    }
    
    # Output based on format
    switch ($OutputFormat) {
        'Table' {
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host "TEST DEFINITIONS" -ForegroundColor Cyan
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host ""
            
            # Add v2 field indicators
            $filteredTests | Select-Object `
                @{Label='#';Expression={$filteredTests.IndexOf($_)+1}}, `
                Name, `
                Method, `
                @{Label='URL';Expression={$_.Url.Substring([Math]::Max(0, $_.Url.Length - 40))}}, `
                ExpectedStatus, `
                Type, `
                @{Label='Vars';Expression={if($_.ContainsKey('Variables') -and $_.Variables.Count -gt 0){'✓'}else{''}}}, `
                @{Label='QP';Expression={if($_.ContainsKey('QueryParams') -and $_.QueryParams.Count -gt 0){'✓'}else{''}}}, `
                @{Label='Pre';Expression={if($_.ContainsKey('PreRequestScript') -and $_.PreRequestScript){'✓'}else{''}}}, `
                @{Label='Test';Expression={if($_.ContainsKey('TestScript') -and $_.TestScript){'✓'}else{''}}} | 
                Format-Table -AutoSize
            
            Write-Host ""
            Write-Host "Showing $($filteredTests.Count) of $($tests.Count) test(s)" -ForegroundColor Gray
        }
        
        'List' {
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host "TEST DEFINITIONS" -ForegroundColor Cyan
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host ""
            
            $index = 1
            foreach ($test in $filteredTests) {
                Write-Host "[$index] $($test.Name)" -ForegroundColor Yellow
                Write-Host "  Method: $($test.Method)" -ForegroundColor Cyan
                Write-Host "  URL: $($test.Url)" -ForegroundColor Gray
                Write-Host "  Expected Status: $($test.ExpectedStatus)" -ForegroundColor $(if ($test.ExpectedStatus -ge 400) { 'Red' } else { 'Green' })
                
                # Show Type if present
                if ($test.ContainsKey('Type') -and $test.Type) {
                    $typeColor = switch ($test.Type) {
                        'Contract' { 'Magenta' }
                        'Functional' { 'Green' }
                        'Manual' { 'Yellow' }
                        default { 'Gray' }
                    }
                    Write-Host "  Type: $($test.Type)" -ForegroundColor $typeColor
                }
                
                # Show v2 fields if present
                if ($test.ContainsKey('Variables') -and $test.Variables) {
                    Write-Host "  Variables:" -ForegroundColor Yellow
                    foreach ($varKey in $test.Variables.Keys) {
                        Write-Host "    • $varKey = $($test.Variables[$varKey])" -ForegroundColor DarkGray
                    }
                }
                
                if ($test.ContainsKey('QueryParams') -and $test.QueryParams) {
                    Write-Host "  Query Params:" -ForegroundColor Yellow
                    foreach ($paramKey in $test.QueryParams.Keys) {
                        Write-Host "    • $paramKey = $($test.QueryParams[$paramKey])" -ForegroundColor DarkGray
                    }
                }
                
                if ($test.ContainsKey('PreRequestScript')) {
                    $scriptType = $test.PreRequestScript.Type
                    Write-Host "  Pre-Request Script: $scriptType" -ForegroundColor Magenta
                    
                    if ($ShowDetails -and $test.PreRequestScript.Content) {
                        Write-Host "    Content:" -ForegroundColor DarkCyan
                        $test.PreRequestScript.Content -split "`n" | Select-Object -First 5 | ForEach-Object {
                            Write-Host "      $_" -ForegroundColor DarkGray
                        }
                        if (($test.PreRequestScript.Content -split "`n").Count -gt 5) {
                            Write-Host "      ... (truncated)" -ForegroundColor DarkGray
                        }
                    }
                }
                
                if ($test.ContainsKey('TestScript')) {
                    $scriptInfo = if ($test.TestScript.Utils) {
                        "Utils: $($test.TestScript.Utils -join ', ')"
                    } else {
                        $test.TestScript.Type
                    }
                    Write-Host "  Test Script: $scriptInfo" -ForegroundColor Magenta
                    
                    if ($ShowDetails) {
                        if ($test.TestScript.Utils) {
                            Write-Host "    Utils Functions:" -ForegroundColor DarkCyan
                            $test.TestScript.Utils | ForEach-Object {
                                Write-Host "      • $_" -ForegroundColor DarkGray
                            }
                        }
                        if ($test.TestScript.RawScript) {
                            Write-Host "    Raw Script:" -ForegroundColor DarkCyan
                            $test.TestScript.RawScript -split "`n" | Select-Object -First 5 | ForEach-Object {
                                Write-Host "      $_" -ForegroundColor DarkGray
                            }
                            if (($test.TestScript.RawScript -split "`n").Count -gt 5) {
                                Write-Host "      ... (truncated)" -ForegroundColor DarkGray
                            }
                        }
                    }
                }
                
                if ($ShowBodies -and $test.Body) {
                    Write-Host "  Request Body:" -ForegroundColor Cyan
                    try {
                        $bodyJson = $test.Body | ConvertTo-Json -Depth 5
                        $bodyLines = $bodyJson -split "`n" | Select-Object -First 10
                        foreach ($line in $bodyLines) {
                            Write-Host "    $line" -ForegroundColor DarkGray
                        }
                        if (($bodyJson -split "`n").Count -gt 10) {
                            Write-Host "    ... (truncated)" -ForegroundColor DarkGray
                        }
                    } catch {
                        Write-Host "    $($test.Body)" -ForegroundColor DarkGray
                    }
                }
                
                Write-Host ""
                $index++
            }
            
            Write-Host "Showing $($filteredTests.Count) of $($tests.Count) test(s)" -ForegroundColor Gray
        }
        
        'Object' {
            # Convert hashtables to PSCustomObject for better pipelining to Format-Table
            $objects = $filteredTests | ForEach-Object {
                $test = $_
                $obj = [PSCustomObject]@{
                    Name = $test.Name
                    Method = $test.Method
                    Url = $test.Url
                    ExpectedStatus = $test.ExpectedStatus
                    Type = $test.Type
                    ExpectedErrorCode = if ($test.ContainsKey('ExpectedErrorCode')) { $test.ExpectedErrorCode } else { $null }
                }
                
                # Add body (Body or RawBody)
                if ($test.ContainsKey('Body')) {
                    $obj | Add-Member -NotePropertyName 'Body' -NotePropertyValue $test.Body
                }
                if ($test.ContainsKey('RawBody')) {
                    $obj | Add-Member -NotePropertyName 'RawBody' -NotePropertyValue $test.RawBody
                }
                
                # Add v2 fields with ACTUAL CONTENT (not just indicators)
                if ($test.ContainsKey('Variables')) {
                    $obj | Add-Member -NotePropertyName 'Variables' -NotePropertyValue $test.Variables
                }
                if ($test.ContainsKey('QueryParams')) {
                    $obj | Add-Member -NotePropertyName 'QueryParams' -NotePropertyValue $test.QueryParams
                }
                if ($test.ContainsKey('PreRequestScript')) {
                    $obj | Add-Member -NotePropertyName 'PreRequestScript' -NotePropertyValue $test.PreRequestScript
                }
                if ($test.ContainsKey('TestScript')) {
                    $obj | Add-Member -NotePropertyName 'TestScript' -NotePropertyValue $test.TestScript
                }
                
                # Add convenience indicators for filtering
                $obj | Add-Member -NotePropertyName 'HasPreRequest' -NotePropertyValue ($test.ContainsKey('PreRequestScript') -and $test.PreRequestScript)
                $obj | Add-Member -NotePropertyName 'HasTestScript' -NotePropertyValue ($test.ContainsKey('TestScript') -and $test.TestScript)
                $obj | Add-Member -NotePropertyName 'HasVariables' -NotePropertyValue ($test.ContainsKey('Variables') -and $test.Variables)
                $obj | Add-Member -NotePropertyName 'HasQueryParams' -NotePropertyValue ($test.ContainsKey('QueryParams') -and $test.QueryParams)
                
                $obj
            }
            
            return $objects
        }
    }
}

