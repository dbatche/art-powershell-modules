function Get-OrderStatusHistory {
    <#
    .SYNOPSIS
        Retrieves status history records for an order
    
    .DESCRIPTION
        GET /tm/orders/{orderId}/statusHistory
        Retrieves the status change history for a specific order.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER OrderId
        The order ID to retrieve status history for (required)
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "status eq 'Delivered'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "status,statusDate,user"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-OrderStatusHistory -OrderId 123
        # Returns all status history for order 123
    
    .EXAMPLE
        Get-OrderStatusHistory -OrderId 123 -Filter "status eq 'Delivered'"
        # Returns only 'Delivered' status entries
    
    .EXAMPLE
        Get-OrderStatusHistory -OrderId 123 -Select "status,statusDate,user" -Limit 10
        # Returns specific fields for last 10 status changes
    
    .EXAMPLE
        # Pipeline from Get-Order
        Get-Order -OrderId 123 | Get-OrderStatusHistory
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-OrderStatusHistory -OrderId 'ABC'
        Get-OrderStatusHistory -OrderId 123 -Limit 'many'
    
    .OUTPUTS
        Array of status history objects
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        $OrderId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        $Limit,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        $Offset,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = $env:DOMAIN,
        
        [Parameter(Mandatory=$false)]
        [string]$Token = $env:TRUCKMATE_API_KEY,
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )
    
    process {
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
        $endpoint = "/orders/$OrderId/statusHistory"
        
        # Build query parameters
        $queryParams = @()
        
        if ($Filter) { $queryParams += "`$filter=$Filter" }
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($Limit) { $queryParams += "limit=$Limit" }
        if ($Offset) { $queryParams += "offset=$Offset" }
        
        $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
        $uri = "$BaseUrl$endpoint$queryString"
        
        Write-Verbose "GET $uri"
        
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Unwrap array (API likely returns collection)
                if ($response.statusHistory) {
                    return $response.statusHistory
                } elseif ($response.statuses) {
                    return $response.statuses
                } else {
                    return $response
                }
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
}