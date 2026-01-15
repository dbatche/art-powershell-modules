@(
    # ========== Setup: Verify test data exists ==========
    @{ Name = 'GET fuelTaxes/2 - verify exists for POST tests'; 
       Method = 'GET'; 
       Url = '/fuelTaxes/2'; 
       ExpectedStatus = 200 },

    # ========== POST Tests - Create tripFuelPurchases ==========
    @{ Name = 'POST tripFuelPurchases - minimal fields'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 201;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - all fields'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 201;
       Body = @(
           @{
               purchaseDate = '2025-01-15T14:30:00'
               fuelVolume1 = 200.0
               fuelCost1 = 300.00
               fuelType1 = 'DIESEL'
               fuelVolume2 = 50.0
               fuelCost2 = 75.00
               fuelType2 = 'DEF'
               purchaseLocation = 'Test Truck Stop'
               vendorId = 'VENDOR01'
               invoiceNumber = 'INV-TEST-001'
               purchaseCardNumber = '1234'
               odometerReading = 125000
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - multiple items'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 201;
       Body = @(
           @{
               purchaseDate = '2025-01-15T08:00:00'
               fuelVolume1 = 100.0
               fuelCost1 = 150.00
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Location A'
           },
           @{
               purchaseDate = '2025-01-15T16:00:00'
               fuelVolume1 = 125.0
               fuelCost1 = 187.50
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Location B'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - with second fuel type'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 201;
       Body = @(
           @{
               purchaseDate = '2025-01-15T12:00:00'
               fuelVolume1 = 180.0
               fuelCost1 = 270.00
               fuelType1 = 'DIESEL'
               fuelVolume2 = 45.0
               fuelCost2 = 67.50
               fuelType2 = 'DEF'
               purchaseLocation = 'Full Service Station'
           }
       ) },

    # ========== POST Validation Tests - Invalid Data ==========
    @{ Name = 'POST tripFuelPurchases - invalid parent ID'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/999999999/tripFuelPurchases'; 
       ExpectedStatus = 404;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - not an array'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @{
           purchaseDate = '2025-01-15T10:30:00'
           fuelVolume1 = 150.5
           fuelCost1 = 225.75
           fuelType1 = 'DIESEL'
           purchaseLocation = 'Test Location'
       } },

    @{ Name = 'POST tripFuelPurchases - invalid date format'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15'  # Missing time
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - negative volume'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = -50.0
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - negative amount'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = -100.00
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - empty fuelType'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = ''
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - volume without amount'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - amount without volume'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    # ========== POST Validation Tests - Data Type Errors ==========
    @{ Name = 'POST tripFuelPurchases - volume as string'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 'not-a-number'
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - amount as string'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 'not-a-number'
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
           }
       ) },

    @{ Name = 'POST tripFuelPurchases - invalid vendorId'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test Location'
               vendorId = 'INVALID_VENDOR_9999'
           }
       ) },

    # ========== PUT Tests - Update tripFuelPurchases ==========
    # Note: These need actual IDs from POST results
    # @{ Name = 'PUT tripFuelPurchases - minimal update'; 
    #    Method = 'PUT'; 
    #    Url = '/fuelTaxes/2/tripFuelPurchases/1'; 
    #    ExpectedStatus = 200;
    #    Body = @{
    #        fuelVolume1 = 175.0
    #        fuelCost1 = 262.50
    #    } },

    # @{ Name = 'PUT tripFuelPurchases - update all fields'; 
    #    Method = 'PUT'; 
    #    Url = '/fuelTaxes/2/tripFuelPurchases/1'; 
    #    ExpectedStatus = 200;
    #    Body = @{
    #        purchaseDate = '2025-01-16T10:30:00'
    #        fuelVolume1 = 200.0
    #        fuelCost1 = 300.00
    #        fuelType1 = 'DIESEL'
    #        fuelVolume2 = 60.0
    #        fuelCost2 = 90.00
    #        fuelType2 = 'DEF'
    #        purchaseLocation = 'Updated Location'
    #        vendorId = 'VENDOR02'
    #        invoiceNumber = 'INV-UPDATED-001'
    #    } },

    # @{ Name = 'PUT tripFuelPurchases - invalid ID'; 
    #    Method = 'PUT'; 
    #    Url = '/fuelTaxes/2/tripFuelPurchases/999999999'; 
    #    ExpectedStatus = 404;
    #    Body = @{
    #        fuelVolume1 = 175.0
    #    } },

    # ========== POST Edge Cases ==========
    @{ Name = 'Edge - very large volume'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 201;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 99999.99
               fuelCost1 = 149999.99
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Bulk Purchase'
           }
       ) },

    @{ Name = 'Edge - zero volume'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 0
               fuelCost1 = 0
               fuelType1 = 'DIESEL'
               purchaseLocation = 'Test'
           }
       ) },

    @{ Name = 'Edge - empty array'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;
       Body = @() },

    @{ Name = 'Edge - very long location string'; 
       Method = 'POST'; 
       Url = '/fuelTaxes/2/tripFuelPurchases'; 
       ExpectedStatus = 400;  # FIXED: Exceeds maxLength (30), should be rejected
       Body = @(
           @{
               purchaseDate = '2025-01-15T10:30:00'
               fuelVolume1 = 150.5
               fuelCost1 = 225.75
               fuelType1 = 'DIESEL'
               purchaseLocation = 'A' * 200  # Very long string (exceeds maxLength: 30)
           }
       ) }
)

