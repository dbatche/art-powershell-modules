function New-ApInvoiceExpense {
    <#
    .SYNOPSIS
        Creates new expense line item(s) for an AP Invoice [POST /apInvoices/{apInvoiceId}/expenses]
    
    .DESCRIPTION
        POST /finance/apInvoices/{apInvoiceId}/expenses
        Creates one or more expense line items for an existing AP Invoice.
        
        Expense line items represent individual expense details on an AP Invoice.
    
    .PARAMETER ApInvoiceId
        Required. The AP Invoice ID to add expenses to.
    
    .PARAMETER Body
        Required. Array of hashtables or PSCustomObjects containing the expense data.
        
        Example structure:
        @(
            @{
                glAccount = "1000-00-0000"
                expenseAmount = 100.50
                # ... other properties
            }
        )
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        $expenses = @(
            @{
                glAccount = "1000-00-0000"
                expenseAmount = 100.50
            }
        )
        New-ApInvoiceExpense -ApInvoiceId 12345 -Body $expenses
    
    .OUTPUTS
        On success: Created expense object(s)
        On error: JSON string containing error details
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $ApInvoiceId,
        
        [Parameter(Mandatory=$true, Position=1)]
        $Body,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = ($env:FINANCE_API_URL),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )
    
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    
    $BaseUrl = $BaseUrl.TrimEnd('/')
    $uri = "$BaseUrl/apInvoices/$ApInvoiceId/expenses"
    
    Write-Verbose "POST $uri"
    
    $jsonBody = $Body | ConvertTo-Json -Depth 10 -AsArray
    Write-Verbose "Request Body: $jsonBody"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        
        if ($PassThru) {
            return $response
        }
        else {
            return $response
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            return $_.ErrorDetails.Message
        }
        else {
            Write-Error $_.Exception.Message
            return $null
        }
    }
}


