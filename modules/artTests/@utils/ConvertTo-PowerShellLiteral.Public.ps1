function ConvertTo-PowerShellLiteral {
    <#
    .SYNOPSIS
        Convert an object to PowerShell literal syntax
    
    .DESCRIPTION
        Recursively converts hashtables, arrays, and primitive types into
        PowerShell literal syntax suitable for saving to .ps1 test files.
        Used by New-TestDefinition and Update-TestDefinition to preserve
        hashtable format (avoiding JSON string double-encoding issues).
    
    .PARAMETER Object
        The object to convert (hashtable, array, string, number, boolean, or null)
    
    .PARAMETER IndentLevel
        Internal parameter for recursive indentation (default: 0)
    
    .EXAMPLE
        ConvertTo-PowerShellLiteral -Object @{ name = "Test"; value = 123 }
        # Returns: @{ name = 'Test'; value = 123 }
    
    .EXAMPLE
        ConvertTo-PowerShellLiteral -Object @( @{ id = 1 }, @{ id = 2 } )
        # Returns: @(
        #     @{ id = 1 },
        #     @{ id = 2 }
        # )
    
    .NOTES
        This function prevents double-encoding by keeping bodies as PowerShell
        hashtables rather than converting to JSON strings.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [object]$Object,
        
        [Parameter(Mandatory=$false)]
        [int]$IndentLevel = 0
    )
    
    $indent = "    " * $IndentLevel
    
    if ($null -eq $Object) {
        return "`$null"
    }
    elseif ($Object -is [string]) {
        # Escape single quotes in strings
        $escaped = $Object -replace "'", "''"
        return "'$escaped'"
    }
    elseif ($Object -is [bool]) {
        return "`$$Object"
    }
    elseif ($Object -is [int] -or $Object -is [long] -or $Object -is [double] -or $Object -is [decimal]) {
        return $Object.ToString()
    }
    elseif ($Object -is [array]) {
        if ($Object.Count -eq 0) {
            return "@()"
        }
        $items = @()
        foreach ($item in $Object) {
            $items += ConvertTo-PowerShellLiteral -Object $item -IndentLevel ($IndentLevel + 1)
        }
        return "@(`n$indent    " + ($items -join ",`n$indent    ") + "`n$indent)"
    }
    elseif ($Object -is [hashtable] -or $Object -is [PSCustomObject]) {
        $hash = if ($Object -is [PSCustomObject]) {
            $h = @{}
            $Object.PSObject.Properties | ForEach-Object { $h[$_.Name] = $_.Value }
            $h
        } else {
            $Object
        }
        
        if ($hash.Keys.Count -eq 0) {
            return "@{}"
        }
        
        $props = @()
        foreach ($key in $hash.Keys) {
            $value = ConvertTo-PowerShellLiteral -Object $hash[$key] -IndentLevel ($IndentLevel + 1)
            $props += "$key = $value"
        }
        return "@{ " + ($props -join "; ") + " }"
    }
    else {
        # Fallback for unknown types - convert to string
        return "'$Object'"
    }
}

