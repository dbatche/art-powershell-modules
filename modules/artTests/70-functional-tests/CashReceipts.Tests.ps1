# Pester Tests for Cash Receipts API
# Uses Pester v5 syntax with PowerShell wrapper functions

BeforeAll {
    # Import required modules
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force -WarningAction SilentlyContinue
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artFinance\artFinance.psm1 -Force -WarningAction SilentlyContinue
    
    # Setup environment variables quietly
    Setup-EnvironmentVariables -Quiet
}

Describe "Cash Receipts API - GET Operations" {
    
    Context "When retrieving cash receipts collection" {
        
        It "Should return cash receipts without errors" {
            $result = Get-CashReceipts -Limit 5
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Not -BeOfType [string]  # Not an error string
        }
        
        It "Should return cash receipts with valid properties" {
            $receipts = Get-CashReceipts -Limit 1
            $firstReceipt = if ($receipts -is [array]) { $receipts[0] } else { $receipts }
            
            $firstReceipt.cashReceiptId | Should -Not -BeNullOrEmpty
            $firstReceipt.clientId | Should -Not -BeNullOrEmpty
            $firstReceipt.checkAmount | Should -BeGreaterThan 0  # Numeric check instead of type
        }
    }
    
    Context "When retrieving a single cash receipt by ID" {
        
        BeforeAll {
            # Get a valid receipt ID
            $receipts = Get-CashReceipts -Limit 1
            $script:testReceiptId = if ($receipts -is [array]) {
                $receipts[0].cashReceiptId
            } else {
                $receipts.cashReceiptId
            }
        }
        
        It "Should return the specific cash receipt" {
            $result = Get-CashReceipts -CashReceiptId $script:testReceiptId
            
            $result | Should -Not -BeOfType [string]
            $result.cashReceiptId | Should -Be $script:testReceiptId
        }
        
        It "Should have all expected properties" {
            $result = Get-CashReceipts -CashReceiptId $script:testReceiptId
            
            $result.PSObject.Properties.Name | Should -Contain 'cashReceiptId'
            $result.PSObject.Properties.Name | Should -Contain 'clientId'
            $result.PSObject.Properties.Name | Should -Contain 'checkAmount'
            $result.PSObject.Properties.Name | Should -Contain 'checkDate'
        }
    }
    
    Context "When using expand parameter" {
        
        BeforeAll {
            # Find a receipt (preferably with invoices)
            $receipts = Get-CashReceipts -Expand "invoices" -Limit 10
            $receiptsArray = if ($receipts -is [array]) { $receipts } else { @($receipts) }
            $script:testReceiptId = $receiptsArray[0].cashReceiptId
        }
        
        It "Should return expanded invoices collection" {
            $result = Get-CashReceipts -CashReceiptId $script:testReceiptId -Expand "invoices"
            
            $result | Should -Not -BeOfType [string]
            $result.PSObject.Properties.Name | Should -Contain 'invoices'
        }
    }
}

Describe "Cash Receipts API - PUT Operations" {
    
    Context "When updating with valid data" {
        
        BeforeAll {
            # Find an unposted receipt to modify
            $receipts = Get-CashReceipts -Filter "transactionPosted eq False" -Limit 1
            if ($receipts -is [string] -or -not $receipts) {
                $receipts = Get-CashReceipts -Limit 1
            }
            $firstReceipt = if ($receipts -is [array]) { $receipts[0] } else { $receipts }
            $script:testReceiptId = $firstReceipt.cashReceiptId
            $script:originalAmount = $firstReceipt.checkAmount
        }
        
        It "Should successfully update checkAmount" {
            $newAmount = $script:originalAmount + 10.50
            
            $result = Set-CashReceipt -CashReceiptId $script:testReceiptId -CashReceipt @{
                checkAmount = $newAmount
            }
            
            $result | Should -Not -BeOfType [string]
            $result.checkAmount | Should -Be $newAmount
        }
    }
    
    Context "When updating with invalid data" -Tag "ErrorHandling" {
        
        BeforeAll {
            $receipts = Get-CashReceipts -Limit 1
            $script:testReceiptId = if ($receipts -is [array]) {
                $receipts[0].cashReceiptId
            } else {
                $receipts.cashReceiptId
            }
        }
        
        It "Should reject negative checkAmount" {
            $result = Set-CashReceipt -CashReceiptId $script:testReceiptId -CashReceipt @{
                checkAmount = -100
            } 2>$null
            
            $result | Should -BeOfType [string]
            $result | Should -Match '"status"\s*:\s*400'
        }
        
        It "Should return validation error with error code" {
            $result = Set-CashReceipt -CashReceiptId $script:testReceiptId -CashReceipt @{
                checkAmount = -100
            } 2>$null
            
            $errorObj = $result | ConvertFrom-Json
            $errorObj.status | Should -Be 400
            $errorObj.errors | Should -Not -BeNullOrEmpty
            $errorObj.errors[0].code | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Cash Receipts API - Performance" -Tag "Performance" {
    
    It "Should retrieve cash receipts in reasonable time" {
        $elapsed = Measure-Command {
            Get-CashReceipts -Limit 10
        }
        
        $elapsed.TotalMilliseconds | Should -BeLessThan 5000  # Less than 5 seconds
    }
    
    It "Should update cash receipt in reasonable time" {
        $receipts = Get-CashReceipts -Limit 1
        $receiptId = if ($receipts -is [array]) {
            $receipts[0].cashReceiptId
        } else {
            $receipts.cashReceiptId
        }
        
        $elapsed = Measure-Command {
            Set-CashReceipt -CashReceiptId $receiptId -CashReceipt @{
                checkReference = "Pester-Test-$(Get-Random)"
            } | Out-Null
        }
        
        $elapsed.TotalMilliseconds | Should -BeLessThan 10000  # Less than 10 seconds
    }
}

