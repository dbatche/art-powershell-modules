function Find-Vendors {
    <#
    .SYNOPSIS
        Searches for vendors using filters and query parameters [/vendors]
    
    .DESCRIPTION
        GET /masterData/vendors
        Retrieves a collection of vendor records with optional filtering,
        selection, ordering, and pagination.
        
        For retrieving a single vendor by ID, use Get-Vendor instead.
        
        Vendor profiles can be viewed in the Customer & Vendor Profiles 
        application > Vendor tab.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Filter
        Optional. OData $filter expression for filtering results.
        Example: "vendorCode eq ABC123 and isInactive eq False"
        Note: Avoid using quoted strings in filter values due to API JSON escaping issues.
    
    .PARAMETER Select
        Optional. OData $select expression for returning specific fields.
        Example: "vendorCode,name,isInactive"
    
    .PARAMETER OrderBy
        Optional. OData $orderby expression for sorting results.
        Example: "name desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
        Default: API default
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
        Useful for paging through large result sets.
    
    .PARAMETER Expand
        Optional. Comma-separated list of sub-resources to include in response.
        Supported values: "aChargeCodes", "aChargeSplits", "contacts", 
        "customDefs", "d83s", "discounts", "rateSheetLinks", 
        "tariffClasses", "tariffClasses/multiServiceLevels", "travelModes"
        Example: "contacts,rateSheetLinks"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:MASTERDATA_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data array
    
    .EXAMPLE
        Find-Vendors -Filter "vendorCode eq ABC123" -Limit 10
        # Returns first 10 vendors matching code ABC123
    
    .EXAMPLE
        Find-Vendors -Filter "isInactive eq False" -OrderBy "name" -Limit 20
        # Returns 20 active vendors sorted by name
    
    .EXAMPLE
        Find-Vendors -Expand "contacts,rateSheetLinks" -Select "vendorCode,name"
        # Returns vendors with expanded contacts and rate sheets, showing only selected fields
    
    .EXAMPLE
        # Pagination: Get second page of 50 records
        Find-Vendors -Limit 50 -Offset 50
    
    .EXAMPLE
        # Get all active vendors
        Find-Vendors -Filter "isInactive eq False"
    
    .EXAMPLE
        # Find vendors with specific currency
        Find-Vendors -Filter "currency eq 'USD'" -Select "vendorId,vendorCode,name,currency"
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Find-Vendors -Limit 'many'
    
    .NOTES
        For retrieving a single vendor by ID, use Get-Vendor instead
    
    .OUTPUTS
        On success: Array of vendor objects (or full response if -PassThru)
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
    $uri = "$BaseUrl/vendors$queryString"
    
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
            if ($response.vendors) {
                return $response.vendors
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

