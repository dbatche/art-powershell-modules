<#
.SYNOPSIS
    Verifies that a specific Postman collection exists and is accessible.

.DESCRIPTION
    Attempts to fetch details of a specific collection using its UID.
    Useful for verifying backup configurations or detecting if a collection was deleted/moved.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER CollectionId
    The UID of the collection to verify (e.g. "12345-abcde...").

.EXAMPLE
    Test-PostmanCollectionAccess -CollectionId "8229908-a0080506-3774-4595-84a4-e2eeb0764ff1"
#>

function Test-PostmanCollectionAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$true)]
        [string]$CollectionId
    )

    if (-not $ApiKey) {
        throw "ApiKey is required."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    Write-Host "Checking collection: $CollectionId" -ForegroundColor Cyan

    try {
        # We use 'single collection' endpoint to verify it exists and is accessible
        $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$CollectionId" -Headers $headers -Method Get -ErrorAction Stop
        
        Write-Host "✅ SUCCESS: Collection found." -ForegroundColor Green
        Write-Host "  Name: $($response.collection.info.name)" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Error "❌ FAILED: $_"
        if ($_.Exception.Response.StatusCode -eq 'NotFound') {
            Write-Warning "404 Not Found: The collection ID does not exist. It may have been deleted or the ID changed."
        }
        elseif ($_.Exception.Response.StatusCode -eq 'Forbidden') {
            Write-Warning "403 Forbidden: You do not have permission to access this collection."
        }
        return $false
    }
}

