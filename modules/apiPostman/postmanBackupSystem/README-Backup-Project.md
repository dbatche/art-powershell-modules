# Postman Collection Backup System - Project Overview

**Status**: ✅ Operational  
**Created**: October 4, 2025  
**Last Updated**: January 2025  
**Owner**: Doug Batchelor

---

## Project Summary

Hybrid backup system combining Postman collection automation (for daily backups) with PowerShell functions (for management and maintenance). Automatically backs up critical collections and environments daily, with retention policies and management tools.

### Key Features
- ✅ Fully automated daily backups via Postman Monitor
- ✅ 10 collections backed up automatically
- ✅ Environment backups stored within backup collections
- ✅ Manual backup option for on-demand use
- ✅ Date-stamped backup naming
- ✅ Retention system (PowerShell) - deletes backups older than 14 days
- ✅ PowerShell management functions for configuration and troubleshooting
- ✅ Email notifications on failure

---

## Documentation Suite

### 🏗️ Architecture & Design

**[PowerShell-vs-Postman-Automation.md](PowerShell-vs-Postman-Automation.md)** ⭐ **NEW**
- **Essential reading** - Explains what runs in PowerShell vs Postman
- Complete breakdown of automation vs management tasks
- When to use each tool
- Workflow guides for common tasks
- Troubleshooting decision tree

**Read this first** to understand the hybrid architecture.

**[Postman-Backup-System-Plan.md](Postman-Backup-System-Plan.md)** (14.8 KB)
- Original system architecture and design
- Technical design with scripts
- Phase 2: Environment backup strategy
- Naming conventions
- Security considerations
- Future enhancements
- Limitations and workarounds

---

### ✅ Implementation Tracker

**[Postman-Backup-Implementation.md](Postman-Backup-Implementation.md)** (16.8 KB)
- Detailed phase-by-phase checklist
- 8 phases from testing to production
- Environment backup tasks included
- Task tracking with checkboxes
- Issue log and notes sections
- Success metrics tracking
- Project completion criteria

**Use this** as your working document during implementation.

---

### 🚀 Quick Start Guide

**[Backup-Phase1-QuickStart.md](Backup-Phase1-QuickStart.md)** (10.9 KB)
- Step-by-step Phase 1 testing guide
- Complete scripts ready to copy/paste
- Environment setup instructions
- Troubleshooting guide
- Success criteria

**Start here** to begin testing in your personal workspace.

---

### 📖 Supporting Documentation

**[Update-Collections-Guide.md](Update-Collections-Guide.md)** (12.4 KB)
- How to update entire collections
- How to update single requests
- Finding request IDs
- PowerShell examples
- Best practices

**[Postman-API-Overview.md](Postman-API-Overview.md)** (11.1 KB)
- Complete Postman API documentation
- All endpoints and resources
- Owner ID discovery
- Integration examples

**[API-Quick-Reference.md](API-Quick-Reference.md)** (5.4 KB)
- Quick endpoint lookup
- Common PowerShell commands
- Response field reference

### 🔧 PowerShell Functions

All PowerShell functions are in `C:\git\art-powershell-modules\modules\apiPostman\postmanBackupSystem\`:

- **`Remove-OldPostmanBackups`** - Retention/cleanup (deletes backups older than X days)
- **`Update-PostmanBackupSystem`** - Updates Postman collection structure
- **`Get-PostmanWorkspaceId`** - Helper to find workspace IDs
- **`Restore-PostmanEnvironment`** - Restore environments to specific workspaces
- **`Test-PostmanWorkspaceAccess`** - Diagnostic tool for permissions
- **`Find-PostmanCollection`** - Find collections by name

See [PowerShell-vs-Postman-Automation.md](PowerShell-vs-Postman-Automation.md) for details.

---

## Quick Links

### Essential Reading
1. **[PowerShell vs Postman Automation](PowerShell-vs-Postman-Automation.md)** ⭐ - **Start here** - Architecture guide
2. [System Plan](Postman-Backup-System-Plan.md) - Original design document
3. [Implementation Tracker](Postman-Backup-Implementation.md) - Task checklist

### Reference Documents
4. [Update Collections Guide](Update-Collections-Guide.md) - API Details
5. [Postman API Overview](Postman-API-Overview.md) - Complete API Docs
6. [API Quick Reference](API-Quick-Reference.md) - Quick Lookup

---

## Getting Started

### 1. Read the Plan
Start with `Postman-Backup-System-Plan.md` to understand:
- System architecture
- How backups work
- Technical approach
- Naming conventions

### 2. Begin Testing
Follow `Backup-Phase1-QuickStart.md`:
- Create test environment
- Create test collection
- Copy/paste scripts
- Run first backup test
- Verify results

### 3. Track Progress
Use `Postman-Backup-Implementation.md`:
- Check off completed tasks
- Document issues
- Track metrics
- Plan next steps

---

## Implementation Status

### Phase 1: Proof of Concept ✅ (Complete)
- [x] Test collection copy in personal workspace
- [x] Verify naming conventions
- [x] Refine scripts

### Phase 2: Environment Backups & Additional Collections ✅ (Complete)
- [x] Review available collections list
- [x] Design environment backup approach (store within backup collection)
- [x] Implement environment backup in "📦 Environment Backups" folder
- [x] Add multiple collections for backup (10 collections total)
- [x] Test full backup run with environments

### Phase 3-4: Production Collection ✅ (Complete)
- [x] Build main backup collection ("Backup System")
- [x] Add backup requests for each collection
- [x] Test collection runner

### Phase 5: Monitor & Automation ✅ (Complete)
- [x] Create daily monitor
- [x] Configure notifications
- [x] Monitor production runs

### Phase 6: Manual Backup Option ✅ (Complete)
- [x] Manual backup option available (set `MANUAL_BACKUP` environment variable)

### Phase 7: Retention & Cleanup ✅ (Complete)
- [x] Design retention policy (14 days default)
- [x] Create PowerShell cleanup function (`Remove-OldPostmanBackups`)
- [x] Manual cleanup available (can be scheduled)

### Phase 8: Enhancements 🔄 (Ongoing)
- [x] Add more collections (10 total)
- [x] PowerShell management functions
- [ ] Optimize performance (as needed)
- [ ] Improve error handling (as needed)

---

## Key Design Decisions

### Why Self-Hosted in Postman?
✅ No external infrastructure  
✅ Leverage existing Postman investment  
✅ Simple maintenance  
✅ Secure (uses Postman's authentication)  
✅ Team can access backups easily

### Why Postman API?
✅ Full CRUD operations on collections  
✅ Can copy collections programmatically  
✅ Supports single request updates  
✅ Returns owner IDs needed for CLI

### Why Monitors?
✅ Built-in scheduling  
✅ Email notifications  
✅ Reliable execution  
✅ No manual intervention

---

## Collections Currently Backed Up

10 collections are automatically backed up daily:

1. **TM - TruckMate**
2. **TM - Trips**
3. **TM - Trips POST/PUT**
4. **TM - Orders**
5. **TM - Master Data**
6. **Finance Functional Tests**
7. **Contract Tests**
8. **TM - CloudHub Functional Tests**
9. **TM - Visibility**
10. **TM - ConnectedDock**

See `Collection-Workspace-Map.json` for complete IDs and workspace mappings.

### Adding New Collections
1. Add to `Collection-Workspace-Map.json`
2. Run `Update-PostmanBackupSystem` PowerShell function
3. Verify in Postman collection

---

## Naming Convention

### Automated Backups
```
Auto Backup 2025-10-04 - [Collection Name]
```

### Manual Backups
```
Manual Backup 2025-10-04 14-30 - [Collection Name]
```

**Benefits**:
- Chronologically sortable
- Clear backup type identification
- No name conflicts
- Preserves original name

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────┐
│         Postman Monitor (Daily 2 AM)                │
│  Executes: "Collection Backup Automation"           │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│    Collection: "Collection Backup Automation"        │
│  ┌─────────────────────────────────────────────┐   │
│  │ Pre-Request: Set timestamps, backup type     │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
│  Request 1: Backup Finance Collection               │
│  Request 2: Backup [Collection 2]                   │
│  Request 3: Backup [Collection 3]                   │
│  ...                                                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│        Each Request Workflow:                        │
│  1. Fetch source collection via API                 │
│  2. Modify name with date stamp                     │
│  3. Create new collection (POST /collections)       │
│  4. Verify success and log result                   │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│     Workspace: "Collection Backups"                  │
│  Auto Backup 2025-10-04 - Finance Functional Tests  │
│  Auto Backup 2025-10-05 - Finance Functional Tests  │
│  Auto Backup 2025-10-06 - Finance Functional Tests  │
│  ...                                                 │
└─────────────────────────────────────────────────────┘
```

---

## Success Criteria

### Must Have ✅
- Daily automated backups of Finance collection
- Backups named with date stamps
- Manual backup option available
- Email alerts on failures
- Backups in dedicated workspace

### Nice to Have ⭐
- Multiple collections backed up
- Retention policy implemented
- Environment backups
- Backup status dashboard

### Stretch Goals 🚀
- Automated restore
- Change detection
- External disaster recovery exports

---

## Current Status

**Status**: ✅ Operational  
**Collections Backed Up**: 10  
**Backup Frequency**: Daily (via Postman Monitor)  
**Retention**: 14 days (configurable via PowerShell)  
**Last Updated**: January 2025

---

## Resources & Tools

### Postman Resources
- Postman API Documentation: https://learning.postman.com/docs/developer/postman-api/
- Monitors Documentation: https://learning.postman.com/docs/monitoring-your-api/intro-monitors/
- Workspace Management: https://learning.postman.com/docs/collaborating-in-postman/using-workspaces/

### Project Resources
- **API Key**: Stored in `POSTMAN_API_KEY` environment variable (set via `Setup-EnvironmentVariables`)
- **Collection Configuration**: `Collection-Workspace-Map.json` maps collections to workspaces
- **PowerShell Functions**: `C:\git\art-powershell-modules\modules\apiPostman\postmanBackupSystem\`
- **Postman Collection**: "Backup System" (ID: `2332132-669c5855-dd73-4858-9222-78547c739666`)

---

## Contact & Support

**Project Owner**: Doug Batchelor  
**Workspace**: [TBD - Backup workspace to be created]  
**Questions**: Document in implementation tracker

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-04 | Initial planning documentation created |
| 2.0 | 2025-01 | System operational, added PowerShell functions, retention system, architecture guide |

---

## Quick Start

### For New Users
1. **Read**: [PowerShell-vs-Postman-Automation.md](PowerShell-vs-Postman-Automation.md) - Understand the architecture
2. **Setup**: Ensure `POSTMAN_API_KEY` environment variable is set
3. **Use**: Backups run automatically daily via Postman Monitor

### Common Tasks

**Add a new collection to backup:**
```powershell
# 1. Edit Collection-Workspace-Map.json
# 2. Run:
Update-PostmanBackupSystem
```

**Clean up old backups:**
```powershell
Remove-OldPostmanBackups -RetentionDays 14 -WhatIf  # Preview
Remove-OldPostmanBackups -RetentionDays 14          # Execute
```

**Restore an environment:**
- Open backup collection in Postman
- Find "Restore: [Environment Name]" request
- Enable and run the request
- Disable again after restore

See [PowerShell-vs-Postman-Automation.md](PowerShell-vs-Postman-Automation.md) for complete workflows.

---

*This is a living document. Update as the project progresses.*

