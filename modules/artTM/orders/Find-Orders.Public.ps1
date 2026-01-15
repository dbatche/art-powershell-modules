function Find-Orders {
    <#
    .SYNOPSIS
        Searches for orders using filters and query parameters
    
    .DESCRIPTION
        GET /tm/orders
        Retrieves a collection of order (freight bill) records with optional filtering,
        selection, ordering, and pagination.
        
        For retrieving a single order by ID, use Get-Order instead.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Filter
        Optional. OData $filter expression for filtering results.
        Example: "billTo eq CUST001 and status ne COMPLETE"
        Note: Avoid using quoted strings in filter values (use CANCL instead of 'CANCL')
        due to API JSON escaping issues.
    
    .PARAMETER Select
        Optional. OData $select expression for returning specific fields.
        Example: "orderId,billTo,deliverBy,rate"
    
    .PARAMETER OrderBy
        Optional. OData $orderby expression for sorting results.
        Example: "deliverBy desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
        Default: API default (typically 50)
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
        Useful for paging through large result sets.
    
    .PARAMETER Type
        Optional. Order type filter.
        Valid values: 'T' (Truckload), 'P' (Parcel), 'Q' (Quote)
    
    .PARAMETER Expand
        Optional. Comma-separated list of child resources to include in response.
        Supported values: "charges", "billing", "xStops"
        Example: "charges,billing"
        Note: Not documented in OpenAPI spec but supported by API
    
    .PARAMETER ExcludePositions
        Optional. Exclude all POSITION records from statusHistory.
        Valid values: 'True', 'False'
    
    .PARAMETER TraceType
        Optional. Trace type to search by (single character).
        Required when using search functionality with TraceNumber.
        Note: Maximum length is 1 character.
    
    .PARAMETER TraceNumber
        Optional. Trace number to search for.
        Required when using search functionality with TraceType.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data array
    
    .EXAMPLE
        Find-Orders -Filter "billTo eq CUST001" -Limit 10
        # Returns first 10 orders for customer CUST001
    
    .EXAMPLE
        Find-Orders -Filter "status ne COMPLETE" -OrderBy "deliverBy desc" -Limit 20
        # Returns 20 incomplete orders sorted by delivery date descending
    
    .EXAMPLE
        Find-Orders -Type 'T' -Filter "deliverBy ge 2025-10-01" -Select "orderId,billTo,deliverBy"
        # Returns truckload orders with delivery after Oct 1, showing only selected fields
    
    .EXAMPLE
        Find-Orders -Filter "status eq PEND" -Expand "charges,billing" -Limit 5
        # Returns pending orders with expanded charges and billing data included
    
    .EXAMPLE
        Find-Orders -TraceType "B" -TraceNumber "T61148" -ExcludePositions 'True'
        # Search for orders by trace number (type 'B'), excluding position records
    
    .EXAMPLE
        # Pagination: Get second page of 50 records
        Find-Orders -Limit 50 -Offset 50
    
    .EXAMPLE
        # Get all orders with specific status
        Find-Orders -Filter "status eq PEND"
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Find-Orders -Limit 'many'
        Find-Orders -Type 'X'
    
    .NOTES
        For retrieving a single order by ID, use Get-Order instead
    
    .OUTPUTS
        On success: Array of order objects (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [string]$OrderBy,
        
        [Parameter(Mandatory=$false)]
        $Limit,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        $Offset,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$Type,  # T, P, Q
        
        [Parameter(Mandatory=$false)]
        [string]$Expand,
        
        [Parameter(Mandatory=$false)]
        [string]$ExcludePositions,  # True, False
        
        [Parameter(Mandatory=$false)]
        [string]$TraceType,
        
        [Parameter(Mandatory=$false)]
        [string]$TraceNumber,
        
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
        'Accept' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build query parameters
    $queryParams = @()
    
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Select) { $queryParams += "`$select=$Select" }
    if ($OrderBy) { $queryParams += "`$orderby=$OrderBy" }
    if ($Limit) { $queryParams += "limit=$Limit" }
    if ($Offset) { $queryParams += "offset=$Offset" }
    if ($Type) { $queryParams += "type=$Type" }
    if ($Expand) { $queryParams += "expand=$Expand" }
    if ($ExcludePositions) { $queryParams += "excludePositions=$ExcludePositions" }
    if ($TraceType) { $queryParams += "traceType=$TraceType" }
    if ($TraceNumber) { $queryParams += "traceNumber=$TraceNumber" }
    
    # Build URI
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/orders$queryString"
    
    Write-Verbose "GET $uri"
    
    # Make API call
    try {
        # Use Invoke-RestMethod for simpler error handling
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap array from response object
            if ($response.orders) {
                return $response.orders
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
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
            return $null
        }
    }
}

