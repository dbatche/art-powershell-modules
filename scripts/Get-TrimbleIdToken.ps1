<#
.SYNOPSIS
    Retrieves a JWT id_token from Trimble Identity for ART server authentication.

.DESCRIPTION
    Authenticates with Trimble Identity using the Resource Owner Password Credentials grant type
    and retrieves an id_token that can be used as a Bearer token for ART server requests.

.PARAMETER Username
    Your Trimble ID username (email).

.PARAMETER Password
    Your Trimble ID password.

.PARAMETER ShowFullResponse
    If specified, outputs the full JSON response instead of just the id_token.

.EXAMPLE
    Get-TrimbleIdToken.ps1 -Username "user@example.com" -Password "secret123"
    Returns the id_token string.

.EXAMPLE
    $token = .\Get-TrimbleIdToken.ps1 -Username "user@example.com" -Password "secret123"
    Invoke-RestMethod -Uri "https://art-server/api/tm/..." -Headers @{ Authorization = "Bearer $token" }
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Username,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Password,

    [Parameter()]
    [switch]$ShowFullResponse
)

$TokenUrl = "https://identity.trimble.com/i/oauth2/token"

# Hardcoded Authorization header provided in instructions
# Corresponds to Basic auth with specific client_id/secret
$AuthHeaderValue = "Basic OWpOdDdCNl9PbUxsbU5vNDZkNkFpVlp6c1lVYTpYRWp5WjNHbVM0OElJSWFKSlVOZnQ4MGdJdmth"

$Body = @{
    grant_type   = "password"
    username     = $Username
    password     = $Password
    scope        = "openid"
    tenantDomain = "trimble.com"
}

$Headers = @{
    Authorization = $AuthHeaderValue
    "Content-Type" = "application/x-www-form-urlencoded"
}

try {
    Write-Verbose "Requesting token from $TokenUrl..."
    $Response = Invoke-RestMethod -Method Post -Uri $TokenUrl -Headers $Headers -Body $Body
    
    if ($ShowFullResponse) {
        return $Response
    }
    
    if ($Response.id_token) {
        Write-Verbose "Token retrieved successfully."
        return $Response.id_token
    }
    else {
        Write-Error "Response did not contain an id_token."
        return $Response
    }
}
catch {
    Write-Error "Failed to retrieve token: $_"
    if ($_.Exception.Response) {
        $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $ErrorBody = $Reader.ReadToEnd()
        Write-Error "Error Details: $ErrorBody"
    }
}

