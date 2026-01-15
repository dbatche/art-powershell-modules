function Get-OpenApiSpecFromUrl {
    <#
    .SYNOPSIS
    Downloads OpenAPI specification from URL and saves to file.
    
    .DESCRIPTION
    Fetches the OpenAPI spec from a URL and saves it to a local JSON file.
    Returns the path to the saved file for use with other functions.
    
    .PARAMETER Url
    The URL of the OpenAPI specification (must return application/json).
    
    .PARAMETER Token
    Optional bearer token for authentication.
    
    .PARAMETER OutputPath
    Optional custom output path. If not specified, creates a timestamped file.
    
    .EXAMPLE
    # Download Finance API spec
    $specFile = Get-OpenApiSpecFromUrl -Url "https://api.com/openapi.json" -Token $token
    
    .EXAMPLE
    # Download to specific file
    $specFile = Get-OpenApiSpecFromUrl -Url "https://api.com/openapi.json" -OutputPath "finance-api.json"
    
    .NOTES
    Part of the contract testing framework. Use with Analyze-OpenApiSchema.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$false)]
        [string]$Token,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )
    
    # Use environment variable as fallback for Token
    if (-not $Token) {
        $Token = $env:TRUCKMATE_API_KEY
    }
    
    Write-Host "Fetching OpenAPI specification..." -ForegroundColor Cyan
    Write-Host "  URL: $Url" -ForegroundColor Gray
    
    # Build headers
    $headers = @{}
    if ($Token) {
        $headers.Authorization = "Bearer $Token"
    }
    
    # Fetch spec
    try {
        $spec = Invoke-RestMethod -Uri $Url -Headers $headers
    } catch {
        Write-Host "❌ Failed to fetch OpenAPI spec: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    
    # Convert to hashtable for consistent property access (handles duplicate keys too)
    $specHashtable = if ($spec -is [string]) {
        $spec | ConvertFrom-Json -AsHashtable
    } else {
        # PSCustomObject - convert via JSON
        $spec | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable
    }
    
    # Extract API name from spec for filename
    # Note: Using hashtable bracket notation for consistent access
    $apiName = if ($specHashtable['info'] -and $specHashtable['info']['title']) {
        # Remove common suffixes (API, REST, Service, etc.) and special chars
        $cleanName = $specHashtable['info']['title'] -replace '\s+(REST\s+)?API\s*$', '' `
                                                      -replace '\s+REST\s+', ' ' `
                                                      -replace '\s+Service\s*$', '' `
                                                      -replace '[^a-zA-Z0-9\s-]', ''
        # Special cases for multi-word names that should be one word
        $cleanName = $cleanName -replace 'Master\s+Data', 'MasterData' `
                                -replace 'Cloud\s+Hub', 'CloudHub'
        # Replace remaining spaces with nothing (no dashes) and convert to lowercase
        $cleanName = $cleanName -replace '\s+', ''
        $cleanName.ToLower().Trim('-')
    } else {
        "unknown"
    }
    
    # Extract version from spec itself (no extra network call needed)
    # Note: Using hashtable bracket notation for consistent access
    $specVersion = if ($specHashtable['info'] -and $specHashtable['info']['x-tm-release']) {
        $specHashtable['info']['x-tm-release']
    } else {
        $null
    }
    
    # Determine output file path
    # Use module root variable (set in .psm1) to ensure specs go in module root, not @utils
    $moduleRoot = $(if ($global:ArtTestsModuleRoot) { $global:ArtTestsModuleRoot } else { $PSScriptRoot })
    $specsFolder = Join-Path $moduleRoot "10-openapi-specs"
    if (-not (Test-Path $specsFolder)) {
        New-Item -ItemType Directory -Path $specsFolder -Force | Out-Null
    }
    
    if (-not $OutputPath) {
        # No path specified - use default timestamped file with API name, timestamp, and version
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $versionStr = if ($specVersion) { "-v$specVersion" } else { "" }
        $finalPath = Join-Path $specsFolder "$apiName-openapi-$timestamp$versionStr.json"
    } elseif ($OutputPath -notmatch '[\\/]') {
        # Just a filename - prepend default folder
        $finalPath = Join-Path $specsFolder $OutputPath
    } else {
        # Has path separators - use as-is
        $finalPath = $OutputPath
    }
    
    # Save to file (handle both string and object responses)
    if ($spec -is [string]) {
        # API returned JSON as a string - save directly (already encoded)
        Write-Host "  Note: API returned pre-encoded JSON string" -ForegroundColor DarkGray
        $spec | Set-Content -Path $finalPath -Encoding UTF8 -NoNewline
        # Parse it for display info (use -AsHashtable to handle duplicate keys with different casing)
        $specObj = $spec | ConvertFrom-Json -AsHashtable
        $specInfo = $specObj
    } else {
        # API returned object - convert to JSON
        $spec | ConvertTo-Json -Depth 100 | Set-Content -Path $finalPath -Encoding UTF8
        $specInfo = $spec
    }
    
    # Display title and version (use bracket notation for hashtable)
    $displayTitle = if ($specInfo['info']) { $specInfo['info']['title'] } else { "Unknown" }
    $displayVersion = if ($specInfo['info']) { $specInfo['info']['version'] } else { "Unknown" }
    Write-Host "✓ Fetched spec: $displayTitle v$displayVersion" -ForegroundColor Green
    Write-Host "✓ Saved to: $finalPath" -ForegroundColor Green
    
    # Validate the saved spec
    $validatorPath = Join-Path $PSScriptRoot 'Test-OpenApiSpec.Public.ps1'
    if (Test-Path $validatorPath) {
        . $validatorPath
        $validation = Test-OpenApiSpec -SpecFile $finalPath
        
        if (-not $validation.Valid) {
            Write-Host ""
            Write-Host "⚠ WARNING: Spec validation found issues!" -ForegroundColor Yellow
            foreach ($issue in $validation.Issues) {
                Write-Host "  ✗ $issue" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "The file may be double-encoded or corrupted." -ForegroundColor Yellow
            Write-Host "Consider using Repair-OpenApiSpec to fix it." -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    return (Resolve-Path $finalPath).Path
}

