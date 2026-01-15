@(
    # ========== Basic GET Tests ==========
    @{ Name = 'GET all apInvoices'; 
       Method = 'GET'; 
       Url = '/apInvoices'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET apInvoices - pagination'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=10&offset=0'; 
       ExpectedStatus = 200 },

    @{ Name = 'GET apInvoices - single result'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=1'; 
       ExpectedStatus = 200 },

    # ========== Filter Tests (OData) ==========
    @{ Name = 'Filter - eq (equals)'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorId eq ''VENDOR'''; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter - ne (not equals)'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=auditNumber ne null'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter - lt (less than)'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorBillAmount lt 500'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter - gt (greater than)'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorBillAmount gt 100'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter - contains'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=contains(vendorBillReference, ''REFERENCE'')'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter - by ID'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=apInvoiceId eq 2'; 
       ExpectedStatus = 200 },

    # ========== Expand Tests ==========
    @{ Name = 'Expand - expenses'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=apInvoiceId eq 2&expand=expenses'; 
       ExpectedStatus = 200 },

    @{ Name = 'Expand - apDriverDeductions'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=apInvoiceId eq 2&expand=apDriverDeductions'; 
       ExpectedStatus = 200 },

    @{ Name = 'Expand - ista'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=apInvoiceId eq 2&expand=ista'; 
       ExpectedStatus = 200 },

    # ========== Combined Query Tests ==========
    @{ Name = 'Filter + Pagination'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorBillAmount lt 1000&limit=5&offset=0'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter + Expand'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorId eq ''VENDOR''&expand=expenses&limit=3'; 
       ExpectedStatus = 200 },

    @{ Name = 'Filter + OrderBy'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorId eq ''VENDOR''&$orderby=vendorBillAmount desc'; 
       ExpectedStatus = 200 },

    # ========== Validation Tests - Query Parameters ==========
    @{ Name = 'limit - decimal'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=1.5'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - negative'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=-10'; 
       ExpectedStatus = 400 },

    @{ Name = 'limit - out of bounds'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=99999'; 
       ExpectedStatus = 400 },

    @{ Name = 'offset - decimal'; 
       Method = 'GET'; 
       Url = '/apInvoices?offset=1.5'; 
       ExpectedStatus = 400 },

    @{ Name = 'offset - negative'; 
       Method = 'GET'; 
       Url = '/apInvoices?offset=-5'; 
       ExpectedStatus = 400 },

    @{ Name = 'offset - string'; 
       Method = 'GET'; 
       Url = '/apInvoices?offset=abc'; 
       ExpectedStatus = 400 },

    # ========== Validation Tests - Invalid Filters ==========
    @{ Name = 'Filter - invalid field'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=nonExistentField eq ''value'''; 
       ExpectedStatus = 400 },

    @{ Name = 'Filter - invalid operator'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorId xx ''VENDOR'''; 
       ExpectedStatus = 400 },

    @{ Name = 'Filter - malformed syntax'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorId eq'; 
       ExpectedStatus = 400 },

    # ========== Select Tests ==========
    @{ Name = 'Select - specific fields'; 
       Method = 'GET'; 
       Url = '/apInvoices?$select=apInvoiceId,vendorId,vendorBillAmount&limit=1'; 
       ExpectedStatus = 200 },

    @{ Name = 'Select - invalid field'; 
       Method = 'GET'; 
       Url = '/apInvoices?$select=nonExistentField'; 
       ExpectedStatus = 400 },

    # ========== POST Tests (if your API supports creation) ==========
    # @{ Name = 'POST - create valid invoice'; 
    #    Method = 'POST'; 
    #    Url = '/apInvoices'; 
    #    ExpectedStatus = 201;
    #    Body = @{
    #        vendorId = 'VENDOR'
    #        vendorBillNumber = 'TEST-' + (Get-Date -Format 'yyyyMMddHHmmss')
    #        vendorBillAmount = 100.00
    #        vendorBillDate = '2025-01-01T00:00:00'
    #        currencyCode = 'CAD'
    #    } },

    # @{ Name = 'POST - missing required field'; 
    #    Method = 'POST'; 
    #    Url = '/apInvoices'; 
    #    ExpectedStatus = 400;
    #    Body = @{
    #        vendorBillNumber = 'TEST-001'
    #        vendorBillAmount = 100.00
    #    } },

    # @{ Name = 'POST - invalid amount type'; 
    #    Method = 'POST'; 
    #    Url = '/apInvoices'; 
    #    ExpectedStatus = 400;
    #    Body = @{
    #        vendorId = 'VENDOR'
    #        vendorBillNumber = 'TEST-001'
    #        vendorBillAmount = 'not-a-number'
    #        vendorBillDate = '2025-01-01T00:00:00'
    #    } },

    # ========== Edge Cases ==========
    @{ Name = 'Edge - very large limit'; 
       Method = 'GET'; 
       Url = '/apInvoices?limit=1000'; 
       ExpectedStatus = 200 },

    @{ Name = 'Edge - filter with special characters'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=contains(vendorBillReference, ''test&value'')'; 
       ExpectedStatus = 200 },

    @{ Name = 'Edge - multiple filters'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=vendorBillAmount gt 50 and vendorBillAmount lt 500'; 
       ExpectedStatus = 200 },

    # ========== Error Cases ==========
    @{ Name = 'Error - nonexistent ID'; 
       Method = 'GET'; 
       Url = '/apInvoices?$filter=apInvoiceId eq 999999999'; 
       ExpectedStatus = 200 },  # Should return empty array, not 404

    @{ Name = 'Error - invalid endpoint'; 
       Method = 'GET'; 
       Url = '/apInvoices/nonexistent'; 
       ExpectedStatus = 404 }
)

