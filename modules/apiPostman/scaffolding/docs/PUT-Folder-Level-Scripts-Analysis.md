# PUT Endpoint Folder-Level Scripts Analysis
**Finance API - Collection and Folder Scripts**

## Date
October 6, 2025

## Purpose
Document the folder-level and collection-level scripts used in PUT endpoint testing to ensure scaffolded endpoints include all necessary test infrastructure.

---

## Key Finding

**Individual request scripts are minimal** because **folder-level scripts do the heavy lifting!**

---

## Script Hierarchy

```
📁 Finance Functional Tests Collection
├── 🔧 Collection-Level PRE-REQUEST (635 lines)
├── ✅ Collection-Level TEST (229 lines)
│
└── 📁 {endpoint}
    └── 📁 {resourceId}
        └── 📁 PUT
            ├── 🔧 PUT Folder PRE-REQUEST (usually empty)
            ├── ✅ PUT Folder TEST (usually empty)
            │
            ├── 📁 200
            │   ├── 🔧 200 Folder PRE-REQUEST (usually empty)
            │   ├── ✅ 200 Folder TEST (**CRITICAL - validation logic**)
            │   └── 📄 Individual requests (minimal scripts)
            │
            └── 📁 4xx
                ├── 🔧 4xx Folder PRE-REQUEST (empty)
                ├── ✅ 4xx Folder TEST (empty)
                └── 📁 invalidBusinessLogic
                    └── 📄 Individual requests (use tm_utils functions)
```

---

## Analysis Summary

| Endpoint | PUT Folder Scripts | 200 Folder Scripts | 4xx Folder Scripts |
|----------|-------------------|-------------------|-------------------|
| currencyRates | ❌ NO | ✅ YES (test only) | ❌ NO |
| driverPayments | ⚠️ Empty | ✅ YES (test only) | ❌ NO |
| driverDeductions | ❌ NO | ✅ YES (test only) | ❌ NO |
| taxes | ❌ NO | ✅ YES (test only) | ❌ NO |

**Pattern**: The 200 folder test script handles all validation logic for success responses!

---

## Collection-Level Scripts

### Pre-request Script (635 lines)

**Purpose**: Setup global utilities, packages, and environment

**Key Components**:

```javascript
// 1. Tag filtering for test execution
pm.require('@trimble-inc/tags').tagFilter();

// 2. Clear variables for fresh state
pm.collectionVariables.clear();

// 3. Declare global utilities
utils = '';
tm_utils = '';

// 4. Additional setup and helper functions
// (schema caching, data setup, etc.)
```

**What it does**:
- Initializes testing environment
- Loads custom packages
- Clears stale variables
- Sets up test filtering by tags
- Declares global utility objects

### Test Script (229 lines)

**Purpose**: Load utilities and common test functions

**Key Components**:

```javascript
// 1. Load required packages
moment = require('moment');
lodash = require('lodash');

// 2. Load custom utility packages
eval(pm.globals.get('packages'));
utils = require('utils')(pm);
tm_utils = require('tm_utils')(pm);

// 3. Validate JSON response
utils.validJson();

// 4. Additional common validations
// (filters, schemas, etc.)
```

**What it does**:
- Loads moment.js and lodash
- Initializes `utils` and `tm_utils` packages
- Validates JSON response format
- Provides common test utilities

---

## 200 Folder Test Script (CRITICAL!)

### Purpose
**Validates ALL successful PUT requests** in the folder

### Common Pattern Across All Endpoints

```javascript
if (utils.testStatusCode(200).status) {
    // 1. Validate against JSON schema
    utils.validateJsonSchemaIfCode(200);

    // 2. Handle $select parameter
    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    } else {
        // 3. Parse request and response
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        
        // 4. Add resource ID from URL to request object
        jsonRequest.{resourceId} = parseInt(pm.request.url.path.at(-1));

        // 5. Validate request fields match response
        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

### Example: driverDeductions

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    }else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        jsonRequest.driverDeductionId = parseInt(pm.request.url.path.at(-1));

        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

### Example: driverPayments (with business logic)

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    }else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        jsonRequest.driverPaymentId = parseInt(pm.request.url.path.at(-1));

        // Special logic: taxable auto-populates from paymentCode
        if ((jsonRequest.paymentCode == pm.variables.get('DRIVER_PAY_CODE')) && (!jsonRequest.taxable)){
            jsonRequest.taxable = 'True';
        }

        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

### What This Script Does

1. **Status Code Validation**: Ensures response is 200 OK
2. **Schema Validation**: Validates response structure against OpenAPI schema
3. **$select Handling**: If `$select` query parameter present, validates only selected fields returned
4. **Field Value Validation**: Compares request body fields with response body fields
5. **Resource ID Injection**: Adds the resource ID from URL to request object for comparison
6. **Business Logic**: Some endpoints have special logic (e.g., auto-populated fields)

---

## Why This Matters for Scaffolding

### Individual Request Scripts Can Be Minimal

Because the 200 folder test script handles:
- ✅ Status code validation
- ✅ Schema validation
- ✅ Field value matching
- ✅ $select parameter handling

Individual requests only need:
- Custom pre-request setup (if needed)
- Specific business rule tests (for error cases)

### Error Requests Use tm_utils

4xx/invalidBusinessLogic requests use simple one-liners:

```javascript
tm_utils.testInvalidBusinessLogicResponse("Expected error message");
```

---

## Template for PUT Endpoints

### 200 Folder Test Script Template

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    }else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        
        // CUSTOMIZE: Set resource ID name
        jsonRequest.{resourceId} = parseInt(pm.request.url.path.at(-1));

        // CUSTOMIZE: Add any special business logic here
        // Example: Auto-populated fields, calculated values, etc.

        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

### For PUT apInvoices/:apInvoiceId

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    }else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);
        jsonRequest.apInvoiceId = parseInt(pm.request.url.path.at(-1));

        // Add any apInvoices-specific logic here
        // Example: auditNumber auto-generation, amount calculations, etc.

        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);
    }
}
```

---

## Validation Functions Explained

### utils.testStatusCode(200)
- Tests that HTTP status code is 200
- Returns object with `status` property (boolean)

### utils.validateJsonSchemaIfCode(200)
- Validates response against OpenAPI JSON schema
- Only runs if status code matches
- Checks all required fields, types, formats

### utils.validateSelectParameter(null)
- Validates that response only includes fields from `$select` query parameter
- Ensures API respects field selection

### utils.validateFieldValuesIfCode(200, responseJson, jsonRequest)
- Compares request body fields with response body fields
- Ensures PUT request actually updated the values
- Handles nested objects and arrays
- Ignores read-only fields

---

## Individual Request Scripts

### Success Requests (200 folder)
Most have **no test script** or minimal pre-request:

```javascript
// Pre-request (if needed)
pm.globals.set('temp_value', 'test-value');

// Test (usually empty - folder script handles it)
```

### Error Requests (4xx folder)
Simple validation with tm_utils:

```javascript
// Test script
tm_utils.testInvalidBusinessLogicResponse("Cannot update a posted invoice");
```

or

```javascript
// Test script
pm.test("Status is 409", () => pm.response.to.have.status(409));
```

---

## Impact on Scaffolding Script

### What Needs to Be Added

1. **200 Folder Test Script** ✅ REQUIRED
   - Copy template from above
   - Customize resource ID name
   - Add endpoint-specific business logic

2. **200 Folder Pre-request Script** ⚠️ OPTIONAL
   - Usually empty
   - Only add if folder-wide setup needed

3. **PUT Folder Scripts** ❌ NOT NEEDED
   - Can be empty
   - Collection-level scripts handle setup

4. **4xx Folder Scripts** ❌ NOT NEEDED
   - Individual requests handle their own validation

### Updated Scaffold Structure

```
📁 apInvoiceId
  📁 PUT
    ├── (no scripts needed)
    │
    ├── 📁 200
    │   ├── ✅ Test Script (REQUIRED - add validation logic)
    │   ├── (no pre-request needed)
    │   └── Individual requests (no scripts)
    │
    └── 📁 4xx
        ├── (no scripts needed)
        └── 📁 invalidBusinessLogic
            └── Individual requests (tm_utils one-liners)
```

---

## Checklist for PUT Endpoint Scaffold

- [ ] Collection-level scripts exist (inherited - no action)
- [ ] 200 folder has test script with:
  - [ ] Status code validation
  - [ ] Schema validation
  - [ ] $select handling
  - [ ] Field value validation
  - [ ] Resource ID injection
  - [ ] Endpoint-specific business logic
- [ ] Individual 200 requests have minimal/no scripts
- [ ] Individual 4xx requests use tm_utils
- [ ] PUT folder itself has no scripts
- [ ] 4xx folder has no scripts

---

## Example: Complete 200 Folder Setup

### Folder Properties
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

---

## Benefits of This Pattern

1. **DRY Principle**: Validation logic written once, applies to all requests
2. **Consistency**: All 200 responses validated the same way
3. **Maintainability**: Update one script vs. many individual scripts
4. **Readability**: Individual requests focus on test data, not validation
5. **Coverage**: Automatic schema and field validation for all success cases

---

## Next Steps

1. ✅ Update analysis document with folder-level patterns
2. ⏳ Update scaffolding script to include 200 folder test script
3. ⏳ Create template function for 200 folder script
4. ⏳ Test updated scaffold with apInvoices
5. ⏳ Update quick-start guide with folder script information

---

**Status**: ✅ Analysis Complete  
**Ready For**: Scaffolding script updates
