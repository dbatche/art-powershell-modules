<#
.SYNOPSIS
    Removes Postman collection backups older than a specified number of days.

.DESCRIPTION
    Lists all collections (optionally within a specific workspace), identifies backups 
    based on naming convention, and deletes those older than the retention period.
    
    Naming Convention handled:
    - "Auto Backup YYYY-MM-DD - Name"
    - "Manual Backup YYYY-MM-DD 14-30 - Name"
    - "Manual Backup YYYY-MM-DD.14-30-00 - Name"

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER WorkspaceId
    Optional. If provided, only checks collections in this workspace.
    If not provided, checks all collections the API Key has access to.

.PARAMETER BackupWorkspaceId
    Optional. Defaults to $env:POSTMAN_BACKUP_WORKSPACE_ID.
    If WorkspaceId is not provided, BackupWorkspaceId will be used as the workspace filter.
    This helps prevent accidental cleanup across all workspaces.

.PARAMETER SourceCollectionName
    Optional. If provided, only considers backups whose source collection name matches one of these values.
    This is the name portion after the date stamp in the backup name, e.g.:
        "Auto Backup 2025-10-04 - Finance Functional Tests"
                               ^ source collection name

.PARAMETER RetentionDays
    Number of days to keep backups. Default is 14.

.PARAMETER KeepNewestPerSource
    Number of newest backups to always keep per source collection (even if older than RetentionDays).
    Default is 3.

.EXAMPLE
    Remove-OldPostmanBackups -RetentionDays 14 -WhatIf
    
    Lists backups that would be deleted without actually deleting them.

.EXAMPLE
    Remove-OldPostmanBackups -WorkspaceId "workspace-uuid"
    
    Deletes backups in the specified workspace older than 14 days (default).
#>

function Remove-OldPostmanBackups {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$false)]
        [string]$WorkspaceId,

        [Parameter(Mandatory=$false)]
        [string]$BackupWorkspaceId = $env:POSTMAN_BACKUP_WORKSPACE_ID,

        [Parameter(Mandatory=$false)]
        [string[]]$SourceCollectionName,

        [Parameter(Mandatory=$false)]
        [int]$RetentionDays = 14,

        [Parameter(Mandatory=$false)]
        [ValidateRange(0, 3650)]
        [int]$KeepNewestPerSource = 3
    )

    if (-not $ApiKey) {
        throw "ApiKey is required. Please provide it as a parameter or set the `$env:POSTMAN_API_KEY` environment variable."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    # 1. Fetch Collections
    Write-Host "Fetching collections..." -ForegroundColor Cyan
    
    $uri = "https://api.getpostman.com/collections"

    $effectiveWorkspaceId = $WorkspaceId
    if (-not $effectiveWorkspaceId) {
        $effectiveWorkspaceId = $BackupWorkspaceId
    }

    if ($effectiveWorkspaceId) {
        Write-Host "Workspace filter: $effectiveWorkspaceId" -ForegroundColor Gray
        $uri += "?workspace=$effectiveWorkspaceId"
    }
    else {
        Write-Warning "No WorkspaceId provided and POSTMAN_BACKUP_WORKSPACE_ID not set. This will query ALL accessible collections."
    }

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        $collections = $response.collections
        Write-Host "Found $($collections.Count) total collections." -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to fetch collections: $_"
        return
    }

    # 2. Identify and Filter Backups
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Write-Host "Retention Policy: Delete backups older than $($cutoffDate.ToString('yyyy-MM-dd')) ($RetentionDays days)" -ForegroundColor Yellow

    $allBackups = @()

    foreach ($collection in $collections) {
        # Regex to match backup names and capture date + optional time
        # Matches:
        # - "Auto Backup 2025-10-04 - ..."
        # - "Manual Backup 2025-10-04 14-30 - ..."
        # - "Manual Backup 2025-10-04.14-30-00 - ..."
        if ($collection.name -match '^(?<type>Auto|Manual) Backup (?<date>\d{4}-\d{2}-\d{2})(?:[\. ](?<time>\d{2}[-:]\d{2}(?:[-:]\d{2})?))? - (?<source>.+)$') {
            $dateStr = $matches['date']
            $timeStr = $matches['time']
            $backupType = $matches['type']
            $sourceName = $matches['source'].Trim()
            
            try {
                $culture = [System.Globalization.CultureInfo]::InvariantCulture

                # Parse to DateTime for comparison. If no time is present, treat as midnight.
                $backupDateTime = $null
                if ($timeStr) {
                    # Normalize time to HH:mm:ss (Postman naming uses '-' or ':' separators)
                    $t = $timeStr.Replace('-', ':')
                    if ($t -match '^\d{2}:\d{2}$') {
                        $t = "$t`:00"
                    }
                    $backupDateTime = [DateTime]::ParseExact("$dateStr $t", 'yyyy-MM-dd HH:mm:ss', $culture)
                }
                else {
                    $backupDateTime = [DateTime]::ParseExact($dateStr, 'yyyy-MM-dd', $culture)
                }
                
                $age = (New-TimeSpan -Start $backupDateTime -End (Get-Date)).Days

                $allBackups += [PSCustomObject]@{
                    Id = $collection.uid
                    Name = $collection.name
                    Source = $sourceName
                    Type = $backupType
                    Date = $backupDateTime
                    AgeDays = $age
                }
            }
            catch {
                Write-Warning "Could not parse date from backup: $($collection.name)"
            }
        }
    }

    if ($allBackups.Count -eq 0) {
        Write-Host "No backups found matching the naming convention." -ForegroundColor Green
        return
    }

    # Optional filter: only consider specified source collections
    $backups = $allBackups
    if ($SourceCollectionName -and $SourceCollectionName.Count -gt 0) {
        $sourceSet = @{}
        foreach ($s in $SourceCollectionName) {
            if ($s) { $sourceSet[$s.Trim().ToLowerInvariant()] = $true }
        }

        $backups = $backups | Where-Object { $sourceSet.ContainsKey($_.Source.ToLowerInvariant()) }
        Write-Host "Filtering to $($sourceSet.Count) source collection name(s)." -ForegroundColor Gray
    }

    if ($backups.Count -eq 0) {
        Write-Host "No backups matched the specified SourceCollectionName filter." -ForegroundColor Yellow
        return
    }

    # Protect newest N per source (even if outside retention window)
    $protectedIds = @{}
    if ($KeepNewestPerSource -gt 0) {
        $bySource = $backups | Group-Object -Property Source
        foreach ($group in $bySource) {
            $newest = $group.Group | Sort-Object Date -Descending | Select-Object -First $KeepNewestPerSource
            foreach ($b in $newest) {
                $protectedIds[$b.Id] = $true
            }
        }
    }

    # Delete only backups older than retention AND not protected
    $backupsToDelete = @($backups | Where-Object { $_.Date -lt $cutoffDate -and -not $protectedIds.ContainsKey($_.Id) })

    if ($backupsToDelete.Count -eq 0) {
        Write-Host "No backups eligible for deletion (after retention + KeepNewestPerSource rules)." -ForegroundColor Green
        return
    }

    Write-Host "Found $($backupsToDelete.Count) backups to delete:" -ForegroundColor Yellow
    $backupsToDelete | Sort-Object Source, Date | Format-Table Source, Type, Date, AgeDays, Name -AutoSize

    # 3. Delete Old Backups
    foreach ($backup in $backupsToDelete) {
        if ($PSCmdlet.ShouldProcess("Collection: $($backup.Name) (Age: $($backup.AgeDays) days)", "Delete Collection")) {
            try {
                Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($backup.Id)" -Headers $headers -Method Delete -ErrorAction Stop
                Write-Host "Deleted: $($backup.Name)" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to delete $($backup.Name): $_"
            }
        }
    }
}

