<#
.SYNOPSIS
    Finds a Postman collection by name and returns its details.

.DESCRIPTION
    Searches through all collections accessible to the API key to find one matching
    the specified name. Useful for recovering lost IDs.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER CollectionName
    The name of the collection to search for.

.EXAMPLE
    Find-PostmanCollection -CollectionName "TM - Trips"
#>

function Find-PostmanCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$true)]
        [string]$CollectionName
    )

    if (-not $ApiKey) {
        throw "ApiKey is required."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    Write-Host "Searching for collection: '$CollectionName'..." -ForegroundColor Cyan

    try {
        $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers -Method Get -ErrorAction Stop
        $collections = $response.collections

        $matches = $collections | Where-Object { $_.name -eq $CollectionName }

        if ($matches) {
            foreach ($match in $matches) {
                Write-Host "✅ FOUND MATCH:" -ForegroundColor Green
                Write-Host "  Name: $($match.name)" -ForegroundColor Gray
                Write-Host "  ID:   $($match.uid)" -ForegroundColor Yellow
                Write-Host "  Owner: $($match.owner)" -ForegroundColor Gray
                Write-Host ""
            }
            return $matches
        } else {
            Write-Warning "No collection found with name '$CollectionName'."
            return $null
        }
    }
    catch {
        Write-Error "Failed to list collections: $_"
    }
}

