function Set-TripFuelPurchase {
    <#
    .SYNOPSIS
        Updates a trip fuel purchase record
    
    .DESCRIPTION
        PUT /fuelTaxes/{fuelTaxId}/tripFuelPurchases/{tripFuelPurchaseId}
        Updates an existing trip fuel purchase record.
        Operates on a single purchase (not an array).
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER FuelTaxId
        The fuel tax ID the purchase is associated with (required)
    
    .PARAMETER TripFuelPurchaseId
        The ID of the trip fuel purchase to update (required)
    
    .PARAMETER Purchase
        Hashtable with purchase properties to update.
        See NOTES for available properties.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the API response object
    
    .EXAMPLE
        Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase @{
            fuelVolume1 = 105.5
            fuelRate1 = 3.60
        }
        # Updates volume and rate for purchase 456
    
    .EXAMPLE
        $updated = @{
            purchaseLocation = 'CA'
            taxable = 'Y'
            taxPaid = 'Y'
        }
        Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase $updated
        # Updates tax fields
    
    .NOTES
        Available properties (all optional):
        - cost, currencyCode, driverId1, driverId2
        - fuelCardNumber, fuelCardVendor, fuelCost1, fuelCost2
        - fuelInvoiceNumber, fuelRate1, fuelRate2
        - fuelStationCity, fuelStationId, fuelStationName
        - fuelStationPostalCode, fuelStationVendor
        - fuelType1, fuelType2, fuelVolume1, fuelVolume2
        - odometer, purchaseDate, purchaseJurisdiction
        - purchaseLocation, purchaseType, receipt
        - reeferFuelCost, reeferFuelRate, reeferFuelVolume
        - taxable, taxPaid, unit, user1, user2, user3, volume
    
    .OUTPUTS
        Updated trip fuel purchase object
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $FuelTaxId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true)]
        $TripFuelPurchaseId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]$Purchase,
        
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
        'Content-Type' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build endpoint
    $uri = "$BaseUrl/fuelTaxes/$FuelTaxId/tripFuelPurchases/$TripFuelPurchaseId"
    
    # Convert to JSON
    $jsonBody = $Purchase | ConvertTo-Json -Depth 10
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $jsonBody"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $jsonBody -ContentType 'application/json'
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        } else {
            # Unwrap to get the actual purchase object
            if ($response.tripFuelPurchase) {
                return $response.tripFuelPurchase
            } else {
                return $response
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

