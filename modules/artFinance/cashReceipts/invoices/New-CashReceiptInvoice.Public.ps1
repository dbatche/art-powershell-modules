function New-CashReceiptInvoice {
    <#
    .SYNOPSIS
        Adds invoice(s) to an existing cash receipt
    
    .DESCRIPTION
        POST /cashReceipts/{cashReceiptId}/invoices
        Creates invoice payment records associated with a cash receipt in the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER CashReceiptId
        The ID of the cash receipt to add invoices to (required)
    
    .PARAMETER Invoices
        Array of invoice payment objects. Each invoice requires:
        - orderId (integer, required)
        - clientId (string, optional, max 10 chars)
        - paymentAmount (number, optional)
        - writeOffAmount (number, optional)
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        # Add single invoice to cash receipt
        $invoice = @{
            orderId = 12345
            clientId = "CLIENT001"
            paymentAmount = 500.00
        }
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices @($invoice)
    
    .EXAMPLE
        # Add multiple invoices
        $invoices = @(
            @{ orderId = 12345; paymentAmount = 500.00 }
            @{ orderId = 12346; paymentAmount = 250.00; writeOffAmount = 25.00 }
        )
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices $invoices
    
    .EXAMPLE
        # API Testing: Test invalid data types
        New-CashReceiptInvoice -CashReceiptId 'ABC' -Invoices @(@{ orderId = 123 })
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices @(@{ orderId = 'XYZ' })
    
    .NOTES
        TM-180953: Finance - Add POST /cashReceipts/{cashReceiptId}/invoices
        
        Invoice properties (from OpenAPI spec):
        - orderId (integer, required) - Order ID for the invoice
        - clientId (string, optional, max 10) - Client identifier
        - paymentAmount (number, optional) - Amount paid on invoice
        - writeOffAmount (number, optional) - Amount written off
        
        Response properties:
        - cashReceiptId, invoiceId, detailLineId
        - billNumber, clientId
        - paymentAmount, writeOffAmount (nullable)
    
    .OUTPUTS
        Array of created invoice payment records, or JSON error string for testability
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $CashReceiptId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [array]$Invoices,
        
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
    
    # Build URI
    $uri = "$BaseUrl/cashReceipts/$CashReceiptId/invoices"
    
    # Convert body to JSON - API expects a direct array, not wrapped in object
    $body = $Invoices | ConvertTo-Json -Depth 10 -AsArray
    
    Write-Verbose "POST $uri"
    Write-Verbose "Body: $body"
    
    # WhatIf support
    if ($PSCmdlet.ShouldProcess("Cash Receipt $CashReceiptId", "Add invoices")) {
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Unwrap if response has wrapper
                if ($response.invoices) {
                    return $response.invoices
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

