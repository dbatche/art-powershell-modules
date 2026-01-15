# apiTM Module

PowerShell DSL (Domain-Specific Language) wrapper for TruckMate `/tm` API endpoints.

## Concept

This module encapsulates TM API calls into PowerShell cmdlets following standard verb-noun conventions. Each function:
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

**The Problem:** If we use strict types like `[int]$OrderId`, PowerShell blocks invalid data *before* it reaches the API. This prevents testing API validation.

**The Solution:** Remove numeric/date type constraints so invalid data reaches the API, which then returns proper error codes.

**Testing Examples:**

```powershell
# Test invalid integer type (expect 400 error)
Set-Order -OrderId 'ABC' -Rate 1500

# Test invalid number type (expect 400 error)
Set-Order -OrderId 123 -Weight 'heavy'

# Test decimal to integer (expect 400 error)
Set-Order -OrderId 999.99 -BillTo 'CUST001'

# Normal usage still works - PowerShell coerces types naturally
Set-Order -OrderId 123 -Rate 1500.50      # Both int and decimal work
Set-Order -OrderId '123' -Rate '1500.50'  # Strings auto-convert
```

**Key Principle:** *The API is the source of truth for validation, not PowerShell parameter types.*

### Hybrid Parameter Design

For complex resources with many properties (e.g., Orders with 62+ fields), we use a **hybrid approach**:

**Named Parameters** - Common fields (most frequently updated):
```powershell
Set-Order -OrderId 123 -BillTo 'CUST001' -ServiceLevel 'EXPRESS' -Rate 1500.50
```

**-Updates Hashtable** - All other fields (including nested objects and arrays):
```powershell
Set-Order -OrderId 123 -Updates @{
    audits = @(
        @{ action = 'UPDATED'; user = 'JOHN'; timestamp = '2024-01-15T10:00:00' }
    )
    consignee = @{ name = 'ABC Corp'; city = 'NYC' }
    notes = 'Customer request'
}
```

**Benefits:**
- **Discoverability** - Common fields show in IntelliSense
- **Flexibility** - `-Updates` handles complex nested data
- **Maintainability** - Don't need 62+ named parameters

## Setup

### Environment Variables (Recommended)

```powershell
# Set once per session
$env:TM_API_URL = "https://your-server.com"
$env:TRUCKMATE_API_TOKEN = "your-api-token"

# Or use the shorter DOMAIN variable
$env:DOMAIN = "https://your-server.com"
```

### Module Import

```powershell
Import-Module apiTM
```

## Available Functions

### Orders

| Function | HTTP | Endpoint | Description |
|----------|------|----------|-------------|
| `Set-Order` | PUT | `/tm/orders/{orderId}` | Update an order (freight bill) |

## Usage Examples

### Simple Updates (Named Parameters)

```powershell
# Update common fields
Set-Order -OrderId 12345 -BillTo 'CUST001' -ServiceLevel 'EXPRESS'

# Update rate and weight
Set-Order -OrderId 12345 -Rate 1500.50 -Weight 5000

# Update delivery driver
Set-Order -OrderId 12345 -DeliveryDriver1 'JOHN'
```

### Complex Updates (Hybrid Approach)

```powershell
# Mix common fields + complex updates
Set-Order -OrderId 12345 -BillTo 'CUST001' -Updates @{
    consignee = @{ 
        name = 'ABC Corp'
        address = '123 Main St'
        city = 'NYC'
        state = 'NY'
        zip = '10001'
    }
    audits = @(
        @{ action = 'UPDATED'; user = 'JOHN'; notes = 'Customer address corrected' }
    )
}
```

### Audit Trail Management

```powershell
# Add audit entry
Set-Order -OrderId 12345 -Updates @{
    audits = @(
        @{ 
            action = 'RERATE'
            user = 'BILLING'
            timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
            notes = 'Rate adjusted per contract'
        }
    )
}

# Multiple audits
Set-Order -OrderId 12345 -Updates @{
    audits = @(
        @{ action = 'PICKUP'; user = 'DRIVER1'; notes = 'Picked up' },
        @{ action = 'DELIVERY'; user = 'DRIVER1'; notes = 'Delivered' }
    )
}
```

### Nested Object Updates

```powershell
# Update consignee details
Set-Order -OrderId 12345 -Updates @{
    consignee = @{
        name = 'New Company Name'
        phone = '555-1234'
        email = 'contact@company.com'
    }
}

# Update shipper details
Set-Order -OrderId 12345 -Updates @{
    shipper = @{
        name = 'Warehouse Inc'
        address = '456 Industrial Way'
        city = 'Los Angeles'
    }
}

# Update multiple nested objects at once
Set-Order -OrderId 12345 -Updates @{
    consignee = @{ name = 'ABC Corp'; city = 'NYC' }
    shipper = @{ name = 'XYZ Warehouse'; city = 'LA' }
    careOf = @{ name = 'Attn: Receiving' }
}
```

### Array Updates

```powershell
# Update accessorial charges
Set-Order -OrderId 12345 -Updates @{
    aCharges = @(
        @{ chargeCode = 'FUEL'; amount = 50.00; description = 'Fuel surcharge' },
        @{ chargeCode = 'TOLL'; amount = 15.00; description = 'Highway tolls' },
        @{ chargeCode = 'WAIT'; amount = 75.00; description = 'Detention time' }
    )
}

# Update custom fields
Set-Order -OrderId 12345 -Updates @{
    customDefs = @(
        @{ field = 'CustomField1'; value = 'SpecialHandling' },
        @{ field = 'CustomField2'; value = 'PriorityDelivery' }
    )
}
```

### Testing Scenarios

```powershell
# Contract testing: Test invalid types (expect 400 errors)
Set-Order -OrderId 'ABC' -Rate 1500           # Invalid integer
Set-Order -OrderId 123 -Weight 'heavy'        # Invalid number
Set-Order -OrderId 999.99 -BillTo 'CUST001'   # Decimal to integer

# Workflow testing: Create audit trail
$orderId = 12345
Set-Order -OrderId $orderId -Updates @{
    audits = @( @{ action = 'CREATED'; user = 'SYSTEM' } )
}

# Verify update
$order = Get-Order -OrderId $orderId  # (if Get-Order exists)
if ($order.audits.Count -gt 0) {
    Write-Host "✓ Audit trail verified" -ForegroundColor Green
}
```

### WhatIf Support

```powershell
# Preview changes without executing
Set-Order -OrderId 12345 -BillTo 'CUST001' -Rate 1500 -WhatIf

# Output: What if: Performing the operation "Update Order" on target "Order 12345"
```

## Benefits

### For Manual Testing
- **Quick updates** - Modify orders without Postman/Swagger UI
- **Discoverable** - `Get-Command -Module apiTM` shows all available functions
- **Help included** - `Get-Help Set-Order -Examples`

### For Automated Testing
- **Reusable** - Same functions for manual and automated tests
- **Composable** - Chain functions together for workflows
- **Contract testing** - Test API validation with invalid data

### For Development
- **Flexible types** - Can test with intentionally invalid data
- **Consistent** - Same pattern across all endpoints
- **Self-documenting** - Function names describe what they do

## Future Enhancements

- Add GET functions (Get-Order, Get-Orders)
- Add POST function (New-Order)
- Add DELETE function (Remove-Order)
- Add response validation (Test-Order)
- Add workflow helpers (New-OrderWorkflow)
- Add more endpoints (trips, stops, details, etc.)

## Related Modules

- **SimpleApiTests** - Contract testing framework
- **apiFinance** - Finance API (fuel taxes, purchases, user fields)
- **apiMasterData** - Master data API (charge codes, etc.)


