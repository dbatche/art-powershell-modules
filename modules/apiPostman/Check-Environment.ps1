# Check if environment with POSTMAN_API_KEY exists
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

Write-Host "`n🔍 Checking environments..." -ForegroundColor Cyan

$envs = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers).environments

Write-Host "`nEnvironments found: $($envs.Count)" -ForegroundColor Yellow
$envs | ForEach-Object { 
    Write-Host "  • $($_.name)" -ForegroundColor White
    Write-Host "    UID: $($_.uid)" -ForegroundColor Gray
}

Write-Host "`n🔑 Checking for POSTMAN_API_KEY variable..." -ForegroundColor Cyan
$foundApiKey = $false

foreach ($env in $envs) {
    try {
        $fullEnv = (Invoke-RestMethod -Uri "https://api.getpostman.com/environments/$($env.uid)" -Headers $headers).environment
        $hasApiKey = $fullEnv.values | Where-Object { $_.key -eq "POSTMAN_API_KEY" }
        
        if ($hasApiKey) {
            Write-Host "  ✓ $($env.name) has POSTMAN_API_KEY" -ForegroundColor Green
            $foundApiKey = $true
        }
    } catch {
        Write-Host "  Error checking $($env.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $foundApiKey) {
    Write-Host "`n❌ PROBLEM FOUND:" -ForegroundColor Red
    Write-Host "  No environment has POSTMAN_API_KEY variable!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This is why the webhook didn't create backups:" -ForegroundColor Yellow
    Write-Host "  • Webhook runs the collection" -ForegroundColor White
    Write-Host "  • But without POSTMAN_API_KEY in an environment" -ForegroundColor White
    Write-Host "  • The pre-request scripts can't call the Postman API" -ForegroundColor White
    Write-Host "  • So no backups are created" -ForegroundColor White
    Write-Host ""
    Write-Host "SOLUTION:" -ForegroundColor Green
    Write-Host "  1. Create/update an environment with POSTMAN_API_KEY" -ForegroundColor White
    Write-Host "  2. Update webhook to use that environment" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
