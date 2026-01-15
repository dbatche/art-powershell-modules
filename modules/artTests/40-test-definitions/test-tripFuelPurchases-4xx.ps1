# Contract-driven tests for POST /fuelTaxes/{fuelTaxId}/tripFuelPurchases
# Generated: 2025-10-13 02:09:10
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
        Name = 'POST - invalid enum: taxable'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'InvalidEnumValue_NotInList' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelType1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelType1 = 'AAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelCardNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelCardNumber = 'AAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationId'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationId = 'AAAAAAAAAAAAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationName'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelStationName = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: driverId2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; driverId2 = 'AAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: user2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; user2 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationPostalCode'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationPostalCode = 'AAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: user1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ user1 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - invalid pattern: purchaseDate'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseDate = 'InvalidPatternValue'; taxable = 'False' })
    },
    @{
        Name = 'POST - invalid enum: purchaseType'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; purchaseType = 'InvalidEnumValue_NotInList' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationCity'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelStationCity = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelInvoiceNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelInvoiceNumber = 'AAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: currencyCode'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ currencyCode = 'AAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: user3'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; user3 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelType2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelType2 = 'AAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: purchaseJurisdiction'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseJurisdiction = 'AAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - invalid enum: receipt'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; receipt = 'InvalidEnumValue_NotInList' })
    },
    @{
        Name = 'POST - invalid enum: unit'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; unit = 'InvalidEnumValue_NotInList' })
    },
    @{
        Name = 'POST - invalid enum: taxPaid'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxPaid = 'InvalidEnumValue_NotInList'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: driverId1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ driverId1 = 'AAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - exceeds maxLength: fuelStationVendor'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelStationVendor = 'AAAAAAAAAAA' })
    },
    @{
        Name = 'POST - exceeds maxLength: purchaseLocation'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ purchaseLocation = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; taxable = 'False' })
    },
    @{
        Name = 'POST - invalid type (number for string): taxable'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 12345 })
    },
    @{
        Name = 'POST - invalid type (number for string): fuelType1'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelType1 = 12345 })
    },
    @{
        Name = 'POST - invalid type (number for string): fuelCardNumber'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelCardNumber = 12345 })
    },
    @{
        Name = 'POST - invalid type (number for string): fuelStationId'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ fuelStationId = 12345; taxable = 'False' })
    },
    @{
        Name = 'POST - invalid type (string for number): fuelVolume2'
        Method = 'POST'
        Url = '/fuelTaxes/2/tripFuelPurchases'
        ExpectedStatus = 400
        Body = @(@{ taxable = 'False'; fuelVolume2 = 'not-a-number' })
    }
)
