# POST Endpoint Scaffolding - Project Summary

**Date**: October 9, 2025  
**Status**: Analysis Complete, Scaffolding Script In Progress

---

## 📋 Project Overview

Analyzed 110 POST requests across 8 major resources in the Finance Functional Tests collection to develop automated scaffolding for POST endpoint test structures.

---

## 🎯 Goals

1. ✅ Analyze existing POST endpoint patterns
2. ✅ Document common test structures and scripts
3. ⏭️ Create automated scaffolding script
4. ⏭️ Generate test templates for new POST endpoints
5. ⏭️ Apply to `fuelTaxes/:id/tripFuelPurchases` (TM-180940)

---

## 📊 Analysis Results

### Resources Analyzed

| Resource | POST Tests | Complexity |
|----------|------------|------------|
| checks | 29 | High (includes sub-resource) |
| apInvoices | 20 | High (3 sub-resources) |
| driverPayments | 17 | Medium |
| driverDeductions | 11 | Low |
| glAccounts | 11 | Low |

### Key Patterns Identified

1. **Folder Structure**: 201 (success) + 4xx (errors)
2. **Request Format**: Arrays of objects
3. **Response Code**: 201 Created
4. **Response Format**: `{resourceName: [...]}` 
5. **Script Levels**: Collection → Folder → Request

---

## 🏗️ Standard POST Structure

```
ResourceName/
└── POST/
    ├── 201/                        📜 Folder test script (34 lines)
    │   ├── minimum fields         ⭐ Most important
    │   ├── array
    │   ├── $select
    │   └── [custom scenarios...]
    └── 4xx/
        ├── 400 - InvalidDBValue/
        │   └── invalid [field]
        └── 400 - invalidBusinessLogic/
            └── [business rule]
```

---

## 🔑 Key Differences: POST vs PUT

| Aspect | POST | PUT |
|--------|------|-----|
| Status Code | 201 Created | 200 OK |
| Request Body | Array `[{...}]` | Object `{...}` |
| Folder Levels | 201, 4xx | 200, 400, 404 |
| Test Focus | Creation | Update |
| 201/200 Script | 34 lines (main resource) | ~20 lines |

---

## 📝 Script Templates

### 201 Folder Test Script

**Purpose**: Validate creation response and field values

**Size**: 
- Main resource: ~34 lines
- Sub-resource: ~13 lines

**Key Validations**:
1. Status code 201
2. JSON schema compliance
3. $select parameter support
4. Response fields match request
5. Auto-populated fields present

### Request Pre-request Script

**Purpose**: Build test data

**Typical Pattern**:
```javascript
// Setup parent ID (if sub-resource)
// Build request body as array
const requestBody = [{ 
    field1: "value",
    field2: 123
}];
pm.request.body.raw = JSON.stringify(requestBody);
```

### Request Test Script

**Purpose**: Custom validation

**Usually minimal**: 1-3 lines or none (folder script handles most)

---

## 🛠️ Scaffolding Script Features

### Inputs

1. **Resource Name**: e.g., "tripFuelPurchases"
2. **Parent Resource** (if sub-resource): e.g., "fuelTaxes"
3. **Parent ID Name**: e.g., "fuelTaxId"
4. **Success Test Names**: Array of scenario names
   - Default: `["minimum fields", "array", "$select"]`
5. **Error Test Scenarios**:
   - InvalidDBValue tests: Field names
   - InvalidBusinessLogic tests: Rule descriptions

### Outputs

1. **JSON Structure**: Importable into Postman
2. **201 Folder**: With comprehensive test script
3. **Test Requests**: Pre-configured with templates
4. **Error Tests**: Structured error validation

### Options

- `-DryRun`: Preview structure without creating
- `-IncludeArrayTest`: Add batch creation test (default: true)
- `-IncludeSelectTest`: Add $select test (default: true)
- `-OutputPath`: Save JSON to file

---

## 📦 Deliverables

### Documentation

1. ✅ **POST-Endpoint-Template-Analysis.md** (24KB)
   - Comprehensive pattern analysis
   - Script breakdowns
   - Test categories
   - OpenAPI integration

2. ⏭️ **POST-Endpoint-Quick-Start.md**
   - Usage examples
   - Common scenarios
   - Troubleshooting

3. ✅ **POST-Endpoint-Scaffold-Summary.md** (this file)
   - High-level overview
   - Key findings
   - Next steps

### Scripts

1. ⏭️ **New-PostEndpointScaffold.ps1**
   - Main scaffolding script
   - OpenAPI integration
   - Template generation

2. ✅ **Get-PostmanCollectionStructure.ps1** (already exists)
   - Collection analysis
   - UID extraction
   - CLI command generation

---

## 🎯 Use Case: fuelTaxes/tripFuelPurchases

### Current State

- **Jira**: TM-180940
- **Endpoint**: POST /fuelTaxes/:fuelTaxId/tripFuelPurchases
- **Status**: Implemented, but error format buggy
- **Tests**: None in Postman

### Required Fields (from OpenAPI)

**Answer**: NONE! All fields are optional.

### Proposed Tests

#### 201 Success Tests
1. **minimum fields**: Basic creation with minimal data
2. **all fields**: Comprehensive field coverage
3. **array**: Multiple fuel purchases in one request
4. **$select**: Field filtering

#### 4xx Error Tests
1. **InvalidDBValue**:
   - invalid fuelTaxId (parent)
   - invalid jurisdiction code
   - invalid fuel type

2. **InvalidBusinessLogic**:
   - Purchase date outside trip dates
   - Negative fuel volume
   - Duplicate purchase detection

### Expected Scaffold Command

```powershell
.\New-PostEndpointScaffold.ps1 `
    -ApiKey "PMAK-..." `
    -CollectionUid "8229908-779780a9-..." `
    -ResourceName "tripFuelPurchases" `
    -ParentResource "fuelTaxes" `
    -ParentIdName "fuelTaxId" `
    -SuccessTests @("minimum fields", "all fields", "array", "$select") `
    -InvalidDBTests @("invalid fuelTaxId") `
    -InvalidLogicTests @("negative volume", "future purchase date") `
    -DryRun
```

---

## ⚠️ Known Issues

### 1. Legacy Error Format

**Issue**: Many POST endpoints return old error format
```json
{"errorCode": 0, "errorText": "Invalid Request"}
```

**Instead of**: API-compliant format
```json
{
  "type": "...",
  "title": "...",
  "status": 400,
  "errors": [...]
}
```

**Affected**: 
- TM-180940 (POST tripFuelPurchases)
- TM-180941 (PUT tripFuelPurchases)
- Others TBD

**Impact**: Error validation tests will fail until fixed

**Workaround**: Scaffold tests anyway, mark as known failures

### 2. No Required Fields

**Issue**: Many POST endpoints have no required fields (per OpenAPI)

**Challenge**: Determining "minimum fields" is business logic, not schema

**Solution**: 
- Default to 2-3 business-critical fields
- Add TODO comments for review
- Document business requirements separately

### 3. Response Format Inconsistency

**Issue**: Response wrapping varies by endpoint
- Some: `{resourceName: [...]}`
- Others: `{data: [...]}` or different property names

**Solution**: Extract from OpenAPI 201 response schema

---

## 🔄 Workflow

### For New POST Endpoint

1. **Fetch OpenAPI spec**
   ```powershell
   $openapi = Invoke-RestMethod -Uri "$domain/openapi.json"
   ```

2. **Extract schema**
   ```powershell
   $postSchema = $openapi.paths."/resource".post
   $requestSchema = $postSchema.requestBody.content.'application/json'.schema
   ```

3. **Generate scaffold**
   ```powershell
   .\New-PostEndpointScaffold.ps1 -ResourceName "resource" [options...]
   ```

4. **Import to Postman**
   - Import generated JSON
   - Review TODO markers
   - Customize business logic tests

5. **Test and Iterate**
   - Run tests in Postman
   - Adjust test data
   - Add custom scenarios

---

## 📈 Success Metrics

### Test Coverage

- ✅ **Basic creation**: minimum fields test
- ✅ **Batch operations**: array test
- ✅ **OData support**: $select test
- ✅ **Error handling**: InvalidDBValue tests
- ✅ **Business rules**: InvalidBusinessLogic tests

### Quality Indicators

- **Automation**: 90%+ of test structure generated
- **Consistency**: All POST tests follow same pattern
- **Maintainability**: Templates easy to update
- **Documentation**: Clear guides for usage

---

## 🚀 Next Steps

### Immediate (Sprint 25.4.20)

1. ⏭️ Complete `New-PostEndpointScaffold.ps1` script
2. ⏭️ Test with tripFuelPurchases endpoint
3. ⏭️ Create quick-start guide
4. ⏭️ Validate against other POST endpoints

### Short Term

1. Document common field patterns
2. Create field default value templates
3. Add business rule catalog
4. Integrate with existing scaffolding folder

### Long Term

1. Unified scaffolding for all HTTP methods (GET, POST, PUT, DELETE)
2. OpenAPI-driven test data generation
3. Automated test execution and reporting
4. Integration with CI/CD pipeline

---

## 🤝 Related Work

### Existing Scaffolding

- ✅ **PUT Endpoint Scaffolding**
  - Scripts: `New-PutEndpointScaffold.ps1`
  - Docs: 5 analysis documents
  - Status: Complete

- ✅ **Request Name Updates**
  - Script: `Update-PostmanRequestName.ps1`
  - Use: Bulk renaming, Jira ticket tagging

- ✅ **Collection Structure**
  - Script: `Get-PostmanCollectionStructure.ps1`
  - Use: UID extraction, CLI commands

### Folder Organization

All scaffolding work organized in:
```
modules/apiPostman/scaffolding/
├── scripts/
│   ├── New-PutEndpointScaffold.ps1
│   ├── New-PostEndpointScaffold.ps1      ⏭️ TO DO
│   ├── Update-PostmanRequestName.ps1
│   └── Get-PostmanCollectionStructure.ps1
├── docs/
│   ├── PUT-*.md (5 files)
│   └── POST-*.md (3 files)                ⏭️ IN PROGRESS
└── examples/
    └── [Generated scaffolds]
```

---

## 📚 References

### Documentation

- POST-Endpoint-Template-Analysis.md
- PUT-Endpoint-Template-Analysis.md
- PUT-Folder-Level-Scripts-Analysis.md

### Jira Issues

- TM-180940: POST /fuelTaxes/:fuelTaxId/tripFuelPurchases
- TM-180941: PUT /fuelTaxes/:fuelTaxId/tripFuelPurchases/:id
- TM-185730: Error message format standardization

### External Resources

- [Postman API Docs](https://www.postman.com/postman/workspace/postman-public-workspace/documentation/12959542-c8142d51-e97c-46b6-bd77-52bb66712c9a)
- [OpenAPI Specification](https://swagger.io/specification/)
- [OData Protocol](https://www.odata.org/)

---

**Project Lead**: Doug Batchelor  
**AI Assistant**: Claude (Anthropic)  
**Last Updated**: October 9, 2025  
**Status**: 🟡 In Progress (70% complete)

