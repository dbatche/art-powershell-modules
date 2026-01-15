# Try to get webhook run logs
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`n🔍 Checking for webhook run logs..." -ForegroundColor Cyan

# Load webhook info
$webhookInfo = Get-Content "postmanAPI/Backup-Webhook-Info.json" | ConvertFrom-Json

Write-Host "Webhook: $($webhookInfo.name)" -ForegroundColor Gray
Write-Host "ID:      $($webhookInfo.id)" -ForegroundColor Gray

# Try different endpoints that might have run information
Write-Host "`n1. Checking webhook details..." -ForegroundColor Yellow
try {
    $webhook = Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/$($webhookInfo.id)" -Headers $headers
    Write-Host "✓ Webhook found" -ForegroundColor Green
    $webhook.webhook | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White
} catch {
    Write-Host "✗ Could not get webhook details: $($_.Exception.Message)" -ForegroundColor Red
}

# Check for monitors (webhooks might be related to monitors)
Write-Host "`n2. Checking monitors..." -ForegroundColor Yellow
try {
    $monitors = (Invoke-RestMethod -Uri "https://api.getpostman.com/monitors" -Headers $headers).monitors
    if ($monitors) {
        Write-Host "✓ Found $($monitors.Count) monitor(s)" -ForegroundColor Green
        $backupMonitor = $monitors | Where-Object { $_.name -like "*Backup*" -or $_.collection -eq $webhookInfo.collection.uid }
        if ($backupMonitor) {
            Write-Host "`nBackup-related monitor:" -ForegroundColor Cyan
            $backupMonitor | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
        } else {
            Write-Host "No monitor found for Backup System collection" -ForegroundColor Gray
        }
    } else {
        Write-Host "No monitors found" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Try to get collection run history (if available)
Write-Host "`n3. Checking for collection runs..." -ForegroundColor Yellow
try {
    # This endpoint might not exist, but worth trying
    $runs = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($webhookInfo.collection.uid)/runs" -Headers $headers
    Write-Host "✓ Found collection runs" -ForegroundColor Green
    $runs | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✗ Collection runs endpoint not available (404)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Try workspace activity (might show webhook executions)
Write-Host "`n4. Checking workspace activity..." -ForegroundColor Yellow
try {
    $activity = Invoke-RestMethod -Uri "https://api.getpostman.com/workspaces/$($webhookInfo.workspace.id)/activities" -Headers $headers
    Write-Host "✓ Found workspace activity" -ForegroundColor Green
    
    # Show recent activity
    if ($activity.activities) {
        Write-Host "`nRecent activities (last 10):" -ForegroundColor Cyan
        $activity.activities | Select-Object -First 10 | ForEach-Object {
            Write-Host "  • $($_.action) - $($_.timestamp)" -ForegroundColor White
            if ($_.message) {
                Write-Host "    $($_.message)" -ForegroundColor Gray
            }
        }
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "✗ Workspace activity endpoint not available (404)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n" -ForegroundColor Gray
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host "SUMMARY:" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Gray
Write-Host ""
Write-Host "Webhook runs are executed by Postman's Newman cloud runner." -ForegroundColor White
Write-Host "Unfortunately, the Postman API doesn't provide:" -ForegroundColor Yellow
Write-Host "  • Console logs from webhook runs" -ForegroundColor White
Write-Host "  • Detailed execution history" -ForegroundColor White
Write-Host "  • Test results or timing information" -ForegroundColor White
Write-Host ""
Write-Host "Available information:" -ForegroundColor Green
Write-Host "  • Created collections (verify backups were made)" -ForegroundColor White
Write-Host "  • Webhook configuration" -ForegroundColor White
Write-Host ""
Write-Host "For detailed run logs, you would need:" -ForegroundColor Cyan
Write-Host "  • Postman Monitor (not webhook) - has full run history" -ForegroundColor White
Write-Host "  • Or check created backup collections as evidence" -ForegroundColor White
Write-Host ""
