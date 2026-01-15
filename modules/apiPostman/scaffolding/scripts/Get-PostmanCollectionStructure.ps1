<#
.SYNOPSIS
    Extracts collection structure and generates CLI commands using Postman API.

.DESCRIPTION
    Uses the Postman API to fetch collection structure directly and extract:
    - Top-level folders (resources)
    - Folder UIDs for CLI commands
    - Request counts and methods
    - Ready-to-use Postman CLI commands
    
    Much simpler than parsing report files - goes straight to the source!

.PARAMETER ApiKey
    Postman API key (PMAK-...).

.PARAMETER CollectionUid
    Collection UID with owner prefix (e.g., 8229908-779780a9-...).

.PARAMETER EnvironmentUid
    Optional environment UID with owner prefix (e.g., 11896768-xxx-...).

.PARAMETER Format
    Output format:
    - Summary: Table view with resources, folder UIDs, and test counts
    - CLI: Ready-to-use Postman CLI commands
    - JSON: Raw collection structure

.PARAMETER NewmanStructure
    When used with -Format CLI, adds --reporter-json-structure newman to commands.

.EXAMPLE
    Get-PostmanCollectionStructure -ApiKey "PMAK-..." -CollectionUid "8229908-779780a9-..."
    
    Shows summary of all top-level folders with UIDs and request counts.

.EXAMPLE
    Get-PostmanCollectionStructure -ApiKey "PMAK-..." -CollectionUid "8229908-779780a9-..." -Format CLI
    
    Generates ready-to-use CLI commands for each resource.

.EXAMPLE
    Get-PostmanCollectionStructure -ApiKey "PMAK-..." -CollectionUid "8229908-779780a9-..." -EnvironmentUid "11896768-xxx-..." -Format CLI -NewmanStructure
    
    Generates CLI commands with environment and Newman structure flag.

.NOTES
    File Name      : Get-PostmanCollectionStructure.ps1
    Prerequisite   : PowerShell 5.1 or higher
    API Access     : Requires valid Postman API key
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$true)]
    [string]$CollectionUid,
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentUid,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Summary', 'CLI', 'JSON')]
    [string]$Format = 'Summary',
    
    [Parameter(Mandatory=$false)]
    [switch]$NewmanStructure
)

$headers = @{
    "X-API-Key" = $ApiKey
}

Write-Host "`nFetching collection from Postman API..." -ForegroundColor Cyan
Write-Host "Collection UID: $CollectionUid" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$CollectionUid" -Headers $headers
    $collection = $response.collection
}
catch {
    Write-Error "Failed to fetch collection: $_"
    if ($_.ErrorDetails.Message) {
        Write-Error "Details: $($_.ErrorDetails.Message)"
    }
    return
}

Write-Host "✓ Collection: $($collection.info.name)" -ForegroundColor Green
Write-Host ""

# Recursive function to extract all requests from a folder
function Get-RequestsFromItem {
    param(
        [object]$Item,
        [string]$Path = ""
    )
    
    $requests = @()
    
    if ($Item.request) {
        # This is a request
        $requests += [PSCustomObject]@{
            UID = $Item.uid
            Name = $Item.name
            Method = $Item.request.method
            Path = $Path
        }
    }
    
    if ($Item.item) {
        # This is a folder with nested items
        $currentPath = if ($Path) { "$Path/$($Item.name)" } else { $Item.name }
        foreach ($child in $Item.item) {
            $requests += Get-RequestsFromItem -Item $child -Path $currentPath
        }
    }
    
    return $requests
}

# Extract top-level folders (resources)
Write-Host "Analyzing collection structure..." -ForegroundColor Cyan

$resources = @()

foreach ($topItem in $collection.item) {
    if ($topItem.item) {
        # This is a folder (resource)
        $resourceName = $topItem.name
        
        # Clean up name (remove Jira tickets, phase markers, etc.)
        $cleanName = $resourceName -replace ' - TM-\d+.*$', '' -replace '\s*\(phase \d+\)\s*$', ''
        $cleanName = $cleanName.Trim()
        
        # Get all requests within this folder
        $requests = Get-RequestsFromItem -Item $topItem -Path $resourceName
        
        # Count by method
        $methodCounts = $requests | Group-Object -Property Method | ForEach-Object {
            @{ $_.Name = $_.Count }
        }
        
        $resources += [PSCustomObject]@{
            Name = $resourceName
            CleanName = $cleanName
            FolderUID = $topItem.uid
            RequestCount = $requests.Count
            Methods = ($requests.Method | Select-Object -Unique | Sort-Object) -join ', '
            Requests = $requests
        }
    }
    elseif ($topItem.request) {
        # Top-level request (not in a folder)
        $resources += [PSCustomObject]@{
            Name = $topItem.name
            CleanName = $topItem.name
            FolderUID = $null
            RequestCount = 1
            Methods = $topItem.request.method
            Requests = @([PSCustomObject]@{
                UID = $topItem.uid
                Name = $topItem.name
                Method = $topItem.request.method
                Path = ""
            })
        }
    }
}

# Sort by request count (descending)
$resources = $resources | Sort-Object -Property RequestCount -Descending

# Output based on format
switch ($Format) {
    'JSON' {
        # Return raw structure
        return $collection
    }
    
    'CLI' {
        # Generate CLI commands
        Write-Host ""
        Write-Host ("=" * 100) -ForegroundColor Magenta
        Write-Host "POSTMAN CLI COMMANDS BY RESOURCE" -ForegroundColor Magenta
        Write-Host ("=" * 100) -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Collection: $($collection.info.name)" -ForegroundColor Cyan
        Write-Host "Collection UID: $CollectionUid" -ForegroundColor Gray
        
        if ($EnvironmentUid) {
            Write-Host "Environment UID: $EnvironmentUid" -ForegroundColor Gray
        }
        else {
            Write-Host "Environment UID: <not specified - use -EnvironmentUid parameter>" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host ("=" * 100) -ForegroundColor Magenta
        Write-Host ""
        
        foreach ($resource in $resources) {
            $envParam = if ($EnvironmentUid) { "-e $EnvironmentUid" } else { "-e <ENVIRONMENT_UID>" }
            $reporterParam = if ($NewmanStructure) { "--reporters json --reporter-json-structure newman" } else { "--reporters json" }
            
            $command = if ($resource.FolderUID) {
                # Use folder UID (clean and simple!)
                "postman collection run $CollectionUid $envParam -i $($resource.FolderUID) $reporterParam"
            }
            else {
                # Single top-level request
                "postman collection run $CollectionUid $envParam -i $($resource.Requests[0].UID) $reporterParam"
            }
            
            # Comment for context
            Write-Host "# Resource: $($resource.CleanName) ($($resource.RequestCount) tests)" -ForegroundColor Yellow
            
            # Output command (to pipeline)
            $command
            
            # Blank line
            Write-Host ""
        }
        
        Write-Host ("=" * 100) -ForegroundColor Magenta
        Write-Host "Total Resources: $($resources.Count)" -ForegroundColor Cyan
        Write-Host ""
        
        if ($NewmanStructure) {
            Write-Host "TIP: Commands include --reporter-json-structure newman for folder UIDs in output" -ForegroundColor Gray
        }
        else {
            Write-Host "TIP: Add -NewmanStructure parameter to include --reporter-json-structure newman flag" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    default {
        # Summary format - Table view
        Write-Host ""
        Write-Host ("=" * 100) -ForegroundColor Green
        Write-Host "COLLECTION STRUCTURE SUMMARY" -ForegroundColor Green
        Write-Host ("=" * 100) -ForegroundColor Green
        Write-Host ""
        Write-Host "Collection: $($collection.info.name)" -ForegroundColor Cyan
        Write-Host ""
        
        # Build summary table
        $summaryData = $resources | ForEach-Object {
            [PSCustomObject]@{
                Resource = $_.CleanName
                FolderUID = if ($_.FolderUID) { $_.FolderUID } else { "(top-level request)" }
                Tests = $_.RequestCount
                Methods = $_.Methods
            }
        }
        
        # Display table
        $summaryData | Format-Table -Property @{
            Name = 'Resource'
            Expression = {$_.Resource}
        }, @{
            Name = 'Folder UID'
            Expression = {$_.FolderUID}
            Width = 40
        }, @{
            Name = 'Tests'
            Expression = {$_.Tests}
        }, @{
            Name = 'Methods'
            Expression = {$_.Methods}
        } -AutoSize
        
        Write-Host ("=" * 100) -ForegroundColor Green
        Write-Host "Total Resources: $($resources.Count)" -ForegroundColor Cyan
        Write-Host "Total Requests: $(($resources | Measure-Object -Property RequestCount -Sum).Sum)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "TIPS:" -ForegroundColor Yellow
        Write-Host "  • Use -Format CLI to generate ready-to-use Postman CLI commands" -ForegroundColor Gray
        Write-Host "  • Use folder UID to run all tests for a resource:" -ForegroundColor Gray
        Write-Host "    postman collection run <collection-uid> -e <env-uid> -i <Folder-UID>" -ForegroundColor DarkGray
        Write-Host "  • Use -Format JSON to get full collection structure" -ForegroundColor Gray
        Write-Host ""
    }
}

