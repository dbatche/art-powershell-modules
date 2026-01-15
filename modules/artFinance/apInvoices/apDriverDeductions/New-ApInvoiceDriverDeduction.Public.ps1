function New-ApInvoiceDriverDeduction {
    <#
    .SYNOPSIS
        Creates new driver deduction(s) for an AP Invoice [POST /apInvoices/{apInvoiceId}/apDriverDeductions]
    
    .PARAMETER ApInvoiceId
        Required. The AP Invoice ID to add driver deductions to. Used in path: /apInvoices/{apInvoiceId}/apDriverDeductions
    
    .PARAMETER Body
        Required. Array of driver deduction data.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object
    
    .EXAMPLE
        New-ApInvoiceDriverDeduction -ApInvoiceId 12345 -Body @(@{ driverId = "DRV001"; amount = 25.00 })
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
    $uri = "$BaseUrl/apInvoices/$ApInvoiceId/apDriverDeductions"
    
    $jsonBody = $Body | ConvertTo-Json -Depth 10 -AsArray
    Write-Verbose "POST $uri"
    Write-Verbose "Body: $jsonBody"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        if ($PassThru) { return $response } else { return $response }
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


