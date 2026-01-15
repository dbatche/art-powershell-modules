# API Endpoint Function Creation Guide

## Overview
This guide documents the standard process and patterns for creating PowerShell API wrapper functions for TruckMate APIs (TM, Finance, MasterData, etc.).

## Core Principle: API Testing Flexibility
**These functions are designed to TEST the API, not validate input for the user.**

Key implications:
- Minimal type constraints (use `$param` not `[int]$param`)
- No mandatory validation that blocks API testing
- ArgumentCompleters for convenience, NOT ValidateSets
- Functions should allow invalid data to reach the API
- API validates and returns proper error codes

## Standard Process

### 1. Analyze OpenAPI Specification

#### Use Get-OpenApiEndpoints
```powershell
# Find top-level resources
Get-OpenApiEndpoints -SpecFile "finance-openapi-*.json" -Path "^/[^/{}]+$" -OutputFormat Table

# Check specific endpoint
Get-OpenApiEndpoints -SpecFile "finance-openapi-*.json" -Path "/apInvoices" -Method GET
```

#### Use Analyze-OpenApiSchema
```powershell
# Analyze POST endpoint
Analyze-OpenApiSchema -SpecFile "finance-openapi-*.json" -Path "/apInvoices" -Method "POST"

# Analyze GET endpoint parameters
$spec = Get-Content "finance-openapi-*.json" -Raw | ConvertFrom-Json -AsHashtable
$getOp = $spec.paths.'/apInvoices'.get
$getOp.parameters | ForEach-Object { ... }
```

#### Check for path parameter endpoints
```powershell
# Does it have /{id} path?
if($spec.paths.'/apInvoices/{apInvoiceId}') {
    # Support both collection and single item retrieval
}
```

### 2. Function Naming Convention

| HTTP Method | Function Prefix | Example |
|-------------|----------------|---------|
| GET (collection) | `Get-` | `Get-ApInvoices` |
| GET (single) | `Get-` | `Get-ApInvoices -ApInvoiceId 123` |
| POST | `New-` | `New-ApInvoice` |
| PUT | `Set-` | `Set-ApInvoice` |
| PATCH | `Update-` | `Update-ApInvoice` |
| DELETE | `Remove-` | `Remove-ApInvoice` |

### Hierarchical Resources
For nested/child resources, concatenate names:
- `/orders` → `Get-Order`
- `/orders/{orderId}/details` → `Get-OrderDetail`
- `/orders/{orderId}/details/{detailId}/barcodes` → `Get-OrderDetailBarcode`

**Hierarchy Indicators:**
1. **Synopsis**: Include endpoint path after description: `[{path}]`
2. **Parameters**: Path parameters naturally indicate hierarchy (see section 3)
3. **Help Text**: Document parent requirements in parameter descriptions

#### Examples

**Top-level resource:**
```powershell
.SYNOPSIS
    Retrieves accounts payable invoice records [/apInvoices]

.PARAMETER ApInvoiceId
    Optional. Specific AP invoice ID to retrieve.
    If omitted, returns collection of AP invoices.
    Used in path: /apInvoices/{apInvoiceId}
```

**2nd-level resource (child):**
```powershell
.SYNOPSIS
    Retrieves order detail records [/orders/{orderId}/details]

.PARAMETER OrderId
    Required. The order ID to retrieve details from.
    Used in path: /orders/{orderId}/details

.PARAMETER DetailId
    Optional. Specific detail ID to retrieve.
    If omitted, returns all details for the order.
    Used in path: /orders/{orderId}/details/{detailId}
```

**3rd-level resource (grandchild):**
```powershell
.SYNOPSIS
    Retrieves barcode records [/orders/{orderId}/details/{detailId}/barcodes]

.PARAMETER OrderId
    Required. The order ID containing the detail.
    Used in path: /orders/{orderId}/details/{detailId}/barcodes

.PARAMETER DetailId
    Required. The detail ID to retrieve barcodes from.
    Used in path: /orders/{orderId}/details/{detailId}/barcodes

.PARAMETER BarcodeId
    Optional. Specific barcode ID to retrieve.
    If omitted, returns all barcodes for the detail.
    Used in path: /orders/{orderId}/details/{detailId}/barcodes/{barcodeId}
```

**Pattern:** The number of "Required" path parameters indicates the resource level.

### 3. Standard GET Function Template

```powershell
function Get-{ResourceName} {
    <#
    .SYNOPSIS
        Retrieves {description} [{endpoint}]
    
    .DESCRIPTION
        GET {endpoint}
        Retrieves {description} from the {API} API.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER {IdParameter}
        Optional. Specific {resource} ID to retrieve.
        If omitted, returns collection of {resources}.
        Used in path: {endpoint}/{idParameter}
    
    .PARAMETER Filter
        Optional. OData filter expression.
        Example: "{example filter}"
    
    .PARAMETER Select
        Optional. OData select expression for specific fields.
        Example: "{example fields}"
    
    .PARAMETER OrderBy
        Optional. OData orderby expression.
        Example: "{example orderby}"
    
    .PARAMETER Limit
        Optional. Maximum number of records to return (pagination).
        Note: Use "limit" (lowercase) not "top" for query parameter
    
    .PARAMETER Offset
        Optional. Number of records to skip (pagination).
        Note: Use "offset" (lowercase) for query parameter
    
    .PARAMETER Expand
        Optional. Comma-separated list of sub-resources to include.
        Supported values: {list from OpenAPI spec}
    
    .PARAMETER BaseUrl
        API base URL. Defaults to $env:{API}_API_URL
    
    .PARAMETER Token
        Bearer token. Defaults to $env:TRUCKMATE_API_KEY
    
    .PARAMETER PassThru
        Returns the full API response object instead of unwrapped data
    
    .EXAMPLE
        Get-{ResourceName}
        # Returns all records
    
    .EXAMPLE
        Get-{ResourceName} -{IdParameter} 123
        # Returns specific record
    
    .EXAMPLE
        Get-{ResourceName} -Filter "{example}" -OrderBy "{example}"
        # Returns filtered and sorted records
    
    .OUTPUTS
        Array of {resource} objects, or JSON error string for testability
    #>
    
    [CmdletBinding()]
    param(
        ${IdParameter},  # No type constraint
        
        [string]$Filter,
        [string]$Select,
        [string]$OrderBy,
        $Limit,   # No type constraint
        $Offset,  # No type constraint
        [string]$Expand,
        
        [string]$BaseUrl = ($env:{API}_API_URL ?? $env:DOMAIN ?? 'http://localhost:9950'),
        [string]$Token = ($env:TRUCKMATE_API_KEY ?? $env:TRUCKMATE_API_TOKEN ?? $env:API_TOKEN),
        [switch]$PassThru
    )
    
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Accept' = 'application/json'
    }
    
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    if (${IdParameter}) {
        # Get specific item
        $uri = "$BaseUrl{endpoint}/${IdParameter}"
        
        if ($Expand) {
            $uri += "?expand=$Expand"
        }
    }
    else {
        # Get collection
        $queryParams = @()
        
        if ($Filter) { $queryParams += "`$filter=$Filter" }
        if ($Select) { $queryParams += "`$select=$Select" }
        if ($OrderBy) { $queryParams += "`$orderby=$OrderBy" }
        if ($Limit) { $queryParams += "limit=$Limit" }
        if ($Offset) { $queryParams += "offset=$Offset" }
        if ($Expand) { $queryParams += "expand=$Expand" }
        
        $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
        $uri = "$BaseUrl{endpoint}$queryString"
    }
    
    # Always add verbose logging for diagnostics
    Write-Verbose "GET $uri"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        if ($PassThru) {
            return $response
        }
        else {
            if (${IdParameter}) {
                # Single item - unwrap from response object
                if ($response.{singularKey}) {
                    return $response.{singularKey}
                } else {
                    return $response
                }
            }
            else {
                # Collection - unwrap array
                if ($response.{collectionKey}) {
                    return $response.{collectionKey}
                } else {
                    return $response
                }
            }
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            Write-Error $_.Exception.Message
        }
    }
}
```

### 4. Standard POST Function Template

```powershell
function New-{ResourceName} {
    <#
    .SYNOPSIS
        Creates new {description} [POST {endpoint}]
    
    .DESCRIPTION
        POST {endpoint}
        Creates one or more {resource} records.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Body,  # No type constraint - allows testing with invalid types
        
        [string]$Select,
        
        [string]$BaseUrl = ($env:{API}_API_URL ?? $env:DOMAIN ?? 'http://localhost:9950'),
        [string]$Token = ($env:TRUCKMATE_API_KEY ?? $env:TRUCKMATE_API_TOKEN ?? $env:API_TOKEN),
        [switch]$PassThru
    )
    
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    $queryParams = @()
    if ($Select) { $queryParams += "`$select=$Select" }
    
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl{endpoint}$queryString"
    
    # Always add verbose logging for diagnostics
    Write-Verbose "POST $uri"
    
    # Note: Check OpenAPI spec for request body format
    # Some APIs expect direct array, others expect wrapper object
    $jsonBody = $Body | ConvertTo-Json -Depth 10 [-AsArray]
    Write-Verbose "Body: $jsonBody"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        
        if ($PassThru) {
            return $response
        }
        else {
            if ($response.{collectionKey}) {
                return $response.{collectionKey}
            } else {
                return $response
            }
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            Write-Error $_.Exception.Message
        }
    }
}
```

### 5. Standard PUT Function Template

```powershell
function Set-{ResourceName} {
    <#
    .SYNOPSIS
        Updates {description} [PUT {endpoint}/{idParameter}]
    
    .DESCRIPTION
        PUT {endpoint}/{idParameter}
        Updates an existing {resource} record.
        
        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes
    
    .PARAMETER {IdParameter}
        Required. The ID of the {resource} to update.
        Used in path: {endpoint}/{idParameter}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        ${IdParameter},  # No type constraint
        
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        ${ResourceParameter},  # No type constraint
        
        [string]$Select,
        
        [string]$BaseUrl = ($env:{API}_API_URL ?? $env:DOMAIN ?? 'http://localhost:9950'),
        [string]$Token = ($env:TRUCKMATE_API_KEY ?? $env:TRUCKMATE_API_TOKEN ?? $env:API_TOKEN),
        [switch]$PassThru
    )
    
    if (-not $Token) {
        throw "No authentication token provided. Set TRUCKMATE_API_KEY environment variable or pass -Token parameter."
    }
    
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    
    $BaseUrl = $BaseUrl.TrimEnd('/')
    
    $queryParams = @()
    if ($Select) { $queryParams += "`$select=$Select" }
    
    $queryString = if ($queryParams.Count -gt 0) { "?" + ($queryParams -join '&') } else { "" }
    $uri = "$BaseUrl{endpoint}/${IdParameter}$queryString"
    
    # Always add verbose logging for diagnostics
    Write-Verbose "PUT $uri"
    
    $jsonBody = ${ResourceParameter} | ConvertTo-Json -Depth 10
    Write-Verbose "Body: $jsonBody"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $jsonBody
        
        if ($PassThru) {
            return $response
        }
        else {
            if ($response.{singularKey}) {
                return $response.{singularKey}
            } else {
                return $response
            }
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            Write-Error "API Returned an error"
            $_.ErrorDetails.Message
        }
        else {
            Write-Error $_.Exception.Message
        }
    }
}
```

## Special Cases and Patterns

### Verbose Logging for Diagnostics
**Always include verbose logging** in all functions for better debugging:

```powershell
# For GET requests
Write-Verbose "GET $uri"

# For POST/PUT/PATCH/DELETE requests with body
Write-Verbose "POST $uri"    # or PUT/PATCH/DELETE
Write-Verbose "Body: $jsonBody"
```

**Why this matters:**
- Provides visibility into actual API calls being made
- Essential for debugging test failures
- Shows exact request structure sent to API
- Use consistent format: `"{METHOD} {URI}"` and `"Body: {JSON}"`
- The body should show the actual JSON being sent (after ConvertTo-Json)

### Query Parameter Naming
**Use lowercase parameter names** for query strings:
- `limit` not `$top` or `top`
- `offset` not `skip`
- `expand` not `$expand` (no $ prefix in actual query)

OData parameters still use `$` prefix:
- `$filter` 
- `$select`
- `$orderby`

```powershell
# Correct
if ($Limit) { $queryParams += "limit=$Limit" }
if ($Offset) { $queryParams += "offset=$Offset" }
if ($Filter) { $queryParams += "`$filter=$Filter" }  # Note the backtick
```

### ArgumentCompleter (NOT ValidateSet)
For parameters with known valid values, use ArgumentCompleter for tab completion without validation:

```powershell
[ArgumentCompleter({ @('value1','value2','value3') })]
[string]$Parameter,
```

**Why not ValidateSet?**
- ValidateSet blocks API testing with invalid values
- ArgumentCompleter provides convenience without restriction
- Allows testing API's validation behavior

### Required Query Parameters
Some endpoints have required query parameters (e.g., `location` for `/currencyRates`):

```powershell
# DON'T use [Parameter(Mandatory=$true)] - blocks API testing
# DO use ArgumentCompleter and allow API to validate
[ArgumentCompleter({ @('generalLedger','driverPay') })]
[string]$Location,

# In query building:
if ($Location) { $queryParams += "location=$Location" }
```

This allows testing:
- Missing required parameter → API returns `missingRequiredField`
- Invalid value → API returns `invalidEnum`
- Valid value → API returns data

### Direct Array vs Wrapper Object
Check OpenAPI spec for request body format:

**Direct Array** (e.g., `/apInvoices`):
```powershell
# Body is array directly
$Body | ConvertTo-Json -Depth 10 -AsArray
```

**Wrapper Object** (e.g., `/orders`):
```powershell
# Body is { orders: [...] }
$Body | ConvertTo-Json -Depth 10
```

### Response Unwrapping
Standard pattern for unwrapping API responses:

```powershell
# Collection endpoint
if ($response.apInvoices) {
    return $response.apInvoices
} else {
    return $response
}

# Single item endpoint
if ($response.apInvoice) {
    return $response.apInvoice
} else {
    return $response
}
```

## File Organization

### Directory Structure
```
artFinance/
├── apInvoices/
│   ├── Get-ApInvoices.Public.ps1
│   ├── New-ApInvoice.Public.ps1
│   └── Set-ApInvoice.Public.ps1
├── cashReceipts/
│   ├── Get-CashReceipts.Public.ps1
│   ├── New-CashReceipt.Public.ps1
│   └── Set-CashReceipt.Public.ps1
└── artFinance.psm1
```

### Naming Convention
- File: `{Verb}-{ResourceName}.Public.ps1`
- Function: `{Verb}-{ResourceName}`
- Directory: camelCase of resource name (first letter lowercase)

## Testing New Functions

### Basic Tests
```powershell
# 1. Load module
Import-Module artFinance -Force

# 2. Test collection query
Get-ApInvoices -Limit 2 | Format-Table

# 3. Test by ID (if supported)
Get-ApInvoices -ApInvoiceId 123

# 4. Test error handling
Get-ApInvoices -Limit 'invalid' 2>$null

# 5. Test required parameters (if any)
Get-CurrencyRates -Limit 1 2>$null  # Should get missingRequiredField
```

### Verification Checklist
- [ ] Function loads without errors
- [ ] Basic query returns data
- [ ] Data is properly unwrapped (not wrapped in response object)
- [ ] Filter parameter works
- [ ] Select parameter works
- [ ] Pagination (Limit/Offset) works
- [ ] Error returns JSON string (not throwing exception)
- [ ] Invalid types reach API (not blocked by PowerShell)

## Common Patterns by API

### TM API (`artTM` module)
- Base URL: `$env:TM_API_URL`
- Common parameters: `filter`, `select`, `orderby`, `limit`, `offset`, `expand`, `type`
- Path parameters use IDs like `orderId`, `orderDetailId`

### Finance API (`artFinance` module)
- Base URL: `$env:FINANCE_API_URL`
- Common parameters: `filter`, `select`, `orderby`, `limit`, `offset`
- Often NO expand parameter (check spec!)
- Some endpoints have required query params (e.g., `location` for currency rates)

### MasterData API (`artMasterData` module)
- Base URL: `$env:MASTERDATA_API_URL`
- Common parameters: `filter`, `select`, `orderby`, `limit`, `offset`, `expand`
- Path parameters use IDs like `clientId`, `vendorId`

## Memory Patterns

### Reserved PowerShell Variables
**NEVER use these as variable names:**
- `$error` - Reserved automatic variable (session error array)
- Use alternatives: `$errorObj`, `$apiError`, `$errorResponse`, `$err`

### PowerShell Syntax
```powershell
# String multiplication MUST use parentheses
Write-Host ("=" * 80) -ForegroundColor Cyan  # ✓ CORRECT
Write-Host "=" * 80 -ForegroundColor Cyan    # ✗ WRONG
```

## Batch Generation
For creating many similar functions efficiently, use a generator script pattern:

1. Create template with placeholders: `{NAME}`, `{PATH}`, `{COLLECTION_KEY}`
2. Define array of function metadata
3. Loop and replace placeholders
4. Write files to appropriate directories
5. Delete generator script after verification

**Important:** Always use single braces `{}` in templates, not double `{{}}`.

## Version Information
- Created: 2025-01-20
- Last Updated: 2025-01-20
- Module Versions: artTM, artFinance, artMasterData
- Based on: Finance API v25.4.75.4, TM API v25.4.79.1

