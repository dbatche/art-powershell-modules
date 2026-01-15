function Get-DriverPaymentCodes {
    <#
    .SYNOPSIS
        Retrieves driver payment code records
    
    .DESCRIPTION
        GET /driverPaymentCodes
        Retrieves driver payment code records from the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "status eq 'ACTIVE'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "code,description"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "code"
    
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
        Get-DriverPaymentCodes
        # Returns all records
    
    .EXAMPLE
        Get-DriverPaymentCodes -Filter "isActive eq True" -OrderBy "code"
        # Returns filtered and sorted records
    
    .EXAMPLE
        Get-DriverPaymentCodes -Limit 100 -Offset 0
        # Returns first page of 100 records
    
    .EXAMPLE
        Get-DriverPaymentCodes -Select "code,description" -Limit 50
        # Returns specific fields for up to 50 records
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverPaymentCodes -Limit 'many'
    
    .OUTPUTS
        Array of driverPaymentCode objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [string]$Filter,
        [string]$Select,
        [string]$OrderBy,
        $Limit,
        $Offset,
        [string]$BaseUrl = $env:FINANCE_API_URL,
        [string]$Token = $env:TRUCKMATE_API_KEY,
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
    $queryParams = @()
    
    if ($Filter) { $queryParams += "`$filter=$Filter" }
    if ($Select) { $queryParams += "`$select=$Select" }
    if ($OrderBy) { $queryParams += "`$orderby=$OrderBy" }
    if ($Limit) { $queryParams += "limit=$Limit" }
    if ($Offset) { $queryParams += "offset=$Offset" }
    
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/driverPaymentCodes$queryString"
    
    Write-Verbose "GET $uri"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        if ($PassThru) {
            return $response
        }
        else {
            if ($response.driverPaymentCodes) {
                return $response.driverPaymentCodes
            } else {
                return $response
            }
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            Write-Error $_.Exception.Message
        }
    }
}
