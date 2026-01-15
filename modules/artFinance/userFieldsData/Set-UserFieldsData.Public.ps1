function Set-UserFieldsData {
    <#
    .SYNOPSIS
        Updates user-defined fields data
    
    .DESCRIPTION
        PUT /userFieldsData
        Updates user-defined custom field data in Finance API.
        Requires query parameters to specify which source and field to update.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER SourceType
        Type of source record (e.g., 'driverStatements', 'bills', 'trips')
        Required query parameter.
    
    .PARAMETER SourceId
        ID of the source record
        Optional query parameter (may be required depending on API version)
    
    .PARAMETER UserField
        User field number to update
        Required query parameter
    
    .PARAMETER UserData
        The value to set for the user field.
        Can be string, number, or object depending on field type.
    
    .PARAMETER Select
        Optional. OData select expression for response fields.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the API response object
    
    .EXAMPLE
        Set-UserFieldsData -SourceType 'driverStatements' -SourceId 123 -UserField 1 -UserData 'CustomValue'
        # Sets user field 1 to 'CustomValue' for driver statement 123
    
    .EXAMPLE
        Set-UserFieldsData -SourceType 'bills' -UserField 2 -UserData @{ field = 'value' }
        # Sets user field 2 with object data
    
    .EXAMPLE
        # Update multiple records in a pipeline
        Get-UserFieldsData -SourceType 'trips' | ForEach-Object {
            Set-UserFieldsData -SourceType 'trips' -SourceId $_.sourceId -UserField 1 -UserData 'Updated'
        }
    
    .NOTES
        Query parameters are critical for this endpoint.
        The combination of SourceType, SourceId, and UserField determines which field is updated.
        
        Body format: { "userData": "value" }
    
    .OUTPUTS
        Updated user fields data object
    #>
    
    [CmdletBinding()]
    param(
        [ArgumentCompleter({ @('driverStatements','apInvoices') })]
        [Parameter(Mandatory=$false)]
        [string]$SourceType,
        
        [Parameter(Mandatory=$false)]
        $SourceId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        $UserField,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [object]$UserData,
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
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
        'Content-Type' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build query parameters (critical for this endpoint!)
    $queryParams = @()
    
    # Add source-specific parameters
    if ($PSBoundParameters.ContainsKey('SourceType')) {
        $queryParams += "sourceType=$SourceType"
    }
    
    if ($PSBoundParameters.ContainsKey('SourceId')) {
        $queryParams += "sourceId=$SourceId"
    }
    
    if ($PSBoundParameters.ContainsKey('UserField')) {
        $queryParams += "userField=$UserField"
    }
    
    # Add OData parameters
    if ($Select) { $queryParams += "`$select=$Select" }
    
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/userFieldsData$queryString"
    
    # Build request body
    $body = @{}
    if ($PSBoundParameters.ContainsKey('UserData')) {
        $body.userData = $UserData
    }
    
    $jsonBody = $body | ConvertTo-Json -Depth 10
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $jsonBody"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $jsonBody -ContentType 'application/json'
        
        # Log successful response
        Write-Verbose "Success Response: $($response | ConvertTo-Json -Depth 10 -Compress)"
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap to get the actual data (returns array)
            if ($response.userFieldsData) {
                # Return first item if single result, otherwise return array
                if ($response.userFieldsData.Count -eq 1) {
                    return $response.userFieldsData[0]
                } else {
                    return $response.userFieldsData
                }
            } else {
                return $response
            }
        }
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            Write-Verbose "Error Response: $($_.ErrorDetails.Message)"
            $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
            Write-Verbose "Exception: $($_.Exception.Message)"
        }
    }
}

