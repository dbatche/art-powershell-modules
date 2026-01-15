# Phase 1 Quick Start: Testing Collection Backup

**Goal**: Test the collection copy functionality in your personal workspace before building the full system.

---

## Step 1: Create Test Environment

In Postman:
1. Go to **Environments** tab
2. Click **Create Environment**
3. Name it: `Backup Testing`
4. Add variables:

| Variable | Type | Initial Value | Current Value |
|----------|------|---------------|---------------|
| `POSTMAN_API_KEY` | secret | `YOUR_API_KEY_HERE` | `YOUR_API_KEY_HERE` |
| `TEST_COLLECTION_ID` | default | `8229908-779780a9-97d0-4004-9a96-37e8c64c3405` | (same) |
| `MANUAL_BACKUP` | default | `true` | `true` |

5. Save environment

**Get your API key**: 
- Go to Postman settings → Integrations → Generate API Key
- Or use the key from your environment: Run `Setup-EnvironmentVariables` to set `$env:POSTMAN_API_KEY`

---

## Step 2: Create Test Collection

1. Click **New** → **Collection**
2. Name: `Backup Test - Manual`
3. Description: `Testing collection backup functionality`

---

## Step 3: Add Collection-Level Pre-Request Script

In the collection settings → **Pre-request Scripts** tab:

```javascript
// Collection-level setup
console.log("=".repeat(60));
console.log("COLLECTION BACKUP - PRE-REQUEST SETUP");
console.log("=".repeat(60));

// Determine backup type
const isManual = pm.environment.get("MANUAL_BACKUP") === "true";
const backupPrefix = isManual ? "Manual Backup" : "Auto Backup";

// Generate timestamps
const now = new Date();
const dateStamp = now.toISOString().slice(0, 10); // YYYY-MM-DD

let timeStamp = "";
if (isManual) {
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    timeStamp = ` ${hours}-${minutes}`;
}

// Store in collection variables
pm.collectionVariables.set("backupPrefix", backupPrefix);
pm.collectionVariables.set("dateStamp", dateStamp);
pm.collectionVariables.set("timeStamp", timeStamp);

console.log(`Backup Type: ${backupPrefix}`);
console.log(`Date Stamp: ${dateStamp}`);
console.log(`Time Stamp: ${timeStamp}`);
console.log("=".repeat(60));
```

---

## Step 4: Create Backup Request

1. In your test collection, add a new request
2. Name: `Test: Copy Collection`
3. Configure request:

### Request Settings

**Method**: `POST`

**URL**: 
```
https://api.getpostman.com/collections
```

**Headers**:
```
X-Api-Key: {{POSTMAN_API_KEY}}
Content-Type: application/json
```

### Pre-Request Script

```javascript
console.log("\n" + "=".repeat(60));
console.log("REQUEST: BACKUP COLLECTION");
console.log("=".repeat(60));

// Get collection ID to backup
const sourceCollectionId = pm.environment.get("TEST_COLLECTION_ID");
console.log(`Source Collection ID: ${sourceCollectionId}`);

// Fetch the source collection
pm.sendRequest({
    url: `https://api.getpostman.com/collections/${sourceCollectionId}`,
    method: 'GET',
    header: {
        'X-Api-Key': pm.environment.get("POSTMAN_API_KEY")
    }
}, function (err, response) {
    if (err) {
        console.error("❌ Error fetching collection:", err);
        pm.variables.set("backupError", err.message);
        return;
    }
    
    if (response.code !== 200) {
        console.error("❌ Failed to fetch collection:", response.code, response.status);
        console.error("Response:", response.text());
        pm.variables.set("backupError", response.text());
        return;
    }
    
    console.log("✓ Successfully fetched source collection");
    
    const collection = response.json().collection;
    const originalName = collection.info.name;
    console.log(`Original Name: ${originalName}`);
    
    // Generate backup name
    const backupPrefix = pm.collectionVariables.get("backupPrefix");
    const dateStamp = pm.collectionVariables.get("dateStamp");
    const timeStamp = pm.collectionVariables.get("timeStamp");
    const backupName = `${backupPrefix} ${dateStamp}${timeStamp} - ${originalName}`;
    
    console.log(`Backup Name: ${backupName}`);
    
    // Modify collection for backup
    collection.info.name = backupName;
    collection.info.description = `Backup of "${originalName}" created on ${dateStamp}${timeStamp}\n\nOriginal Collection ID: ${sourceCollectionId}`;
    
    // Remove the _postman_id so a new collection is created
    delete collection.info._postman_id;
    
    // Store for the actual request body
    const backupPayload = { collection: collection };
    pm.variables.set("backupCollection", JSON.stringify(backupPayload));
    pm.variables.set("backupName", backupName);
    pm.variables.set("originalName", originalName);
    
    console.log("✓ Backup payload prepared");
    console.log("=".repeat(60) + "\n");
});
```

### Request Body

Select **raw** and **JSON** format, then paste:
```
{{backupCollection}}
```

### Tests Script

```javascript
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
    
    console.log(`✅ SUCCESS: Backup created!`);
    console.log(`   Original: ${originalName}`);
    console.log(`   Backup: ${backupName}`);
    console.log(`   New Collection UID: ${response.collection.uid}`);
    console.log(`   New Collection ID: ${response.collection.id}`);
    
    // Additional validation
    pm.test("Backup has correct name", function () {
        pm.expect(response.collection.info.name).to.equal(backupName);
    });
    
    pm.test("Backup has description", function () {
        pm.expect(response.collection.info.description).to.include("Backup of");
    });
    
} else {
    console.error(`❌ FAILED: Could not create backup`);
    console.error(`   Status: ${pm.response.code} ${pm.response.status}`);
    console.error(`   Response: ${pm.response.text()}`);
}

console.log("=".repeat(60) + "\n");

// Clean up temporary variables
pm.variables.unset("backupCollection");
pm.variables.unset("backupName");
pm.variables.unset("originalName");
pm.variables.unset("backupError");
```

---

## Step 5: Run the Test

1. Select the `Backup Testing` environment
2. Click **Send** on your test request
3. Check the **Console** (View → Show Postman Console)

### Expected Console Output:

```
============================================================
COLLECTION BACKUP - PRE-REQUEST SETUP
============================================================
Backup Type: Manual Backup
Date Stamp: 2025-10-04
Time Stamp:  14-30
============================================================

============================================================
REQUEST: BACKUP COLLECTION
============================================================
Source Collection ID: 8229908-779780a9-97d0-4004-9a96-37e8c64c3405
✓ Successfully fetched source collection
Original Name: Finance Functional Tests
Backup Name: Manual Backup 2025-10-04 14-30 - Finance Functional Tests
✓ Backup payload prepared
============================================================

============================================================
RESPONSE: BACKUP RESULT
============================================================
✅ SUCCESS: Backup created!
   Original: Finance Functional Tests
   Backup: Manual Backup 2025-10-04 14-30 - Finance Functional Tests
   New Collection UID: 8229908-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   New Collection ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
============================================================
```

---

## Step 6: Verify the Backup

1. Go to **Collections** tab in Postman
2. Look for collection named: `Manual Backup 2025-10-04 [time] - Finance Functional Tests`
3. Open it and verify:
   - ✅ All folders are present
   - ✅ All requests are present
   - ✅ Description mentions it's a backup
   - ✅ Content matches original

---

## Step 7: Test Auto Backup Mode

1. Go to `Backup Testing` environment
2. Change `MANUAL_BACKUP` to `false`
3. Run the request again
4. Expected backup name: `Auto Backup 2025-10-04 - Finance Functional Tests` (no time)

---

## Step 8: Test with Different Collections

1. Get another collection ID from your workspace
2. Update `TEST_COLLECTION_ID` in environment
3. Run request
4. Verify backup created

---

## Troubleshooting

### Error: "We could not find the collection you are looking for"
**Cause**: Collection ID might need owner prefix  
**Solution**: Use full UID format: `8229908-779780a9-97d0-4004-9a96-37e8c64c3405`

### Error: "Unauthorized"
**Cause**: Invalid API key  
**Solution**: 
- Verify API key in environment
- Generate new key if needed
- Check key has proper permissions

### Error: Nothing happens, no backup created
**Cause**: Pre-request script might have failed silently  
**Solution**: 
- Open Postman Console (Ctrl+Alt+C or View → Show Postman Console)
- Look for error messages
- Check if `{{backupCollection}}` variable is set

### Backup created but empty
**Cause**: Collection fetch might have failed  
**Solution**: 
- Check console for fetch errors
- Verify source collection ID is correct
- Ensure API key has read access to source collection

---

## Success Criteria

✅ **Phase 1 Complete When:**
- [ ] Backup collection created successfully
- [ ] Backup name follows format: `[Type] Backup YYYY-MM-DD [HH-MM] - [Original Name]`
- [ ] Backup contains all folders and requests from original
- [ ] Both auto and manual modes tested
- [ ] Console logging is clear and helpful
- [ ] No errors in test results

---

## Next Steps

Once Phase 1 testing is successful:

1. **Document findings** in implementation tracker
2. **Create backup workspace** (Phase 2)
3. **Build production collection** with multiple backup requests (Phase 3)
4. **Set up monitor** for daily automation (Phase 4)

See `Postman-Backup-Implementation.md` for detailed next steps.

---

## Quick Commands Reference

### Get Your API Key
```powershell
# Use environment variable (recommended)
Setup-EnvironmentVariables
$env:POSTMAN_API_KEY
```

### Get Collection IDs from PowerShell
```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{"X-Api-Key" = $apiKey}
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers
$response.collections | Select-Object uid, name, owner | Format-Table
```

### Get Your User ID
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/me" -Headers $headers
$response.user.id  # This is your owner ID
```

---

**Ready to start?** Follow steps 1-7 above to complete Phase 1 testing! 🚀

