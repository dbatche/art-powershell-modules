<#
.SYNOPSIS
    Updates an order detail record.

.DESCRIPTION
    Updates one or more properties of an order detail record using PUT method.
    When a resource like 'barcodes' is specified in the body, it performs a complete replace:
    - Items with barcodeId: Updates existing barcode
    - Items without barcodeId: Creates new barcode
    
.PARAMETER OrderId
    The ID of the order (required).

.PARAMETER OrderDetailId
    The ID of the order detail to update (required).

.PARAMETER OrderDetail
    The order detail properties to update (hashtable or object).

.PARAMETER Select
    Optional. OData select query parameter to limit fields returned.

.PARAMETER Expand
    Optional. OData expand query parameter to include related entities (e.g., "barcodes").

.EXAMPLE
    Set-OrderDetail -OrderId 123 -OrderDetailId 456 -OrderDetail @{ volume = 100 }
    # Updates the volume field

.EXAMPLE
    $barcodes = @(
        @{ barcodeId = 789; altBarcode1 = "UPDATED" },  # Updates existing
        @{ altBarcode1 = "NEW-A" },                      # Creates new
        @{ altBarcode1 = "NEW-B" }                       # Creates new
    )
    Set-OrderDetail -OrderId 123 -OrderDetailId 456 -OrderDetail @{ barcodes = $barcodes } -Expand "barcodes"
    # Updates barcodes array

.NOTES
    Returns error as JSON string if API call fails, otherwise returns updated detail object.
    TM-185682: Including barcodeId in barcodes array should update that barcode, not create duplicate.
#>
function Set-OrderDetail {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$true, Position=1)]
        $OrderDetailId,
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]$OrderDetail,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [string]$Expand
    )

    try {
        $apiUrl = "$env:TM_API_URL/orders/$OrderId/details/$OrderDetailId"
        
        # Build query parameters
        $queryParams = @()
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        
        if ($queryParams.Count -gt 0) {
            $apiUrl += "?" + ($queryParams -join "&")
        }
        
        $body = $OrderDetail | ConvertTo-Json -Depth 10 -Compress
        
        Write-Verbose "PUT $apiUrl"
        Write-Verbose "Body: $($body | ConvertFrom-Json | ConvertTo-Json -Depth 10)"
        
        if ($PSCmdlet.ShouldProcess("OrderDetail $OrderDetailId", "Update")) {
            $token = $env:TRUCKMATE_API_KEY
            
            $headers = @{
                "Authorization" = "Bearer $token"
                "Content-Type" = "application/json"
            }
            
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $body
            
            Write-Verbose "Requested HTTP/1.1 PUT with $($body.Length)-byte payload"
            Write-Verbose "Received HTTP/1.1 $($response.PSObject.Properties.Count)-property response"
            
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