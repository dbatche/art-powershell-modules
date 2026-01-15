function Analyze-OpenApiSchema {
    <#
    .SYNOPSIS
    Analyzes OpenAPI schema for a specific endpoint and method.
    
    .DESCRIPTION
    Reads OpenAPI spec from file, resolves $ref references, and extracts
    detailed schema information including required fields, types, constraints,
    and validation rules for both request and response schemas.
    
    .PARAMETER SpecFile
    Path to the OpenAPI JSON specification file (use Get-OpenApiSpecFromUrl to download).
    
    .PARAMETER Path
    The API path to analyze (e.g., '/fuelTaxes/{fuelTaxId}/tripFuelPurchases').
    Required unless -SchemaName is specified.
    
    .PARAMETER Method
    The HTTP method to analyze (GET, POST, PUT, PATCH, DELETE).
    Required unless -SchemaName is specified.
    
    .PARAMETER SchemaName
    Optional. Analyze a schema directly from components/schemas by name.
    When specified, -Path and -Method are not required.
    Useful for looking up schema details without knowing which endpoint uses it.
    
    .PARAMETER OutputFormat
        Output format: 
        - 'List' (default, detailed text with all properties)
        - 'Table' (compact table format with visual headers)
        - 'Object' (silent, returns object for pipeline)
    
    .PARAMETER OutputFile
    Optional path to save the contract analysis as JSON.
    
    .EXAMPLE
    # Analyze POST endpoint
    $contract = Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/items" -Method "POST"
    
    .EXAMPLE
    # Analyze a schema directly by name
    Analyze-OpenApiSchema -SpecFile "finance-openapi-*.json" -SchemaName "cashReceiptInvoices" -OutputFormat Table
    
    .EXAMPLE
    # Find schema details without knowing endpoint
    Analyze-OpenApiSchema -SpecFile "openapi.json" -SchemaName "OrderBarCodesRequest" -OutputFormat List
    
    .EXAMPLE
    # Analyze and save contract
    $contract = Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/items" -Method "POST" -OutputFile "contract.json"
    
    .EXAMPLE
    # Check required fields
    $contract = Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/items" -Method "POST"
    if ($contract.RequestSchema.Required.Count -eq 0) {
        Write-Host "⚠ No required fields!" -ForegroundColor Yellow
    }
    
    .EXAMPLE
    # Pipeline from Get-OpenApiEndpoints (silent object mode)
    Get-OpenApiEndpoints -SpecFile "openapi.json" -Method POST -OutputFormat Object | 
        Analyze-OpenApiSchema -SpecFile "openapi.json" -OutputFormat Object
    
    .EXAMPLE
    # Pipeline with filtering (analyze fuel-related endpoints)
    Get-OpenApiEndpoints -SpecFile "openapi.json" -Path "fuel" -OutputFormat Object | 
        Analyze-OpenApiSchema -SpecFile "openapi.json" -OutputFormat Object |
        ForEach-Object { 
            Write-Host "$($_.Method) $($_.Path): $($_.RequestSchema.Required.Count) required fields"
        }
    
    .EXAMPLE
    # List format (default) - shows detailed analysis, no object return
    Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/items" -Method "POST"
    
    .EXAMPLE
    # Object format - silent mode for pipeline
    $contract = Analyze-OpenApiSchema -SpecFile "openapi.json" -Path "/items" -Method "POST" -OutputFormat Object
    
    .OUTPUTS
    PSCustomObject with properties:
    - Path: API path
    - Method: HTTP method
    - OperationId: OpenAPI operation identifier
    - Summary: Operation summary
    - Description: Operation description
    - RequestSchema: Request body schema (IsArray, Required, Properties, SchemaName)
    - ResponseSchemas: Response schemas by status code
    - Parameters: Path/query parameters
    
    .NOTES
    Part of the contract testing framework. Use with Get-OpenApiSpecFromUrl.
    #>
    [CmdletBinding(DefaultParameterSetName='ByEndpoint')]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SpecFile,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByEndpoint')]
        [string]$Path,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='ByEndpoint')]
        [string]$Method,
        
        [Parameter(Mandatory=$true, ParameterSetName='BySchemaName')]
        [string]$SchemaName,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('List', 'Table', 'Object')]
        [string]$OutputFormat = 'List',
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile
    )
    
    begin {
        # Smart input path detection
        $specPath = if (Test-Path $SpecFile) {
            $SpecFile
        } elseif ($SpecFile -notmatch '[\\/]') {
            # Just a filename - try default folder
            $moduleRoot = $global:ArtTestsModuleRoot ?? $PSScriptRoot
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
        
        # Load spec once at the beginning (not for each piped object)
        if ($OutputFormat -eq 'List') {
            Write-Host "Loading OpenAPI specification from file..." -ForegroundColor Cyan
            Write-Host "  File: $specPath" -ForegroundColor Gray
        }
        
        $script:spec = Get-Content $specPath | ConvertFrom-Json -AsHashtable
        
        if ($OutputFormat -eq 'List') {
            Write-Host "✓ Loaded spec: $($script:spec['info']['title']) v$($script:spec['info']['version'])" -ForegroundColor Green
            Write-Host ""
        }
    }
    
    process {
        # Use the spec loaded in begin block
        $spec = $script:spec
        
        # Handle schema name lookup (direct schema analysis)
        if ($PSCmdlet.ParameterSetName -eq 'BySchemaName') {
            if ($OutputFormat -eq 'List' -or $OutputFormat -eq 'Table') {
                Write-Host "Analyzing schema: $SchemaName" -ForegroundColor Yellow
                Write-Host ""
            }
            
            # Check if schema exists
            if (-not $spec['components'] -or -not $spec['components']['schemas'] -or -not $spec['components']['schemas'][$SchemaName]) {
                Write-Host "❌ Schema not found: $SchemaName" -ForegroundColor Red
                Write-Host ""
                Write-Host "Available schemas:" -ForegroundColor Yellow
                if ($spec['components']['schemas']) {
                    $spec['components']['schemas'].Keys | Sort-Object | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  (No schemas defined in spec)" -ForegroundColor Gray
                }
                throw "Schema not found: $SchemaName"
            }
            
            # Resolve helpers first (needed for schema analysis)
            $resolveRef = {
                param([object]$Schema, [object]$RootSpec)
                
                if ($Schema.'$ref') {
                    $refPath = $Schema.'$ref' -replace '#/', '' -split '/'
                    $resolved = $RootSpec
                    foreach ($part in $refPath) {
                        $resolved = $resolved[$part]
                    }
                    return $resolved
                }
                return $Schema
            }
            
            $getProperties = {
                param([object]$Schema, [object]$RootSpec, [scriptblock]$ResolveRef)
                
                $resolved = & $ResolveRef $Schema $RootSpec
                
                $properties = @{}
                
                if ($resolved['properties']) {
                    foreach ($propName in $resolved['properties'].Keys) {
                        $prop = $resolved['properties'][$propName]
                        $propResolved = & $ResolveRef $prop $RootSpec
                        
                        $properties[$propName] = @{
                            Name = $propName
                            Type = $propResolved['type']
                            Format = $propResolved['format']
                            Description = $propResolved['description']
                            MinLength = $propResolved['minLength']
                            MaxLength = $propResolved['maxLength']
                            Minimum = $propResolved['minimum']
                            Maximum = $propResolved['maximum']
                            Pattern = $propResolved['pattern']
                            Enum = $propResolved['enum']
                            Nullable = $propResolved['nullable']
                            Default = $propResolved['default']
                            Deprecated = $propResolved['deprecated']
                            ReadOnly = $propResolved['readOnly']
                            WriteOnly = $propResolved['writeOnly']
                        }
                    }
                }
                
                return $properties
            }
            
            # Get the schema
            $schemaObj = $spec['components']['schemas'][$SchemaName]
            $resolvedSchema = & $resolveRef $schemaObj $spec
            
            # Determine if it's an array schema
            $isArray = $resolvedSchema['type'] -eq 'array'
            $itemSchema = if ($isArray) {
                & $resolveRef $resolvedSchema['items'] $spec
            } else {
                $resolvedSchema
            }
            
            # Extract properties
            $properties = & $getProperties $itemSchema $spec $resolveRef
            $required = $itemSchema['required']
            if (-not $required) { $required = @() }
            
            # Display schema details
            if ($OutputFormat -eq 'Table') {
                $headerText = "📋 Schema: $SchemaName"
                $boxWidth = [Math]::Max($headerText.Length + 2, 80)
                Write-Host ""
                Write-Host ("═" * $boxWidth) -ForegroundColor Cyan
                Write-Host $headerText -ForegroundColor White
                Write-Host ("═" * $boxWidth) -ForegroundColor Cyan
                Write-Host ""
                if ($resolvedSchema['description']) {
                    Write-Host "$($resolvedSchema['description'])" -ForegroundColor White
                    Write-Host ""
                }
                
                Write-Host "=== PROPERTIES ===" -ForegroundColor Cyan
                Write-Host ""
                
                if ($properties.Count -gt 0) {
                    $properties.Values |
                        Select-Object Name,
                                    @{L='Required';E={$required -contains $_.Name}},
                                    Type, Nullable, MaxLength, MinLength, Pattern,
                                    @{L='Enum';E={if($_.Enum){$_.Enum -join ', '}else{''}}} |
                        Format-Table -Property Name, Required, Type, Nullable, MaxLength, MinLength, Pattern, Enum -Wrap
                } else {
                    Write-Host "  (No properties defined)" -ForegroundColor Gray
                }
            }
            elseif ($OutputFormat -eq 'List') {
                Write-Host "Schema Name: $SchemaName" -ForegroundColor Cyan
                if ($resolvedSchema['description']) {
                    Write-Host "Description: $($resolvedSchema['description'])" -ForegroundColor Gray
                }
                Write-Host "Type: $(if ($isArray) { 'array' } else { $resolvedSchema['type'] })" -ForegroundColor Gray
                Write-Host ""
                
                if ($properties.Count -gt 0) {
                    Write-Host "Properties:" -ForegroundColor Yellow
                    foreach ($prop in $properties.Values) {
                        $requiredMark = if ($required -contains $prop.Name) { "*" } else { "" }
                        Write-Host "  $($prop.Name)$requiredMark" -ForegroundColor White
                        Write-Host "    Type: $($prop.Type)" -ForegroundColor Gray
                        if ($prop.Description) { Write-Host "    Description: $($prop.Description)" -ForegroundColor Gray }
                        if ($prop.MaxLength) { Write-Host "    MaxLength: $($prop.MaxLength)" -ForegroundColor Gray }
                        if ($prop.MinLength) { Write-Host "    MinLength: $($prop.MinLength)" -ForegroundColor Gray }
                        if ($prop.Pattern) { Write-Host "    Pattern: $($prop.Pattern)" -ForegroundColor Gray }
                        if ($prop.Enum) { Write-Host "    Enum: $($prop.Enum -join ', ')" -ForegroundColor Gray }
                        if ($prop.Nullable) { Write-Host "    Nullable: $($prop.Nullable)" -ForegroundColor Gray }
                        if ($prop.Default) { Write-Host "    Default: $($prop.Default)" -ForegroundColor Gray }
                        Write-Host ""
                    }
                } else {
                    Write-Host "  (No properties defined)" -ForegroundColor Gray
                }
            }
            
            # Return object for pipeline
            if ($OutputFormat -eq 'Object' -or $OutputFile) {
                $result = [PSCustomObject]@{
                    SchemaName = $SchemaName
                    Type = if ($isArray) { 'array' } else { $resolvedSchema['type'] }
                    Description = $resolvedSchema['description']
                    Required = $required
                    Properties = $properties
                    IsArray = $isArray
                }
                
                if ($OutputFile) {
                    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
                    Write-Host "✓ Saved schema analysis to: $OutputFile" -ForegroundColor Green
                }
                
                if ($OutputFormat -eq 'Object') {
                    return $result
                }
            }
            
            return
        }
        
        # ENDPOINT ANALYSIS MODE (original code)
        if ($OutputFormat -eq 'List') {
            Write-Host "Analyzing: $Method $Path" -ForegroundColor Yellow
            Write-Host ""
        }
        
        # Nested helper: Resolve $ref references
        $resolveRef = {
        param([object]$Schema, [object]$RootSpec)
        
        if ($Schema.'$ref') {
            # Parse reference path (e.g., "#/components/schemas/TripFuelPurchaseDto")
            $refPath = $Schema.'$ref' -replace '#/', '' -split '/'
            
            $resolved = $RootSpec
            foreach ($part in $refPath) {
                $resolved = $resolved[$part]
            }
            
            return $resolved
        }
        
        return $Schema
    }
    
    # Nested helper: Extract property details
    $getProperties = {
        param([object]$Schema, [object]$RootSpec, [scriptblock]$ResolveRef)
        
        $resolved = & $ResolveRef $Schema $RootSpec
        
        $properties = @{}
        
        if ($resolved['properties']) {
            foreach ($propName in $resolved['properties'].Keys) {
                $prop = $resolved['properties'][$propName]
                $propResolved = & $ResolveRef $prop $RootSpec
                
                $properties[$propName] = @{
                    Name = $propName
                    Type = $propResolved['type']
                    Format = $propResolved['format']
                    Description = $propResolved['description']
                    MinLength = $propResolved['minLength']
                    MaxLength = $propResolved['maxLength']
                    Minimum = $propResolved['minimum']
                    Maximum = $propResolved['maximum']
                    Pattern = $propResolved['pattern']
                    Enum = $propResolved['enum']
                    Nullable = $propResolved['nullable']
                    Default = $propResolved['default']
                    Deprecated = $propResolved['deprecated']
                    ReadOnly = $propResolved['readOnly']
                    WriteOnly = $propResolved['writeOnly']
                }
                
                # For array types, include items schema information
                if ($propResolved['type'] -eq 'array' -and $propResolved['items']) {
                    $itemsResolved = & $ResolveRef $propResolved['items'] $RootSpec
                    $itemsProperties = & $ResolveRef $propResolved['items'] $RootSpec
                    
                    # Get nested properties if the items have them
                    $nestedProps = @{}
                    if ($itemsResolved['properties']) {
                        foreach ($itemPropName in $itemsResolved['properties'].Keys) {
                            $itemProp = $itemsResolved['properties'][$itemPropName]
                            $itemPropResolved = & $ResolveRef $itemProp $RootSpec
                            
                            $nestedProps[$itemPropName] = @{
                                Name = $itemPropName
                                Type = $itemPropResolved['type']
                                Format = $itemPropResolved['format']
                                Description = $itemPropResolved['description']
                                MinLength = $itemPropResolved['minLength']
                                MaxLength = $itemPropResolved['maxLength']
                                Minimum = $itemPropResolved['minimum']
                                Maximum = $itemPropResolved['maximum']
                                Pattern = $itemPropResolved['pattern']
                                Enum = $itemPropResolved['enum']
                                Nullable = $itemPropResolved['nullable']
                                Default = $itemPropResolved['default']
                                Deprecated = $itemPropResolved['deprecated']
                                ReadOnly = $itemPropResolved['readOnly']
                                WriteOnly = $itemPropResolved['writeOnly']
                            }
                        }
                    }
                    
                    # Add items information to the property
                    $properties[$propName]['ItemsSchema'] = if ($propResolved['items']['$ref']) { 
                        $propResolved['items']['$ref'] -replace '#/components/schemas/', '' 
                    } else { 
                        'inline' 
                    }
                    $properties[$propName]['ItemsType'] = $itemsResolved['type']
                    $properties[$propName]['ItemsProperties'] = $nestedProps
                    $properties[$propName]['ItemsRequired'] = $itemsResolved['required']
                }
            }
        }
        
        return $properties
    }
    
    # Find the operation
    $operation = $spec['paths'][$Path][($Method.ToLower())]
    
    if (-not $operation) {
        if ($OutputFormat -eq 'List') {
            Write-Host "❌ Operation not found: $Method $Path" -ForegroundColor Red
            Write-Host ""
            Write-Host "Available paths:" -ForegroundColor Yellow
            $spec['paths'].Keys | ForEach-Object {
                $pathName = $_
                $pathMethods = $spec['paths'][$pathName].Keys
                Write-Host "  ${pathName}: $($pathMethods -join ', ')" -ForegroundColor Gray
            }
        }
        throw "Operation not found: $Method $Path"
    }
    
    if ($OutputFormat -eq 'List') {
        Write-Host "Operation: $($operation['operationId'])" -ForegroundColor Cyan
        Write-Host "Summary: $($operation['summary'])" -ForegroundColor Gray
        if ($operation['description']) {
            Write-Host "Description: $($operation['description'])" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Analyze parameters (query, path, header)
    # Collect from BOTH path level (apply to all operations) AND operation level
    $resolvedParameters = @()
    $allParameters = @()
    
    # First, add path-level parameters (if any)
    $pathDef = $spec['paths'][$Path]
    if ($pathDef['parameters']) {
        $allParameters += $pathDef['parameters']
    }
    
    # Then, add operation-level parameters (if any)
    if ($operation['parameters']) {
        $allParameters += $operation['parameters']
    }
    
    # Now process all parameters
    if ($allParameters.Count -gt 0) {
        foreach ($param in $allParameters) {
            $resolvedParam = & $resolveRef $param $spec
            $paramSchema = $resolvedParam['schema']
            $resolvedParameters += [PSCustomObject]@{
                Name = $resolvedParam['name']
                In = $resolvedParam['in']
                Required = $resolvedParam['required']
                Type = $paramSchema['type']
                Format = $paramSchema['format']
                Description = $resolvedParam['description']
                Minimum = $paramSchema['minimum']
                Maximum = $paramSchema['maximum']
                MinLength = $paramSchema['minLength']
                MaxLength = $paramSchema['maxLength']
                Pattern = $paramSchema['pattern']
                Enum = $paramSchema['enum']
                Default = $paramSchema['default']
                Deprecated = $resolvedParam['deprecated']
            }
        }
        
        if ($OutputFormat -eq 'List' -and $resolvedParameters.Count -gt 0) {
            Write-Host "Parameters:" -ForegroundColor Cyan
            $resolvedParameters | ForEach-Object {
                $reqMarker = if ($_.Required) { " [REQUIRED]" } else { "" }
                $color = if ($_.Required) { "Green" } else { "Gray" }
                Write-Host "  • $($_.Name) ($($_.In))$reqMarker" -ForegroundColor $color
                
                # Type and format
                if ($_.Type) {
                    $typeStr = $_.Type
                    if ($_.Format) { $typeStr += " ($($_.Format))" }
                    Write-Host "      Type: $typeStr" -ForegroundColor DarkGray
                }
                
                # Constraints
                if ($null -ne $_.Minimum) {
                    Write-Host "      Minimum: $($_.Minimum)" -ForegroundColor DarkCyan
                }
                if ($null -ne $_.Maximum) {
                    Write-Host "      Maximum: $($_.Maximum)" -ForegroundColor DarkCyan
                }
                if ($_.MinLength) {
                    Write-Host "      MinLength: $($_.MinLength)" -ForegroundColor DarkCyan
                }
                if ($_.MaxLength) {
                    Write-Host "      MaxLength: $($_.MaxLength)" -ForegroundColor DarkCyan
                }
                if ($_.Pattern) {
                    Write-Host "      Pattern: $($_.Pattern)" -ForegroundColor DarkCyan
                }
                if ($_.Enum) {
                    Write-Host "      Enum: $($_.Enum -join ', ')" -ForegroundColor DarkCyan
                }
                if ($null -ne $_.Default) {
                    Write-Host "      Default: $($_.Default)" -ForegroundColor DarkCyan
                }
                
                if ($_.Description) {
                    Write-Host "      Description: $($_.Description)" -ForegroundColor DarkGray
                }
                if ($_.Deprecated) {
                    Write-Host "      Deprecated: $($_.Deprecated)" -ForegroundColor Red
                }
            }
            Write-Host ""
        }
    }
    
    # Analyze request body
    $requestContract = $null
    if ($operation['requestBody']) {
        if ($OutputFormat -eq 'List') {
            Write-Host "Request Body Contract:" -ForegroundColor Cyan
        }
        
        $requestContent = $operation['requestBody']['content']['application/json']
        $requestSchema = & $resolveRef $requestContent['schema'] $spec
        
        # Handle arrays
        $isArray = $requestSchema['type'] -eq 'array'
        $itemSchema = if ($isArray) { 
            & $resolveRef $requestSchema['items'] $spec
        } else { 
            $requestSchema 
        }
        
        # Get required fields
        $required = if ($itemSchema['required']) { $itemSchema['required'] } else { @() }
        
        # Get all properties
        $properties = & $getProperties $itemSchema $spec $resolveRef
        
        # Try to find schema name from refs (do this before display)
        $schemaName = 'inline'
        if ($requestContent['schema']['$ref']) {
            $schemaName = $requestContent['schema']['$ref'] -replace '#/components/schemas/', ''
        } elseif ($requestSchema['items'] -and $requestSchema['items']['$ref']) {
            $schemaName = $requestSchema['items']['$ref'] -replace '#/components/schemas/', ''
        }
        
        if ($OutputFormat -eq 'List') {
            Write-Host "  Type: $(if($isArray){'array of '}else{''})$($itemSchema['type'])" -ForegroundColor Gray
            Write-Host "  Required fields: $(if($required.Count -gt 0){$required -join ', '}else{'NONE ⚠'})" -ForegroundColor $(if($required.Count -gt 0){"Green"}else{"Red"})
            Write-Host "  Total properties: $($properties.Count)" -ForegroundColor Gray
            Write-Host "  Schema name: $schemaName" -ForegroundColor Gray
            Write-Host ""
            
            # Show ALL properties with full details
            Write-Host "Properties:" -ForegroundColor Yellow
            $properties.Values | Sort-Object Name | ForEach-Object {
                $isRequired = $required -contains $_.Name
                $reqMarker = if($isRequired) { " [REQUIRED]" } else { "" }
                $color = if ($isRequired) { "Green" } elseif ($_.ReadOnly) { "DarkMagenta" } else { "Gray" }
                
                Write-Host "    • $($_.Name)$reqMarker" -ForegroundColor $color
                
                # Type and format
                $typeStr = $_.Type
                if ($_.Format) { $typeStr += " ($($_.Format))" }
                Write-Host "        Type: $typeStr" -ForegroundColor DarkGray
                
                # Nullable
                if ($null -ne $_.Nullable) {
                    Write-Host "        Nullable: $($_.Nullable)" -ForegroundColor DarkCyan
                }
                
                # Constraints
                if ($_.MinLength) {
                    Write-Host "        MinLength: $($_.MinLength)" -ForegroundColor DarkCyan
                }
                if ($_.MaxLength) {
                    Write-Host "        MaxLength: $($_.MaxLength)" -ForegroundColor DarkCyan
                }
                if ($null -ne $_.Minimum) {
                    Write-Host "        Minimum: $($_.Minimum)" -ForegroundColor DarkCyan
                }
                if ($null -ne $_.Maximum) {
                    Write-Host "        Maximum: $($_.Maximum)" -ForegroundColor DarkCyan
                }
                if ($_.Pattern) {
                    Write-Host "        Pattern: $($_.Pattern)" -ForegroundColor DarkCyan
                }
                if ($_.Enum) {
                    Write-Host "        Enum: $($_.Enum -join ', ')" -ForegroundColor DarkCyan
                }
                if ($null -ne $_.Default) {
                    Write-Host "        Default: $($_.Default)" -ForegroundColor DarkCyan
                }
                if ($_.Description) {
                    Write-Host "        Description: $($_.Description)" -ForegroundColor DarkGray
                }
                if ($_.Deprecated) {
                    Write-Host "        Deprecated: $($_.Deprecated)" -ForegroundColor Red
                }
                if ($_.ReadOnly) {
                    Write-Host "        ReadOnly: $($_.ReadOnly)" -ForegroundColor DarkMagenta
                }
                if ($_.WriteOnly) {
                    Write-Host "        WriteOnly: $($_.WriteOnly)" -ForegroundColor DarkMagenta
                }
            }
            
            # Check for array properties and expand their items
            foreach ($propName in $properties.Keys) {
                $prop = $properties[$propName]
                
                if ($prop.Type -eq 'array') {
                    # This property is an array - try to get its items schema
                    $propFullSchema = $itemSchema['properties'][$propName]
                    
                    if ($propFullSchema -and $propFullSchema['items']) {
                        $itemsResolved = & $resolveRef $propFullSchema['items'] $spec
                        $itemsProperties = & $getProperties $propFullSchema['items'] $spec $resolveRef
                        
                        if ($itemsProperties.Count -gt 0) {
                            Write-Host ""
                            Write-Host "    • $propName (array of $($itemsResolved['type']) objects):" -ForegroundColor Cyan
                            Write-Host "      Items Schema: $(if($propFullSchema['items']['$ref']){$propFullSchema['items']['$ref'] -replace '#/components/schemas/', ''}else{'inline'})" -ForegroundColor DarkGray
                            Write-Host "      Items Properties: $($itemsProperties.Count)" -ForegroundColor DarkGray
                            
                            # Show ALL item properties with full details
                            $itemsProperties.Values | Sort-Object Name | ForEach-Object {
                                $isRequired = if ($itemsResolved['required']) { $itemsResolved['required'] -contains $_.Name } else { $false }
                                $color = if ($isRequired) { "Green" } elseif ($_.ReadOnly) { "DarkMagenta" } else { "Gray" }
                                $reqMarker = if ($isRequired) { " [REQUIRED]" } elseif ($_.ReadOnly) { " [ReadOnly]" } else { "" }
                                
                                Write-Host "        - $($_.Name)$reqMarker" -ForegroundColor $color
                                
                                # Type and format
                                $typeStr = $_.Type
                                if ($_.Format) { $typeStr += " ($($_.Format))" }
                                Write-Host "            Type: $typeStr" -ForegroundColor DarkGray
                                
                                # Nullable
                                if ($null -ne $_.Nullable) {
                                    Write-Host "            Nullable: $($_.Nullable)" -ForegroundColor DarkCyan
                                }
                                
                                # Constraints
                                if ($_.MinLength) {
                                    Write-Host "            MinLength: $($_.MinLength)" -ForegroundColor DarkCyan
                                }
                                if ($_.MaxLength) {
                                    Write-Host "            MaxLength: $($_.MaxLength)" -ForegroundColor DarkCyan
                                }
                                if ($null -ne $_.Minimum) {
                                    Write-Host "            Minimum: $($_.Minimum)" -ForegroundColor DarkCyan
                                }
                                if ($null -ne $_.Maximum) {
                                    Write-Host "            Maximum: $($_.Maximum)" -ForegroundColor DarkCyan
                                }
                                if ($_.Pattern) {
                                    Write-Host "            Pattern: $($_.Pattern)" -ForegroundColor DarkCyan
                                }
                                if ($_.Enum) {
                                    Write-Host "            Enum: $($_.Enum -join ', ')" -ForegroundColor DarkCyan
                                }
                                if ($null -ne $_.Default) {
                                    Write-Host "            Default: $($_.Default)" -ForegroundColor DarkCyan
                                }
                                if ($_.Description) {
                                    Write-Host "            Description: $($_.Description)" -ForegroundColor DarkGray
                                }
                                if ($_.Deprecated) {
                                    Write-Host "            Deprecated: $($_.Deprecated)" -ForegroundColor Red
                                }
                                if ($_.WriteOnly) {
                                    Write-Host "            WriteOnly: $($_.WriteOnly)" -ForegroundColor DarkMagenta
                                }
                            }
                        }
                    }
                }
            }
        }
        
        $requestContract = @{
            IsArray = $isArray
            Required = $required
            Properties = $properties
            SchemaName = $schemaName
        }
    }
    
    if ($OutputFormat -eq 'List') {
        Write-Host ""
    }
    
    # Analyze response schemas
    $responseContracts = @{}
    if ($operation['responses']) {
        if ($OutputFormat -eq 'List') {
            Write-Host "Response Contracts:" -ForegroundColor Cyan
        }
        
        foreach ($statusCode in $operation['responses'].Keys) {
            $response = $operation['responses'][$statusCode]
            
            if ($response['content'] -and $response['content']['application/json']) {
                $responseSchema = $response['content']['application/json']['schema']
                $isArray = $responseSchema['type'] -eq 'array'
                $itemSchema = if ($isArray) { $responseSchema['items'] } else { $responseSchema }
                
                $resolved = & $resolveRef $itemSchema $spec
                $properties = & $getProperties $itemSchema $spec $resolveRef
                
                if ($OutputFormat -eq 'List') {
                    Write-Host "  Status ${statusCode}:" -ForegroundColor Yellow
                    Write-Host "    Type: $(if($isArray){'array of '}else{''})$($resolved['type'])" -ForegroundColor Gray
                    
                    # Explicitly get count from hashtable
                    $propCount = if ($properties -is [hashtable]) { $properties.Keys.Count } else { $properties.Count }
                    Write-Host "    Properties: $propCount" -ForegroundColor Gray
                    
                    Write-Host "    Schema name: $(if ($itemSchema['$ref']) { $itemSchema['$ref'] -replace '#/components/schemas/', '' } else { 'inline' })" -ForegroundColor Gray
                }
                
                # Display all properties - both scalar and array types
                if ($OutputFormat -eq 'List' -and $properties -and $properties.Keys.Count -gt 0) {
                    Write-Host ""
                    Write-Host "    Properties:" -ForegroundColor White
                    
                    # Display scalar/simple properties first
                    $properties.Values | Where-Object { $_.Type -ne 'array' } | Sort-Object Name | ForEach-Object {
                        $isReadOnly = $_.ReadOnly
                        $color = if ($isReadOnly) { "DarkMagenta" } else { "DarkGray" }
                        $reqMarker = if ($isReadOnly) { " [ReadOnly]" } else { "" }
                        
                        Write-Host "      • $($_.Name)$reqMarker" -ForegroundColor $color
                        
                        # Type and format
                        $typeStr = $_.Type
                        if ($_.Format) { $typeStr += " ($($_.Format))" }
                        Write-Host "          Type: $typeStr" -ForegroundColor DarkGray
                        
                        # Nullable
                        if ($null -ne $_.Nullable) {
                            Write-Host "          Nullable: $($_.Nullable)" -ForegroundColor DarkCyan
                        }
                        
                        # Constraints
                        if ($_.MinLength) {
                            Write-Host "          MinLength: $($_.MinLength)" -ForegroundColor DarkCyan
                        }
                        if ($_.MaxLength) {
                            Write-Host "          MaxLength: $($_.MaxLength)" -ForegroundColor DarkCyan
                        }
                        if ($null -ne $_.Minimum) {
                            Write-Host "          Minimum: $($_.Minimum)" -ForegroundColor DarkCyan
                        }
                        if ($null -ne $_.Maximum) {
                            Write-Host "          Maximum: $($_.Maximum)" -ForegroundColor DarkCyan
                        }
                        if ($_.Pattern) {
                            Write-Host "          Pattern: $($_.Pattern)" -ForegroundColor DarkCyan
                        }
                        if ($_.Enum) {
                            Write-Host "          Enum: $($_.Enum -join ', ')" -ForegroundColor DarkCyan
                        }
                        if ($null -ne $_.Default) {
                            Write-Host "          Default: $($_.Default)" -ForegroundColor DarkCyan
                        }
                        if ($_.Description) {
                            Write-Host "          Description: $($_.Description)" -ForegroundColor DarkGray
                        }
                        if ($_.Deprecated) {
                            Write-Host "          Deprecated: $($_.Deprecated)" -ForegroundColor Red
                        }
                    }
                }
                
                # Check for array properties and expand their items
                $expandedProperties = @{}
                foreach ($propName in $properties.Keys) {
                    $prop = $properties[$propName]
                    
                    if ($prop.Type -eq 'array') {
                        # This property is an array - try to get its items schema
                        $propFullSchema = $resolved['properties'][$propName]
                        
                        if ($propFullSchema['items']) {
                            $itemsResolved = & $resolveRef $propFullSchema['items'] $spec
                            $itemsProperties = & $getProperties $propFullSchema['items'] $spec $resolveRef
                            
                            if ($itemsProperties.Count -gt 0) {
                                if ($OutputFormat -eq 'List') {
                                    Write-Host ""
                                    Write-Host "    • $propName (array of $($itemsResolved['type']) objects):" -ForegroundColor Cyan
                                    Write-Host "      Items Schema: $(if($propFullSchema['items']['$ref']){$propFullSchema['items']['$ref'] -replace '#/components/schemas/', ''}else{'inline'})" -ForegroundColor DarkGray
                                    Write-Host "      Items Properties: $($itemsProperties.Count)" -ForegroundColor DarkGray
                                    
                                    # Show ALL item properties with full details
                                    $itemsProperties.Values | Sort-Object Name | ForEach-Object {
                                        $isReadOnly = $_.ReadOnly
                                        $color = if ($isReadOnly) { "DarkMagenta" } else { "DarkGray" }
                                        $reqMarker = if ($isReadOnly) { " [ReadOnly]" } else { "" }
                                        
                                        Write-Host "        - $($_.Name)$reqMarker" -ForegroundColor $color
                                        
                                        # Type and format
                                        $typeStr = $_.Type
                                        if ($_.Format) { $typeStr += " ($($_.Format))" }
                                        Write-Host "            Type: $typeStr" -ForegroundColor DarkGray
                                        
                                        # Nullable
                                        if ($null -ne $_.Nullable) {
                                            Write-Host "            Nullable: $($_.Nullable)" -ForegroundColor DarkCyan
                                        }
                                        
                                        # Constraints
                                        if ($_.MinLength) {
                                            Write-Host "            MinLength: $($_.MinLength)" -ForegroundColor DarkCyan
                                        }
                                        if ($_.MaxLength) {
                                            Write-Host "            MaxLength: $($_.MaxLength)" -ForegroundColor DarkCyan
                                        }
                                        if ($null -ne $_.Minimum) {
                                            Write-Host "            Minimum: $($_.Minimum)" -ForegroundColor DarkCyan
                                        }
                                        if ($null -ne $_.Maximum) {
                                            Write-Host "            Maximum: $($_.Maximum)" -ForegroundColor DarkCyan
                                        }
                                        if ($_.Pattern) {
                                            Write-Host "            Pattern: $($_.Pattern)" -ForegroundColor DarkCyan
                                        }
                                        if ($_.Enum) {
                                            Write-Host "            Enum: $($_.Enum -join ', ')" -ForegroundColor DarkCyan
                                        }
                                        if ($null -ne $_.Default) {
                                            Write-Host "            Default: $($_.Default)" -ForegroundColor DarkCyan
                                        }
                                        if ($_.Deprecated) {
                                            Write-Host "            Deprecated: $($_.Deprecated)" -ForegroundColor Red
                                        }
                                    }
                                }
                                
                                # Store expanded info
                                $expandedProperties[$propName] = @{
                                    Type = 'array'
                                    ItemsSchema = if ($propFullSchema['items']['$ref']) { $propFullSchema['items']['$ref'] -replace '#/components/schemas/', '' } else { 'inline' }
                                    ItemsProperties = $itemsProperties
                                }
                            }
                        }
                    }
                }
                
                $responseContracts[$statusCode] = @{
                    IsArray = $isArray
                    Properties = $properties
                    ExpandedProperties = $expandedProperties
                    SchemaName = if ($itemSchema['$ref']) { $itemSchema['$ref'] -replace '#/components/schemas/', '' } else { 'inline' }
                }
            }
        }
    }
    
    # Build contract object
    $contract = [PSCustomObject]@{
        Path = $Path
        Method = $Method.ToUpper()
        OperationId = $operation['operationId']
        Summary = $operation['summary']
        Description = $operation['description']
        RequestSchema = $requestContract
        ResponseSchemas = $responseContracts
        Parameters = $resolvedParameters
    }
    
    if ($OutputFile) {
        # Smart path detection: if just a filename, use default folder
        $outputPath = if ($OutputFile -notmatch '[\\/]') {
            $moduleRoot = $global:ArtTestsModuleRoot ?? $PSScriptRoot
            $contractsFolder = Join-Path $moduleRoot "30-contract-schemas"
            if (-not (Test-Path $contractsFolder)) {
                New-Item -ItemType Directory -Path $contractsFolder -Force | Out-Null
            }
            Join-Path $contractsFolder $OutputFile
        } else {
            $OutputFile
        }
        
        $contract | ConvertTo-Json -Depth 20 | Set-Content $outputPath
        if ($OutputFormat -eq 'List') {
            Write-Host ""
            Write-Host "✓ Contract saved to: $outputPath" -ForegroundColor Green
        }
    }
    
    # Table format - compact visual output
    if ($OutputFormat -eq 'Table') {
        # Method-specific icons
        $methodIcon = switch ($contract.Method) {
            'GET'    { '🔍' }
            'POST'   { '➕' }
            'PUT'    { '✏️' }
            'PATCH'  { '🔧' }
            'DELETE' { '🗑️' }
            default  { '📋' }
        }
        
        # Header with double lines
        $headerText = "$methodIcon $($contract.Method) $($contract.Path)"
        $boxWidth = [Math]::Max($headerText.Length + 2, 80)
        Write-Host ""
        Write-Host ("═" * $boxWidth) -ForegroundColor Cyan
        Write-Host $headerText -ForegroundColor White
        Write-Host ("═" * $boxWidth) -ForegroundColor Cyan
        Write-Host ""
        Write-Host "$($contract.Summary)" -ForegroundColor White
        
        # Parameters
        if ($contract.Parameters -and $contract.Parameters.Count -gt 0) {
            Write-Host ""
            Write-Host "=== PARAMETERS ===" -ForegroundColor Yellow
            $contract.Parameters | Format-Table @{L='Name';E={$_.Name}}, @{L='In';E={$_.In}}, @{L='Type';E={$_.Type}}, @{L='Required';E={$_.Required}}, @{L='Default';E={$_.Default}} -AutoSize
        }
        
        # Request Body
        if ($contract.RequestSchema) {
            Write-Host ""
            Write-Host "=== REQUEST BODY PROPERTIES ===" -ForegroundColor Yellow
            Write-Host "Schema: $($contract.RequestSchema.SchemaName)" -ForegroundColor Gray
            if ($contract.RequestSchema.Required.Count -gt 0) {
                Write-Host "Required: $($contract.RequestSchema.Required -join ', ')" -ForegroundColor Green
            }
            Write-Host ""
            
            $contract.RequestSchema.Properties.Values | 
                Select-Object Name,
                              @{L='Required';E={$contract.RequestSchema.Required -contains $_.Name}},
                              Type, Nullable, MaxLength, MinLength, Pattern,
                              @{L='Enum';E={if($_.Enum){$_.Enum -join ', '}else{''}}} | 
                Format-Table -Property Name, Required, Type, Nullable, MaxLength, MinLength, Pattern, Enum -Wrap
        }
        
        # Response Schemas
        foreach ($statusCode in ($contract.ResponseSchemas.Keys | Sort-Object)) {
            $response = $contract.ResponseSchemas[$statusCode]
            Write-Host ""
            Write-Host "=== RESPONSE $statusCode ===" -ForegroundColor Yellow
            Write-Host "Schema: $($response.SchemaName)" -ForegroundColor Gray
            Write-Host "Properties: $($response.Properties.Keys.Count)" -ForegroundColor Gray
            
            # Show scalar properties
            $scalarProps = $response.Properties.Values | Where-Object { $_.Type -ne 'array' }
            if ($scalarProps) {
                Write-Host ""
                $scalarProps | 
                    Select-Object Name, Type, Nullable, MaxLength, MinLength, Pattern,
                                  @{L='Enum';E={if($_.Enum){$_.Enum -join ', '}else{''}}} | 
                    Format-Table -Property Name, Type, Nullable, MaxLength, MinLength, Pattern, Enum -Wrap
            }
            
            # Show array properties
            $arrayProps = $response.ExpandedProperties
            if ($arrayProps -and $arrayProps.Keys.Count -gt 0) {
                foreach ($arrayPropName in $arrayProps.Keys) {
                    $arrayInfo = $arrayProps[$arrayPropName]
                    Write-Host ""
                    Write-Host "  Array: $arrayPropName ($($arrayInfo.ItemsSchema))" -ForegroundColor Cyan
                    if ($arrayInfo.ItemsProperties -and $arrayInfo.ItemsProperties.Count -gt 0) {
                        $arrayInfo.ItemsProperties.Values | 
                            Select-Object Name, Type, Nullable, MaxLength | 
                            Format-Table -AutoSize
                    }
                }
            }
        }
        
        Write-Host ""
        return
    }
    
    # Only return object if OutputFormat is Object, otherwise List/Table format already displayed everything
    if ($OutputFormat -eq 'Object') {
        return $contract
    }
    } # end process
}

