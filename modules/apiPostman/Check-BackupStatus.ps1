# Check if webhook-triggered backups were created
$apiKey = $env:POSTMAN_API_KEY
if (-not $apiKey) {
    Write-Error "POSTMAN_API_KEY environment variable not set. Run Setup-EnvironmentVariables first."
    exit 1
}
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`nChecking for backup collections..." -ForegroundColor Cyan

$collections = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers).collections

# Check for today's backups
$todayBackups = $collections | Where-Object { $_.name -like "*Backup 2025-10-06*" }

if ($todayBackups) {
    Write-Host "`n✓ Found $($todayBackups.Count) backup(s) from today:" -ForegroundColor Green
    $todayBackups | ForEach-Object { 
        Write-Host "  • $($_.name)" -ForegroundColor White
        Write-Host "    Updated: $($_.updatedAt)" -ForegroundColor Gray
    }
} else {
    Write-Host "`n✗ No backups found from today (2025-10-06)" -ForegroundColor Yellow
    
    Write-Host "`nAll collections with 'Backup' in name:" -ForegroundColor Cyan
    $allBackups = $collections | Where-Object { $_.name -like "*Backup*" }
    if ($allBackups) {
        $allBackups | Sort-Object updatedAt -Descending | Select-Object -First 10 | ForEach-Object { 
            Write-Host "  • $($_.name)" -ForegroundColor Gray
            Write-Host "    Updated: $($_.updatedAt)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  No backup collections found at all" -ForegroundColor Red
    }
}

# Check the Backup System collection itself
Write-Host "`nChecking Backup System collection..." -ForegroundColor Cyan
$backupSystem = $collections | Where-Object { $_.name -eq "Backup System" }
if ($backupSystem) {
    Write-Host "✓ Backup System collection found" -ForegroundColor Green
    Write-Host "  UID: $($backupSystem.uid)" -ForegroundColor Gray
    
    # Try to get the full collection to see the requests
    try {
        $fullCollection = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($backupSystem.uid)" -Headers $headers).collection
        Write-Host "  Requests in collection:" -ForegroundColor Gray
        $fullCollection.item | ForEach-Object {
            if ($_.item) {
                # It's a folder
                Write-Host "    📁 $($_.name) ($($_.item.Count) requests)" -ForegroundColor Cyan
            } else {
                Write-Host "    📄 $($_.name)" -ForegroundColor White
            }
        }
    } catch {
        Write-Host "  Error fetching collection details: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Backup System collection NOT found!" -ForegroundColor Red
}

Write-Host ""
