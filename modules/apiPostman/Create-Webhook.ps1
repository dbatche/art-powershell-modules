# Create Webhook for Backup System
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "`nFetching Backup System collection..." -ForegroundColor Cyan

# Get the Backup System collection UID
$collections = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers).collections
$backupCollection = $collections | Where-Object { $_.name -eq "Backup System" }

if (-not $backupCollection) {
    Write-Host "ERROR: Backup System collection not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found collection: $($backupCollection.name)" -ForegroundColor Green
Write-Host "  UID: $($backupCollection.uid)" -ForegroundColor Gray

# Get personal workspace ID
Write-Host "`nFetching workspace..." -ForegroundColor Cyan
$workspaces = (Invoke-RestMethod -Uri "https://api.getpostman.com/workspaces" -Headers $headers).workspaces
$personalWs = $workspaces | Where-Object { $_.type -eq "personal" }

Write-Host "✓ Found workspace: $($personalWs.name)" -ForegroundColor Green
Write-Host "  ID: $($personalWs.id)" -ForegroundColor Gray

# Create webhook
Write-Host "`nCreating webhook..." -ForegroundColor Cyan

$webhookPayload = @{
    webhook = @{
        name = "Backup System - Manual Trigger"
        collection = $backupCollection.uid
    }
} | ConvertTo-Json -Depth 10

try {
    $webhook = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/webhooks?workspace=$($personalWs.id)" `
        -Method Post `
        -Headers $headers `
        -Body $webhookPayload
    
    Write-Host "`n✅ WEBHOOK CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "WEBHOOK DETAILS" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "Name:           $($webhook.webhook.name)" -ForegroundColor Cyan
    Write-Host "ID:             $($webhook.webhook.id)" -ForegroundColor Gray
    Write-Host "Collection:     $($backupCollection.name)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔗 WEBHOOK URL:" -ForegroundColor Green
    Write-Host $webhook.webhook.webhookUrl -ForegroundColor White
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "HOW TO USE:" -ForegroundColor Yellow
    Write-Host "  # Trigger from PowerShell:" -ForegroundColor Gray
    Write-Host "  Invoke-RestMethod -Uri '$($webhook.webhook.webhookUrl)' -Method Post" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Trigger with environment:" -ForegroundColor Gray
    Write-Host "  `$body = @{ environment = 'ENV_UID' } | ConvertTo-Json" -ForegroundColor White
    Write-Host "  Invoke-RestMethod -Uri '$($webhook.webhook.webhookUrl)' -Method Post -Body `$body -ContentType 'application/json'" -ForegroundColor White
    Write-Host ""
    
    # Save webhook info to file
    $webhookInfo = @{
        name = $webhook.webhook.name
        id = $webhook.webhook.id
        webhookUrl = $webhook.webhook.webhookUrl
        collection = @{
            name = $backupCollection.name
            uid = $backupCollection.uid
        }
        workspace = @{
            name = $personalWs.name
            id = $personalWs.id
        }
        createdDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $webhookInfo | ConvertTo-Json -Depth 10 | Out-File "postmanAPI/Backup-Webhook-Info.json" -Encoding utf8
    Write-Host "📄 Webhook info saved to: postmanAPI/Backup-Webhook-Info.json" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "`n❌ ERROR creating webhook:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
