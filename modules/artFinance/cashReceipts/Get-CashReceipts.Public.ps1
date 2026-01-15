function Get-CashReceipts {
    <#
    .SYNOPSIS
        Retrieves cash receipt records
    
    .DESCRIPTION
        GET /cashReceipts or /cashReceipts/{cashReceiptId}
        Retrieves cash receipt records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER CashReceiptId
        Optional. Specific cash receipt ID to retrieve.
        If omitted, returns collection of cash receipts.
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "customerId eq '12345' and status eq 'POSTED'"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "cashReceiptId,amount,receiptDate,paymentMethod"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "receiptDate desc"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
    
    .PARAMETER Expand
        Optional. OData expand query parameter to include related entities.
        Example: "invoices" to include invoice details in the response.
        Note: Not documented in OpenAPI spec but supported by API.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-CashReceipts
        # Returns all cash receipt records
    
    .EXAMPLE
        Get-CashReceipts -CashReceiptId 123
        # Returns cash receipt 123
    
    .EXAMPLE
        Get-CashReceipts -Filter "customerId eq '12345'" -OrderBy "receiptDate desc"
        # Returns cash receipts for customer 12345, newest first
    
    .EXAMPLE
        Get-CashReceipts -Filter "amount gt 1000 and status eq 'POSTED'" -Limit 10
        # Returns first 10 posted receipts over $1000
    
    .EXAMPLE
        Get-CashReceipts -Select "cashReceiptId,amount,receiptDate" -Limit 100
        # Returns specific fields for up to 100 receipts
    
    .EXAMPLE
        Get-CashReceipts -CashReceiptId 123 -Expand "invoices"
        # Returns cash receipt 123 with expanded invoice details
    
    .EXAMPLE
        Get-CashReceipts -Filter "amount gt 1000" -Expand "invoices" -Limit 10
        # Returns first 10 receipts over $1000 with invoice details
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Get-CashReceipts -CashReceiptId 'ABC'
        Get-CashReceipts -Limit 'many'
    
    .OUTPUTS
        Single cash receipt object or array of cash receipt objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        $CashReceiptId,  # No type constraint - allows testing with invalid types
        
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
    $endpoint = "/cashReceipts"
    
    if ($CashReceiptId) {
        # Get specific cash receipt
        $uri = "$BaseUrl$endpoint/$CashReceiptId"
        
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
            if ($CashReceiptId) {
                # Single item - unwrap from response object
                if ($response.cashReceipt) {
                    return $response.cashReceipt
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.cashReceipts) {
                    return $response.cashReceipts
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

