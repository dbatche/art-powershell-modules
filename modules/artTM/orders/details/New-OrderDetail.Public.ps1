<#
.SYNOPSIS
    Creates new order detail line(s).

.DESCRIPTION
    POST /orders/{orderId}/details
    Creates one or more detail lines for an order.
    
.PARAMETER OrderId
    The ID of the order (required).

.PARAMETER OrderDetail
    The detail properties as an array of detail objects (NOT wrapped in 'details' key).
    Can be array or single hashtable.

.PARAMETER Expand
    Optional. OData expand query parameter to include related entities (e.g., "barcodes").

.EXAMPLE
    $details = @(
        @{
            items = 10
            weight = 1000
            weightUnits = "LB"
        }
    )
    New-OrderDetail -OrderId 123 -OrderDetail $details

.EXAMPLE
    # Create detail with barcodes
    $detail = @{
        details = @(
            @{
                items = 10
                weight = 1000
                weightUnits = "LB"
                barcodes = @(
                    @{ altBarcode1 = "BC001"; weight = 500 }
                )
            }
        )
    }
    New-OrderDetail -OrderId 123 -OrderDetail $detail -Expand "barcodes"

.NOTES
    Returns error as JSON string if API call fails, otherwise returns created detail(s).
#>
function New-OrderDetail {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [array]$OrderDetail,
        
        [Parameter(Mandatory=$false)]
        [string]$Expand,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = ($env:TM_API_URL ),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY)
    )

    try {
        $apiUrl = "$BaseUrl/orders/$OrderId/details"
        
        # Build query parameters
        if ($Expand) {
            $apiUrl += "?expand=$Expand"
        }
        
        $body = $OrderDetail | ConvertTo-Json -Depth 10 -Compress -AsArray
        
        Write-Verbose "POST $apiUrl"
        Write-Verbose "Body: $($body | ConvertFrom-Json | ConvertTo-Json -Depth 10)"
        
        if ($PSCmdlet.ShouldProcess("Order $OrderId", "Create detail")) {
            $headers = @{
                "Authorization" = "Bearer $Token"
                "Content-Type" = "application/json"
            }
            
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body
            
            Write-Verbose "Requested HTTP/1.1 POST with $($body.Length)-byte payload"
            Write-Verbose "Received HTTP/1.1 $($response.PSObject.Properties.Count)-property response"
            
            return $response
        }
        
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Host " API Returned an error" -ForegroundColor Red
            return $_.ErrorDetails.Message
            
        }
        else {
            # Fallback for non-API errors (network issues, invalid JSON, etc.)
            Write-Error $_.Exception.Message
            return $null
        }
    }
}
            
            