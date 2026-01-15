function Get-OpenApiEndpoints {
    <#
    .SYNOPSIS
        Extract all available endpoints and methods from an OpenAPI specification file
    
    .DESCRIPTION
        Parses an OpenAPI/Swagger JSON file and returns a list of all available
        API endpoints with their HTTP methods, summaries, and operation IDs.
        
        This function bridges the gap between downloading the spec and analyzing
        specific endpoints - use it to discover what's available before running
        Analyze-OpenApiSchema.
    
    .PARAMETER SpecFile
        Path to the OpenAPI specification JSON file
    
    .PARAMETER Method
        Optional filter to show only specific HTTP methods (GET, POST, PUT, DELETE, PATCH)
    
    .PARAMETER Path
        Optional regex pattern to filter paths (e.g., "status$" to find paths ending in 'status')
    
    .PARAMETER SchemaName
        Optional. Find all endpoints that reference a specific schema name (supports regex).
        Searches request bodies and responses for the schema.
        Useful for finding where a schema is used across the API.
        Examples: "cashReceipt" (partial), "^invoice$" (exact), "invoice.*201" (pattern)
    
    .PARAMETER OutputFormat
        Output format: 'Table' (default), 'List', or 'Object'
    
    .PARAMETER OutputFile
        Optional path to save the endpoint list as JSON
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi-visibility.json"
        # Lists all endpoints in table format
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi-finance.json" -Method POST
        # Shows only POST endpoints
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi.json" -Path "status$"
        # Shows only endpoints where path ends with 'status'
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi.json" -Method POST -Path "/fuel"
        # Shows only POST endpoints with '/fuel' in the path
    
    .EXAMPLE
        $endpoints = Get-OpenApiEndpoints -SpecFile "openapi.json" -OutputFormat Object
        # Returns endpoints as PowerShell objects for programmatic use
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi.json" -OutputFile "endpoints.json"
        # Saves endpoint list to JSON file
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "finance-openapi-*.json" -SchemaName "CashReceiptsPostCashReceiptInvoices201"
        # Find all endpoints that use the exact schema name
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "finance-openapi-*.json" -SchemaName "invoice"
        # Find all endpoints with schemas containing "invoice" (regex partial match)
    
    .EXAMPLE
        Get-OpenApiEndpoints -SpecFile "openapi.json" -SchemaName "barcode" -OutputFormat Object
        # Get endpoints using barcode schema as objects for programmatic use
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SpecFile,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method,
        
        [ArgumentCompleter({ @("'^/[^/{}]+$'") })]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$SchemaName,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Table', 'List', 'Object')]
        [string]$OutputFormat = 'Table',
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile
    )
    
    # Smart input path detection
    $specPath = if (Test-Path $SpecFile) {
        $SpecFile
    } elseif ($SpecFile -notmatch '[\\/]') {
        # Just a filename - try default folder
        $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
        $defaultPath = Join-Path $moduleRoot "10-openapi-specs" $SpecFile
        if (Test-Path $defaultPath) {
            $defaultPath
        } else {
            Write-Error "OpenAPI spec file not found: $SpecFile (tried current dir and 10-openapi-specs/)"
            return
        }
    } else {
        Write-Error "OpenAPI spec file not found: $SpecFile"
        return
    }
    
    # Load the OpenAPI spec
    Write-Host "Loading OpenAPI specification..." -ForegroundColor Cyan
    Write-Host "  File: $specPath" -ForegroundColor Gray
    
    $spec = Get-Content $specPath | ConvertFrom-Json -AsHashtable
    
    Write-Host "✓ Loaded spec: $($spec['info']['title']) v$($spec['info']['version'])" -ForegroundColor Green
    Write-Host ""
    
    # Extract all endpoints
    $endpoints = @()
    $httpMethods = @('get', 'post', 'put', 'delete', 'patch')
    
    foreach ($pathValue in $spec['paths'].Keys) {
        $pathObj = $spec['paths'][$pathValue]
        
        # Apply path regex filter if specified
        if ($Path -and $pathValue -notmatch $Path) {
            continue
        }
        
        foreach ($httpMethod in $httpMethods) {
            if ($pathObj.Keys -contains $httpMethod) {
                $operation = $pathObj[$httpMethod]
                
                # Apply method filter if specified
                if ($Method -and $httpMethod.ToUpper() -ne $Method.ToUpper()) {
                    continue
                }
                
                # Apply schema name filter if specified (supports regex)
                if ($SchemaName) {
                    $schemaFound = $false
                    $schemaLocation = @()  # Track where schema was found
                    
                    # Helper to extract schema name from $ref and check if it matches pattern
                    $matchesSchema = {
                        param($ref)
                        if ($ref -match '/([^/]+)$') {
                            $extractedName = $matches[1]
                            return $extractedName -match $SchemaName
                        }
                        return $false
                    }
                    
                    # Check request body for schema reference
                    if ($operation['requestBody'] -and $operation['requestBody']['content']) {
                        foreach ($contentType in $operation['requestBody']['content'].Keys) {
                            $schema = $operation['requestBody']['content'][$contentType]['schema']
                            if ($schema) {
                                # Check direct $ref
                                if ($schema.'$ref' -and (& $matchesSchema $schema.'$ref')) {
                                    $schemaFound = $true
                                    if ($schemaLocation -notcontains 'Request') {
                                        $schemaLocation += 'Request'
                                    }
                                    break
                                }
                                # Check array items $ref
                                if ($schema['type'] -eq 'array' -and $schema['items'] -and $schema['items'].'$ref' -and (& $matchesSchema $schema['items'].'$ref')) {
                                    $schemaFound = $true
                                    if ($schemaLocation -notcontains 'Request') {
                                        $schemaLocation += 'Request'
                                    }
                                    break
                                }
                            }
                        }
                    }
                    
                    # Check response bodies for schema reference (even if found in request)
                    if ($operation['responses']) {
                        foreach ($responseCode in $operation['responses'].Keys) {
                            $response = $operation['responses'][$responseCode]
                            if ($response['content']) {
                                foreach ($contentType in $response['content'].Keys) {
                                    $schema = $response['content'][$contentType]['schema']
                                    if ($schema) {
                                        # Check direct $ref
                                        if ($schema.'$ref' -and (& $matchesSchema $schema.'$ref')) {
                                            $schemaFound = $true
                                            if ($schemaLocation -notcontains 'Response') {
                                                $schemaLocation += 'Response'
                                            }
                                            break
                                        }
                                        # Check array items $ref
                                        if ($schema['type'] -eq 'array' -and $schema['items'] -and $schema['items'].'$ref' -and (& $matchesSchema $schema['items'].'$ref')) {
                                            $schemaFound = $true
                                            if ($schemaLocation -notcontains 'Response') {
                                                $schemaLocation += 'Response'
                                            }
                                            break
                                        }
                                        # Check object properties $ref (for nested schemas)
                                        if ($schema['properties']) {
                                            foreach ($propName in $schema['properties'].Keys) {
                                                $prop = $schema['properties'][$propName]
                                                if ($prop.'$ref' -and (& $matchesSchema $prop.'$ref')) {
                                                    $schemaFound = $true
                                                    if ($schemaLocation -notcontains 'Response') {
                                                        $schemaLocation += 'Response'
                                                    }
                                                    break
                                                }
                                                # Check array properties
                                                if ($prop['type'] -eq 'array' -and $prop['items'] -and $prop['items'].'$ref' -and (& $matchesSchema $prop['items'].'$ref')) {
                                                    $schemaFound = $true
                                                    if ($schemaLocation -notcontains 'Response') {
                                                        $schemaLocation += 'Response'
                                                    }
                                                    break
                                                }
                                            }
                                            if ($schemaFound) { break }
                                        }
                                    }
                                }
                                if ($schemaFound) { break }
                            }
                        }
                    }
                    
                    # Skip if schema not found
                    if (-not $schemaFound) {
                        continue
                    }
                }
                
                $endpoint = [PSCustomObject]@{
                    Method = $httpMethod.ToUpper()
                    Path = $pathValue
                    OperationId = $operation['operationId']
                    Summary = $operation['summary']
                    Description = $operation['description']
                    Tags = if ($operation['tags']) { ($operation['tags'] -join ', ') } else { '' }
                    HasRequestBody = ($null -ne $operation['requestBody'])
                    ResponseCodes = if ($operation['responses']) { ($operation['responses'].Keys -join ', ') } else { '' }
                    SchemaUsage = if ($SchemaName -and $schemaLocation.Count -gt 0) { ($schemaLocation -join ', ') } else { '' }
                }
                
                $endpoints += $endpoint
            }
        }
    }
    
    Write-Host "Found $($endpoints.Count) endpoint(s)" -ForegroundColor Cyan
    
    if ($Method) {
        Write-Host "  Filtered by method: $Method" -ForegroundColor Gray
    }
    
    if ($Path) {
        Write-Host "  Filtered by path regex: $Path" -ForegroundColor Gray
    }
    
    if ($SchemaName) {
        Write-Host "  Filtered by schema name: $SchemaName" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Save to file if requested
    if ($OutputFile) {
        # Smart path detection: if just a filename, use default folder
        $outputPath = if ($OutputFile -notmatch '[\\/]') {
            $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
            $endpointsFolder = Join-Path $moduleRoot "20-openapi-endpoints"
            if (-not (Test-Path $endpointsFolder)) {
                New-Item -ItemType Directory -Path $endpointsFolder -Force | Out-Null
            }
            Join-Path $endpointsFolder $OutputFile
        } else {
            $OutputFile
        }
        
        $endpoints | ConvertTo-Json -Depth 10 | Out-File $outputPath
        Write-Host "✓ Endpoint list saved to: $outputPath" -ForegroundColor Green
        Write-Host ""
    }
    
    # Output in requested format
    switch ($OutputFormat) {
        'Table' {
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host "AVAILABLE ENDPOINTS" -ForegroundColor Cyan
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host ""
            
            # If filtering by schema, include SchemaUsage column
            if ($SchemaName) {
                $endpoints | Format-Table @(
                    @{Label='Method'; Expression={$_.Method}; Width=8}
                    @{Label='Path'; Expression={$_.Path}; Width=40}
                    @{Label='Operation'; Expression={$_.OperationId}; Width=25}
                    @{Label='Summary'; Expression={$_.Summary}; Width=25}
                    @{Label='Schema In'; Expression={$_.SchemaUsage}; Width=15}
                ) -Wrap
            } else {
                $endpoints | Format-Table Method, Path, OperationId, Summary -AutoSize
            }
        }
        
        'List' {
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host "AVAILABLE ENDPOINTS" -ForegroundColor Cyan
            Write-Host ("=" * 120) -ForegroundColor Gray
            Write-Host ""
            
            foreach ($endpoint in $endpoints) {
                Write-Host "$($endpoint.Method) $($endpoint.Path)" -ForegroundColor Yellow
                if ($endpoint.Summary) {
                    Write-Host "  Summary: $($endpoint.Summary)" -ForegroundColor Gray
                }
                if ($endpoint.Description) {
                    Write-Host "  Description: $($endpoint.Description)" -ForegroundColor Gray
                }
                if ($endpoint.OperationId) {
                    Write-Host "  Operation: $($endpoint.OperationId)" -ForegroundColor Gray
                }
                if ($endpoint.Tags) {
                    Write-Host "  Tags: $($endpoint.Tags)" -ForegroundColor Gray
                }
                Write-Host "  Request Body: $(if ($endpoint.HasRequestBody) { 'Yes' } else { 'No' })" -ForegroundColor Gray
                Write-Host "  Responses: $($endpoint.ResponseCodes)" -ForegroundColor Gray
                Write-Host ""
            }
        }
        
        'Object' {
            # Return the objects for programmatic use
            return $endpoints
        }
    }
}

