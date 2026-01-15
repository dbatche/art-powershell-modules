# apiFinance Module

PowerShell DSL (Domain-Specific Language) wrapper for TruckMate Finance API endpoints.

## Concept

This module encapsulates Finance API calls into PowerShell cmdlets following standard verb-noun conventions. Each function:
- **Handles authentication** (token from environment or parameter)
- **Manages base URLs** (environment variables or defaults)
- **Unwraps API responses** (returns data directly, not wrapper objects)
- **Supports pipelining** (output from one function feeds into another)
- **Provides discovery** (Get-Command, Get-Help work as expected)
- **Enables testing** (can be used directly or in test automation)

## Design Goals

### Dual-Purpose Functions: Production + Testing

These functions serve two critical purposes:
1. **Production use** - Quick, discoverable API calls for scripts and automation
2. **API testing** - Verify API validates inputs and returns proper error codes

### Flexible Type Design

Parameters use **minimal type constraints** to enable API contract testing:

**❌ NOT Constrained:** `[int]`, `[decimal]`, `[datetime]`
- Allows testing with intentionally invalid data types
- API validates and returns proper 400 error codes
- Valid usage still works (PowerShell auto-converts types)

**✅ Constrained:** `[hashtable]`, `[switch]`, `[string]`, `[object[]]`
- Structural constraints maintain function usability
- Preserve IntelliSense and discoverability

### Why Flexible Types?

**The Problem:** If we use strict types like `[int]$FuelTaxId`, PowerShell blocks invalid data *before* it reaches the API. This prevents testing API validation.

**The Solution:** Remove numeric/date type constraints so invalid data reaches the API, which then returns proper error codes.

**Testing Examples:**

```powershell
# Test invalid integer type (expect 400 error)
Get-FuelTaxes -FuelTaxId 'ABC'

# Test invalid number type (expect 400 error)
Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase @{ 
    fuelVolume1 = 'heavy' 
}

# Test decimal to integer (expect 400 error)
Get-TripFuelPurchases -FuelTaxId 999.99

# Normal usage still works - PowerShell coerces types naturally
Get-FuelTaxes -FuelTaxId 123      # int works
Get-FuelTaxes -FuelTaxId '123'    # string auto-converts to int
```

**Key Principle:** *The API is the source of truth for validation, not PowerShell parameter types.*

## Setup

### Environment Variables (Recommended)

```powershell
# Set once per session
$env:FINANCE_API_URL = "https://your-server.com"
$env:TRUCKMATE_API_TOKEN = "your-api-token"

# Or use the shorter DOMAIN variable
$env:DOMAIN = "https://your-server.com"
```

### Module Import

```powershell
Import-Module apiFinance
```

## Available Functions

### Fuel Taxes

| Function | HTTP | Endpoint | Description |
|----------|------|----------|-------------|
| `Get-FuelTaxes` | GET | `/fuelTaxes` | Retrieve all fuel tax records |
| `Get-FuelTaxes -FuelTaxId 123` | GET | `/fuelTaxes/{id}` | Retrieve specific fuel tax |

### Trip Fuel Purchases

| Function | HTTP | Endpoint | Description |
|----------|------|----------|-------------|
| `Get-TripFuelPurchases` | GET | `/fuelTaxes/{id}/tripFuelPurchases` | Get purchases for a fuel tax |
| `Get-TripFuelPurchases -TripFuelPurchaseId` | GET | `/fuelTaxes/{id}/tripFuelPurchases/{id}` | Get specific purchase |
| `New-TripFuelPurchases` | POST | `/fuelTaxes/{id}/tripFuelPurchases` | Create purchase(s) |
| `Set-TripFuelPurchase` | PUT | `/fuelTaxes/{id}/tripFuelPurchases/{id}` | Update a purchase |

## Usage Examples

### Simple Retrieval

```powershell
# Get all fuel taxes
Get-FuelTaxes

# Get specific fuel tax
Get-FuelTaxes -FuelTaxId 123

# Get all purchases for a fuel tax
Get-TripFuelPurchases -FuelTaxId 123

# Get specific purchase
Get-TripFuelPurchases -FuelTaxId 123 -TripFuelPurchaseId 456
```

### Filtering and Pagination

```powershell
# OData filtering
Get-FuelTaxes -Filter "tripNumber eq '12345'"
Get-TripFuelPurchases -FuelTaxId 123 -Filter "purchaseLocation eq 'CA'"

# Field selection
Get-FuelTaxes -Select "fuelTaxId,tripNumber,totalTax"

# Pagination
Get-FuelTaxes -Limit 10 -Offset 0  # First page
Get-FuelTaxes -Limit 10 -Offset 10 # Second page
```

### Creating Records

```powershell
# Quick test with default values
New-TripFuelPurchases -FuelTaxId 123 -Default

# Create single purchase
$purchase = @{
    purchaseDate = '2024-01-15'
    purchaseLocation = 'CA'
    fuelType1 = 'DIESEL'
    fuelVolume1 = 100.5
    fuelRate1 = 3.50
    fuelCost1 = 351.75
}
New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchase

# Create multiple purchases at once
$purchases = @(
    @{ purchaseDate = '2024-01-15'; fuelVolume1 = 100; fuelRate1 = 3.50 },
    @{ purchaseDate = '2024-01-16'; fuelVolume1 = 95; fuelRate1 = 3.55 }
)
New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchases
```

### Updating Records

```powershell
# Update specific fields
Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase @{
    fuelVolume1 = 105.5
    fuelRate1 = 3.60
    taxable = 'Y'
}
```

### Pipeline Operations

```powershell
# Get fuel tax, then its purchases
Get-FuelTaxes -FuelTaxId 123 | Get-TripFuelPurchases

# Filter and process
Get-FuelTaxes -Filter "tripNumber eq '12345'" | 
    Get-TripFuelPurchases |
    Where-Object { $_.purchaseLocation -eq 'CA' } |
    Measure-Object -Property fuelVolume1 -Sum

# Create and immediately retrieve
$created = New-TripFuelPurchases -FuelTaxId 123 -Default
Get-TripFuelPurchases -FuelTaxId 123 -TripFuelPurchaseId $created.tripFuelPurchaseId
```

### Testing Scenarios

```powershell
# Contract testing: Create minimal valid purchase
$purchase = New-TripFuelPurchases -FuelTaxId 123 -Default
Write-Host "Created purchase ID: $($purchase.tripFuelPurchaseId)"

# Workflow testing: Create, update, verify
$created = New-TripFuelPurchases -FuelTaxId 123 -Default
$updated = Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId $created.tripFuelPurchaseId -Purchase @{ taxable = 'Y' }
$verified = Get-TripFuelPurchases -FuelTaxId 123 -TripFuelPurchaseId $created.tripFuelPurchaseId

if ($verified.taxable -eq 'Y') {
    Write-Host "✓ Update verified" -ForegroundColor Green
}
```

### Integration with Test Automation

```powershell
# Use with Run-ApiTests for contract validation
$fuelTaxId = 123

# Create test data
$purchase = New-TripFuelPurchases -FuelTaxId $fuelTaxId -Default

# Run contract tests against that data
Run-ApiTests -RequestsFile "test-tripFuelPurchases.ps1" `
    -BaseUrl $env:FINANCE_API_URL `
    -Token $env:TRUCKMATE_API_TOKEN

# Cleanup test data (if DELETE endpoint exists)
# Remove-TripFuelPurchase -FuelTaxId $fuelTaxId -TripFuelPurchaseId $purchase.tripFuelPurchaseId
```

## Benefits

### For Manual Testing
- **Quick experimentation** - Create test data without Postman/curl
- **Discoverable** - `Get-Command -Module apiFinance` shows all available functions
- **Help included** - `Get-Help New-TripFuelPurchases -Examples`

### For Automated Testing
- **Reusable** - Same functions for manual and automated tests
- **Composable** - Chain functions together for workflows
- **Test data setup** - Use `-Default` for quick minimal objects

### For Development
- **Type-safe** - PowerShell parameter validation
- **Consistent** - Same pattern across all endpoints
- **Self-documenting** - Function names describe what they do

## Future Enhancements

- Add response validation (Test-TripFuelPurchase)
- Add DELETE functions (Remove-TripFuelPurchase)
- Add bulk operations (Import-TripFuelPurchases from CSV)
- Add workflow helpers (New-FuelTaxWorkflow)
- Generate from OpenAPI spec automatically

## Related Modules

- **SimpleApiTests** - Contract testing framework
- **apiMasterData** - Master data API (aChargeCodes, etc.)
- **apiTM** - TM endpoint API (orders, trips, etc.)


