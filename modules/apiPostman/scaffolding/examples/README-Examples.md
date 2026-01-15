# Scaffolding Examples

This folder contains example outputs from the scaffolding scripts.

## Generating Examples

To generate a full scaffold example, use the `New-PutEndpointScaffold.ps1` script:

```powershell
# Example: Generate scaffold for PUT /apInvoices/:apInvoiceId
cd ..\scripts
.\New-PutEndpointScaffold.ps1 `
    -ApiKey "PMAK-..." `
    -CollectionUid "8229908-779780a9-..." `
    -EndpointName "apInvoices" `
    -ResourceIdName "apInvoiceId" `
    -SuccessTests @("minimal fields", "vendor update", "status change") `
    -ErrorTests @("invalid vendorId", "invalid status") `
    -OutputPath "..\examples\PUT-apInvoices-Scaffold.json"
```

This will generate a complete JSON structure that can be imported directly into Postman.

## Example Structure

A typical scaffold output includes:

```
PUT /resourceName/:resourceId
├── 200 (Success Tests)
│   ├── minimal fields
│   ├── vendor update
│   └── status change
├── 400 (Bad Request Tests)
│   ├── invalid vendorId
│   └── invalid status
└── 404 (Not Found Tests)
    └── invalid resourceId
```

Each request includes:
- Pre-configured URL with path variables
- Request body template
- Pre-request setup script
- Validation test script

## Import Instructions

1. Open Postman
2. Click "Import" button
3. Select the generated JSON file
4. Choose target collection or create new one
5. Review and adjust test data as needed
6. Manually add the 200 folder test script (see PUT-Scaffold-Update-Summary.md)

## Notes

- Generated scaffolds are templates and need customization
- Business logic validations must be added manually
- Test data values should be updated to match your environment
- The 200 folder-level test script requires manual addition due to JSON serialization limitations

## See Also

- `../docs/PUT-Endpoint-Quick-Start.md` - Detailed usage guide
- `../docs/PUT-Scaffold-Update-Summary.md` - Known limitations and workarounds

