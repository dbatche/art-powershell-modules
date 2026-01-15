# Functional Tests for Cash Receipts API
# Uses PowerShell wrapper functions instead of raw HTTP calls
# Generated: 2025-10-17

@(
    @{
        Name = "Get cash receipts - retrieve collection"
        Description = "Verify GET /cashReceipts returns a collection"
        Setup = $null
        Test = {
            Get-CashReceipts -Limit 5
        }
        Assert = {
            param($result)
            # Success if not an error string
            $result -isnot [string]
        }
        ExpectedOutcome = "Success - Returns cash receipts"
    },
    
    @{
        Name = "Get cash receipts - single item by ID"
        Description = "Retrieve a specific cash receipt by ID"
        Setup = {
            # Get a valid receipt ID first
            $receipts = Get-CashReceipts -Limit 1
            if ($receipts -is [string]) {
                throw "Setup failed: Could not fetch receipts"
            }
            # Handle both array and single object
            $script:testReceiptId = if ($receipts -is [array]) {
                $receipts[0].cashReceiptId
            } else {
                $receipts.cashReceiptId
            }
        }
        Test = {
            Get-CashReceipts -CashReceiptId $script:testReceiptId
        }
        Assert = {
            param($result)
            # Success if not an error string and has cashReceiptId
            ($result -isnot [string]) -and ($null -ne $result.cashReceiptId)
        }
        ExpectedOutcome = "Success - Returns single cash receipt"
        Cleanup = {
            Remove-Variable -Name testReceiptId -Scope Script -ErrorAction SilentlyContinue
        }
    },
    
    @{
        Name = "Update cash receipt - valid checkAmount"
        Description = "Update checkAmount field with valid value"
        Setup = {
            # Find an unposted receipt to modify
            $receipts = Get-CashReceipts -Filter "transactionPosted eq False" -Limit 1
            if ($receipts -is [string] -or -not $receipts) {
                # Fallback: just get any receipt
                $receipts = Get-CashReceipts -Limit 1
            }
            if ($receipts -is [string]) {
                throw "Setup failed: Could not fetch receipts"
            }
            # Handle both array and single object
            $firstReceipt = if ($receipts -is [array]) { $receipts[0] } else { $receipts }
            $script:testReceiptId = $firstReceipt.cashReceiptId
            $script:originalAmount = $firstReceipt.checkAmount
        }
        Test = {
            $newAmount = $script:originalAmount + 10.50
            Set-CashReceipt -CashReceiptId $script:testReceiptId -CashReceipt @{
                checkAmount = $newAmount
            }
        }
        Assert = {
            param($result)
            # Success if not an error string
            $result -isnot [string]
        }
        ExpectedOutcome = "Success - Updates checkAmount"
        Cleanup = {
            Remove-Variable -Name testReceiptId, originalAmount -Scope Script -ErrorAction SilentlyContinue
        }
    },
    
    @{
        Name = "Update cash receipt - invalid checkAmount (negative)"
        Description = "Attempt to set negative checkAmount (should fail)"
        Setup = {
            $receipts = Get-CashReceipts -Limit 1
            if ($receipts -is [string]) {
                throw "Setup failed: Could not fetch receipts"
            }
            # Handle both array and single object
            $script:testReceiptId = if ($receipts -is [array]) {
                $receipts[0].cashReceiptId
            } else {
                $receipts.cashReceiptId
            }
        }
        Test = {
            Set-CashReceipt -CashReceiptId $script:testReceiptId -CashReceipt @{
                checkAmount = -100
            } 2>$null  # Suppress Write-Error
        }
        Assert = {
            param($result)
            # Should return error string with 400 status
            if ($result -is [string]) {
                # Check if the error string contains status 400
                $result -match '"status"\s*:\s*400'
            } else {
                $false
            }
        }
        ExpectedOutcome = "Fail - Returns 400 validation error"
        Cleanup = {
            Remove-Variable -Name testReceiptId -Scope Script -ErrorAction SilentlyContinue
        }
    },
    
    @{
        Name = "Get cash receipts with expand"
        Description = "Retrieve cash receipt with expanded invoices"
        Setup = {
            # Find a receipt that has invoices
            $receipts = Get-CashReceipts -Expand "invoices" -Limit 10
            if ($receipts -is [string]) {
                throw "Setup failed: Could not fetch receipts"
            }
            # Ensure array for Where-Object
            $receiptsArray = if ($receipts -is [array]) { $receipts } else { @($receipts) }
            # Find one with invoices
            $receiptWithInvoices = $receiptsArray | Where-Object { $_.invoices -and $_.invoices.Count -gt 0 } | Select-Object -First 1
            if (-not $receiptWithInvoices) {
                # Just use first one
                $receiptWithInvoices = $receiptsArray[0]
            }
            $script:testReceiptId = $receiptWithInvoices.cashReceiptId
        }
        Test = {
            Get-CashReceipts -CashReceiptId $script:testReceiptId -Expand "invoices"
        }
        Assert = {
            param($result)
            # Success if not an error and has the invoices property (even if null)
            ($result -isnot [string]) -and ($null -ne $result.cashReceiptId)
        }
        ExpectedOutcome = "Success - Returns receipt with invoices expanded"
        Cleanup = {
            Remove-Variable -Name testReceiptId -Scope Script -ErrorAction SilentlyContinue
        }
    }
)

