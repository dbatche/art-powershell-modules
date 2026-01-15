# Update-PostmanRequestName.ps1 - Usage Examples

## Script Features
- Updates request names using Postman API
- Supports single or bulk updates
- Uses GET → modify → PUT pattern (full object required)
- Proper error handling and progress reporting

## Single Update Example

```powershell
.\Update-PostmanRequestName.ps1 `
    -ApiKey "PMAK-67a3fbc01f830c0001362e8f-..." `
    -CollectionUid "8229908-779780a9-97d0-4004-9a96-37e8c64c3405" `
    -RequestUid "8229908-78ca2f0e-330f-4b3e-ab33-c74f188dad1e" `
    -NewName "invalid ISTA code TM-185730"
```

## Bulk Update Example

```powershell
$apiKey = "PMAK-67a3fbc01f830c0001362e8f-..."
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"

$updates = @(
    @{ Uid = "8229908-5f141504-5a9d-462b-9e8a-be2844927572"; NewName = "invalid GL Account TM-185730" },
    @{ Uid = "8229908-f60d41a0-f982-4b72-a5c8-6533f9c18021"; NewName = "invalid GL Account TM-185730" },
    @{ Uid = "8229908-fbc7e4d9-f97b-4e58-aae7-c9220266d79e"; NewName = "invalid Driver Deduction Code TM-185730" },
    @{ Uid = "8229908-78ca2f0e-330f-4b3e-ab33-c74f188dad1e"; NewName = "invalid ISTA code TM-185730" },
    @{ Uid = "8229908-c043260d-f23d-4bf9-838d-124f9699a835"; NewName = "invalid Equipment Id TM-185730" },
    @{ Uid = "8229908-6c01334f-be09-4507-b56a-68f796704fff"; NewName = "invalid Power Unit Id TM-185730" },
    @{ Uid = "8229908-9def603b-9f64-4a14-8434-14ede2ad8f8a"; NewName = "invalid Trailer Id TM-185730" }
)

.\Update-PostmanRequestName.ps1 `
    -ApiKey $apiKey `
    -CollectionUid $collectionUid `
    -BulkUpdates $updates
```

## Important Notes

1. **Request UID Format**: Must include the owner prefix (e.g., `8229908-xxx`), not just the UUID
2. **Full Object Required**: The API requires GET → modify → PUT with the complete request object
3. **Partial Updates**: Sending only `{ "name": "new name" }` will fail with 400/404 errors
4. **API Key**: Use your Postman API key (PMAK-...), not the Finance API key

## Real-World Use Case (2025-10-06)

Updated 7 test requests in "Finance Functional Tests" collection to tag them with `TM-185730`:
- Changed ISTA-related tests from `TM-180923` → `TM-185730`
- Added `TM-185730` tag to GL Account and Driver Deduction tests
- All 7 requests successfully updated in bulk

## API Endpoint

```
PUT https://api.getpostman.com/collections/{collectionUid}/requests/{requestUid}
```

Requires the full request object in the body, not just the changed fields.

