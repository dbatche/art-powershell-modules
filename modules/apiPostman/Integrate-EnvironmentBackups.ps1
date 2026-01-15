# Integrate-EnvironmentBackups.ps1
# Integrates environment backup functionality into the main 6 backup requests

param(
    [string]$ApiKey = $env:POSTMAN_API_KEY,
    [string]$CollectionName = "Backup Test - Manual",
    [int]$MaxEnvironments = 10  # Reasonable limit for production
)

Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "INTEGRATING ENVIRONMENT BACKUPS" -ForegroundColor Yellow
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""

try {
    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    # Get the backup collection
    $collections = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers).collections
    $backupCollection = $collections | Where-Object { $_.name -eq $CollectionName }

    if (-not $backupCollection) {
        throw "Collection '$CollectionName' not found"
    }

    Write-Host "✓ Found collection: $($backupCollection.uid)" -ForegroundColor Green
    
    # Get full collection details
    $fullCollection = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" -Headers $headers).collection
    
    Write-Host "  Current items: $($fullCollection.item.Count)" -ForegroundColor Gray
    Write-Host ""
    
    # Find the main 6 backup requests
    $backupRequests = $fullCollection.item | Where-Object { $_.name -match "^Backup: " }
    
    Write-Host "Found $($backupRequests.Count) backup requests to update:" -ForegroundColor Yellow
    $backupRequests | ForEach-Object { Write-Host "  • $($_.name)" -ForegroundColor Gray }
    Write-Host ""
    
    $updatedCount = 0
    
    foreach ($request in $backupRequests) {
        $requestName = $request.name
        Write-Host "Processing: $requestName" -ForegroundColor Cyan
        
        $preReq = $request.event | Where-Object { $_.listen -eq "prerequest" }
        if (-not $preReq) {
            Write-Host "  ⚠ No pre-request script found, skipping" -ForegroundColor DarkYellow
            continue
        }
        
        # Find where we create the backup collection (before stringify)
        $scriptLines = $preReq.script.exec
        $insertIndex = -1
        
        for ($i = 0; $i -lt $scriptLines.Count; $i++) {
            if ($scriptLines[$i] -match "Clean collection before stringify") {
                $insertIndex = $i - 1  # Insert before the cleaning comment
                break
            }
        }
        
        if ($insertIndex -eq -1) {
            Write-Host "  ⚠ Could not find insertion point, skipping" -ForegroundColor DarkYellow
            continue
        }
        
        # Create the environment backup code to insert
        $envBackupCode = @'
    
    // ========================================================================
    // ADD ENVIRONMENT BACKUPS
    // ========================================================================
    console.log('\n📦 Adding environment backups...');
    
    const maxEnvs = 10;  // Limit to prevent timeouts
    let envBackupsPending = true;
    
    pm.sendRequest({
        url: 'https://api.getpostman.com/environments',
        method: 'GET',
        header: { 'X-Api-Key': pm.environment.get("POSTMAN_API_KEY") }
    }, function(envListErr, envListResponse) {
        if (envListErr || envListResponse.code !== 200) {
            console.log('⚠️  Could not fetch environments, skipping');
            envBackupsPending = false;
            return;
        }
        
        const allEnvs = envListResponse.json().environments;
        const environments = allEnvs.slice(0, maxEnvs);
        console.log('   Backing up ' + environments.length + ' of ' + allEnvs.length + ' environments');
        
        if (environments.length === 0) {
            envBackupsPending = false;
            return;
        }
        
        const envFolder = {
            name: '📦 Environment Backups',
            description: 'Backup of workspace environments. Enable and run a request to restore.',
            item: []
        };
        
        let pendingEnvs = environments.length;
        let successCount = 0;
        
        environments.forEach(function(env) {
            pm.sendRequest({
                url: 'https://api.getpostman.com/environments/' + env.uid,
                method: 'GET',
                header: { 'X-Api-Key': pm.environment.get("POSTMAN_API_KEY") }
            }, function(envErr, envResponse) {
                if (!envErr && envResponse.code === 200) {
                    const fullEnv = envResponse.json().environment;
                    envFolder.item.push({
                        name: 'Restore: ' + fullEnv.name,
                        request: {
                            method: 'POST',
                            header: [
                                { key: 'X-Api-Key', value: '{{POSTMAN_API_KEY}}' },
                                { key: 'Content-Type', value: 'application/json' }
                            ],
                            body: {
                                mode: 'raw',
                                raw: JSON.stringify({ environment: fullEnv }, null, 2)
                            },
                            url: 'https://api.getpostman.com/environments',
                            description: 'Restore ' + fullEnv.name + ' environment.'
                        }
                    });
                    successCount++;
                }
                
                pendingEnvs--;
                if (pendingEnvs === 0) {
                    console.log('   ✓ Added ' + successCount + ' environment backups');
                    collection.item.push(envFolder);
                    envBackupsPending = false;
                }
            });
        });
    });
    
    // Wait for environment backups to complete (with timeout)
    const waitStart = Date.now();
    const waitForEnvs = function() {
        if (!envBackupsPending) {
            // Ready to proceed with backup creation
'@
        
        # Insert the code
        $newScript = @()
        for ($i = 0; $i -lt $scriptLines.Count; $i++) {
            if ($i -eq $insertIndex) {
                $envBackupCode -split "`n" | ForEach-Object { $newScript += $_ }
            }
            $newScript += $scriptLines[$i]
        }
        
        # Now we need to wrap the cleanup and stringify in a function call
        # Find the stringify line and wrap everything after insertion point
        $stringifyIndex = -1
        for ($i = $insertIndex; $i -lt $newScript.Count; $i++) {
            if ($newScript[$i] -match "JSON\.stringify") {
                $stringifyIndex = $i
                break
            }
        }
        
        if ($stringifyIndex -ne -1) {
            # Close the waitForEnvs function and add timeout logic
            $closeWait = @'
        } else if (Date.now() - waitStart > 30000) {
            console.log('⚠️  Timeout waiting for environment backups, proceeding anyway');
            envBackupsPending = false;
        } else {
            setTimeout(waitForEnvs, 500);
        }
    };
    
    setTimeout(waitForEnvs, 100);
});

// Note: The cleanup and stringify code below will execute after environment backups
// are added to the collection object
'@
            
            # We need to restructure - actually, let's use a simpler approach
            # Just add environments synchronously AFTER collection fetch, BEFORE stringify
            Write-Host "  ⚠ Structure too complex, needs manual integration" -ForegroundColor DarkYellow
            continue
        }
        
        $preReq.script.exec = $newScript
        $updatedCount++
        Write-Host "  ✓ Added environment backup code" -ForegroundColor Green
    }
    
    if ($updatedCount -eq 0) {
        Write-Host ""
        Write-Host "❌ Could not update any requests automatically" -ForegroundColor Red
        Write-Host "   The pre-request structure is too complex for automatic integration" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Recommendation: Manually add environment backup code based on the test" -ForegroundColor Cyan
        return
    }
    
    Write-Host ""
    Write-Host "Summary: Updated $updatedCount requests" -ForegroundColor Yellow
    Write-Host ""
    
    # Update collection via API
    $updatePayload = @{
        collection = $fullCollection
    } | ConvertTo-Json -Depth 20
    
    Write-Host "Updating collection via API..." -ForegroundColor Cyan
    
    $updateResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✓ Environment backups integrated!" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}


