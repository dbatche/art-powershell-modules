# TM-185682: Postman Collection Comparison

**Date**: October 17, 2025  
**Collection**: TM - Orders (8229908-048191f7-b6f7-44ad-8d62-4178b8944f08)

## Summary

Analyzed all barcode-related requests in the Postman collection to compare with our test coverage for TM-185682.

## Key Finding: ✅ Postman Requests Follow Best Practices

**All 5 PUT `/barcodes/{barcodeId}` requests in Postman do NOT include `barcodeId` in the request body.**

This confirms that:
1. ✅ The Postman collection follows the correct RESTful pattern
2. ✅ Our tests validate the proper behavior (API ignores `barcodeId` in body)
3. ✅ TM-185682 validates an edge case, not a common usage pattern

## Postman Collection Analysis

### Found 10 Barcode Requests:

#### GET Requests (2)
1. **Direct lookup by barcodeId**
   - URL: `{{DOMAIN}}/orders/{{POSTED_orderId}}/details/{{resourceId}}/barcodes/{{grandchildResourceId}}`
   - ID: `ed3dd40c-fadd-48d5-ae96-bca9ea9e7b2c`

2. **Direct lookup by barcodeId - webUser Auth**
   - URL: `{{DOMAIN}}/orders/{{POSTED_orderId}}/details/{{resourceId}}/barcodes/{{grandchildResourceId}}`
   - ID: `7cc4b653-2ce0-4d55-9d7f-d07e7983553c`

#### PUT Requests to `/barcodes/{barcodeId}` (5)

1. **Update Barcode** (Standard)
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}`
   - ID: `b6af6197-cd07-4889-8c1c-6b440b484754`
   - Body: `{ altBarcode1, pallets, palletUnits }` 
   - ✅ **No barcodeId in body**

2. **Update Barcode** (Extended)
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}`
   - ID: `5e7d2012-8275-4f90-bccb-8bc5c9da3de8`
   - Body: `{ altBarcode1, pallets, height, width, length, cube, user1-5 }` 
   - ✅ **No barcodeId in body**

3. **Update Barcode - Calculate Cube Automatically**
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}`
   - ID: `f271d6ac-6fa4-4dc8-8105-77ad41ff6c07`
   - Body: `{ length, width, height, user1 }`
   - ✅ **No barcodeId in body**

4. **Update Barcode's altBarcode1 Quote**
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}?type=Q`
   - ID: `df668574-f582-4bd2-8ea1-b60ad80bc841`
   - Body: `{ altBarcode1 }`
   - ✅ **No barcodeId in body**

5. **noValidFields** (Error test)
   - URL: `{{DOMAIN}}/orders/{{POSTED_orderId}}/details/{{resourceId}}/barcodes/{{grandchildResourceId}}`
   - ID: `7eb1fbe4-1641-44fc-a915-2aa674ec4cb4`
   - Body: `{}`
   - ✅ **No barcodeId in body**
   - Tests the `noValidFields` error response

#### DELETE Requests (3)

1. **DELETE barcodeId**
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}`
   - ID: `16866b69-e292-4383-b39b-81ef8c47206d`

2. **DELETE barcodeId Quote**
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}?type=Q`
   - ID: `86cde2c3-9286-4584-a736-0cc0f37c2bf0`

3. **DELETE barcodeId PUR - TM-160481**
   - URL: `{{DOMAIN}}/orders/{{temp_orderId}}/details/{{temp_orderDetailId}}/barcodes/{{temp_barcodeId}}?type=Q`
   - ID: `1f16ae9e-66d7-4e8b-8580-e3987cc985b8`
   - Related to TM-160481

## Comparison: Postman vs Our Tests

| Test Scenario | In Postman? | In Our Tests? | Notes |
|---------------|-------------|---------------|-------|
| GET /barcodes (collection) | ❌ | ✅ | We test collection retrieval |
| POST /barcodes (create) | ❌ | ✅ | We test creation |
| GET /barcodes/{id} | ✅ | ✅ | Both have it |
| PUT /barcodes/{id} (standard) | ✅ (5 variants) | ✅ | Both have it |
| PUT /barcodes/{id} (with same barcodeId in body) | ❌ | ✅ | **TM-185682 edge case - we test it** |
| PUT /barcodes/{id} (with different barcodeId) | ❌ | ✅ | **TM-185682 edge case - we test it** |
| PUT /barcodes/{id} (invalid data type) | ❌ | ✅ | Contract validation |
| PUT /barcodes/{id} (noValidFields) | ✅ | ❌ | Postman tests empty body |
| DELETE /barcodes/{id} | ✅ (3 variants) | ✅ | Both have it |

## Additional Postman Features Not in Our Tests

1. **Quote Type Parameter**: `?type=Q`
   - Several requests use this parameter
   - Tests quote-specific operations

2. **Cube Auto-calculation Test**
   - Validates automatic cube calculation from dimensions
   - Not in our tests (business logic validation)

3. **WebUser Authentication Test**
   - Tests with different auth type
   - Not in our tests (auth testing)

## What TM-185682 Actually Tests

Based on this analysis, **TM-185682 tests an edge case that is NOT in the Postman collection**:
- What happens if a developer mistakenly includes `barcodeId` in the PUT request body?
- Should the API reject it, allow it, or ignore it?

**Our Test Result**: ✅ API correctly **ignores** the field (proper RESTful behavior)

This explains why it's not in Postman - it's testing misuse/edge case, not normal usage.

## Recommendations

### For TM-185682
✅ **Close as "Working as Designed"** - API handles the edge case correctly

### For Our Test Suite
Consider adding tests from Postman:
1. ❌ `PUT /barcodes/{id}` with empty body → expects `noValidFields` error
2. ❌ Operations with `?type=Q` parameter (quote operations)
3. ❌ Cube auto-calculation validation

### For Postman Collection
Consider adding our edge case tests to Postman:
1. ❌ `POST /barcodes` (create barcode)
2. ❌ `GET /barcodes` (collection query)
3. ❌ `PUT /barcodes/{id}` with `barcodeId` in body (TM-185682 validation)
4. ❌ Contract validation tests (invalid data types, etc.)

## Conclusion

✅ **Postman collection follows best practices** - no `barcodeId` in PUT bodies  
✅ **Our tests validate edge cases** - TM-185682 scenario covered  
✅ **API behavior is correct** - ignores `barcodeId` field in body  
✅ **Test coverage is complementary** - Postman tests normal usage, our tests validate edge cases

---

**Files**:
- Postman export: `postman-all-barcode-requests-20251017-182221.json`
- Our test script: `OrderDetailBarcodes-Scenario.ps1`
- Test results: `orderbarcodes-test-data-20251017-143403.json`

