function Get-GlAccounts {
    <#
    .SYNOPSIS
        Retrieves general ledger account records
    
    .DESCRIPTION
        GET /glAccounts
        Retrieves general ledger account records from the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "status eq 'ACTIVE'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "glAccountId,accountNumber,description"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "accountNumber"
    
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
        Get-GlAccounts
        # Returns all records
    
    .EXAMPLE
        Get-GlAccounts -Filter "accountType eq 'ASSET'" -OrderBy "accountNumber"
        # Returns filtered and sorted records
    
    .EXAMPLE
        Get-GlAccounts -Limit 100 -Offset 0
        # Returns first page of 100 records
    
    .EXAMPLE
        Get-GlAccounts -Select "glAccountId,accountNumber,description" -Limit 50
        # Returns specific fields for up to 50 records
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-GlAccounts -Limit 'many'
    
    .OUTPUTS
        Array of glAccount objects, or JSON error string for testability
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
    $uri = "$BaseUrl/glAccounts$queryString"
    
    Write-Verbose "GET $uri"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        if ($PassThru) {
            return $response
        }
        else {
            if ($response.glAccounts) {
                return $response.glAccounts
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
