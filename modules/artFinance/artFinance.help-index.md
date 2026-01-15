# artFinance help index

Generated: 2026-01-06 12:13:03
Module root: C:\git\art-powershell-modules\modules\artFinance
Total functions: 32
Synopses found: 32
Descriptions found: 30

## Functions

### Get-AccountsReceivables

- File: C:\git\art-powershell-modules\modules\artFinance\accountsReceivables\Get-AccountsReceivables.Public.ps1
- Synopsis: Retrieves accounts receivable records

#### Description

GET /accountsReceivables
        Retrieves accounts receivable records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "arId,clientId,amount"
- OrderBy: Optional. OData orderby expression. Example: "invoiceDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-AccountsReceivables
        # Returns all records

        Get-AccountsReceivables -Filter "status eq 'OPEN'" -OrderBy "invoiceDate desc"
        # Returns filtered and sorted records

        Get-AccountsReceivables -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-AccountsReceivables -Select "arId,clientId,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-AccountsReceivables -Limit 'many'

    .OUTPUTS
        Array of accountsReceivable objects, or JSON error string for testability
```

### Get-ApInvoices

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\Get-ApInvoices.Public.ps1
- Synopsis: Retrieves accounts payable invoice records [/apInvoices]

#### Description

GET /apInvoices or /apInvoices/{apInvoiceId}
        Retrieves accounts payable invoice records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.

        AP invoices represent vendor invoices for payment processing.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- ApInvoiceId: Optional. Specific AP invoice ID to retrieve. If omitted, returns collection of AP invoices. Required for: /apInvoices/{apInvoiceId}
- Filter: Optional. OData filter expression. Example: "vendorId eq 'V12345' and status eq 'POSTED'"
- Select: Optional. OData select expression for specific fields. Example: "apInvoiceId,vendorId,invoiceNumber,amount,status"
- OrderBy: Optional. OData orderby expression. Example: "invoiceDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- Expand: Optional. Comma-separated list of sub-resources to include in response. Supported values (per OpenAPI spec): - "expenses" - Include expense line items - "apDriverDeductions" - Include driver deduction details - "ista" - Include ISTA-related data Example: "expenses,apDriverDeductions"
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-ApInvoices
        # Returns all AP invoice records

        Get-ApInvoices -ApInvoiceId 123
        # Returns AP invoice 123

        Get-ApInvoices -Filter "vendorId eq 'V12345'" -OrderBy "invoiceDate desc"
        # Returns AP invoices for vendor V12345, newest first

        Get-ApInvoices -Filter "amount gt 1000 and status eq 'POSTED'" -Limit 10
        # Returns first 10 posted invoices over $1000

        Get-ApInvoices -Select "apInvoiceId,vendorId,invoiceNumber,amount" -Limit 100
        # Returns specific fields for up to 100 invoices

        Get-ApInvoices -ApInvoiceId 123 -Expand "expenses"
        # Returns AP invoice 123 with expanded expense line items

        Get-ApInvoices -Filter "status eq 'PENDING'" -Expand "expenses,apDriverDeductions" -Limit 20
        # Returns first 20 pending invoices with expenses and driver deductions

        # Pagination: Get second page of 50 records
        Get-ApInvoices -Limit 50 -Offset 50 -OrderBy "invoiceDate desc"

        # API Testing: Test invalid types (expect 400 errors)
        Get-ApInvoices -ApInvoiceId 'ABC'
        Get-ApInvoices -Limit 'many'

    .OUTPUTS
        Single AP invoice object or array of AP invoice objects, or JSON error string for testability
```

### Get-CashReceipts

- File: C:\git\art-powershell-modules\modules\artFinance\cashReceipts\Get-CashReceipts.Public.ps1
- Synopsis: Retrieves cash receipt records

#### Description

GET /cashReceipts or /cashReceipts/{cashReceiptId}
        Retrieves cash receipt records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- CashReceiptId: Optional. Specific cash receipt ID to retrieve. If omitted, returns collection of cash receipts.
- Filter: Optional. OData filter expression. Example: "customerId eq '12345' and status eq 'POSTED'"
- Select: Optional. OData select expression for specific fields. Example: "cashReceiptId,amount,receiptDate,paymentMethod"
- OrderBy: Optional. OData orderby expression. Example: "receiptDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- Expand: Optional. OData expand query parameter to include related entities. Example: "invoices" to include invoice details in the response. Note: Not documented in OpenAPI spec but supported by API.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-CashReceipts
        # Returns all cash receipt records

        Get-CashReceipts -CashReceiptId 123
        # Returns cash receipt 123

        Get-CashReceipts -Filter "customerId eq '12345'" -OrderBy "receiptDate desc"
        # Returns cash receipts for customer 12345, newest first

        Get-CashReceipts -Filter "amount gt 1000 and status eq 'POSTED'" -Limit 10
        # Returns first 10 posted receipts over $1000

        Get-CashReceipts -Select "cashReceiptId,amount,receiptDate" -Limit 100
        # Returns specific fields for up to 100 receipts

        Get-CashReceipts -CashReceiptId 123 -Expand "invoices"
        # Returns cash receipt 123 with expanded invoice details

        Get-CashReceipts -Filter "amount gt 1000" -Expand "invoices" -Limit 10
        # Returns first 10 receipts over $1000 with invoice details

        # API Testing: Test invalid types (expect 400 errors)
        Get-CashReceipts -CashReceiptId 'ABC'
        Get-CashReceipts -Limit 'many'

    .OUTPUTS
        Single cash receipt object or array of cash receipt objects, or JSON error string for testability
```

### Get-Checks

- File: C:\git\art-powershell-modules\modules\artFinance\checks\Get-Checks.Public.ps1
- Synopsis: Retrieves check records

#### Description

GET /checks
        Retrieves check records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "checkId,checkNumber,amount"
- OrderBy: Optional. OData orderby expression. Example: "checkDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-Checks
        # Returns all records

        Get-Checks -Filter "status eq 'PRINTED'" -OrderBy "checkDate desc"
        # Returns filtered and sorted records

        Get-Checks -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-Checks -Select "checkId,checkNumber,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-Checks -Limit 'many'

    .OUTPUTS
        Array of check objects, or JSON error string for testability
```

### Get-CurrencyRates

- File: C:\git\art-powershell-modules\modules\artFinance\currencyRates\Get-CurrencyRates.Public.ps1
- Synopsis: Retrieves currency rate records [/currencyRates]

#### Description

GET /currencyRates
        Retrieves currency rate records from the Finance API.

        REQUIRED PARAMETER: Location must be specified (generalLedger or driverPay)

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Location: Required. Currency rate location. Valid values: 'generalLedger' or 'driverPay'
- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "currencyRateId,currencyCode,rate"
- OrderBy: Optional. OData orderby expression. Example: "effectiveDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-CurrencyRates -Location generalLedger
        # Returns all general ledger currency rates

        Get-CurrencyRates -Location driverPay -Filter "currencyCode eq 'USD'" -OrderBy "effectiveDate desc"
        # Returns filtered and sorted driver pay currency rates

        Get-CurrencyRates -Location generalLedger -Limit 100 -Offset 0
        # Returns first page of 100 general ledger currency rates

        Get-CurrencyRates -Location driverPay -Select "currencyRateId,currencyCode,rate" -Limit 50
        # Returns specific fields for up to 50 driver pay currency rates

        # API Testing: Test invalid types (expect 400 errors)
        Get-CurrencyRates -Location 'invalid'
        Get-CurrencyRates -Location generalLedger -Limit 'many'

    .OUTPUTS
        Array of currencyRate objects, or JSON error string for testability
```

### Get-DriverDeductionCodes

- File: C:\git\art-powershell-modules\modules\artFinance\driverDeductionCodes\Get-DriverDeductionCodes.Public.ps1
- Synopsis: Retrieves driver deduction code records

#### Description

GET /driverDeductionCodes
        Retrieves driver deduction code records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "code,description"
- OrderBy: Optional. OData orderby expression. Example: "code"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-DriverDeductionCodes
        # Returns all records

        Get-DriverDeductionCodes -Filter "isActive eq True" -OrderBy "code"
        # Returns filtered and sorted records

        Get-DriverDeductionCodes -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-DriverDeductionCodes -Select "code,description" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverDeductionCodes -Limit 'many'

    .OUTPUTS
        Array of driverDeductionCode objects, or JSON error string for testability
```

### Get-DriverDeductions

- File: C:\git\art-powershell-modules\modules\artFinance\driverDeductions\Get-DriverDeductions.Public.ps1
- Synopsis: Retrieves driver deduction records

#### Description

GET /driverDeductions
        Retrieves driver deduction records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "driverDeductionId,driverId,amount"
- OrderBy: Optional. OData orderby expression. Example: "deductionDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-DriverDeductions
        # Returns all records

        Get-DriverDeductions -Filter "driverId eq 'D12345'" -OrderBy "deductionDate desc"
        # Returns filtered and sorted records

        Get-DriverDeductions -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-DriverDeductions -Select "driverDeductionId,driverId,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverDeductions -Limit 'many'

    .OUTPUTS
        Array of driverDeduction objects, or JSON error string for testability
```

### Get-DriverPaymentCodes

- File: C:\git\art-powershell-modules\modules\artFinance\driverPaymentCodes\Get-DriverPaymentCodes.Public.ps1
- Synopsis: Retrieves driver payment code records

#### Description

GET /driverPaymentCodes
        Retrieves driver payment code records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "code,description"
- OrderBy: Optional. OData orderby expression. Example: "code"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-DriverPaymentCodes
        # Returns all records

        Get-DriverPaymentCodes -Filter "isActive eq True" -OrderBy "code"
        # Returns filtered and sorted records

        Get-DriverPaymentCodes -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-DriverPaymentCodes -Select "code,description" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverPaymentCodes -Limit 'many'

    .OUTPUTS
        Array of driverPaymentCode objects, or JSON error string for testability
```

### Get-DriverPayments

- File: C:\git\art-powershell-modules\modules\artFinance\driverPayments\Get-DriverPayments.Public.ps1
- Synopsis: Retrieves driver payment records

#### Description

GET /driverPayments
        Retrieves driver payment records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "driverPaymentId,driverId,amount"
- OrderBy: Optional. OData orderby expression. Example: "paymentDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-DriverPayments
        # Returns all records

        Get-DriverPayments -Filter "driverId eq 'D12345'" -OrderBy "paymentDate desc"
        # Returns filtered and sorted records

        Get-DriverPayments -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-DriverPayments -Select "driverPaymentId,driverId,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverPayments -Limit 'many'

    .OUTPUTS
        Array of driverPayment objects, or JSON error string for testability
```

### Get-DriverStatements

- File: C:\git\art-powershell-modules\modules\artFinance\driverStatements\Get-DriverStatements.Public.ps1
- Synopsis: Retrieves driver statement records

#### Description

GET /driverStatements
        Retrieves driver statement records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "driverStatementId,driverId,statementDate"
- OrderBy: Optional. OData orderby expression. Example: "statementDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-DriverStatements
        # Returns all records

        Get-DriverStatements -Filter "driverId eq 'D12345'" -OrderBy "statementDate desc"
        # Returns filtered and sorted records

        Get-DriverStatements -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-DriverStatements -Select "driverStatementId,driverId,statementDate" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-DriverStatements -Limit 'many'

    .OUTPUTS
        Array of driverStatement objects, or JSON error string for testability
```

### Get-EmployeePayments

- File: C:\git\art-powershell-modules\modules\artFinance\employeePayments\Get-EmployeePayments.Public.ps1
- Synopsis: Retrieves employee payment records

#### Description

GET /employeePayments
        Retrieves employee payment records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "employeePaymentId,employeeId,amount"
- OrderBy: Optional. OData orderby expression. Example: "paymentDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-EmployeePayments
        # Returns all records

        Get-EmployeePayments -Filter "employeeId eq 'E12345'" -OrderBy "paymentDate desc"
        # Returns filtered and sorted records

        Get-EmployeePayments -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-EmployeePayments -Select "employeePaymentId,employeeId,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-EmployeePayments -Limit 'many'

    .OUTPUTS
        Array of employeePayment objects, or JSON error string for testability
```

### Get-FuelTaxes

- File: C:\git\art-powershell-modules\modules\artFinance\fuelTaxes\Get-FuelTaxes.Public.ps1
- Synopsis: Retrieves fuel tax records

#### Description

GET /fuelTaxes or /fuelTaxes/{fuelTaxId}
        Retrieves fuel tax calculation records from the Finance API.
        Can retrieve all records or a specific one by ID.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- FuelTaxId: Optional. Specific fuel tax ID to retrieve. If omitted, returns all fuel tax records.
- Filter: Optional. OData filter expression. Example: "tripNumber eq '12345'"
- Select: Optional. OData select expression for specific fields. Example: "fuelTaxId,tripNumber,totalTax"
- Expand: Optional. OData expand expression for related entities. Example: "tripSegments,tripFuelPurchases,tripWaypoints"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-FuelTaxes
        # Returns all fuel tax records

        Get-FuelTaxes -FuelTaxId 123
        # Returns fuel tax record 123

        Get-FuelTaxes -Filter "tripNumber eq '12345'"
        # Returns fuel taxes for trip 12345

        Get-FuelTaxes -FuelTaxId 123 -Expand "tripSegments,tripFuelPurchases"
        # Returns fuel tax 123 with expanded child resources

        Get-FuelTaxes -Limit 10 -Offset 20
        # Returns 10 records starting from record 20 (page 3)

    .OUTPUTS
        Single fuel tax object or array of fuel tax objects
```

### Get-GlAccounts

- File: C:\git\art-powershell-modules\modules\artFinance\glAccounts\Get-GlAccounts.Public.ps1
- Synopsis: Retrieves general ledger account records

#### Description

GET /glAccounts
        Retrieves general ledger account records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "glAccountId,accountNumber,description"
- OrderBy: Optional. OData orderby expression. Example: "accountNumber"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-GlAccounts
        # Returns all records

        Get-GlAccounts -Filter "accountType eq 'ASSET'" -OrderBy "accountNumber"
        # Returns filtered and sorted records

        Get-GlAccounts -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-GlAccounts -Select "glAccountId,accountNumber,description" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-GlAccounts -Limit 'many'

    .OUTPUTS
        Array of glAccount objects, or JSON error string for testability
```

### Get-GlAccountSegments

- File: C:\git\art-powershell-modules\modules\artFinance\glAccountSegments\Get-GlAccountSegments.Public.ps1
- Synopsis: Retrieves GL account segment records

#### Description

GET /glAccountSegments
        Retrieves GL account segment records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "segmentId,segmentName"
- OrderBy: Optional. OData orderby expression. Example: "segmentName"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-GlAccountSegments
        # Returns all records

        Get-GlAccountSegments -Filter "isActive eq True" -OrderBy "segmentName"
        # Returns filtered and sorted records

        Get-GlAccountSegments -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-GlAccountSegments -Select "segmentId,segmentName" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-GlAccountSegments -Limit 'many'

    .OUTPUTS
        Array of glAccountSegment objects, or JSON error string for testability
```

### Get-GlAccountTypes

- File: C:\git\art-powershell-modules\modules\artFinance\glAccountTypes\Get-GlAccountTypes.Public.ps1
- Synopsis: Retrieves GL account type records

#### Description

GET /glAccountTypes
        Retrieves GL account type records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "typeId,typeName"
- OrderBy: Optional. OData orderby expression. Example: "typeName"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-GlAccountTypes
        # Returns all records

        Get-GlAccountTypes -Filter "isActive eq True" -OrderBy "typeName"
        # Returns filtered and sorted records

        Get-GlAccountTypes -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-GlAccountTypes -Select "typeId,typeName" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-GlAccountTypes -Limit 'many'

    .OUTPUTS
        Array of glAccountType objects, or JSON error string for testability
```

### Get-InterlinerPayables

- File: C:\git\art-powershell-modules\modules\artFinance\interlinerPayables\Get-InterlinerPayables.Public.ps1
- Synopsis: Retrieves interliner payable records

#### Description

GET /interlinerPayables or /interlinerPayables/{interlinerPayableId}
        Retrieves interliner payable records from the Finance API.
        Can retrieve all records, filtered collection, or a specific one by ID.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- InterlinerPayableId: Optional. Specific interliner payable ID to retrieve. If omitted, returns collection of interliner payables.
- Filter: Optional. OData filter expression. Example: "carrierId eq '12345' and status eq 'OPEN'"
- Select: Optional. OData select expression for specific fields. Example: "interlinerPayableId,amount,invoiceNumber,carrierId"
- OrderBy: Optional. OData orderby expression. Example: "invoiceDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-InterlinerPayables
        # Returns all interliner payable records

        Get-InterlinerPayables -InterlinerPayableId 123
        # Returns interliner payable 123

        Get-InterlinerPayables -Filter "carrierId eq '12345'" -OrderBy "invoiceDate desc"
        # Returns interliner payables for carrier 12345, newest first

        Get-InterlinerPayables -Filter "amount gt 1000 and status eq 'OPEN'" -Limit 10
        # Returns first 10 open payables over $1000

        Get-InterlinerPayables -Select "interlinerPayableId,amount,invoiceNumber" -Limit 100
        # Returns specific fields for up to 100 payables

        # API Testing: Test invalid types (expect 400 errors)
        Get-InterlinerPayables -InterlinerPayableId 'ABC'
        Get-InterlinerPayables -Limit 'many'

    .OUTPUTS
        Single interliner payable object or array of interliner payable objects, or JSON error string for testability
```

### Get-Taxes

- File: C:\git\art-powershell-modules\modules\artFinance\taxes\Get-Taxes.Public.ps1
- Synopsis: Retrieves tax code records

#### Description

GET /taxes
        Retrieves tax code records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "taxId,taxCode,taxRate"
- OrderBy: Optional. OData orderby expression. Example: "taxCode"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-Taxes
        # Returns all records

        Get-Taxes -Filter "isActive eq True" -OrderBy "taxCode"
        # Returns filtered and sorted records

        Get-Taxes -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-Taxes -Select "taxId,taxCode,taxRate" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-Taxes -Limit 'many'

    .OUTPUTS
        Array of tax objects, or JSON error string for testability
```

### Get-TripFuelPurchases

- File: C:\git\art-powershell-modules\modules\artFinance\fuelTaxes\tripFuelPurchases\Get-TripFuelPurchases.Public.ps1
- Synopsis: Retrieves trip fuel purchase records for a fuel tax

#### Description

GET /fuelTaxes/{fuelTaxId}/tripFuelPurchases
        GET /fuelTaxes/{fuelTaxId}/tripFuelPurchases/{tripFuelPurchaseId}
        Retrieves fuel purchase records associated with a fuel tax calculation.
        Can retrieve all purchases for a fuel tax or a specific one by ID.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- FuelTaxId: The fuel tax ID to retrieve purchases for (required)
- TripFuelPurchaseId: Optional. Specific trip fuel purchase ID to retrieve. If omitted, returns all purchases for the fuel tax.
- Filter: Optional. OData filter expression. Example: "purchaseLocation eq 'CA'"
- Select: Optional. OData select expression for specific fields. Example: "tripFuelPurchaseId,purchaseDate,fuelVolume1"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-TripFuelPurchases -FuelTaxId 123
        # Returns all purchases for fuel tax 123

        Get-TripFuelPurchases -FuelTaxId 123 -TripFuelPurchaseId 456
        # Returns purchase 456 for fuel tax 123

        Get-TripFuelPurchases -FuelTaxId 123 -Filter "purchaseLocation eq 'CA'"
        # Returns California purchases for fuel tax 123

        Get-FuelTaxes -FuelTaxId 123 | Get-TripFuelPurchases
        # Pipeline: Gets fuel tax 123, then its purchases

    .OUTPUTS
        Single purchase object or array of purchase objects
```

### Get-UserFieldsData

- File: C:\git\art-powershell-modules\modules\artFinance\userFieldsData\Get-UserFieldsData.Public.ps1
- Synopsis: Retrieves user-defined fields data [/userFieldsData]

#### Description

GET /userFieldsData
        Retrieves user-defined custom fields data from Finance API.
        Requires query parameters to specify which source and field to retrieve.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- SourceType: Required by API. Type of source record. Valid values: 'driverStatements', 'apInvoices'
- SourceId: ID of the source record Optional query parameter (may be required depending on API version)
- UserField: User field number to retrieve Optional query parameter
- Filter: Optional. OData filter expression.
- Select: Optional. OData select expression for specific fields. Example: "userFieldValue,sourceId"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-UserFieldsData -SourceType driverStatements -SourceId 123
        # Returns user field data for driver statement 123

        Get-UserFieldsData -SourceType apInvoices -Select "userFieldValue,sourceId"
        # Returns specific fields for all AP invoice user fields

        Get-UserFieldsData -SourceType driverStatements -Filter "userFieldValue ne null"
        # Returns all driver statement user fields that have values

    .NOTES
        Query parameters are critical for this endpoint.
        The combination of SourceType, SourceId, and UserField determines what data is retrieved.

    .OUTPUTS
        Array of user fields data objects or single object
```

### Get-VendorPayments

- File: C:\git\art-powershell-modules\modules\artFinance\vendorPayments\Get-VendorPayments.Public.ps1
- Synopsis: Retrieves vendor payment records

#### Description

GET /vendorPayments
        Retrieves vendor payment records from the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Filter: Optional. OData filter expression. Example: "status eq 'ACTIVE'"
- Select: Optional. OData select expression for specific fields. Example: "vendorPaymentId,vendorId,amount"
- OrderBy: Optional. OData orderby expression. Example: "paymentDate desc"
- Limit: Optional. Maximum number of records to return (pagination).
- Offset: Optional. Number of records to skip (pagination).
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Get-VendorPayments
        # Returns all records

        Get-VendorPayments -Filter "vendorId eq 'V12345'" -OrderBy "paymentDate desc"
        # Returns filtered and sorted records

        Get-VendorPayments -Limit 100 -Offset 0
        # Returns first page of 100 records

        Get-VendorPayments -Select "vendorPaymentId,vendorId,amount" -Limit 50
        # Returns specific fields for up to 50 records

        # API Testing: Test invalid types (expect 400 errors)
        Get-VendorPayments -Limit 'many'

    .OUTPUTS
        Array of vendorPayment objects, or JSON error string for testability
```

### New-ApInvoice

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\New-ApInvoice.Public.ps1
- Synopsis: Creates new accounts payable invoice(s) in TruckMate [POST /apInvoices]

#### Description

POST /apInvoices
        Creates one or more accounts payable invoice records.

        AP invoices represent vendor invoices for payment processing and can be
        viewed in the finance applications.

        Request body is an array of AP invoice objects (not wrapped in a property).

        REQUIRED FIELDS (per OpenAPI spec):
        - vendorId (string, max 10 chars)
        - vendorBillNumber (string, max 20 chars)
        - vendorBillDate (string, date format)
        - currencyCode (string, max 3 chars)

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Body: Required. Array of hashtables or PSCustomObjects containing the AP invoice data. Each invoice must include required fields: vendorId, vendorBillNumber, vendorBillDate, currencyCode. Example structure: @( @{ vendorId = "V12345" vendorBillNumber = "INV-2025-001" vendorBillDate = "2025-10-20" currencyCode = "USD" vendorBillAmount = 1500.00 payableType = "bill" # ... other optional properties } ) Optional properties include: - vendorBillAmount (number) - vendorBillReference (string, max 40) - poNumber (string, max 25) - equipmentId, powerUnitId, trailerId (string, max 10) - payableType (string) - payableHold (string) - payableTerms (string, max 10) - payableAgingDate, payableDueDate, payableDiscountDate (string, date format) - payableDiscount (number) - glAccount (string, max 50) - autoForeignExchange (string) - isIntercompany (string) - expenses (array) - for creating expense line items - apDriverDeductions (array) - for creating driver deductions - ista (array) - for sales tax information
- Select: Optional. OData $select expression for specific fields to return. Example: "apInvoiceId,vendorId,vendorBillNumber,vendorBillAmount"
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
$invoice = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-2025-001"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1500.00
                payableType = "bill"
            }
        )
        New-ApInvoice -Body $invoice
        # Creates a new AP invoice

        # Create multiple invoices at once
        $invoices = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-001"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1500.00
            },
            @{
                vendorId = "V67890"
                vendorBillNumber = "INV-002"
                vendorBillDate = "2025-10-20"
                currencyCode = "CAD"
                vendorBillAmount = 2000.00
            }
        )
        New-ApInvoice -Body $invoices

        # Create with specific fields returned
        New-ApInvoice -Body $invoice -Select "apInvoiceId,vendorId,vendorBillAmount"

        # Create invoice with expense line items
        $invoiceWithExpenses = @(
            @{
                vendorId = "V12345"
                vendorBillNumber = "INV-003"
                vendorBillDate = "2025-10-20"
                currencyCode = "USD"
                vendorBillAmount = 1000.00
                expenses = @(
                    @{
                        expenseGlAccount = "00-5000"
                        expenseAmount = 500.00
                    },
                    @{
                        expenseGlAccount = "00-5100"
                        expenseAmount = 500.00
                    }
                )
            }
        )
        New-ApInvoice -Body $invoiceWithExpenses

        # API Testing: Test validation errors
        New-ApInvoice -Body @()  # Empty array
        New-ApInvoice -Body @(@{vendorId = "TEST"})  # Missing required fields

    .OUTPUTS
        On success: Created AP invoice object(s) (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)

    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
```

### New-ApInvoiceDriverDeduction

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\apDriverDeductions\New-ApInvoiceDriverDeduction.Public.ps1
- Synopsis: Creates new driver deduction(s) for an AP Invoice [POST /apInvoices/{apInvoiceId}/apDriverDeductions]

#### Parameters

- ApInvoiceId: Required. The AP Invoice ID to add driver deductions to. Used in path: /apInvoices/{apInvoiceId}/apDriverDeductions
- Body: Required. Array of driver deduction data.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object

#### Examples

```powershell
New-ApInvoiceDriverDeduction -ApInvoiceId 12345 -Body @(@{ driverId = "DRV001"; amount = 25.00 })
```

### New-ApInvoiceExpense

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\expenses\New-ApInvoiceExpense.Public.ps1
- Synopsis: Creates new expense line item(s) for an AP Invoice [POST /apInvoices/{apInvoiceId}/expenses]

#### Description

POST /finance/apInvoices/{apInvoiceId}/expenses
        Creates one or more expense line items for an existing AP Invoice.

        Expense line items represent individual expense details on an AP Invoice.

#### Parameters

- ApInvoiceId: Required. The AP Invoice ID to add expenses to.
- Body: Required. Array of hashtables or PSCustomObjects containing the expense data. Example structure: @( @{ glAccount = "1000-00-0000" expenseAmount = 100.50 # ... other properties } )
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
$expenses = @(
            @{
                glAccount = "1000-00-0000"
                expenseAmount = 100.50
            }
        )
        New-ApInvoiceExpense -ApInvoiceId 12345 -Body $expenses

    .OUTPUTS
        On success: Created expense object(s)
        On error: JSON string containing error details
```

### New-ApInvoiceIsta

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\ista\New-ApInvoiceIsta.Public.ps1
- Synopsis: Creates new sales tax record(s) for an AP Invoice [POST /apInvoices/{apInvoiceId}/ista]

#### Parameters

- ApInvoiceId: Required. The AP Invoice ID to add sales tax to. Used in path: /apInvoices/{apInvoiceId}/ista
- Body: Required. Array of sales tax data.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object

#### Examples

```powershell
New-ApInvoiceIsta -ApInvoiceId 12345 -Body @(@{ taxAmount = 50.00 })
```

### New-CashReceipt

- File: C:\git\art-powershell-modules\modules\artFinance\cashReceipts\New-CashReceipt.Public.ps1
- Synopsis: Creates new cash receipt(s) in TruckMate

#### Description

POST /cashReceipts
        Creates one or more cash receipt records.

        Cash receipts can be viewed in the AR Cash Receipts application.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- Body: Required. Hashtable or PSCustomObject containing the cash receipt data. Must include a 'cashReceipts' array with at least one cash receipt object. Example structure: @{ cashReceipts = @( @{ transactionType = "CASH" transactionDate = "2025-10-16" transactionAmount = 1000.00 clientId = "12345" # ... other properties } ) }
- Select: Optional. OData $select expression for specific fields to return. Example: "cashReceiptId,transactionType,transactionAmount"
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
$receiptBody = @{
            cashReceipts = @(
                @{
                    transactionType = "CASH"
                    transactionDate = "2025-10-16"
                    transactionAmount = 1000.00
                    clientId = "12345"
                }
            )
        }
        New-CashReceipt -Body $receiptBody

        # Create with specific fields returned
        New-CashReceipt -Body $receiptBody -Select "cashReceiptId,transactionAmount"

    .OUTPUTS
        PSCustomObject - The created cash receipt(s)
        OR
        String - JSON error message if API returns an error

    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
```

### New-CashReceiptInvoice

- File: C:\git\art-powershell-modules\modules\artFinance\cashReceipts\invoices\New-CashReceiptInvoice.Public.ps1
- Synopsis: Adds invoice(s) to an existing cash receipt

#### Description

POST /cashReceipts/{cashReceiptId}/invoices
        Creates invoice payment records associated with a cash receipt in the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- CashReceiptId: The ID of the cash receipt to add invoices to (required)
- Invoices: Array of invoice payment objects. Each invoice requires: - orderId (integer, required) - clientId (string, optional, max 10 chars) - paymentAmount (number, optional) - writeOffAmount (number, optional)
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
# Add single invoice to cash receipt
        $invoice = @{
            orderId = 12345
            clientId = "CLIENT001"
            paymentAmount = 500.00
        }
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices @($invoice)

        # Add multiple invoices
        $invoices = @(
            @{ orderId = 12345; paymentAmount = 500.00 }
            @{ orderId = 12346; paymentAmount = 250.00; writeOffAmount = 25.00 }
        )
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices $invoices

        # API Testing: Test invalid data types
        New-CashReceiptInvoice -CashReceiptId 'ABC' -Invoices @(@{ orderId = 123 })
        New-CashReceiptInvoice -CashReceiptId 100 -Invoices @(@{ orderId = 'XYZ' })

    .NOTES
        TM-180953: Finance - Add POST /cashReceipts/{cashReceiptId}/invoices

        Invoice properties (from OpenAPI spec):
        - orderId (integer, required) - Order ID for the invoice
        - clientId (string, optional, max 10) - Client identifier
        - paymentAmount (number, optional) - Amount paid on invoice
        - writeOffAmount (number, optional) - Amount written off

        Response properties:
        - cashReceiptId, invoiceId, detailLineId
        - billNumber, clientId
        - paymentAmount, writeOffAmount (nullable)

    .OUTPUTS
        Array of created invoice payment records, or JSON error string for testability
```

### New-TripFuelPurchases

- File: C:\git\art-powershell-modules\modules\artFinance\fuelTaxes\tripFuelPurchases\New-TripFuelPurchases.Public.ps1
- Synopsis: Creates one or more trip fuel purchase records

#### Description

POST /fuelTaxes/{fuelTaxId}/tripFuelPurchases
        Creates trip fuel purchase records associated with a fuel tax calculation.
        Accepts an array of fuel purchase objects.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- FuelTaxId: The fuel tax ID to associate purchases with (required)
- Purchases: Array of trip fuel purchase objects (hashtables) with properties: - purchaseDate, purchaseLocation, fuelVolume1, fuelRate1, etc. See NOTES for full property list.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- Default: Creates a minimal default purchase for testing (single purchase with minimal fields)
- PassThru: Returns the API response object instead of just the purchases array

#### Examples

```powershell
New-TripFuelPurchases -FuelTaxId 123 -Default
        # Creates a minimal test purchase

        $purchase = @{
            purchaseDate = '2024-01-15'
            purchaseLocation = 'CA'
            fuelVolume1 = 100.5
            fuelRate1 = 3.50
            fuelType1 = 'DIESEL'
        }
        New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchase
        # Creates a single purchase

        $purchases = @(
            @{ purchaseDate = '2024-01-15'; fuelVolume1 = 100; fuelRate1 = 3.50 },
            @{ purchaseDate = '2024-01-16'; fuelVolume1 = 95; fuelRate1 = 3.55 }
        )
        New-TripFuelPurchases -FuelTaxId 123 -Purchases $purchases
        # Creates multiple purchases

    .NOTES
        Available properties (all optional):
        - cost, currencyCode, driverId1, driverId2
        - fuelCardNumber, fuelCardVendor, fuelCost1, fuelCost2
        - fuelInvoiceNumber, fuelRate1, fuelRate2
        - fuelStationCity, fuelStationId, fuelStationName
        - fuelStationPostalCode, fuelStationVendor
        - fuelType1, fuelType2, fuelVolume1, fuelVolume2
        - odometer, purchaseDate, purchaseJurisdiction
        - purchaseLocation, purchaseType, receipt
        - reeferFuelCost, reeferFuelRate, reeferFuelVolume
        - taxable, taxPaid, unit, user1, user2, user3, volume

    .OUTPUTS
        Array of created trip fuel purchase objects with IDs assigned
```

### Set-ApInvoice

- File: C:\git\art-powershell-modules\modules\artFinance\apInvoices\Set-ApInvoice.Public.ps1
- Synopsis: Updates an accounts payable invoice record [PUT /apInvoices/{apInvoiceId}]

#### Description

PUT /apInvoices/{apInvoiceId}
        Updates an existing accounts payable invoice record in the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- ApInvoiceId: Required. The ID of the AP invoice to update. Used in path: /apInvoices/{apInvoiceId}
- ApInvoice: Required. Hashtable or PSCustomObject with AP invoice properties to update. REQUIRED FIELDS (per OpenAPI spec): - vendorId (string, max 10) - vendorBillNumber (string, max 20) - vendorBillDate (string, date format) - currencyCode (string, max 3) OPTIONAL FIELDS: - vendorBillAmount (number) - vendorBillReference (string, max 40) - poNumber (string, max 25) - equipmentId, powerUnitId, trailerId (string, max 10) - payableType (string) - payableHold (string) - payableTerms (string, max 10) - payableAgingDate, payableDueDate, payableDiscountDate (string, date format) - payableDiscount (number) - glAccount (string, max 50) - autoForeignExchange (string) - isIntercompany (string)
- Select: Optional. OData $select expression for specific fields to return. Example: "apInvoiceId,vendorId,vendorBillAmount"
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the full API response object instead of unwrapped data

#### Examples

```powershell
Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            vendorBillAmount = 1500.00
        }
        # Updates the invoice with new values

        # Update just the amount and reference
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            vendorBillAmount = 2000.00
            vendorBillReference = "Updated reference"
        }

        # Update with select to return specific fields
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            payableHold = "True"
        } -Select "apInvoiceId,payableHold"

        # Update payment terms
        $updates = @{
            vendorId = "V12345"
            vendorBillNumber = "INV-001"
            vendorBillDate = "2025-10-20"
            currencyCode = "USD"
            payableTerms = "NET30"
            payableDueDate = "2025-11-20"
        }
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice $updates

        # API Testing: Test invalid types (expect 400 errors)
        Set-ApInvoice -ApInvoiceId 'ABC' -ApInvoice @{vendorId = "V12345"; vendorBillNumber = "INV-001"; vendorBillDate = "2025-10-20"; currencyCode = "USD"}
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice @{vendorId = "V12345"; vendorBillNumber = "INV-001"; vendorBillDate = "invalid"; currencyCode = "USD"}

    .NOTES
        All four required fields must be provided in every PUT request, even if only updating one field.
        This is a full update (PUT), not a partial update (PATCH).

        To get the current values before updating:
        $current = Get-ApInvoices -ApInvoiceId 123
        $current.vendorBillAmount = 2000.00
        Set-ApInvoice -ApInvoiceId 123 -ApInvoice $current

        For AI Assistants:
        - This function is based on adherence to the OpenAPI spec.
        - The spec may change, and should be consulted for usage notes, e.g. creating contract tests for endpoint
        - Fresh version can always be obtained via GET $baseUrl/openapi.json

    .OUTPUTS
        On success: Updated AP invoice object (or full response if -PassThru)
        On error: JSON string containing error details (parse with ConvertFrom-Json for testing)

    .LINK
        https://developer.trimble.com/docs/transportation/truckmate/api-documentation/finance-rest-api
```

### Set-CashReceipt

- File: C:\git\art-powershell-modules\modules\artFinance\cashReceipts\Set-CashReceipt.Public.ps1
- Synopsis: Updates a cash receipt record

#### Description

PUT /cashReceipts/{cashReceiptId}
        Updates an existing cash receipt record in the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- CashReceiptId: The ID of the cash receipt to update (required)
- CashReceipt: Hashtable with cash receipt properties to update. See NOTES for common properties.
- Expand: Optional. OData expand query parameter to include related entities. Example: "invoices" to include invoice details in the response. Note: Not documented in OpenAPI spec but supported by API.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the API response object

#### Examples

```powershell
Set-CashReceipt -CashReceiptId 123 -CashReceipt @{
            amount = 1500.00
            paymentMethod = 'CHECK'
        }
        # Updates amount and payment method

        $receipt = @{
            receiptDate = '2024-01-15'
            amount = 2500.00
            paymentMethod = 'ACH'
            referenceNumber = 'CHK12345'
            notes = 'Payment received'
        }
        Set-CashReceipt -CashReceiptId 123 -CashReceipt $receipt
        # Updates multiple fields

        Set-CashReceipt -CashReceiptId 123 -CashReceipt @{ amount = 1500 } -Expand "invoices"
        # Updates and returns cash receipt with expanded invoice details

        # API Testing: Test invalid types (expect 400 errors)
        Set-CashReceipt -CashReceiptId 'ABC' -CashReceipt @{ amount = 100 }
        Set-CashReceipt -CashReceiptId 123 -CashReceipt @{ amount = 'heavy' }

    .NOTES
        Common properties (vary by API version):
        - amount, receiptDate, paymentMethod, referenceNumber
        - customerId, customerName, bankAccount
        - currencyCode, exchangeRate
        - appliedTo (array of applications to invoices/orders)
        - notes, status, postedDate

        Consult your API documentation for the complete list of available fields.

    .OUTPUTS
        Updated cash receipt object
```

### Set-InterlinerPayable

- File: C:\git\art-powershell-modules\modules\artFinance\interlinerPayables\Set-InterlinerPayable.Public.ps1
- Synopsis: Updates an interliner payable record

#### Description

PUT /interlinerPayables/{interlinerPayableId}
        Updates an existing interliner payable record in the Finance API.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- InterlinerPayableId: The ID of the interliner payable to update (required)
- InterlinerPayable: Hashtable with interliner payable properties to update. See NOTES for common properties.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the API response object

#### Examples

```powershell
Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable @{
            amount = 1500.00
            status = 'APPROVED'
        }
        # Updates amount and status

        $payable = @{
            invoiceDate = '2024-01-15'
            amount = 2500.00
            invoiceNumber = 'INV-12345'
            carrierId = 'CARR001'
            status = 'PENDING'
            notes = 'Payment approved'
        }
        Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable $payable
        # Updates multiple fields

        # API Testing: Test invalid types (expect 400 errors)
        Set-InterlinerPayable -InterlinerPayableId 'ABC' -InterlinerPayable @{ amount = 100 }
        Set-InterlinerPayable -InterlinerPayableId 123 -InterlinerPayable @{ amount = 'heavy' }

    .NOTES
        Common properties (vary by API version):
        - amount, invoiceDate, invoiceNumber, carrierId
        - status, paymentDate, paymentMethod, referenceNumber
        - currencyCode, exchangeRate
        - orderIds (array of related order IDs)
        - notes, approvalDate, approvedBy

        Consult your API documentation for the complete list of available fields.

    .OUTPUTS
        Updated interliner payable object, or JSON error string for testability
```

### Set-TripFuelPurchase

- File: C:\git\art-powershell-modules\modules\artFinance\fuelTaxes\tripFuelPurchases\Set-TripFuelPurchase.Public.ps1
- Synopsis: Updates a trip fuel purchase record

#### Description

PUT /fuelTaxes/{fuelTaxId}/tripFuelPurchases/{tripFuelPurchaseId}
        Updates an existing trip fuel purchase record.
        Operates on a single purchase (not an array).

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- FuelTaxId: The fuel tax ID the purchase is associated with (required)
- TripFuelPurchaseId: The ID of the trip fuel purchase to update (required)
- Purchase: Hashtable with purchase properties to update. See NOTES for available properties.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the API response object

#### Examples

```powershell
Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase @{
            fuelVolume1 = 105.5
            fuelRate1 = 3.60
        }
        # Updates volume and rate for purchase 456

        $updated = @{
            purchaseLocation = 'CA'
            taxable = 'Y'
            taxPaid = 'Y'
        }
        Set-TripFuelPurchase -FuelTaxId 123 -TripFuelPurchaseId 456 -Purchase $updated
        # Updates tax fields

    .NOTES
        Available properties (all optional):
        - cost, currencyCode, driverId1, driverId2
        - fuelCardNumber, fuelCardVendor, fuelCost1, fuelCost2
        - fuelInvoiceNumber, fuelRate1, fuelRate2
        - fuelStationCity, fuelStationId, fuelStationName
        - fuelStationPostalCode, fuelStationVendor
        - fuelType1, fuelType2, fuelVolume1, fuelVolume2
        - odometer, purchaseDate, purchaseJurisdiction
        - purchaseLocation, purchaseType, receipt
        - reeferFuelCost, reeferFuelRate, reeferFuelVolume
        - taxable, taxPaid, unit, user1, user2, user3, volume

    .OUTPUTS
        Updated trip fuel purchase object
```

### Set-UserFieldsData

- File: C:\git\art-powershell-modules\modules\artFinance\userFieldsData\Set-UserFieldsData.Public.ps1
- Synopsis: Updates user-defined fields data

#### Description

PUT /userFieldsData
        Updates user-defined custom field data in Finance API.
        Requires query parameters to specify which source and field to update.

        FLEXIBLE TYPE DESIGN:
        - Parameters have minimal type constraints for API testing flexibility
        - Allows testing with intentionally invalid data types
        - API validates and returns proper error codes

#### Parameters

- SourceType: Type of source record (e.g., 'driverStatements', 'bills', 'trips') Required query parameter.
- SourceId: ID of the source record Optional query parameter (may be required depending on API version)
- UserField: User field number to update Required query parameter
- UserData: The value to set for the user field. Can be string, number, or object depending on field type.
- Select: Optional. OData select expression for response fields.
- BaseUrl: API base URL. Defaults to $env:FINANCE_API_URL or localhost
- Token: Bearer token. Defaults to $env:TRUCKMATE_API_KEY
- PassThru: Returns the API response object

#### Examples

```powershell
Set-UserFieldsData -SourceType 'driverStatements' -SourceId 123 -UserField 1 -UserData 'CustomValue'
        # Sets user field 1 to 'CustomValue' for driver statement 123

        Set-UserFieldsData -SourceType 'bills' -UserField 2 -UserData @{ field = 'value' }
        # Sets user field 2 with object data

        # Update multiple records in a pipeline
        Get-UserFieldsData -SourceType 'trips' | ForEach-Object {
            Set-UserFieldsData -SourceType 'trips' -SourceId $_.sourceId -UserField 1 -UserData 'Updated'
        }

    .NOTES
        Query parameters are critical for this endpoint.
        The combination of SourceType, SourceId, and UserField determines which field is updated.

        Body format: { "userData": "value" }

    .OUTPUTS
        Updated user fields data object
```


