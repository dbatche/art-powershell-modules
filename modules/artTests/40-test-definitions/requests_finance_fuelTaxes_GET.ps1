@(
    # ========== Basic GET Tests - Main Collection ==========
    @{ Name = 'GET all fuelTaxes'; 
       Method = 'GET'; 
       Url = '/fuelTaxes'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes - pagination'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=10&offset=0'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes - single result'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes - by ID filter'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId eq 2'; 
       ExpectedStatus = 200 },

    # ========== Individual Item Tests ==========
    @{ Name = 'GET fuelTaxes/2'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes/2 - with expand all'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2?expand=tripSegments,tripFuelPurchases,tripWaypoints'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes/2 - expand tripFuelPurchases only'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2?expand=tripFuelPurchases'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET fuelTaxes - nonexistent ID'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/999999999'; 
       ExpectedStatus = 404 },

    # ========== Sub-Collection Tests - tripFuelPurchases ==========
    @{ Name = 'GET tripFuelPurchases - all'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases - pagination'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?limit=5&offset=0'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases - single result'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases - by volume filter'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelVolume1 gt 100'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases - invalid parent ID'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/999999999/tripFuelPurchases'; 
       ExpectedStatus = 404 },

    # ========== Individual tripFuelPurchase Tests ==========
    @{ Name = 'GET tripFuelPurchases/42'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases/42 - with $select'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42?$select=tripFuelPurchaseId,purchaseDate,fuelVolume1'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET tripFuelPurchases - nonexistent item'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/999999999'; 
       ExpectedStatus = 404 },

    # ========== Filter Tests - Main Collection ==========
    @{ Name = 'Filter fuelTaxes - equals'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId eq 2'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter fuelTaxes - not equals'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId ne 1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter fuelTaxes - greater than'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId gt 1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter fuelTaxes - less than'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId lt 10'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter fuelTaxes - invalid field'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=nonExistentField eq ''value'''; 
       ExpectedStatus = 400 },

    @{ Name = 'Filter fuelTaxes - invalid operator'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId xx 2'; 
       ExpectedStatus = 400 },

    # ========== Filter Tests - Sub-Collection ==========
    @{ Name = 'Filter tripFuelPurchases - equals'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelType1 eq ''DIESEL'''; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter tripFuelPurchases - greater than'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelVolume1 gt 100'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter tripFuelPurchases - less than'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelAmount1 lt 500'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter tripFuelPurchases - and operator'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelVolume1 gt 50 and fuelVolume1 lt 200'; 
       ExpectedStatus = 200 },

    # ========== Select Tests ==========
    @{ Name = 'Select fuelTaxes - single field'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$select=fuelTaxId&limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Select fuelTaxes - multiple fields'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$select=fuelTaxId,tripNumber,driverId&limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Select tripFuelPurchases - specific fields'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$select=tripFuelPurchaseId,purchaseDate,fuelVolume1&limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Select fuelTaxes - invalid field'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$select=nonExistentField'; 
       ExpectedStatus = 400 },

    @{ Name = 'Select tripFuelPurchases - invalid field'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$select=invalidField'; 
       ExpectedStatus = 400 },

    # ========== OrderBy Tests ==========
    @{ Name = 'OrderBy fuelTaxes - ascending'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$orderby=fuelTaxId asc'; 
       ExpectedStatus = 200 },

    @{ Name = 'OrderBy fuelTaxes - descending'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$orderby=fuelTaxId desc'; 
       ExpectedStatus = 200 },

    @{ Name = 'OrderBy tripFuelPurchases - ascending'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$orderby=purchaseDate asc'; 
       ExpectedStatus = 200 },

    @{ Name = 'OrderBy tripFuelPurchases - descending'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$orderby=fuelVolume1 desc'; 
       ExpectedStatus = 200 },

    # ========== Combined Query Tests ==========
    @{ Name = 'Filter + Pagination'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId gt 1&limit=5&offset=0'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter + Select'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId eq 2&$select=fuelTaxId,tripNumber'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter + OrderBy'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId gt 1&$orderby=fuelTaxId desc'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter + Select + Pagination'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=fuelVolume1 gt 50&$select=tripFuelPurchaseId,fuelVolume1&limit=3'; 
       ExpectedStatus = 200 },

    # ========== Query Parameter Validation ==========
    @{ Name = 'limit - negative'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=-10'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - zero'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=0'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - out of bounds'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=99999'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - decimal'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=10.5'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - string'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=abc'; 
       ExpectedStatus = 400 },

    @{ Name = 'offset - negative'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?offset=-5'; 
       ExpectedStatus = 400 },

    @{ Name = 'offset - string'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?offset=abc'; 
       ExpectedStatus = 400 },

    # ========== Edge Cases ==========
    @{ Name = 'Edge - very large limit (within bounds)'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?limit=1000'; 
       ExpectedStatus = 200 },

    @{ Name = 'Edge - very large offset'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?offset=10000'; 
       ExpectedStatus = 200 },

    @{ Name = 'Edge - filter with special characters in string'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$filter=contains(purchaseLocation, ''Test & Location'')'; 
       ExpectedStatus = 200 },

    @{ Name = 'Edge - empty result set'; 
       Method = 'GET'; 
       Url = '/fuelTaxes?$filter=fuelTaxId eq 999999999'; 
       ExpectedStatus = 200 },  # Should return empty array, not 404

    @{ Name = 'Edge - multiple orderby fields'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?$orderby=purchaseDate desc,fuelVolume1 asc'; 
       ExpectedStatus = 200 }
)

