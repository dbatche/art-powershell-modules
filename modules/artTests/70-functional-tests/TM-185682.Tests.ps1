# ============================================================================
# TM-185682 - Pester Test
# PUT /orders/{orderId}/details/{orderDetailId}
# Verify: Update existing barcode (with barcodeId) + Create new (without barcodeId)
# ============================================================================

BeforeAll {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
    Setup-EnvironmentVariables -Quiet
}

Describe "TM-185682: PUT /orders/{orderId}/details/{orderDetailId} with mixed barcode array" {
    
    BeforeAll {
        $timestamp = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ss")
        
        Write-Host "`n[Create Order]" -ForegroundColor Cyan
        $script:order = New-Order -Body @{
            orders = @(
                @{
                    pickUpBy = $timestamp
                    pickUpByEnd = $timestamp
                    deliverBy = $timestamp
                    deliverByEnd = $timestamp
                    startZone = "BCLAN"
                    endZone = "ABCAL"
                    caller = @{ clientId = "TM" }
                    consignee = @{ clientId = "TMSUPPORT" }
                }
            )
        } 4>$null
        $script:order | Format-Table orderId, billNumber, startZone, endZone, status | Out-String | Write-Host
        
        Write-Host "[Add Detail]" -ForegroundColor Cyan
        $script:detail = New-OrderDetail -OrderId $script:order.orderId -OrderDetail @(
            @{ weight = 1000; weightUnits = "LB" }
        ) 4>$null
        $script:detail.details | Format-Table orderDetailId, items, weight, weightUnits | Out-String | Write-Host
        
        Write-Host "[Add 2 Initial Barcodes]" -ForegroundColor Cyan
        $script:barcodes = New-OrderDetailBarcode -OrderId $script:order.orderId -OrderDetailId $script:detail.details[0].orderDetailId -Barcodes @(
            @{ altBarcode1 = "ORIGINAL-A"; weight = 100.5; weightUnits = "LB" }
            @{ altBarcode1 = "ORIGINAL-B"; weight = 200.5; weightUnits = "LB" }
        ) 4>$null
        $script:barcodes | Format-Table barcodeId, altBarcode1, weight, weightUnits | Out-String | Write-Host
        
        $script:barcodeId1 = $script:barcodes[0].barcodeId
    }
    
    Context "Initial State" {
        It "Should have created an order" {
            $script:order.orderId | Should -Not -BeNullOrEmpty
            $script:order.status | Should -Be "AVAIL"
        }
        
        It "Should have created a detail" {
            $script:detail.details | Should -HaveCount 3
            $script:detail.details[0].orderDetailId | Should -Not -BeNullOrEmpty
        }
        
        It "Should have 2 initial barcodes" {
            $script:barcodes | Should -HaveCount 2
            $script:barcodes[0].altBarcode1 | Should -Be "ORIGINAL-A"
            $script:barcodes[0].weight | Should -Be 100.5
            $script:barcodes[1].altBarcode1 | Should -Be "ORIGINAL-B"
            $script:barcodes[1].weight | Should -Be 200.5
        }
    }
    
    Context "PUT with mixed barcode array (update 1, create 2)" {
        
        BeforeAll {
            Write-Host "`n[PUT with mixed barcode array - update 1, create 2]" -ForegroundColor Cyan
            $script:result = Set-OrderDetail -OrderId $script:order.orderId -OrderDetailId $script:detail.details[0].orderDetailId -OrderDetail @{
                barcodes = @(
                    @{ barcodeId = $script:barcodeId1; altBarcode1 = "UPDATED-A"; weight = 999.99; weightUnits = "LB" }
                    @{ altBarcode1 = "NEW-C"; weight = 111.11; weightUnits = "LB" }
                    @{ altBarcode1 = "NEW-D"; weight = 222.22; weightUnits = "LB" }
                )
            } 4>$null
            
            Write-Host "[Result - All Barcodes After PUT]" -ForegroundColor Cyan
            $script:result.barcodes | Format-Table barcodeId, altBarcode1, weight, weightUnits | Out-String | Write-Host
        }
        
        It "Should return updated detail with barcodes" {
            $script:result | Should -Not -BeNullOrEmpty
            $script:result.barcodes | Should -Not -BeNullOrEmpty
        }
        
        It "Should have 4 barcodes after PUT (2 original + 2 new)" {
            $script:result.barcodes | Should -HaveCount 4
        }
        
        It "Should have UPDATED the first barcode (with barcodeId)" {
            $updatedBarcode = $script:result.barcodes | Where-Object { $_.barcodeId -eq $script:barcodeId1 }
            $updatedBarcode | Should -Not -BeNullOrEmpty
            $updatedBarcode.altBarcode1 | Should -Be "UPDATED-A"
            $updatedBarcode.weight | Should -Be 999.99
        }
        
        It "Should have kept the second barcode unchanged" {
            $unchangedBarcode = $script:result.barcodes | Where-Object { $_.altBarcode1 -eq "ORIGINAL-B" }
            $unchangedBarcode | Should -Not -BeNullOrEmpty
            $unchangedBarcode.weight | Should -Be 200.5
        }
        
        It "Should have CREATED new barcode NEW-C" {
            $newBarcode = $script:result.barcodes | Where-Object { $_.altBarcode1 -eq "NEW-C" }
            $newBarcode | Should -Not -BeNullOrEmpty
            $newBarcode.weight | Should -Be 111.11
            $newBarcode.barcodeId | Should -Not -Be $script:barcodeId1
        }
        
        It "Should have CREATED new barcode NEW-D" {
            $newBarcode = $script:result.barcodes | Where-Object { $_.altBarcode1 -eq "NEW-D" }
            $newBarcode | Should -Not -BeNullOrEmpty
            $newBarcode.weight | Should -Be 222.22
            $newBarcode.barcodeId | Should -Not -Be $script:barcodeId1
        }
        
        It "Should NOT have created duplicate barcodes" {
            $barcodeIds = $script:result.barcodes | Select-Object -ExpandProperty barcodeId
            $uniqueIds = $barcodeIds | Select-Object -Unique
            $barcodeIds.Count | Should -Be $uniqueIds.Count
        }
    }
}

