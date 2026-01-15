# Script to generate GET functions for Finance API resources
$ErrorActionPreference = "Stop"

$spec = Get-Content "finance-openapi-20251017-144638-v25.4.75.4.json" -Raw | ConvertFrom-Json -AsHashtable

$resources = @(
    @{Name="VendorPayments"; Path="/vendorPayments"; Singular="VendorPayment"}
    @{Name="Checks"; Path="/checks"; Singular="Check"}
    @{Name="CurrencyRates"; Path="/currencyRates"; Singular="CurrencyRate"}
    @{Name="DriverDeductionCodes"; Path="/driverDeductionCodes"; Singular="DriverDeductionCode"}
    @{Name="DriverDeductions"; Path="/driverDeductions"; Singular="DriverDeduction"}
    @{Name="DriverPaymentCodes"; Path="/driverPaymentCodes"; Singular="DriverPaymentCode"}
    @{Name="DriverPayments"; Path="/driverPayments"; Singular="DriverPayment"}
    @{Name="DriverStatements"; Path="/driverStatements"; Singular="DriverStatement"}
    @{Name="EmployeePayments"; Path="/employeePayments"; Singular="EmployeePayment"}
    @{Name="GlAccounts"; Path="/glAccounts"; Singular="GlAccount"}
    @{Name="GlAccountSegments"; Path="/glAccountSegments"; Singular="GlAccountSegment"}
    @{Name="GlAccountTypes"; Path="/glAccountTypes"; Singular="GlAccountType"}
    @{Name="Taxes"; Path="/taxes"; Singular="Tax"}
    @{Name="AccountsReceivables"; Path="/accountsReceivables"; Singular="AccountsReceivable"}
)

Write-Host "Will generate $($resources.Count) functions" -ForegroundColor Yellow
