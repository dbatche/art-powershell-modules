# Postman API Overview

The Postman API (`api.getpostman.com`) allows you to programmatically interact with your Postman workspace.

## Authentication

All API requests require a valid API key:
```powershell
$headers = @{"X-Api-Key" = "YOUR_POSTMAN_API_KEY"}
Invoke-RestMethod -Uri "https://api.getpostman.com/endpoint" -Headers $headers
```

## Main Resources You Can Manage

### 1. **Collections** 📦
Organize and manage your API requests.

**Endpoints:**
- `GET /collections` - List all collections
- `GET /collections/{collectionId}` - Get single collection (full details)
- `POST /collections` - Create new collection
- `PUT /collections/{collectionId}` - Update collection
- `DELETE /collections/{collectionId}` - Delete collection

**Key Fields Returned:**
- `id` - 5-segment UUID
- `uid` - Full 6-segment ID with owner prefix
- `owner` - Owner ID (⭐ Important for CLI commands)
- `name` - Collection name

**Example:**
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers
$response.collections | Select-Object uid, name, owner, id
```

### 2. **Environments** 🌍
Store variables and configurations for different contexts.

**Endpoints:**
- `GET /environments` - List all environments
- `GET /environments/{environmentId}` - Get single environment
- `POST /environments` - Create new environment
- `PUT /environments/{environmentId}` - Update environment
- `DELETE /environments/{environmentId}` - Delete environment

**Key Fields Returned:**
- `id` - 5-segment UUID
- `uid` - Full 6-segment ID with owner prefix
- `owner` - Owner ID (⭐ Important for CLI commands)
- `name` - Environment name
- `values` - Array of key-value pairs

**Example:**
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers
$response.environments | Select-Object uid, name, owner, id
```

### 3. **Monitors** 📊
Schedule and automate API tests.

**Endpoints:**
- `GET /monitors` - List all monitors (supports filtering)
- `GET /monitors/{monitorId}` - Get single monitor
- `POST /monitors` - Create new monitor
- `PUT /monitors/{monitorId}` - Update monitor
- `DELETE /monitors/{monitorId}` - Delete monitor
- `GET /monitors/{monitorId}/runs` - Get monitor run history

**Query Parameters:**
- `owner` - Filter by owner ID
- `active` - Filter by active status (true/false)
- `limit` - Results per page (default: 25)

**Example:**
```powershell
# List active monitors for owner 8229908
$url = "https://api.getpostman.com/monitors?owner=8229908&active=true&limit=25"
$response = Invoke-RestMethod -Uri $url -Headers $headers
$response.monitors
```

### 4. **Workspaces** 🗂️
Collaborate with teams on API projects.

**Endpoints:**
- `GET /workspaces` - List all workspaces
- `GET /workspaces/{workspaceId}` - Get single workspace
- `POST /workspaces` - Create new workspace
- `PUT /workspaces/{workspaceId}` - Update workspace
- `DELETE /workspaces/{workspaceId}` - Delete workspace

### 5. **Mock Servers** 🎭
Simulate API responses for testing.

**Endpoints:**
- `GET /mocks` - List all mocks
- `GET /mocks/{mockId}` - Get single mock
- `POST /mocks` - Create new mock
- `PUT /mocks/{mockId}` - Update mock
- `DELETE /mocks/{mockId}` - Delete mock

### 6. **Users & Team** 👥
Manage account and team information.

**Endpoints:**
- `GET /me` - Get current user info
- `GET /team` - Get team information (requires Enterprise)

**Example:**
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/me" -Headers $headers
$response.user | Format-List id, username, email, fullName, teamId, teamName
```

### 7. **APIs** 🔌
Manage API definitions and schemas.

**Endpoints:**
- `GET /apis` - List all APIs
- `GET /apis/{apiId}` - Get single API
- `POST /apis` - Create new API
- `PUT /apis/{apiId}` - Update API
- `GET /apis/{apiId}/versions` - Get API versions
- `GET /apis/{apiId}/schemas` - Get API schemas

### 8. **Webhooks** 🪝
Trigger collection runs via external events.

**Endpoints:**
- Create webhooks to trigger collection runs
- Integrate with CI/CD pipelines
- Automate workflows based on external triggers

## Key Discovery: Owner IDs ⭐

### The Problem
Postman CLI requires **full 6-segment IDs** for collections and environments:
```
8229908-779780a9-97d0-4004-9a96-37e8c64c3405
^^^^^^^
Owner ID (required for CLI, not in exported files!)
```

### Where Owner IDs Are NOT Available ❌
- Exported `.postman_collection.json` files (except hidden in `_collection_link` URL)
- Exported `.postman_environment.json` files
- Newman/native JSON report files

### Where Owner IDs ARE Available ✅
- **Postman API** - Both `/collections` and `/environments` endpoints return `owner` field
- Postman Web UI URLs

### Solution Implemented
Created `Update-PostmanOwners.ps1` script that:
1. Queries Postman API for all collections and environments
2. Extracts owner IDs automatically
3. Generates `postman-owners.json` config file
4. Used by `Get-PostmanResourceGroups` for automatic owner ID lookup

## API Response Statistics (Trimble Account)

Based on actual query:
- **Collections**: 2,367 total
- **Environments**: 1,706 total

## Rate Limits

The Postman API enforces rate limits:
- Standard tier: Check Postman documentation for current limits
- Responses include rate limit headers
- Uses HTTPS for secure communication
- Returns JSON format with appropriate HTTP status codes

## Common Use Cases

### 1. Auto-Generate Owner Config
```powershell
# Fetch all collections and environments with owner IDs
. .\Update-PostmanOwners.ps1
Update-PostmanOwners

# Result: postman-owners.json with 2000+ mappings
```

### 2. List Your Collections
```powershell
$apiKey = "YOUR_API_KEY"
$headers = @{"X-Api-Key" = $apiKey}
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers

$response.collections | 
    Where-Object { $_.owner -eq '8229908' } |
    Select-Object name, uid |
    Sort-Object name
```

### 3. Find Environment by Name
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/environments" -Headers $headers

$response.environments | 
    Where-Object { $_.name -like '*TDE*' } |
    Select-Object name, uid, owner
```

### 4. Get Active Monitors for Your Team
```powershell
$owner = "8229908"
$url = "https://api.getpostman.com/monitors?owner=$owner&active=true"
$response = Invoke-RestMethod -Uri $url -Headers $headers

$response.monitors | 
    Select-Object name, uid, schedule |
    Format-Table -AutoSize
```

### 5. Get User Information
```powershell
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/me" -Headers $headers

Write-Host "User: $($response.user.fullName)" -ForegroundColor Cyan
Write-Host "Email: $($response.user.email)" -ForegroundColor Cyan
Write-Host "Team: $($response.user.teamName)" -ForegroundColor Cyan
```

## Integration with Postman CLI

The Postman API complements the Postman CLI:

### API Use Cases:
- ✅ **Discover** collections and environments
- ✅ **Get owner IDs** for CLI commands
- ✅ **List** available resources
- ✅ **Manage** collections/environments/monitors
- ✅ **Query** monitor run history

### CLI Use Cases:
- ✅ **Run** collections locally or in CI/CD
- ✅ **Execute** tests with specific data
- ✅ **Generate** detailed reports
- ✅ **Validate** APIs with folder-level granularity

### Combined Workflow:
```powershell
# 1. Use API to discover resources
$collections = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers

# 2. Use API data to build CLI commands
$financeCollection = $collections.collections | Where-Object { $_.name -like '*Finance*' }
$collectionUid = $financeCollection.uid
$envUid = "11896768-68887950-1feb-4817-87c5-f5dcffa370cb"

# 3. Execute with CLI
postman collection run $collectionUid -e $envUid --reporters json
```

## Enterprise Features

Additional features available with Postman Enterprise:
- **SCIM** - Automate team provisioning
- **Audit Logs** - Monitor team activities
- **Secret Scanner** - Manage detected secrets
- **Advanced team management** - Role-based access control

## Error Handling

Common HTTP status codes:
- `200` - Success
- `400` - Bad Request (check parameters)
- `401` - Unauthorized (check API key)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `429` - Rate Limit Exceeded
- `500` - Server Error

**Example with error handling:**
```powershell
try {
    $response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections" -Headers $headers
    Write-Host "Success! Found $($response.collections.Count) collections" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.Exception.Message
    Write-Host "Error ($statusCode): $errorMessage" -ForegroundColor Red
}
```

## Documentation Links

- **Official API Documentation**: https://www.postman.com/postman/postman-api/documentation/
- **Postman Learning Center**: https://learning.postman.com/
- **API Reference**: Search for "Postman API reference" in Postman web UI

## Related Scripts in This Module

### Using Postman API:
- `Update-PostmanOwners.ps1` - Auto-generate owner ID mappings
- `List-PostmanMonitors.ps1` - Query monitors via API
- `Get-PostmanMonitor.ps1` - Get monitor details and reports
- `Export-PostmanMonitorSnapshot.ps1` - Automate monitor report exports

### Using Postman CLI:
- `Get-PostmanResourceGroups.ps1` - Analyze reports and generate CLI commands
- `Get-PostmanRunFailures.ps1` - Extract failed tests from reports
- `Get-PostmanRunSummary.ps1` - Extract metadata from reports
- `Invoke-PostmanResourceTests.ps1` - Execute resource-specific tests

### Configuration:
- `postman-owners.json` - Owner ID mappings (auto-generated)

## Benefits of API Integration

1. **Automation** - Eliminate manual lookups and data entry
2. **Discovery** - Find collections/environments programmatically
3. **Integration** - Combine with CLI for end-to-end workflows
4. **Scale** - Manage hundreds/thousands of resources efficiently
5. **Accuracy** - Auto-extract IDs reduces errors
6. **Maintenance** - Keep configs up-to-date automatically

## Example: Complete Workflow

```powershell
# Step 1: Update owner mappings from API
. ..\Update-PostmanOwners.ps1
Update-PostmanOwners

# Step 2: Analyze existing report
. .\Get-PostmanResourceGroups.ps1
$summary = Get-PostmanResourceGroups -Path "Finance-Report.json" -Format Summary
$summary | Format-Table

# Step 3: Generate CLI commands (uses API-sourced owner IDs)
Get-PostmanResourceGroups -Path "Finance-Report.json" -Format CLI

# Step 4: Execute specific resource
Get-PostmanResourceGroups -Path "Finance-Report.json" -Format CLI |
    Select-Object -First 1 |
    ForEach-Object { Invoke-Expression $_ }

# Step 5: Analyze failures
. .\Get-PostmanRunFailures.ps1
Get-PostmanRunFailures -Path "Finance-Report.json" -Format Table
```

---

**Last Updated**: October 4, 2025  
**API Version**: v10  
**Postman Account**: Trimble (Team ID: 445948)

