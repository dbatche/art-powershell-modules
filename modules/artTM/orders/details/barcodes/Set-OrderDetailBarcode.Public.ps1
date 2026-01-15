function Set-OrderDetailBarcode {
    <#
    .SYNOPSIS
        Updates an order detail line barcode item
    
    .DESCRIPTION
        PUT /orders/{orderId}/details/{orderDetailId}/barcodes/{barcodeId}
        Updates one or more properties of a barcode item record for the specified order and detail line.
        
        TM-185682: Duplicate Barcode ID with PUT in REST API
        
        Barcode items can be viewed in Customer Service application > Details tab > Barcode Item Details window.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER OrderId
        The order ID (required)
    
    .PARAMETER OrderDetailId
        The order detail line ID (required)
    
    .PARAMETER BarcodeId
        The barcode ID to update (required, automatically generated integer)
    
    .PARAMETER Barcode
        Hashtable with barcode properties to update. Common properties:
        - barcode (string, max 50) - System-generated scannable barcode
        - altBarcode1 (string, max 50) - Alternate scannable barcode
        - altBarcode2 (string, max 50) - Second alternate scannable barcode
        - cube (number, nullable) - Cubic dimensional value
        - cubeUnits (string, max 3) - Unit of measure for cube
        - height (number, nullable) - Height of handling unit
        - heightUnits (string, max 3) - Unit of measure for height
        - length (number, nullable) - Length of handling unit
        - lengthUnits (string, max 3) - Unit of measure for length
        - width (number, nullable) - Width of handling unit
        - widthUnits (string, max 3) - Unit of measure for width
        - weight (number, nullable) - Weight of handling unit
        - weightUnits (string, max 3) - Unit of measure for weight
        - location (string, max 12) - Last known location identifier
        - pieceCount (integer, nullable) - Number of pieces
        - barcodeSequence (integer, nullable) - Barcode sequence
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        # Update barcode identifier
        Set-OrderDetailBarcode -OrderId 12345 -OrderDetailId 1 -BarcodeId 100 -Barcode @{
            altBarcode1 = "ALT123456"
        }
    
    .EXAMPLE
        # Update dimensions
        Set-OrderDetailBarcode -OrderId 12345 -OrderDetailId 1 -BarcodeId 100 -Barcode @{
            length = 48.0
            lengthUnits = "IN"
            width = 40.0
            widthUnits = "IN"
            height = 36.0
            heightUnits = "IN"
        }
    
    .EXAMPLE
        # API Testing: Test duplicate barcodeId (TM-185682)
        Set-OrderDetailBarcode -OrderId 12345 -OrderDetailId 1 -BarcodeId 100 -Barcode @{
            barcodeId = 999  # Should this be allowed or cause duplicate error?
            altBarcode1 = "TEST"
        }
    
    .NOTES
        TM-185682: Duplicate Barcode ID with PUT in REST API
        
        Important: barcodeId is automatically generated. If included in the request body,
        it may cause issues with duplicate IDs.
    
    .OUTPUTS
        Updated barcode object, or JSON error string for testability
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, Position=1)]
        $OrderDetailId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, Position=2)]
        $BarcodeId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]$Barcode,
        
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
    
    # Build URI
    $uri = "$BaseUrl/orders/$OrderId/details/$OrderDetailId/barcodes/$BarcodeId"
    
    # Convert body to JSON
    $body = $Barcode | ConvertTo-Json -Depth 10
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $body"
    
    # WhatIf support
    if ($PSCmdlet.ShouldProcess("Barcode $BarcodeId on Order $OrderId Detail $OrderDetailId", "Update")) {
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Return the barcode object
                return $response
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
                
