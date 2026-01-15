function Repair-OpenApiSpec {
    <#
    .SYNOPSIS
    Repairs OpenAPI spec files with duplicate keys (different casing)
    
    .DESCRIPTION
    Preprocesses OpenAPI JSON files to remove duplicate keys with different casing.
    PowerShell's ConvertFrom-Json cannot handle duplicate keys (case-insensitive),
    so this function parses with -AsHashtable, cleans duplicates, and converts back.
    
    Strategy: Within each hashtable, keeps the FIRST occurrence of a key (case-insensitive)
    and removes subsequent occurrences with different casing.
    
    .PARAMETER InputFile
    Path to the OpenAPI spec file to repair
    
    .PARAMETER OutputFile
    Path to save the repaired spec (default: adds -repaired.json suffix)
    
    .PARAMETER BackupOriginal
    Create a backup of the original file (default: $true)
    
    .EXAMPLE
    Repair-OpenApiSpec -InputFile ".\10-openapi-specs\orders-raw.json"
    
    .EXAMPLE
    Repair-OpenApiSpec -InputFile ".\orders-raw.json" -OutputFile ".\orders-clean.json" -BackupOriginal $false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$InputFile,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$false)]
        [bool]$BackupOriginal = $true
    )
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "   OPENAPI SPEC REPAIR UTILITY (v2 - Hashtable Method)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Resolve input file path
    if (-not (Test-Path $InputFile)) {
        Write-Host "❌ File not found: $InputFile" -ForegroundColor Red
        return
    }
    
    $InputFile = Resolve-Path $InputFile
    Write-Host "📄 Input File: $InputFile" -ForegroundColor Gray
    
    # Determine output file
    if (-not $OutputFile) {
        $dir = Split-Path $InputFile -Parent
        $name = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
        $ext = [System.IO.Path]::GetExtension($InputFile)
        $OutputFile = Join-Path $dir "$name-repaired$ext"
    }
    Write-Host "💾 Output File: $OutputFile" -ForegroundColor Gray
    Write-Host ""
    
    # Backup original if requested
    if ($BackupOriginal) {
        $backupFile = "$InputFile.backup"
        if (-not (Test-Path $backupFile)) {
            Copy-Item $InputFile $backupFile
            Write-Host "✓ Backed up original to: $backupFile" -ForegroundColor Green
        } else {
            Write-Host "ℹ Backup already exists: $backupFile" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Read and parse with -AsHashtable
    Write-Host "📖 Reading JSON file..." -ForegroundColor Cyan
    $content = Get-Content $InputFile -Raw -Encoding UTF8
    $originalSize = $content.Length
    Write-Host "   Size: $originalSize bytes" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🔧 Parsing with -AsHashtable..." -ForegroundColor Cyan
    try {
        $spec = $content | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        Write-Host "   ✓ Parsed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Failed to parse: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    Write-Host ""
    
    # Clean duplicate keys recursively
    Write-Host "🔍 Scanning and cleaning duplicate keys..." -ForegroundColor Cyan
    $stats = @{
        ObjectsScanned = 0
        DuplicatesFound = 0
        DuplicatesRemoved = 0
    }
    
    $cleanedSpec = Remove-DuplicateKeys -Object $spec -Stats $stats
    
    Write-Host "   Objects scanned: $($stats.ObjectsScanned)" -ForegroundColor Gray
    Write-Host "   Duplicates found: $($stats.DuplicatesFound)" -ForegroundColor Yellow
    Write-Host "   Duplicates removed: $($stats.DuplicatesRemoved)" -ForegroundColor Green
    Write-Host ""
    
    if ($stats.DuplicatesRemoved -eq 0) {
        Write-Host "✓ No duplicate keys found!" -ForegroundColor Green
        Write-Host "  File is already clean." -ForegroundColor Gray
        return $InputFile
    }
    
    # Convert back to JSON
    Write-Host "💾 Converting to JSON and saving..." -ForegroundColor Cyan
    try {
        $json = $cleanedSpec | ConvertTo-Json -Depth 100 -Compress:$false
        $json | Set-Content -Path $OutputFile -Encoding UTF8
        $newSize = $json.Length
        $sizeDiff = $originalSize - $newSize
        
        Write-Host "   Original: $originalSize bytes" -ForegroundColor Gray
        Write-Host "   Repaired: $newSize bytes" -ForegroundColor Gray
        if ($sizeDiff -gt 0) {
            Write-Host "   Removed:  $sizeDiff bytes" -ForegroundColor Green
        } else {
            Write-Host "   Added:    $([Math]::Abs($sizeDiff)) bytes (pretty-print formatting)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   ❌ Failed to convert to JSON: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    Write-Host ""
    
    # Verify the cleaned file can be parsed normally
    Write-Host "✓ Verifying cleaned JSON..." -ForegroundColor Cyan
    try {
        $testParse = Get-Content $OutputFile -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "   ✓ JSON is valid and can be parsed WITHOUT -AsHashtable!" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "   ✅ REPAIR COMPLETE" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "📁 Repaired file: $OutputFile" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  Use this file with:" -ForegroundColor Gray
        Write-Host "    Analyze-OpenApiSchema -SpecFile `"$OutputFile`"" -ForegroundColor White
        Write-Host "    Get-OpenApiEndpoints -SpecFile `"$OutputFile`"" -ForegroundColor White
        Write-Host "    New-ContractTests (with contract from Analyze-OpenApiSchema)" -ForegroundColor White
        Write-Host ""
        
        return $OutputFile
    }
    catch {
        Write-Host "   ⚠ Warning: Cleaned JSON may still have issues" -ForegroundColor Yellow
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "   The file has been saved but may need manual review." -ForegroundColor Yellow
        return $null
    }
}

function Remove-DuplicateKeys {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Object,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Stats
    )
    
    if ($Object -is [hashtable]) {
        $Stats.ObjectsScanned++
        
        # Create case-insensitive comparison
        $seenKeys = @{}
        $keysToRemove = @()
        
        # First pass: identify duplicates
        foreach ($key in @($Object.Keys)) {
            $keyLower = $key.ToLower()
            if ($seenKeys.ContainsKey($keyLower)) {
                # This is a duplicate (different casing)
                $Stats.DuplicatesFound++
                $keysToRemove += $key
            } else {
                $seenKeys[$keyLower] = $key
            }
        }
        
        # Remove duplicates
        foreach ($key in $keysToRemove) {
            $Object.Remove($key)
            $Stats.DuplicatesRemoved++
        }
        
        # Recursively process values
        foreach ($key in @($Object.Keys)) {
            if ($Object[$key] -is [hashtable] -or $Object[$key] -is [array]) {
                $Object[$key] = Remove-DuplicateKeys -Object $Object[$key] -Stats $Stats
            }
        }
        
        return $Object
    }
    elseif ($Object -is [array]) {
        # Process each item in array
        for ($i = 0; $i -lt $Object.Count; $i++) {
            if ($Object[$i] -is [hashtable] -or $Object[$i] -is [array]) {
                $Object[$i] = Remove-DuplicateKeys -Object $Object[$i] -Stats $Stats
            }
        }
        
        return $Object
    }
    else {
        # Primitive type, return as-is
        return $Object
    }
}

# Export the function if being used as a module
Export-ModuleMember -Function Repair-OpenApiSpec
