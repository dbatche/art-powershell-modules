# Contract-driven tests for PUT /cashReceipts/{cashReceiptId}
# Generated: 2025-10-17 02:18:49
# Schema: PutCashReceipt
# Required Fields: NONE
# Total Properties: 1

@(
    @{
        Name = 'PUT - empty object (no fields)'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'noValidFields'
        Type = 'Contract'
        Body = @{  }
    },
    @{
        Name = 'PUT - exceeds maxLength: checkReference'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: clientId'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Type = 'Contract'
        Body = @{ clientId = 'AAAAAAAAAAA'; checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: bankAccount'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Type = 'Contract'
        Body = @{ bankAccount = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'; checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid pattern: checkDate'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA'; checkDate = 'InvalidPatternValue' }
    },
    @{
        Name = 'PUT - invalid enum: postDated'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA'; postDated = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - exceeds maxLength: checkNumber'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'exceedsMaxLength'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA'; checkNumber = 'AAAAAAAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): checkReference'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Type = 'Contract'
        Body = @{ checkReference = 12345 }
    },
    @{
        Name = 'PUT - invalid type (string for number): checkAmount'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDouble'
        Type = 'Contract'
        Body = @{ checkAmount = 'not-a-number'; checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): clientId'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Type = 'Contract'
        Body = @{ clientId = 12345; checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): bankAccount'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Type = 'Contract'
        Body = @{ bankAccount = 12345; checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): checkDate'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA'; checkDate = 12345 }
    },
    @{
        Name = 'PUT - missing required parameter: cashReceiptId'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345'
        ExpectedStatus = 400
        ExpectedErrorCode = 'missingRequiredField'
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type for parameter: cashReceiptId'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345?cashReceiptId=not_a_number'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - OData parameter invalid syntax: $select'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345?$select=invalid,,field'
        ExpectedStatus = 400
        Type = 'Contract'
        Body = @{ checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - minimal valid request'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345?cashReceiptId=1'
        ExpectedStatus = 200
        Type = 'Functional'
        Body = @{ checkReference = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - all fields with valid data'
        Method = 'PUT'
        Url = 'https://tde-truckmate.tmwcloud.com/fin/finance/cashReceipts/12345?cashReceiptId=1&$select=test'
        ExpectedStatus = 200
        Type = 'Functional'
        Body = @{ postDated = 'False'; checkReference = 'AAAAAAAAAA'; checkNumber = 'AAAAAAAAAA'; checkAmount = 100; checkDate = '2025-01-15'; bankAccount = 'AAAAAAAAAA'; clientId = 'AAAAAAAAAA' }
    }
)
