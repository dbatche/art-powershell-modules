# POST Endpoint Test Template Analysis
## Finance Functional Tests Collection

**Date**: October 9, 2025  
**Collection**: Finance Functional Tests  
**Analysis Scope**: POST endpoint patterns and test structures

---

## Executive Summary

Analyzed **110 POST requests** across **8 major resources** in the Finance Functional Tests collection to identify common patterns, folder structures, and testing approaches for POST endpoint scaffolding.

### Key Findings

1. **Status Code**: POST endpoints return **201 Created** (not 200 OK)
2. **Request Body**: Arrays of objects (not single objects)
3. **Response Format**: Wrapped in resource name (e.g., `{apInvoices: [...]}}`)
4. **Folder Structure**: Simpler than PUT (201 and 4xx only)
5. **Test Scripts**: Focused on creation validation and field matching

---

## POST Resources Distribution

| Resource | POST Requests | Notes |
|----------|---------------|-------|
| checks | 29 | Most complex POST, includes bills sub-resource |
| apInvoices | 20 | Main resource + sub-resources (expenses, ista, apDriverDeductions) |
| driverPayments | 17 | Simple creation pattern |
| driverDeductions | 11 | Minimal fields pattern |
| glAccounts | 11 | Array support, $select tests |
| taxes | 9 | Standard pattern |
| currencyRates | 8 | Simple creation |
| cashReceipts | 5 | Minimal POST tests |

---

## Folder Structure Pattern

### Standard POST Folder Hierarchy

```
ResourceName/
├── POST/
│   ├── 201/                          📜 Folder test script (34 lines)
│   │   ├── minimum fields            (most important test)
│   │   ├── all fields
│   │   ├── array                     (tests batch creation)
│   │   ├── $select                   (tests field filtering)
│   │   └── [business logic tests]
│   └── 4xx/
│       ├── 400 - InvalidDBValue/
│       │   └── invalid [fieldName]
│       └── 400 - invalidBusinessLogic/
│           └── [business rule violations]
└── :resourceId/
    └── SubResource/
        └── POST/
            ├── 201/                  📜 Folder test script (13 lines)
            │   ├── minimum fields
            │   ├── array
            │   └── $select
            └── 4xx/
                └── 400 - invalidDBValue/
```

### Key Differences from PUT

| Aspect | PUT | POST |
|--------|-----|------|
| **Success Code** | 200 OK | 201 Created |
| **Folder Levels** | 200, 400, 404 | 201, 4xx |
| **Request Body** | Single object | Array of objects |
| **Response Validation** | Field comparison | Array validation |
| **Common Tests** | Field updates | Creation scenarios |

---

## Test Categories

### 1. Success Tests (201 Folder)

#### Common Test Types

1. **minimum fields** - Most critical test
   - Tests resource creation with only required fields
   - Validates auto-populated fields
   - Confirms default values

2. **all fields**
   - Comprehensive field coverage
   - Tests optional field handling
   - Validates complex scenarios

3. **array**
   - Tests batch creation (POST multiple items)
   - Validates array handling
   - Tests transaction boundaries

4. **$select**
   - Tests OData field selection
   - Validates response filtering
   - Uses pre-request to add `?$select=field1,field2`

5. **Business Logic Tests**
   - Resource-specific scenarios
   - Examples: "Direct Deposit check", "bills", "overpayment"

### 2. Error Tests (4xx Folder)

#### Sub-folders

1. **400 - InvalidDBValue**
   - Invalid foreign key references
   - Examples: "invalid vendorId", "invalid glAccountId"
   - Tests database constraint violations

2. **400 - invalidBusinessLogic**
   - Business rule violations
   - Examples: "duplicate bills not allowed", "check amount cap"
   - Tests application-level validation

---

## Script Analysis

### Collection-Level Scripts

**Same as PUT endpoints** - shared across all HTTP methods:

- **Pre-request Script**: 
  - Authentication (Bearer token generation)
  - Package loading (@trimble-inc/utils_finance)
  - Cache management
  - Tag filtering support

- **Test Script**: None at collection level

### Folder-Level Scripts

#### Main Resource POST/201 Folder

**Lines**: ~34 lines  
**Purpose**: Validate creation response

```javascript
if (utils.testStatusCode(201).status) {
    utils.validateJsonSchemaIfCode(201);
    
    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter('resourceName');
    }
    else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);

        // Validate array response
        if (responseJson.resourceName && responseJson.resourceName.length > 0) {
            utils.validateFieldValuesIfCode(201, 
                responseJson.resourceName[0], 
                jsonRequest[0]);
        }
    }
}
```

**Validations**:
1. ✅ Status code is 201
2. ✅ Response matches JSON schema
3. ✅ $select parameter works if used
4. ✅ Response fields match request fields
5. ✅ Auto-populated fields are present (ID, timestamps, etc.)

#### Sub-Resource POST/201 Folder

**Lines**: ~13 lines  
**Purpose**: Simpler validation for sub-resources

```javascript
if (utils.testStatusCode(201).status) {
    utils.validateJsonSchemaIfCode(201);

     if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter('subResourceName');
    }
    else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);

        utils.validateFieldValuesIfCode(201, 
            responseJson.subResources[0], 
            jsonRequest[0]);
    }
}
```

**Key Difference**: No conditional check for array existence (assumes success)

### Request-Level Scripts

#### Typical Pre-request Script

**Lines**: 15-30 lines  
**Purpose**: Setup test data

```javascript
// Set parent resource ID if sub-resource
pm.variables.set('resourceId', someExistingId);

// Build request body
const requestBody = [{
    field1: "test value",
    field2: 123,
    field3: "2025-10-09T12:00:00Z"
    // ... minimal or all fields
}];

pm.request.body.raw = JSON.stringify(requestBody);
```

**Common Patterns**:
- Array body (even for single item)
- Date fields in ISO 8601 format
- Foreign keys from environment/global variables
- Optional: Add `?$select=` query parameter

#### Typical Test Script

**Lines**: 1-3 lines  
**Purpose**: Request-specific validation

```javascript
pm.test("Expected [specific business logic]", function() {
    // Custom validation beyond folder-level checks
});
```

**Usually minimal** because folder-level script handles most validation.

---

## Response Patterns

### 201 Success Response

```json
{
  "resourceName": [
    {
      "resourceId": 12345,
      "field1": "value1",
      "field2": "value2",
      "createdDate": "2025-10-09T12:34:56Z",
      "createdBy": "API_USER",
      // ... all fields including auto-populated
    }
  ],
  "@odata.context": "...",
  "href": "...",
  "offset": 0,
  "limit": 100
}
```

**Key Characteristics**:
- Array wrapped in resource name property
- Includes auto-populated fields (IDs, timestamps)
- OData metadata properties
- All fields from request + generated fields

### 400 Error Response

**Expected (API Standards)**:
```json
{
  "type": "https://developer.trimble.com/docs/truckmate/errors",
  "title": "Invalid field value.",
  "status": 400,
  "errors": [
    {
      "code": "invalidDBValue",
      "description": "The vendorId field is invalid.",
      "type": "...",
      "title": "Invalid vendorId"
    }
  ]
}
```

**Actual (Legacy - Being Fixed)**:
```json
{
  "errorCode": 0,
  "errorText": "Invalid Request"
}
```

⚠️ **Note**: Many POST endpoints still use legacy error format (TM-180940, TM-180941, etc.)

---

## Request Body Patterns

### Array-Based Requests

**All POST requests use arrays**, even for single item.

**Why?** POST only targets **collection endpoints**, not individual item endpoints:
- ✅ `POST /resourceName` - Create new items in collection
- ✅ `POST /parent/:id/subResource` - Create new sub-items in collection
- ❌ `POST /resourceName/:id` - **Never used** (can't POST to existing item)

Since POST always targets collections (which naturally contain multiple items), the request body is always an array, even when creating just one item:

```json
[
  {
    "field1": "value1",
    "field2": "value2"
  }
]
```

**NOT**:
```json
{
  "field1": "value1",
  "field2": "value2"
}
```

This is fundamentally different from PUT, which targets individual items and uses single objects.

### Field Types

| Type | Format | Example |
|------|--------|---------|
| **String** | Plain text | `"Test Value"` |
| **Number** | Integer or decimal | `123.45` |
| **Date** | ISO 8601 | `"2025-10-09T12:00:00Z"` |
| **Boolean** | String | `"True"` or `"False"` |
| **Foreign Key** | String/Integer | `"VENDOR123"` or `12345` |

⚠️ **Note**: Booleans are often strings, not native JSON booleans!

---

## Test Data Strategy

### Required Field Identification

From OpenAPI spec:
```javascript
$schema = $openapiSpec.components.schemas['PostResourceNameDto'];
$requiredFields = $schema.required; // Array of field names
```

Many POST endpoints have **NO required fields**!

### Minimal Fields Test

**Purpose**: Test creation with bare minimum data

**Strategy**:
1. Check OpenAPI for required fields
2. Add business-critical fields (even if not required)
3. Validate auto-population of optional fields

**Example (apInvoices)**:
```json
[{
  "vendorId": "VENDOR123",
  "invoiceNumber": "INV-001",
  "invoiceDate": "2025-10-09T00:00:00Z"
}]
```

### All Fields Test

**Purpose**: Comprehensive field coverage

**Strategy**:
1. Include all documented fields from OpenAPI
2. Use valid test data for each field type
3. Test field type conversions
4. Validate complex scenarios

---

## Common Test Patterns

### Pattern 1: Basic Creation

**Folder**: `POST/201`  
**Test**: `minimum fields`

```javascript
// Pre-request
const body = [{
    requiredField1: "value1",
    requiredField2: "value2"
}];
pm.request.body.raw = JSON.stringify(body);

// Test (minimal - folder handles validation)
// Usually just 1 line or none
```

### Pattern 2: Array Creation

**Folder**: `POST/201`  
**Test**: `array`

```javascript
// Pre-request
const body = [
    { field1: "value1" },
    { field1: "value2" },
    { field1: "value3" }
];
pm.request.body.raw = JSON.stringify(body);

// Test
pm.test("Multiple items created", function() {
    const response = pm.response.json();
    pm.expect(response.resourceName).to.have.lengthOf(3);
});
```

### Pattern 3: $select Parameter

**Folder**: `POST/201`  
**Test**: `$select`

```javascript
// Pre-request
pm.request.url.addQueryParams('$select=field1,field2,resourceId');

const body = [{ /* minimal fields */ }];
pm.request.body.raw = JSON.stringify(body);

// Test (folder script validates $select automatically)
```

### Pattern 4: Invalid Foreign Key

**Folder**: `POST/4xx/400 - InvalidDBValue`  
**Test**: `invalid vendorId`

```javascript
// Pre-request
const body = [{
    vendorId: "INVALID_VENDOR_99999"
}];
pm.request.body.raw = JSON.stringify(body);

// Test
pm.test("Expected invalid vendorId error", function() {
    const response = pm.response.json();
    pm.expect(response.errors[0].code).to.equal("invalidDBValue");
});
```

### Pattern 5: Business Rule Violation

**Folder**: `POST/4xx/400 - invalidBusinessLogic`  
**Test**: `duplicate bills not allowed`

```javascript
// Pre-request (create once first)
// Then attempt to create again

const body = [{
    billNumber: pm.globals.get('existingBillNumber')
}];
pm.request.body.raw = JSON.stringify(body);

// Test
pm.test("Expected duplicate bill error", function() {
    const response = pm.response.json();
    pm.expect(response.errors[0].code).to.equal("invalidBusinessLogic");
});
```

---

## Sub-Resource POST Pattern

### Differences from Main Resource

1. **URL Path**: Includes parent resource ID
   - Format: `/resourceName/:resourceId/subResourceName`
   - Example: `/apInvoices/123/expenses`

2. **Pre-request Setup**: Must ensure parent exists
   ```javascript
   // Get or create parent resource
   const parentId = pm.globals.get('apInvoiceId');
   pm.variables.set('apInvoiceId', parentId);
   ```

3. **Folder Script**: Simpler (13 lines vs 34 lines)

4. **Test Coverage**: Fewer business logic tests

### Common Sub-Resources with POST

- `apInvoices/:id/expenses`
- `apInvoices/:id/apDriverDeductions`
- `apInvoices/:id/ista`
- `checks/:id/bills`
- `fuelTaxes/:id/tripFuelPurchases` ⚠️ **No tests yet!**

---

## Scaffolding Implications

### Inputs Required

1. **Resource Name**: e.g., "tripFuelPurchases"
2. **Parent Resource**: e.g., "fuelTaxes" (if sub-resource)
3. **Parent ID Parameter**: e.g., "fuelTaxId"
4. **Success Tests**: List of scenario names
   - Default: ["minimum fields", "array", "$select"]
   - Custom: ["business logic scenario 1", ...]
5. **Error Tests**: List of error scenarios
   - InvalidDBValue: ["invalid field1", "invalid field2"]
   - InvalidBusinessLogic: ["rule violation 1", ...]

### Generated Structure

```
POST/
├── 201/                              [Folder with test script]
│   ├── minimum fields
│   ├── array
│   ├── $select
│   └── [custom success tests...]
└── 4xx/
    ├── 400 - InvalidDBValue/
    │   └── invalid [field]
    └── 400 - invalidBusinessLogic/
        └── [business rule]
```

### Script Templates

#### 201 Folder Test Script Template

```javascript
if (utils.testStatusCode(201).status) {
    utils.validateJsonSchemaIfCode(201);
    
    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter('{{resourceName}}');
    }
    else{
        let responseJson = pm.response.json();
        let jsonRequest = JSON.parse(pm.request.body.raw);

        if (responseJson.{{resourceName}} && responseJson.{{resourceName}}.length > 0) {
            utils.validateFieldValuesIfCode(201, 
                responseJson.{{resourceName}}[0], 
                jsonRequest[0]);
        } else {
            console.warn("The '{{resourceName}}' array is empty or missing.");
        }
    }
}
```

#### Request Pre-request Template

```javascript
// TODO: Set parent resource ID if sub-resource
{{#if isSubResource}}
const {{parentIdName}} = pm.globals.get('{{parentIdName}}') || {{defaultParentId}};
pm.variables.set('{{parentIdName}}', {{parentIdName}});
{{/if}}

// Build request body (array)
const requestBody = [{
    {{#each fields}}
    {{name}}: {{defaultValue}}, // {{type}}
    {{/each}}
}];

pm.request.body.raw = JSON.stringify(requestBody);
```

---

## OpenAPI Integration

### Schema Extraction

```powershell
$openapi = Invoke-RestMethod -Uri "$domain/openapi.json"
$postPath = $openapi.paths."/resourceName"
$requestSchema = $postPath.post.requestBody.content.'application/json'.schema

# Get the DTO name (usually an array wrapper)
$arraySchemaRef = $requestSchema.'$ref' -replace '#/components/schemas/', ''
$arraySchema = $openapi.components.schemas.$arraySchemaRef

# Get the actual item schema
$itemSchemaRef = $arraySchema.items.'$ref' -replace '#/components/schemas/', ''
$itemSchema = $openapi.components.schemas.$itemSchemaRef

# Extract properties
$fields = $itemSchema.properties.PSObject.Properties
$requiredFields = $itemSchema.required
```

### Field Default Values by Type

```powershell
function Get-DefaultValue {
    param($property)
    
    switch ($property.type) {
        "string" {
            if ($property.format -eq "date-time") {
                return '"2025-10-09T12:00:00Z"'
            }
            return '"TestValue"'
        }
        "number" { return '100' }
        "integer" { return '1' }
        "boolean" { return '"False"' }  # Note: Often string in TruckMate
        default { return 'null' }
    }
}
```

---

## Comparison with PUT Endpoints

| Feature | POST | PUT |
|---------|------|-----|
| **Status Code** | 201 Created | 200 OK |
| **HTTP Semantics** | Create | Update |
| **Request Body** | Array of new items | Single item with updates |
| **Required Fields** | Usually minimal or none | Usually just ID |
| **Response** | Array with created items | Single updated item |
| **Folder Structure** | 201, 4xx | 200, 400, 404 |
| **404 Tests** | No (parent 404 instead) | Yes (resource not found) |
| **Test Complexity** | Creation scenarios | Update scenarios |
| **Script Size (201/200)** | 34 lines (main), 13 (sub) | ~20 lines |

---

## Recommendations

### For Scaffolding Script

1. **Default to standard structure**:
   - 201 folder with 3 default tests
   - 4xx folder with InvalidDBValue and InvalidBusinessLogic sub-folders

2. **Auto-generate from OpenAPI**:
   - Extract field names and types
   - Generate default test data
   - Create field validation tests

3. **Parameterize for flexibility**:
   - Allow custom success test names
   - Support sub-resource pattern
   - Enable/disable $select and array tests

4. **Include TODO markers**:
   - Business logic placeholders
   - Custom validation areas
   - Parent resource setup (for sub-resources)

### For Manual Testing

1. **Start with minimal fields test** - Most important
2. **Add array test** - Validate batch operations
3. **Test $select** - Ensure OData support
4. **Add InvalidDBValue tests** for each foreign key
5. **Add InvalidBusinessLogic tests** for business rules

### For Documentation

1. Link to OpenAPI spec for field definitions
2. Document business rules that trigger errors
3. Maintain test data requirements
4. Track legacy error format endpoints

---

## Known Issues

### Legacy Error Format

**Affected Endpoints** (partial list):
- POST /fuelTaxes/:fuelTaxId/tripFuelPurchases (TM-180940)
- PUT /fuelTaxes/:fuelTaxId/tripFuelPurchases/:id (TM-180941)

**Issue**: Returns old TruckMate error format instead of API standards

**Impact**: Error validation tests will fail

**Status**: Under development, waiting for fix

---

## Next Steps

1. ✅ Complete POST endpoint analysis
2. ⏭️ Create POST scaffolding script
3. ⏭️ Test script with fuelTaxes/tripFuelPurchases
4. ⏭️ Document POST-specific patterns
5. ⏭️ Create quick-start guide for POST endpoints

---

**Document Version**: 1.0  
**Last Updated**: October 9, 2025  
**Author**: AI Assistant + Doug Batchelor

