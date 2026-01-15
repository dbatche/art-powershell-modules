function New-ContractTests {
    <#
    .SYNOPSIS
    Generates PowerShell test cases from an OpenAPI contract.
    
    .DESCRIPTION
    Analyzes an OpenAPI contract and automatically generates comprehensive test cases
    including required field validation, data type tests, constraint tests, and success cases.
    Output is compatible with Run-ApiTests-IRM.ps1.
    
    .PARAMETER Contract
    The contract object from Analyze-OpenApiSchema, OR a file path to a contract JSON file.
    If a file path is provided, the contract will be loaded automatically.
    
    .PARAMETER BaseUrl
    The base URL for the API (e.g., '/fuelTaxes/{fuelTaxId}/tripFuelPurchases').
    Can include path parameters in {braces}.
    
    .PARAMETER PathParameters
    Hashtable of path parameter values (e.g., @{ fuelTaxId = 2 }).
    
    .PARAMETER OutputFile
    Path to save the generated test file.
    If not specified, auto-generates a filename like: tests-put-cashReceipts-cashReceiptId-{timestamp}.ps1
    Saves to 40-test-definitions folder by default.
    
    .PARAMETER IncludeSuccessTests
    Generate success test cases (minimal valid, all fields). 
    Enabled by default if no switches are specified.
    
    .PARAMETER IncludeConstraintTests
    Generate constraint violation tests.
    Enabled by default if no switches are specified.
    
    .PARAMETER IncludeTypeTests
    Generate invalid type tests.
    Enabled by default if no switches are specified.
    
    .PARAMETER IncludeParameterTests
    Generate parameter validation tests (path/query parameters).
    Enabled by default if no switches are specified.
    
    .PARAMETER IncludeMalformedJsonTests
    Generate malformed JSON tests (unclosed braces, invalid syntax, etc.).
    Opt-in only (disabled by default). Only applies to POST, PUT, and PATCH methods.
    
    .EXAMPLE
    # Generate all tests from a contract file (simplest usage)
    New-ContractTests -Contract "put-cashReceiptId.json" -BaseUrl $env:FINANCE_API_URL
    
    .EXAMPLE
    # Generate tests with path parameters
    New-ContractTests -Contract ".\30-contract-schemas\put-cashReceiptId.json" `
                      -BaseUrl "$env:FINANCE_API_URL/cashReceipts/{cashReceiptId}" `
                      -PathParameters @{ cashReceiptId = 12345 }
    
    .EXAMPLE
    # Generate only specific test types
    New-ContractTests -Contract "put-cashReceiptId.json" -BaseUrl $env:FINANCE_API_URL `
                      -IncludeConstraintTests -IncludeTypeTests
    
    .EXAMPLE
    # Traditional usage: Load contract first, then generate tests
    $contract = Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/fuelTaxes/{fuelTaxId}/tripFuelPurchases" -Method "POST"
    New-ContractTests -Contract $contract -BaseUrl '/fuelTaxes/2/tripFuelPurchases' -OutputFile "tests.ps1"
    
    .OUTPUTS
    Array of test case objects compatible with Run-ApiTests.
    Also saves tests to a .ps1 file (auto-named if -OutputFile not specified)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Contract,
        
        [Parameter(Mandatory=$true)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$PathParameters = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeSuccessTests,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeConstraintTests,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeTypeTests,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeParameterTests,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeMalformedJsonTests
    )
    
    # Set defaults for switches if not explicitly provided
    # If user didn't specify any switches, enable all by default
    $anySwitchProvided = $PSBoundParameters.ContainsKey('IncludeSuccessTests') -or
                         $PSBoundParameters.ContainsKey('IncludeConstraintTests') -or
                         $PSBoundParameters.ContainsKey('IncludeTypeTests') -or
                         $PSBoundParameters.ContainsKey('IncludeParameterTests') -or
                         $PSBoundParameters.ContainsKey('IncludeMalformedJsonTests')
    
    if (-not $anySwitchProvided) {
        # Enable all tests by default (except malformed JSON which is opt-in)
        $IncludeSuccessTests = $true
        $IncludeConstraintTests = $true
        $IncludeTypeTests = $true
        $IncludeParameterTests = $true
    }
    
    # If Contract is a string (file path), load it
    if ($Contract -is [string]) {
        $contractPath = if (Test-Path $Contract) {
            $Contract
        } elseif ($Contract -notmatch '[\\/]') {
            # Just a filename - try default folder
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $defaultPath = Join-Path $moduleRoot "30-contract-schemas" $Contract
            if (Test-Path $defaultPath) {
                $defaultPath
            } else {
                throw "Contract file not found: $Contract (tried current dir and 30-contract-schemas/)"
            }
        } else {
            throw "Contract file not found: $Contract"
        }
        
        Write-Host "Loading contract from file..." -ForegroundColor Cyan
        Write-Host "  File: $contractPath" -ForegroundColor Gray
        
        try {
            $Contract = Get-Content $contractPath -Raw | ConvertFrom-Json
        } catch {
            throw "Failed to load contract file: $($_.Exception.Message)"
        }
    }
    
    Write-Host "Generating contract-driven tests..." -ForegroundColor Cyan
    Write-Host "  Endpoint: $($Contract.Method) $($Contract.Path)" -ForegroundColor Gray
    Write-Host "  Schema: $($Contract.RequestSchema.SchemaName)" -ForegroundColor Gray
    Write-Host ""
    
    # Replace path parameters in URL
    $url = $BaseUrl
    foreach ($param in $PathParameters.Keys) {
        $url = $url -replace "\{$param\}", $PathParameters[$param]
    }
    
    $tests = @()
    $requestSchema = $Contract.RequestSchema
    $method = $Contract.Method
    
    # Determine success status code (typically 201 for POST, 200 for PUT/PATCH)
    $successStatus = if ($method -eq 'POST') { 201 } else { 200 }
    
    Write-Host "📋 Generating Test Categories:" -ForegroundColor Cyan
    Write-Host ""
    
    #region Required Field Tests
    
    if ($requestSchema.Required.Count -gt 0) {
        Write-Host "1. Required Field Tests ($($requestSchema.Required.Count) tests)" -ForegroundColor Yellow
        
        foreach ($requiredField in $requestSchema.Required) {
            # Create a minimal valid body
            $body = @{}
            foreach ($req in $requestSchema.Required) {
                if ($req -ne $requiredField) {
                    # Add other required fields with valid values
                    $body[$req] = Get-SampleValue -Property $requestSchema.Properties.$req
                }
            }
            
            # Wrap in array if needed (use comma operator to preserve array)
            $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
            
            $tests += @{
                Name = "$method - missing required field: $requiredField"
                Method = $method
                Url = $url
                ExpectedStatus = 400
                ExpectedErrorCode = "missingRequiredField"
                Type = 'Contract'
                Body = $bodyToSend
            }
        }
        
        Write-Host "   ✓ Generated $($requestSchema.Required.Count) missing required field tests" -ForegroundColor Green
    } else {
        Write-Host "1. Required Field Tests (0 tests - no required fields)" -ForegroundColor Yellow
        
        # Special case: No required fields, but need at least one field
        $emptyBody = if ($requestSchema.IsArray) { , @(@{}) } else { @{} }
        $tests += @{
            Name = "$method - empty object (no fields)"
            Method = $method
            Url = $url
            ExpectedStatus = 400
            ExpectedErrorCode = "noValidFields"
            Type = 'Contract'
            Body = $emptyBody
        }
        
        Write-Host "   ✓ Generated 1 empty object test" -ForegroundColor Green
    }
    
    Write-Host ""
    
    #endregion
    
    #region Constraint Tests
    
    if ($IncludeConstraintTests) {
        $constraintTests = 0
        
        Write-Host "2. Constraint Violation Tests" -ForegroundColor Yellow
        
        $propNames = if ($requestSchema.Properties -is [hashtable]) {
            $requestSchema.Properties.Keys
        } else {
            $requestSchema.Properties.PSObject.Properties.Name
        }
        
        foreach ($propName in $propNames) {
            $prop = $requestSchema.Properties.$propName
            
            # MaxLength test
            if ($prop.MaxLength) {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = 'A' * ($prop.MaxLength + 1)
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - exceeds maxLength: $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "exceedsMaxLength"
                    Body = $bodyToSend
                }
                $constraintTests++
            }
            
            # Enum test
            if ($prop.Enum -and $prop.Enum.Count -gt 0) {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = "InvalidEnumValue_NotInList"
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - invalid enum: $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "invalidEnum"
                    Body = $bodyToSend
                }
                $constraintTests++
            }
            
            # Pattern test (for string patterns like dates)
            if ($prop.Pattern -and $prop.Type -eq 'string') {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = "InvalidPatternValue"
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - invalid pattern: $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "invalidDateTime"
                    Body = $bodyToSend
                }
                $constraintTests++
            }
            
            # Minimum/Maximum tests for numbers
            if ($null -ne $prop.Minimum -and $prop.Type -in @('number', 'integer')) {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = $prop.Minimum - 1
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - below minimum: $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "belowMinValue"
                    Body = $bodyToSend
                }
                $constraintTests++
            }
            
            if ($null -ne $prop.Maximum -and $prop.Type -in @('number', 'integer')) {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = $prop.Maximum + 1
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - exceeds maximum: $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "exceedsMaxValue"
                    Body = $bodyToSend
                }
                $constraintTests++
            }
        }
        
        Write-Host "   ✓ Generated $constraintTests constraint tests" -ForegroundColor Green
        Write-Host ""
    }
    
    #endregion
    
    #region Type Tests
    
    if ($IncludeTypeTests) {
        $typeTests = 0
        
        Write-Host "3. Invalid Type Tests" -ForegroundColor Yellow
        
        # Test a few key properties with wrong types
        $allPropNames = if ($requestSchema.Properties -is [hashtable]) {
            $requestSchema.Properties.Keys
        } else {
            $requestSchema.Properties.PSObject.Properties.Name
        }
        $testProps = $allPropNames | Select-Object -First 5
        
        foreach ($propName in $testProps) {
            $prop = $requestSchema.Properties.$propName
            
            if ($prop.Type -eq 'number' -or $prop.Type -eq 'integer') {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = "not-a-number"
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $errorCode = if ($prop.Type -eq 'integer') { "invalidInteger" } else { "invalidDouble" }
                $tests += @{
                    Name = "$method - invalid type (string for number): $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = $errorCode
                    Body = $bodyToSend
                }
                $typeTests++
            }
            
            if ($prop.Type -eq 'string') {
                $body = Get-MinimalValidBody -RequestSchema $requestSchema
                $body[$propName] = 12345
                $bodyToSend = if ($requestSchema.IsArray) { , @($body) } else { $body }
                
                $tests += @{
                    Name = "$method - invalid type (number for string): $propName"
                    Method = $method
                    Url = $url
                    ExpectedStatus = 400
                Type = 'Contract'
                    ExpectedErrorCode = "invalidString"
                    Body = $bodyToSend
                }
                $typeTests++
            }
        }
        
        Write-Host "   ✓ Generated $typeTests type validation tests" -ForegroundColor Green
        Write-Host ""
    }
    
    #endregion
    
    #region Parameter Tests
    
    if ($IncludeParameterTests -and $Contract.Parameters -and $Contract.Parameters.Count -gt 0) {
        $parameterTests = 0
        
        Write-Host "4. Parameter Validation Tests" -ForegroundColor Yellow
        
        # Required parameter tests
        $requiredParams = $Contract.Parameters | Where-Object { $_.Required }
        foreach ($param in $requiredParams) {
            # Test missing required query parameters (applies to ALL methods)
            $minimalBody = if ($requestSchema) { Get-MinimalValidBody -RequestSchema $requestSchema } else { $null }
            $minimalBodyToSend = if ($requestSchema -and $requestSchema.IsArray) { , @($minimalBody) } else { $minimalBody }
            
            $tests += @{
                Name = "$method - missing required parameter: $($param.Name)"
                Method = $method
                Url = $url  # Don't include the required parameter
                ExpectedStatus = 400
                Type = 'Contract'
                ExpectedErrorCode = "missingRequiredField"
                Body = $minimalBodyToSend
            }
            $parameterTests++
        }
        
        # Constraint violation tests for parameters
        foreach ($param in $Contract.Parameters) {
            $minimalBody = if ($requestSchema) { Get-MinimalValidBody -RequestSchema $requestSchema } else { $null }
            $minimalBodyToSend = if ($requestSchema -and $requestSchema.IsArray) { , @($minimalBody) } else { $minimalBody }
            
            # Minimum violation
            if ($null -ne $param.Minimum -and $param.Type -in @('integer', 'number')) {
                $invalidValue = $param.Minimum - 1
                $tests += @{
                    Name = "$method - parameter below minimum: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=$invalidValue"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
            }
            
            # Maximum violation
            if ($null -ne $param.Maximum -and $param.Type -in @('integer', 'number')) {
                $invalidValue = $param.Maximum + 1
                $tests += @{
                    Name = "$method - parameter exceeds maximum: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=$invalidValue"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
            }
            
            # Enum violation
            if ($param.Enum -and $param.Enum.Count -gt 0) {
                $tests += @{
                    Name = "$method - invalid enum for parameter: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=INVALID_ENUM_VALUE"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
            }
            
            # Type violation (string when expecting integer)
            if ($param.Type -eq 'integer') {
                $tests += @{
                    Name = "$method - invalid type for parameter: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=not_a_number"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
            }
            
            # Pagination-specific tests (for offset/limit/skip/page parameters)
            if ($param.Name -in @('offset', 'limit', 'skip', 'page', 'pageSize', 'top') -and $param.Type -in @('integer', 'number')) {
                # Negative value test
                $tests += @{
                    Name = "$method - pagination parameter negative: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=-1"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
                
                # Decimal value test (if integer type)
                if ($param.Type -eq 'integer') {
                    $tests += @{
                        Name = "$method - pagination parameter decimal: $($param.Name)"
                        Method = $method
                        Url = "$url`?$($param.Name)=5.5"
                        ExpectedStatus = 400
                Type = 'Contract'
                        Body = $minimalBodyToSend
                    }
                    $parameterTests++
                }
                
                # Out of bounds test (if it's a limit parameter)
                if ($param.Name -in @('limit', 'pageSize', 'top')) {
                    $tests += @{
                        Name = "$method - pagination parameter out of bounds: $($param.Name)"
                        Method = $method
                        Url = "$url`?$($param.Name)=999999999"
                        ExpectedStatus = 400
                Type = 'Contract'
                        Body = $minimalBodyToSend
                    }
                    $parameterTests++
                }
            }
            
            # OData-specific tests (for $select, $filter, $orderBy)
            if ($param.Name -in @('$select', '$filter', '$orderBy')) {
                # Invalid syntax test
                $invalidValue = if ($param.Name -eq '$select') { 'invalid,,field' } 
                                elseif ($param.Name -eq '$filter') { 'invalid syntax here!' }
                                else { 'invalid field name!' }
                
                $tests += @{
                    Name = "$method - OData parameter invalid syntax: $($param.Name)"
                    Method = $method
                    Url = "$url`?$($param.Name)=$invalidValue"
                    ExpectedStatus = 400
                Type = 'Contract'
                    Body = $minimalBodyToSend
                }
                $parameterTests++
            }
        }
        
        Write-Host "   ✓ Generated $parameterTests parameter validation tests" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "4. Parameter Validation Tests (0 tests - no parameters or disabled)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    #endregion
    
    #region Success Tests
    
    if ($IncludeSuccessTests) {
        Write-Host "5. Success Tests" -ForegroundColor Yellow
        
        # Only generate request body tests if there's a request schema
        if ($requestSchema) {
            # Build URL with required query parameters (if any)
            $urlWithParams = $url
            $requiredParams = $Contract.Parameters | Where-Object { $_.Required }
            if ($requiredParams) {
                $paramStr = ($requiredParams | ForEach-Object { 
                    $value = if ($_.Enum) { $_.Enum[0] } elseif ($_.Type -eq 'integer') { 1 } else { 'test' }
                    "$($_.Name)=$value"
                }) -join '&'
                $urlWithParams = "$url`?$paramStr"
            }
            
            # Minimal valid request
            $minimalBody = Get-MinimalValidBody -RequestSchema $requestSchema
            $minimalBodyToSend = if ($requestSchema.IsArray) { , @($minimalBody) } else { $minimalBody }
            $tests += @{
                Name = "$method - minimal valid request"
                Method = $method
                Url = $urlWithParams
                ExpectedStatus = $successStatus
                Type = 'Functional'
                Body = $minimalBodyToSend
            }
            
            # All fields (sample data)
            $allFieldsBody = @{}
            $allPropNames = if ($requestSchema.Properties -is [hashtable]) {
                $requestSchema.Properties.Keys
            } else {
                $requestSchema.Properties.PSObject.Properties.Name
            }
            foreach ($propName in $allPropNames) {
                $allFieldsBody[$propName] = Get-SampleValue -Property $requestSchema.Properties.$propName
            }
            $allFieldsBodyToSend = if ($requestSchema.IsArray) { , @($allFieldsBody) } else { $allFieldsBody }
            
            # Build URL with ALL parameters (required + optional) for "all fields" test
            $urlWithAllParams = $url
            $allParams = $Contract.Parameters
            if ($allParams) {
                $paramStr = ($allParams | ForEach-Object { 
                    $value = if ($_.Enum) { $_.Enum[0] } elseif ($_.Type -eq 'integer') { 1 } else { 'test' }
                    "$($_.Name)=$value"
                }) -join '&'
                $urlWithAllParams = "$url`?$paramStr"
            }
            
            $tests += @{
                Name = "$method - all fields with valid data"
                Method = $method
                Url = $urlWithAllParams
                ExpectedStatus = $successStatus
                Type = 'Functional'
                Body = $allFieldsBodyToSend
            }
            
            Write-Host "   ✓ Generated 2 success tests" -ForegroundColor Green
        } else {
            # GET request with no body - just test the basic endpoint
            # Include required parameters if any
            $urlWithParams = $url
            $requiredParams = $Contract.Parameters | Where-Object { $_.Required }
            if ($requiredParams) {
                $paramStr = ($requiredParams | ForEach-Object { 
                    $value = if ($_.Enum) { $_.Enum[0] } elseif ($_.Type -eq 'integer') { 1 } else { 'test' }
                    "$($_.Name)=$value"
                }) -join '&'
                $urlWithParams = "$url`?$paramStr"
            }
            
            $tests += @{
                Name = "$method - valid request with required parameters"
                Method = $method
                Url = $urlWithParams
                ExpectedStatus = $successStatus
                Type = 'Functional'
                Body = $null
            }
            
            Write-Host "   ✓ Generated 1 success test" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    #endregion
    
    #region Malformed JSON Tests
    
    if ($IncludeMalformedJsonTests -and $method -in @('POST', 'PUT', 'PATCH')) {
        Write-Host "Malformed JSON Tests" -ForegroundColor Yellow
        
        # Test 1: Unclosed brace
        $tests += @{
            Name = "$method - malformed JSON: unclosed brace"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = '{ "field": "value"'
        }
        
        # Test 2: Unquoted key
        $tests += @{
            Name = "$method - malformed JSON: unquoted key"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = '{ key: "value" }'
        }
        
        # Test 3: Array when object expected
        $tests += @{
            Name = "$method - malformed JSON: array instead of object"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = '[1, 2, 3]'
        }
        
        # Test 4: Not JSON at all
        $tests += @{
            Name = "$method - malformed JSON: plain text"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = 'this is not json'
        }
        
        # Test 5: Empty string
        $tests += @{
            Name = "$method - malformed JSON: empty string"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = ''
        }
        
        # Test 6: Null bytes / invalid characters
        $tests += @{
            Name = "$method - malformed JSON: invalid characters"
            Method = $method
            Url = $url
            ExpectedStatus = 400
                Type = 'Contract'
            RawBody = '{ "field": "value' + [char]0x00 + '" }'
        }
        
        Write-Host "   ✓ Generated 6 malformed JSON tests" -ForegroundColor Green
        Write-Host ""
    }
    
    #endregion
    
    # Summary
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host "✅ Generated $($tests.Count) contract-driven tests" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Green
    Write-Host ""
    
    # Auto-generate output file name if not provided
    if (-not $OutputFile) {
        $methodLower = $Contract.Method.ToLower()
        # Extract resource name from path (e.g., /cashReceipts/{id} -> cashReceipts)
        $resourceName = if ($Contract.Path -match '/([^/]+)/\{') {
            # Has path parameter: /resource/{id}
            $matches[1]
        } elseif ($Contract.Path -match '/([^/]+)$') {
            # Ends with resource name: /resource
            $matches[1]
        } else {
            # Fallback: clean up the whole path
            $Contract.Path -replace '[{}/]', '-' -replace '--+', '-' -replace '^-|-$', ''
        }
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $OutputFile = "tests-$methodLower-$resourceName-$timestamp.ps1"
        Write-Host "Auto-generating output file: $OutputFile" -ForegroundColor Cyan
    }
    
    # Save to file
    if ($OutputFile) {
        $testStrings = $tests | ForEach-Object {
            $test = $_
            
            # Handle RawBody (for malformed JSON) or Body (for normal tests)
            if ($test.ContainsKey('RawBody')) {
                $bodyLiteral = "'$($test.RawBody -replace "'", "''")'"  # Escape single quotes
                $bodyProperty = "RawBody"
            } else {
                $bodyLiteral = ConvertTo-PowerShellLiteral -Object $test.Body
                $bodyProperty = "Body"
            }
            
            # Add ExpectedErrorCode if present
            $errorCodeLine = if ($test.ContainsKey('ExpectedErrorCode') -and $test.ExpectedErrorCode) {
                "`n        ExpectedErrorCode = '$($test.ExpectedErrorCode)'"
            } else { "" }
            
            # Build Type line
            $typeLine = if ($test.ContainsKey('Type')) {
                "`n        Type = '$($test.Type)'"
            } else { "" }
            
            @"
    @{
        Name = '$($test.Name)'
        Method = '$($test.Method)'
        Url = '$($test.Url)'
        ExpectedStatus = $($test.ExpectedStatus)$errorCodeLine$typeLine
        $bodyProperty = $bodyLiteral
    }
"@
        }
        
        $fileContent = @"
# Contract-driven tests for $($Contract.Method) $($Contract.Path)
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Schema: $($Contract.RequestSchema.SchemaName)
# Required Fields: $(if($requestSchema.Required.Count -gt 0){$requestSchema.Required -join ', '}else{'NONE'})
# Total Properties: $($requestSchema.Properties.Count)

@(
$($testStrings -join ",`n")
)
"@
        
        # Smart path detection: if just a filename, use default folder
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
        
        $fileContent | Set-Content -Path $outputPath -Encoding UTF8
        Write-Host "✓ Saved to: $outputPath" -ForegroundColor Green
        Write-Host ""
    }
    
    return $tests
}

#region Helper Functions

function Get-MinimalValidBody {
    param([object]$RequestSchema)
    
    $body = @{}
    
    if ($RequestSchema.Required -and $RequestSchema.Required.Count -gt 0) {
        # Include all required fields
        foreach ($req in $RequestSchema.Required) {
            $body[$req] = Get-SampleValue -Property $RequestSchema.Properties.$req
        }
    } else {
        # No required fields - pick first property
        $propNames = if ($RequestSchema.Properties -is [hashtable]) {
            $RequestSchema.Properties.Keys
        } else {
            $RequestSchema.Properties.PSObject.Properties.Name
        }
        $firstProp = $propNames | Select-Object -First 1
        if ($firstProp) {
            $body[$firstProp] = Get-SampleValue -Property $RequestSchema.Properties.$firstProp
        }
    }
    
    return $body
}

function Get-SampleValue {
    param([object]$Property)
    
    if (-not $Property) { return $null }
    
    # Handle enums
    if ($Property.Enum -and $Property.Enum.Count -gt 0) {
        return $Property.Enum[0]
    }
    
    # Handle types
    switch ($Property.Type) {
        'string' {
            # Check for datetime patterns (regex patterns with date AND time components)
            # Look for patterns with colons (time separator) AND dashes/slashes (date separator)
            if ($Property.Pattern -match ':' -and $Property.Pattern -match '(-|/)') {
                return '2025-01-15T10:30:00'
            }
            
            # Check Description field for format hints
            if ($Property.Description -match 'yyyy-MM-dd.*hh:mm:ss|datetime') {
                return '2025-01-15T10:30:00'
            }
            if ($Property.Description -match 'yyyy-MM-dd|date') {
                return '2025-01-15'
            }
            
            # Check for date-only patterns (has date separators but no time separators)
            if ($Property.Pattern -match '(-|/)' -and $Property.Pattern -notmatch ':') {
                return '2025-01-15'
            }
            
            # Check for time-only patterns (has colons but no date separators)
            if ($Property.Pattern -match ':' -and $Property.Pattern -notmatch '(-|/)') {
                return '10:30:00'
            }
            
            # Regular string - respect maxLength
            if ($Property.MaxLength) {
                # Generate a string that fits within maxLength
                $maxLen = [Math]::Min($Property.MaxLength, 10)
                $value = 'A' * $maxLen
            } else {
                $value = 'TestValue'
            }
            return $value
        }
        'number' {
            if ($null -ne $Property.Minimum) { return $Property.Minimum + 1 }
            return 100.0
        }
        'integer' {
            if ($null -ne $Property.Minimum) { return $Property.Minimum + 1 }
            return 1
        }
        'boolean' {
            return $true
        }
        'array' {
            return @()
        }
        default {
            return $null
        }
    }
}

function ConvertTo-PowerShellLiteral {
    param([object]$Object)
    
    if ($Object -is [array]) {
        if ($Object.Count -eq 0) {
            return "@()"
        }
        
        $items = $Object | ForEach-Object {
            ConvertTo-PowerShellLiteral -Object $_
        }
        return "@($($items -join ', '))"
    }
    
    if ($Object -is [hashtable] -or $Object -is [PSCustomObject]) {
        $props = @()
        
        if ($Object -is [hashtable]) {
            $keys = $Object.Keys
        } else {
            $keys = $Object.PSObject.Properties.Name
        }
        
        foreach ($key in $keys) {
            $value = if ($Object -is [hashtable]) { $Object[$key] } else { $Object.$key }
            $valueStr = ConvertTo-PowerShellLiteral -Object $value
            $props += "$key = $valueStr"
        }
        
        return "@{ $($props -join '; ') }"
    }
    
    if ($Object -is [string]) {
        return "'$($Object -replace "'", "''")'"
    }
    
    if ($Object -is [bool]) {
        return if ($Object) { '$true' } else { '$false' }
    }
    
    if ($null -eq $Object) {
        return '$null'
    }
    
    return $Object.ToString()
}

#endregion

