# Contract-driven tests for PUT /userFieldsData
# Generated: 2025-10-14 11:13:11
# Schema: PutUserFieldsDataDto
# Required Fields: NONE
# Total Properties: 1

@(
    @{
        Name = 'PUT - empty object (no fields)'
        Method = 'PUT'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'noValidFields'
        Type = 'Contract'
        Body = @{  }
    },
    @{
        Name = 'PUT - exceeds maxLength: userData'
        Method = 'PUT'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): userData'
        Method = 'PUT'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Type = 'Contract'
        Body = @{ userData = 12345 }
    },
    @{
        Name = 'PUT - missing required parameter: sourceType'
        Method = 'PUT'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'missingRequiredField'
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - missing required parameter: userField'
        Method = 'PUT'
        Url = '/userFieldsData'
        ExpectedStatus = 400
        ExpectedErrorCode = 'missingRequiredField'
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum for parameter: sourceType'
        Method = 'PUT'
        Url = '/userFieldsData?sourceType=INVALID_ENUM_VALUE'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type for parameter: sourceId'
        Method = 'PUT'
        Url = '/userFieldsData?sourceId=not_a_number'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type for parameter: limit'
        Method = 'PUT'
        Url = '/userFieldsData?limit=not_a_number'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - pagination parameter negative: limit'
        Method = 'PUT'
        Url = '/userFieldsData?limit=-1'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - pagination parameter decimal: limit'
        Method = 'PUT'
        Url = '/userFieldsData?limit=5.5'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - pagination parameter out of bounds: limit'
        Method = 'PUT'
        Url = '/userFieldsData?limit=999999999'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type for parameter: offset'
        Method = 'PUT'
        Url = '/userFieldsData?offset=not_a_number'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - pagination parameter negative: offset'
        Method = 'PUT'
        Url = '/userFieldsData?offset=-1'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - pagination parameter decimal: offset'
        Method = 'PUT'
        Url = '/userFieldsData?offset=5.5'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - OData parameter invalid syntax: $select'
        Method = 'PUT'
        Url = '/userFieldsData?$select=invalid,,field'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - minimal valid request'
        Method = 'PUT'
        Url = '/userFieldsData?sourceType=driverStatements&userField=test'
        ExpectedStatus = 200
        Type = 'Functional'
        Body = @{ userData = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - all fields with valid data'
        Method = 'PUT'
        Url = '/userFieldsData?sourceType=driverStatements&sourceId=1&userField=test&limit=1&offset=1&$select=test'
        ExpectedStatus = 200
        Type = 'Functional'
        Body = @{ userData = 'AAAAAAAAAA' }
    }
)
