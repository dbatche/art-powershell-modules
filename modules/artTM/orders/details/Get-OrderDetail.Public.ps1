<#
.SYNOPSIS
    Retrieves an order detail record.

.DESCRIPTION
    Retrieves a single order detail record by ID or a collection of detail records for an order.
    
.PARAMETER OrderId
    The ID of the order (required).

.PARAMETER OrderDetailId
    The ID of the order detail to retrieve. If not specified, retrieves all details for the order.

.PARAMETER Select
    Optional. OData select query parameter to limit fields returned.

.PARAMETER Expand
    Optional. OData expand query parameter to include related entities (e.g., "barcodes").

.EXAMPLE
    Get-OrderDetail -OrderId 123 -OrderDetailId 456
    # Retrieves a specific order detail

.EXAMPLE
    Get-OrderDetail -OrderId 123 -Expand "barcodes"
    # Retrieves all details for an order with barcode details

.NOTES
    Returns error as JSON string if API call fails, otherwise returns detail object(s).
#>
function Get-OrderDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$false, Position=1)]
        $OrderDetailId,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [string]$Expand
    )

    try {
        $apiUrl = "$env:TM_API_URL/orders/$OrderId/details"
        
        if ($OrderDetailId) {
            $apiUrl += "/$OrderDetailId"
        }
        
        # Build query parameters
        $queryParams = @()
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        
        if ($queryParams.Count -gt 0) {
            $apiUrl += "?" + ($queryParams -join "&")
        }
        
        Write-Verbose "GET $apiUrl"
        
        $token = $env:TRUCKMATE_API_KEY 
        
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        return $response
        
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