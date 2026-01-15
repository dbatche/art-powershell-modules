# Manual test definitions
# Created: 2025-10-10 15:22:35

@(
    @{
        Name = 'Modify a posted invoice'
        Method = 'PUT'
        Url = '/apInvoices/5'
        ExpectedStatus = 400
        Body = 'auditNumber=22'
    },

    @{
        Name = 'Modify a posted invoice'
        Method = 'PUT'
        Url = '/apInvoices/5'
        ExpectedStatus = 400
        Body = @{ auditNumber = 22 }
    }
)
