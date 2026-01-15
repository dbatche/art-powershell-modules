function Get-ApInvoices {
    <#
    .SYNOPSIS
        Retrieves accounts payable invoice records [/apInvoices]
    
    .DESCRIPTION
        GET /apInvoices or /apInvoices/{apInvoiceId}
        Retrieves accounts payable invoice records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.
        
        AP invoices represent vendor invoices for payment processing.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER ApInvoiceId
        Optional. Specific AP invoice ID to retrieve.
        If omitted, returns collection of AP invoices.
        Required for: /apInvoices/{apInvoiceId}
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "vendorId eq 'V12345' and status eq 'POSTED'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "apInvoiceId,vendorId,invoiceNumber,amount,status"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "invoiceDate desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER Expand
        Optional. Comma-separated list of sub-resources to include in response.
        Supported values (per OpenAPI spec):
        - "expenses" - Include expense line items
        - "apDriverDeductions" - Include driver deduction details
        - "ista" - Include ISTA-related data
        Example: "expenses,apDriverDeductions"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-ApInvoices
        # Returns all AP invoice records
    
    .EXAMPLE
        Get-ApInvoices -ApInvoiceId 123
        # Returns AP invoice 123
    
    .EXAMPLE
        Get-ApInvoices -Filter "vendorId eq 'V12345'" -OrderBy "invoiceDate desc"
        # Returns AP invoices for vendor V12345, newest first
    
    .EXAMPLE
        Get-ApInvoices -Filter "amount gt 1000 and status eq 'POSTED'" -Limit 10
        # Returns first 10 posted invoices over $1000
    
    .EXAMPLE
        Get-ApInvoices -Select "apInvoiceId,vendorId,invoiceNumber,amount" -Limit 100
        # Returns specific fields for up to 100 invoices
    
    .EXAMPLE
        Get-ApInvoices -ApInvoiceId 123 -Expand "expenses"
        # Returns AP invoice 123 with expanded expense line items
    
    .EXAMPLE
        Get-ApInvoices -Filter "status eq 'PENDING'" -Expand "expenses,apDriverDeductions" -Limit 20
        # Returns first 20 pending invoices with expenses and driver deductions
    
    .EXAMPLE
        # Pagination: Get second page of 50 records
        Get-ApInvoices -Limit 50 -Offset 50 -OrderBy "invoiceDate desc"
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-ApInvoices -ApInvoiceId 'ABC'
        Get-ApInvoices -Limit 'many'
    
    .OUTPUTS
        Single AP invoice object or array of AP invoice objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $ApInvoiceId,  # No type constraint - allows testing with invalid types
        
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
        [string]$BaseUrl = ($env:FINANCE_API_URL),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
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
    
    # Build URI
    $endpoint = "/apInvoices"
    
    if ($ApInvoiceId) {
        # Get specific AP invoice
        $uri = "$BaseUrl$endpoint/$ApInvoiceId"
        
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
            if ($ApInvoiceId) {
                # Single item - unwrap from response object
                if ($response.apInvoice) {
                    return $response.apInvoice
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.apInvoices) {
                    return $response.apInvoices
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

