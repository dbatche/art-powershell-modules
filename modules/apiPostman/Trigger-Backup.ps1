# Quick Trigger for Backup System Webhook
# Run this anytime you want to manually trigger a backup

param(
    [string]$EnvironmentUid = ""  # Optional: specify environment UID
)

Write-Host "`n🚀 Triggering Backup System..." -ForegroundColor Cyan

# Load webhook info
$webhookInfo = Get-Content "postmanAPI/Backup-Webhook-Info.json" | ConvertFrom-Json
$webhookUrl = $webhookInfo.webhookUrl

Write-Host "Collection: $($webhookInfo.collection.name)" -ForegroundColor Gray
Write-Host "Workspace:  $($webhookInfo.workspace.name)" -ForegroundColor Gray

try {
    if ($EnvironmentUid) {
        Write-Host "Environment: $EnvironmentUid" -ForegroundColor Gray
        $body = @{ environment = $EnvironmentUid } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
    } else {
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post
    }
    
    Write-Host "`n📊 WEBHOOK RESPONSE:" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Gray
    
    if ($response) {
        # Display the full response
        $response | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor White
        
        # Check for common response fields
        if ($response.message) {
            Write-Host "`nMessage: $($response.message)" -ForegroundColor Yellow
        }
        if ($response.status) {
            Write-Host "Status: $($response.status)" -ForegroundColor Yellow
        }
        if ($response.runId) {
            Write-Host "Run ID: $($response.runId)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Empty response (this might indicate a problem)" -ForegroundColor Yellow
    }
    
    Write-Host "=" * 60 -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Webhook call completed" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ Wait 30-60 seconds, then check your Postman workspace for:" -ForegroundColor Yellow
    Write-Host "  • Auto Backup [timestamp] - [Collection Name]" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 To verify backups were created, run:" -ForegroundColor Cyan
    Write-Host "   .\Check-BackupStatus.ps1" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "`n❌ Error triggering backup:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
