# Get run history for webhook (via monitor API)
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`n📊 Fetching webhook run history..." -ForegroundColor Cyan

# Load webhook info
$webhookInfo = Get-Content "postmanAPI/Backup-Webhook-Info.json" | ConvertFrom-Json

Write-Host "Webhook: $($webhookInfo.name)" -ForegroundColor Gray
Write-Host "Monitor ID: $($webhookInfo.id)" -ForegroundColor Gray

try {
    $runs = Invoke-RestMethod -Uri "https://api.getpostman.com/monitors/$($webhookInfo.id)/runs" -Headers $headers
    
    Write-Host "`n✅ Found run history!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "WEBHOOK RUN HISTORY" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Total runs: $($runs.runs.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    if ($runs.runs -and $runs.runs.Count -gt 0) {
        Write-Host "Recent runs (showing last 10):" -ForegroundColor Cyan
        Write-Host ""
        
        $runs.runs | Select-Object -First 10 | ForEach-Object {
            $duration = if ($_.startedAt -and $_.finishedAt) {
                $start = [datetime]$_.startedAt
                $end = [datetime]$_.finishedAt
                $diff = $end - $start
                "$($diff.TotalSeconds.ToString('0.0'))s"
            } else {
                "N/A"
            }
            
            $statusColor = switch ($_.status) {
                "finished" { "Green" }
                "failed" { "Red" }
                "running" { "Yellow" }
                default { "Gray" }
            }
            
            Write-Host "  Run #$($runs.runs.IndexOf($_) + 1)" -ForegroundColor White
            Write-Host "    Started:  $($_.startedAt)" -ForegroundColor Gray
            Write-Host "    Finished: $($_.finishedAt)" -ForegroundColor Gray
            Write-Host "    Duration: $duration" -ForegroundColor Gray
            Write-Host "    Status:   $($_.status)" -ForegroundColor $statusColor
            
            if ($_.stats) {
                Write-Host "    Stats:" -ForegroundColor Cyan
                Write-Host "      Requests:   $($_.stats.requests?.total)" -ForegroundColor White
                Write-Host "      Assertions: $($_.stats.assertions?.total) (Failed: $($_.stats.assertions?.failed))" -ForegroundColor White
            }
            
            Write-Host ""
        }
        
        # Check if we can get detailed logs for the most recent run
        Write-Host "=" * 80 -ForegroundColor Yellow
        Write-Host "`nTrying to get detailed logs for most recent run..." -ForegroundColor Cyan
        
        $latestRun = $runs.runs[0]
        try {
            $runDetails = Invoke-RestMethod -Uri "https://api.getpostman.com/monitors/$($webhookInfo.id)/runs/$($latestRun.id)" -Headers $headers
            
            Write-Host "✓ Found detailed logs!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Latest Run Details:" -ForegroundColor Yellow
            $runDetails | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor White
            
        } catch {
            Write-Host "✗ Detailed logs not available: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "No runs found yet" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n✗ Could not get run history" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}

Write-Host ""
