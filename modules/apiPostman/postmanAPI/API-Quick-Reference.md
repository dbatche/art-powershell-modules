# Postman API Quick Reference

## Base URL
```
https://api.getpostman.com
```

## Authentication
```powershell
$headers = @{"X-Api-Key" = "YOUR_API_KEY"}
```

## Common Endpoints

### Collections
```
GET    /collections                      # List all
GET    /collections/{id}                 # Get single
POST   /collections                      # Create
PUT    /collections/{id}                 # Update
DELETE /collections/{id}                 # Delete
```

### Environments
```
GET    /environments                     # List all
GET    /environments/{id}                # Get single
POST   /environments                     # Create
PUT    /environments/{id}                # Update
DELETE /environments/{id}                # Delete
```

### Monitors
```
GET    /monitors                         # List all
GET    /monitors/{id}                    # Get single
GET    /monitors/{id}/runs               # Get run history
POST   /monitors                         # Create
PUT    /monitors/{id}                    # Update
DELETE /monitors/{id}                    # Delete

# Query params: ?owner=ID&active=true&limit=25
```

### User & Team
```
GET    /me                               # Current user
GET    /team                             # Team info
```

### Workspaces
```
GET    /workspaces                       # List all
GET    /workspaces/{id}                  # Get single
POST   /workspaces                       # Create
PUT    /workspaces/{id}                  # Update
DELETE /workspaces/{id}                  # Delete
```

### Mocks
```
GET    /mocks                            # List all
GET    /mocks/{id}                       # Get single
POST   /mocks                            # Create
PUT    /mocks/{id}                       # Update
DELETE /mocks/{id}                       # Delete
```

### APIs
```
GET    /apis                             # List all
GET    /apis/{id}                        # Get single
GET    /apis/{id}/versions               # Get versions
GET    /apis/{id}/schemas                # Get schemas
POST   /apis                             # Create
PUT    /apis/{id}                        # Update
```

## PowerShell Examples

### Get All Collections
```powershell
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections" `
    -Headers $headers

$response.collections | Select uid, name, owner
```

### Get All Environments
```powershell
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/environments" `
    -Headers $headers

$response.environments | Select uid, name, owner
```

### Get Active Monitors for Owner
```powershell
$url = "https://api.getpostman.com/monitors?owner=8229908&active=true"
$response = Invoke-RestMethod -Uri $url -Headers $headers
$response.monitors
```

### Get Current User
```powershell
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/me" `
    -Headers $headers

$response.user | Format-List
```

### Search Collections by Name
```powershell
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections" `
    -Headers $headers

$response.collections | Where-Object { $_.name -like '*Finance*' }
```

### Get Specific Collection Details
```powershell
$id = "779780a9-97d0-4004-9a96-37e8c64c3405"
$response = Invoke-RestMethod `
    -Uri "https://api.getpostman.com/collections/$id" `
    -Headers $headers

$response.collection
```

## Response Fields

### Collections/Environments
- `id` - 5-segment UUID
- `uid` - Full 6-segment ID with owner (use for CLI!)
- `owner` - Owner ID number
- `name` - Resource name

### User
- `id` - User ID
- `username` - Username
- `email` - Email address
- `fullName` - Full name
- `teamId` - Team ID
- `teamName` - Team name

## HTTP Status Codes
- `200` - Success
- `400` - Bad Request
- `401` - Unauthorized (check API key)
- `403` - Forbidden
- `404` - Not Found
- `429` - Rate Limit Exceeded
- `500` - Server Error

## Key Insights

### Owner IDs
✅ **Available in API responses** - Both collections and environments return `owner` field  
❌ **NOT in exported files** - Must query API or check web UI URL

### Full IDs for CLI
API returns both:
- `id` - UUID only (5 segments)
- `uid` - Full CLI-ready ID (6 segments with owner prefix)

Example:
```
id:  779780a9-97d0-4004-9a96-37e8c64c3405
uid: 8229908-779780a9-97d0-4004-9a96-37e8c64c3405
     ^^^^^^^
     owner prefix (required by Postman CLI)
```

## Pagination

Many endpoints support pagination:
```powershell
$url = "https://api.getpostman.com/monitors?limit=25&cursor=next_cursor_token"
```

## Related Scripts

### Postman API Scripts
- `Update-PostmanOwners.ps1` - Generate owner config from API
- `List-PostmanMonitors.ps1` - Query monitors
- `Get-PostmanMonitor.ps1` - Get monitor details

### Postman CLI Scripts
- `Get-PostmanResourceGroups.ps1` - Analyze reports, generate commands
- `Get-PostmanRunFailures.ps1` - Extract failures
- `Get-PostmanRunSummary.ps1` - Extract metadata

## Tips

1. **Cache API responses** - Don't query for every operation
2. **Use owner filters** - Reduce data transfer: `?owner=8229908`
3. **Update config periodically** - Run `Update-PostmanOwners` weekly
4. **Check rate limits** - Monitor response headers
5. **Error handling** - Always wrap API calls in try/catch

---

**See Also**: `Postman-API-Overview.md` for comprehensive documentation

