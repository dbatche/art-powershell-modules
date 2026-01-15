function Get-TripFuelPurchases {
    <#
    .SYNOPSIS
        Retrieves trip fuel purchase records for a fuel tax
    
    .DESCRIPTION
        GET /fuelTaxes/{fuelTaxId}/tripFuelPurchases
        GET /fuelTaxes/{fuelTaxId}/tripFuelPurchases/{tripFuelPurchaseId}
        Retrieves fuel purchase records associated with a fuel tax calculation.
        Can retrieve all purchases for a fuel tax or a specific one by ID.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER FuelTaxId
        The fuel tax ID to retrieve purchases for (required)
    
    .PARAMETER TripFuelPurchaseId
        Optional. Specific trip fuel purchase ID to retrieve.
        If omitted, returns all purchases for the fuel tax.
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "purchaseLocation eq 'CA'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "tripFuelPurchaseId,purchaseDate,fuelVolume1"
    
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
        Get-TripFuelPurchases -FuelTaxId 123
        # Returns all purchases for fuel tax 123
    
    .EXAMPLE
        Get-TripFuelPurchases -FuelTaxId 123 -TripFuelPurchaseId 456
        # Returns purchase 456 for fuel tax 123
    
    .EXAMPLE
        Get-TripFuelPurchases -FuelTaxId 123 -Filter "purchaseLocation eq 'CA'"
        # Returns California purchases for fuel tax 123
    
    .EXAMPLE
        Get-FuelTaxes -FuelTaxId 123 | Get-TripFuelPurchases
        # Pipeline: Gets fuel tax 123, then its purchases
    
    .OUTPUTS
        Single purchase object or array of purchase objects
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        $FuelTaxId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false, Position=1)]
        $TripFuelPurchaseId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
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
    
    process {
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
        $endpoint = "/fuelTaxes/$FuelTaxId/tripFuelPurchases"
        
        if ($TripFuelPurchaseId) {
            # Get specific purchase
            $uri = "$BaseUrl$endpoint/$TripFuelPurchaseId"
        }
        else {
            # Get collection with optional query parameters
            $queryParams = @()
            
            if ($Filter) { $queryParams += "`$filter=$Filter" }
            if ($Select) { $queryParams += "`$select=$Select" }
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
                if ($TripFuelPurchaseId) {
                    # Single item
                    if ($response.tripFuelPurchase) {
                        return $response.tripFuelPurchase
                    } else {
                        return $response
                    }
                }
                else {
                    # Collection
                    if ($response.tripFuelPurchases) {
                        return $response.tripFuelPurchases
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
}

