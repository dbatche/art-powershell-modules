function Set-InterlinerPayable {
    <#
    .SYNOPSIS
        Updates an interliner payable record
    
    .DESCRIPTION
        PUT /interlinerPayables/{interlinerPayableId}
        Updates an existing interliner payable record in the Finance API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER InterlinerPayableId
        The ID of the interliner payable to update (required)
    
    .PARAMETER InterlinerPayable
        Hashtable with interliner payable properties to update.
        See NOTES for common properties.
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:FINANCE_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the API response object
    
    .EXAMPLE
        Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable @{
            amount = 1500.00
            status = 'APPROVED'
        }
        # Updates amount and status
    
    .EXAMPLE
        $payable = @{
            invoiceDate = '2024-01-15'
            amount = 2500.00
            invoiceNumber = 'INV-12345'
            carrierId = 'CARR001'
            status = 'PENDING'
            notes = 'Payment approved'
        }
        Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable $payable
        # Updates multiple fields
    
    .EXAMPLE
        # API Testing: Test invalid types (expect 400 errors)
        Set-InterlinerPayable -InterlinerPayableId 'ABC' -InterlinerPayable @{ amount = 100 }
        Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable @{ amount = 'heavy' }
    
    .NOTES
        Common properties (vary by API version):
        - amount, invoiceDate, invoiceNumber, carrierId
        - status, paymentDate, paymentMethod, referenceNumber
        - currencyCode, exchangeRate
        - orderIds (array of related order IDs)
        - notes, approvalDate, approvedBy
        
        Consult your API documentation for the complete list of available fields.
    
    .OUTPUTS
        Updated interliner payable object, or JSON error string for testability
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $InterlinerPayableId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]$InterlinerPayable,
        
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
    $uri = "$BaseUrl/interlinerPayables/$InterlinerPayableId"
    
    # Convert body to JSON
    $body = $InterlinerPayable | ConvertTo-Json -Depth 10
    
    Write-Verbose "PUT $uri"
    Write-Verbose "Body: $body"
    
    # WhatIf support
    if ($PSCmdlet.ShouldProcess("Interliner Payable $InterlinerPayableId", "Update")) {
        # Make API call
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
            
            # Return response or unwrapped data
            if ($PassThru) {
                return $response
            }
            else {
                # Unwrap if response has wrapper
                if ($response.interlinerPayable) {
                    return $response.interlinerPayable
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

