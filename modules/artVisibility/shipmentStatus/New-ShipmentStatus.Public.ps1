function New-ShipmentStatus {
    <#
    .SYNOPSIS
        Creates new shipment status record(s) in Visibility [POST /shipmentStatus]
    
    .DESCRIPTION
        POST /visibility/shipmentStatus
        Creates a new shipment status record.
        
        Shipment status updates can be used to track shipment progress.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Body
        Required. Hashtable or PSCustomObject containing the shipment status data.
        
        Required fields:
        - shipmentStatus: integer
        - tripId: string (max 40 chars)
        
        Example structure:
        @{
            shipmentStatus = 1
            tripId = "TRIP-12345"
        }
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:VISIBILITY_API_URL or localhost
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .PARAMETER DryRun
        Shows the request that would be sent without actually executing it.
        Outputs Method, Uri, Headers (with token masked), and Body.
        Useful for debugging, documentation, and learning.
    
    .EXAMPLE
        $statusBody = @{
            shipmentStatus = 1
            tripId = "TRIP-12345"
        }
        New-ShipmentStatus -Body $statusBody
        # Creates a new shipment status record
    
    .EXAMPLE
        # Show the request without executing it (useful for debugging)
        New-ShipmentStatus -Body $statusBody -DryRun
        # Outputs: Method, Uri, Headers (token masked), and Body
    
    .EXAMPLE
        # API Testing: Test validation errors
        New-ShipmentStatus -Body @{}  # Missing required fields
        New-ShipmentStatus -Body @{ tripId = "x" * 50 }  # Exceeds maxLength
    
    .OUTPUTS
        On success: Created shipment status object (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Body,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = ($env:VISIBILITY_API_URL),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
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
    
    # Build URI (no query parameters for this endpoint)
    $uri = "$BaseUrl/shipmentStatus"
    
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
            # Return the response directly (single object)
            return $response
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

