function New-TripFuelPurchases {
    <#
    .SYNOPSIS
        Creates one or more trip fuel purchase records
    
    .DESCRIPTION
        POST /fuelTaxes/{fuelTaxId}/tripFuelPurchases
        Creates trip fuel purchase records associated with a fuel tax calculation.
        Accepts an array of fuel purchase objects.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER FuelTaxId
        The fuel tax ID to associate purchases with (required)
    
    .PARAMETER Purchases
        Array of trip fuel purchase objects (hashtables) with properties:
        - purchaseDate, purchaseLocation, fuelVolume1, fuelRate1, etc.
        See NOTES for full property list.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER Default
        Creates a minimal default purchase for testing (single purchase with minimal fields)
    
    .PARAMETER PassThru
        Returns the API response object instead of just the purchases array
    
    .EXAMPLE
        New-TripFuelPurchases -FuelTaxId 123 -Default
        # Creates a minimal test purchase
    
    .EXAMPLE
        $purchase = @{
            purchaseDate = '2024-01-15'
            purchaseLocation = 'CA'
            fuelVolume1 = 100.5
            fuelRate1 = 3.50
            fuelType1 = 'DIESEL'
        }
        New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchase
        # Creates a single purchase
    
    .EXAMPLE
        $purchases = @(
            @{ purchaseDate = '2024-01-15'; fuelVolume1 = 100; fuelRate1 = 3.50 },
            @{ purchaseDate = '2024-01-16'; fuelVolume1 = 95; fuelRate1 = 3.55 }
        )
        New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchases
        # Creates multiple purchases
    
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
        Array of created trip fuel purchase objects with IDs assigned
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $FuelTaxId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [object[]]$Purchases,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = $env:FINANCE_API_URL,
        
        [Parameter(Mandatory=$false)]
        [string]$Token = $env:TRUCKMATE_API_KEY,
        
        [Parameter(Mandatory=$false)]
        [switch]$Default,
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )
    
    begin {
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
        $uri = "$BaseUrl/fuelTaxes/$FuelTaxId/tripFuelPurchases"
        
        # Collect all purchases from pipeline
        $allPurchases = @()
    }
    
    process {
        if ($Purchases) {
            $allPurchases += $Purchases
        }
    }
    
    end {
        # Handle -Default flag
        if ($Default) {
            $allPurchases = @(
                @{
                    purchaseDate = (Get-Date -Format 'yyyy-MM-dd')
                    purchaseLocation = 'CA'
                    fuelType1 = 'DIESEL'
                    fuelVolume1 = 100.0
                    fuelRate1 = 3.50
                    fuelCost1 = 350.0
                }
            )
        }
        
        # Validate we have purchases
        if ($allPurchases.Count -eq 0) {
            throw "No purchases provided. Use -Purchases or -Default parameter."
        }
        
        # Convert to JSON - always as array (API expects array even for single item)
        # Ensure we send an array even if there's only one purchase
        if ($allPurchases.Count -eq 1) {
            $jsonBody = ConvertTo-Json -InputObject @($allPurchases) -Depth 10
        } else {
            $jsonBody = ConvertTo-Json -InputObject $allPurchases -Depth 10
        }
        
        Write-Verbose "POST $uri"
        Write-Verbose "Body: $jsonBody"
        
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody -ContentType 'application/json'
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            } else {
                # Unwrap to get the actual purchases array
                if ($response.tripFuelPurchases) {
                    return $response.tripFuelPurchases
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
}

