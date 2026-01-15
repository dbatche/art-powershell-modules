<#
.SYNOPSIS
    Restores a Postman environment from a backup file or JSON string to a specific workspace.

.DESCRIPTION
    Takes a JSON string (or file content) representing a Postman environment and creates
    a new environment in the specified workspace using the Postman API.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER WorkspaceId
    The ID of the target workspace where the environment should be restored.

.PARAMETER EnvironmentJson
    The full JSON string of the environment to restore. 
    This matches the 'body' content from the backup request.

.PARAMETER NewName
    Optional. Specify a new name for the restored environment. 
    If omitted, uses the name from the JSON.

.EXAMPLE
    Restore-PostmanEnvironment -WorkspaceId "8336cc29-ee97-43dd-883d-ff8d36bfe143" -EnvironmentJson $jsonString

.OUTPUTS
    Details of the created environment.
#>

function Restore-PostmanEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$true)]
        [string]$WorkspaceId,

        [Parameter(Mandatory=$true)]
        [string]$EnvironmentJson,

        [Parameter(Mandatory=$false)]
        [string]$NewName
    )

    if (-not $ApiKey) {
        throw "ApiKey is required. Please provide it as a parameter or set the `$env:POSTMAN_API_KEY` environment variable."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    try {
        # Parse JSON to modify name or structure if needed
        $envObj = $EnvironmentJson | ConvertFrom-Json

        # Handle different JSON structures (backup might be wrapped in "environment": {})
        if ($envObj.environment) {
            $envData = $envObj.environment
        } else {
            $envData = $envObj
        }

        # Update name if requested
        if ($NewName) {
            $envData.name = $NewName
        }

        # Construct payload
        $payload = @{
            environment = $envData
        } | ConvertTo-Json -Depth 10

        Write-Host "Restoring environment '$($envData.name)' to workspace '$WorkspaceId'..." -ForegroundColor Cyan

        # Make API Call
        $uri = "https://api.getpostman.com/environments?workspace=$WorkspaceId"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $payload -ErrorAction Stop

        Write-Host "✅ Environment Restored Successfully!" -ForegroundColor Green
        Write-Host "  Name: $($response.environment.name)" -ForegroundColor Gray
        Write-Host "  ID:   $($response.environment.uid)" -ForegroundColor Gray
        
        return $response.environment
    }
    catch {
        Write-Error "Failed to restore environment: $_"
        if ($_.ErrorDetails) {
            Write-Error "API Error: $($_.ErrorDetails.Message)"
        }
    }
}

