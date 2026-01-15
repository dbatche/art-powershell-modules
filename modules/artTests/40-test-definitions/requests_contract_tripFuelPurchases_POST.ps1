# Contract-driven tests for POST /fuelTaxes/{fuelTaxId}/tripFuelPurchases
# Generated: 2025-10-09 12:14:20
# Schema: PostFuelTaxTripFuelPurchaseDtoList
# Required Fields: NONE
# Total Properties: 36

@(
    @{
        Name = 'POST - empty object (no fields)'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{  })
    },
    @{
        Name = 'POST - invalid enum: receipt'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ receipt = 'InvalidEnumValue_NotInList' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelCardNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelCardNumber = 'AAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: user2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ user2 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelInvoiceNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelInvoiceNumber = 'AAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationCity'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationCity = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: purchaseLocation'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseLocation = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelType2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelType2 = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid enum: purchaseType'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseType = 'InvalidEnumValue_NotInList'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationVendor'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationVendor = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: user3'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ user3 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: driverId1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ driverId1 = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationId'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationId = 'AAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationName'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationName = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelType1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelType1 = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid enum: unit'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ unit = 'InvalidEnumValue_NotInList'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid enum: taxPaid'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxPaid = 'InvalidEnumValue_NotInList'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: currencyCode'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ currencyCode = 'AAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: purchaseJurisdiction'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseJurisdiction = 'AAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: user1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ user1 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationPostalCode'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationPostalCode = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid pattern: purchaseDate'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseDate = 'InvalidPatternValue'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid enum: taxable'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'InvalidEnumValue_NotInList'; receipt = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: driverId2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ driverId2 = 'AAAAAAAAAAA'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid type (number for string): receipt'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ receipt = 12345 })
    },
    @{
        Name = 'POST - invalid type (number for string): fuelCardNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelCardNumber = 12345; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid type (number for string): user2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ user2 = 12345; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid type (string for number): fuelCost1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelCost1 = 'not-a-number'; receipt = 'False' })
    },
    @{
        Name = 'POST - invalid type (number for string): fuelInvoiceNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelInvoiceNumber = 12345; receipt = 'False' })
    },
    @{
        Name = 'POST - minimal valid request'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 201
        Body = @(@{ receipt = 'False' })
    },
    @{
        Name = 'POST - all fields with valid data'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 201
        Body = @(@{ fuelCardNumber = 'AAAAAAAAAA'; user2 = 'AAAAAAAAAA'; receipt = 'False'; fuelInvoiceNumber = 'AAAAAAAAAA'; odometer = 100; fuelStationCity = 'AAAAAAAAAA'; purchaseLocation = 'AAAAAAAAAA'; fuelType2 = 'AAAAAAAAAA'; currencyCode = 'AAA'; reeferFuelCost = 100; purchaseType = 'bulk'; fuelStationVendor = 'AAAAAAAAAA'; fuelRate1 = 100; user3 = 'AAAAAAAAAA'; driverId1 = 'AAAAAAAAAA'; fuelStationId = 'AAAAAAAAAA'; fuelCost1 = 100; taxPaid = 'False'; cost = 100; fuelStationName = 'AAAAAAAAAA'; fuelType1 = 'AAAAAAAAAA'; unit = 'GAL'; reeferFuelVolume = 100; volume = 100; taxable = 'False'; purchaseJurisdiction = 'AAAA'; user1 = 'AAAAAAAAAA'; fuelRate2 = 100; fuelVolume1 = 100; reeferFuelRate = 100; purchaseDate = '2025-01-15T10:30:00'; fuelCardVendor = 1; driverId2 = 'AAAAAAAAAA'; fuelVolume2 = 100; fuelCost2 = 100; fuelStationPostalCode = 'AAAAAAAAAA' })
    }
)
