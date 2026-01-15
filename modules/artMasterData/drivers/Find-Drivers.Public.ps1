function Find-Drivers {
    <#
    .SYNOPSIS
        Searches for drivers using filters and query parameters [/drivers]
    
    .DESCRIPTION
        GET /masterData/drivers
        Retrieves a collection of driver records with optional filtering,
        selection, ordering, and pagination.
        
        For retrieving a single driver by ID, use Get-Driver instead.
        
        Driver profiles can be viewed in the Driver application.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Filter
        Optional. OData $filter expression for filtering results.
        Example: "driverCode eq 'DRV001' and isInactive eq False"
        Note: Avoid using quoted strings in filter values due to API JSON escaping issues.
    
    .PARAMETER Select
        Optional. OData $select expression for returning specific fields.
        Example: "driverCode,firstName,lastName,isInactive"
    
    .PARAMETER OrderBy
        Optional. OData $orderby expression for sorting results.
        Example: "lastName asc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
        Default: API default
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
        Useful for paging through large result sets.
    
    .PARAMETER Expand
        Optional. Comma-separated list of sub-resources to include in response.
        Example: "contacts"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:MASTERDATA_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data array
    
    .EXAMPLE
        Find-Drivers -Filter "driverCode eq 'DRV001'" -Limit 10
        # Returns first 10 drivers matching code DRV001
    
    .EXAMPLE
        Find-Drivers -Filter "isInactive eq False" -OrderBy "lastName" -Limit 20
        # Returns 20 active drivers sorted by last name
    
    .EXAMPLE
        Find-Drivers -Select "driverCode,firstName,lastName"
        # Returns drivers with only selected fields
    
    .EXAMPLE
        # Pagination: Get second page of 50 records
        Find-Drivers -Limit 50 -Offset 50
    
    .EXAMPLE
        # Get all active drivers
        Find-Drivers -Filter "isInactive eq False"
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Find-Drivers -Limit 'many'
    
    .NOTES
        For retrieving a single driver by ID, use Get-Driver instead
    
    .OUTPUTS
        On success: Array of driver objects (or full response if -PassThru)
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
        [string]$Expand,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = $env:MASTERDATA_API_URL,
        
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
    if ($Expand) { $queryParams += "expand=$Expand" }
    
    # Build URI
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/drivers$queryString"
    
    Write-Verbose "GET $uri"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap array from response object
            if ($response.drivers) {
                return $response.drivers
            } else {
                return $response
            }
        }
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
        }
    }
}

