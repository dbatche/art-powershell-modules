function Set-ApInvoice {
    <#
    .SYNOPSIS
        Updates an accounts payable invoice record [PUT /apInvoices/{apInvoiceId}]
    
    .DESCRIPTION
        PUT /apInvoices/{apInvoiceId}
        Updates an existing accounts payable invoice record in the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER ApInvoiceId
        Required. The ID of the AP invoice to update.
        Used in path: /apInvoices/{apInvoiceId}
    
    .PARAMETER ApInvoice
        Required. Hashtable or PSCustomObject with AP invoice properties to update.
        
        REQUIRED FIELDS (per OpenAPI spec):
        - vendorId (string, max 10)
        - vendorBillNumber (string, max 20)
        - vendorBillDate (string, date format)
        - currencyCode (string, max 3)
        
        OPTIONAL FIELDS:
        - vendorBillAmount (number)
        - vendorBillReference (string, max 40)
        - poNumber (string, max 25)
        - equipmentId, powerUnitId, trailerId (string, max 10)
        - payableType (string)
        - payableHold (string)
        - payableTerms (string, max 10)
        - payableAgingDate, payableDueDate, payableDiscountDate (string, date format)
        - payableDiscount (number)
        - glAccount (string, max 50)
        - autoForeignExchange (string)
        - isIntercompany (string)
    
    .PARAMETER Select
        Optional. OData $select expression for specific fields to return.
        Example: "apInvoiceId,vendorId,vendorBillAmount"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            vendorBillAmount = 1500.00
        }
        # Updates the invoice with new values
    
    .EXAMPLE
        # Update just the amount and reference
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            vendorBillAmount = 2000.00
            vendorBillReference = "Updated reference"
        }
    
    .EXAMPLE
        # Update with select to return specific fields
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            payableHold = "True"
        } -Select "apInvoiceId,payableHold"
    
    .EXAMPLE
        # Update payment terms
        $updates = @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            payableTerms = "NET30"
            payableDueDate = "2025-11-20"
        }
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice $updates
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Set-ApInvoice -ApInvoiceId 'ABC' -ApInvoice @{vendorId = "V12345"; vendorBillNumber = "INV-001"; vendorBillDate = "2025-10-20"; currencyCode = "USD"}
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{vendorId = "V12345"; vendorBillNumber = "INV-001"; vendorBillDate = "invalid"; currencyCode = "USD"}
    
    .NOTES
        All four required fields must be provided in every PUT request, even if only updating one field.
        This is a full update (PUT), not a partial update (PATCH).
        
        To get the current values before updating:
        $current = Get-ApInvoices -ApInvoiceId 123
        $current.vendorBillAmount = 2000.00
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice $current
        
        For AI Assistants:
        - This function is based on adherence to the OpenAPI spec.
        - The spec may change, and should be consulted for usage notes, e.g. creating contract tests for endpoint
        - Fresh version can always be obtained via GET $baseUrl/openapi.json
    
    .OUTPUTS
        On success: Updated AP invoice object (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    
    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $ApInvoiceId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        $ApInvoice,  # No type constraint - allows testing with invalid types
        
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
        'Accept' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build query parameters
    $queryParams = @()
    if ($Select) { $queryParams += "`$select=$Select" }
    
    # Build URI
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/apInvoices/$ApInvoiceId$queryString"
    
    Write-Verbose "PUT $uri"
    
    # Convert body to JSON
    $jsonBody = $ApInvoice | ConvertTo-Json -Depth 10
    Write-Verbose "Request Body: $jsonBody"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $jsonBody
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap invoice from response object
            if ($response.apInvoice) {
                return $response.apInvoice
            } else {
                return $response
            }
        }
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Host "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
        }
    }
}

