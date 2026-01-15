# Update webhook to use "Backup Testing" environment
$apiKey = $env:POSTMAN_API_KEY
if (-not $apiKey) {
    Write-Error "POSTMAN_API_KEY environment variable not set. Run Setup-EnvironmentVariables first."
    exit 1
}
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "`n🔍 Finding 'Backup Testing' environment..." -ForegroundColor Cyan

# Get the Backup Testing environment
$envs = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers).environments
$backupEnv = $envs | Where-Object { $_.name -eq "Backup Testing" }

if (-not $backupEnv) {
    Write-Host "❌ 'Backup Testing' environment not found!" -ForegroundColor Red
    Write-Host "Available environments:" -ForegroundColor Yellow
    $envs | ForEach-Object { Write-Host "  • $($_.name)" -ForegroundColor White }
    exit 1
}

Write-Host "✓ Found: $($backupEnv.name)" -ForegroundColor Green
Write-Host "  UID: $($backupEnv.uid)" -ForegroundColor Gray

# Load current webhook info
$webhookInfo = Get-Content "postmanAPI/Backup-Webhook-Info.json" | ConvertFrom-Json
$webhookId = $webhookInfo.id

Write-Host "`n🔄 Updating webhook to use 'Backup Testing' environment..." -ForegroundColor Cyan

# Get current webhook details
$webhook = (Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/$webhookId" -Headers $headers).webhook

# Update webhook with environment
$updatePayload = @{
    webhook = @{
        name = $webhook.name
        collection = $webhook.collection
        environment = $backupEnv.uid
    }
} | ConvertTo-Json -Depth 10

try {
    $updatedWebhook = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/webhooks/$webhookId" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✅ Webhook updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Webhook now uses: $($backupEnv.name) environment" -ForegroundColor Cyan
    Write-Host ""
    
    # Update the saved webhook info
    $webhookInfo | Add-Member -NotePropertyName "environment" -NotePropertyValue @{
        name = $backupEnv.name
        uid = $backupEnv.uid
    } -Force
    
    $webhookInfo | ConvertTo-Json -Depth 10 | Out-File "postmanAPI/Backup-Webhook-Info.json" -Encoding utf8
    Write-Host "📄 Updated: postmanAPI/Backup-Webhook-Info.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎯 Now try triggering the backup again:" -ForegroundColor Yellow
    Write-Host "   .\Trigger-Backup.ps1" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Error updating webhook:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
