# Add-EnvironmentBackupTest.ps1
# Creates a single test request to backup environments as disabled requests in a folder

param(
    [string]$ApiKey = $env:POSTMAN_API_KEY,
    [string]$CollectionName = "Backup Test - Manual",
    [int]$MaxEnvironments = 5  # Limit for testing
)

Write-Host "`n" -NoNewline
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "ADDING ENVIRONMENT BACKUP TEST" -ForegroundColor Yellow
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
    
    # Create test request pre-request script
    $preRequestScript = @'
// TEST: Environment Backup
console.log('\n📦 ENVIRONMENT BACKUP TEST');
console.log('='.repeat(60));

const maxEnvs = 5;  // Limit for testing
const apiKey = pm.environment.get("POSTMAN_API_KEY");

pm.sendRequest({
    url: 'https://api.getpostman.com/environments',
    method: 'GET',
    header: {
        'X-Api-Key': apiKey
    }
}, function(err, response) {
    if (err) {
        console.log('❌ Error fetching environments:', err);
        pm.variables.set("envError", err.message);
        return;
    }
    
    const allEnvs = response.json().environments;
    const environments = allEnvs.slice(0, maxEnvs);  // Limit for testing
    
    console.log('Found: ' + allEnvs.length + ' total environments');
    console.log('Testing with: ' + environments.length + ' environments\n');
    
    // Create test collection with environment backups folder
    const backupPrefix = pm.variables.get("backupPrefix");
    const dateStamp = pm.variables.get("dateStamp");
    const timeStamp = pm.variables.get("timeStamp");
    const backupName = backupPrefix + " " + dateStamp + timeStamp + " - Environment Backup Test";
    
    const testCollection = {
        info: {
            name: backupName,
            description: "Test backup containing environment backups",
            schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        item: []
    };
    
    let envCount = 0;
    let pendingRequests = environments.length;
    
    if (pendingRequests === 0) {
        pm.variables.set("backupError", "No environments found");
        return;
    }
    
    // Create environment backups folder
    const envFolder = {
        name: '📦 Environment Backups',
        description: 'Backup of workspace environments. Enable and run a request to restore that environment.',
        item: []
    };
    
    // Fetch each environment's full details
    environments.forEach(function(env, index) {
        pm.sendRequest({
            url: 'https://api.getpostman.com/environments/' + env.uid,
            method: 'GET',
            header: {
                'X-Api-Key': apiKey
            }
        }, function(envErr, envResponse) {
            if (!envErr && envResponse.code === 200) {
                const fullEnv = envResponse.json().environment;
                
                console.log('  ✓ Fetched: ' + fullEnv.name);
                
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
                        description: 'Restore ' + fullEnv.name + ' environment.\n\nTo restore:\n1. Enable this request\n2. Run it\n3. Disable it again\n\nOriginal UID: ' + fullEnv.uid
                    }
                };
                
                envFolder.item.push(restoreRequest);
                envCount++;
            } else {
                console.log('  ✗ Error fetching: ' + env.name);
            }
            
            pendingRequests--;
            if (pendingRequests === 0) {
                console.log('\nBacked up: ' + envCount + ' environments');
                console.log('Creating test backup collection...\n');
                
                testCollection.item.push(envFolder);
                pm.variables.set("backupCollection", JSON.stringify({ collection: testCollection }));
                pm.variables.set("backupName", backupName);
            }
        });
    });
});
'@

    # Create test script
    $testScript = @'
console.log("\n" + "=".repeat(60));
console.log("RESPONSE: ENVIRONMENT BACKUP TEST");
console.log("=".repeat(60));

const backupName = pm.variables.get("backupName");
const backupError = pm.variables.get("backupError");

if (backupError) {
    console.log("❌ ERROR: " + backupError);
    pm.test("No errors occurred", function() {
        pm.expect(backupError).to.be.undefined;
    });
} else if (pm.response.code === 200) {
    const response = pm.response.json();
    
    console.log("\n✅ SUCCESS! Environment backup test complete!");
    console.log("   Backup: " + backupName);
    console.log("   New Collection UID: " + response.collection.uid);
    console.log("   New Collection ID: " + response.collection.id);
    
    // Check for environment backups folder
    const hasEnvFolder = response.collection.item && 
                         response.collection.item.some(item => item.name === '📦 Environment Backups');
    
    if (hasEnvFolder) {
        const envFolder = response.collection.item.find(item => item.name === '📦 Environment Backups');
        console.log("\n📦 Environment Backups Folder:");
        console.log("   Contains: " + envFolder.item.length + " restore requests");
        envFolder.item.forEach(req => {
            console.log("   • " + req.name);
        });
    }
    
    pm.test("Backup created successfully", function () {
        pm.response.to.have.status(200);
    });
    
    pm.test("Backup has correct name", function () {
        pm.expect(response.collection.name).to.equal(backupName);
    });
    
    pm.test("Environment backups folder exists", function () {
        pm.expect(hasEnvFolder).to.be.true;
    });
} else {
    console.log("❌ API ERROR: " + pm.response.code);
    console.log("   " + JSON.stringify(pm.response.json(), null, 2));
    
    pm.test("Backup created successfully", function () {
        pm.response.to.have.status(200);
    });
}
'@

    # Create the request
    $newRequest = @{
        name = "TEST: Environment Backup"
        request = @{
            method = "POST"
            header = @(
                @{
                    key = "X-Api-Key"
                    value = "{{POSTMAN_API_KEY}}"
                },
                @{
                    key = "Content-Type"
                    value = "application/json"
                }
            )
            body = @{
                mode = "raw"
                raw = "{{backupCollection}}"
            }
            url = "https://api.getpostman.com/collections"
        }
        event = @(
            @{
                listen = "prerequest"
                script = @{
                    exec = @($preRequestScript -split "`n")
                }
            },
            @{
                listen = "test"
                script = @{
                    exec = @($testScript -split "`n")
                }
            }
        )
    }
    
    # Add to collection
    $fullCollection.item += $newRequest
    
    # Update collection
    $updatePayload = @{
        collection = $fullCollection
    } | ConvertTo-Json -Depth 20
    
    Write-Host "Updating collection via API..." -ForegroundColor Cyan
    
    $updateResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✓ Environment backup test added!" -ForegroundColor Green
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "TEST IT" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run: 'TEST: Environment Backup' in Postman" -ForegroundColor White
    Write-Host ""
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Fetch first $MaxEnvironments environments" -ForegroundColor Gray
    Write-Host "  2. Create '📦 Environment Backups' folder" -ForegroundColor Gray
    Write-Host "  3. Add disabled restore requests for each environment" -ForegroundColor Gray
    Write-Host "  4. Create test backup collection" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Expected: Backup collection with environment restore requests! 🎯" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}


