# Backup-SingleFolder.ps1
# Backs up a single folder from a collection when Postman pre-request script fails

param(
    [Parameter(Mandatory=$true)]
    [string]$CollectionId,
    
    [Parameter(Mandatory=$true)]
    [string]$FolderName,
    
    [string]$ApiKey = "$env:POSTMAN_API_KEY",
    [string]$BackupPrefix = "Manual Backup"
)

Write-Host "`n" -NoNewline
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "BACKUP SINGLE FOLDER VIA POWERSHELL" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

try {
    Write-Host "Fetching collection $CollectionId..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$CollectionId" -Headers $headers
    $collection = $response.collection
    $originalName = $collection.info.name
    
    Write-Host "✓ Collection: $originalName" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Searching for folder: $FolderName" -ForegroundColor Cyan
    $folder = $collection.item | Where-Object { $_.name -eq $FolderName }
    
    if (-not $folder) {
        Write-Host "✗ Folder '$FolderName' not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available folders:" -ForegroundColor Yellow
        $collection.item | Where-Object { $_.item } | ForEach-Object {
            Write-Host "  • $($_.name)" -ForegroundColor Gray
        }
        exit 1
    }
    
    $itemCount = if ($folder.item) { $folder.item.Count } else { 0 }
    Write-Host "✓ Found folder with $itemCount items" -ForegroundColor Green
    Write-Host ""
    
    # Generate backup name
    $now = Get-Date
    $dateStamp = $now.ToString("yyyy-MM-dd")
    $timeStamp = "." + $now.ToString("HH-mm-ss")
    $backupName = "$BackupPrefix $dateStamp$timeStamp - $originalName - $FolderName"
    
    Write-Host "Creating backup: $backupName" -ForegroundColor Cyan
    
    # Create new collection with just this folder
    $newCollection = @{
        info = @{
            name = $backupName
            description = "Backup of folder '$FolderName' from $originalName created on $dateStamp$timeStamp"
            schema = $collection.info.schema
        }
        item = @($folder)
    }
    
    # Copy collection-level properties if they exist
    if ($collection.variable) {
        $newCollection.variable = $collection.variable
    }
    
    if ($collection.auth) {
        $newCollection.auth = $collection.auth
    }
    
    # Serialize and create backup
    $payload = @{ collection = $newCollection } | ConvertTo-Json -Depth 50 -Compress
    
    $sizeKB = [Math]::Round($payload.Length / 1KB, 2)
    Write-Host "  Payload size: $sizeKB KB" -ForegroundColor Gray
    
    Write-Host "  Creating collection via API..." -ForegroundColor Gray
    $createResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections" `
        -Method Post `
        -Headers $headers `
        -Body $payload
    
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "SUCCESS" -ForegroundColor Green
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backup Details:" -ForegroundColor Yellow
    Write-Host "  Original: $originalName - $FolderName" -ForegroundColor Gray
    Write-Host "  Backup: $backupName" -ForegroundColor Gray
    Write-Host "  New Collection UID: $($createResponse.collection.uid)" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Write-Host $reader.ReadToEnd() -ForegroundColor DarkRed
    }
    exit 1
}

