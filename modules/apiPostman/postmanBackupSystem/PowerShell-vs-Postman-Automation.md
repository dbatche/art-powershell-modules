# PowerShell vs Postman Automation - Architecture Guide

**Last Updated**: January 2025  
**Purpose**: Clarify which parts of the backup system run in PowerShell vs Postman collections

---

## Overview

The Postman Backup System uses a **hybrid approach**:
- **Postman Collections**: Automated daily backups (runs via Monitor)
- **PowerShell Functions**: Management, maintenance, and configuration tasks

This document explains what runs where and when to use each.

---

## Postman Collection Automation (Automated Backups)

### What It Does
The **"Backup System"** Postman collection runs automatically via Postman Monitor to create daily backups of collections and environments.

### Location
- **Collection Name**: "Backup System"
- **Collection ID**: `2332132-669c5855-dd73-4858-9222-78547c739666`
- **Workspace**: Personal workspace (Doug Batchelor)

### Structure
```
Backup System
  ├─ 📦 Collection Backups (folder)
  │   ├─ Backup: TM - TruckMate
  │   ├─ Backup: TM - Trips
  │   ├─ Backup: TM - Trips POST/PUT
  │   ├─ Backup: TM - Orders
  │   ├─ Backup: TM - Master Data
  │   ├─ Backup: Finance Functional Tests
  │   ├─ Backup: Contract Tests
  │   ├─ Backup: TM - CloudHub Functional Tests
  │   ├─ Backup: TM - Visibility
  │   └─ Backup: TM - ConnectedDock
  └─ 🌍 Environment Backups (folder)
      └─ Backup: All Environments
```

### How It Works
1. **Collection Backups**: Each request in the "📦 Collection Backups" folder:
   - Fetches the source collection via Postman API
   - Modifies the name with timestamp (`Auto Backup YYYY-MM-DD - Name`)
   - Creates a new backup collection in the personal workspace
   - Uses JavaScript in pre-request scripts

2. **Environment Backups**: The "🌍 Environment Backups" folder contains one request that:
   - Fetches environments from multiple workspaces (defined in script)
   - Creates a backup collection with disabled POST requests
   - Each environment stored as a restore request (enable and run to restore)

### Execution
- **Automated**: Runs daily via Postman Monitor (scheduled)
- **Manual**: Can be run manually from Postman UI
- **Language**: JavaScript (in pre-request and test scripts)
- **No External Dependencies**: Runs entirely within Postman

### Configuration
- **Collection IDs**: Hardcoded in each backup request's pre-request script
- **Workspace IDs**: Defined in the environment backup script's `workspaceIds` array
- **API Key**: Stored in Postman environment variable `POSTMAN_API_KEY`

### When to Modify
- Adding a new collection to backup → Use PowerShell `Update-PostmanBackupSystem`
- Changing backup naming convention → Edit collection-level pre-request script
- Updating workspace IDs for environment backups → Use PowerShell `Update-PostmanBackupSystem`

---

## PowerShell Functions (Management & Maintenance)

### Location
All PowerShell functions are in:
```
C:\git\art-powershell-modules\modules\apiPostman\postmanBackupSystem\
```

### Available Functions

#### 1. `Remove-OldPostmanBackups`
**Purpose**: Retention/cleanup - deletes backups older than specified days

**What It Does**:
- Lists all collections (optionally filtered by workspace)
- Parses backup names to extract dates
- Deletes backups older than retention period (default: 14 days)

**When to Use**:
- Weekly/monthly cleanup tasks
- Manual cleanup before major changes
- Scheduled via Task Scheduler (optional)

**Example**:
```powershell
Remove-OldPostmanBackups -RetentionDays 14 -WhatIf  # Preview
Remove-OldPostmanBackups -RetentionDays 14          # Execute
```

**Runs**: PowerShell (manual or scheduled)

---

#### 2. `Update-PostmanBackupSystem`
**Purpose**: Configuration - updates the Postman Backup System collection structure

**What It Does**:
- Adds new backup requests to the "📦 Collection Backups" folder
- Updates the `workspaceIds` array in the environment backup script
- Ensures the collection structure matches `Collection-Workspace-Map.json`

**When to Use**:
- Adding a new collection to the backup system
- Adding a new workspace for environment backups
- After updating `Collection-Workspace-Map.json`

**Example**:
```powershell
Update-PostmanBackupSystem
```

**Runs**: PowerShell (manual, when configuration changes)

---

#### 3. `Get-PostmanWorkspaceId`
**Purpose**: Helper - finds workspace ID by name

**What It Does**:
- Searches all accessible workspaces
- Returns workspace ID for a given name

**When to Use**:
- When you need a workspace ID for configuration
- Troubleshooting workspace access issues

**Example**:
```powershell
Get-PostmanWorkspaceId -WorkspaceName "TM - Visibility"
```

**Runs**: PowerShell (manual, as needed)

---

#### 4. `Restore-PostmanEnvironment`
**Purpose**: Restore - restores an environment to a specific workspace

**What It Does**:
- Takes environment JSON (from backup)
- Creates/updates environment in specified workspace
- Handles workspace context (avoids defaulting to personal workspace)

**When to Use**:
- Restoring an environment from backup
- Moving environments between workspaces
- After environment backup collection is created

**Example**:
```powershell
$envJson = Get-Content "backup-environment.json" -Raw
Restore-PostmanEnvironment -EnvironmentJson $envJson -WorkspaceId "workspace-id"
```

**Runs**: PowerShell (manual, when restoring)

---

#### 5. `Test-PostmanWorkspaceAccess`
**Purpose**: Diagnostic - checks API key permissions for a workspace

**What It Does**:
- Verifies API key can access a workspace
- Checks permission level (viewer, editor, admin)
- Helps diagnose 403 Forbidden errors

**When to Use**:
- Troubleshooting permission issues
- Verifying API key has correct access
- Before attempting restore operations

**Example**:
```powershell
Test-PostmanWorkspaceAccess -WorkspaceId "workspace-id"
```

**Runs**: PowerShell (manual, for troubleshooting)

---

#### 6. `Find-PostmanCollection`
**Purpose**: Discovery - finds collection by name across workspaces

**What It Does**:
- Searches all accessible workspaces
- Returns collection ID and workspace info
- Useful when collection IDs change

**When to Use**:
- Collection ID is outdated (404 errors)
- Collection was renamed or moved
- Updating `Collection-Workspace-Map.json`

**Example**:
```powershell
Find-PostmanCollection -CollectionName "TM - Trips"
```

**Runs**: PowerShell (manual, when IDs are stale)

---

## Configuration Files

### `Collection-Workspace-Map.json`
**Purpose**: Maps collection names to their IDs and workspace information

**Used By**:
- `Update-PostmanBackupSystem` - to determine what to add
- PowerShell functions - as reference for collection/workspace relationships

**When to Update**:
- Adding new collections to backup system
- Collection IDs change
- Collections move to different workspaces

**Location**: `C:\git\art-powershell-modules\modules\apiPostman\postmanBackupSystem\Collection-Workspace-Map.json`

---

## Workflow: Adding a New Collection to Backup

### Step 1: Update Configuration (PowerShell)
1. Add collection to `Collection-Workspace-Map.json`:
   ```json
   "New Collection": {
     "CollectionId": "collection-uuid",
     "WorkspaceId": "workspace-uuid",
     "WorkspaceName": "Workspace Name"
   }
   ```

### Step 2: Update Postman Collection (PowerShell)
2. Run `Update-PostmanBackupSystem`:
   ```powershell
   Update-PostmanBackupSystem
   ```
   This adds the backup request to the Postman collection.

### Step 3: Verify (Postman)
3. Open Postman → "Backup System" collection
4. Verify new request appears in "📦 Collection Backups" folder
5. Test run the new backup request manually

### Step 4: Monitor (Postman)
6. The Postman Monitor will automatically include the new request in daily backups

---

## Workflow: Daily Backup Execution

### Automated Flow (Postman)
1. **Postman Monitor** triggers at scheduled time (e.g., 2:00 AM)
2. **"Backup System"** collection runs automatically
3. **Collection Backups** folder executes first:
   - Each request creates a backup collection
   - Named: `Auto Backup YYYY-MM-DD - [Collection Name]`
4. **Environment Backups** folder executes next:
   - Creates backup collection with environment restore requests
   - Organized by workspace in sub-folders

### Manual Cleanup (PowerShell)
5. **Weekly/Monthly**: Run `Remove-OldPostmanBackups`:
   ```powershell
   Remove-OldPostmanBackups -RetentionDays 14
   ```

---

## Decision Tree: When to Use What

### Use Postman Collection When:
- ✅ Running automated daily backups (Monitor handles this)
- ✅ Creating manual backups on-demand
- ✅ Restoring environments (enable/run restore request)
- ✅ Viewing backup history (browse backup collections)

### Use PowerShell When:
- ✅ Adding new collections to backup system
- ✅ Cleaning up old backups (retention)
- ✅ Troubleshooting (finding IDs, testing access)
- ✅ Restoring environments to specific workspaces
- ✅ Updating collection structure/configuration

---

## Environment Variables

### Required for PowerShell Functions
- `POSTMAN_API_KEY`: Postman API key (set via `Setup-EnvironmentVariables`)

### Required for Postman Collection
- `POSTMAN_API_KEY`: Stored in Postman environment variable
- `MANUAL_BACKUP`: "false" for automated, "true" for manual backups

---

## Troubleshooting Guide

### Issue: Backup not running automatically
**Check**: Postman Monitor status and schedule

### Issue: 404 Not Found for collection
**Solution**: Run `Find-PostmanCollection` to get updated ID, then update `Collection-Workspace-Map.json` and run `Update-PostmanBackupSystem`

### Issue: 403 Forbidden when restoring environment
**Solution**: Run `Test-PostmanWorkspaceAccess` to verify permissions

### Issue: Old backups not being cleaned up
**Solution**: Run `Remove-OldPostmanBackups` manually or schedule it

### Issue: New collection not being backed up
**Solution**: 
1. Add to `Collection-Workspace-Map.json`
2. Run `Update-PostmanBackupSystem`
3. Verify request appears in Postman collection

---

## Summary Table

| Task | Tool | Execution | Frequency |
|------|------|-----------|-----------|
| Daily collection backups | Postman Collection | Automated (Monitor) | Daily |
| Daily environment backups | Postman Collection | Automated (Monitor) | Daily |
| Manual backups | Postman Collection | Manual (UI) | On-demand |
| Add new collection | PowerShell | Manual | As needed |
| Cleanup old backups | PowerShell | Manual/Scheduled | Weekly/Monthly |
| Restore environment | Postman or PowerShell | Manual | As needed |
| Troubleshoot IDs | PowerShell | Manual | As needed |
| Update configuration | PowerShell | Manual | As needed |

---

## Related Documentation

- **[Postman-Backup-System-Plan.md](Postman-Backup-System-Plan.md)** - Overall system architecture
- **[Postman-Backup-Implementation.md](Postman-Backup-Implementation.md)** - Implementation tracker
- **[README-Backup-Project.md](README-Backup-Project.md)** - Project overview

---

**Key Takeaway**: 
- **Postman = Automated execution** (backups run automatically)
- **PowerShell = Management & maintenance** (configuration, cleanup, troubleshooting)

Both work together to provide a complete backup solution.


