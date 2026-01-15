function New-ApInvoice {
    <#
    .SYNOPSIS
        Creates new accounts payable invoice(s) in TruckMate [POST /apInvoices]
    
    .DESCRIPTION
        POST /apInvoices
        Creates one or more accounts payable invoice records.
        
        AP invoices represent vendor invoices for payment processing and can be 
        viewed in the finance applications.
        
        Request body is an array of AP invoice objects (not wrapped in a property).
        
        REQUIRED FIELDS (per OpenAPI spec):
        - vendorId (string, max 10 chars)
        - vendorBillNumber (string, max 20 chars)
        - vendorBillDate (string, date format)
        - currencyCode (string, max 3 chars)
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Body
        Required. Array of hashtables or PSCustomObjects containing the AP invoice data.
        Each invoice must include required fields: vendorId, vendorBillNumber, 
        vendorBillDate, currencyCode.
        
        Example structure:
        @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-2025-001"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1500.00
                payableType = "bill"
                # ... other optional properties
            }
        )
        
        Optional properties include:
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
        - expenses (array) - for creating expense line items
        - apDriverDeductions (array) - for creating driver deductions
        - ista (array) - for sales tax information
    
    .PARAMETER Select
        Optional. OData $select expression for specific fields to return.
        Example: "apInvoiceId,vendorId,vendorBillNumber,vendorBillAmount"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        $invoice = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-2025-001"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1500.00
                payableType = "bill"
            }
        )
        New-ApInvoice -Body $invoice
        # Creates a new AP invoice
    
    .EXAMPLE
        # Create multiple invoices at once
        $invoices = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-001"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1500.00
            },
            @{
                vendorId = "V67890"
                vendorBillNumber = "INV-002"
                vendorBillDate = "2025-10-20"
                currencyCode = "CAD"
                vendorBillAmount = 2000.00
            }
        )
        New-ApInvoice -Body $invoices
    
    .EXAMPLE
        # Create with specific fields returned
        New-ApInvoice -Body $invoice -Select "apInvoiceId,vendorId,vendorBillAmount"
    
    .EXAMPLE
        # Create invoice with expense line items
        $invoiceWithExpenses = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-003"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1000.00
                expenses = @(
                    @{
                        expenseGlAccount = "00-5000"
                        expenseAmount = 500.00
                    },
                    @{
                        expenseGlAccount = "00-5100"
                        expenseAmount = 500.00
                    }
                )
            }
        )
        New-ApInvoice -Body $invoiceWithExpenses
    
    .EXAMPLE
        # API Testing: Test validation errors
        New-ApInvoice -Body @()  # Empty array
        New-ApInvoice -Body @(@{vendorId = "TEST"})  # Missing required fields
    
    .OUTPUTS
        On success: Created AP invoice object(s) (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    
    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Body,  # No type constraint - allows testing with invalid types
        
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
    $uri = "$BaseUrl/apInvoices$queryString"
    
    Write-Verbose "POST $uri"
    
    # Convert body to JSON (API expects a direct array, not wrapped)
    $jsonBody = $Body | ConvertTo-Json -Depth 10 -AsArray
    Write-Verbose "Request Body: $jsonBody"
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap invoices from response object
            if ($response.apInvoices) {
                return $response.apInvoices
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

