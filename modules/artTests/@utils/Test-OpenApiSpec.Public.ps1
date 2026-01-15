function Test-OpenApiSpec {
    <#
    .SYNOPSIS
        Validates that a file or object is a valid OpenAPI specification
    
    .DESCRIPTION
        Checks for required OpenAPI 3.x structure:
        - Has 'openapi' version field
        - Has 'info' section with title and version
        - Has 'paths' section (not empty)
        - All schema references ($ref) point to existing schemas
        
        Catches common issues:
        - Double-encoded JSON (missing openapi field)
        - Incomplete specs (missing required sections)
        - Wrong content type (HTML error pages saved as JSON)
        - Duplicate keys with different casing
        - Broken schema references (e.g., InterlinerPayableDto not found)
    
    .PARAMETER SpecFile
        Path to OpenAPI JSON file to validate
    
    .PARAMETER SpecObject
        Pre-loaded OpenAPI spec object or hashtable to validate
    
    .PARAMETER Quiet
        Suppress output and return only boolean result
    
    .EXAMPLE
        Test-OpenApiSpec -SpecFile "openapi.json"
        # Validates file and displays detailed results
    
    .EXAMPLE
        $isValid = Test-OpenApiSpec -SpecFile "openapi.json" -Quiet
        # Returns $true or $false
    
    .EXAMPLE
        $spec = Get-Content "spec.json" | ConvertFrom-Json -AsHashtable
        Test-OpenApiSpec -SpecObject $spec
        # Validates pre-loaded spec
    
    .OUTPUTS
        When -Quiet: Boolean (valid or not)
        Otherwise: Hashtable with Valid, Issues, Warnings properties
    #>
    
    [CmdletBinding(DefaultParameterSetName='File')]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='File')]
        [string]$SpecFile,
        
        [Parameter(Mandatory=$true, ParameterSetName='Object')]
        [object]$SpecObject,
        
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )
    
    $issues = @()
    $warnings = @()
    $spec = $null
    
    # Load spec from file or use provided object
    if ($PSCmdlet.ParameterSetName -eq 'File') {
        if (-not $Quiet) {
            Write-Host "`nValidating OpenAPI Spec..." -ForegroundColor Cyan
            Write-Host "  File: $SpecFile" -ForegroundColor Gray
        }
        
        # Check file exists
        if (-not (Test-Path $SpecFile)) {
            $issues += "File not found: $SpecFile"
            if ($Quiet) { return $false }
            Write-Host "❌ File not found" -ForegroundColor Red
            return @{ Valid = $false; Issues = $issues; Warnings = $warnings }
        }
        
        # Try to load as JSON
        try {
            $raw = Get-Content $SpecFile -Raw
            
            # Check for double-encoded JSON (starts with quote)
            if ($raw[0] -eq '"' -and $raw[1] -eq '{') {
                $issues += "File appears to be double-encoded JSON (starts with quote)"
            }
            
            # Try parsing with -AsHashtable for better duplicate key handling
            try {
                $spec = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            } catch {
                # If -AsHashtable fails due to duplicate keys, try without (but warn)
                if ($_.Exception.Message -like "*different casing*") {
                    $warnings += "Spec contains duplicate keys with different casing (e.g., 'Stop' and 'stop')"
                    $spec = $raw | ConvertFrom-Json -ErrorAction Stop
                } else {
                    throw
                }
            }
            
        } catch {
            $issues += "Failed to parse JSON: $($_.Exception.Message)"
            if ($Quiet) { return $false }
            Write-Host "❌ Invalid JSON" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Gray
            return @{ Valid = $false; Issues = $issues; Warnings = $warnings }
        }
    } else {
        $spec = $SpecObject
    }
    
    # Validate OpenAPI structure
    # Note: Using bracket notation since spec is loaded with -AsHashtable
    
    # 1. Check for 'openapi' version field (required)
    if (-not $spec['openapi']) {
        $issues += "Missing 'openapi' field (required, e.g., '3.0.0')"
    } else {
        # Validate version format
        if ($spec['openapi'] -notmatch '^\d+\.\d+\.\d+$') {
            $warnings += "OpenAPI version format unusual: '$($spec['openapi'])'"
        }
        
        # Check if it's OpenAPI 3.x
        if ($spec['openapi'] -notmatch '^3\.') {
            $warnings += "OpenAPI version is not 3.x: '$($spec['openapi'])' (may not be fully supported)"
        }
    }
    
    # 2. Check for 'info' section (required)
    if (-not $spec['info']) {
        $issues += "Missing 'info' section (required)"
    } else {
        # Check required info fields
        if (-not $spec['info']['title']) {
            $issues += "Missing 'info.title' field (required)"
        }
        if (-not $spec['info']['version']) {
            $issues += "Missing 'info.version' field (required)"
        }
    }
    
    # 3. Check for 'paths' section (required)
    if (-not $spec['paths']) {
        $issues += "Missing 'paths' section (required)"
    } else {
        # Check if paths is empty
        $pathCount = if ($spec['paths'] -is [hashtable]) {
            $spec['paths'].Count
        } else {
            ($spec['paths'].PSObject.Properties | Measure-Object).Count
        }
        
        if ($pathCount -eq 0) {
            $warnings += "'paths' section is empty (no endpoints defined)"
        }
    }
    
    # 4. Check for 'components' section (optional but common)
    if ($spec['components']) {
        if ($spec['components']['schemas']) {
            $schemaCount = if ($spec['components']['schemas'] -is [hashtable]) {
                $spec['components']['schemas'].Count
            } else {
                ($spec['components']['schemas'].PSObject.Properties | Measure-Object).Count
            }
            if (-not $Quiet) {
                # This is informational, not a warning
            }
        }
    }
    
    # 5. Validate schema references (check that all $ref references exist)
    if ($spec['paths'] -and $spec['components'] -and $spec['components']['schemas']) {
        $brokenRefs = @()
        $availableSchemas = $spec['components']['schemas'].Keys
        
        # Helper to recursively find $ref in objects
        function Find-SchemaRefs {
            param($Object, $Path = "")
            
            if ($Object -is [hashtable]) {
                if ($Object['$ref']) {
                    $ref = $Object['$ref']
                    # Only check component schema refs
                    if ($ref -match '^#/components/schemas/(.+)$') {
                        $schemaName = $matches[1]
                        if ($availableSchemas -notcontains $schemaName) {
                            return @{ Ref = $ref; SchemaName = $schemaName; Location = $Path }
                        }
                    }
                }
                # Recurse into nested hashtables
                foreach ($key in $Object.Keys) {
                    if ($key -ne '$ref') {
                        $newPath = if ($Path) { "$Path.$key" } else { $key }
                        Find-SchemaRefs -Object $Object[$key] -Path $newPath
                    }
                }
            }
            elseif ($Object -is [array]) {
                for ($i = 0; $i -lt $Object.Count; $i++) {
                    Find-SchemaRefs -Object $Object[$i] -Path "$Path[$i]"
                }
            }
        }
        
        # Check all paths
        foreach ($pathKey in $spec['paths'].Keys) {
            $pathObj = $spec['paths'][$pathKey]
            foreach ($method in @('get', 'post', 'put', 'delete', 'patch')) {
                if ($pathObj[$method]) {
                    $operation = $pathObj[$method]
                    
                    # Check request body
                    if ($operation['requestBody']) {
                        $refs = Find-SchemaRefs -Object $operation['requestBody'] -Path "$method $pathKey (requestBody)"
                        if ($refs) { $brokenRefs += $refs }
                    }
                    
                    # Check responses
                    if ($operation['responses']) {
                        foreach ($statusCode in $operation['responses'].Keys) {
                            $refs = Find-SchemaRefs -Object $operation['responses'][$statusCode] -Path "$method $pathKey (response $statusCode)"
                            if ($refs) { $brokenRefs += $refs }
                        }
                    }
                    
                    # Check parameters
                    if ($operation['parameters']) {
                        $refs = Find-SchemaRefs -Object $operation['parameters'] -Path "$method $pathKey (parameters)"
                        if ($refs) { $brokenRefs += $refs }
                    }
                }
            }
        }
        
        # Report broken references
        if ($brokenRefs.Count -gt 0) {
            foreach ($broken in $brokenRefs) {
                $issues += "Broken schema reference '$($broken.Ref)' at $($broken.Location)"
            }
        }
    }
    
    # Determine validity
    $isValid = ($issues.Count -eq 0)
    
    # Output results
    if ($Quiet) {
        return $isValid
    }
    
    Write-Host ""
    if ($isValid) {
        Write-Host "✓ Valid OpenAPI Specification" -ForegroundColor Green
        Write-Host "  Version: $($spec['openapi'])" -ForegroundColor Gray
        Write-Host "  Title: $($spec['info']['title'])" -ForegroundColor Gray
        Write-Host "  API Version: $($spec['info']['version'])" -ForegroundColor Gray
        
        # Show path count
        $pathCount = if ($spec['paths'] -is [hashtable]) {
            $spec['paths'].Count
        } else {
            ($spec['paths'].PSObject.Properties | Measure-Object).Count
        }
        Write-Host "  Endpoints: $pathCount" -ForegroundColor Gray
    } else {
        Write-Host "❌ Invalid OpenAPI Specification" -ForegroundColor Red
        Write-Host ""
        Write-Host "Issues found:" -ForegroundColor Yellow
        foreach ($issue in $issues) {
            Write-Host "  ✗ $issue" -ForegroundColor Red
        }
    }
    
    # Show warnings if any
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    return @{
        Valid = $isValid
        Issues = $issues
        Warnings = $warnings
        Info = if ($spec['info']) {
            @{
                Title = $spec['info']['title']
                Version = $spec['info']['version']
                Description = $spec['info']['description']
            }
        } else { $null }
        OpenApiVersion = $spec['openapi']
        PathCount = if ($spec['paths']) {
            if ($spec['paths'] -is [hashtable]) { $spec['paths'].Count }
            else { ($spec['paths'].PSObject.Properties | Measure-Object).Count }
        } else { 0 }
    }
}


