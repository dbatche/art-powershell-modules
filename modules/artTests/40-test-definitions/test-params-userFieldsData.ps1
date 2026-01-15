# Contract-driven tests for GET /userFieldsData
# Generated: 2025-10-10 02:57:34
# Schema: 
# Required Fields: NONE
# Total Properties: 0

@(
    @{
        Name = 'GET - empty object (no fields)'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData'
        ExpectedStatus = 400
        Body = @{  }
    },
    @{
        Name = 'GET - missing required parameter: sourceType'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid enum for parameter: sourceType'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?sourceType=INVALID_ENUM_VALUE'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid type for parameter: sourceId'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?sourceId=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid type for parameter: userField'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?userField=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid type for parameter: limit'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?limit=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - invalid type for parameter: offset'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?offset=not_a_number'
        ExpectedStatus = 400
        Body = $null
    },
    @{
        Name = 'GET - valid request with required parameters'
        Method = 'GET'
        Url = 'https://tde-truckmate.tmwcloud.com/cur/finance/userFieldsData?sourceType=driverStatements'
        ExpectedStatus = 200
        Body = $null
    }
)
