function Get-InterlinerPayables {
    <#
    .SYNOPSIS
        Retrieves interliner payable records
    
    .DESCRIPTION
        GET /interlinerPayables or /interlinerPayables/{interlinerPayableId}
        Retrieves interliner payable records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER InterlinerPayableId
        Optional. Specific interliner payable ID to retrieve.
        If omitted, returns collection of interliner payables.
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "carrierId eq '12345' and status eq 'OPEN'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "interlinerPayableId,amount,invoiceNumber,carrierId"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "invoiceDate desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-InterlinerPayables
        # Returns all interliner payable records
    
    .EXAMPLE
        Get-InterlinerPayables -InterlinerPayableId 123
        # Returns interliner payable 123
    
    .EXAMPLE
        Get-InterlinerPayables -Filter "carrierId eq '12345'" -OrderBy "invoiceDate desc"
        # Returns interliner payables for carrier 12345, newest first
    
    .EXAMPLE
        Get-InterlinerPayables -Filter "amount gt 1000 and status eq 'OPEN'" -Limit 10
        # Returns first 10 open payables over $1000
    
    .EXAMPLE
        Get-InterlinerPayables -Select "interlinerPayableId,amount,invoiceNumber" -Limit 100
        # Returns specific fields for up to 100 payables
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-InterlinerPayables -InterlinerPayableId 'ABC'
        Get-InterlinerPayables -Limit 'many'
    
    .OUTPUTS
        Single interliner payable object or array of interliner payable objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $InterlinerPayableId,  # No type constraint - allows testing with invalid types
        
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
        [string]$BaseUrl = $env:FINANCE_API_URL,
        
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
    $endpoint = "/interlinerPayables"
    
    if ($InterlinerPayableId) {
        # Get specific interliner payable
        $uri = "$BaseUrl$endpoint/$InterlinerPayableId"
    }
    else {
        # Get collection with optional query parameters
        $queryParams = @()
        
        if ($Filter) { $queryParams += "`$filter=$Filter" }
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($OrderBy) { $queryParams += "`$orderby=$OrderBy" }
        if ($Limit) { $queryParams += "limit=$Limit" }
        if ($Offset) { $queryParams += "offset=$Offset" }
        
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
            if ($InterlinerPayableId) {
                # Single item - unwrap from response object
                if ($response.interlinerPayable) {
                    return $response.interlinerPayable
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.interlinerPayables) {
                    return $response.interlinerPayables
                } else {
                    return $response
                }
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

