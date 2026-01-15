function Get-UserFieldsData {
    <#
    .SYNOPSIS
        Retrieves user-defined fields data [/userFieldsData]
    
    .DESCRIPTION
        GET /userFieldsData
        Retrieves user-defined custom fields data from Finance API.
        Requires query parameters to specify which source and field to retrieve.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER SourceType
        Required by API. Type of source record.
        Valid values: 'driverStatements', 'apInvoices'
    
    .PARAMETER SourceId
        ID of the source record
        Optional query parameter (may be required depending on API version)
    
    .PARAMETER UserField
        User field number to retrieve
        Optional query parameter
    
    .PARAMETER Filter
        Optional. OData filter expression.
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "userFieldValue,sourceId"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-UserFieldsData -SourceType driverStatements -SourceId 123
        # Returns user field data for driver statement 123
    
    .EXAMPLE
        Get-UserFieldsData -SourceType apInvoices -Select "userFieldValue,sourceId"
        # Returns specific fields for all AP invoice user fields
    
    .EXAMPLE
        Get-UserFieldsData -SourceType driverStatements -Filter "userFieldValue ne null"
        # Returns all driver statement user fields that have values
    
    .NOTES
        Query parameters are critical for this endpoint.
        The combination of SourceType, SourceId, and UserField determines what data is retrieved.
    
    .OUTPUTS
        Array of user fields data objects or single object
    #>
    
    [CmdletBinding()]
    param(
        [ArgumentCompleter({ @('driverStatements','apInvoices') })]
        [string]$SourceType,
        
        $SourceId,  # No type constraint
        $UserField,  # No type constraint
        
        [Parameter(Mandatory=$false)]
        [string]$Filter,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
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
    
    # Build query parameters (critical for this endpoint!)
    $queryParams = @()
    
    # Add source-specific parameters
    if ($SourceType) {
        $queryParams += "sourceType=$SourceType"
    }
    
    if ($PSBoundParameters.ContainsKey('SourceId')) {
        $queryParams += "sourceId=$SourceId"
    }
    
    if ($PSBoundParameters.ContainsKey('UserField')) {
        $queryParams += "userField=$UserField"
    }
    
    # Add OData parameters
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Select) { $queryParams += "`$select=$Select" }
    if ($Limit) { $queryParams += "limit=$Limit" }
    if ($Offset) { $queryParams += "offset=$Offset" }
    
    $queryString = "?" + ($queryParams -join '&')
    $uri = "$BaseUrl/userFieldsData$queryString"
    
    Write-Verbose "GET $uri"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap array
            if ($response.userFieldsData) {
                return $response.userFieldsData
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

