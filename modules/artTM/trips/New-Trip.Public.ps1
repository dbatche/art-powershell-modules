function New-Trip {
    <#
    .SYNOPSIS
        Creates new trip(s) in TruckMate [POST /trips]
    
    .DESCRIPTION
        POST /tm/trips
        Creates one or more new trip records.
        
        Trips represent the movement of equipment/drivers from one location to another,
        and can include multiple stops.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER Body
        Required (unless -Interactive is used). Hashtable or PSCustomObject containing the trip data.
        
        Key fields (all optional but you likely need at least some):
        - powerUnit: string (max 10 chars) - truck/tractor
        - driver: string (max 10 chars) - driver ID
        - trailer: string (max 10 chars) - trailer ID
        - fromZone: string (max 10 chars) - starting location
        - toZone: string (max 10 chars) - ending location
        - stops: array - stop details with zone and resources
        - pickupDeliveryTrip: string ("True"/"False")
        - routeId: integer
        
        Example structure:
        @{
            powerUnit = "TRUCK001"
            driver = "DRV001"
            trailer = "TRL001"
            fromZone = "BCVAN"
            toZone = "ABCAL"
        }
    
    .PARAMETER Interactive
        Prompts for common trip fields interactively.
        Note: OpenAPI spec has NO required fields, but these are commonly needed:
        - powerUnit, driver, trailer, fromZone, toZone
    
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
        $tripBody = @{
            powerUnit = "TRUCK001"
            driver = "DRV001"
            trailer = "TRL001"
            fromZone = "BCVAN"
            toZone = "ABCAL"
        }
        New-Trip -Body $tripBody
        # Creates a new trip
    
    .EXAMPLE
        # Trip with stops
        $tripWithStops = @{
            powerUnit = "TRUCK001"
            driver = "DRV001"
            stops = @(
                @{
                    zone = "BCVAN"
                    resources = @("ORDER001")
                },
                @{
                    zone = "ABCAL"
                    resources = @("ORDER002")
                }
            )
        }
        New-Trip -Body $tripWithStops
    
    .EXAMPLE
        # Show the request without executing it (useful for debugging)
        New-Trip -Body $tripBody -DryRun
        # Outputs: Method, Uri, Headers (token masked), and Body
    
    .EXAMPLE
        # Interactive mode - prompts for common fields
        New-Trip -Interactive
        # Prompts for: powerUnit, driver, trailer, fromZone, toZone
    
    .EXAMPLE
        # API Testing: Test validation errors
        New-Trip -Body @{}  # Empty body
        New-Trip -Body @{ powerUnit = "x" * 20 }  # Exceeds maxLength
    
    .OUTPUTS
        On success: Created trip object (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)
    #>
    
    [CmdletBinding(DefaultParameterSetName='Body')]
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Body')]
        $Body,  # No type constraint - allows testing with invalid types
        
        [Parameter(Mandatory=$true, ParameterSetName='Interactive')]
        [switch]$Interactive,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = ($env:TM_API_URL),
        
        [Parameter(Mandatory=$false)]
        [string]$Token = ($env:TRUCKMATE_API_KEY),
        
        [Parameter(Mandatory=$false)]
        [switch]$PassThru,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    # Interactive mode - prompt for common fields
    if ($Interactive) {
        Write-Host "`nCreating New Trip (Interactive Mode)" -ForegroundColor Cyan
        Write-Host ("=" * 50) -ForegroundColor Cyan
        Write-Host "Note: OpenAPI spec has no required fields, but these are commonly needed." -ForegroundColor Yellow
        Write-Host "Press Enter to skip optional fields.`n" -ForegroundColor Gray
        
        $Body = @{}
        
        # Prompt for common fields
        $powerUnit = Read-Host "Power Unit (truck/tractor, max 10 chars)"
        if ($powerUnit) { $Body['powerUnit'] = $powerUnit }
        
        $driver = Read-Host "Driver ID (max 10 chars)"
        if ($driver) { $Body['driver'] = $driver }
        
        $trailer = Read-Host "Trailer (max 10 chars)"
        if ($trailer) { $Body['trailer'] = $trailer }
        
        $fromZone = Read-Host "From Zone (starting location, max 10 chars)"
        if ($fromZone) { $Body['fromZone'] = $fromZone }
        
        $toZone = Read-Host "To Zone (ending location, max 10 chars)"
        if ($toZone) { $Body['toZone'] = $toZone }
        
        Write-Host "`nBuilt trip body with $($Body.Keys.Count) field(s)" -ForegroundColor Green
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
    
    # Build URI (no query parameters for this endpoint)
    $uri = "$BaseUrl/trips"
    
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

