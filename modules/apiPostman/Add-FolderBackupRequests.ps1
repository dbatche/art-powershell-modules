# Add-FolderBackupRequests.ps1
# Adds 19 folder-level backup requests for TM - Master Data collection

param(
    [string]$ApiKey = "$env:POSTMAN_API_KEY",
    [string]$CollectionName = "Backup Test - Manual",
    [string]$SourceCollectionId = "8229908-2c4dc1fc-b5d0-4923-b20d-501a8c2b4d68"
)

Write-Host "`n" -NoNewline
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "ADD FOLDER-LEVEL BACKUP REQUESTS" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

$headers = @{
    "X-Api-Key" = $ApiKey
    "Content-Type" = "application/json"
}

try {
    # Get folder names from source collection
    Write-Host "Fetching TM - Master Data folder structure..." -ForegroundColor Cyan
    $sourceResponse = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$SourceCollectionId" -Headers $headers
    $sourceCollection = $sourceResponse.collection
    
    $folders = $sourceCollection.item | Where-Object { $_.item } | Select-Object -Property name
    Write-Host "✓ Found $($folders.Count) folders" -ForegroundColor Green
    
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
    
    # Pre-request script template for folder extraction
    $preRequestScript = @'
// Fetch the source collection and extract specific folder
const sourceCollectionId = "{{SOURCE_COLLECTION_ID}}";
const folderName = "{{FOLDER_NAME}}";

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
    
    const fullCollection = response.json().collection;
    const originalName = fullCollection.info.name;
    
    // Find the specific folder
    const folder = fullCollection.item.find(item => item.name === folderName);
    
    if (!folder) {
        console.log("Error: Folder '" + folderName + "' not found in collection");
        pm.variables.set("backupError", "Folder not found");
        return;
    }
    
    console.log("Found folder: " + folderName + " with " + (folder.item ? folder.item.length : 0) + " items");
    
    // Store original name for logging
    pm.variables.set("originalName", originalName + " - " + folderName);
    
    // Generate backup name
    const backupPrefix = pm.variables.get("backupPrefix");
    const dateStamp = pm.variables.get("dateStamp");
    const timeStamp = pm.variables.get("timeStamp");
    const backupName = backupPrefix + " " + dateStamp + timeStamp + " - " + originalName + " - " + folderName;
    
    // Create new collection with just this folder
    const newCollection = {
        info: {
            name: backupName,
            description: "Backup of folder '" + folderName + "' from " + originalName + " created on " + dateStamp + timeStamp,
            schema: fullCollection.info.schema
        },
        item: [folder]
    };
    
    // Copy collection-level variables if they exist
    if (fullCollection.variable) {
        newCollection.variable = fullCollection.variable;
    }
    
    // Copy collection-level auth if it exists
    if (fullCollection.auth) {
        newCollection.auth = fullCollection.auth;
    }
    
    // Store for the actual request
    pm.variables.set("backupCollection", JSON.stringify({ collection: newCollection }));
    pm.variables.set("backupName", backupName);
    
    console.log("Prepared backup: " + backupName);
});
'@
    
    # Test script template
    $testScript = @'
// Test Script
console.log("\n" + "=".repeat(60));
console.log("RESPONSE: FOLDER BACKUP RESULT");
console.log("=".repeat(60));

const backupName = pm.variables.get("backupName");
const originalName = pm.variables.get("originalName");
const backupError = pm.variables.get("backupError");

if (backupError) {
    console.log("✗ ERROR: " + backupError);
    pm.test("Folder backup failed", function() {
        pm.expect.fail("Backup error: " + backupError);
    });
    return;
}

// Test: Successful backup
pm.test("Folder backup created successfully", function () {
    pm.response.to.have.status(200);
});

// Log results
if (pm.response.code === 200) {
    const response = pm.response.json();

    console.log("✅ SUCCESS: Folder backup created!");
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
    
    # Keep existing items and add new folder backup requests
    $existingItems = $fullCollection.item
    $newItems = @()
    
    # Add folder backup request for each folder
    $folderCount = 0
    foreach ($folder in $folders) {
        $folderCount++
        Write-Host "[$folderCount/$($folders.Count)] Adding backup request for folder: $($folder.name)" -ForegroundColor Yellow
        
        $preReqWithDetails = $preRequestScript `
            -replace "{{SOURCE_COLLECTION_ID}}", $SourceCollectionId `
            -replace "{{FOLDER_NAME}}", $folder.name
        
        $newRequest = @{
            name = "Backup Folder: $($folder.name)"
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
                        exec = @($preReqWithDetails -split "`n")
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
    
    # Combine existing items with new folder backup items
    $allItems = $existingItems + $newItems
    $fullCollection.item = $allItems
    
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
    Write-Host "  Existing Requests: $($existingItems.Count)" -ForegroundColor Gray
    Write-Host "  New Folder Backup Requests: $($newItems.Count)" -ForegroundColor Gray
    Write-Host "  Total Requests: $($allItems.Count)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Folder backup requests added for:" -ForegroundColor Yellow
    foreach ($folder in $folders) {
        Write-Host "  • $($folder.name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "NEXT STEPS" -ForegroundColor Yellow
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "1. Open 'Backup Test - Manual' in Postman" -ForegroundColor White
    Write-Host "2. Run the folder backup requests (last 19 requests)" -ForegroundColor White
    Write-Host "3. Verify 19 folder backup collections are created" -ForegroundColor White
    Write-Host "4. Each backup will be named: 'Manual Backup YYYY-MM-DD - TM Master Data - [FolderName]'" -ForegroundColor White
    Write-Host ""
    Write-Host "Optional: To recombine folders later, use the Recombine-FolderBackups.ps1 script" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    exit 1
}

