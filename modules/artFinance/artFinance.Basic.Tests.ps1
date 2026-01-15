<#
.SYNOPSIS
    Comprehensive basic tests for all artFinance module functions
    
.DESCRIPTION
    This test file validates that all artFinance module functions:
    - Are properly exported from the module
    - Have valid help content (Synopsis)
    - Can be called with expected parameters
    
    Each function has one Context block with basic validation tests.
#>

BeforeAll {
    # Ensure the module is loaded
    Import-Module 'C:\git\art-powershell-modules\modules\artFinance\artFinance.psm1' -Force
    
    # Setup environment variables for testing
    $env:FINANCE_API_URL = "http://localhost:8199/finance"
    $env:TRUCKMATE_API_KEY = "8e8c563a68a03bda2c1fce86ffef1261"
}

Describe "artFinance Module - All Functions Basic Tests" {
    
    Context "Get-AccountsReceivables" {
        It "Should be exported from module" {
            Get-Command Get-AccountsReceivables -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-AccountsReceivables
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-ApInvoices" {
        It "Should be exported from module" {
            Get-Command Get-ApInvoices -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-ApInvoices
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-CashReceipts" {
        It "Should be exported from module" {
            Get-Command Get-CashReceipts -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-CashReceipts
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-Checks" {
        It "Should be exported from module" {
            Get-Command Get-Checks -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-Checks
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-CurrencyRates" {
        It "Should be exported from module" {
            Get-Command Get-CurrencyRates -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-CurrencyRates
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-DriverDeductionCodes" {
        It "Should be exported from module" {
            Get-Command Get-DriverDeductionCodes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-DriverDeductionCodes
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-DriverDeductions" {
        It "Should be exported from module" {
            Get-Command Get-DriverDeductions -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-DriverDeductions
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-DriverPaymentCodes" {
        It "Should be exported from module" {
            Get-Command Get-DriverPaymentCodes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-DriverPaymentCodes
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-DriverPayments" {
        It "Should be exported from module" {
            Get-Command Get-DriverPayments -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-DriverPayments
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-DriverStatements" {
        It "Should be exported from module" {
            Get-Command Get-DriverStatements -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-DriverStatements
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-EmployeePayments" {
        It "Should be exported from module" {
            Get-Command Get-EmployeePayments -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-EmployeePayments
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-FuelTaxes" {
        It "Should be exported from module" {
            Get-Command Get-FuelTaxes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-FuelTaxes
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-GlAccounts" {
        It "Should be exported from module" {
            Get-Command Get-GlAccounts -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-GlAccounts
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-GlAccountSegments" {
        It "Should be exported from module" {
            Get-Command Get-GlAccountSegments -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-GlAccountSegments
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-GlAccountTypes" {
        It "Should be exported from module" {
            Get-Command Get-GlAccountTypes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-GlAccountTypes
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-InterlinerPayables" {
        It "Should be exported from module" {
            Get-Command Get-InterlinerPayables -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-InterlinerPayables
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-Taxes" {
        It "Should be exported from module" {
            Get-Command Get-Taxes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-Taxes
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-TripFuelPurchases" {
        It "Should be exported from module" {
            Get-Command Get-TripFuelPurchases -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-TripFuelPurchases
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-UserFieldsData" {
        It "Should be exported from module" {
            Get-Command Get-UserFieldsData -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-UserFieldsData
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-VendorPayments" {
        It "Should be exported from module" {
            Get-Command Get-VendorPayments -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Get-VendorPayments
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "New-ApInvoice" {
        It "Should be exported from module" {
            Get-Command New-ApInvoice -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-ApInvoice
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have Body parameter" {
            (Get-Command New-ApInvoice).Parameters.Keys | Should -Contain 'Body'
        }
    }
    
    Context "New-ApInvoiceDriverDeduction" {
        It "Should be exported from module" {
            Get-Command New-ApInvoiceDriverDeduction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-ApInvoiceDriverDeduction
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have ApInvoiceId and Body parameters" {
            $cmd = Get-Command New-ApInvoiceDriverDeduction
            $cmd.Parameters.Keys | Should -Contain 'ApInvoiceId'
            $cmd.Parameters.Keys | Should -Contain 'Body'
        }
    }
    
    Context "New-ApInvoiceExpense" {
        It "Should be exported from module" {
            Get-Command New-ApInvoiceExpense -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-ApInvoiceExpense
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have ApInvoiceId and Body parameters" {
            $cmd = Get-Command New-ApInvoiceExpense
            $cmd.Parameters.Keys | Should -Contain 'ApInvoiceId'
            $cmd.Parameters.Keys | Should -Contain 'Body'
        }
    }
    
    Context "New-ApInvoiceIsta" {
        It "Should be exported from module" {
            Get-Command New-ApInvoiceIsta -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-ApInvoiceIsta
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have ApInvoiceId and Body parameters" {
            $cmd = Get-Command New-ApInvoiceIsta
            $cmd.Parameters.Keys | Should -Contain 'ApInvoiceId'
            $cmd.Parameters.Keys | Should -Contain 'Body'
        }
    }
    
    Context "New-CashReceipt" {
        It "Should be exported from module" {
            Get-Command New-CashReceipt -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-CashReceipt
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have Body parameter" {
            (Get-Command New-CashReceipt).Parameters.Keys | Should -Contain 'Body'
        }
    }
    
    Context "New-CashReceiptInvoice" {
        It "Should be exported from module" {
            Get-Command New-CashReceiptInvoice -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-CashReceiptInvoice
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have CashReceiptId and Invoices parameters" {
            $cmd = Get-Command New-CashReceiptInvoice
            $cmd.Parameters.Keys | Should -Contain 'CashReceiptId'
            $cmd.Parameters.Keys | Should -Contain 'Invoices'
        }
    }
    
    Context "New-TripFuelPurchases" {
        It "Should be exported from module" {
            Get-Command New-TripFuelPurchases -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help New-TripFuelPurchases
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have FuelTaxId and Purchases parameters" {
            $cmd = Get-Command New-TripFuelPurchases
            $cmd.Parameters.Keys | Should -Contain 'FuelTaxId'
            $cmd.Parameters.Keys | Should -Contain 'Purchases'
        }
    }
    
    Context "Set-ApInvoice" {
        It "Should be exported from module" {
            Get-Command Set-ApInvoice -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Set-ApInvoice
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have ApInvoiceId and ApInvoice parameters" {
            $cmd = Get-Command Set-ApInvoice
            $cmd.Parameters.Keys | Should -Contain 'ApInvoiceId'
            $cmd.Parameters.Keys | Should -Contain 'ApInvoice'
        }
    }
    
    Context "Set-CashReceipt" {
        It "Should be exported from module" {
            Get-Command Set-CashReceipt -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Set-CashReceipt
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have CashReceiptId and CashReceipt parameters" {
            $cmd = Get-Command Set-CashReceipt
            $cmd.Parameters.Keys | Should -Contain 'CashReceiptId'
            $cmd.Parameters.Keys | Should -Contain 'CashReceipt'
        }
    }
    
    Context "Set-InterlinerPayable" {
        It "Should be exported from module" {
            Get-Command Set-InterlinerPayable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Set-InterlinerPayable
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have InterlinerPayableId and InterlinerPayable parameters" {
            $cmd = Get-Command Set-InterlinerPayable
            $cmd.Parameters.Keys | Should -Contain 'InterlinerPayableId'
            $cmd.Parameters.Keys | Should -Contain 'InterlinerPayable'
        }
    }
    
    Context "Set-TripFuelPurchase" {
        It "Should be exported from module" {
            Get-Command Set-TripFuelPurchase -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Set-TripFuelPurchase
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have FuelTaxId, TripFuelPurchaseId, and Purchase parameters" {
            $cmd = Get-Command Set-TripFuelPurchase
            $cmd.Parameters.Keys | Should -Contain 'FuelTaxId'
            $cmd.Parameters.Keys | Should -Contain 'TripFuelPurchaseId'
            $cmd.Parameters.Keys | Should -Contain 'Purchase'
        }
    }
    
    Context "Set-UserFieldsData" {
        It "Should be exported from module" {
            Get-Command Set-UserFieldsData -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have valid help synopsis" {
            $help = Get-Help Set-UserFieldsData
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It "Should have SourceType, SourceId, and UserData parameters" {
            $cmd = Get-Command Set-UserFieldsData
            $cmd.Parameters.Keys | Should -Contain 'SourceType'
            $cmd.Parameters.Keys | Should -Contain 'SourceId'
            $cmd.Parameters.Keys | Should -Contain 'UserData'
        }
    }
}

