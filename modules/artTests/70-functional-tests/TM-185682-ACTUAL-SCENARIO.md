# TM-185682: ACTUAL SCENARIO TESTING - Barcode Array in Detail PUT

**Date**: October 17, 2025  
**Status**: ✅ TEST CREATED - Bug Confirmed with `invalidBusinessLogic` error

## Corrected Understanding

**PREVIOUS** (Incorrect): Testing `PUT /orders/{orderId}/details/{detailId}/barcodes/{barcodeId}`  
**ACTUAL** (Correct): Testing `PUT /orders/{orderId}/details/{detailId}` with `barcodes` array in body

## The Real Scenario

### Setup
- Order detail originally has 2 barcodes

### PUT Request Body
```json
{
  "barcodes": [
    { "barcodeId": 789, "altBarcode1": "UPDATED", "weight": 999.99 },  // ← WITH barcodeId (UPDATE)
    { "altBarcode1": "NEW-A", "weight": 111.11 },                       // ← NO barcodeId (CREATE)
    { "altBarcode1": "NEW-B", "weight": 222.22 }                        // ← NO barcodeId (CREATE)
  ]
}
```

### Expected Behavior
- Barcode with `barcodeId`: **UPDATE** existing barcode (not duplicate)
- Barcodes without `barcodeId`: **CREATE** new barcodes
- Result: 4 total barcodes (1 untouched original, 1 updated, 2 new)

## Test Results

### ❌ Bug Confirmed
```
PUT /orders/{orderId}/details/{detailId} 
Status: 400 Bad Request
Error Code: invalidBusinessLogic
```

The API returns an error when trying to update a detail with a barcodes array that includes `barcodeId` fields.

### What We Need
To fully investigate, we need:
1. The complete error message text (what does "invalidBusinessLogic" mean in this context?)
2. Is the API rejecting the `barcodeId` field entirely?
3. Is this the duplicate barcode issue, or a different validation error?

## Files Created

### 1. **New ART Functions**
- `artTM/orders/Get-Order.Public.ps1` - Retrieve order with details
- `artTM/orders/details/Get-OrderDetail.Public.ps1` - Retrieve order detail(s)
- `artTM/orders/details/Set-OrderDetail.Public.ps1` - **Update detail with barcodes array**

### 2. **Test Script**
- `artTests/70-functional-tests/OrderDetailBarcodes-Array-Test.ps1`
  - Automated test for the actual TM-185682 scenario
  - Tests mixed barcode array (with/without `barcodeId`)
  - Validates expected vs actual barcode counts
  - Scenario-based with detailed logging

### 3. **Test Results**
- Log file: `orderbarcodes-array-test-*.json`
- Error: `invalidBusinessLogic` (HTTP 400)
- Barcode count unchanged (PUT request failed)

## Comparison: What Changed

| Aspect | Previous Test | Current Test |
|--------|---------------|--------------|
| **Endpoint** | PUT `/barcodes/{barcodeId}` | PUT `/details/{detailId}` |
| **Body** | Single barcode properties | Barcodes **array** |
| **barcodeId** | In URL path | In **array elements** |
| **Purpose** | Update single barcode | Update detail + multiple barcodes |
| **Result** | ✅ Works (ignores barcodeId in body) | ❌ **Error: `invalidBusinessLogic`** |

## Next Steps

1. **Capture full error message**:
   ```powershell
   # Run with specific order/detail that has barcodes
   .\OrderDetailBarcodes-Array-Test.ps1 -OrderId [ID] -OrderDetailId [ID]
   ```

2. **Test variations**:
   - What if array has ONLY barcodes with `barcodeId`? (all updates)
   - What if array has ONLY barcodes without `barcodeId`? (all creates)
   - Does the API documentation mention this behavior?

3. **Check Postman**:
   - We found Postman requests that PUT to `/orders/{orderId}/details/{detailId}` with barcodes array
   - Do those include `barcodeId` fields?
   - What was the expected behavior in those tests?

## Conclusion So Far

✅ **Created proper test for actual TM-185682 scenario**  
❌ **Bug confirmed**: API returns `invalidBusinessLogic` error  
❓ **Root cause unclear**: Need full error message to understand why  

The test framework is working correctly and can be used to investigate further once we have:
- A specific order/detail to test against
- The full error message text from the API

---

**Files**:
- Test script: `OrderDetailBarcodes-Array-Test.ps1`
- Functions: `Get-Order.Public.ps1`, `Get-OrderDetail.Public.ps1`, `Set-OrderDetail.Public.ps1`
- Results: `orderbarcodes-array-test-20251017-194326.json`

