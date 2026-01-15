@(
    # ========== Setup: GET existing records to use for PUT tests ==========
    @{ Name = 'GET tripFuelPurchases for PUT testing'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2/tripFuelPurchases?limit=5'; 
       ExpectedStatus = 200 },

    # NOTE: Use actual IDs from the GET results above
    # For these tests, we'll use tripFuelPurchaseId = 42 (from recent POST tests)
    # Adjust the ID if needed based on your data

    # ========== PUT Success Tests - Individual Item ==========
    @{ Name = 'PUT tripFuelPurchases - minimal update'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 175.5
           fuelCost1 = 263.25
       } },

    @{ Name = 'PUT tripFuelPurchases - update multiple fields'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           purchaseDate = '2025-01-16T14:30:00'
           fuelVolume1 = 200.0
           fuelCost1 = 300.00
           fuelType1 = 'DIESEL'
           purchaseLocation = 'Updated Test Location'
       } },

    @{ Name = 'PUT tripFuelPurchases - add second fuel type'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 180.0
           fuelCost1 = 270.00
           fuelType1 = 'DIESEL'
           fuelVolume2 = 45.0
           fuelCost2 = 67.50
           fuelType2 = 'DEF'
       } },

    @{ Name = 'PUT tripFuelPurchases - update with all optional fields'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           purchaseDate = '2025-01-17T10:00:00'
           fuelVolume1 = 250.0
           fuelCost1 = 375.00
           fuelType1 = 'DIESEL'
           purchaseLocation = 'Full Update Location'
           vendorId = 'VENDOR01'
           invoiceNumber = 'INV-UPDATE-001'
           purchaseCardNumber = '5678'
           odometerReading = 130000
       } },

    @{ Name = 'PUT tripFuelPurchases - remove second fuel type'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 150.0
           fuelCost1 = 225.00
           fuelType1 = 'DIESEL'
           fuelVolume2 = $null
           fuelCost2 = $null
           fuelType2 = ''
       } },

    @{ Name = 'PUT tripFuelPurchases - update with $select'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42?$select=tripFuelPurchaseId,fuelVolume1,fuelCost1'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 155.0
           fuelCost1 = 232.50
       } },

    # ========== PUT Validation Tests - Not Found ==========
    @{ Name = 'PUT tripFuelPurchases - nonexistent tripFuelPurchaseId'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/999999999'; 
       ExpectedStatus = 404;
       Body = @{
           fuelVolume1 = 150.0
       } },

    @{ Name = 'PUT tripFuelPurchases - nonexistent fuelTaxId'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/999999999/tripFuelPurchases/42'; 
       ExpectedStatus = 404;
       Body = @{
           fuelVolume1 = 150.0
       } },

    # ========== PUT Validation Tests - Invalid Data ==========
    @{ Name = 'PUT tripFuelPurchases - negative volume'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelVolume1 = -50.0
       } },

    @{ Name = 'PUT tripFuelPurchases - negative amount'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelCost1 = -100.00
       } },

    @{ Name = 'PUT tripFuelPurchases - zero volume'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelVolume1 = 0
       } },

    @{ Name = 'PUT tripFuelPurchases - empty fuelType'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelType1 = ''
       } },

    @{ Name = 'PUT tripFuelPurchases - invalid date format'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           purchaseDate = '2025-01-17'  # Missing time
       } },

    @{ Name = 'PUT tripFuelPurchases - invalid vendorId'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           vendorId = 'INVALID_VENDOR_9999'
       } },

    # ========== PUT Validation Tests - Data Type Errors ==========
    @{ Name = 'PUT tripFuelPurchases - volume as string'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelVolume1 = 'not-a-number'
       } },

    @{ Name = 'PUT tripFuelPurchases - amount as string'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           fuelCost1 = 'not-a-number'
       } },

    @{ Name = 'PUT tripFuelPurchases - odometer as string'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           odometerReading = 'not-a-number'
       } },

    # ========== PUT Edge Cases ==========
    @{ Name = 'PUT tripFuelPurchases - very large volume'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 99999.99
           fuelCost1 = 149999.99
       } },

    @{ Name = 'PUT tripFuelPurchases - very long location'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{
           purchaseLocation = 'A' * 200
       } },

    @{ Name = 'PUT tripFuelPurchases - minimal decimal values'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           fuelVolume1 = 0.01
           fuelCost1 = 0.01
       } },

    @{ Name = 'PUT tripFuelPurchases - empty body'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 400;
       Body = @{} },

    @{ Name = 'PUT tripFuelPurchases - update only location'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           purchaseLocation = 'New Location Only'
       } },

    @{ Name = 'PUT tripFuelPurchases - update only date'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42'; 
       ExpectedStatus = 200;
       Body = @{
           purchaseDate = '2025-01-20T08:00:00'
       } },

    # ========== Query Parameter Tests ==========
    @{ Name = 'PUT tripFuelPurchases - invalid query param'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42?invalidParam=test'; 
       ExpectedStatus = 400;
       Body = @{
           fuelVolume1 = 150.0
       } },

    @{ Name = 'PUT tripFuelPurchases - $select with invalid field'; 
       Method = 'PUT'; 
       Url = '/fuelTaxes/2/tripFuelPurchases/42?$select=nonExistentField'; 
       ExpectedStatus = 400;
       Body = @{
           fuelVolume1 = 150.0
       } }
)

