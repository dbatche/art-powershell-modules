function Get-UserFieldsData {
    <#
    .SYNOPSIS
        Retrieves user-defined fields data [/userFieldsData]
    
    .DESCRIPTION
        GET /userFieldsData
        Retrieves user-defined custom fields data from TM API.
        Requires query parameters to specify which source and field to retrieve.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER SourceType
        Required by API. Type of source record.
        Valid values: 'orderInterliner', 'tripCarrier', 'order', 'pickupRequest'
    
    .PARAMETER SourceId
        ID of the source record
        Optional query parameter
    
    .PARAMETER UserField
        User field number to retrieve
        Optional query parameter
    
    .PARAMETER UserData
        User data parameter (TM API specific)
        Optional query parameter
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-UserFieldsData -SourceType order -SourceId 123
        # Returns user field data for order 123
    
    .EXAMPLE
        Get-UserFieldsData -SourceType orderInterliner -Limit 10
        # Returns first 10 order interliner user fields
    
    .EXAMPLE
        Get-UserFieldsData -SourceType tripCarrier -UserField 1
        # Returns user field 1 data for all trip carriers
    
    .EXAMPLE
        # API Testing: Test validation
        Get-UserFieldsData -Limit 1  # Missing SourceType
        Get-UserFieldsData -SourceType invalid  # Invalid SourceType
    
    .NOTES
        Query parameters are critical for this endpoint.
        The combination of SourceType, SourceId, UserField, and UserData determines what data is retrieved.
        
        TM API source types differ from Finance API:
        - TM: orderInterliner, tripCarrier, order, pickupRequest
        - Finance: driverStatements, apInvoices
    
    .OUTPUTS
        Array of user fields data objects or single object, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [ArgumentCompleter({ @('orderInterliner','tripCarrier','order','pickupRequest') })]
        [string]$SourceType,
        
        $SourceId,   # No type constraint
        $UserField,  # No type constraint
        $UserData,   # No type constraint
        $Limit,      # No type constraint
        $Offset,     # No type constraint
        
        [string]$BaseUrl = ($env:TM_API_URL),
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        [switch]$PassThru
    )
    
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Accept' = 'application/json'
    }
    
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
    
    if ($PSBoundParameters.ContainsKey('UserData')) {
        $queryParams += "userData=$UserData"
    }
    
    # Add pagination parameters
    if ($Limit) { $queryParams += "limit=$Limit" }
    if ($Offset) { $queryParams += "offset=$Offset" }
    
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/userFieldsData$queryString"
    
    Write-Verbose "GET $uri"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap data from response
            if ($response.userFieldsData) {
                return $response.userFieldsData
            } else {
                return $response
            }
        }
    }
    catch {
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