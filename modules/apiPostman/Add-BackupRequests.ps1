# Add-BackupRequests.ps1
# Adds backup requests for 6 selected collections to "Backup Test - Manual"

param(
    [string]$ApiKey = "$env:POSTMAN_API_KEY",
    [string]$CollectionName = "Backup Test - Manual"
)

Write-Host "`n" -NoNewline
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "ADD BACKUP REQUESTS TO COLLECTION" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Collections to add backup requests for
$collectionsToBackup = @(
    @{
        Name = "TM - TruckMate"
        UID = "8229908-9882ef5d-1ba8-483c-b609-1b507180f67c"
    },
    @{
        Name = "TM - Trips"
        UID = "8229908-a0080506-3774-4595-84a4-e2eeb0764ff1"
    },
    @{
        Name = "TM - Orders"
        UID = "8229908-048191f7-b6f7-44ad-8d62-4178b8944f08"
    },
    @{
        Name = "TM - Master Data"
        UID = "8229908-2c4dc1fc-b5d0-4923-b20d-501a8c2b4d68"
    },
    @{
        Name = "Finance Functional Tests"
        UID = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
    },
    @{
        Name = "Contract Tests"
        UID = "8229908-8d36f75f-8c41-41bd-8bb9-3b476d4e8ccd"
    }
)

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

try {
    # Get the backup collection
    Write-Host "Fetching '$CollectionName' collection..." -ForegroundColor Cyan
    $collections = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers).collections
    $backupCollection = $collections | Where-Object { $_.name -eq $CollectionName }
    
    if (-not $backupCollection) {
        Write-Host "✗ Collection '$CollectionName' not found!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Found collection: $($backupCollection.uid)" -ForegroundColor Green
    
    # Get full collection details
    $fullCollection = (Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" -Headers $headers).collection
    
    Write-Host "  Current items: $($fullCollection.item.Count)" -ForegroundColor Gray
    Write-Host ""
    
    # Pre-request script template
    $preRequestScript = @'
// Fetch the source collection to backup
const sourceCollectionId = "{{SOURCE_COLLECTION_ID}}";

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
    
    # Create new items array with existing collection-level scripts preserved
    $newItems = @()
    
    # Add backup request for each collection
    foreach ($coll in $collectionsToBackup) {
        Write-Host "Adding backup request for: $($coll.Name)" -ForegroundColor Yellow
        
        $preReqWithId = $preRequestScript -replace "{{SOURCE_COLLECTION_ID}}", $coll.UID
        
        $newRequest = @{
            name = "Backup: $($coll.Name)"
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
                        exec = @($preReqWithId -split "`n")
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
        
        $newItems += $newRequest
        Write-Host "  ✓ Created request" -ForegroundColor Green
    }
    
    # Update the collection with new items
    $fullCollection.item = $newItems
    
    # Prepare update payload
    $updatePayload = @{
        collection = $fullCollection
    } | ConvertTo-Json -Depth 20
    
    Write-Host ""
    Write-Host "Updating collection via API..." -ForegroundColor Cyan
    
    # Update collection
    $updateResponse = Invoke-RestMethod `
        -Uri "https://api.getpostman.com/collections/$($backupCollection.uid)" `
        -Method Put `
        -Headers $headers `
        -Body $updatePayload
    
    Write-Host "✓ Collection updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Collection: $($updateResponse.collection.name)" -ForegroundColor Gray
    Write-Host "  UID: $($updateResponse.collection.uid)" -ForegroundColor Gray
    Write-Host "  Total Backup Requests: $($newItems.Count)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Backup requests added:" -ForegroundColor Yellow
    foreach ($coll in $collectionsToBackup) {
        Write-Host "  • $($coll.Name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "NEXT STEPS" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "1. Open 'Backup Test - Manual' in Postman" -ForegroundColor White
    Write-Host "2. Run the entire collection using the 'Backup Testing' environment" -ForegroundColor White
    Write-Host "3. Verify 6 backup collections are created" -ForegroundColor White
    Write-Host "4. Check the backup names and content" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}

