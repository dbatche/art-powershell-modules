function Get-SampleValue {
    <#
    .SYNOPSIS
        Generate sample value based on OpenAPI property definition
    
    .DESCRIPTION
        Intelligently generates test data based on property type, constraints, and patterns.
        Used for populating test bodies, scaffolds, and realistic test data.
    
    .PARAMETER Property
        Property definition from OpenAPI schema (from Analyze-OpenApiSchema)
    
    .EXAMPLE
        $contract = Analyze-OpenApiSchema -SpecFile "spec.json" -Path "/items" -Method POST -OutputFormat Object
        $value = Get-SampleValue -Property $contract.RequestSchema.Properties['purchaseDate']
        # Returns: '2025-01-15T10:30:00' (detects datetime pattern)
    
    .EXAMPLE
        $value = Get-SampleValue -Property @{ Type = 'string'; MaxLength = 10 }
        # Returns: 'AAAAAAAAAA' (10 characters, respects maxLength)
    
    .EXAMPLE
        $value = Get-SampleValue -Property @{ Type = 'string'; Enum = @('Active', 'Inactive') }
        # Returns: 'Active' (first enum value)
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]$Property
    )
    
    if (-not $Property) { return $null }
    
    # Handle enums - use first value
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

