# PUT Endpoint Scaffolding - Quick Start Guide
**Finance API - TDD Approach**

## Overview

This guide shows how to scaffold a complete PUT endpoint test structure using the `New-PutEndpointScaffold.ps1` script.

---

## Files Created

1. **`PUT-Endpoint-Template-Analysis.md`** - Analysis of existing PUT patterns
2. **`New-PutEndpointScaffold.ps1`** - PowerShell script to generate scaffolds
3. **`PUT-{endpoint}-Scaffold.json`** - Generated Postman collection structure

---

## Quick Start: PUT apInvoices/:apInvoiceId (TM-180924)

### Step 1: Review Analysis

See `PUT-Endpoint-Template-Analysis.md` for:
- Common patterns across existing PUT endpoints
- Standard test request types
- Naming conventions
- Variable setup requirements

### Step 2: Generate Scaffold

```powershell
$apiKey = "PMAK-67a3fbc01f830c0001362e8f-..."
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"

# Define custom success tests
$successTests = @(
    "minimal fields",
    "Request body based on openAPI",
    "`$select",
    "blank string",
    "vendor update",
    "invoice date update",
    "amounts update"
)

# Define custom error tests
$errorTests = @(
    "invoice is posted - no update allowed",
    "invalid vendorId",
    "invalid glAccount",
    "duplicate invoice number",
    "random invalidDBValue",
    "409 - Resource Conflict"
)

# Generate scaffold (dry run first)
.\New-PutEndpointScaffold.ps1 `
    -ApiKey $apiKey `
    -CollectionUid $collectionUid `
    -EndpointName "apInvoices" `
    -ResourceIdName "apInvoiceId" `
    -SuccessTests $successTests `
    -ErrorTests $errorTests `
    -DryRun
```

### Step 3: Review Generated Structure

The script creates:

```
📁 apInvoiceId
  📁 PUT
    📁 200
      • minimal fields
      • Request body based on openAPI
      • $select
      • blank string
      • vendor update
      • invoice date update
      • amounts update
    📁 4xx
      📁 invalidBusinessLogic
        • invoice is posted - no update allowed
        • invalid vendorId
        • invalid glAccount
        • duplicate invoice number
        • random invalidDBValue
        • 409 - Resource Conflict
```

**Output**: `postmanAPI\PUT-apInvoices-Scaffold.json`

### Step 4: Import into Postman

#### Option A: Manual Import
1. Open Postman
2. Navigate to "Finance Functional Tests" collection
3. Find the `apInvoices` folder
4. Import the `PUT-apInvoices-Scaffold.json` file

#### Option B: Programmatic Import (future enhancement)
Use Postman API to directly add folders/requests to the collection.

### Step 5: Customize Template Requests

The generated requests include TODO placeholders. Update:

#### 1. **minimal fields** request
```json
{
    // TODO: Set up test data
    // pm.globals.set('apInvoiceId', 123);
}
```

Change to:
```javascript
// Use existing cached data
const apInvoiceId = pm.variables.get('AP_INVOICE_ID');
pm.globals.set('temp_apInvoiceId', apInvoiceId);
```

#### 2. **Request body based on openAPI**
```json
{
    // TODO: Add full OpenAPI schema fields
    "field1": "value1",
    "field2": 123
}
```

Change to actual OpenAPI fields:
```json
{
    "vendorId": "{{VENDOR_ID}}",
    "invoiceNumber": "INV-{{$timestamp}}",
    "invoiceDate": "{{$isoTimestamp}}",
    "invoiceAmount": 1000.00,
    "glAccount": "{{GL_ACCOUNT}}"
}
```

#### 3. **Error test scripts**
```javascript
tm_utils.testInvalidBusinessLogicResponse("Expected error message for invoice is posted - no update allowed");
```

Change to:
```javascript
tm_utils.testInvalidBusinessLogicResponse("Cannot update a posted invoice");
```

### Step 6: Set Up Variables

Add to Finance collection or environment:

#### Collection Variables
```javascript
// Existing for tests
AP_INVOICE_ID = 2  // or appropriate test invoice
VENDOR_ID = 1
GL_ACCOUNT = "00-5000"
```

#### Pre-request Script (folder-level)
```javascript
// Create a test invoice for PUT tests
if (!pm.variables.get('temp_apInvoiceId')) {
    const postBody = {
        vendorId: pm.variables.get('VENDOR_ID'),
        invoiceNumber: `TEST-INV-${Date.now()}`,
        invoiceDate: new Date().toISOString().split('T')[0],
        invoiceAmount: 100.00
    };
    
    pm.sendRequest({
        url: `${pm.environment.get('DOMAIN')}/apInvoices`,
        method: 'POST',
        header: {
            'Authorization': `Bearer ${pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')}`,
            'Content-Type': 'application/json'
        },
        body: {
            mode: 'raw',
            raw: JSON.stringify([postBody])
        }
    }, (err, response) => {
        if (err) {
            console.error('Failed to create test invoice:', err);
            return;
        }
        const jsonData = response.json();
        pm.globals.set('temp_apInvoiceId', jsonData.apInvoices[0].apInvoiceId);
    });
}
```

### Step 7: Run Tests

1. **Run individual requests** to verify structure
2. **Run 200 folder** to test success scenarios
3. **Run 4xx folder** to test error handling
4. **Run full PUT folder** for complete validation

---

## Script Parameters

### Required
- **`-ApiKey`**: Postman API key
- **`-CollectionUid`**: Target collection UID
- **`-EndpointName`**: API endpoint name (e.g., "apInvoices")
- **`-ResourceIdName`**: Resource ID parameter name (e.g., "apInvoiceId")

### Optional
- **`-SuccessTests`**: Array of success test names (default: minimal, openAPI, $select, blank string)
- **`-ErrorTests`**: Array of error test names (default: invalidDBValue, 409 conflict)
- **`-ParentFolderId`**: Postman folder ID to nest under
- **`-DryRun`**: Preview only, don't create

---

## Default Tests Included

### Success (200)
1. **minimal fields** - Required fields only
2. **Request body based on openAPI** - Full schema
3. **$select** - Field selection
4. **blank string** - Empty string handling

### Errors (4xx)
1. **random invalidDBValue** - Invalid DB references
2. **409 - Resource Conflict** - Concurrent updates

### Custom Tests
Add via `-SuccessTests` and `-ErrorTests` parameters. The script will generate appropriate templates.

---

## Customization Tips

### Adding Business-Specific Tests

```powershell
$successTests = @(
    "minimal fields",
    "update with sub-resources",    # Custom
    "partial update",                # Custom
    "bulk update"                    # Custom
)
```

### Adding Validation Tests

```powershell
$errorTests = @(
    "missing required field",
    "exceeds max length",
    "invalid date format",
    "business rule violation"
)
```

---

## Next Steps After Scaffolding

1. ✅ Generate scaffold with `New-PutEndpointScaffold.ps1`
2. ⏳ Import into Postman collection
3. ⏳ Customize request bodies with actual fields
4. ⏳ Update pre-request scripts for data setup
5. ⏳ Update test scripts with specific validations
6. ⏳ Set up required variables
7. ⏳ Run tests to verify structure
8. ⏳ Implement PUT endpoint in backend
9. ⏳ Run tests against implementation
10. ⏳ Refine tests based on results

---

## TDD Workflow

```
1. Generate Scaffold (Tests First)
   ↓
2. Review & Customize Tests
   ↓
3. Run Tests (Should Fail - No Implementation)
   ↓
4. Implement PUT Endpoint
   ↓
5. Run Tests (Should Pass)
   ↓
6. Refine Implementation & Tests
```

---

## Example: Complete PUT apInvoices Setup

### Variables Needed
```javascript
// Collection/Environment
DOMAIN = "https://tde-truckmate.tmwcloud.com/fin/finance"
TRUCKMATE_API_KEY = "9ade1b0487df4d67dcdc501eaa317b91"
AP_INVOICE_ID = 2
VENDOR_ID = 1
GL_ACCOUNT = "00-5000"

// Temporary (set in pre-request)
temp_apInvoiceId = (created dynamically)
temp_invoiceNumber = (generated)
```

### Sample Request Bodies

#### Minimal Fields
```json
{
    "invoiceAmount": 150.00
}
```

#### Full Update
```json
{
    "vendorId": {{VENDOR_ID}},
    "invoiceNumber": "INV-{{$timestamp}}",
    "invoiceDate": "{{$isoTimestamp}}",
    "invoiceAmount": 1000.00,
    "glAccount": "{{GL_ACCOUNT}}",
    "description": "Updated invoice"
}
```

#### Vendor Update
```json
{
    "vendorId": {{NEW_VENDOR_ID}}
}
```

---

## Troubleshooting

### Issue: Generated JSON file is empty
**Solution**: Check PowerShell execution policy and permissions.

### Issue: Requests don't appear in Postman
**Solution**: Ensure you're importing into the correct collection and folder.

### Issue: Tests fail immediately
**Solution**: Verify variables are set (DOMAIN, API_KEY, resource IDs).

### Issue: Pre-request script errors
**Solution**: Check that required variables exist before using them.

---

## Related Files

- `PUT-Endpoint-Template-Analysis.md` - Detailed pattern analysis
- `New-PutEndpointScaffold.ps1` - Scaffolding script
- `PUT-apInvoices-Scaffold.json` - Generated scaffold for apInvoices
- `Update-PostmanRequestName.ps1` - Update request names after creation

---

## Future Enhancements

- [ ] Direct Postman API integration (skip manual import)
- [ ] Variable setup automation
- [ ] Test data generation
- [ ] OpenAPI schema import
- [ ] Batch scaffolding for multiple endpoints

---

**Generated**: October 6, 2025  
**For**: TM-180924 - Finance - Add PUT apInvoices/apInvoiceId

