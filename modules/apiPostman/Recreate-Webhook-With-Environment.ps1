# Delete old webhook and create new one with environment
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "`n🔍 Getting webhook and environment info..." -ForegroundColor Cyan

# Load current webhook info
$webhookInfo = Get-Content "postmanAPI/Backup-Webhook-Info.json" | ConvertFrom-Json

# Get Backup Testing environment
$envs = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers).environments
$backupEnv = $envs | Where-Object { $_.name -eq "Backup Testing" }

if (-not $backupEnv) {
    Write-Host "❌ 'Backup Testing' environment not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Environment: $($backupEnv.name)" -ForegroundColor Green
Write-Host "  UID: $($backupEnv.uid)" -ForegroundColor Gray

# Delete old webhook
Write-Host "`n🗑️  Deleting old webhook..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/$($webhookInfo.id)" -Headers $headers -Method Delete | Out-Null
    Write-Host "✓ Old webhook deleted" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not delete old webhook (might already be gone)" -ForegroundColor Yellow
}

# Create new webhook with environment
Write-Host "`n✨ Creating new webhook with environment..." -ForegroundColor Cyan

$webhookPayload = @{
    webhook = @{
        name = "Backup System - Manual Trigger"
        collection = $webhookInfo.collection.uid
        environment = $backupEnv.uid
    }
} | ConvertTo-Json -Depth 10

try {
    $newWebhook = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/webhooks?workspace=$($webhookInfo.workspace.id)" `
        -Method Post `
        -Headers $headers `
        -Body $webhookPayload
    
    Write-Host "`n✅ NEW WEBHOOK CREATED WITH ENVIRONMENT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "Name:           $($newWebhook.webhook.name)" -ForegroundColor Cyan
    Write-Host "ID:             $($newWebhook.webhook.id)" -ForegroundColor Gray
    Write-Host "Collection:     $($webhookInfo.collection.name)" -ForegroundColor Cyan
    Write-Host "Environment:    $($backupEnv.name) ✓" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔗 WEBHOOK URL:" -ForegroundColor Green
    Write-Host $newWebhook.webhook.webhookUrl -ForegroundColor White
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    
    # Save updated webhook info
    $updatedInfo = @{
        name = $newWebhook.webhook.name
        id = $newWebhook.webhook.id
        webhookUrl = $newWebhook.webhook.webhookUrl
        collection = @{
            name = $webhookInfo.collection.name
            uid = $webhookInfo.collection.uid
        }
        workspace = @{
            name = $webhookInfo.workspace.name
            id = $webhookInfo.workspace.id
        }
        environment = @{
            name = $backupEnv.name
            uid = $backupEnv.uid
        }
        createdDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $updatedInfo | ConvertTo-Json -Depth 10 | Out-File "postmanAPI/Backup-Webhook-Info.json" -Encoding utf8
    Write-Host "📄 Updated: postmanAPI/Backup-Webhook-Info.json" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎯 Now trigger the backup (this should work!):" -ForegroundColor Yellow
    Write-Host "   .\Trigger-Backup.ps1" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Error creating webhook:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
