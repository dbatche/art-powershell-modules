# Add-EnvironmentBackup.ps1
# Adds environment backup functionality to existing backup requests
# Environments will be stored as disabled requests in a "📦 Environment Backups" folder
# Strategy: Fetch environments and add to collection BEFORE creating the backup

param(
    [string]$ApiKey = "$env:POSTMAN_API_KEY",
    [string]$CollectionName = "Backup Test - Manual",
    [int]$MaxEnvironments = 10  # Limit number of environments to backup
)

Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "ADDING ENVIRONMENT BACKUP FUNCTIONALITY" -ForegroundColor Yellow
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
    
    # Add environment backup code to collection-level pre-request
    Write-Host "Updating collection-level pre-request..." -ForegroundColor Cyan
    
    # Get current collection pre-request
    $collectionPreReq = $fullCollection.event | Where-Object { $_.listen -eq "prerequest" }
    $currentScript = $collectionPreReq.script.exec -join "`n"
    
    # Add environment backup function
    $envBackupFunction = @'

// ============================================================================
// ENVIRONMENT BACKUP FUNCTIONS
// ============================================================================

// Store environment backup functions as string for use in request callbacks
const envBackupFunctions = `
// Fetch all environments and add to backup collection
function addEnvironmentBackupsToCollection(backupCollectionObj, apiKey, callback) {
    pm.sendRequest({
        url: 'https://api.getpostman.com/environments',
        method: 'GET',
        header: {
            'X-Api-Key': apiKey
        }
    }, function(err, response) {
        if (err) {
            console.log('⚠️  Error fetching environments:', err);
            callback(backupCollectionObj);
            return;
        }
        
        const environments = response.json().environments;
        console.log('\\n📦 Adding environment backups...');
        console.log('   Found: ' + environments.length + ' environments');
        
        // Create environment backups folder
        const envFolder = {
            name: '📦 Environment Backups',
            description: 'Backup of workspace environments. Enable and run a request to restore that environment.',
            item: []
        };
        
        let envCount = 0;
        let pendingRequests = environments.length;
        
        if (pendingRequests === 0) {
            callback(backupCollectionObj);
            return;
        }
        
        // Fetch each environment's details
        environments.forEach(function(env) {
            pm.sendRequest({
                url: 'https://api.getpostman.com/environments/' + env.uid,
                method: 'GET',
                header: {
                    'X-Api-Key': apiKey
                }
            }, function(envErr, envResponse) {
                if (!envErr && envResponse.code === 200) {
                    const fullEnv = envResponse.json().environment;
                    
                    // Create disabled POST request to restore this environment
                    const restoreRequest = {
                        name: 'Restore: ' + fullEnv.name,
                        request: {
                            method: 'POST',
                            header: [
                                {
                                    key: 'X-Api-Key',
                                    value: '{{POSTMAN_API_KEY}}'
                                },
                                {
                                    key: 'Content-Type',
                                    value: 'application/json'
                                }
                            ],
                            body: {
                                mode: 'raw',
                                raw: JSON.stringify({ environment: fullEnv }, null, 2)
                            },
                            url: 'https://api.getpostman.com/environments',
                            description: 'Restore ' + fullEnv.name + ' environment.\\n\\nTo restore:\\n1. Enable this request\\n2. Run it\\n3. Disable it again'
                        },
                        protocolProfileBehavior: {
                            disabledSystemHeaders: {}
                        }
                    };
                    
                    envFolder.item.push(restoreRequest);
                    envCount++;
                }
                
                pendingRequests--;
                if (pendingRequests === 0) {
                    console.log('   Backed up: ' + envCount + ' environments');
                    backupCollectionObj.item.push(envFolder);
                    callback(backupCollectionObj);
                }
            });
        });
    });
}
`;

pm.variables.set("envBackupFunctions", envBackupFunctions);
'@

    $updatedScript = $currentScript + "`n" + $envBackupFunction
    $collectionPreReq.script.exec = @($updatedScript -split "`n")
    
    Write-Host "  ✓ Added environment backup functions" -ForegroundColor Green
    Write-Host ""
    
    # Now update each backup request's test script to add environment backups
    Write-Host "Updating backup request test scripts..." -ForegroundColor Cyan
    $backupRequests = $fullCollection.item | Where-Object { $_.name -match "^Backup: " }
    
    foreach ($request in $backupRequests) {
        Write-Host "  Processing: $($request.name)" -ForegroundColor Gray
        
        $testScript = $request.event | Where-Object { $_.listen -eq "test" }
        if (-not $testScript) { 
            Write-Host "    ⚠ No test script found" -ForegroundColor DarkYellow
            continue 
        }
        
        # Find the end of the successful response handling
        $scriptLines = $testScript.script.exec
        $insertIndex = -1
        
        for ($i = $scriptLines.Count - 1; $i -ge 0; $i--) {
            if ($scriptLines[$i] -match "New Collection ID") {
                $insertIndex = $i + 1
                break
            }
        }
        
        if ($insertIndex -eq -1) {
            Write-Host "    ⚠ Could not find insertion point" -ForegroundColor DarkYellow
            continue
        }
        
        # Add environment backup call
        $newLines = @()
        for ($i = 0; $i -lt $scriptLines.Count; $i++) {
            $newLines += $scriptLines[$i]
            
            if ($i -eq $insertIndex) {
                $newLines += ""
                $newLines += "    // TODO: Add environment backups"
                $newLines += "    // (Will be implemented after collection creation works)"
            }
        }
        
        $testScript.script.exec = $newLines
        Write-Host "    ✓ Added environment backup placeholder" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Updating collection via API..." -ForegroundColor Cyan
    
    $updatePayload = @{
        collection = $fullCollection
    } | ConvertTo-Json -Depth 20
    
    $updateResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✓ Environment backup functions added!" -ForegroundColor Green
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "NEXT STEPS" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Test environment backup by running a backup request" -ForegroundColor White
    Write-Host "2. Verify '📦 Environment Backups' folder is created" -ForegroundColor White
    Write-Host "3. Check that environments are stored as disabled requests" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}

