<#
.SYNOPSIS
    Adds a backup request for "TM - Trips POST/PUT" to the Backup System collection.

.DESCRIPTION
    Finds the "Backup System" collection and adds a new backup request to the 
    "📦 Collection Backups" folder for the TM - Trips POST/PUT collection.

.PARAMETER ApiKey
    Postman API Key. Defaults to $env:POSTMAN_API_KEY.

.PARAMETER BackupCollectionId
    The UID of the Backup System collection. Defaults to the known ID.

.EXAMPLE
    Add-TripsPostPutBackupRequest
#>

function Add-TripsPostPutBackupRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = $env:POSTMAN_API_KEY,

        [Parameter(Mandatory=$false)]
        [string]$BackupCollectionId = "2332132-fdd6be92-cea2-4421-8109-0bcd3724ae20"
    )

    if (-not $ApiKey) {
        throw "ApiKey is required. Please provide it as a parameter or set the `$env:POSTMAN_API_KEY` environment variable."
    }

    $headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }

    Write-Host "Adding backup request for 'TM - Trips POST/PUT'..." -ForegroundColor Cyan

    try {
        # Get the backup collection
        Write-Host "Fetching Backup System collection..." -ForegroundColor Yellow
        $fullCollection = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$BackupCollectionId" -Headers $headers).collection
        
        Write-Host "✓ Found collection: $($fullCollection.info.name)" -ForegroundColor Green

        # Find the "📦 Collection Backups" folder (match by containing "Collection Backups")
        $backupFolder = $fullCollection.item | Where-Object { $_.name -match "Collection Backups" }
        
        if (-not $backupFolder) {
            Write-Error "Could not find '📦 Collection Backups' folder in the collection."
            return
        }

        Write-Host "✓ Found backup folder with $($backupFolder.item.Count) existing requests" -ForegroundColor Green

        # Check if request already exists
        $existingRequest = $backupFolder.item | Where-Object { $_.name -eq "Backup: TM - Trips POST/PUT" }
        if ($existingRequest) {
            Write-Warning "Request 'Backup: TM - Trips POST/PUT' already exists. Skipping."
            return
        }

        # Pre-request script template
        $preRequestScript = @'
// Fetch the source collection to backup
const sourceCollectionId = "11896768-19dca00d-e47a-44be-8267-43ccc1242729";

pm.sendRequest({
    url: `https://api.getpostman.com/collections/${sourceCollectionId}`,
    method: 'GET',
    header: {
        'X-Api-Key': pm.environment.get("POSTMAN_API_KEY")
    }
}, function (err, response) {
    if (err) {
        console.log("Error fetching collection:", err);
        pm.variables.set("backupError", err.message);
        return;
    }
    
    const collection = response.json().collection;
    const originalName = collection.info.name;
    
    // Store original name for logging
    pm.variables.set("originalName", originalName);
    
    // Generate backup name
    const backupPrefix = pm.variables.get("backupPrefix");
    const dateStamp = pm.variables.get("dateStamp");
    const timeStamp = pm.variables.get("timeStamp");
    const backupName = backupPrefix + " " + dateStamp + timeStamp + " - " + originalName;
    
    // Modify collection for backup
    collection.info.name = backupName;
    collection.info.description = "Backup of " + originalName + " created on " + dateStamp + timeStamp;
    
    // Remove the _postman_id to create a new collection
    delete collection.info._postman_id;
    
    // Store for the actual request
    pm.variables.set("backupCollection", JSON.stringify({ collection: collection }));
    pm.variables.set("backupName", backupName);
    
    console.log("Prepared backup: " + backupName);
});
'@
        
        # Test script template
        $testScript = @'
// Test Script
console.log("\n" + "=".repeat(60));
console.log("RESPONSE: BACKUP RESULT");
console.log("=".repeat(60));

const backupName = pm.variables.get("backupName");
const originalName = pm.variables.get("originalName");

// Test: Successful backup
pm.test("Backup created successfully", function () {
    pm.response.to.have.status(200);
});

// Log results
if (pm.response.code === 200) {
    const response = pm.response.json();

    console.log("✅ SUCCESS: Backup created!");
    console.log("   Original: " + originalName);
    console.log("   Backup: " + backupName);
    console.log("   New Collection UID: " + response.collection.uid);
    console.log("   New Collection ID: " + response.collection.id);

    // Test: Backup has correct name
    pm.test("Backup has correct name", function () {
        pm.expect(response.collection.name).to.equal(backupName);
    });
}
'@
        
        # Create new request
        $newRequest = @{
            name = "Backup: TM - Trips POST/PUT"
            request = @{
                method = "POST"
                header = @(
                    @{
                        key = "X-Api-Key"
                        value = "{{POSTMAN_API_KEY}}"
                        type = "text"
                    },
                    @{
                        key = "Content-Type"
                        value = "application/json"
                        type = "text"
                    }
                )
                body = @{
                    mode = "raw"
                    raw = "{{backupCollection}}"
                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }
                url = @{
                    raw = "https://api.getpostman.com/collections"
                    protocol = "https"
                    host = @("api", "getpostman", "com")
                    path = @("collections")
                }
            }
            event = @(
                @{
                    listen = "prerequest"
                    script = @{
                        type = "text/javascript"
                        exec = @($preRequestScript -split "`n")
                    }
                },
                @{
                    listen = "test"
                    script = @{
                        type = "text/javascript"
                        exec = @($testScript -split "`n")
                    }
                }
            )
        }
        
        # Add the new request to the folder
        $backupFolder.item += $newRequest
        
        Write-Host "✓ Created new request structure" -ForegroundColor Green

        # Prepare update payload
        $updatePayload = @{
            collection = $fullCollection
        } | ConvertTo-Json -Depth 20

        Write-Host "Updating collection via API..." -ForegroundColor Yellow
        
        # Update collection
        $updateResponse = Invoke-RestMethod `
            -Uri "https://api.getpostman.com/collections/$BackupCollectionId" `
            -Method Put `
            -Headers $headers `
            -Body $updatePayload

        Write-Host "✅ SUCCESS: Collection updated!" -ForegroundColor Green
        Write-Host "  Collection: $($updateResponse.collection.info.name)" -ForegroundColor Gray
        Write-Host "  New request count in folder: $($backupFolder.item.Count)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "The backup request 'Backup: TM - Trips POST/PUT' has been added to your Backup System collection." -ForegroundColor Cyan
        
    }
    catch {
        Write-Error "Failed to add backup request: $_"
        if ($_.ErrorDetails.Message) {
            Write-Error "API Error: $($_.ErrorDetails.Message)"
        }
    }
}

