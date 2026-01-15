function Get-OrderDetailBarcodes {
    <#
    .SYNOPSIS
        Retrieves order detail line barcode items
    
    .DESCRIPTION
        GET /orders/{orderId}/details/{orderDetailId}/barcodes
        Retrieves barcode item records for specified order and detail line.
        
        Barcode items can be viewed in Customer Service application > Details tab > Barcode Item Details window.
    
    .PARAMETER OrderId
        The order ID (required)
    
    .PARAMETER OrderDetailId
        The order detail line ID (required)
    
    .PARAMETER BarcodeId
        Optional. If specified, retrieves a specific barcode by ID.
        Otherwise retrieves all barcodes for the detail line.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        # Get all barcodes for an order detail line
        Get-OrderDetailBarcodes -OrderId 12345 -OrderDetailId 1
    
    .EXAMPLE
        # Get a specific barcode
        Get-OrderDetailBarcodes -OrderId 12345 -OrderDetailId 1 -BarcodeId 100
    
    .OUTPUTS
        Array of barcode objects or single barcode object, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$true, Position=1)]
        $OrderDetailId,
        
        [Parameter(Mandatory=$false)]
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
    if ($BarcodeId) {
        $uri = "$BaseUrl/orders/$OrderId/details/$OrderDetailId/barcodes/$BarcodeId"
    } else {
        $uri = "$BaseUrl/orders/$OrderId/details/$OrderDetailId/barcodes"
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
            if ($BarcodeId) {
                return $response
            }
            else {
                # Collection - unwrap array
                if ($response.barcodes) {
                    return $response.barcodes
                } else {
                    return $response
                }
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