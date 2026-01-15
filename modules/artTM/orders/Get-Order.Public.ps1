<#
.SYNOPSIS
    Retrieves order record(s) [/orders/{orderId}]

.DESCRIPTION
    Retrieves a single order by ID or searches for orders using filters.
    
.PARAMETER OrderId
    The ID of the order to retrieve. Used in path: /orders/{orderId}

.PARAMETER Select
    Optional. OData select query parameter to limit fields returned.

.PARAMETER Expand
    Optional. OData expand query parameter to include related entities (e.g., "details", "details,details/barcodes").

.PARAMETER BaseUrl
    Optional. Override the base URL. Defaults to $env:TM_API_URL.

.PARAMETER Token
    Optional. Override the bearer token. Defaults to $env:TRUCKMATE_API_KEY.

.PARAMETER PassThru
    Optional. Return full response wrapper instead of unwrapped data.

.EXAMPLE
    Get-Order -OrderId 123
    # Retrieves a specific order

.EXAMPLE
    Get-Order -OrderId 123 -Expand "details"
    # Retrieves order with detail lines included

.NOTES
    Returns error as JSON string if API call fails, otherwise returns order object.
#>
function Get-Order {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $OrderId,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [string]$Expand,

        [Parameter(Mandatory=$false)]
        [string]$BaseUrl,

        [Parameter(Mandatory=$false)]
        [string]$Token,

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    try {
        $apiUrl = if ($BaseUrl) { $BaseUrl } else { $env:TM_API_URL }
        $apiUrl += "/orders/$OrderId"
        
        # Build query parameters
        $queryParams = @()
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        
        if ($queryParams.Count -gt 0) {
            $apiUrl += "?" + ($queryParams -join "&")
        }
        
        Write-Verbose "GET $apiUrl"
        
        $bearerToken = if ($Token) { $Token } else { $env:TRUCKMATE_API_KEY }
        
        $headers = @{
            "Authorization" = "Bearer $bearerToken"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        
        # For single order GET, API returns order directly (no wrapper)
        # PassThru returns whatever the API returns
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
