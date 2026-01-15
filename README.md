# ART PowerShell Modules

PowerShell modules for TruckMate REST API testing and automation.

## Modules

### 🚚 API Wrapper Modules
Modern PowerShell function wrappers for TruckMate REST APIs:

- **artTM** - TruckMate Orders API (`/tm`)
- **artFinance** - Finance API (`/finance`)
- **artMasterData** - Master Data API (`/masterData`)
- **artVisibility** - Visibility API (`/visibility`)
- **artCloudHub** - CloudHub API integration

### 🧪 Testing & Utilities

- **artTests** - Testing utilities, OpenAPI analyzers, contract tests
- **apiPostman** - Postman collection management and backup automation

## Features

✅ **Minimal Type Constraints** - Functions designed to test API behavior, not validate input  
✅ **ArgumentCompleter** - Tab completion without validation (allows testing invalid values)  
✅ **OData Query Support** - `$filter`, `$select`, `$orderby`, `limit`, `offset`, `expand`  
✅ **Error Handling** - Returns JSON error strings for testability  
✅ **OpenAPI-Driven** - Functions generated from OpenAPI specifications  
✅ **Environment Variables** - Uses `$env:TM_API_URL`, `$env:TRUCKMATE_API_KEY`, etc.

## Quick Start

```powershell
# Import modules
Import-Module artTM
Import-Module artFinance
Import-Module artTests

# Setup environment variables
Setup-EnvironmentVariables -Quiet

# Use API functions
$orders = Find-Orders -Filter "status eq 'NEW'" -Limit 10
$order = Get-Order -OrderId 12345 -Expand "details"
$newOrder = New-Order -Type "P" -Body $orderData
```

## Environment Variables

Set these before using the modules:

```powershell
$env:TM_API_URL = "https://tde-truckmate.tmwcloud.com/cur/tm"
$env:FINANCE_API_URL = "https://tde-truckmate.tmwcloud.com/fin/finance"
$env:MASTERDATA_API_URL = "https://tde-truckmate.tmwcloud.com/cur/masterData"
$env:VISIBILITY_API_URL = "https://tde-truckmate.tmwcloud.com/cur/visibility"
$env:TRUCKMATE_API_KEY = "your-api-key-here"
```

Or use the built-in setup:
```powershell
Import-Module artTests
Setup-EnvironmentVariables
```

## Function Naming Conventions

### Top-Level Resources
- `Find-{Resource}` - GET collection (e.g., `Find-Orders`)
- `Get-{Resource}` - GET single item by ID (e.g., `Get-Order`)
- `New-{Resource}` - POST create (e.g., `New-Order`)
- `Set-{Resource}` - PUT update (e.g., `Set-Order`)
- `Remove-{Resource}` - DELETE (e.g., `Remove-Order`)

### Hierarchical Resources
- `Get-OrderDetail` - 2nd level: `/orders/{orderId}/details/{detailId}`
- `Get-OrderDetailBarcode` - 3rd level: `/orders/{orderId}/details/{detailId}/barcodes/{barcodeId}`

## Error Handling

Functions return **error JSON strings** on failure for testability:

```powershell
$result = Get-Order -OrderId 999999

if ($result -is [string]) {
    # Parse error
    $error = $result | ConvertFrom-Json
    Write-Host "Error $($error.error.status): $($error.error.title)"
} else {
    # Success - got order object
    Write-Host "Order: $($result.billNumber)"
}
```

## Documentation

- [API Function Creation Guide](docs/API-Function-Creation-Guide.md)
- [Module Development Plan](docs/ApiModulesPlan.md)

## Requirements

- PowerShell 7+
- TruckMate API access and valid API key
- Network access to TruckMate environments

## Contributing

When adding new API endpoint functions:

1. Check OpenAPI spec using `Get-OpenApiEndpoints`
2. Use `Analyze-OpenApiSchema` for complex schemas
3. Follow the patterns in the [Creation Guide](docs/API-Function-Creation-Guide.md)
4. Use minimal type constraints (designed for testing, not validation)
5. Include synopsis with endpoint path: `[GET /resource]`

## License

Internal use only - Trimble TruckMate QA Team

