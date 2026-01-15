# Update-EnvironmentBackup.ps1
# Updates the environment backup request to fetch environments from collection workspaces

param(
    [string]$ApiKey = "$env:POSTMAN_API_KEY",
    [string]$CollectionName = "Backup System"
)

Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "UPDATING ENVIRONMENT BACKUP" -ForegroundColor Yellow
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
    
    # Find the Environment Backups folder and the backup request
    $envFolder = $fullCollection.item | Where-Object { $_.name -eq "🌍 Environment Backups" }
    if (-not $envFolder) {
        throw "Environment Backups folder not found"
    }
    
    $envBackupRequest = $envFolder.item | Where-Object { $_.name -eq "Backup: All Environments" }
    if (-not $envBackupRequest) {
        throw "Backup: All Environments request not found"
    }
    
    Write-Host "✓ Found environment backup request" -ForegroundColor Green
    Write-Host ""
    
    # Load workspace mapping
    $workspaceMapPath = "postmanAPI/Collection-Workspace-Map.json"
    if (-not (Test-Path $workspaceMapPath)) {
        throw "Workspace mapping file not found: $workspaceMapPath"
    }
    
    $workspaceMap = Get-Content $workspaceMapPath | ConvertFrom-Json -AsHashtable
    Write-Host "✓ Loaded workspace mapping ($($workspaceMap.Count) collections)" -ForegroundColor Green
    
    # Get unique workspace IDs
    $uniqueWorkspaces = @{}
    $workspaceMap.GetEnumerator() | ForEach-Object {
        $wsId = $_.Value.WorkspaceId
        $wsName = $_.Value.WorkspaceName
        if (-not $uniqueWorkspaces.ContainsKey($wsId)) {
            $uniqueWorkspaces[$wsId] = $wsName
        }
    }
    
    Write-Host "✓ Found $($uniqueWorkspaces.Count) unique workspaces" -ForegroundColor Green
    Write-Host ""
    
    # Create new pre-request script
    $preRequestScript = @"
// Environment Backup - Fetches environments from collection workspaces
console.log('\n📦 ENVIRONMENT BACKUP');
console.log('='.repeat(60));

const apiKey = pm.environment.get("POSTMAN_API_KEY");

// Workspace IDs for our backed-up collections
const workspaceIds = [
$(($uniqueWorkspaces.GetEnumerator() | ForEach-Object { "    '$($_.Key)',  // $($_.Value)" }) -join "`n")
];

console.log('Fetching environments from ' + workspaceIds.length + ' workspaces...\n');

const backupPrefix = pm.variables.get("backupPrefix");
const dateStamp = pm.variables.get("dateStamp");
const timeStamp = pm.variables.get("timeStamp");
const backupName = backupPrefix + " " + dateStamp + timeStamp + " - Environment Backups";

// Create backup collection structure
const envBackupCollection = {
    info: {
        name: backupName,
        description: "Environment backups from collection workspaces",
        schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    item: []
};

const envFolder = {
    name: '📦 Environment Backups',
    description: 'Backup of workspace environments. Enable and run a request to restore.',
    item: []
};

let pendingWorkspaces = workspaceIds.length;
let totalEnvCount = 0;
let workspaceEnvCounts = {};

// Fetch environments from each workspace
workspaceIds.forEach(function(workspaceId, index) {
    pm.sendRequest({
        url: 'https://api.getpostman.com/workspaces/' + workspaceId,
        method: 'GET',
        header: { 'X-Api-Key': apiKey }
    }, function(wsErr, wsResponse) {
        if (wsErr || wsResponse.code !== 200) {
            console.log('  ✗ Workspace [' + (index + 1) + ']: Error fetching');
            pendingWorkspaces--;
            checkCompletion();
            return;
        }
        
        const workspace = wsResponse.json().workspace;
        console.log('  📁 ' + workspace.name + ':');
        
        if (!workspace.environments || workspace.environments.length === 0) {
            console.log('     No environments');
            pendingWorkspaces--;
            checkCompletion();
            return;
        }
        
        console.log('     Found ' + workspace.environments.length + ' environment(s)');
        workspaceEnvCounts[workspace.name] = workspace.environments.length;
        
        let pendingEnvs = workspace.environments.length;
        let successCount = 0;
        
        // Fetch each environment's details
        workspace.environments.forEach(function(env) {
            pm.sendRequest({
                url: 'https://api.getpostman.com/environments/' + env.uid,
                method: 'GET',
                header: { 'X-Api-Key': apiKey }
            }, function(envErr, envResponse) {
                if (!envErr && envResponse.code === 200) {
                    const fullEnv = envResponse.json().environment;
                    console.log('       ✓ ' + fullEnv.name);
                    
                    // Create restore request
                    const restoreRequest = {
                        name: 'Restore: ' + fullEnv.name + ' [' + workspace.name + ']',
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
                            description: 'Restore ' + fullEnv.name + ' environment from ' + workspace.name + ' workspace.\n\nOriginal UID: ' + fullEnv.uid
                        }
                    };
                    
                    envFolder.item.push(restoreRequest);
                    successCount++;
                    totalEnvCount++;
                } else {
                    console.log('       ✗ Error: ' + env.name);
                }
                
                pendingEnvs--;
                if (pendingEnvs === 0) {
                    console.log('     Backed up: ' + successCount + ' environment(s)');
                    pendingWorkspaces--;
                    checkCompletion();
                }
            });
        });
    });
});

function checkCompletion() {
    if (pendingWorkspaces === 0) {
        console.log('');
        console.log('=' .repeat(60));
        console.log('Total environments backed up: ' + totalEnvCount);
        console.log('Creating backup collection...');
        console.log('');
        
        envBackupCollection.item.push(envFolder);
        pm.variables.set("backupCollection", JSON.stringify({ collection: envBackupCollection }));
        pm.variables.set("backupName", backupName);
        pm.variables.set("envCount", totalEnvCount);
    }
}
"@

    # Update the pre-request script
    $preReq = $envBackupRequest.event | Where-Object { $_.listen -eq "prerequest" }
    $preReq.script.exec = @($preRequestScript -split "`n")
    
    Write-Host "Updating collection via API..." -ForegroundColor Cyan
    
    $updatePayload = @{
        collection = $fullCollection
    } | ConvertTo-Json -Depth 20
    
    $updateResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✓ Environment backup updated!" -ForegroundColor Green
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "READY TO TEST" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run: 'Backup: All Environments' in Postman" -ForegroundColor White
    Write-Host ""
    Write-Host "Will fetch environments from:" -ForegroundColor Yellow
    $uniqueWorkspaces.GetEnumerator() | Sort-Object Value | ForEach-Object {
        Write-Host "  • $($_.Value)" -ForegroundColor Gray
    }
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}


