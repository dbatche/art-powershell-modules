function Test-ResponseJson {
    <#
    .SYNOPSIS
    Tests if a string is valid JSON using .NET System.Text.Json
    
    .PARAMETER JsonString
    The string to test for valid JSON
    
    .PARAMETER ThrowOnError
    If true, throws an exception on invalid JSON. If false, returns $false.
    
    .EXAMPLE
    Test-ResponseJson -JsonString '{"key":"value"}'  # Returns $true
    Test-ResponseJson -JsonString 'invalid'          # Returns $false
    Test-ResponseJson -JsonString '{"key":"value"}' -ThrowOnError  # Throws on error
    #>
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$JsonString,
        
        [Parameter(Mandatory=$false)]
        [switch]$ThrowOnError
    )
    
    if ([string]::IsNullOrWhiteSpace($JsonString)) {
        if ($ThrowOnError) {
            throw "JSON string is null or empty"
        }
        return $false
    }
    
    try {
        # Use .NET JSON parser for robust validation
        $null = [System.Text.Json.JsonDocument]::Parse($JsonString)
        return $true
    } catch {
        if ($ThrowOnError) {
            throw "Invalid JSON: $($_.Exception.Message)"
        }
        return $false
    }
}

# Export the function
# Export-ModuleMember -Function Test-ResponseJson

