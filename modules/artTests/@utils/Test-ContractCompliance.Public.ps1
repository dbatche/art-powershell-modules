function Test-ContractCompliance {
    <#
    .SYNOPSIS
    Validates an API response against an OpenAPI schema specification
    
    .DESCRIPTION
    Performs comprehensive validation of API response data against OpenAPI schema definitions:
    - Required fields presence
    - Data type validation
    - Constraint validation (minLength, maxLength, pattern, enum, min/max)
    - Nested object and array validation
    - Read-only field detection in requests
    
    .PARAMETER Response
    The API response object (already parsed from JSON)
    
    .PARAMETER Schema
    The OpenAPI schema definition (from Analyze-OpenApiSchema.Public.ps1)
    Can be a full schema object with properties, or a simplified hashtable
    
    .PARAMETER IsRequest
    If true, validates a request body (checks for read-only fields)
    If false (default), validates a response body
    
    .PARAMETER ShowDetails
    If true, shows detailed validation information for each field
    
    .OUTPUTS
    Returns a validation result object with:
    - IsValid: Boolean indicating overall compliance
    - Errors: Array of validation errors
    - Warnings: Array of warnings (e.g., extra fields not in schema)
    - FieldCount: Number of fields validated
    - Summary: Human-readable summary
    
    .EXAMPLE
    $response = @{ tripFuelPurchaseId = 123; fuelTaxId = 2; receipt = "True" }
    $schema = @{
        properties = @{
            tripFuelPurchaseId = @{ type = 'integer'; readOnly = $true }
            fuelTaxId = @{ type = 'integer'; required = $true }
            receipt = @{ type = 'string'; required = $true }
        }
    }
    Test-ContractCompliance -Response $response -Schema $schema
    
    .EXAMPLE
    # Validate from test log
    $log = Get-Content "test-results.json" | ConvertFrom-Json
    $result = $log.Results[0]
    $response = $result.Body | ConvertFrom-Json
    Test-ContractCompliance -Response $response -Schema $schemaDefinition
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [object]$Response,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Schema,
        
        [switch]$IsRequest,
        [switch]$ShowDetails
    )
    
    $errors = @()
    $warnings = @()
    $fieldsValidated = 0
    
    # Helper function to validate a single field
    function Test-Field {
        param(
            [string]$FieldName,
            [object]$Value,
            [hashtable]$FieldSchema,
            [string]$Path = ""
        )
        
        $fullPath = if ($Path) { "$Path.$FieldName" } else { $FieldName }
        $fieldErrors = @()
        $fieldWarnings = @()
        
        if ($ShowDetails) {
            Write-Host "    Checking: $fullPath" -ForegroundColor DarkGray
        }
        
        # Check if value is null/empty
        $isNull = $null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value))
        
        # Required field check
        if ($FieldSchema.Required -and $isNull) {
            $fieldErrors += "Required field '$fullPath' is missing or empty"
        }
        
        # Skip further validation if value is null and not required
        if ($isNull -and -not $FieldSchema.Required) {
            return @{ Errors = $fieldErrors; Warnings = $fieldWarnings }
        }
        
        # Type validation
        $expectedType = $FieldSchema.Type
        $actualType = if ($null -ne $Value) { $Value.GetType().Name } else { "null" }
        
        switch ($expectedType) {
            'string' {
                if ($Value -isnot [string]) {
                    $fieldErrors += "Field '$fullPath' should be string, got $actualType"
                } else {
                    # String constraints
                    if ($FieldSchema.MinLength -and $Value.Length -lt $FieldSchema.MinLength) {
                        $fieldErrors += "Field '$fullPath' length ($($Value.Length)) is less than minLength ($($FieldSchema.MinLength))"
                    }
                    if ($FieldSchema.MaxLength -and $Value.Length -gt $FieldSchema.MaxLength) {
                        $fieldErrors += "Field '$fullPath' length ($($Value.Length)) exceeds maxLength ($($FieldSchema.MaxLength))"
                    }
                    if ($FieldSchema.Pattern -and $Value -notmatch $FieldSchema.Pattern) {
                        $fieldErrors += "Field '$fullPath' does not match pattern: $($FieldSchema.Pattern)"
                    }
                    if ($FieldSchema.Enum -and $Value -notin $FieldSchema.Enum) {
                        $fieldErrors += "Field '$fullPath' value '$Value' not in allowed enum: $($FieldSchema.Enum -join ', ')"
                    }
                }
            }
            'integer' {
                if ($Value -isnot [int] -and $Value -isnot [long] -and $Value -isnot [int32] -and $Value -isnot [int64]) {
                    # Try to parse as integer
                    $intValue = 0
                    if (-not [int]::TryParse($Value, [ref]$intValue)) {
                        $fieldErrors += "Field '$fullPath' should be integer, got $actualType with value '$Value'"
                    } else {
                        $Value = $intValue
                    }
                }
                
                # Numeric constraints
                if ($FieldSchema.Minimum -and $Value -lt $FieldSchema.Minimum) {
                    $fieldErrors += "Field '$fullPath' value ($Value) is less than minimum ($($FieldSchema.Minimum))"
                }
                if ($FieldSchema.Maximum -and $Value -gt $FieldSchema.Maximum) {
                    $fieldErrors += "Field '$fullPath' value ($Value) exceeds maximum ($($FieldSchema.Maximum))"
                }
            }
            'number' {
                if ($Value -isnot [double] -and $Value -isnot [float] -and $Value -isnot [decimal] -and $Value -isnot [int]) {
                    # Try to parse as number
                    $numValue = 0.0
                    if (-not [double]::TryParse($Value, [ref]$numValue)) {
                        $fieldErrors += "Field '$fullPath' should be number, got $actualType with value '$Value'"
                    } else {
                        $Value = $numValue
                    }
                }
                
                # Numeric constraints
                if ($FieldSchema.Minimum -and $Value -lt $FieldSchema.Minimum) {
                    $fieldErrors += "Field '$fullPath' value ($Value) is less than minimum ($($FieldSchema.Minimum))"
                }
                if ($FieldSchema.Maximum -and $Value -gt $FieldSchema.Maximum) {
                    $fieldErrors += "Field '$fullPath' value ($Value) exceeds maximum ($($FieldSchema.Maximum))"
                }
            }
            'boolean' {
                if ($Value -isnot [bool]) {
                    # Check if it's a string representation
                    if ($Value -is [string]) {
                        if ($Value -notin @('true', 'false', 'True', 'False')) {
                            $fieldErrors += "Field '$fullPath' should be boolean, got string '$Value'"
                        }
                    } else {
                        $fieldErrors += "Field '$fullPath' should be boolean, got $actualType"
                    }
                }
            }
            'array' {
                if ($Value -isnot [array] -and $Value -isnot [System.Collections.IEnumerable]) {
                    $fieldErrors += "Field '$fullPath' should be array, got $actualType"
                } else {
                    # Validate array items if schema provided
                    if ($FieldSchema.Items) {
                        $index = 0
                        foreach ($item in $Value) {
                            $itemResult = Test-Field -FieldName "[$index]" -Value $item -FieldSchema $FieldSchema.Items -Path $fullPath
                            $fieldErrors += $itemResult.Errors
                            $fieldWarnings += $itemResult.Warnings
                            $index++
                        }
                    }
                }
            }
            'object' {
                if ($Value -isnot [hashtable] -and $Value -isnot [PSCustomObject]) {
                    $fieldErrors += "Field '$fullPath' should be object, got $actualType"
                } else {
                    # Validate nested object properties
                    if ($FieldSchema.Properties) {
                        foreach ($propName in $FieldSchema.Properties.Keys) {
                            $propSchema = $FieldSchema.Properties[$propName]
                            $propValue = if ($Value -is [hashtable]) { $Value[$propName] } else { $Value.$propName }
                            $propResult = Test-Field -FieldName $propName -Value $propValue -FieldSchema $propSchema -Path $fullPath
                            $fieldErrors += $propResult.Errors
                            $fieldWarnings += $propResult.Warnings
                        }
                    }
                }
            }
        }
        
        # Read-only field check (for requests)
        if ($IsRequest -and $FieldSchema.ReadOnly -and -not $isNull) {
            $fieldWarnings += "Field '$fullPath' is read-only and should not be included in requests"
        }
        
        return @{
            Errors = $fieldErrors
            Warnings = $fieldWarnings
        }
    }
    
    # Main validation logic
    Write-Host "`nValidating $($IsRequest ? 'request' : 'response') against schema..." -ForegroundColor Cyan
    
    # Handle both direct properties and nested schema structure
    $properties = if ($Schema.properties) { $Schema.properties } else { $Schema }
    
    if (-not $properties -or $properties.Count -eq 0) {
        Write-Host "  ⚠ No schema properties provided for validation" -ForegroundColor Yellow
        return @{
            IsValid = $true
            Errors = @()
            Warnings = @("No schema properties to validate against")
            FieldCount = 0
            Summary = "No validation performed (empty schema)"
        }
    }
    
    # Convert response to hashtable if it's PSCustomObject
    $responseHash = @{}
    if ($Response -is [PSCustomObject]) {
        $Response.PSObject.Properties | ForEach-Object {
            $responseHash[$_.Name] = $_.Value
        }
    } elseif ($Response -is [hashtable]) {
        $responseHash = $Response
    } else {
        $errors += "Response must be a hashtable or PSCustomObject, got $($Response.GetType().Name)"
        return @{
            IsValid = $false
            Errors = $errors
            Warnings = @()
            FieldCount = 0
            Summary = "Invalid response type"
        }
    }
    
    # Validate each field in the schema
    foreach ($fieldName in $properties.Keys) {
        $fieldSchema = $properties[$fieldName]
        $fieldValue = $responseHash[$fieldName]
        
        $fieldResult = Test-Field -FieldName $fieldName -Value $fieldValue -FieldSchema $fieldSchema
        $errors += $fieldResult.Errors
        $warnings += $fieldResult.Warnings
        $fieldsValidated++
    }
    
    # Check for extra fields not in schema
    foreach ($fieldName in $responseHash.Keys) {
        if (-not $properties.ContainsKey($fieldName)) {
            $warnings += "Field '$fieldName' in response is not defined in schema"
        }
    }
    
    # Build result
    $isValid = $errors.Count -eq 0
    
    $result = @{
        IsValid = $isValid
        Errors = $errors
        Warnings = $warnings
        FieldCount = $fieldsValidated
        Summary = if ($isValid) {
            "✅ Valid: $fieldsValidated fields validated, $($warnings.Count) warnings"
        } else {
            "❌ Invalid: $($errors.Count) errors, $($warnings.Count) warnings"
        }
    }
    
    # Display results
    Write-Host ""
    Write-Host $result.Summary -ForegroundColor $(if ($isValid) { 'Green' } else { 'Red' })
    
    if ($errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  ❌ $_" -ForegroundColor Red }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor Yellow }
    }
    
    return $result
}

