function New-TestDefinition {
    <#
    .SYNOPSIS
        Create or append a test definition to a test file
    
    .DESCRIPTION
        Helper function to create properly formatted test definitions.
        Creates new test file or appends to existing file.
        Ensures correct PowerShell hashtable format for Run-ApiTests compatibility.
    
    .PARAMETER TestFile
        Path to test file (creates if doesn't exist, appends if exists)
        Auto-uses 40-test-definitions/ folder for filenames
    
    .PARAMETER Name
        Test name (descriptive)
    
    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE, PATCH)
    
    .PARAMETER Url
        API endpoint URL (relative or absolute)
    
    .PARAMETER ExpectedStatus
        Expected HTTP status code (200, 201, 400, 404, etc.)
    
    .PARAMETER Type
        Type of test ('Manual', 'Functional', 'Contract', 'Integration', etc.)
        Defaults to 'Manual'
    
    .PARAMETER ExpectedErrorCode
        Expected error code in response body (e.g., 'missingRequiredField', 'invalidInteger')
        Optional - only used for error responses (4xx/5xx)
        Used for validating specific API error codes
    
    .PARAMETER Body
        Request body (hashtable or array of hashtables)
        For GET/DELETE: typically $null
        For POST/PUT: hashtable with fields
        Cannot be used with -RawBody
    
    .PARAMETER RawBody
        Raw request body as string (for malformed JSON tests)
        Use this to send invalid JSON that cannot be represented as a hashtable
        Cannot be used with -Body
    
    .PARAMETER Comment
        Optional comment to add above the test definition
    
    .EXAMPLE
        New-TestDefinition -TestFile "my-tests.ps1" -Name "Create item" -Method POST -Url "/items" -ExpectedStatus 201 -Body @{ name = "Test"; value = 123 }
        # Creates new file with one test
    
    .EXAMPLE
        New-TestDefinition -TestFile "my-tests.ps1" -Name "Get items" -Method GET -Url "/items" -ExpectedStatus 200 -Body $null
        # Appends GET test to existing file
    
    .EXAMPLE
        New-TestDefinition -TestFile "edge-tests.ps1" -Name "Empty string edge case" -Method POST -Url "/items" -ExpectedStatus 400 -Body @{ name = "" } -Comment "Testing empty string validation"
        # Adds test with comment
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestFile,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [int]$ExpectedStatus,
        
        [Parameter(Mandatory=$false)]
        [string]$Type = 'Manual',
        
        [Parameter(Mandatory=$false)]
        [string]$ExpectedErrorCode,
        
        [Parameter(Mandatory=$false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$RawBody,
        
        [Parameter(Mandatory=$false)]
        [string]$Comment
    )
    
    # Validate mutual exclusivity of Body and RawBody
    if ($PSBoundParameters.ContainsKey('Body') -and $PSBoundParameters.ContainsKey('RawBody')) {
        throw "Cannot use both -Body and -RawBody parameters. Use -Body for normal tests (hashtables) or -RawBody for malformed JSON tests (raw strings)."
    }
    
    # Smart path detection for output
    $testPath = if ($TestFile -notmatch '[\\/]') {
        $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
        $testsFolder = Join-Path $moduleRoot "40-test-definitions"
        if (-not (Test-Path $testsFolder)) {
            New-Item -ItemType Directory -Path $testsFolder -Force | Out-Null
        }
        Join-Path $testsFolder $TestFile
    } else {
        $TestFile
    }
    
    # Validate Body format
    $bodyWarnings = @()
    
    if ($PSBoundParameters.ContainsKey('RawBody')) {
        # Using RawBody - no validation needed, store as-is
        $bodyLiteral = "'$($RawBody -replace "'", "''")'"  # Escape single quotes
        $bodyProperty = "RawBody"
    } elseif ($null -ne $Body) {
        # Check if Body is hashtable or array
        if ($Body -isnot [hashtable] -and $Body -isnot [array]) {
            Write-Warning "Body should be a hashtable or array. Attempting to convert..."
            $bodyWarnings += "Body type is $($Body.GetType().Name) - should be hashtable or array"
        }
        
        # For POST/PUT, warn if body is null
        if ($Method -in @('POST', 'PUT', 'PATCH') -and $null -eq $Body) {
            Write-Warning "Method is $Method but Body is null. Is this intentional?"
            $bodyWarnings += "Null body for $Method request"
        }
        
        # Convert body to PowerShell literal format (uses shared function)
        $bodyLiteral = ConvertTo-PowerShellLiteral -Object $Body
        $bodyProperty = "Body"
    } else {
        # No body
        $bodyLiteral = ConvertTo-PowerShellLiteral -Object $null
        $bodyProperty = "Body"
    }
    
    # Build test definition
    $expectedErrorCodeLine = if ($PSBoundParameters.ContainsKey('ExpectedErrorCode')) {
        "`n        ExpectedErrorCode = '$ExpectedErrorCode'"
    } else { "" }
    
    $testDefinition = @"
    @{
        Name = '$Name'
        Method = '$Method'
        Url = '$Url'
        ExpectedStatus = $ExpectedStatus$expectedErrorCodeLine
        Type = '$Type'
        $bodyProperty = $bodyLiteral
    }
"@
    
    # Add comment if provided
    if ($Comment) {
        $testDefinition = "    # $Comment`n$testDefinition"
    }
    
    # Check if file exists
    if (Test-Path $testPath) {
        # File exists - append to it
        Write-Host "Appending test to existing file..." -ForegroundColor Cyan
        Write-Host "  File: $testPath" -ForegroundColor Gray
        
        # Read existing content
        $existingContent = Get-Content $testPath -Raw
        
        # Check if it ends with closing parenthesis
        if ($existingContent -match '\)[\s\r\n]*$') {
            # Remove the closing paren
            $existingContent = $existingContent -replace '\)[\s\r\n]*$', ''
            
            # Add comma and new test
            $newContent = $existingContent.TrimEnd() + ",`n`n$testDefinition`n)"
            
            $newContent | Set-Content -Path $testPath -Encoding UTF8
            
            Write-Host "✓ Test appended" -ForegroundColor Green
        } else {
            Write-Warning "File format not recognized. Creating backup and recreating file."
            Copy-Item $testPath "$testPath.bak"
            Write-Host "  Backup saved: $testPath.bak" -ForegroundColor Yellow
            
            # Load existing tests
            $existingTests = . $testPath
            
            # Build new test hashtable
            $newTest = @{
                Name = $Name
                Method = $Method
                Url = $Url
                ExpectedStatus = $ExpectedStatus
                Type = $Type
            }
            if ($PSBoundParameters.ContainsKey('ExpectedErrorCode')) {
                $newTest.ExpectedErrorCode = $ExpectedErrorCode
            }
            if ($PSBoundParameters.ContainsKey('RawBody')) {
                $newTest.RawBody = $RawBody
            } else {
                $newTest.Body = $Body
            }
            $existingTests += $newTest
            
            # Regenerate file (uses shared ConvertTo-PowerShellLiteral)
            $testStrings = $existingTests | ForEach-Object {
                # Determine if test uses RawBody or Body
                if ($_.ContainsKey('RawBody')) {
                    $bodyLit = "'$($_.RawBody -replace "'", "''")'"  # Escape single quotes
                    $bodyProp = "RawBody"
                } else {
                    $bodyLit = ConvertTo-PowerShellLiteral -Object $_.Body
                    $bodyProp = "Body"
                }
                
                # Add ExpectedErrorCode if present
                $errorCodeLine = if ($_.ContainsKey('ExpectedErrorCode')) {
                    "`n        ExpectedErrorCode = '$($_.ExpectedErrorCode)'"
                } else { "" }
                
                # Get Type or default to 'Manual'
                $testType = if ($_.ContainsKey('Type')) { $_.Type } else { 'Manual' }
                
                @"
    @{
        Name = '$($_.Name)'
        Method = '$($_.Method)'
        Url = '$($_.Url)'
        ExpectedStatus = $($_.ExpectedStatus)$errorCodeLine
        Type = '$testType'
        $bodyProp = $bodyLit
    }
"@
            }
            
            $newFileContent = "# Manual test definitions`n# Generated/Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n@(`n$($testStrings -join ",`n")`n)"
            $newFileContent | Set-Content -Path $testPath -Encoding UTF8
            
            Write-Host "✓ File regenerated with new test" -ForegroundColor Green
        }
        
    } else {
        # File doesn't exist - create it
        Write-Host "Creating new test file..." -ForegroundColor Cyan
        Write-Host "  File: $testPath" -ForegroundColor Gray
        
        $fileContent = @"
# Manual test definitions
# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

@(
$testDefinition
)
"@
        
        $fileContent | Set-Content -Path $testPath -Encoding UTF8
        Write-Host "✓ File created with 1 test" -ForegroundColor Green
    }
    
    # Load and show test count
    $allTests = . $testPath
    Write-Host ""
    Write-Host "File now contains: $($allTests.Count) test(s)" -ForegroundColor Yellow
    
    # Show warnings if any
    if ($bodyWarnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        $bodyWarnings | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor Yellow }
    }
    
    Write-Host ""
    Write-Host "✓ Test added successfully" -ForegroundColor Green
    Write-Host ""
    
    return $testPath
}

