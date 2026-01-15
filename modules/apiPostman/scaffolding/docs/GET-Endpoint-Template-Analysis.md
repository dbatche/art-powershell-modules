# GET Endpoint Test Template Analysis
## Finance Functional Tests Collection

**Date**: October 9, 2025  
**Collection**: Finance Functional Tests  
**Analysis Scope**: GET endpoint patterns and test structures

---

## Executive Summary

Analyzed **319 GET requests** across **10 major resources** in the Finance Functional Tests collection to identify common patterns, folder structures, and testing approaches for GET endpoint scaffolding.

### Key Findings

1. **Two Main Patterns**: Collection retrieval vs Individual item retrieval
2. **OData Heavy**: Extensive use of $filter, $select, $orderBy, $expand
3. **Status Code**: GET endpoints return **200 OK**
4. **Folder Structure**: Single 200 folder with query parameter sub-folders
5. **Script Complexity**: 40 lines (collection) to 15 lines (individual item)

---

## GET Resources Distribution

| Resource | GET Requests | Notes |
|----------|--------------|-------|
| interlinerPayables | 63 | Extensive $filter tests |
| apInvoices | 37 | Collection + sub-resources |
| fuelTaxes | 34 | Collection + sub-resources (tripSegments, tripFuelPurchases, tripWaypoints) |
| cashReceipts | 32 | Query parameters focus |
| checks | 22 | $filter variations |
| taxes | 19 | Standard pattern |
| currencyRates | 17 | Simple collection |
| driverPayments | 10 | Basic pattern |
| employeePayments | 10 | Basic pattern |
| glAccounts | 9 | Minimal tests |

**Total**: 319 GET requests

---

## GET Endpoint Patterns

### Pattern 1: Main Resource Collection
**Example**: `GET /apInvoices`

**URL Pattern**: `/resourceName`  
**Response**: Array of items wrapped in property  
**Typical Script Size**: 40 lines (folder)

### Pattern 2: Main Resource Individual
**Example**: `GET /apInvoices/:apInvoiceId`

**URL Pattern**: `/resourceName/:resourceId`  
**Response**: Single object  
**Typical Script Size**: 17 lines (folder)

### Pattern 3: Sub-Resource Collection
**Example**: `GET /apInvoices/:apInvoiceId/expenses`

**URL Pattern**: `/parentResource/:parentId/subResource`  
**Response**: Array of sub-resource items  
**Typical Script Size**: 21 lines (folder)

### Pattern 4: Sub-Resource Individual
**Example**: `GET /apInvoices/:apInvoiceId/expenses/:expenseId`

**URL Pattern**: `/parentResource/:parentId/subResource/:subResourceId`  
**Response**: Single sub-resource object  
**Typical Script Size**: 15 lines (folder)

---

## Folder Structure Pattern

### Main Resource Collection

```
ResourceName/
└── GET/
    └── 200/                          📜 Folder test script (40 lines)
        ├── resourceName              (basic collection retrieval)
        ├── $filter/
        │   ├── eq
        │   ├── ne
        │   ├── lt, gt, le, ge
        │   └── complex filters
        ├── $select
        ├── orderBy / $orderBy
        ├── expand/
        │   └── subResource1, subResource2...
        ├── Query Parameters/
        │   ├── Pagination - Limit
        │   ├── Pagination - Offset
        │   └── Limit and Offset
        └── [business-specific tests]
```

### Individual Item

```
ResourceName/
└── :resourceId/
    └── GET/
        └── 200/                      📜 Folder test script (17 lines)
            ├── resourceId            (basic item retrieval)
            ├── $select
            └── expand/ (sometimes)
                └── subResource...
```

### Sub-Resource Collection

```
ResourceName/
└── :resourceId/
    └── SubResourceName/
        └── GET/
            └── 200/                  📜 Folder test script (21 lines)
                ├── subResourceName   (basic collection)
                ├── $filter/
                │   └── eq
                ├── $select
                ├── orderBy
                ├── pagination
                └── expand/ (rare)
```

### Sub-Resource Individual

```
ResourceName/
└── :resourceId/
    └── SubResourceName/
        └── :subResourceId/
            └── GET/
                └── 200/              📜 Folder test script (15 lines)
                    ├── subResourceId
                    └── $select
```

---

## Test Categories

### OData Query Parameters

#### 1. $filter (61 tests across collection)

**Purpose**: Test OData filter expressions

**Common Operators**:
- `eq` - Equals
- `ne` - Not equals
- `lt` - Less than
- `gt` - Greater than
- `le` - Less than or equal
- `ge` - Greater than or equal
- `and` - Logical AND
- `or` - Logical OR

**Example Tests**:
```
vendorId eq 'VENDOR'
originalAmount gt 100
invoiceDate ge 2025-01-01T00:00:00Z
```

**Request-Level Script** (typical):
```javascript
if (pm.response.code == 200) {
    let responseJson = pm.response.json();
    utils.performFilterAssertion(
        responseJson.resourceName, 
        'fieldName', 
        { type: 'eq', args: ['VALUE'] }
    );
}
```

#### 2. $select (9 tests)

**Purpose**: Test OData field selection

**Pre-request Script**:
```javascript
// Generate random properties from the schema
let randomProperties = utils.getRandomProperties('resourceName');

// Add to query string
pm.collectionVariables.set("temp_randomProperties", randomProperties);
```

**Folder Validation**: Handled by `utils.validateSelectParameter('resourceName')`

#### 3. $orderBy / orderBy (27 tests)

**Purpose**: Test sorting

**Common Patterns**:
- Single field ascending
- Single field descending
- Multiple fields

**Examples**:
```
$orderBy=invoiceDate desc
$orderBy=vendorId asc,invoiceNumber asc
```

**Request-Level Script** (typical):
```javascript
pm.test("Results ordered correctly", function() {
    let responseJson = pm.response.json();
    let items = responseJson.resourceName;
    
    for (let i = 0; i < items.length - 1; i++) {
        pm.expect(items[i].field).to.be.at.most(items[i+1].field);
    }
});
```

#### 4. $expand (10 tests)

**Purpose**: Test OData expansion of related entities

**Common Patterns**:
- Single expansion: `$expand=subResource`
- Multiple expansions: `$expand=subResource1,subResource2`

**Folder Validation**: Handled by `utils.validateExpandParameter('resourceName')`

**Test**:
```javascript
pm.test("Expanded data present", function() {
    let responseJson = pm.response.json();
    responseJson.resourceName.forEach(item => {
        pm.expect(item).to.have.property('subResource');
        pm.expect(item.subResource).to.be.an('array');
    });
});
```

### Pagination Tests (Query Parameters folder)

#### Limit
**Query**: `?limit=10`  
**Validates**: Maximum number of results returned

#### Offset
**Query**: `?offset=20`  
**Validates**: Skipping specified number of records

#### Limit and Offset
**Query**: `?limit=10&offset=20`  
**Validates**: Pagination combination

**Folder Validation**: Handled by `tm_utils.validatePagination('resourceName')`

---

## Script Analysis

### Collection-Level Scripts

**Same across all HTTP methods** (GET, POST, PUT, DELETE):

- **Pre-request Script**: 
  - Authentication (Bearer token)
  - Package loading
  - Cache management
  - Tag filtering

- **Test Script**: None

### Folder-Level Scripts

#### 1. Main Resource Collection GET/200

**Lines**: ~40 lines  
**Purpose**: Comprehensive validation for collection responses

```javascript
// Folder-Level Test Script for GET /resourceName (200 Success Response)
if (utils.testStatusCode(200).status) {

    // Validate JSON Schema for 200 Response
    utils.validateJsonSchemaIfCode(200);

    // Validate Pagination
    tm_utils.validatePagination('resourceName');

    // Parse API Response
    let responseJson = pm.response.json();

    // Validate $select Query Parameter
    if (pm.request.url.query.get('$select')) {
        utils.validateSelectParameter('resourceName');
    } else {

        // Ensure Unique ID Values
        const responseIDs = responseJson.resourceName.map(record => record.resourceId);
        const uniqueIDs = new Set(responseIDs);
        pm.test("Unique resourceId Values", function () {
            pm.expect(Array.from(uniqueIDs)).to.deep.equal(responseIDs);
        });

        // Validate expand Query Parameter
        let expand = pm.request.url.query.get('expand');
        if (expand) {
            utils.validateExpandParameter('resourceName');
        }

        // Custom Business Logic Validations
        // TODO: Add resource-specific validations here
        // Example: Validate positive amounts, date ranges, etc.

    }
}
```

**Validations**:
1. ✅ Status code 200
2. ✅ Response matches JSON schema
3. ✅ Pagination metadata correct
4. ✅ $select parameter works (if used)
5. ✅ $expand parameter works (if used)
6. ✅ All IDs are unique
7. ✅ Business logic rules (resource-specific)

#### 2. Main Resource Individual GET/200

**Lines**: ~17 lines  
**Purpose**: Validate single item retrieval

```javascript
// Validate Status Code and JSON Schema for 200 Response
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    // Parse API Response
    let responseJson = pm.response.json();

    // Check if $select Query Parameter is Used
    if (pm.request.url.query.get('$select')) {
        utils.validateSelectParameter(null); // null for single item
    } else {
        // Validate the returned ID matches the requested ID
        utils.validateFieldValuesIfCode(200, responseJson, {
            "resourceId": parseInt(pm.request.url.path.at(-1))
        });
    }
}
```

**Validations**:
1. ✅ Status code 200
2. ✅ Response matches JSON schema
3. ✅ $select parameter works (if used)
4. ✅ Returned ID matches URL parameter
5. ✅ Response is single object (not array)

#### 3. Sub-Resource Collection GET/200

**Lines**: ~21 lines  
**Purpose**: Validate sub-resource collection

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    tm_utils.validatePagination('subResourceName');

    let responseJson = pm.response.json();

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter('subResourceName');
    } else {
        // Ensure Unique IDs
        const responseIDs = responseJson.subResourceName.map(record => record.subResourceId);
        const uniqueIDs = new Set(responseIDs);
        pm.test("Unique IDs", function () {
            pm.expect(Array.from(uniqueIDs)).to.deep.equal(responseIDs);
        });
    }

    // Validate expand if present
    let expand = pm.request.url.query.get('expand');
    if(expand){
        utils.validateExpandParameter('subResourceName');
    }
}
```

**Validations**:
1. ✅ Status code 200
2. ✅ JSON schema validation
3. ✅ Pagination validation
4. ✅ $select parameter (if used)
5. ✅ Unique IDs in response
6. ✅ $expand parameter (if used)

#### 4. Sub-Resource Individual GET/200

**Lines**: ~15 lines  
**Purpose**: Validate single sub-resource item

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    
    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    } else {
        let responseJson = pm.response.json();
        utils.validateFieldValuesIfCode(200, responseJson, {
            "subResourceId": parseInt(pm.request.url.path.at(-1))
        });
    }

    // Validate expand if present
    let expand = pm.request.url.query.get('expand');
    if(expand){
        utils.validateExpandParameter(null);
    }
}
```

**Validations**:
1. ✅ Status code 200
2. ✅ JSON schema validation
3. ✅ $select parameter (if used)
4. ✅ ID matches URL parameter
5. ✅ $expand parameter (if used)

### Request-Level Scripts

Most GET request scripts are **minimal** (1-6 lines) because folder scripts handle most validation.

#### Common Patterns

**1. $filter validation**:
```javascript
if (pm.response.code == 200) {
    let responseJson = pm.response.json();
    utils.performFilterAssertion(
        responseJson.resourceName, 
        'fieldName', 
        { type: 'eq', args: ['VALUE'] }
    );
}
```

**2. $select pre-request**:
```javascript
let randomProperties = utils.getRandomProperties('resourceName');
pm.collectionVariables.set("temp_randomProperties", randomProperties);
```

**3. Basic test** (often none - folder handles everything)

**4. orderBy validation**:
```javascript
pm.test("Ordered by field desc", function() {
    let items = pm.response.json().resourceName;
    for (let i = 0; i < items.length - 1; i++) {
        pm.expect(items[i].field).to.be.at.least(items[i+1].field);
    }
});
```

---

## Response Patterns

### Collection Response

```json
{
  "resourceName": [
    {
      "resourceId": 1,
      "field1": "value1",
      "field2": "value2",
      "createdDate": "2025-10-09T12:34:56Z"
      // ... all fields
    },
    // ... more items
  ],
  "@odata.context": "...",
  "href": "https://api.example.com/resourceName",
  "offset": 0,
  "limit": 100,
  "count": 2,
  "sort": "",
  "filter": "",
  "select": ""
}
```

**Key Properties**:
- Array wrapped in resource name property
- OData context
- Pagination metadata (offset, limit, count)
- Query metadata (sort, filter, select)

### Individual Item Response

```json
{
  "resourceId": 1,
  "field1": "value1",
  "field2": "value2",
  "createdDate": "2025-10-09T12:34:56Z",
  // ... all fields
  "@odata.context": "..."
}
```

**Key Properties**:
- Single object (not array)
- All fields from schema
- OData context

### With $expand

```json
{
  "resourceName": [
    {
      "resourceId": 1,
      "field1": "value1",
      "subResource": [
        {
          "subResourceId": 1,
          "subField1": "subValue1"
        }
      ]
    }
  ]
}
```

### With $select

```json
{
  "resourceName": [
    {
      "resourceId": 1,
      "field1": "value1"
      // Only selected fields
    }
  ]
}
```

---

## OData Query Combinations

### Common Combinations

1. **Filtered + Sorted**:
   ```
   ?$filter=amount gt 100&$orderBy=amount desc
   ```

2. **Filtered + Paginated**:
   ```
   ?$filter=status eq 'Active'&limit=50&offset=0
   ```

3. **Expanded + Selected**:
   ```
   ?$expand=subResource&$select=id,name,subResource
   ```

4. **Complex Filter**:
   ```
   ?$filter=(amount gt 100 and amount lt 1000) or status eq 'Pending'
   ```

### Query Parameter Priority

Tests typically focus on **one query parameter** at a time, but folder scripts validate combinations.

---

## Script Complexity Comparison

| GET Pattern | Lines | Key Validations |
|-------------|-------|-----------------|
| Collection (Main) | 40 | Schema, pagination, $select, $expand, unique IDs, business logic |
| Individual (Main) | 17 | Schema, $select, ID match |
| Collection (Sub) | 21 | Schema, pagination, $select, $expand, unique IDs |
| Individual (Sub) | 15 | Schema, $select, $expand, ID match |

**Comparison with Other Methods**:

| Method | Main Resource Script Size |
|--------|---------------------------|
| GET Collection | 40 lines |
| POST 201 | 34 lines |
| PUT 200 | 20 lines |
| GET Individual | 17 lines |

GET collection scripts are the **most complex** due to:
- OData query parameter validation
- Pagination validation
- Unique ID checking
- Multiple business logic rules

---

## Scaffolding Implications

### Inputs Required

1. **Resource Name**: e.g., "tripFuelPurchases"
2. **Parent Resource** (if sub-resource): e.g., "fuelTaxes"
3. **Parent ID Parameter**: e.g., "fuelTaxId"
4. **Resource Type**: Collection, Individual, or Both
5. **OData Features**:
   - Support $filter (and which fields)
   - Support $select
   - Support $orderBy (and default field)
   - Support $expand (and which sub-resources)
6. **Business Logic Validations**: Custom rules (e.g., positive amounts)

### Generated Structure

For **Collection + Individual** pattern:

```
ResourceName/
└── GET/
    └── 200/                          [Folder with test script - 40 lines]
        ├── resourceName              (basic test)
        ├── $filter/
        │   ├── eq                    (per field)
        │   ├── ne
        │   ├── lt, gt
        │   └── complex
        ├── $select
        ├── orderBy
        ├── expand/
        │   └── [per sub-resource]
        └── Query Parameters/
            ├── Pagination - Limit
            ├── Pagination - Offset
            └── Limit and Offset

ResourceName/
└── :resourceId/
    └── GET/
        └── 200/                      [Folder with test script - 17 lines]
            ├── resourceId
            ├── $select
            └── expand/ (optional)
```

### Script Templates

#### Collection 200 Folder Script Template

```javascript
if (utils.testStatusCode(200).status) {

    utils.validateJsonSchemaIfCode(200);
    tm_utils.validatePagination('{{resourceName}}');

    let responseJson = pm.response.json();

    if (pm.request.url.query.get('$select')) {
        utils.validateSelectParameter('{{resourceName}}');
    } else {

        const responseIDs = responseJson.{{resourceName}}.map(record => record.{{resourceId}});
        const uniqueIDs = new Set(responseIDs);
        pm.test("Unique {{resourceId}} Values", function () {
            pm.expect(Array.from(uniqueIDs)).to.deep.equal(responseIDs);
        });

        let expand = pm.request.url.query.get('expand');
        if (expand) {
            utils.validateExpandParameter('{{resourceName}}');
        }

        // TODO: Add business logic validations
        {{#each businessRules}}
        pm.test("{{this.description}}", function () {
            responseJson.{{resourceName}}.forEach(item => {
                {{this.assertion}}
            });
        });
        {{/each}}
    }
}
```

#### Individual 200 Folder Script Template

```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);

    let responseJson = pm.response.json();

    if (pm.request.url.query.get('$select')) {
        utils.validateSelectParameter(null);
    } else {
        utils.validateFieldValuesIfCode(200, responseJson, {
            "{{resourceId}}": parseInt(pm.request.url.path.at(-1))
        });
    }

    {{#if supportsExpand}}
    let expand = pm.request.url.query.get('expand');
    if(expand){
        utils.validateExpandParameter(null);
    }
    {{/if}}
}
```

#### $filter/eq Request Template

```javascript
if (pm.response.code == 200) {
    let responseJson = pm.response.json();
    utils.performFilterAssertion(
        responseJson.{{resourceName}}, 
        '{{fieldName}}', 
        { type: 'eq', args: ['{{testValue}}'] }
    );
}
```

#### $select Pre-request Template

```javascript
let randomProperties = utils.getRandomProperties('{{schemaName}}');
pm.collectionVariables.set("temp_randomProperties", randomProperties);
```

---

## OpenAPI Integration

### Schema Extraction

```powershell
$openapi = Invoke-RestMethod -Uri "$domain/openapi.json"

# Collection GET
$getPath = $openapi.paths."/resourceName"
$getOperation = $getPath.get
$responseSchema = $getOperation.responses.'200'.content.'application/json'.schema

# Extract properties for $select and $filter tests
$properties = $responseSchema.properties.PSObject.Properties

# Identify filterable fields (typically: strings, numbers, dates)
$filterableFields = $properties | Where-Object { 
    $_.Value.type -in @("string", "number", "integer") -or 
    $_.Value.format -eq "date-time"
}

# Identify expandable sub-resources
$expandableResources = $properties | Where-Object { 
    $_.Value.type -eq "array" 
}
```

### Query Parameter Detection

Most GET operations in Finance API support:
- `$filter` - If response is collection
- `$select` - Always
- `$orderBy` - If response is collection
- `$expand` - If schema has related entities
- `limit/offset` - If response is collection

---

## Comparison with POST/PUT Endpoints

| Feature | GET Collection | GET Individual | POST | PUT |
|---------|----------------|----------------|------|-----|
| **Status Code** | 200 OK | 200 OK | 201 Created | 200 OK |
| **Response Type** | Array | Object | Array | Object |
| **Request Body** | None | None | Array | Object |
| **Folder Levels** | 200 only | 200 only | 201, 4xx | 200, 400, 404 |
| **Script Lines** | 40 | 17 | 34 | 20 |
| **OData Support** | Yes (heavy) | Yes (limited) | Sometimes | Rare |
| **Pagination** | Yes | No | No | No |
| **Main Tests** | Queries | Retrieval | Creation | Update |

---

## Test Categories Summary

### By Query Type

| Category | Tests | Complexity | Priority |
|----------|-------|------------|----------|
| $filter | 61 | High | High |
| $orderBy | 27 | Medium | Medium |
| Query Parameters | 14 | Medium | High |
| $expand | 10 | Medium | Medium |
| $select | 9 | Low | High |
| Pagination | 6 | Low | High |

### By Pattern Type

| Pattern | Tests | Avg Complexity |
|---------|-------|----------------|
| Collection | ~15-30 per resource | High |
| Individual | ~2-5 per resource | Low |
| Sub-Resource Collection | ~5-10 per sub | Medium |
| Sub-Resource Individual | ~2-3 per sub | Low |

---

## Known Issues

### 1. Pagination Validation Function

**Issue**: Two pagination validators
- `utils.validatePagination()` - Looks for `totalItems` and `pageIndex`
- `tm_utils.validatePagination()` - Current Finance API format

**Impact**: Must use correct validator

**Solution**: Always use `tm_utils.validatePagination()` for Finance API

### 2. $select with Individual Items

**Issue**: Parameter changes for single vs collection
- Collection: `utils.validateSelectParameter('resourceName')`
- Individual: `utils.validateSelectParameter(null)`

**Impact**: Must detect pattern type

**Solution**: Scaffold generates correct parameter based on pattern

### 3. Expand Support Inconsistency

**Issue**: Not all resources support $expand even with sub-resources

**Impact**: Can't assume expand availability

**Solution**: Check OpenAPI spec for expand support

---

## Recommendations

### For Scaffolding Script

1. **Detect Pattern Type**: Collection vs Individual vs Both
2. **Auto-detect OData Support**: From OpenAPI spec
3. **Generate $filter Tests**: For common field types
4. **Include Pagination Tests**: For all collections
5. **Template Business Rules**: With TODO markers
6. **Support Sub-Resources**: Recursive scaffolding

### For Manual Testing

1. **Start with basic test** - Collection or Individual
2. **Add $select test** - Always useful
3. **Add $filter tests** - For key fields (ID, status, dates)
4. **Add pagination tests** - For collections
5. **Add $expand tests** - If sub-resources exist
6. **Add $orderBy** - For sortable fields
7. **Add business rules** - Resource-specific validations

### For Documentation

1. Document which fields support filtering
2. Document sortable fields and default sort
3. Document expandable sub-resources
4. Document business validation rules
5. Document pagination limits and defaults

---

## Next Steps

1. ✅ Complete GET endpoint analysis
2. ⏭️ Create GET scaffolding script
3. ⏭️ Test with fuelTaxes/tripFuelPurchases
4. ⏭️ Create GET quick-start guide
5. ⏭️ Integrate with POST/PUT scaffolding

---

## Use Case: fuelTaxes/tripFuelPurchases

### Required Tests

#### Collection GET (fuelTaxes/:id/tripFuelPurchases)
1. **Basic**: GET all fuel purchases for a trip
2. **$select**: Field filtering
3. **$filter**:
   - purchaseDate eq
   - fuelVolume1 gt/lt
   - purchaseJurisdiction eq
4. **$orderBy**: purchaseDate desc
5. **Pagination**: limit/offset

#### Individual GET (fuelTaxes/:id/tripFuelPurchases/:tripFuelPurchaseId)
1. **Basic**: GET single fuel purchase
2. **$select**: Field filtering

### Expected Scaffold Command

```powershell
.\New-GetEndpointScaffold.ps1 `
    -ApiKey "PMAK-..." `
    -CollectionUid "8229908-779780a9-..." `
    -ResourceName "tripFuelPurchases" `
    -ParentResource "fuelTaxes" `
    -ParentIdName "fuelTaxId" `
    -Pattern "Both" `
    -FilterableFields @("purchaseDate", "fuelVolume1", "purchaseJurisdiction") `
    -SortableFields @("purchaseDate", "fuelVolume1") `
    -DefaultSort "purchaseDate desc" `
    -IncludePagination `
    -DryRun
```

---

**Document Version**: 1.0  
**Last Updated**: October 9, 2025  
**Author**: AI Assistant + Doug Batchelor

