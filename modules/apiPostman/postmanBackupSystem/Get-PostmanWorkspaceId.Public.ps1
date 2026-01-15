<#
.SYNOPSIS
    Finds the Workspace ID for a given Workspace Name.

.DESCRIPTION
    Queries the Postman API to list all workspaces and returns the details
    for the workspace matching the specified name.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER WorkspaceName
    The name of the workspace to find.

.EXAMPLE
    Get-PostmanWorkspaceId -WorkspaceName "TM - CloudHub"

.OUTPUTS
    PSCustomObject containing Workspace Id, Name, and Type.
#>

function Get-PostmanWorkspaceId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$true)]
        [string]$WorkspaceName
    )

    if (-not $ApiKey) {
        throw "ApiKey is required. Please provide it as a parameter or set the `$env:POSTMAN_API_KEY` environment variable."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    Write-Host "Searching for workspace: '$WorkspaceName'..." -ForegroundColor Cyan

    try {
        $response = Invoke-RestMethod -Uri "https://api.getpostman.com/workspaces" -Headers $headers -Method Get -ErrorAction Stop
        $workspaces = $response.workspaces

        $targetWorkspace = $workspaces | Where-Object { $_.name -eq $WorkspaceName }

        if ($targetWorkspace) {
            Write-Host "Found Workspace!" -ForegroundColor Green
            return [PSCustomObject]@{
                Id = $targetWorkspace.id
                Name = $targetWorkspace.name
                Type = $targetWorkspace.type
            }
        } else {
            Write-Warning "Workspace '$WorkspaceName' not found."
            return $null
        }
    }
    catch {
        Write-Error "Failed to fetch workspaces: $_"
    }
}

