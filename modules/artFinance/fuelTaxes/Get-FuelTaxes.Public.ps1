function Get-FuelTaxes {
    <#
    .SYNOPSIS
        Retrieves fuel tax records
    
    .DESCRIPTION
        GET /fuelTaxes or /fuelTaxes/{fuelTaxId}
        Retrieves fuel tax calculation records from the Finance API.
        Can retrieve all records or a specific one by ID.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER FuelTaxId
        Optional. Specific fuel tax ID to retrieve.
        If omitted, returns all fuel tax records.
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "tripNumber eq '12345'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "fuelTaxId,tripNumber,totalTax"
    
    .PARAMETER Expand
        Optional. OData expand expression for related entities.
        Example: "tripSegments,tripFuelPurchases,tripWaypoints"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-FuelTaxes
        # Returns all fuel tax records
    
    .EXAMPLE
        Get-FuelTaxes -FuelTaxId 123
        # Returns fuel tax record 123
    
    .EXAMPLE
        Get-FuelTaxes -Filter "tripNumber eq '12345'"
        # Returns fuel taxes for trip 12345
    
    .EXAMPLE
        Get-FuelTaxes -FuelTaxId 123 -Expand "tripSegments,tripFuelPurchases"
        # Returns fuel tax 123 with expanded child resources
    
    .EXAMPLE
        Get-FuelTaxes -Limit 10 -Offset 20
        # Returns 10 records starting from record 20 (page 3)
    
    .OUTPUTS
        Single fuel tax object or array of fuel tax objects
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $FuelTaxId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [ArgumentCompleter({@('tripSegments','tripFuelPurchases','tripWaypoints')})]
        [string]$Expand,
        
        [Parameter(Mandatory=$false)]
        $Limit,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        $Offset,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = $env:FINANCE_API_URL,
        
        [Parameter(Mandatory=$false)]
        [string]$Token = $env:TRUCKMATE_API_KEY,
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )
    
    # Validate token
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    # Build headers
    $headers = @{
        'Authorization' = "Bearer $Token"
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build URI
    $endpoint = "/fuelTaxes"
    
    if ($FuelTaxId) {
        # Get specific fuel tax
        $uri = "$BaseUrl$endpoint/$FuelTaxId"
    }
    else {
        # Get collection with optional query parameters
        $queryParams = @()
        
        if ($Filter) { $queryParams += "`$filter=$Filter" }
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        if ($Limit) { $queryParams += "limit=$Limit" }
        if ($Offset) { $queryParams += "offset=$Offset" }
        
        $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
        $uri = "$BaseUrl$endpoint$queryString"
    }
    
    Write-Verbose "GET $uri"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap based on whether we requested a single item or collection
            if ($FuelTaxId) {
                # Single item - unwrap from response object
                if ($response.fuelTax) {
                    return $response.fuelTax
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.fuelTaxes) {
                    return $response.fuelTaxes
                } else {
                    return $response
                }
            }
        }
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
        }
    }
}

