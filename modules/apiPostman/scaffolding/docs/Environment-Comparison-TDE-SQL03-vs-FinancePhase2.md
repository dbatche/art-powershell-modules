# Environment Comparison Report
## TDE-SQL03 vs Finance Phase 2 (Automation)

**Date**: October 9, 2025  
**Purpose**: Identify missing variables causing test failures

---

## ⚠️ Critical Finding

**TDE-SQL03 is missing `FUEL_TAX_ID`** which is required for the tripFuelPurchases tests.

---

## Missing Variables

### In Finance Phase 2 (Automation) but NOT in TDE-SQL03:

| Variable | Value | Impact |
|----------|-------|--------|
| **FUEL_TAX_ID** | `2` | 🔥 **CRITICAL** - Required for tripFuelPurchases tests |
| INTERLINER_PAYABLE_ID | `1` | Needed for interlinerPayables tests |
| AP_INVOICE_DEDUCTION_ID | `975` | Needed for AP Invoice deduction tests |

### In TDE-SQL03 but NOT in Finance Phase 2:

| Variable | Value | Notes |
|----------|-------|-------|
| DRIVER_NONTAX_DEDUCTION_CODE | `NONTAXABLE` | TDE-specific |
| DRIVER_DEDUCTION_CODE_CONTROLLED | `LOANOT4` | TDE-specific (duplicate entry) |
| DRIVER_PAY_CONTRACT_ID | `3` | TDE-specific |
| DEDUCTION_DRIVER_CONTRACT_ID | `4` | TDE-specific |
| ISTA_GROUP_CODE | `ISTA1` | TDE-specific |
| adminTaxDeductionEnabledCode | `AdminFee` | TDE-specific |
| *(empty key)* | `driverStatements` | Invalid variable |
| *(empty key)* | *(empty)* | Invalid variable |

---

## Different Values

### Domain Configurations

| Variable | TDE-SQL03 | Finance Phase 2 (Automation) |
|----------|-----------|------------------------------|
| **DOMAIN** | `https://tde-truckmate.tmwcloud.com/fin/finance` | `http://van-dev-api-01.am.trimblecorp.net:8481/finance` |
| **TM_DOMAIN** | `https://tde-truckmate.tmwcloud.com/fin/tm` | `http://van-dev-api-01.am.trimblecorp.net:8483/tm` |
| **MD_DOMAIN** | `https://tde-truckmate.tmwcloud.com/fin/masterData` | `http://van-dev-api-01.am.trimblecorp.net:8482/masterData` |

**Note**: Different environments point to different servers
- **TDE-SQL03**: Production-like TDE environment
- **Finance Phase 2**: Internal dev server

### Test Data IDs

| Variable | TDE-SQL03 | Finance Phase 2 |
|----------|-----------|-----------------|
| CHECKLIST_DRIVER_PAYMENT_ID | `229036` | `229033` |
| AP_INVOICE_ID_REGISTERED | `{"apInvoiceId":1071,"expenseId":2480,"deductionId":19,"istaId":6}` | `{"apInvoiceId":978,"expenseId":2476,"deductionId":8,"istaId":5}` |

**Note**: Each environment has its own test data with different IDs

---

## Statistics

| Environment | Total Variables | Unique Variables |
|-------------|-----------------|------------------|
| TDE-SQL03 | 41 | 8 |
| Finance Phase 2 (Automation) | 35 | 3 |
| **Common** | **32** | - |

---

## Impact on Testing

### Current Issue

The POST request to `/fuelTaxes/{{FUEL_TAX_ID}}/tripFuelPurchases` fails in TDE-SQL03 because:
1. `{{FUEL_TAX_ID}}` is undefined
2. URL becomes `/fuelTaxes//tripFuelPurchases` (invalid)

### Recommended Actions

**Option 1: Add Missing Variables to TDE-SQL03**

Add to TDE-SQL03 environment:
```
FUEL_TAX_ID = 2
INTERLINER_PAYABLE_ID = 1
AP_INVOICE_DEDUCTION_ID = 975
```

✅ **Pros**: Quick fix, tests work immediately  
⚠️ **Cons**: Need to verify these IDs exist in TDE database

**Option 2: Find Correct TDE IDs**

Query TDE database to find existing fuel tax records:
```sql
SELECT TOP 1 fuelTaxId FROM FuelTax WHERE ...
```

Then add the correct ID to TDE-SQL03 environment.

✅ **Pros**: Uses correct test data  
⚠️ **Cons**: Requires database access

**Option 3: Use Finance Phase 2 Environment**

Switch to "Finance Phase 2 (Automation)" environment which has all variables.

✅ **Pros**: Everything works  
⚠️ **Cons**: Points to different server (van-dev-api-01)

---

## Detailed Variable Lists

### TDE-SQL03 Variables (41)

<details>
<summary>Click to expand full list</summary>

1. DOMAIN
2. TM_DOMAIN
3. MD_DOMAIN
4. TRUCKMATE_API_KEY
5. VENDOR_ID
6. VENDOR_BILL_ID
7. GL_ACCOUNT_ID
8. CURRENCY_CODE
9. TAX_ID
10. CASH_RECEIPT_ID
11. CHECK_ID
12. DRIVER_PAYMENT_ID
13. DRIVER_DEDUCTION_ID
14. CHECKLIST_DRIVER_PAYMENT_ID
15. EMPLOYEE_PAYMENT_ID
16. AP_INVOICE_ID_REGISTERED
17. DRIVER_NONTAX_DEDUCTION_CODE ⚠️ Unique to TDE
18. DRIVER_DEDUCTION_CODE_CONTROLLED ⚠️ Unique to TDE
19. DRIVER_PAY_CONTRACT_ID ⚠️ Unique to TDE
20. DRIVER_DEDUCTION_CODE_CONTROLLED ⚠️ Duplicate
21. DEDUCTION_DRIVER_CONTRACT_ID ⚠️ Unique to TDE
22. (empty key) ⚠️ Invalid
23. ISTA_GROUP_CODE ⚠️ Unique to TDE
24. adminTaxDeductionEnabledCode ⚠️ Unique to TDE
25. (empty key) ⚠️ Invalid
26-41. (Other common variables)

</details>

### Finance Phase 2 (Automation) Variables (35)

<details>
<summary>Click to expand full list</summary>

1. DOMAIN
2. TM_DOMAIN
3. MD_DOMAIN
4. TRUCKMATE_API_KEY
5. VENDOR_ID
6. VENDOR_BILL_ID
7. GL_ACCOUNT_ID
8. CURRENCY_CODE
9. TAX_ID
10. CASH_RECEIPT_ID
11. CHECK_ID
12. DRIVER_PAYMENT_ID
13. DRIVER_DEDUCTION_ID
14. CHECKLIST_DRIVER_PAYMENT_ID
15. EMPLOYEE_PAYMENT_ID
16. AP_INVOICE_ID_REGISTERED
17. **FUEL_TAX_ID** ⚠️ Missing in TDE-SQL03
18. **INTERLINER_PAYABLE_ID** ⚠️ Missing in TDE-SQL03
19. **AP_INVOICE_DEDUCTION_ID** ⚠️ Missing in TDE-SQL03
20-35. (Other common variables)

</details>

---

## Environment Cleanup Recommendations

### TDE-SQL03

**Issues Found**:
1. Two entries with empty key names (invalid)
2. Duplicate key: `DRIVER_DEDUCTION_CODE_CONTROLLED`
3. Missing 3 critical test data IDs

**Recommended Cleanup**:
1. Remove invalid entries (empty keys)
2. Remove duplicate `DRIVER_DEDUCTION_CODE_CONTROLLED`
3. Add missing test data IDs
4. Verify all variable names follow naming convention

### Finance Phase 2 (Automation)

**Status**: ✅ Clean, no issues found

---

## How to Update TDE-SQL03

### Via Postman UI

1. Open Postman
2. Click "Environments" (left sidebar)
3. Select "TDE-SQL03"
4. Click "Add new variable"
5. Add:
   - Key: `FUEL_TAX_ID`, Initial Value: `2`, Current Value: `2`
   - Key: `INTERLINER_PAYABLE_ID`, Initial Value: `1`, Current Value: `1`
   - Key: `AP_INVOICE_DEDUCTION_ID`, Initial Value: `975`, Current Value: `975`
6. Save

### Via Postman API

```powershell
$tdeEnvUid = "11896768-68887950-1feb-4817-87c5-f5dcffa370cb"
$apiKey = "YOUR_API_KEY"

# Get current environment
$env = Invoke-RestMethod -Uri "https://api.getpostman.com/environments/$tdeEnvUid" -Headers @{"X-Api-Key" = $apiKey}

# Add new variables
$env.environment.values += @(
    @{ key = "FUEL_TAX_ID"; value = "2"; enabled = $true; type = "default" },
    @{ key = "INTERLINER_PAYABLE_ID"; value = "1"; enabled = $true; type = "default" },
    @{ key = "AP_INVOICE_DEDUCTION_ID"; value = "975"; enabled = $true; type = "default" }
)

# Update environment
$body = @{ environment = $env.environment } | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri "https://api.getpostman.com/environments/$tdeEnvUid" -Headers @{"X-Api-Key" = $apiKey; "Content-Type" = "application/json"} -Method Put -Body $body
```

---

## Next Steps

1. **Immediate**: Add `FUEL_TAX_ID = 2` to TDE-SQL03 to unblock testing
2. **Verify**: Check if fuelTaxId = 2 exists in TDE database
3. **Optional**: Add other missing IDs if needed for future tests
4. **Cleanup**: Remove invalid/duplicate entries from TDE-SQL03

---

**Report Generated**: October 9, 2025  
**Tool**: PowerShell + Postman API  
**Author**: AI Assistant + Doug Batchelor

