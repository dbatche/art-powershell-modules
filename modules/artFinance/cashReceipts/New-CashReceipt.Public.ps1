function New-CashReceipt {
    <#
    .SYNOPSIS
        Creates new cash receipt(s) in TruckMate
    
    .DESCRIPTION
        POST /cashReceipts
        Creates one or more cash receipt records.
        
        Cash receipts can be viewed in the AR Cash Receipts application.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Body
        Required. Hashtable or PSCustomObject containing the cash receipt data.
        Must include a 'cashReceipts' array with at least one cash receipt object.
        
        Example structure:
        @{
            cashReceipts = @(
                @{
                    transactionType = "CASH"
                    transactionDate = "2025-10-16"
                    transactionAmount = 1000.00
                    clientId = "12345"
                    # ... other properties
                }
            )
        }
    
    .PARAMETER Select
        Optional. OData $select expression for specific fields to return.
        Example: "cashReceiptId,transactionType,transactionAmount"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        $receiptBody = @{
            cashReceipts = @(
                @{
                    transactionType = "CASH"
                    transactionDate = "2025-10-16"
                    transactionAmount = 1000.00
                    clientId = "12345"
                }
            )
        }
        New-CashReceipt -Body $receiptBody
    
    .EXAMPLE
        # Create with specific fields returned
        New-CashReceipt -Body $receiptBody -Select "cashReceiptId,transactionAmount"
    
    .OUTPUTS
        PSCustomObject - The created cash receipt(s)
        OR
        String - JSON error message if API returns an error
    
    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        $Body,

        [Parameter(Mandatory = $false)]
        [string]$Select,

        [Parameter(Mandatory = $false)]
        [string]$BaseUrl = $env:FINANCE_API_URL,

        [Parameter(Mandatory = $false)]
        [string]$Token = $env:TRUCKMATE_API_KEY,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Validate required environment
    if (-not $BaseUrl) {
        throw "BaseUrl not provided and FINANCE_API_URL environment variable not set. Use Setup-EnvironmentVariables or provide -BaseUrl parameter."
    }
    if (-not $Token) {
        throw "Token not provided and TRUCKMATE_API_KEY environment variable not set. Use Setup-EnvironmentVariables or provide -Token parameter."
    }

    # Build URI with query parameters
    $uri = "$BaseUrl/cashReceipts"
    $queryParams = @()
    
    if ($Select) {
        $queryParams += "`$select=$Select"
    }
    
    if ($queryParams.Count -gt 0) {
        $uri += "?" + ($queryParams -join "&")
    }

    # Prepare headers
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }

    # Convert body to JSON
    $bodyJson = $Body | ConvertTo-Json -Depth 10

    Write-Verbose "POST $uri"
    Write-Verbose "Body: $bodyJson"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $bodyJson

        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap the response - typically returns cashReceipts array
            if ($response.PSObject.Properties['cashReceipts']) {
                return $response.cashReceipts
            }
            return $response
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

