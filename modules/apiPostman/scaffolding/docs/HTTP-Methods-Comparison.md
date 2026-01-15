# HTTP Methods Comparison
## GET vs POST vs PUT - Finance API Testing Patterns

**Date**: October 9, 2025  
**Collection**: Finance Functional Tests  
**Analysis Scope**: 467 total requests across all methods

---

## Quick Reference Table

| Aspect | GET | POST | PUT |
|--------|-----|------|-----|
| **Total Requests** | 319 | 110 | 38 |
| **Status Code** | 200 OK | 201 Created | 200 OK |
| **Request Body** | None | Array `[{...}]` | Object `{...}` |
| **Response Type** | Array or Object | Array (wrapped) | Object |
| **Folder Levels** | 200 only | 201, 4xx | 200, 400, 404 |
| **Script Complexity** | 🔥 High (40L) | 🟡 Medium (34L) | 🟢 Low (20L) |
| **OData Support** | 🔥 Heavy | 🟡 Limited | 🟢 Rare |
| **Test Categories** | 6+ types | 2 types | 3 types |
| **Main Purpose** | Query & Retrieve | Create | Update |

---

## Detailed Comparison

### Request Patterns

#### GET
- **Collection**: `/resourceName` → Array of items
- **Individual**: `/resourceName/:id` → Single item
- **Sub-Collection**: `/parent/:id/sub` → Array of sub-items
- **Sub-Individual**: `/parent/:id/sub/:subId` → Single sub-item

**4 distinct patterns!**

#### POST
- **Main Resource**: `/resourceName` → Creates items
- **Sub-Resource**: `/parent/:id/sub` → Creates sub-items

**2 patterns, always arrays** (POST only targets collections, never individual items)

#### PUT
- **Main Resource**: `/resourceName/:id` → Updates item
- **Sub-Resource**: `/parent/:id/sub/:subId` → Updates sub-item

**2 patterns, always individual objects**

---

### Response Formats

#### GET Collection
```json
{
  "resourceName": [
    { "id": 1, "field": "value" },
    { "id": 2, "field": "value" }
  ],
  "@odata.context": "...",
  "offset": 0,
  "limit": 100,
  "count": 2
}
```

#### GET Individual
```json
{
  "id": 1,
  "field": "value",
  "@odata.context": "..."
}
```

#### POST
```json
{
  "resourceName": [
    {
      "id": 123,
      "field": "value",
      "createdDate": "2025-10-09T...",
      "createdBy": "API_USER"
    }
  ],
  "@odata.context": "..."
}
```

#### PUT
```json
{
  "id": 123,
  "field": "updated value",
  "modifiedDate": "2025-10-09T...",
  "modifiedBy": "API_USER"
}
```

---

### Folder Structure Comparison

#### GET
```
Resource/
└── GET/
    └── 200/                    📜 40 lines (collection) or 17 lines (individual)
        ├── resourceName
        ├── $filter/
        ├── $select
        ├── $orderBy
        ├── expand/
        └── Query Parameters/
```

#### POST
```
Resource/
└── POST/
    ├── 201/                    📜 34 lines (main) or 13 lines (sub)
    │   ├── minimum fields
    │   ├── array
    │   └── $select
    └── 4xx/
        ├── 400 - InvalidDBValue/
        └── 400 - invalidBusinessLogic/
```

#### PUT
```
Resource/
└── :resourceId/
    └── PUT/
        ├── 200/                📜 20 lines
        │   ├── minimal fields
        │   ├── field updates
        │   └── $select
        ├── 400/
        │   ├── InvalidDBValue/
        │   └── invalidBusinessLogic/
        └── 404/
```

---

### Script Complexity

#### Folder Script Line Counts

| Method | Pattern | Lines | Complexity |
|--------|---------|-------|------------|
| **GET** | Collection (Main) | 40 | 🔥 Highest |
| **POST** | Main Resource | 34 | 🟡 High |
| **GET** | Collection (Sub) | 21 | 🟡 Medium |
| **PUT** | Any | 20 | 🟢 Medium-Low |
| **GET** | Individual (Main) | 17 | 🟢 Low |
| **GET** | Individual (Sub) | 15 | 🟢 Lowest |
| **POST** | Sub-Resource | 13 | 🟢 Lowest |

**Why GET is most complex:**
- OData query parameter validation ($filter, $select, $orderBy, $expand)
- Pagination validation
- Unique ID checking
- Multiple business logic rules

**Why POST is medium:**
- Array handling and validation
- Response field matching
- Auto-populated field checks
- $select support

**Why PUT is simplest:**
- Single object validation
- Straightforward field comparison
- Basic $select support

---

### Test Categories

#### GET (6 major categories)
1. **Basic Retrieval** - Collection or Individual
2. **$filter** - OData filtering (61 tests)
3. **$select** - Field selection (9 tests)
4. **$orderBy** - Sorting (27 tests)
5. **$expand** - Related entities (10 tests)
6. **Pagination** - limit/offset (14 tests)

#### POST (2 major categories)
1. **Success (201)**:
   - minimum fields
   - all fields
   - array (batch creation)
   - $select
   - business logic scenarios

2. **Errors (4xx)**:
   - InvalidDBValue (foreign keys)
   - invalidBusinessLogic (business rules)

#### PUT (3 major categories)
1. **Success (200)**:
   - minimal field update
   - specific field updates
   - $select

2. **Errors (400)**:
   - InvalidDBValue
   - invalidBusinessLogic

3. **Not Found (404)**:
   - Invalid resource ID

---

### OData Support Comparison

| Feature | GET Collection | GET Individual | POST | PUT |
|---------|----------------|----------------|------|-----|
| **$filter** | ✅ Extensive | ❌ No | ❌ No | ❌ No |
| **$select** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **$orderBy** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **$expand** | ✅ Yes | ✅ Sometimes | ❌ No | ❌ No |
| **Pagination** | ✅ Yes | ❌ No | ❌ No | ❌ No |

**GET Collection** is the OData powerhouse!

---

### Validation Patterns

#### GET Collection (40 lines)
```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    tm_utils.validatePagination('resourceName');
    
    if ($select) {
        utils.validateSelectParameter('resourceName');
    } else {
        // Unique ID validation
        // $expand validation
        // Business logic validation
    }
}
```

#### GET Individual (17 lines)
```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    
    if ($select) {
        utils.validateSelectParameter(null);
    } else {
        // ID match validation
        utils.validateFieldValuesIfCode(200, response, {"id": urlId});
    }
}
```

#### POST (34 lines)
```javascript
if (utils.testStatusCode(201).status) {
    utils.validateJsonSchemaIfCode(201);
    
    if ($select) {
        utils.validateSelectParameter('resourceName');
    } else {
        // Array response validation
        if (response.resourceName && response.resourceName.length > 0) {
            utils.validateFieldValuesIfCode(201, 
                response.resourceName[0], 
                requestBody[0]);
        }
    }
}
```

#### PUT (20 lines)
```javascript
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    
    if ($select) {
        utils.validateSelectParameter(null);
    } else {
        let requestBody = JSON.parse(pm.request.body.raw);
        requestBody.resourceId = parseInt(urlId);
        
        // Business logic validation (optional)
        
        utils.validateFieldValuesIfCode(200, response, requestBody);
    }
}
```

---

### Request-Level Scripts

#### GET
**Typical**: 0-6 lines  
**Why minimal?** Folder script handles most validation

**Common patterns**:
- $filter: `utils.performFilterAssertion(...)`
- $select: Pre-request generates random fields
- orderBy: Validates sort order
- Most tests: No script (folder handles all)

#### POST
**Typical**: 1-3 lines  
**Why minimal?** Folder script handles validation

**Common patterns**:
- Pre-request: Build request body array
- Test: Usually none (folder validates)
- Custom: Business logic assertions only

#### PUT
**Typical**: 1-3 lines  
**Why minimal?** Folder script handles validation

**Common patterns**:
- Pre-request: Build single object body
- Test: Usually none
- Custom: Field-specific validations

---

## Use Case: fuelTaxes/tripFuelPurchases

### GET Tests Needed

#### Collection (GET /fuelTaxes/:id/tripFuelPurchases)
1. Basic retrieval (5-10 records expected)
2. $select (field filtering)
3. $filter:
   - `purchaseDate eq`
   - `fuelVolume1 gt/lt`
   - `purchaseJurisdiction eq`
4. $orderBy: `purchaseDate desc`
5. Pagination: limit/offset
6. Business rule: fuelVolume1 > 0

**Estimated**: ~12 tests

#### Individual (GET /fuelTaxes/:id/tripFuelPurchases/:id)
1. Basic retrieval
2. $select

**Estimated**: ~2 tests

### POST Tests Needed

#### POST /fuelTaxes/:id/tripFuelPurchases
1. minimum fields (201)
2. all fields (201)
3. array - multiple purchases (201)
4. $select (201)
5. Invalid fuelTaxId (400 - InvalidDBValue)
6. Invalid jurisdiction (400 - InvalidDBValue)
7. Negative volume (400 - invalidBusinessLogic)
8. Future purchase date (400 - invalidBusinessLogic)

**Estimated**: ~8 tests

### PUT Tests Needed

#### PUT /fuelTaxes/:id/tripFuelPurchases/:id
1. minimal field update (200)
2. update fuelVolume1 (200)
3. update purchaseDate (200)
4. $select (200)
5. Invalid jurisdiction (400 - InvalidDBValue)
6. Negative volume (400 - invalidBusinessLogic)
7. Invalid tripFuelPurchaseId (404)

**Estimated**: ~7 tests

### Total Tests: ~29

---

## Scaffolding Command Comparison

### GET
```powershell
.\New-GetEndpointScaffold.ps1 `
    -ResourceName "tripFuelPurchases" `
    -ParentResource "fuelTaxes" `
    -Pattern "Both" `
    -FilterableFields @("purchaseDate", "fuelVolume1", "purchaseJurisdiction") `
    -SortableFields @("purchaseDate", "fuelVolume1") `
    -IncludePagination
```

### POST
```powershell
.\New-PostEndpointScaffold.ps1 `
    -ResourceName "tripFuelPurchases" `
    -ParentResource "fuelTaxes" `
    -SuccessTests @("minimum fields", "all fields", "array", "$select") `
    -InvalidDBTests @("invalid fuelTaxId", "invalid jurisdiction") `
    -InvalidLogicTests @("negative volume", "future purchase date")
```

### PUT
```powershell
.\New-PutEndpointScaffold.ps1 `
    -ResourceName "tripFuelPurchases" `
    -ParentResource "fuelTaxes" `
    -SuccessTests @("minimal fields", "update volume", "update date") `
    -ErrorTests @("invalid jurisdiction", "negative volume")
```

---

## Best Practices by Method

### GET
1. ✅ Start with basic collection test
2. ✅ Add $select test (always useful)
3. ✅ Add $filter for key fields (ID, status, dates)
4. ✅ Add pagination tests
5. ✅ Add $expand if sub-resources exist
6. ✅ Add $orderBy for sortable fields
7. ✅ Add business logic validations
8. ✅ Test individual item retrieval

### POST
1. ✅ Start with minimum fields test (most important)
2. ✅ Add all fields test (comprehensive)
3. ✅ Add array test (batch operations)
4. ✅ Add $select test
5. ✅ Add InvalidDBValue for each foreign key
6. ✅ Add invalidBusinessLogic for business rules
7. ✅ Test error responses match spec

### PUT
1. ✅ Start with minimal field update
2. ✅ Add specific field update tests
3. ✅ Add $select test
4. ✅ Add InvalidDBValue for foreign keys
5. ✅ Add invalidBusinessLogic for rules
6. ✅ Add 404 test (invalid ID)
7. ✅ Keep it simple - PUT is straightforward

---

## Common Patterns Across All Methods

### All Use Collection-Level Scripts
- Authentication (Bearer token)
- Package loading (@trimble-inc/utils_finance)
- Cache management
- Tag filtering

### All Use Folder-Level Scripts
- Status code validation
- JSON schema validation
- $select parameter validation (when applicable)
- Field value validation

### All Have Minimal Request Scripts
- Folder scripts handle 90%+ of validation
- Request scripts only for specific cases
- Keep tests simple and maintainable

### All Support $select
- GET: Collection and Individual
- POST: Creation response
- PUT: Update response

---

## Testing Workflow

### 1. Explore with GET
```
GET /resource          → See what exists
GET /resource/:id      → Get details
GET /resource?$filter  → Test filtering
```

### 2. Create with POST
```
POST /resource         → Create test data
Verify with GET        → Confirm creation
```

### 3. Update with PUT
```
PUT /resource/:id      → Modify data
Verify with GET        → Confirm update
```

### 4. Query with GET
```
GET /resource?filters  → Find updated data
GET /resource?expand   → Get related data
```

---

## Summary

| Method | Best For | Complexity | Script Size | OData | Test Count |
|--------|----------|------------|-------------|-------|------------|
| **GET** | Querying & Retrieval | 🔥 Highest | 15-40 lines | Heavy | ~15-30 per resource |
| **POST** | Creation | 🟡 Medium | 13-34 lines | Light | ~8-12 per resource |
| **PUT** | Updates | 🟢 Lowest | 20 lines | Minimal | ~5-8 per resource |

**Total Test Estimate per Complete Resource**: ~30-50 tests (GET + POST + PUT + sub-resources)

---

## Recommendations

### For Scaffolding Implementation

1. **Start with PUT** - Simplest, good template
2. **Add POST** - Medium complexity, builds on PUT
3. **Add GET last** - Most complex, requires OData handling

### For Test Development

1. **GET first** - Understand existing data
2. **POST second** - Create test data
3. **PUT third** - Modify test data
4. **GET again** - Verify changes

### For Maintenance

1. **Keep folder scripts generic** - Handle common validations
2. **Keep request scripts minimal** - Only specific cases
3. **Use TODO markers** - For custom business logic
4. **Document OData support** - In OpenAPI or README

---

**Document Version**: 1.0  
**Last Updated**: October 9, 2025  
**Author**: AI Assistant + Doug Batchelor  
**Status**: Reference Guide - Complete

