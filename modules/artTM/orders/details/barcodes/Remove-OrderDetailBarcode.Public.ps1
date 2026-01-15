function Remove-OrderDetailBarcode {
    <#
    .SYNOPSIS
        Deletes an order detail line barcode item
    
    .DESCRIPTION
        DELETE /orders/{orderId}/details/{orderDetailId}/barcodes/{barcodeId}
        Deletes a barcode item record for the specified order and detail line.
        
        Barcode items can be viewed in Customer Service application > Details tab > Barcode Item Details window.
    
    .PARAMETER OrderId
        The order ID (required)
    
    .PARAMETER OrderDetailId
        The order detail line ID (required)
    
    .PARAMETER BarcodeId
        The barcode ID to delete (required)
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        # Delete a barcode
        Remove-OrderDetailBarcode -OrderId 12345 -OrderDetailId 1 -BarcodeId 100
    
    .OUTPUTS
        Success message or JSON error string for testability
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$true, Position=1)]
        $OrderDetailId,
        
        [Parameter(Mandatory=$true, Position=2)]
        $BarcodeId,
        
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
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build URI
    $uri = "$BaseUrl/orders/$OrderId/details/$OrderDetailId/barcodes/$BarcodeId"
    
    Write-Verbose "DELETE $uri"
    
    # WhatIf support
    if ($PSCmdlet.ShouldProcess("Barcode $BarcodeId on Order $OrderId Detail $OrderDetailId", "Delete")) {
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
            
            # Return response
            if ($PassThru) {
                return $response
            }
            else {
                # DELETE typically returns 204 No Content or 200 with empty body
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