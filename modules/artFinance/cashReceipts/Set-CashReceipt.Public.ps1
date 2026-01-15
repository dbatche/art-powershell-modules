function Set-CashReceipt {
    <#
    .SYNOPSIS
        Updates a cash receipt record
    
    .DESCRIPTION
        PUT /cashReceipts/{cashReceiptId}
        Updates an existing cash receipt record in the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER CashReceiptId
        The ID of the cash receipt to update (required)
    
    .PARAMETER CashReceipt
        Hashtable with cash receipt properties to update.
        See NOTES for common properties.
    
    .PARAMETER Expand
        Optional. OData expand query parameter to include related entities.
        Example: "invoices" to include invoice details in the response.
        Note: Not documented in OpenAPI spec but supported by API.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the API response object
    
    .EXAMPLE
        Set-CashReceipt -CashReceiptId 123 -CashReceipt @{
            amount = 1500.00
            paymentMethod = 'CHECK'
        }
        # Updates amount and payment method
    
    .EXAMPLE
        $receipt = @{
            receiptDate = '2024-01-15'
            amount = 2500.00
            paymentMethod = 'ACH'
            referenceNumber = 'CHK12345'
            notes = 'Payment received'
        }
        Set-CashReceipt -CashReceiptId 123 -CashReceipt $receipt
        # Updates multiple fields
    
    .EXAMPLE
        Set-CashReceipt -CashReceiptId 123 -CashReceipt @{ amount = 1500 } -Expand "invoices"
        # Updates and returns cash receipt with expanded invoice details
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Set-CashReceipt -CashReceiptId 'ABC' -CashReceipt @{ amount = 100 }
        Set-CashReceipt -CashReceiptId 123 -CashReceipt @{ amount = 'heavy' }
    
    .NOTES
        Common properties (vary by API version):
        - amount, receiptDate, paymentMethod, referenceNumber
        - customerId, customerName, bankAccount
        - currencyCode, exchangeRate
        - appliedTo (array of applications to invoices/orders)
        - notes, status, postedDate
        
        Consult your API documentation for the complete list of available fields.
    
    .OUTPUTS
        Updated cash receipt object
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $CashReceiptId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]$CashReceipt,
        
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
        'Content-Type' = 'application/json'
    }
    
    # Trim base URL
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    # Build URI with query parameters
    $uri = "$BaseUrl/cashReceipts/$CashReceiptId"
    $queryParams = @()
    
    if ($Expand) {
        $queryParams += "expand=$Expand"
    }
    
    if ($queryParams.Count -gt 0) {
        $uri += "?" + ($queryParams -join "&")
    }
    
    # Convert body to JSON
    $body = $CashReceipt | ConvertTo-Json -Depth 10
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $body"
    
    # WhatIf support
    if ($PSCmdlet.ShouldProcess("Cash Receipt $CashReceiptId", "Update")) {
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Unwrap if response has wrapper
                if ($response.cashReceipt) {
                    return $response.cashReceipt
                }
                else {
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
}

