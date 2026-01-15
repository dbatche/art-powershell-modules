# PUT Scaffolding Script - Update Summary
**Folder-Level Scripts Added**

## Date
October 6, 2025

## What Was Added

### 1. Folder-Level Scripts Analysis
**File**: `PUT-Folder-Level-Scripts-Analysis.md`

Comprehensive documentation of:
- Collection-level scripts (635 lines pre-request, 229 lines test)
- Folder-level scripts for PUT endpoints
- Critical finding: **200 folder has the main validation test script**
- Common patterns across all endpoints

### 2. Updated Scaffolding Script
**File**: `New-PutEndpointScaffold.ps1`

Added new function `New-200FolderTestScript`:
```powershell
function New-200FolderTestScript {
    param([string]$ResourceIdName)
    
    return @(
        "if (utils.testStatusCode(200).status) {",
        "    utils.validateJsonSchemaIfCode(200);",
        "",
        "    if(pm.request.url.query.get('`$select')){",
        "        utils.validateSelectParameter(null);",
        "    }else{",
        "        let responseJson = pm.response.json();",
        "        let jsonRequest = JSON.parse(pm.request.body.raw);",
        "        jsonRequest.$ResourceIdName = parseInt(pm.request.url.path.at(-1));",
        "",
        "        // TODO: Add any endpoint-specific business logic here",
        "",
        "        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);",
        "    }",
        "}"
    )
}
```

---

## Critical 200 Folder Test Script

### What It Does

The 200 folder test script provides **automatic validation for ALL successful PUT requests** in the folder:

1. ✅ Validates status code is 200
2. ✅ Validates response against JSON schema
3. ✅ Handles `$select` query parameter
4. ✅ Compares request fields with response fields
5. ✅ Injects resource ID from URL path

### Why This Matters

Without this script:
- ❌ Each request needs its own validation logic
- ❌ Easy to miss validations
- ❌ Inconsistent testing across requests

With this script:
- ✅ Write validation logic once
- ✅ Applies to all 200 requests automatically
- ✅ Consistent validation across endpoint

---

## Template for Manual Addition

If the scaffolding script doesn't properly generate the 200 folder event, add manually:

### JSON Structure
```json
{
  "name": "200",
  "description": "Successful update tests",
  "event": [
    {
      "listen": "test",
      "script": {
        "type": "text/javascript",
        "exec": [
          "if (utils.testStatusCode(200).status) {",
          "    utils.validateJsonSchemaIfCode(200);",
          "",
          "    if(pm.request.url.query.get('$select')){",
          "        utils.validateSelectParameter(null);",
          "    }else{",
          "        let responseJson = pm.response.json();",
          "        let jsonRequest = JSON.parse(pm.request.body.raw);",
          "        jsonRequest.apInvoiceId = parseInt(pm.request.url.path.at(-1));",
          "",
          "        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);",
          "    }",
          "}"
        ]
      }
    }
  ],
  "item": [
    // ... individual requests here
  ]
}
```

### In Postman UI
1. Navigate to the `200` folder
2. Click the three dots (...)  next to folder name
3. Select "Edit"
4. Go to "Tests" tab
5. Paste the test script:

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    }else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        jsonRequest.apInvoiceId = parseInt(pm.request.url.path.at(-1));

        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

6. Save

---

## Customization for Different Endpoints

### Replace Resource ID Name

Change `apInvoiceId` to match your endpoint:

| Endpoint | Resource ID Name |
|----------|------------------|
| apInvoices | `apInvoiceId` |
| currencyRates | `currencyRateId` |
| driverDeductions | `driverDeductionId` |
| driverPayments | `driverPaymentId` |
| glAccounts | `glAccountId` |
| taxes | `taxId` |

### Add Business Logic

For endpoints with auto-populated fields, add logic before `validateFieldValuesIfCode`:

```javascript
// Example: driverPayments auto-populates taxable from paymentCode
if ((jsonRequest.paymentCode == pm.variables.get('DRIVER_PAY_CODE')) && (!jsonRequest.taxable)){
    jsonRequest.taxable = 'True';
}
```

---

## Files Updated

1. ✅ `PUT-Folder-Level-Scripts-Analysis.md` - New comprehensive analysis
2. ✅ `New-PutEndpointScaffold.ps1` - Updated with 200 folder script function
3. ✅ `PUT-Endpoint-Template-Analysis.md` - Original analysis (still relevant)
4. ✅ `PUT-Endpoint-Quick-Start.md` - Quick start guide (still relevant)
5. ⏳ Future: Fix JSON serialization issue for automatic inclusion

---

## Known Issue

**PowerShell ConvertTo-Json Limitation**: The `event` property at the 200 folder level may not serialize properly in the generated JSON file.

**Workaround**: Add the 200 folder test script manually in Postman UI after importing the scaffold.

**Fix Needed**: Update scaffolding script to use PSCustomObject or custom JSON serialization to ensure event property is properly included.

---

## Testing the 200 Folder Script

### Before Implementation (TDD)

1. Import scaffold with 200 folder script
2. Run any request in 200 folder
3. Tests should **fail** (endpoint not implemented yet)
4. Error messages show what validations are being checked

### After Implementation

1. Implement PUT endpoint in backend
2. Run requests in 200 folder
3. Tests should **pass**
4. All validations automatically applied

---

## Next Steps for TM-180924

1. ✅ Analysis complete
2. ✅ Scaffolding script updated
3. ⏳ Generate scaffold for PUT apInvoices
4. ⏳ Import into Postman
5. ⏳ **Add 200 folder test script manually** (if not in generated JSON)
6. ⏳ Customize request bodies
7. ⏳ Run tests (should fail - TDD)
8. ⏳ Implement PUT endpoint
9. ⏳ Run tests (should pass)

---

## Summary

**Major Improvement**: Discovered that folder-level test scripts are the key to efficient PUT endpoint testing!

- Individual requests can be minimal
- 200 folder handles all validation
- Consistent testing across all endpoints
- Follows existing Finance API patterns

**Status**: Ready to use with manual 200 folder script addition

**Recommendation**: For TM-180924, add the 200 folder test script manually in Postman UI after importing the generated scaffold.

---

**Updated**: October 6, 2025  
**For**: TM-180924 - Finance - Add PUT apInvoices/apInvoiceId
