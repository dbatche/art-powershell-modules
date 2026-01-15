function Set-Order {
    <#
    .SYNOPSIS
        Updates an order (freight bill)
    
    .DESCRIPTION
        PUT /tm/orders/{orderId}
        Updates an existing order in TruckMate.
        
        HYBRID PARAMETER DESIGN (62+ properties):
        - Common fields as named parameters (discoverable, tab-completable)
        - Everything else via -Updates hashtable (flexible, handles nested data)
        
        FLEXIBLE TYPE DESIGN (for API testing):
        - NO type constraints on parameters
        - Allows testing API validation with intentionally invalid data
        - API validates and returns proper error codes (400, etc.)
        - Normal usage still works (PowerShell handles type coercion)
    
    .PARAMETER OrderId
        The order ID to update (required)
    
    .PARAMETER BillTo
        Bill-to customer code
    
    .PARAMETER ServiceLevel
        Service level code (e.g., 'REGULAR', 'EXPRESS')
    
    .PARAMETER Status
        Order status code
    
    .PARAMETER DeliveryAppt
        Delivery appointment date/time
    
    .PARAMETER PickupAppt
        Pickup appointment date/time
    
    .PARAMETER DeliveryDriver1
        Primary delivery driver ID
    
    .PARAMETER Weight
        Total weight
    
    .PARAMETER Rate
        Rate amount
    
    .PARAMETER Updates
        Hashtable containing any other order properties to update.
        
        Common uses:
        - Nested objects: consignee, shipper, caller, careOf
        - Arrays: audits, aCharges, customDefs, dangerousGoods, details
        - Other fields: currencyCode, codAmount, declaredValue, etc.
        
        Example: @{
            audits = @(
                @{ action = 'UPDATED'; user = 'JOHN'; timestamp = (Get-Date) }
            )
            consignee = @{ name = 'ABC Corp'; city = 'NYC' }
            notes = 'Updated for customer request'
        }
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL or $env:DOMAIN
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object
    
    .EXAMPLE
        Set-Order -OrderId 12345 -BillTo 'CUST001' -ServiceLevel 'EXPRESS'
        # Update common fields using named parameters
    
    .EXAMPLE
        Set-Order -OrderId 12345 -Updates @{
            audits = @(
                @{ action = 'UPDATED'; user = 'JOHN'; timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss'); notes = 'Rate adjusted' }
            )
        }
        # Add audit entry
    
    .EXAMPLE
        Set-Order -OrderId 12345 -BillTo 'CUST001' -Updates @{
            consignee = @{ name = 'ABC Corp'; address = '123 Main St'; city = 'NYC'; state = 'NY' }
            audits = @( @{ action = 'UPDATED'; user = 'SYSTEM' } )
            notes = 'Customer address updated'
        }
        # Mix common fields and complex updates
    
    .EXAMPLE
        $changes = @{
            deliveryAppt = '2024-01-20T10:00:00'
            weight = 5000
            rate = 1500
            audits = @( @{ action = 'RERATE'; user = 'BILLING' } )
        }
        Set-Order -OrderId 'ORD123' -Updates $changes
        # Bulk update from hashtable
    
    .EXAMPLE
        Set-Order -OrderId 'ORD123' -Updates @{
            aCharges = @(
                @{ chargeCode = 'FUEL'; amount = 50.00 },
                @{ chargeCode = 'TOLL'; amount = 15.00 }
            )
            customDefs = @(
                @{ field = 'CustomField1'; value = 'TestValue' }
            )
        }
        # Update arrays of nested objects
    
    .EXAMPLE
        # API Testing: Test invalid data types (expect 400 errors)
        Set-Order -OrderId 'ABC' -Rate 1500    # Test: invalid integer
        Set-Order -OrderId 123 -Weight 'heavy' # Test: invalid number
        Set-Order -OrderId 999.99 -BillTo 'X'  # Test: decimal to integer
        # Flexible types allow testing API validation
    
    .NOTES
        Order has 62+ properties including nested objects and arrays.
        Named parameters expose the most commonly updated fields.
        -Updates hashtable provides full flexibility for all other fields.
        
        Common nested objects: consignee, shipper, caller, careOf
        Common arrays: audits, aCharges, details, customDefs, dangerousGoods
        
        Type Design Philosophy:
        - NO type constraints = maximum testing flexibility
        - Can test API validation with intentionally invalid types
        - Normal usage works fine (PowerShell coerces '123' → 123)
        - API is source of truth for validation (returns proper 400 errors)
    
    .OUTPUTS
        Updated order object
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,  # No type constraint - allows testing invalid types
        
        # Common fields - minimal type constraints for testing flexibility
        # OpenAPI types: integer, string, number, datetime
        # But we allow ANY type to test API validation
        [Parameter(Mandatory=$false)]
        $BillTo,
        
        [Parameter(Mandatory=$false)]
        $ServiceLevel,
        
        [Parameter(Mandatory=$false)]
        $Status,
        
        [Parameter(Mandatory=$false)]
        $DeliveryAppt,  # Can be datetime, string, or invalid for testing
        
        [Parameter(Mandatory=$false)]
        $PickupAppt,  # Can be datetime, string, or invalid for testing
        
        [Parameter(Mandatory=$false)]
        $DeliveryDriver1,
        
        [Parameter(Mandatory=$false)]
        $Weight,  # Can be number, string, or invalid for testing
        
        [Parameter(Mandatory=$false)]
        $Rate,  # Can be number, string, or invalid for testing
        
        # Everything else (including audits, nested objects, arrays)
        [Parameter(Mandatory=$false)]
        [hashtable]$Updates,
        
        # Standard parameters
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = $env:DOMAIN,
        
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
    
    # Build request body by merging named parameters + Updates hashtable
    $body = @{}
    
    # Add named parameters if provided
    # Pass values as-is to allow testing with invalid types
    # API will validate and return appropriate errors
    if ($PSBoundParameters.ContainsKey('BillTo')) { $body.billTo = $BillTo }
    if ($PSBoundParameters.ContainsKey('ServiceLevel')) { $body.serviceLevel = $ServiceLevel }
    if ($PSBoundParameters.ContainsKey('Status')) { $body.status = $Status }
    if ($PSBoundParameters.ContainsKey('DeliveryAppt')) { 
        # Accept datetime objects or strings (for testing flexibility)
        if ($DeliveryAppt -is [datetime]) {
            $body.deliveryAppt = $DeliveryAppt.ToString('yyyy-MM-ddTHH:mm:ss')
        } else {
            $body.deliveryAppt = $DeliveryAppt  # Pass as-is for testing
        }
    }
    if ($PSBoundParameters.ContainsKey('PickupAppt')) { 
        # Accept datetime objects or strings (for testing flexibility)
        if ($PickupAppt -is [datetime]) {
            $body.pickupAppt = $PickupAppt.ToString('yyyy-MM-ddTHH:mm:ss')
        } else {
            $body.pickupAppt = $PickupAppt  # Pass as-is for testing
        }
    }
    if ($PSBoundParameters.ContainsKey('DeliveryDriver1')) { $body.deliveryDriver1 = $DeliveryDriver1 }
    if ($PSBoundParameters.ContainsKey('Weight')) { $body.weight = $Weight }
    if ($PSBoundParameters.ContainsKey('Rate')) { $body.rate = $Rate }
    
    # Merge Updates hashtable (overwrites named params if conflicts)
    if ($Updates) {
        foreach ($key in $Updates.Keys) {
            $body[$key] = $Updates[$key]
        }
    }
    
    # Validate we have something to update
    if ($body.Count -eq 0) {
        throw "No updates provided. Use named parameters or -Updates hashtable to specify changes."
    }
    
    # Build URI
    $uri = "$BaseUrl/orders/$OrderId"
    
    # Convert to JSON
    $jsonBody = $body | ConvertTo-Json -Depth 10 -Compress
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $jsonBody"
    
    # Make API call with WhatIf support
    if ($PSCmdlet.ShouldProcess($OrderId, "Update order")) {
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $jsonBody -ContentType 'application/json'
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Unwrap to get the actual order object
                if ($response.order) {
                    return $response.order
                } else {
                    return $response
                }
            }
        }
        catch {
            # Output error for interactive use and return JSON string for testability
            if ($_.ErrorDetails.Message) {
                Write-Host "API Returned an error" -ForegroundColor Red
                return $_.ErrorDetails.Message
            }
            else {
                # Fallback for non-API errors (network issues, invalid JSON, etc.)
                Write-Error $_.Exception.Message
                return $null
            }
        }
    }
}