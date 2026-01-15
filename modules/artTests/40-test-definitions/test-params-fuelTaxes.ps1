# Contract-driven tests for GET /fuelTaxes
# Generated: 2025-10-10 02:59:08
# Schema: 
# Required Fields: NONE
# Total Properties: 0

@(
    @{
        Name = 'GET - empty object (no fields)'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/fuelTaxes'
        ExpectedStatus = 400
        Body = @{  }
    },
    @{
        Name = 'GET - invalid type for parameter: limit'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/fuelTaxes?limit=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid type for parameter: offset'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/fuelTaxes?offset=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - valid request with required parameters'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/fuelTaxes'
        ExpectedStatus = 200
        Body = $null
    }
)
