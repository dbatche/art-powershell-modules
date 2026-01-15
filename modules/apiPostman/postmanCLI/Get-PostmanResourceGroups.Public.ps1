<#
.SYNOPSIS
    Extracts and groups Postman test executions by top-level API resource.

.DESCRIPTION
    Analyzes Postman JSON report files (native or Newman format) and extracts test executions,
    grouping them by top-level API resource (e.g., /apInvoices, /checks, /driverDeductions).
    
    Folder IDs are extracted from Newman format files, allowing you to run all tests for a
    resource with a single -i parameter instead of listing individual request UIDs.

.PARAMETER Path
    Path to the Postman JSON report file (native or Newman format).

.PARAMETER Format
    Output format:
    - Summary: Table view with resource names, folder IDs, test counts, and methods
    - Raw: Individual request records for detailed filtering
    - CLI: Ready-to-use Postman CLI commands for each resource

.PARAMETER NewmanStructure
    When used with -Format CLI, adds --reporter-json-structure newman to commands.
    This ensures the output JSON files include folder IDs and collection structure.

.PARAMETER CollectionOwner
    Owner ID to prepend to collection ID (e.g., 8229908).
    Required by Postman CLI when using CLI format.
    Note: Newman reports don't include owner IDs, so this must be provided manually.

.PARAMETER EnvironmentOwner
    Owner ID to prepend to environment ID (e.g., 11896768).
    Required by Postman CLI when using CLI format with environments.
    Note: Reports don't include environment owner IDs, so this must be provided manually.

.EXAMPLE
    Get-PostmanResourceGroups -Path "report.json"
    
    Displays a summary table of all resources with folder IDs and test counts.

.EXAMPLE
    Get-PostmanResourceGroups -Path "report.json" -Format CLI -CollectionOwner 8229908 -EnvironmentOwner 11896768
    
    Outputs ready-to-use Postman CLI commands with full owner-prefixed IDs.

.EXAMPLE
    Get-PostmanResourceGroups -Path "report.json" -Format CLI -NewmanStructure -CollectionOwner 8229908
    
    Outputs commands with Newman structure format and collection owner prefix.

.EXAMPLE
    $data = Get-PostmanResourceGroups -Path "report.json" -Format Raw
    $data | Where-Object { $_.Resource -eq 'checks' -and $_.Method -eq 'POST' }
    
    Gets all POST requests for the /checks resource.

.NOTES
    File Name      : Get-PostmanResourceGroups.Public.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Format         : Postman native or Newman JSON format
    
    Note: Folder IDs are only available in Newman format files.
          Use --reporter-json-structure newman when running Postman CLI.
#>

function Get-PostmanResourceGroups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Summary', 'Raw', 'CLI')]
        [string]$Format = 'Summary',
        
        [Parameter(Mandatory=$false)]
        [switch]$NewmanStructure,
        
        [Parameter(Mandatory=$false)]
        [string]$CollectionOwner,
        
        [Parameter(Mandatory=$false)]
        [string]$EnvironmentOwner
    )
    
    Write-Host "Analyzing: $([System.IO.Path]::GetFileName($Path))" -ForegroundColor Cyan
    
    # Try to load owner mappings from config file (if not provided as parameters)
    $ownerConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) "postman-owners.json"
    $ownerConfig = $null
    if ((Test-Path $ownerConfigPath) -and (-not $CollectionOwner -or -not $EnvironmentOwner)) {
        try {
            $ownerConfig = Get-Content $ownerConfigPath | ConvertFrom-Json
            Write-Host "Loaded owner config from: postman-owners.json" -ForegroundColor Gray
        }
        catch {
            Write-Host "Could not load owner config: $_" -ForegroundColor DarkGray
        }
    }
    
    # Read and parse JSON
    Write-Host "Reading JSON file..." -ForegroundColor Gray
    try {
        $jsonContent = Get-Content -Path $Path -Raw -ErrorAction Stop
        $report = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to read or parse JSON file: $_"
        return
    }
    
    # Determine format and extract metadata
    $isNewmanFormat = $report.collection -ne $null
    $collectionId = $null
    $collectionName = $null
    $environmentId = $null
    $environmentName = $null
    
    if ($isNewmanFormat) {
        Write-Host "Format detected: Newman (has folder IDs)" -ForegroundColor Green
        if ($report.collection.info) {
            $collectionId = $report.collection.info._postman_id
            $collectionName = $report.collection.info.name
        }
        if ($report.environment) {
            $environmentId = $report.environment.id
            $environmentName = $report.environment.name
        }
    }
    else {
        Write-Host "Format detected: Native (no folder IDs)" -ForegroundColor Yellow
        Write-Warning "Folder IDs are not available in native format. Use --reporter-json-structure newman to get folder IDs."
        if ($report.run.meta) {
            $collectionId = $report.run.meta.collectionId
            $collectionName = $report.run.meta.collectionName
        }
    }
    
    # Look up owner IDs from config if not provided
    if (-not $CollectionOwner -and $ownerConfig -and $collectionId) {
        $collectionUuid = $collectionId
        if ($ownerConfig.collections.$collectionUuid) {
            $CollectionOwner = $ownerConfig.collections.$collectionUuid.owner
            Write-Host "Found Collection Owner in config: $CollectionOwner" -ForegroundColor Gray
        }
    }
    if (-not $EnvironmentOwner -and $ownerConfig -and $environmentId) {
        $environmentUuid = $environmentId
        if ($ownerConfig.environments.$environmentUuid) {
            $EnvironmentOwner = $ownerConfig.environments.$environmentUuid.owner
            Write-Host "Found Environment Owner in config: $EnvironmentOwner" -ForegroundColor Gray
        }
    }
    
    # Prepend owner IDs if provided or loaded from config
    if ($CollectionOwner -and $collectionId) {
        $collectionId = "$CollectionOwner-$collectionId"
        Write-Host "Using Collection ID: $collectionId" -ForegroundColor Gray
    }
    if ($EnvironmentOwner -and $environmentId) {
        $environmentId = "$EnvironmentOwner-$environmentId"
        Write-Host "Using Environment ID: $environmentId" -ForegroundColor Gray
    }
    
    # Extract folder IDs from collection structure (Newman format only)
    Write-Host "Extracting folder information from collection..." -ForegroundColor Gray
    $folderMap = @{}
    
    if ($isNewmanFormat -and $report.collection -and $report.collection.item) {
        foreach ($item in $report.collection.item) {
            if ($item.item) {
                # This is a folder - extract the resource name
                $folderName = $item.name -replace ' - TM-\d+.*$', '' -replace '\s*\(phase \d+\)\s*$', ''
                $folderName = $folderName.Trim()
                $folderMap[$folderName] = $item.id
            }
        }
    }
    
    # Extract executions
    Write-Host "Extracting resource information..." -ForegroundColor Gray
    if (-not $report.run -or -not $report.run.executions) {
        Write-Error "Invalid report format: Missing run.executions"
        return
    }
    
    $executions = @()
    $executionIndex = 0
    
    foreach ($exec in $report.run.executions) {
        $executionIndex++
        
        # Handle both native format (requestExecuted) and Newman format (item)
        $uid = $null
        $requestName = $null
        $method = "UNKNOWN"
        $urlObj = $null
        
        if ($exec.requestExecuted) {
            # Native Postman format
            $uid = $exec.requestExecuted.id.Trim()
            $requestName = ($exec.requestExecuted.name -replace '\t', ' ').Trim()
            $method = $exec.requestExecuted.method
            $urlObj = $exec.requestExecuted.url
        }
        elseif ($exec.item) {
            # Newman format
            $uid = $exec.item.id.Trim()
            $requestName = ($exec.item.name -replace '\t', ' ').Trim()
            if ($exec.request) {
                $method = $exec.request.method
                $urlObj = $exec.request.url
            }
        }
        
        if ($uid -and $requestName) {
            # Extract resource from URL path
            $resource = "Unknown"
            if ($urlObj -and $urlObj.path) {
                $pathSegments = @($urlObj.path | Where-Object { 
                    $_ -notmatch '^\{\{.*\}\}$' -and 
                    $_ -ne "" -and 
                    $_ -notmatch '^(fin|finance|api|v1|v2|tm|masterData)$' -and
                    $_ -notmatch '^\d+$'  # Skip numeric IDs
                })
                
                if ($pathSegments -and $pathSegments.Count -gt 0) {
                    # Get the first meaningful resource segment
                    $resource = $pathSegments[0]
                }
            }
            
            $executions += [PSCustomObject]@{
                ExecutionOrder = $executionIndex
                UID = $uid
                Method = $method
                RequestName = $requestName
                Resource = $resource
            }
        }
    }
    
    if ($executions.Count -eq 0) {
        Write-Host "`nNo executions found in report." -ForegroundColor Yellow
        return
    }
    
    # Group by resource
    $grouped = $executions | Group-Object -Property Resource | Sort-Object Count -Descending
    
    # Output based on format
    switch ($Format) {
        'Raw' {
            # Return individual request records
            return $executions
        }
        
        'CLI' {
            # Output ready-to-use CLI commands
            Write-Host "`n" -NoNewline
            Write-Host ("=" * 100) -ForegroundColor Magenta
            Write-Host "POSTMAN CLI COMMANDS BY RESOURCE" -ForegroundColor Magenta
            Write-Host ("=" * 100) -ForegroundColor Magenta
            Write-Host ""
            
            if (-not $isNewmanFormat) {
                Write-Host "WARNING: Native format detected - no folder IDs available." -ForegroundColor Red
                Write-Host "Commands will use individual request UIDs (longer command lines)." -ForegroundColor Yellow
                Write-Host ""
            }
            
            Write-Host "Collection: $collectionName" -ForegroundColor Cyan
            Write-Host "Collection ID: $collectionId" -ForegroundColor Gray
            if ($environmentId) {
                Write-Host "Environment: $environmentName" -ForegroundColor Cyan
                Write-Host "Environment ID: $environmentId" -ForegroundColor Gray
            }
            else {
                Write-Host "Environment ID: <not available - specify with -e parameter>" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host ("=" * 100) -ForegroundColor Magenta
            Write-Host ""
            
            foreach ($group in $grouped) {
                $resourceName = $group.Name
                $folderId = $folderMap[$resourceName]
                $testCount = $group.Count
                
                # Build command
                $envParam = if ($environmentId) { "-e $environmentId" } else { "-e <ENVIRONMENT_ID>" }
                $reporterParam = if ($NewmanStructure) { "--reporters json --reporter-json-structure newman" } else { "--reporters json" }
                
                $command = if ($folderId) {
                    # Use folder ID (much simpler!)
                    "postman collection run $collectionId $envParam -i $folderId $reporterParam"
                }
                else {
                    # Fall back to individual UIDs
                    $uids = @($group.Group.UID) -join ' -i '
                    "postman collection run $collectionId $envParam -i $uids $reporterParam"
                }
                
                # Comment for context (Write-Host, not in pipeline)
                Write-Host "# Resource: /$resourceName ($testCount tests)" -ForegroundColor Yellow
                
                # Command to pipeline (Write-Output)
                $command
                
                # Blank line for visual separation (Write-Host)
                Write-Host ""
            }
            
            Write-Host ("=" * 100) -ForegroundColor Magenta
            Write-Host "Total Resources: $($grouped.Count)" -ForegroundColor Cyan
            Write-Host ""
            if ($NewmanStructure) {
                Write-Host "TIP: Commands include --reporter-json-structure newman for folder IDs in output" -ForegroundColor Gray
            }
            else {
                Write-Host "TIP: Add -NewmanStructure parameter to include --reporter-json-structure newman flag" -ForegroundColor Gray
            }
        }
        
        default {
            # Summary format - Table view
            Write-Host "`n" -NoNewline
            Write-Host ("=" * 100) -ForegroundColor Green
            Write-Host "RESOURCE SUMMARY" -ForegroundColor Green
            Write-Host ("=" * 100) -ForegroundColor Green
            Write-Host ""
            
            if (-not $isNewmanFormat) {
                Write-Host "⚠ Native format: Folder IDs not available (use Newman format for folder IDs)" -ForegroundColor Yellow
                Write-Host ""
            }
            
            # Build summary table data
            $summaryData = $grouped | ForEach-Object {
                $resourceName = $_.Name
                $folderId = $folderMap[$resourceName]
                $methods = ($_.Group.Method | Select-Object -Unique | Sort-Object) -join ', '
                
                [PSCustomObject]@{
                    Resource = "/$resourceName"
                    FolderID = if ($folderId) { $folderId } else { "" }
                    Tests = $_.Count
                    Methods = $methods
                }
            }
            
            # Display table
            $summaryData | Format-Table -Property @{
                Name = 'Resource'
                Expression = {$_.Resource}
            }, @{
                Name = 'Folder ID'
                Expression = {$_.FolderID}
            }, @{
                Name = 'Tests'
                Expression = {$_.Tests}
            }, @{
                Name = 'Methods'
                Expression = {$_.Methods}
            } -AutoSize
            
            Write-Host ("=" * 100) -ForegroundColor Green
            Write-Host "Total Resources: $(@($grouped).Count)" -ForegroundColor Cyan
            Write-Host "Total Executions: $($executions.Count)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "TIPS:" -ForegroundColor Yellow
            if ($isNewmanFormat) {
                Write-Host "  • Use -Format CLI to generate ready-to-use Postman CLI commands" -ForegroundColor Gray
                Write-Host "  • Use Folder ID to run all tests for a resource:" -ForegroundColor Gray
                Write-Host '    postman collection run <collection-id> -e <env-id> -i <Folder-ID>' -ForegroundColor DarkGray
            }
            else {
                Write-Host "  • Use -Format CLI to generate Postman CLI commands (will use individual UIDs)" -ForegroundColor Gray
                Write-Host "  • For folder IDs, re-run with: --reporter-json-structure newman" -ForegroundColor Gray
            }
            Write-Host "  • Use -Format Raw to get individual request records for detailed analysis" -ForegroundColor Gray
        }
    }
}
