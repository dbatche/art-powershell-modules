# Postman API Usage Notes

**Date**: October 9, 2025  
**Purpose**: Document learnings and best practices for Postman API interactions

---

## ⚠️ Critical: Use UID, Not ID for Request Updates

### The Issue

When updating existing requests via the Postman API, you **MUST use the full UID**, not just the ID.

### What's the Difference?

**ID** (wrong - just the request ID):
```
ec4f0669-efb1-4c23-95ec-0eb7f481e1be
```

**UID** (correct - owner + request ID):
```
8229908-ec4f0669-efb1-4c23-95ec-0eb7f481e1be
```

The UID format is: `{owner-id}-{request-id}`

**NOT**: `{collection-uid}-{request-id}` ❌

**Example**:
- Owner ID: `8229908`
- Collection UID: `8229908-779780a9-97d0-4004-9a96-37e8c64c3405`
- Request ID: `ec4f0669-efb1-4c23-95ec-0eb7f481e1be`
- **Correct Request UID**: `8229908-ec4f0669-efb1-4c23-95ec-0eb7f481e1be`
- **WRONG**: `8229908-779780a9-97d0-4004-9a96-37e8c64c3405-ec4f0669-efb1-4c23-95ec-0eb7f481e1be`

### API Endpoint

```
PUT /collections/{collection_uid}/requests/{request_uid}
```

❌ **Wrong:**
```powershell
$requestId = "ec4f0669-efb1-4c23-95ec-0eb7f481e1be"
Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestId" ...
# Result: 404 Not Found
```

✅ **Correct:**
```powershell
$requestUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405-ec4f0669-efb1-4c23-95ec-0eb7f481e1be"
Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestUid" ...
# Result: Success
```

### Error Message

If you use just the ID, you'll get:
```json
{
  "error": {
    "name": "instanceNotFoundError",
    "message": "We could not find the request you are looking for"
  }
}
```

---

## Postman API Capabilities & Limitations

### ✅ What Works

1. **Get Collection**
   ```
   GET /collections/{collection_uid}
   ```
   - Retrieves full collection structure
   - Returns all folders and requests
   - Works reliably

2. **Get Single Request**
   ```
   GET /collections/{collection_uid}/requests/{request_uid}
   ```
   - Retrieves specific request details
   - Must use full UID format
   - Works for existing requests

3. **Get Folder**
   ```
   GET /collections/{collection_uid}/folders/{folder_uid}
   ```
   - Retrieves folder details
   - Must use UID format: `{owner}-{folder_id}`
   - Returns folder properties and events

4. **Update Existing Request**
   ```
   PUT /collections/{collection_uid}/requests/{request_uid}
   ```
   - ✅ Update request name
   - ✅ Update request URL (`url` property as string)
   - ✅ Update request body (`rawModeData` property)
   - ✅ Update request headers (`headers` as string)
   - ✅ Update pre-request scripts (`preRequestScript` as string)
   - ✅ Update test scripts (`tests` as string)
   - ✅ Update description
   - **Requires UID format: `{owner}-{request_id}`**
   - **Only works on existing requests**
   - **Request body should be in `rawModeData`, not built in pre-request**

5. **Update Existing Folder**
   ```
   PUT /collections/{collection_uid}/folders/{folder_uid}
   ```
   - ✅ Update folder name
   - ✅ Update folder description
   - ✅ Update folder events (pre-request, test scripts)
   - **Requires UID format: `{owner}-{folder_id}`**
   - **Events array format: see example below**

4. **Update Entire Collection**
   ```
   PUT /collections/{collection_uid}
   ```
   - Can add new folders/requests
   - Replaces entire collection
   - Complex and error-prone for large collections
   - PowerShell JSON depth limits (20 levels)
   - Not recommended for incremental changes

### ❌ What Doesn't Work

1. **Create Individual Request**
   ```
   POST /collections/{collection_uid}/requests
   ```
   - ❌ Not supported by Postman API
   - No endpoint exists for this operation

2. **Create Individual Folder**
   ```
   POST /collections/{collection_uid}/folders
   ```
   - ❌ Not supported by Postman API
   - No endpoint exists for this operation

3. **Update Newly Created Requests**
   ```
   PUT /collections/{collection_uid}/requests/{new_request_uid}
   ```
   - ❌ Returns 404 even with correct UID
   - New requests not immediately API-accessible
   - Possible sync delay (untested)

---

## Best Practices

### For Updating Existing Requests

1. **Always fetch the full collection first**
   ```powershell
   $collection = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers @{"X-Api-Key" = $apiKey}
   ```

2. **Extract the full UID (not just ID)**
   ```powershell
   # Collection structure has 'id' property on items
   $requestId = $item.id
   
   # Build full UID
   $requestUid = "$collectionUid-$requestId"
   ```

3. **Use full UID in API calls**
   ```powershell
   Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestUid" -Method Put ...
   ```

### For Creating New Requests

**Recommended Approach**: Manual creation in Postman UI
1. Create folder structure manually
2. Create blank request manually
3. Wait for Postman to sync (if using API updates later)
4. Update via API if needed

**Alternative**: Generate specifications
1. Use scripts to generate request specs (URL, body, scripts)
2. Provide specs to user for manual creation
3. Much faster than JSON import/export

**Not Recommended**: Full collection update
- Too complex for large collections
- PowerShell JSON serialization limits
- High error rate
- Only use for small collections

---

## Example: Bulk Request Name Updates

This pattern **works** (used successfully):

```powershell
# 1. Fetch collection
$collection = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers @{"X-Api-Key" = $apiKey}

# 2. Find requests to update
$updates = @(
    @{ Id = "request-id-1"; NewName = "Updated Name 1" },
    @{ Id = "request-id-2"; NewName = "Updated Name 2" }
)

# 3. Update each request
foreach ($update in $updates) {
    $requestUid = "$collectionUid-$($update.Id)"
    
    # Fetch current request
    $request = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestUid" -Headers @{"X-Api-Key" = $apiKey}
    
    # Modify name
    $request.data.name = $update.NewName
    
    # Update via API
    $body = $request.data | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestUid" -Headers @{"X-Api-Key" = $apiKey; "Content-Type" = "application/json"} -Method Put -Body $body
}
```

---

## Common Errors

### Error 1: 404 Not Found (Wrong ID Format)

**Symptom**:
```json
{
  "error": {
    "name": "instanceNotFoundError",
    "message": "We could not find the request you are looking for"
  }
}
```

**Cause**: Using request ID instead of full UID

**Fix**: Use `{collection_uid}-{request_id}` format

### Error 2: 400 Bad Request (Malformed Collection)

**Symptom**:
```json
{
  "error": {
    "name": "malformedRequestError",
    "message": "Found X errors with the supplied collection"
  }
}
```

**Cause**: Collection JSON structure invalid (usually from full collection update)

**Fix**: 
- Check JSON depth (PowerShell default is 2, use `-Depth 20`)
- Validate collection structure matches Postman schema
- Use incremental request updates instead

### Error 3: JSON Depth Truncation

**Symptom**:
```
WARNING: Resulting JSON is truncated as serialization has exceeded the set depth
```

**Cause**: PowerShell `ConvertTo-Json` default depth is 2

**Fix**: Always use `-Depth 10` or higher
```powershell
$json = $object | ConvertTo-Json -Depth 10
```

---

## Scripts Using These Patterns

### Update-PostmanRequestName.ps1
**Location**: `scaffolding/scripts/`  
**Uses**: Full UID format for bulk request name updates  
**Status**: ✅ Working

**Example**:
```powershell
.\Update-PostmanRequestName.ps1 `
    -ApiKey "PMAK-..." `
    -CollectionUid "8229908-779780a9-..." `
    -BulkUpdates @(
        @{ Uid = "8229908-xxx-yyy"; NewName = "New Name" }
    )
```

### Get-PostmanCollectionStructure.ps1
**Location**: `scaffolding/scripts/`  
**Uses**: Collection GET to analyze structure  
**Status**: ✅ Working

**Example**:
```powershell
.\Get-PostmanCollectionStructure.ps1 `
    -ApiKey "PMAK-..." `
    -CollectionUid "8229908-779780a9-..." `
    -Format JSON
```

---

## Postman API Documentation

**Official Docs**: https://www.postman.com/postman/workspace/postman-public-workspace/documentation/12959542-c8142d51-e97c-46b6-bd77-52bb66712c9a

**Key Endpoints**:
- GET `/collections/{uid}` - Get full collection
- GET `/collections/{collection_uid}/requests/{request_uid}` - Get request
- PUT `/collections/{collection_uid}/requests/{request_uid}` - Update request
- PUT `/collections/{uid}` - Update entire collection

**Authentication**: API Key via `X-Api-Key` header

---

## Future Enhancements

### Potential Improvements

1. **Retry Logic**: Add retry with exponential backoff for newly created requests
2. **Sync Detection**: Detect when new requests become API-accessible
3. **Validation**: Pre-validate UID format before API calls
4. **Error Handling**: Better error messages for common issues

### Workarounds Explored

1. ✅ **Request specifications** - Generate specs for manual creation (fast, reliable)
2. ❌ **Full collection update** - Too error-prone for large collections
3. ⏸️ **Sync delay retry** - Not yet tested

---

## Request Body Best Practices

### ❌ WRONG: Building body in pre-request

```javascript
// Pre-request Script
const requestBody = [{
    field1: "value",
    field2: 123
}];
pm.request.body.raw = JSON.stringify(requestBody);
```

**Problem**: Body should be static in the request, not dynamically built

### ✅ CORRECT: Body in request, variables in pre-request

**Request Body** (`rawModeData` property):
```json
[
  {
    "field1": "{{variable1}}",
    "field2": 123
  }
]
```

**Pre-request Script** (`preRequestScript` property):
```javascript
// Set variables only
const parentId = pm.globals.get('PARENT_ID') || 2;
pm.variables.set('parentId', parentId);
```

---

## Folder Events Format

Folders use an `events` array (not individual script properties):

```powershell
$folder.data.events = @(
    @{
        listen = "test"
        script = @{
            type = "text/javascript"
            exec = @(
                "if (utils.testStatusCode(201).status) {",
                "    utils.validateJsonSchemaIfCode(201);",
                "    // More validation...",
                "}"
            )
        }
    }
)
```

**Note**: Each line in `exec` is a separate array element

---

## Variable Naming Conventions

**Check collection-level scripts** for existing variable names:

- Finance collection uses: `FUEL_TAX_ID` (not `fuelTaxId`)
- Always use `pm.globals.get('VARIABLE_NAME')` first
- Fallback to environment: `pm.environment.get('VARIABLE_NAME')`
- Use local variables sparingly

---

## Pre-Request Script Best Practices

### Use Variables Directly When Possible

**❌ UNNECESSARY: Pre-request for simple variable**
```javascript
// Pre-request
const fuelTaxId = pm.environment.get('FUEL_TAX_ID') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);
```
**URL**: `{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases`

**✅ BETTER: Use environment variable directly**

**Pre-request**: None (empty)

**URL**: `{{DOMAIN}}/fuelTaxes/{{FUEL_TAX_ID}}/tripFuelPurchases`

### When to Use Pre-Request Scripts

**Use pre-request ONLY when you need to:**
- Calculate/transform values (dates, random data, etc.)
- Make API calls to get dependent IDs
- Complex conditional logic
- Generate test data dynamically

**Don't use pre-request for:**
- Simple variable passthrough
- Variables that already exist in environment/globals
- Static values that can go in URL/body directly

**Postman automatically resolves** `{{VARIABLE_NAME}}` from:
1. Local variables (set in pre-request)
2. Environment variables
3. Global variables
4. Collection variables

---

## Postman CLI Usage

### Running Collections/Requests

**Basic Syntax**:
```bash
postman collection run <collection_uid> -e <environment_uid> -i <uid>
```

**Key Learnings**:
1. **Always use `-i` for both folders and requests** (not `--folder` or `--request`)
2. **UIDs for `-i` parameter**:
   - Both formats work: `owner-id` or just `id`
   - **Recommended**: Use `owner-id` format for consistency with API
   - Folder UID: `8229908-b1548ae9-6d91-4688-baa5-e67a41a1d65f`
   - Request UID: `8229908-ec4f0669-efb1-4c23-95ec-0eb7f481e1be`
   - CLI accepts both, but owner-prefix maintains consistency

### Output Formats

**CLI Format** (default, recommended for quick checks):
```bash
postman collection run <collection_uid> -e <environment_uid> -i <request_uid>
```
- **Pros**: Immediate output to stdout, no file I/O, can stream/pipe
- **Cons**: Text parsing (regex), not structured
- **Best for**: Quick verification, real-time monitoring, AI/automation

**JSON Format** (recommended for reporting):
```bash
postman collection run <collection_uid> -e <environment_uid> -i <request_uid> -r json
```
- **Pros**: Structured data, comprehensive details, easy property access
- **Cons**: Saves to file (not stdout), requires file read, ~30% slower
- **Best for**: Detailed reporting, historical analysis, complex data extraction
- **Output location**: `postman-cli-reports/Collection-Name-YYYY-MM-DD-HH-MM-SS.json`

### When to Use Each Format

| Use Case | Format | Why |
|----------|--------|-----|
| Quick test verification | CLI | Immediate, no file management |
| CI/CD pass/fail checks | CLI | Pipe to logs, exit codes |
| Detailed test reports | JSON | Full execution details |
| Historical tracking | JSON | Persistent files for analysis |
| AI/scripting quick checks | CLI | Faster, easier to grep/filter |
| Complex data extraction | JSON | Structured property access |

### Examples

**Run a specific request**:
```powershell
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
$envUid = "11896768-68887950-1feb-4817-87c5-f5dcffa370cb"
$requestUid = "8229908-ec4f0669-efb1-4c23-95ec-0eb7f481e1be"  # owner-id format

# CLI format (quick check)
postman collection run $collectionUid -e $envUid -i $requestUid

# JSON format (detailed report)
postman collection run $collectionUid -e $envUid -i $requestUid -r json
```

**Run a folder**:
```powershell
$folderUid = "8229908-b1548ae9-6d91-4688-baa5-e67a41a1d65f"  # owner-id format

# Same -i parameter for folders!
postman collection run $collectionUid -e $envUid -i $folderUid
```

### Parsing CLI Output in PowerShell

```powershell
# Quick status check
$output = postman collection run $collectionUid -e $envUid -i $requestUid 2>&1 | Out-String
if ($output -match "POST.*\[(\d+) (\w+)") {
    Write-Host "Status: $($matches[1]) $($matches[2])"
}

# Extract pass/fail counts
postman collection run $collectionUid -e $envUid -i $requestUid 2>&1 | 
    Select-String -Pattern "passed.*failed" | 
    ForEach-Object { $_.Line }
```

### Parsing JSON Output in PowerShell

```powershell
# Run with JSON output (saves to file)
postman collection run $collectionUid -e $envUid -i $requestUid -r json 2>$null | Out-Null

# Read the latest report
$reportFile = Get-ChildItem "postman-cli-reports" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1
$result = Get-Content $reportFile.FullName | ConvertFrom-Json

# Access results
$result.run.stats                    # Statistics (requests, assertions)
$result.run.executions[0]            # First request execution details
$result.run.executions[0].response   # Response details (code, status, time)
$result.run.failures                 # Failed assertions
```

---

**Last Updated**: October 9, 2025  
**Author**: Doug Batchelor + AI Assistant  
**Status**: Living document - will update as we learn more

