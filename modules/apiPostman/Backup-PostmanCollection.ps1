<#
.SYNOPSIS
    Backs up a Postman collection by copying it with a timestamped name.

.DESCRIPTION
    Fetches a collection from the Postman API, modifies its name with a timestamp,
    and creates a new collection as a backup. Supports both manual and automated
    backup modes with different naming conventions.

.PARAMETER SourceCollectionId
    The full UID of the collection to backup (e.g., 8229908-779780a9-97d0-4004-9a96-37e8c64c3405)

.PARAMETER ApiKey
    Postman API key for authentication

.PARAMETER ManualBackup
    Switch to create a manual backup (includes time in name). If not specified, creates auto backup.

.PARAMETER BackupPrefix
    Custom backup prefix (default: "Manual Backup" or "Auto Backup")

.EXAMPLE
    Backup-PostmanCollection -SourceCollectionId "8229908-779780a9-97d0-4004-9a96-37e8c64c3405" -ApiKey "YOUR_API_KEY"
    
    Creates an auto backup: "Auto Backup 2025-10-04 - [Collection Name]"

.EXAMPLE
    Backup-PostmanCollection -SourceCollectionId "8229908-779780a9-97d0-4004-9a96-37e8c64c3405" -ApiKey "YOUR_API_KEY" -ManualBackup
    
    Creates a manual backup: "Manual Backup 2025-10-04 14-30 - [Collection Name]"

.NOTES
    File Name      : Backup-PostmanCollection.ps1
    Author         : Doug Batchelor
    Created        : October 4, 2025
    Prerequisite   : PowerShell 5.1 or higher, Postman API key
#>

function Backup-PostmanCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceCollectionId,
        
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [switch]$ManualBackup,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupPrefix
    )
    
    Write-Host "==========================================================`n" -ForegroundColor Cyan
    Write-Host "POSTMAN COLLECTION BACKUP" -ForegroundColor Magenta
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Setup headers
    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }
    
    # Determine backup type and generate timestamps
    if (-not $BackupPrefix) {
        $BackupPrefix = if ($ManualBackup) { "Manual Backup" } else { "Auto Backup" }
    }
    
    $now = Get-Date
    $dateStamp = $now.ToString("yyyy-MM-dd")
    $timeStamp = "." + $now.ToString("HH-mm-ss")
    
    Write-Host "Backup Configuration:" -ForegroundColor Yellow
    Write-Host "  Type: $BackupPrefix" -ForegroundColor Cyan
    Write-Host "  Date: $dateStamp" -ForegroundColor Cyan
    if ($timeStamp) {
        Write-Host "  Time: $($timeStamp.Trim())" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Step 1: Fetch source collection
    Write-Host "Step 1: Fetching source collection..." -ForegroundColor Yellow
    Write-Host "  Collection ID: $SourceCollectionId" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.getpostman.com/collections/$SourceCollectionId" `
            -Headers $headers `
            -ErrorAction Stop
        
        Write-Host "  ✓ Successfully fetched collection" -ForegroundColor Green
        
        $collection = $response.collection
        $originalName = $collection.info.name
        $folderCount = ($collection.item | Measure-Object).Count
        
        Write-Host "  Original Name: $originalName" -ForegroundColor Cyan
        Write-Host "  Folders: $folderCount" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host "  ✗ Error fetching collection: $_" -ForegroundColor Red
        throw
    }
    
    # Step 2: Prepare backup collection
    Write-Host "Step 2: Preparing backup collection..." -ForegroundColor Yellow
    
    $backupName = "$BackupPrefix $dateStamp$timeStamp - $originalName"
    Write-Host "  Backup Name: $backupName" -ForegroundColor Green
    
    # Modify collection
    $collection.info.name = $backupName
    
    # Add description
    $description = "Backup of `"$originalName`" created on $dateStamp$timeStamp`n`nOriginal Collection ID: $SourceCollectionId"
    if ($collection.info.description) {
        $collection.info.description = $description
    } else {
        $collection.info | Add-Member -MemberType NoteProperty -Name "description" -Value $description -Force
    }
    
    # Remove _postman_id to create a new collection
    $collection.info.PSObject.Properties.Remove('_postman_id')
    
    Write-Host "  ✓ Name updated" -ForegroundColor Green
    Write-Host "  ✓ Description added" -ForegroundColor Green
    Write-Host "  ✓ Ready to create new collection" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Create backup collection
    Write-Host "Step 3: Creating backup collection..." -ForegroundColor Yellow
    
    $backupPayload = @{
        collection = $collection
    } | ConvertTo-Json -Depth 100
    
    try {
        $createResponse = Invoke-RestMethod `
            -Uri "https://api.getpostman.com/collections" `
            -Method Post `
            -Headers $headers `
            -Body $backupPayload `
            -ErrorAction Stop
        
        Write-Host "  ✅ SUCCESS: Backup created!" -ForegroundColor Green
        Write-Host ""
        
        $newCollection = $createResponse.collection
        Write-Host "  New Collection UID: $($newCollection.uid)" -ForegroundColor Cyan
        Write-Host "  New Collection ID: $($newCollection.id)" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host "  ✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "  Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        throw
    }
    
    # Step 4: Verify backup
    Write-Host "Step 4: Verifying backup..." -ForegroundColor Yellow
    
    try {
        $verifyResponse = Invoke-RestMethod `
            -Uri "https://api.getpostman.com/collections/$($newCollection.uid)" `
            -Headers $headers `
            -ErrorAction Stop
        
        Write-Host "  ✓ Backup verified in Postman!" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  ⚠ Warning: Could not verify backup (but it was created)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Summary
    Write-Host "==========================================================`n" -ForegroundColor Cyan
    Write-Host "BACKUP COMPLETE ✅" -ForegroundColor Green
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Original: $originalName" -ForegroundColor White
    Write-Host "  Backup: $backupName" -ForegroundColor White
    Write-Host "  New UID: $($newCollection.uid)" -ForegroundColor White
    Write-Host "  Folders: $folderCount" -ForegroundColor White
    Write-Host ""
    Write-Host "The backup collection is now available in your Postman workspace!" -ForegroundColor Cyan
    Write-Host ""
    
    # Return backup details
    return [PSCustomObject]@{
        OriginalName = $originalName
        OriginalId = $SourceCollectionId
        BackupName = $backupName
        BackupUid = $newCollection.uid
        BackupId = $newCollection.id
        FolderCount = $folderCount
        BackupType = $BackupPrefix
        Timestamp = "$dateStamp$timeStamp"
    }
}

# Export function
Export-ModuleMember -Function Backup-PostmanCollection

# If running as script (not imported as module), execute with default parameters
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "Usage Examples:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# Auto backup (no time stamp):" -ForegroundColor Gray
    Write-Host '  Backup-PostmanCollection -SourceCollectionId "8229908-779780a9-97d0-4004-9a96-37e8c64c3405" -ApiKey "YOUR_API_KEY"' -ForegroundColor White
    Write-Host ""
    Write-Host "# Manual backup (with time stamp):" -ForegroundColor Gray
    Write-Host '  Backup-PostmanCollection -SourceCollectionId "8229908-779780a9-97d0-4004-9a96-37e8c64c3405" -ApiKey "YOUR_API_KEY" -ManualBackup' -ForegroundColor White
    Write-Host ""
    Write-Host "# Multiple backups:" -ForegroundColor Gray
    Write-Host '  $apiKey = "YOUR_API_KEY"' -ForegroundColor White
    Write-Host '  Backup-PostmanCollection -SourceCollectionId "collection-id-1" -ApiKey $apiKey' -ForegroundColor White
    Write-Host '  Backup-PostmanCollection -SourceCollectionId "collection-id-2" -ApiKey $apiKey' -ForegroundColor White
    Write-Host ""
}

