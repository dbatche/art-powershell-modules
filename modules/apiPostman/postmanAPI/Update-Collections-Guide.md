# Postman API: Updating Collections and Requests

## Overview

The Postman API provides two approaches for updating collections:

1. **Update entire collection** - Replace the whole collection
2. **Update single request** - Modify just one request within a collection

## Approach 1: Update Entire Collection

### Endpoint
```
PUT https://api.getpostman.com/collections/{collectionUid}
```

### When to Use
- Updating collection-level properties (name, description, variables)
- Making multiple changes across many requests
- Reorganizing folder structure
- When you have the full collection JSON already

### Body Format
Must provide the **complete collection object** in JSON format:

```json
{
  "collection": {
    "info": {
      "name": "My Collection",
      "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
      "_postman_id": "779780a9-97d0-4004-9a96-37e8c64c3405"
    },
    "item": [
      // All folders and requests must be included
    ],
    "variable": [
      // Collection variables
    ]
  }
}
```

### PowerShell Example
```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

# 1. Get current collection
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
$current = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid" `
    -Headers $headers

# 2. Modify what you need
$current.collection.info.name = "Updated Collection Name"

# 3. Update collection (must send entire collection)
$body = $current | ConvertTo-Json -Depth 100
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid" `
    -Method Put `
    -Headers $headers `
    -Body $body

Write-Host "Collection updated!" -ForegroundColor Green
```

### Limitations
❌ **Size Limits** - Large collections may exceed API limits  
❌ **Overwrites Everything** - Must include all items or they'll be deleted  
❌ **Complex** - Requires managing the entire collection structure

---

## Approach 2: Update Single Request ⭐ (Recommended)

### Endpoint
```
PUT https://api.getpostman.com/collections/{collectionUid}/requests/{requestId}
```

### When to Use
- Updating a single request's properties
- Modifying request URL, method, headers, body
- Changing test scripts or pre-request scripts
- More efficient for targeted changes

### Body Format
Only include the **fields you want to update** (partial update supported):

```json
{
  "name": "Updated Request Name",
  "request": {
    "url": "https://new-api-endpoint.com/resource",
    "method": "POST",
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      }
    ],
    "body": {
      "mode": "raw",
      "raw": "{\"key\": \"value\"}"
    }
  }
}
```

### PowerShell Example: Update Request Name and URL
```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
$requestId = "49972cd7-3602-42a1-9872-93639becc166"

# Only update what you need
$updates = @{
    name = "Updated Request Name"
    request = @{
        url = "https://new-endpoint.com/api/v2/resource"
        method = "GET"
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestId" `
    -Method Put `
    -Headers $headers `
    -Body $updates

Write-Host "Request updated!" -ForegroundColor Green
```

### PowerShell Example: Update Test Script
```powershell
# Add or update test scripts
$updates = @{
    event = @(
        @{
            listen = "test"
            script = @{
                type = "text/javascript"
                exec = @(
                    "pm.test('Status code is 200', function () {",
                    "    pm.response.to.have.status(200);",
                    "});"
                )
            }
        }
    )
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$requestId" `
    -Method Put `
    -Headers $headers `
    -Body $updates

Write-Host "Test script updated!" -ForegroundColor Green
```

### Advantages
✅ **Partial Updates** - Only send what you need to change  
✅ **Efficient** - No size limit issues  
✅ **Simple** - Don't need to manage entire collection  
✅ **Safe** - Won't accidentally delete other requests

---

## Finding Request IDs

### Method 1: From API (Full Collection)
```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{"X-Api-Key" = $apiKey}
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"

# Get full collection
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid" `
    -Headers $headers

# Browse structure
Write-Host "Folders:" -ForegroundColor Cyan
$response.collection.item | ForEach-Object {
    Write-Host "  $($_.name) (ID: $($_.id))" -ForegroundColor Yellow
    
    if ($_.item) {
        Write-Host "    Requests:" -ForegroundColor Gray
        $_.item | ForEach-Object {
            Write-Host "      $($_.name) (ID: $($_.id))" -ForegroundColor Green
        }
    }
}
```

### Method 2: From Exported Collection File
```powershell
$collection = Get-Content "Finance Functional Tests.postman_collection.json" | ConvertFrom-Json

# Search for request by name
$collection.item | ForEach-Object {
    $folder = $_
    if ($folder.item) {
        $folder.item | Where-Object { $_.name -like "*version*" } | ForEach-Object {
            [PSCustomObject]@{
                Folder = $folder.name
                Request = $_.name
                ID = $_.id
            }
        }
    }
}
```

### Method 3: From Newman Report
```powershell
$report = Get-Content "report.json" | ConvertFrom-Json

# Request IDs are in executions
$report.run.executions | ForEach-Object {
    if ($_.item) {
        [PSCustomObject]@{
            Name = $_.item.name
            ID = $_.item.id
        }
    }
} | Select-Object -Unique Name, ID
```

---

## Request Structure Reference

### Complete Request Object
```json
{
  "id": "49972cd7-3602-42a1-9872-93639becc166",
  "name": "Get Version",
  "request": {
    "url": "https://api.example.com/version",
    "method": "GET",
    "header": [
      {
        "key": "Authorization",
        "value": "Bearer {{token}}",
        "type": "text"
      }
    ],
    "body": {
      "mode": "raw",
      "raw": "{\"key\": \"value\"}",
      "options": {
        "raw": {
          "language": "json"
        }
      }
    },
    "description": "Retrieves API version information"
  },
  "response": [],
  "event": [
    {
      "listen": "prerequest",
      "script": {
        "type": "text/javascript",
        "exec": [
          "// Pre-request script",
          "console.log('Running pre-request');"
        ]
      }
    },
    {
      "listen": "test",
      "script": {
        "type": "text/javascript",
        "exec": [
          "pm.test('Status code is 200', function () {",
          "    pm.response.to.have.status(200);",
          "});"
        ]
      }
    }
  ]
}
```

### Common Update Scenarios

#### Update URL
```json
{
  "request": {
    "url": "https://new-domain.com/api/v2/endpoint"
  }
}
```

#### Update Method
```json
{
  "request": {
    "method": "POST"
  }
}
```

#### Update Headers
```json
{
  "request": {
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      },
      {
        "key": "Authorization",
        "value": "Bearer {{token}}"
      }
    ]
  }
}
```

#### Update Request Body
```json
{
  "request": {
    "body": {
      "mode": "raw",
      "raw": "{\"newKey\": \"newValue\"}",
      "options": {
        "raw": {
          "language": "json"
        }
      }
    }
  }
}
```

#### Update Tests
```json
{
  "event": [
    {
      "listen": "test",
      "script": {
        "type": "text/javascript",
        "exec": [
          "pm.test('Response is successful', function () {",
          "    pm.response.to.be.success;",
          "});"
        ]
      }
    }
  ]
}
```

---

## Real-World Example: Bulk Update URLs

Update all request URLs to a new domain:

```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{
    "X-Api-Key" = $apiKey
    "Content-Type" = "application/json"
}

$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"

# Get collection structure
$collection = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$collectionUid" `
    -Headers $headers

# Find all requests
$allRequests = @()
foreach ($folder in $collection.collection.item) {
    if ($folder.item) {
        foreach ($request in $folder.item) {
            $allRequests += [PSCustomObject]@{
                ID = $request.id
                Name = $request.name
                CurrentURL = $request.request.url.raw
            }
        }
    }
}

# Update each request
$oldDomain = "https://old-domain.com"
$newDomain = "https://new-domain.com"

foreach ($req in $allRequests) {
    if ($req.CurrentURL -like "$oldDomain*") {
        $newUrl = $req.CurrentURL -replace [regex]::Escape($oldDomain), $newDomain
        
        Write-Host "Updating: $($req.Name)" -ForegroundColor Yellow
        Write-Host "  Old: $($req.CurrentURL)" -ForegroundColor Gray
        Write-Host "  New: $newUrl" -ForegroundColor Green
        
        $updates = @{
            request = @{
                url = $newUrl
            }
        } | ConvertTo-Json -Depth 10
        
        try {
            Invoke-RestMethod `
                -Uri "https://api.getpostman.com/collections/$collectionUid/requests/$($req.ID)" `
                -Method Put `
                -Headers $headers `
                -Body $updates
            
            Write-Host "  ✓ Updated" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 500  # Rate limit courtesy
    }
}

Write-Host "`nBulk update complete!" -ForegroundColor Cyan
```

---

## Best Practices

### 1. Use Request-Level Updates When Possible ✅
- More efficient
- Less error-prone
- Faster execution
- No size limits

### 2. Always Test Changes First
```powershell
# Get current state
$current = Invoke-RestMethod -Uri "..." -Headers $headers

# Make a backup
$current | ConvertTo-Json -Depth 100 | Out-File "backup.json"

# Then make changes
```

### 3. Handle Errors Gracefully
```powershell
try {
    $response = Invoke-RestMethod -Uri "..." -Method Put -Headers $headers -Body $body
    Write-Host "Success!" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.ErrorDetails.Message
    Write-Host "Error ($statusCode): $errorMessage" -ForegroundColor Red
}
```

### 4. Respect Rate Limits
```powershell
# Add delays between bulk operations
Start-Sleep -Milliseconds 500
```

### 5. Use Version Control
- Export collections before making changes
- Keep backups in git
- Track changes over time

---

## Comparison: Full vs Request Update

| Feature | Full Collection Update | Single Request Update |
|---------|----------------------|----------------------|
| **Endpoint** | `PUT /collections/{id}` | `PUT /collections/{id}/requests/{requestId}` |
| **Body Size** | Full collection (can be huge) | Only changed fields (small) |
| **Partial Update** | ❌ No - must send everything | ✅ Yes - send only changes |
| **Size Limits** | ⚠️ May hit limits | ✅ No issues |
| **Complexity** | High - manage full structure | Low - simple updates |
| **Risk** | High - can delete items | Low - isolated changes |
| **Speed** | Slow for large collections | Fast |
| **Best For** | Collection-level changes | Request-specific changes |

---

## See Also

- `Postman-API-Overview.md` - General API documentation
- `API-Quick-Reference.md` - Quick endpoint reference
- Postman API Documentation: https://learning.postman.com/docs/developer/postman-api/

---

**Last Updated**: October 4, 2025  
**Postman API Version**: v10

