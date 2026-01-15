function New-Order {
    <#
    .SYNOPSIS
        Creates new order(s) in TruckMate
    
    .DESCRIPTION
        POST /tm/orders
        Creates one or more new order (freight bill) records.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Body
        Required (unless -Interactive is used). Hashtable or PSCustomObject containing the order data.
        Must include an 'orders' array with at least one order object.
        
        Example structure:
        @{
            orders = @(
                @{
                    pickUpBy = "2025-10-20T10:00:00Z"
                    pickUpByEnd = "2025-10-20T12:00:00Z"
                    deliverBy = "2025-10-21T10:00:00Z"
                    deliverByEnd = "2025-10-21T12:00:00Z"
                    startZone = "BCVAN"
                    endZone = "ABCAL"
                    caller = @{ clientId = "ABC123" }
                }
            )
        }
    
    .PARAMETER Interactive
        Prompts for order fields interactively.
        Required fields per OpenAPI spec: pickUpBy, pickUpByEnd, deliverBy, deliverByEnd
        Also prompts for common optional fields: startZone, endZone, caller clientId
    
    .PARAMETER Type
        Optional. Order type indicator.
        Valid values: 'T' (Truckload), 'P' (Pickup request), 'Q' (Quote)
        Default: 'T' if not provided
    
    .PARAMETER CopyOrderId
        Optional. Create a new order or rate quote from an existing order or rate quote.
        Provide the order ID to copy from.
    
    .PARAMETER SaveAsDraft
        Optional. Save the order as a draft.
        - Incomplete web status for pickup requests
        - Entry truckload order
    
    .PARAMETER MasterOrderId
        Optional. Assigns the newly created record as a "child" (X-stop) of an existing order.
        Minimum: 1, Maximum: 2147483647
    
    .PARAMETER Select
        Optional. OData $select expression for specific fields to return.
        Example: "orderId,billNumber,currencyCode"
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:TM_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .PARAMETER DryRun
        Shows the request that would be sent without actually executing it.
        Outputs Method, Uri, Headers (with token masked), and Body.
        Useful for debugging, documentation, and learning.
    
    .EXAMPLE
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $orderBody = @{
            orders = @(
                @{
                    pickUpBy = $timestamp
                    pickUpByEnd = $timestamp
                    deliverBy = $timestamp
                    deliverByEnd = $timestamp
                    startZone = "BCVAN"
                    endZone = "ABCAL"
                    caller = @{ clientId = "12345" }
                }
            )
        }
        New-Order -Body $orderBody
        # Creates a new order
    
    .EXAMPLE
        New-Order -Type 'P' -Body $orderBody
        # Creates a new pickup request
    
    .EXAMPLE
        New-Order -Type 'Q' -Body $orderBody -SaveAsDraft 'True'
        # Creates a new quote saved as draft
    
    .EXAMPLE
        New-Order -CopyOrderId 12345 -Body $orderBody
        # Creates a new order by copying from order 12345
    
    .EXAMPLE
        New-Order -MasterOrderId 67890 -Body $orderBody
        # Creates a new order as a child (X-stop) of master order 67890
    
    .EXAMPLE
        # Create order and return only specific fields
        $response = New-Order -Body $orderBody -Select "orderId,billNumber,currencyCode"
    
    .EXAMPLE
        # Create order with expanded caller info
        $response = New-Order -Body $orderBody -PassThru
        $orderId = $response.orders[0].orderId
        Get-Order -OrderId $orderId -Expand "caller"
    
    .EXAMPLE
        # API Testing: Test validation errors
        New-Order -Body @{ orders = @() }  # Empty orders array
        New-Order -Body @{ invalid = "structure" }  # Invalid body
    
    .EXAMPLE
        # Show the request without executing it (useful for debugging)
        New-Order -Body $orderBody -Type 'T' -DryRun
        # Outputs: Method, Uri, Headers (token masked), and Body
    
    .EXAMPLE
        # Interactive mode - prompts for required and common fields
        New-Order -Interactive
        # Prompts for: pickUpBy, pickUpByEnd, deliverBy, deliverByEnd, startZone, endZone, caller clientId
    
    .OUTPUTS
        On success: Created order object(s) (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    #>
    
    [CmdletBinding(DefaultParameterSetName='Body')]
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Body')]
        $Body,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ParameterSetName='Interactive')]
        [switch]$Interactive,
        
        [Parameter(Mandatory=$false)]
        [string]$Type,  # T, P, Q
        
        [Parameter(Mandatory=$false)]
        $CopyOrderId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$SaveAsDraft,
        
        [Parameter(Mandatory=$false)]
        $MasterOrderId,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$Select,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = ($env:TM_API_URL),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    # Interactive mode - prompt for required and common fields
    if ($Interactive) {
        Write-Host "`nCreating New Order (Interactive Mode)" -ForegroundColor Cyan
        Write-Host ("=" * 50) -ForegroundColor Cyan
        Write-Host "Required fields: pickUpBy, pickUpByEnd, deliverBy, deliverByEnd" -ForegroundColor Yellow
        Write-Host "Press Enter to use defaults (based on current time).`n" -ForegroundColor Gray
        
        $order = @{}
        
        # Generate smart defaults based on current time
        $now = (Get-Date).ToUniversalTime()
        $defaultPickUpBy = $now.ToString("yyyy-MM-ddTHH:mm:ss")
        $defaultPickUpByEnd = $now.AddHours(2).ToString("yyyy-MM-ddTHH:mm:ss")
        $defaultDeliverBy = $now.AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss")
        $defaultDeliverByEnd = $now.AddDays(1).AddHours(2).ToString("yyyy-MM-ddTHH:mm:ss")
        
        # Required fields with defaults
        Write-Host "Required fields (press Enter for default):" -ForegroundColor Yellow
        
        $pickUpBy = Read-Host "Pick Up By [default: $defaultPickUpBy]"
        $order['pickUpBy'] = if ($pickUpBy) { $pickUpBy } else { $defaultPickUpBy }
        
        $pickUpByEnd = Read-Host "Pick Up By End [default: $defaultPickUpByEnd]"
        $order['pickUpByEnd'] = if ($pickUpByEnd) { $pickUpByEnd } else { $defaultPickUpByEnd }
        
        $deliverBy = Read-Host "Deliver By [default: $defaultDeliverBy]"
        $order['deliverBy'] = if ($deliverBy) { $deliverBy } else { $defaultDeliverBy }
        
        $deliverByEnd = Read-Host "Deliver By End [default: $defaultDeliverByEnd]"
        $order['deliverByEnd'] = if ($deliverByEnd) { $deliverByEnd } else { $defaultDeliverByEnd }
        
        # Optional common fields
        Write-Host "`nOptional fields:" -ForegroundColor Gray
        
        $startZone = Read-Host "Start Zone (max 10 chars)"
        if ($startZone) { $order['startZone'] = $startZone }
        
        $endZone = Read-Host "End Zone (max 10 chars)"
        if ($endZone) { $order['endZone'] = $endZone }
        
        $clientId = Read-Host "Caller Client ID"
        if ($clientId) { $order['caller'] = @{ clientId = $clientId } }
        
        # Build Body with orders array
        $Body = @{
            orders = @($order)
        }
        
        Write-Host "`nBuilt order body with $($order.Keys.Count) field(s)" -ForegroundColor Green
    }
    
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
    if ($Type) { $queryParams += "type=$Type" }
    if ($CopyOrderId) { $queryParams += "copyOrderId=$CopyOrderId" }
    if ($SaveAsDraft) { $queryParams += "saveAsDraft=$SaveAsDraft" }
    if ($MasterOrderId) { $queryParams += "masterOrderId=$MasterOrderId" }
    if ($Select) { $queryParams += "`$select=$Select" }
    
    # Build URI
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl/orders$queryString"
    
    Write-Verbose "POST $uri"
    
    # Convert body to JSON
    $jsonBody = $Body | ConvertTo-Json -Depth 10
    Write-Verbose "Request Body: $jsonBody"
    
    # DryRun mode - show request without executing
    if ($DryRun) {
        $maskedHeaders = $headers.Clone()
        if ($maskedHeaders['Authorization']) {
            $maskedHeaders['Authorization'] = "Bearer ***MASKED***"
        }
        
        return [PSCustomObject]@{
            Method = 'POST'
            Uri = $uri
            Headers = $maskedHeaders
            Body = ($Body | ConvertTo-Json -Depth 10)
        }
    }
    
    # Make API call
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        
        # Return response or unwrapped data
        if ($PassThru) {
            return $response
        }
        else {
            # Unwrap orders from response object
            if ($response.orders) {
                return $response.orders
            } else {
                return $response
            }
        }
    }
    catch {
        # Output error for interactive use and return JSON string for testability
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            return $_.ErrorDetails.Message
        }
        else {
            # Fallback for non-API errors
            Write-Error $_.Exception.Message
            return $null
        }
    }
}

