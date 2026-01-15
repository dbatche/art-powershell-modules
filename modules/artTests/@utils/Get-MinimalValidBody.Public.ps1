function Get-MinimalValidBody {
    <#
    .SYNOPSIS
        Generate minimal valid request body from OpenAPI schema
    
    .DESCRIPTION
        Creates a request body with only required fields (or first field if no required fields).
        Uses Get-SampleValue to populate fields with appropriate test data.
    
    .PARAMETER RequestSchema
        Request schema from Analyze-OpenApiSchema (RequestSchema property)
    
    .EXAMPLE
        $contract = Analyze-OpenApiSchema -SpecFile "spec.json" -Path "/items" -Method POST -OutputFormat Object
        $body = Get-MinimalValidBody -RequestSchema $contract.RequestSchema
        # Returns hashtable with required fields populated
    
    .EXAMPLE
        # Use with contract testing
        $contract = Analyze-OpenApiSchema -SpecFile "spec.json" -Path "/items" -Method POST -OutputFormat Object
        $minBody = Get-MinimalValidBody -RequestSchema $contract.RequestSchema
        $minBody | ConvertTo-Json
        # Generate JSON for API request
    
    .OUTPUTS
        Hashtable with minimum required fields populated with sample values
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$RequestSchema
    )
    
    # Load Get-SampleValue if not already available
    if (-not (Get-Command Get-SampleValue -ErrorAction SilentlyContinue)) {
        $getSampleValuePath = Join-Path $PSScriptRoot 'Get-SampleValue.Public.ps1'
        if (Test-Path $getSampleValuePath) {
            . $getSampleValuePath
        } else {
            throw "Get-SampleValue function not found. Ensure Get-SampleValue.Public.ps1 is in the same directory."
        }
    }
    
    $body = @{}
    
    if ($RequestSchema.Required.Count -gt 0) {
        # Include all required fields
        foreach ($req in $RequestSchema.Required) {
            $body[$req] = Get-SampleValue -Property $RequestSchema.Properties[$req]
        }
    } else {
        # No required fields - pick first property
        $firstProp = $RequestSchema.Properties.Keys | Select-Object -First 1
        $body[$firstProp] = Get-SampleValue -Property $RequestSchema.Properties[$firstProp]
    }
    
    return $body
}

