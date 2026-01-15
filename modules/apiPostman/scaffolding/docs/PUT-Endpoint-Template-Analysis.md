# PUT Endpoint Template Analysis
**Finance API - TDD Test Structure**

## Analysis Date
October 6, 2025

## Purpose
Analyze existing PUT endpoints in Finance API to create a reusable template for new PUT endpoints like `PUT apInvoices/:apInvoiceId` (TM-180924).

---

## Analyzed Endpoints

Based on Finance Functional Tests collection analysis:

| Endpoint | PUT Requests | Structure Level |
|----------|--------------|-----------------|
| `checks` | 23 | Top-level + nested (bills) |
| `currencyRates` | 6 | Top-level |
| `driverDeductions` | 11 | Top-level |
| `driverPayments` | 17 | Top-level |
| `glAccounts` | 8 | Top-level |
| `interlinerPayables` | 5 | Top-level |
| `taxes` | 6 | Nested (taxRates) |

---

## Common Folder Structure Pattern

```
📁 {endpoint}
  📁 {resourceId}          # e.g., apInvoiceId, driverDeductionId
    📁 PUT
      📁 200               # Success responses
        ├── minimal fields
        ├── Request body based on openAPI
        ├── $select
        ├── blank string
        └── {specific business scenarios}
      📁 4xx               # Error responses
        📁 invalidBusinessLogic
          ├── {business rule 1}
          ├── {business rule 2}
          └── ...
        ├── random invalidDBValue
        ├── 409 - Resource Conflict
        └── ...
```

---

## Standard Test Requests in PUT/200 Folder

### 1. **minimal fields**
- **Purpose**: Test with only required fields
- **Body**: Minimal valid JSON
- **Pre-request**: Often sets up random/temp variables
- **Test**: Usually empty or basic response validation

### 2. **Request body based on openAPI**
- **Purpose**: Test with comprehensive fields from OpenAPI spec
- **Body**: Full example from OpenAPI schema
- **Pre-request**: May generate data
- **Test**: Validates response structure

### 3. **$select**
- **Purpose**: Test field selection
- **URL**: Includes `?$select=field1,field2`
- **Body**: Standard update
- **Test**: Validates only selected fields returned

### 4. **blank string**
- **Purpose**: Test handling of empty string values
- **Body**: Fields with `""`
- **Test**: Validates proper handling

### 5. **{Specific Business Scenarios}**
- Examples from existing endpoints:
  - `accountsPayableId auto updates the bill amounts` (checks)
  - `paymentCode - values auto populated` (driverPayments)
  - `FB` (driverDeductions - specific code)
  - `subAccount true` (glAccounts)

---

## Standard Test Requests in PUT/4xx Folder

### invalidBusinessLogic Subfolder

Common business rule validations:
- **State/Status Checks**
  - `check is posted - no update allowed`
  - `change State not allowed`
  - `Update an approved pay record to hold`
  
- **Invalid References**
  - `invalid accountsPayableId`
  - `Invalid deduction code`
  - `Bill number not a valid bill!`
  
- **Business Logic Violations**
  - `bills can only be created for vendor pay type`
  - `No driver pay contract`
  - `Deduction record imported by Card Import`

### Other 4xx Tests

- **`random invalidDBValue`**: Tests invalid DB references
- **`409 - Resource Conflict`**: Tests concurrent update scenarios
- **`400 - aboveMaxValue`**: Tests validation limits

---

## Test Script Patterns

### Success Tests (200)

Most 200 tests have minimal or no test scripts:
```javascript
// Often empty or basic validation
```

### Error Tests (4xx)

Use `tm_utils` helper functions:
```javascript
// Example from driverDeductions
tm_utils.testInvalidBusinessLogicResponse("Expected error message");
```

### Pre-request Patterns

#### Data Setup
```javascript
// Create a resource first via POST
let postBody = {
    "field1": pm.variables.get('VAR1'),
    "field2": pm.variables.get('VAR2')
}

pm.sendRequest({
    url: pm.environment.get("DOMAIN") + "/endpoint",
    method: 'POST',
    header: {
        'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
    },
    body: {
        mode: 'application/json',
        raw: [postBody]
    }
}, function (err, response) {
    if (err) {
        console.error('error:\n', err, 'Response: \n', response.text());
        throw new Error("An error has occurred. Check logs.");
    }
    const jsonData = response.json();
    pm.globals.set('temp_resourceId', jsonData.resources[0].resourceId);
});
```

#### Random Data Generation
```javascript
pm.collectionVariables.set('temp_randomCurrency', lodash.sample(['CAD', 'USD', 'AUD', 'NZD']));
```

---

## Request Body Patterns

### Minimal Fields
```json
{
    "requiredField1": "{{variable1}}",
    "requiredField2": {{variable2}}
}
```

### Full OpenAPI
```json
{
    "field1": "value1",
    "field2": 123,
    "field3": true,
    "nestedObject": {
        "nestedField": "value"
    },
    "array": ["item1", "item2"]
}
```

### Blank String Test
```json
{
    "stringField": "",
    "otherField": "valid value"
}
```

---

## Variable Naming Conventions

### Collection/Environment Variables
- Resource IDs: `{RESOURCE}_ID` (e.g., `AP_INVOICE_ID`, `DRIVER_ID`)
- Domain: `DOMAIN`
- API Key: `TRUCKMATE_API_KEY`

### Temporary Variables (set in pre-request)
- Prefix with `temp_` or `temp`
- Examples:
  - `temp_apInvoiceId`
  - `tempCurrencyRateId`
  - `temp_randomCurrency`

---

## Query Parameter Patterns

### Common Query Params for PUT
- `$select=field1,field2` - Field selection
- `location=driverPay` - Context-specific (currencyRates)
- None for most simple PUTs

---

## URL Structure

```
{{DOMAIN}}/{endpoint}/{{resourceId}}[?queryParams]
```

Examples:
- `{{DOMAIN}}/apInvoices/{{apInvoiceId}}`
- `{{DOMAIN}}/driverDeductions/{{temp_driverDeductionId}}`
- `{{DOMAIN}}/currencyRates/{{tempCurrencyRateId}}?location={{tempRandLocation}}`

---

## Recommended Template for PUT apInvoices/:apInvoiceId

### Folder Structure
```
📁 apInvoices
  📁 apInvoiceId
    📁 PUT
      📁 200
        ├── minimal fields
        ├── Request body based on openAPI
        ├── $select
        ├── blank string
        ├── vendor update
        ├── invoice date update
        └── amounts update
      📁 4xx
        📁 invalidBusinessLogic
          ├── invoice is posted - no update allowed
          ├── invalid vendorId
          ├── invalid glAccount
          └── duplicate invoice number
        ├── random invalidDBValue
        └── 409 - Resource Conflict
```

### Variables Needed
- Collection/Environment:
  - `AP_INVOICE_ID` - existing invoice for testing
  - `VENDOR_ID` - valid vendor
  - `GL_ACCOUNT` - valid GL account
  
- Temporary (set in pre-request):
  - `temp_apInvoiceId` - created for specific tests
  - `temp_invoiceNumber` - random invoice number
  - `temp_invoiceDate` - random date

### Test Cases to Include

#### 200 - Success
1. **minimal fields** - Update only required fields
2. **Request body based on openAPI** - Full update with all fields
3. **$select** - Update with field selection
4. **blank string** - Test empty string handling
5. **vendor update** - Change vendor
6. **invoice date update** - Change invoice date
7. **amounts update** - Update invoice amounts

#### 4xx - Errors
1. **invoice is posted - no update allowed** - Business rule
2. **invalid vendorId** - Invalid reference
3. **invalid glAccount** - Invalid GL account
4. **duplicate invoice number** - Uniqueness violation
5. **random invalidDBValue** - Generic validation
6. **409 - Resource Conflict** - Concurrent update

---

## Next Steps

1. ✅ Complete analysis of existing PUT patterns
2. ⏳ Create scaffolding script to generate folder structure
3. ⏳ Create template requests with placeholders
4. ⏳ Document variable setup requirements
5. ⏳ Test scaffold on TM-180924 (PUT apInvoices)

---

## Notes

- All PUT endpoints follow similar structure patterns
- Test scripts are minimal for 200 responses
- Error tests use `tm_utils` helper functions
- Pre-request scripts often create test data via POST
- Variable naming is consistent across endpoints
- TDD approach: folders and tests created before implementation

