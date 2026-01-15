<#
.SYNOPSIS
    Verifies access to a specific Postman workspace.

.DESCRIPTION
    Attempts to fetch details of a specific workspace to verify if the API key has access.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER WorkspaceId
    The ID of the workspace to check.

.EXAMPLE
    Test-PostmanWorkspaceAccess -WorkspaceId "workspace-uuid"
#>

function Test-PostmanWorkspaceAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$true)]
        [string]$WorkspaceId
    )

    if (-not $ApiKey) {
        throw "ApiKey is required."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    Write-Host "Checking access to workspace: $WorkspaceId" -ForegroundColor Cyan

    try {
        $response = Invoke-RestMethod -Uri "https://api.getpostman.com/workspaces/$WorkspaceId" -Headers $headers -Method Get -ErrorAction Stop
        
        Write-Host "✅ SUCCESS: Access granted." -ForegroundColor Green
        Write-Host "  Name: $($response.workspace.name)" -ForegroundColor Gray
        Write-Host "  Type: $($response.workspace.type)" -ForegroundColor Gray
        Write-Host "  Visibility: $($response.workspace.visibility)" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Error "❌ FAILED: $_"
        if ($_.Exception.Response.StatusCode -eq 'Forbidden') {
            Write-Warning "403 Forbidden: Your API Key does NOT have permission to access this workspace."
            Write-Warning "Ensure you have 'Editor' or 'Admin' role in the target workspace."
        }
        return $false
    }
}

