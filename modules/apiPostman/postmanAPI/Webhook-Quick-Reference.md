# Backup System Webhook - Quick Reference

## 🔗 Your Webhook URL

```
https://newman-api.getpostman.com/run/2332132/99e329a2-a1b4-4a11-8c8a-741ccca066f2
```

**Webhook ID**: `1f0a268f-52b4-4ec0-b583-9314389bdfca`  
**Collection**: Backup System  
**Workspace**: My Workspace (Personal)

---

## 🚀 Quick Trigger

### Option 1: Use the Script (Easiest)
```powershell
# From the apiPostman directory:
.\Trigger-Backup.ps1
```

### Option 2: Direct PowerShell
```powershell
Invoke-RestMethod -Uri 'https://newman-api.getpostman.com/run/2332132/99e329a2-a1b4-4a11-8c8a-741ccca066f2' -Method Post
```

### Option 3: With Specific Environment
```powershell
$body = @{ environment = 'YOUR_ENV_UID' } | ConvertTo-Json
Invoke-RestMethod -Uri 'https://newman-api.getpostman.com/run/2332132/99e329a2-a1b4-4a11-8c8a-741ccca066f2' -Method Post -Body $body -ContentType 'application/json'
```

---

## 📋 What Happens When Triggered

1. ✅ Runs all 6 collection backups
   - TM - TruckMate
   - TM - Trips
   - TM - Orders
   - TM - Master Data
   - Finance Functional Tests
   - Contract Tests

2. ✅ Runs environment backup
   - Fetches from 5 workspaces
   - Organizes by workspace folders

3. ✅ Creates timestamped backup collections in your workspace

---

## 🛠️ Management Commands

### View Webhook Details
```powershell
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

# Get webhook info
Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/1f0a268f-52b4-4ec0-b583-9314389bdfca" -Headers $headers
```

### Delete Webhook
```powershell
$apiKey = "$env:POSTMAN_API_KEY"
$headers = @{ "X-Api-Key" = $apiKey }

Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/1f0a268f-52b4-4ec0-b583-9314389bdfca" -Headers $headers -Method Delete
```

### Create New Webhook
```powershell
.\Create-Webhook.ps1
```

---

## 🎯 Use Cases

### Before Major Changes
```powershell
Write-Host "Creating backup before deployment..."
.\Trigger-Backup.ps1
Start-Sleep -Seconds 30  # Wait for backup to complete
# Continue with your deployment
```

### In CI/CD Pipeline
```yaml
# GitHub Actions example
- name: Backup Postman Collections
  run: |
    curl -X POST https://newman-api.getpostman.com/run/2332132/99e329a2-a1b4-4a11-8c8a-741ccca066f2
```

### Weekly Manual Check
```powershell
# Add to your weekly routine
.\Trigger-Backup.ps1
```

---

## 📊 Monitor vs Webhook

| Feature | **Monitor** | **Webhook** |
|---------|------------|-------------|
| Trigger | Scheduled (daily) | On-demand (you call it) |
| Best For | Automated daily backups | Before deployments, testing |
| Setup | Phase 3 (upcoming) | ✅ Ready now |

**Recommendation**: Use both! Monitor for daily automation, webhook for manual control.

---

## ℹ️ Files

- **`Create-Webhook.ps1`** - Creates the webhook
- **`Trigger-Backup.ps1`** - Quick trigger script
- **`Backup-Webhook-Info.json`** - Webhook details (auto-generated)
- **`Webhook-Quick-Reference.md`** - This file

---

## 🔐 Security Note

⚠️ **Keep your webhook URL private!** Anyone with the URL can trigger your backups.

If compromised:
1. Delete the webhook: `Invoke-RestMethod -Uri "https://api.getpostman.com/webhooks/1f0a268f-52b4-4ec0-b583-9314389bdfca" -Headers $headers -Method Delete`
2. Create a new one: `.\Create-Webhook.ps1`
