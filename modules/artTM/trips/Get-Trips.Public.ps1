function Get-Trips {
    <#
    .SYNOPSIS
        Retrieves trip records [/trips]
    
    .DESCRIPTION
        GET /trips or /trips/{tripNumber}
        Retrieves trip records from the TruckMate TM API.
        Can retrieve all records, filtered collection, or a specific one by trip number.
        
        Trips represent transportation trips with stops, freight bills, and resources.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER TripNumber
        Optional. Specific trip number to retrieve.
        If omitted, returns collection of trips.
        Required for: /trips/{tripNumber}
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "status eq 'ACTIVE' and driverId eq 'D12345'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "tripNumber,driverId,status,startDate"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "startDate desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER Expand
        Optional. Comma-separated list of sub-resources to include in response.
        Supported values (per OpenAPI spec):
        - "stops" - Include trip stops
        - "resources" - Include trip resources
        - "summary" - Include trip summary
        Example: "stops,resources"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL or $env:DOMAIN
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-Trips
        # Returns all trip records
    
    .EXAMPLE
        Get-Trips -TripNumber 12345
        # Returns trip 12345
    
    .EXAMPLE
        Get-Trips -Filter "status eq 'ACTIVE'" -OrderBy "startDate desc"
        # Returns active trips, newest first
    
    .EXAMPLE
        Get-Trips -Filter "driverId eq 'D12345' and startDate gt datetime'2026-01-01T00:00:00Z'" -Limit 10
        # Returns first 10 trips for driver D12345 after Jan 1, 2026
    
    .EXAMPLE
        Get-Trips -Select "tripNumber,driverId,status,startDate" -Limit 100
        # Returns specific fields for up to 100 trips
    
    .EXAMPLE
        Get-Trips -TripNumber 12345 -Expand "stops"
        # Returns trip 12345 with expanded stops
    
    .EXAMPLE
        Get-Trips -Filter "status eq 'ACTIVE'" -Expand "stops,resources" -Limit 20
        # Returns first 20 active trips with stops and resources
    
    .EXAMPLE
        # Pagination: Get second page of 50 records
        Get-Trips -Limit 50 -Offset 50 -OrderBy "startDate desc"
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-Trips -TripNumber 'ABC'
        Get-Trips -Limit 'many'
    
    .OUTPUTS
        Single trip object or array of trip objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $TripNumber,  # No type constraint - allows testing with invalid types
        
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
        [string]$BaseUrl,
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    # Validate token
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    # Set default BaseUrl if not provided
    if (-not $BaseUrl) {
        $BaseUrl = if ($env:TM_API_URL) { $env:TM_API_URL } else { $env:DOMAIN }
    }
    
    # Build headers
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Accept' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build URI
    $endpoint = "/trips"
    
    if ($TripNumber) {
        # Get specific trip
        $uri = "$BaseUrl$endpoint/$TripNumber"
        
        # Add expand parameter if specified (for single item)
        if ($Expand) {
            $uri += "?expand=$Expand"
        }
    }
    else {
        # Get collection with optional query parameters
        $queryParams = @()
        
        if ($Filter) { $queryParams += "`$filter=$Filter" }
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($OrderBy) { $queryParams += "`$orderby=$OrderBy" }
        if ($Limit) { $queryParams += "limit=$Limit" }
        if ($Offset) { $queryParams += "offset=$Offset" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        
        $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
        $uri = "$BaseUrl$endpoint$queryString"
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
            if ($TripNumber) {
                # Single item - unwrap from response object
                if ($response.trip) {
                    return $response.trip
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.trips) {
                    return $response.trips
                } elseif ($response.value) {
                    # Some APIs return collections as 'value'
                    return $response.value
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
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
        }
    }
}
