function Test-OpenApiDuplicateKeys {
    <#
    .SYNOPSIS
        Scans an OpenAPI specification file for duplicate schema keys with different casing
    
    .DESCRIPTION
        Diagnostic tool to identify case-insensitive duplicate keys in OpenAPI schemas.
        Helps distinguish between intentional duplicates (different schemas) and bugs/typos.
        
        Useful for QA and reporting issues to API development teams.
    
    .PARAMETER SpecFile
        Path to the OpenAPI specification JSON file
    
    .EXAMPLE
        Test-OpenApiDuplicateKeys -SpecFile "finance-openapi.json"
        # Scans the Finance API spec for duplicate keys
    
    .EXAMPLE
        Test-OpenApiDuplicateKeys -SpecFile "truckmate-openapi.json"
        # Shows that TruckMate has 'Stop' vs 'stop' (intentional - different schemas)
    
    .OUTPUTS
        Displays duplicate key groups with property counts to help identify intentional vs bugs
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SpecFile
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
    
    Write-Host "`n══════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🔍 SCANNING FOR DUPLICATE KEYS" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    Write-Host "File: $specPath" -ForegroundColor Gray
    Write-Host ""
    
    # Load and parse spec
    try {
        $content = Get-Content $specPath -Raw
        $spec = $content | ConvertFrom-Json -AsHashtable
    } catch {
        Write-Error "Failed to parse OpenAPI spec: $($_.Exception.Message)"
        return
    }
    
    # Check if spec has schemas
    if (-not $spec.components -or -not $spec.components.schemas) {
        Write-Host "⚠️  No schemas found in OpenAPI spec" -ForegroundColor Yellow
        return
    }
    
    $schemas = $spec.components.schemas
    Write-Host "Scanning $($schemas.Keys.Count) schema definitions..." -ForegroundColor Gray
    Write-Host ""
    
    # Find case-insensitive duplicates (skip empty/null keys)
    # Force array wrapping with @() to handle single-result case
    $duplicateGroups = @($schemas.Keys | 
        Where-Object { $_ } | 
        Group-Object { $_.ToLower() } | 
        Where-Object { $_.Count -gt 1 -and $_.Name })
    
    if (-not $duplicateGroups) {
        Write-Host "✅ No duplicate keys found!" -ForegroundColor Green
        Write-Host "   All schema names have unique casing." -ForegroundColor Gray
        Write-Host ""
        return @{
            HasDuplicates = $false
            DuplicateCount = 0
            Duplicates = @()
        }
    }
    
    # Report findings
    Write-Host "⚠️  Found $($duplicateGroups.Count) duplicate key group(s):`n" -ForegroundColor Yellow
    
    $duplicateDetails = @()
    
    foreach ($group in $duplicateGroups) {
        $groupName = $group.Name
        $variants = $group.Group
        
        Write-Host "  📦 Group: '$groupName' (case-insensitive)" -ForegroundColor Cyan
        
        $variantDetails = @()
        foreach ($variant in $variants) {
            $schema = $schemas[$variant]
            $propCount = if ($schema.properties) { $schema.properties.Keys.Count } else { 0 }
            $schemaType = if ($schema.type) { $schema.type } else { "object" }
            
            Write-Host "     • $variant" -ForegroundColor White
            Write-Host "       Type: $schemaType, Properties: $propCount" -ForegroundColor Gray
            
            $variantDetails += @{
                Name = $variant
                Type = $schemaType
                PropertyCount = $propCount
            }
        }
        
        # Analyze if likely intentional or bug
        $propCounts = $variantDetails | ForEach-Object { $_.PropertyCount } | Sort-Object -Unique
        $verdict = if ($propCounts.Count -eq 1) {
            "🐛 LIKELY BUG (identical property counts - probable typo)"
        } else {
            "✅ LIKELY INTENTIONAL (different property counts - different schemas)"
        }
        
        Write-Host "       $verdict" -ForegroundColor $(if ($propCounts.Count -eq 1) { "Red" } else { "Green" })
        Write-Host ""
        
        $duplicateDetails += @{
            GroupName = $groupName
            Variants = $variantDetails
            LikelyBug = ($propCounts.Count -eq 1)
        }
    }
    
    # Summary (force array wrapping to avoid hashtable .Count quirk)
    Write-Host "──────────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
    $bugCount = @($duplicateDetails | Where-Object { $_.LikelyBug }).Count
    $intentionalCount = $duplicateGroups.Count - $bugCount
    
    Write-Host "📊 Summary:" -ForegroundColor Yellow
    Write-Host "   Total duplicate groups: $($duplicateGroups.Count)" -ForegroundColor White
    Write-Host "   Likely bugs: $bugCount" -ForegroundColor $(if ($bugCount -gt 0) { "Red" } else { "Green" })
    Write-Host "   Likely intentional: $intentionalCount" -ForegroundColor Green
    Write-Host ""
    
    if ($bugCount -gt 0) {
        Write-Host "💡 Recommendation: Report bugs to API development team" -ForegroundColor Cyan
    } else {
        Write-Host "💡 All duplicates appear intentional (different schemas)" -ForegroundColor Cyan
    }
    
    Write-Host "══════════════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # Return structured data for scripting
    return @{
        HasDuplicates = $true
        DuplicateCount = $duplicateGroups.Count
        Duplicates = $duplicateDetails
        BugCount = $bugCount
        IntentionalCount = $intentionalCount
    }
}

