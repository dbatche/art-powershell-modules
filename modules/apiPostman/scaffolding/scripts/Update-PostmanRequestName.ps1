# Update-PostmanRequestName.ps1
# Updates one or more Postman request names using the Postman API

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $true)]
    [string]$CollectionUid,
    
    [Parameter(Mandatory = $false)]
    [string]$RequestUid,
    
    [Parameter(Mandatory = $false)]
    [string]$NewName,
    
    [Parameter(Mandatory = $false)]
    [hashtable[]]$BulkUpdates
)

$headers = @{
    "X-API-Key" = $ApiKey
    "Content-Type" = "application/json"
}

function Update-SingleRequest {
    param(
        [string]$CollectionUid,
        [string]$RequestUid,
        [string]$NewName
    )
    
    $uri = "https://api.getpostman.com/collections/$CollectionUid/requests/$RequestUid"
    
    try {
        # GET the full request object
        Write-Host "Fetching request..." -ForegroundColor Yellow
        $getResponse = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        $requestData = $getResponse.data | ConvertTo-Json -Depth 20 | ConvertFrom-Json
        
        $oldName = $requestData.name
        Write-Host "  Current: $oldName" -ForegroundColor Gray
        
        # Modify the name
        $requestData.name = $NewName
        
        # PUT the full object back
        $body = $requestData | ConvertTo-Json -Depth 20
        $putResponse = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
        
        Write-Host "✓ Renamed to: $NewName" -ForegroundColor Green
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "✗ Failed to rename" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($_.ErrorDetails.Message) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
        Write-Host ""
        
        return $false
    }
}

# Main execution
Write-Host "Postman Request Name Updater" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

if ($BulkUpdates) {
    # Bulk update mode
    Write-Host "Bulk update mode: $($BulkUpdates.Count) request(s)" -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    
    foreach ($update in $BulkUpdates) {
        Write-Host "[$($successCount + $failCount + 1)/$($BulkUpdates.Count)] Processing: $($update.NewName)" -ForegroundColor Cyan
        
        $result = Update-SingleRequest -CollectionUid $CollectionUid `
                                       -RequestUid $update.Uid `
                                       -NewName $update.NewName
        
        if ($result) {
            $successCount++
        } else {
            $failCount++
        }
    }
    
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "✓ Success: $successCount" -ForegroundColor Green
    if ($failCount -gt 0) {
        Write-Host "✗ Failed: $failCount" -ForegroundColor Red
    }
}
elseif ($RequestUid -and $NewName) {
    # Single update mode
    Write-Host "Single update mode" -ForegroundColor Cyan
    Write-Host ""
    
    $result = Update-SingleRequest -CollectionUid $CollectionUid `
                                   -RequestUid $RequestUid `
                                   -NewName $NewName
    
    if ($result) {
        Write-Host "✓ Request updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to update request" -ForegroundColor Red
    }
}
else {
    Write-Host "ERROR: Please provide either:" -ForegroundColor Red
    Write-Host "  1. -RequestUid and -NewName for single update" -ForegroundColor Yellow
    Write-Host "  2. -BulkUpdates for multiple updates" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  # Single update:" -ForegroundColor Gray
    Write-Host '  .\Update-PostmanRequestName.ps1 -ApiKey "YOUR_KEY" -CollectionUid "8229908-xxx" -RequestUid "8229908-xxx" -NewName "My New Name"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Bulk update:" -ForegroundColor Gray
    Write-Host '  $updates = @(' -ForegroundColor Gray
    Write-Host '      @{ Uid = "8229908-xxx"; NewName = "Name 1" },' -ForegroundColor Gray
    Write-Host '      @{ Uid = "8229908-yyy"; NewName = "Name 2" }' -ForegroundColor Gray
    Write-Host '  )' -ForegroundColor Gray
    Write-Host '  .\Update-PostmanRequestName.ps1 -ApiKey "YOUR_KEY" -CollectionUid "8229908-xxx" -BulkUpdates $updates' -ForegroundColor Gray
    exit 1
}

