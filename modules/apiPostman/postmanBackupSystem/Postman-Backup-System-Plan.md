# Postman Collection Backup System - Project Plan

## Project Overview

**Goal**: Create a self-contained backup system within Postman that automatically backs up critical collections daily.

**Key Principle**: Entirely hosted within Postman - no external systems or scripts required.

---

## System Architecture

### Components

1. **Backup Workspace**
   - Dedicated workspace named "Collection Backups"
   - Stores all backup collections
   - Organized by date or collection name

2. **Backup Collection**
   - Named: "Collection Backup Automation"
   - Contains one request per collection to be backed up
   - Uses Postman API to copy collections
   - Runs daily via Postman Monitor

3. **Monitor**
   - Scheduled to run daily (e.g., 2:00 AM)
   - Executes the backup collection
   - Sends notifications on failure

---

## Backup Naming Convention

### Automated Backups (Daily)
```
Auto Backup YYYY-MM-DD - [Collection Name]
```
**Example**: `Auto Backup 2025-10-04 - Finance Functional Tests`

### Manual Backups
```
Manual Backup YYYY-MM-DD HH-MM - [Collection Name]
```
**Example**: `Manual Backup 2025-10-04 14-30 - Finance Functional Tests`

### Benefits
- ✅ Chronologically sortable
- ✅ Clearly identifies backup type
- ✅ Preserves original collection name
- ✅ No name conflicts

---

## Technical Design

### Request Structure (Per Collection)

Each backup request will:
1. **Identify** the source collection (by ID)
2. **Fetch** the collection via Postman API
3. **Modify** the collection name and metadata
4. **Create** a new collection in the backup workspace
5. **Log** the result

### Pre-Request Script (Collection Level)
```javascript
// Set up API key (stored in environment)
pm.environment.set("postmanApiKey", pm.environment.get("POSTMAN_API_KEY"));

// Determine backup type (auto vs manual)
const isManual = pm.environment.get("MANUAL_BACKUP") === "true";
const backupPrefix = isManual ? "Manual Backup" : "Auto Backup";

// Generate timestamp
const now = new Date();
const dateStamp = now.toISOString().slice(0, 10); // YYYY-MM-DD
const timeStamp = isManual ? " " + now.toTimeString().slice(0, 5).replace(":", "-") : "";

pm.collectionVariables.set("backupPrefix", backupPrefix);
pm.collectionVariables.set("dateStamp", dateStamp);
pm.collectionVariables.set("timeStamp", timeStamp);
```

### Individual Request Structure

**Request Name**: `Backup: Finance Functional Tests`

**Method**: POST  
**URL**: `https://api.getpostman.com/collections`

**Headers**:
```
X-Api-Key: {{postmanApiKey}}
Content-Type: application/json
```

**Pre-Request Script** (per request):
```javascript
// Collection to backup (specific to each request)
const sourceCollectionId = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405";

// Fetch the source collection
pm.sendRequest({
    url: `https://api.getpostman.com/collections/${sourceCollectionId}`,
    method: 'GET',
    header: {
        'X-Api-Key': pm.environment.get("postmanApiKey")
    }
}, function (err, response) {
    if (err) {
        console.log("Error fetching collection:", err);
        pm.variables.set("backupError", err.message);
        return;
    }
    
    const collection = response.json().collection;
    const originalName = collection.info.name;
    
    // Generate backup name
    const backupPrefix = pm.collectionVariables.get("backupPrefix");
    const dateStamp = pm.collectionVariables.get("dateStamp");
    const timeStamp = pm.collectionVariables.get("timeStamp");
    const backupName = `${backupPrefix} ${dateStamp}${timeStamp} - ${originalName}`;
    
    // Modify collection for backup
    collection.info.name = backupName;
    collection.info.description = `Backup of "${originalName}" created on ${dateStamp}${timeStamp}`;
    
    // Remove the _postman_id to create a new collection
    delete collection.info._postman_id;
    
    // Store for the actual request
    pm.variables.set("backupCollection", JSON.stringify({ collection: collection }));
    pm.variables.set("backupName", backupName);
    
    console.log(`Prepared backup: ${backupName}`);
});
```

**Body** (raw JSON):
```
{{backupCollection}}
```

**Tests**:
```javascript
// Verify backup was created
pm.test("Backup created successfully", function () {
    pm.response.to.have.status(200);
});

const backupName = pm.variables.get("backupName");
if (pm.response.code === 200) {
    const response = pm.response.json();
    console.log(`✓ Successfully backed up: ${backupName}`);
    console.log(`  New Collection ID: ${response.collection.uid}`);
} else {
    console.log(`✗ Failed to backup: ${backupName}`);
    console.log(`  Error: ${pm.response.text()}`);
}
```

---

## Environment Variables Required

### Backup Environment
Create an environment named "Backup Automation" with:

```json
{
  "POSTMAN_API_KEY": "YOUR_POSTMAN_API_KEY",
  "BACKUP_WORKSPACE_ID": "workspace-id-here",
  "MANUAL_BACKUP": "false"
}
```

**Variable Descriptions**:
- `POSTMAN_API_KEY` - Your Postman API key for authentication
- `BACKUP_WORKSPACE_ID` - ID of the workspace where backups are stored
- `MANUAL_BACKUP` - Set to "true" for manual runs, "false" for automated

---

## Collections to Backup (Initial List)

Based on your current setup:

1. **Finance Functional Tests**
   - ID: `8229908-779780a9-97d0-4004-9a96-37e8c64c3405`
   - Priority: High
   - Frequency: Daily

2. *[Add more collections as needed]*

---

## Monitor Configuration

### Schedule
- **Frequency**: Daily
- **Time**: 2:00 AM (low usage period)
- **Timezone**: Your local timezone

### Monitor Settings
- **Name**: "Collection Backup - Daily"
- **Collection**: "Collection Backup Automation"
- **Environment**: "Backup Automation"
- **Region**: Select closest region
- **Email notifications**: On failure

---

## Backup Retention Policy

### Recommended Strategy
Keep backups for a rolling window:
- **Daily backups**: Last 7 days
- **Weekly backups**: Last 4 weeks (keep Sunday backups)
- **Monthly backups**: Last 12 months (keep 1st of month)

### Implementation
Create separate requests or collection:
- "Cleanup Old Backups" collection
- Runs weekly via separate monitor
- Uses Postman API to:
  1. List all collections in backup workspace
  2. Parse backup names for dates
  3. Delete backups outside retention window

---

## Manual Backup Workflow

### Trigger Manual Backup
1. Open "Collection Backup Automation" collection
2. Go to collection variables or environment
3. Set `MANUAL_BACKUP` to `true`
4. Run collection manually or specific request
5. Reset `MANUAL_BACKUP` to `false` after completion

### Alternative: Separate Manual Backup Collection
Create duplicate collection:
- Name: "Collection Backup - Manual"
- Same structure but `MANUAL_BACKUP` hardcoded to `true`
- No monitor attached
- Run on-demand only

---

## Error Handling & Logging

### Logging Strategy
Use console logging throughout:
```javascript
console.log(`[INFO] Starting backup for: ${collectionName}`);
console.log(`[SUCCESS] Backup created: ${backupName}`);
console.log(`[ERROR] Failed to fetch collection: ${errorMessage}`);
```

### Error Scenarios
1. **Source collection not found**
   - Log error, continue to next backup
   - Send notification

2. **API rate limit hit**
   - Delay between requests (use `setTimeout` if needed)
   - Retry logic in tests

3. **Backup workspace full**
   - Monitor should alert
   - Trigger cleanup process

4. **Network/API failures**
   - Monitor will flag as failed run
   - Email notification sent

---

## Advantages of This Approach

✅ **No External Dependencies**
- Everything runs within Postman
- No servers, scripts, or infrastructure to maintain

✅ **Automated & Reliable**
- Monitors ensure daily execution
- Email alerts on failures

✅ **Versioned Backups**
- Date-stamped names
- Easy to track history
- Compare versions over time

✅ **Flexible**
- Add/remove collections easily
- Adjust schedule as needed
- Manual backups on-demand

✅ **Secure**
- Uses Postman's API authentication
- Workspace permissions control access
- API keys stored in environments

---

## Potential Limitations & Considerations

### Size Limits
⚠️ **Issue**: Large collections may hit API size limits  
**Solution**: Test with your largest collection first; may need to split very large collections

### Rate Limits
⚠️ **Issue**: Multiple backups in quick succession could hit rate limits  
**Solution**: Add delays between requests using `setTimeout` in pre-request scripts

### Collection Dependencies
⚠️ **Issue**: Collections reference environments, which aren't backed up  
**Solution**: Consider separate environment backup system or include environment backup requests

### Workspace Clutter
⚠️ **Issue**: Backup workspace could fill with hundreds of collections  
**Solution**: Implement retention/cleanup policy early

### Restoration Process
⚠️ **Issue**: No automated restore mechanism  
**Solution**: Manual restore by copying backup collection back to source workspace (document this process)

---

## Phase 2: Environment Backups

### Strategy Overview
Environment backups are stored **within the backup collection itself** to keep everything self-contained and avoid polluting the backup workspace with numerous environment objects.

### Implementation Approach

After backing up a collection, the system will:
1. Query all environments from the source workspace
2. Add a folder to the backup collection: **"📦 Environment Backups"**
3. Create one **disabled** POST request per environment in that folder
4. Store the full environment JSON in the request body

### Request Structure

**Folder Name**: `📦 Environment Backups`

**Request Name** (per environment): `Restore: {environment-name}`

**Method**: POST  
**URL**: `https://api.getpostman.com/environments`  
**Status**: Disabled (prevents accidental execution during collection runs)

**Headers**:
```
X-Api-Key: {{POSTMAN_API_KEY}}
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
  "environment": {
    "name": "TDE-SQL03",
    "values": [
      {
        "key": "baseUrl",
        "value": "https://api.example.com",
        "enabled": true,
        "type": "default"
      },
      {
        "key": "apiKey",
        "value": "{{SECURE_KEY}}",
        "enabled": true,
        "type": "secret"
      }
    ]
  }
}
```

**Request Description**:
```
Environment backup created on: 2025-10-04.14-30-45
Source Workspace: Finance Development
Original Environment ID: 11896768-68887950-1feb-4817-87c5-f5dcffa370cb

To restore:
1. Enable this request
2. Update the name if needed (avoid conflicts)
3. Run the request
4. Disable again after restoration
```

### Why This Approach Works

✅ **Self-Contained**: Everything in one collection backup  
✅ **Visible**: Environment variables visible without execution  
✅ **Restorable**: Enable request and run to restore environment  
✅ **Clean**: No workspace pollution with environment copies  
✅ **Organized**: All environments grouped in one folder  
✅ **Documented**: Request description explains restore process  
✅ **Safe**: Disabled by default prevents accidental execution

### Technical Implementation

**Pre-Request Script Addition** (for backup requests):
```javascript
// After backing up the collection, fetch and add environments

// Get workspace environments
pm.sendRequest({
    url: 'https://api.getpostman.com/environments',
    method: 'GET',
    header: {
        'X-Api-Key': pm.environment.get("POSTMAN_API_KEY")
    }
}, function (err, response) {
    if (err) {
        console.log("Error fetching environments:", err);
        return;
    }
    
    const environments = response.json().environments;
    const backupCollectionUid = pm.variables.get("backupCollectionUid");
    
    // Create "📦 Environment Backups" folder
    const envFolder = {
        name: "📦 Environment Backups",
        description: "Environment backups from source workspace. Requests are disabled by default. Enable and run to restore an environment."
    };
    
    // For each environment, create a disabled request
    environments.forEach(env => {
        // Fetch full environment details
        pm.sendRequest({
            url: `https://api.getpostman.com/environments/${env.uid}`,
            method: 'GET',
            header: {
                'X-Api-Key': pm.environment.get("POSTMAN_API_KEY")
            }
        }, function (err, envResponse) {
            if (!err) {
                const fullEnv = envResponse.json().environment;
                
                // Create disabled request with environment in body
                const restoreRequest = {
                    name: `Restore: ${fullEnv.name}`,
                    request: {
                        method: "POST",
                        url: "https://api.getpostman.com/environments",
                        header: [
                            {
                                key: "X-Api-Key",
                                value: "{{POSTMAN_API_KEY}}"
                            }
                        ],
                        body: {
                            mode: "raw",
                            raw: JSON.stringify({ environment: fullEnv }, null, 2)
                        },
                        description: `Environment backup created on: ${pm.variables.get("dateStamp")}${pm.variables.get("timeStamp")}\n\nOriginal Environment ID: ${env.uid}\n\nTo restore:\n1. Enable this request\n2. Update the name if needed\n3. Run the request\n4. Disable again`
                    },
                    disabled: true
                };
                
                console.log(`✓ Environment backed up: ${fullEnv.name}`);
            }
        });
    });
});
```

### Limitations & Considerations

⚠️ **Secret Variables**: Postman may mask secret-type variables in API responses  
**Solution**: Document that secrets must be manually re-entered after restore

⚠️ **Workspace Context**: Can't determine which environments apply to which collection  
**Solution**: Backup all workspace environments with each collection

⚠️ **Nested Requests**: Multiple API calls required (adds execution time)  
**Solution**: Acceptable for daily automated backups; monitor performance

### Success Criteria

- ✅ All workspace environments backed up with collection
- ✅ Environments stored as disabled POST requests
- ✅ Request bodies contain full environment JSON
- ✅ Restore process documented in request descriptions
- ✅ No impact on backup workspace environment list

---

## Future Enhancements

### Phase 3 Ideas
1. **Diff Detection**
   - Compare current vs last backup
   - Only create backup if changes detected
   - Log what changed

3. **Backup Compression**
   - Store metadata separately
   - Reference full backups with incremental changes

4. **Dashboard Collection**
   - Query backup workspace
   - Display backup status
   - Show last backup dates
   - Identify missing backups

5. **Restore Collection**
   - Automated restore process
   - Select backup by date
   - Copy back to original workspace

6. **Backup Exports**
   - Periodically export backups as JSON files
   - Store in external location (git, cloud storage)
   - Ultimate disaster recovery

---

## Success Criteria

### Must Have (Phase 1)
- ✅ Daily automated backups of Finance collection
- ✅ Backups named with date stamps
- ✅ Manual backup option available
- ✅ Email alerts on backup failures
- ✅ Backups stored in dedicated workspace

### Phase 2 Goals
- ⭐ Environment backups stored within backup collections
- ⭐ Multiple collections backed up (not just Finance)
- ⭐ All workspace environments captured automatically

### Nice to Have (Later Phases)
- ⭐ Retention policy implemented
- ⭐ Dashboard showing backup status

### Stretch Goals
- 🚀 Automated restore functionality
- 🚀 Change detection (only backup if changed)
- 🚀 External export for disaster recovery

---

## Security Considerations

### API Key Management
- Store API key in environment variable
- Use environment-specific keys
- Rotate keys periodically
- Limit key permissions to necessary scopes

### Workspace Permissions
- Backup workspace: View-only for most users
- Editor access only for backup administrators
- Audit who can modify backup collection

### Backup Integrity
- Verify backup creation with tests
- Check backup collection is complete
- Log all backup operations

---

## Next Steps

See `Postman-Backup-Implementation.md` for detailed implementation tracker.

---

**Document Version**: 1.0  
**Created**: October 4, 2025  
**Status**: Planning Phase  
**Owner**: Doug Batchelor

