<#
.SYNOPSIS
    Retrieves a JWT token from the TruckMate ART server (/tm/login) using standard credentials.

.DESCRIPTION
    Authenticates directly with the ART server using the /tm/login endpoint.
    This bypasses Trimble Identity (TID) and uses TruckMate user credentials (or TM4Web credentials).
    The returned JWT can be used as a Bearer token for subsequent API calls.

.NOTES
	Steps in Truckmate to create a web-enabled client or vendor	
	Client/Vendor Profile ... Web Configuration Tab - set Web Enabled 
	WebAdmin ... Users - Vendors ... type in an access code (new or existing), e.g. WEB_VENDOR
	Also set the Feature Group (dropdown, eg. 'USER' or 'CARRIER')
	Vendor Profile ... refresh, check access code
	Add new web user (fill in user registration wizard fields with email, etc)
	RMC on web user, choose set password 
	
	Now run this utility with the contact name and their password
	POST http://{{domain}}/tm/login {username, password}
	>> returns JWT Token 

.PARAMETER BaseUrl
    The base URL of the ART server (e.g. "http://localhost:8888" or "https://myserver.com").
    The script will append "/tm/login" to this URL.

.PARAMETER Username
    The TruckMate/TM4Web username.

.PARAMETER Password
    The user's password.

.PARAMETER ShowFullResponse
    If specified, outputs the full response object instead of just the token string.

.EXAMPLE
    Get-TmJwtToken -BaseUrl "http://localhost:8888" -Username "SYS" -Password "password"
    Returns the JWT string.

.EXAMPLE
    $token = Get-TmJwtToken -BaseUrl "http://truckmate.example.com" -Username "ClientUser" -Password "pass123"
    Invoke-RestMethod -Uri "http://truckmate.example.com/tm/orders" -Headers @{ Authorization = "Bearer $token" }
#>
function Get-TmJwtToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$BaseUrl = $env:TM_API_URL,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Username,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Password,

        [Parameter()]
        [switch]$ShowFullResponse
    )

    if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
        Throw "BaseUrl parameter is required or TM_API_URL environment variable must be set."
    }

    # Ensure BaseUrl doesn't have a trailing slash for consistency
    $BaseUrl = $BaseUrl.TrimEnd('/')
    $LoginUrl = "$BaseUrl/login"

    $Body = @{
        username = $Username
        password = $Password
    } | ConvertTo-Json

    $Headers = @{
        "Content-Type" = "application/json"
        "Accept"       = "application/json"
    }

    try {
        Write-Verbose "Requesting token from $LoginUrl..."
        
        # Use -SessionVariable to capture cookies if needed, though we expect a JWT in response body
        $Response = Invoke-RestMethod -Method Post -Uri $LoginUrl -Headers $Headers -Body $Body -ErrorAction Stop
        
        if ($ShowFullResponse) {
            return $Response
        }
        
        if ($Response.JWT) {
            Write-Verbose "JWT retrieved successfully."
            return $Response.JWT
        }
        elseif ($Response.token) {
            # Fallback in case the property name varies
            Write-Verbose "Token retrieved successfully."
            return $Response.token
        }
        else {
            Write-Error "Response did not contain a 'JWT' or 'token' property."
            return $Response
        }
    }
    catch {
        $ErrorBody = ""
        
        # Try to get details from standard ErrorDetails first (often populated by Invoke-RestMethod)
        if ($_.ErrorDetails.Message) {
             $ErrorBody = $_.ErrorDetails.Message
        }

        if ([string]::IsNullOrWhiteSpace($ErrorBody)) {
            try {
                # Handle PowerShell 6/7+ HttpResponseMessage
                if ($_.Exception.Response -is [System.Net.Http.HttpResponseMessage]) {
                    # Wrap in try/catch because accessing Content or Result might throw if disposed
                    $ErrorBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
                }
                # Handle Windows PowerShell WebException
                elseif ($_.Exception.Response -and $_.Exception.Response.GetResponseStream) {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $Reader = New-Object System.IO.StreamReader($stream)
                        $ErrorBody = $Reader.ReadToEnd()
                    }
                }
            }
            catch {
                # Ignore errors reading the response body (e.g. disposed objects)
                Write-Verbose "Could not read response body from exception: $_"
            }
        }

        # Check for 401 Unauthorized specifically to warn about case-sensitivity
        $StatusCode = 0
        if ($_.Exception.Response -is [System.Net.Http.HttpResponseMessage]) {
            $StatusCode = [int]$_.Exception.Response.StatusCode
        }
        elseif ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
             $StatusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($StatusCode -eq 401) {
            Write-Warning "Authentication failed (401 Unauthorized). Note that usernames are often case-sensitive."
        }

        if (-not [string]::IsNullOrWhiteSpace($ErrorBody)) {
             Write-Error "Failed to retrieve token: $ErrorBody"
        }
        else {
             Write-Error "Failed to retrieve token: $_"
        }
    }
}

