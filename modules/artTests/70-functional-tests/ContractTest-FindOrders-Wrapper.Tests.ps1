# ============================================================================
# Contract Test: Find-Orders (Using Wrapper Function)
# Tests both the PowerShell function AND the API endpoint
# ============================================================================

BeforeAll {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTM\artTM.psm1 -Force
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
    Setup-EnvironmentVariables -Quiet
}

Describe "Find-Orders Contract Tests (Using Wrapper Function)" {
    
    Context "Query Parameters" {
        
        It "Should support -Filter parameter" {
            Write-Host "`n[Test: Filter parameter]" -ForegroundColor Cyan
            $result = Find-Orders -Filter "status eq 'AVAIL'" -Limit 2 4>$null
            
            Write-Host "Sample Response:" -ForegroundColor Yellow
            $result | Format-Table orderId, billNumber, status, startZone, endZone -AutoSize | Out-String | Write-Host
            
            $result | Should -Not -BeNullOrEmpty
            $result | ForEach-Object { $_.status | Should -Be "AVAIL" }
        }
        
        It "Should support -Select parameter" {
            Write-Host "`n[Test: Select parameter]" -ForegroundColor Cyan
            $result = Find-Orders -Select "orderId,billNumber,status" -Limit 1 4>$null
            
            Write-Host "Sample Response (only selected fields):" -ForegroundColor Yellow
            $result | Format-List orderId, billNumber, status | Out-String | Write-Host
            
            $result | Should -Not -BeNullOrEmpty
            $result[0].orderId | Should -Not -BeNullOrEmpty
            $result[0].billNumber | Should -Not -BeNullOrEmpty
            # Should NOT have other fields like startZone
            $result[0].PSObject.Properties.Name | Should -Not -Contain "caller"
        }
        
        It "Should support -OrderBy parameter" {
            Write-Host "`n[Test: OrderBy parameter]" -ForegroundColor Cyan
            $result = Find-Orders -OrderBy "orderId desc" -Limit 3 4>$null
            
            Write-Host "Sample Response (ordered by orderId desc):" -ForegroundColor Yellow
            $result | Format-Table orderId, billNumber, status -AutoSize | Out-String | Write-Host
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 1
            # Verify descending order
            $result[0].orderId | Should -BeGreaterThan $result[1].orderId
        }
        
        It "Should support -Limit parameter" {
            Write-Host "`n[Test: Limit parameter]" -ForegroundColor Cyan
            $result = Find-Orders -Limit 5 4>$null
            
            Write-Host "Sample Response (limit 5):" -ForegroundColor Yellow
            Write-Host "Count: $($result.Count)" -ForegroundColor White
            $result | Select-Object -First 2 | Format-Table orderId, billNumber, status -AutoSize | Out-String | Write-Host
            
            $result.Count | Should -BeLessOrEqual 5
        }
        
        It "Should support -Expand parameter" {
            Write-Host "`n[Test: Expand parameter]" -ForegroundColor Cyan
            $result = Find-Orders -Expand "details" -Limit 1 -Filter "type eq 'T'" 4>$null
            
            Write-Host "Sample Response (with expanded details):" -ForegroundColor Yellow
            $result | Format-List orderId, billNumber, @{L="DetailCount";E={$_.details.Count}} | Out-String | Write-Host
            
            if ($result.details) {
                Write-Host "First Detail:" -ForegroundColor Yellow
                $result.details[0] | Format-List orderDetailId, items, weight, weightUnits | Out-String | Write-Host
            }
            
            $result | Should -Not -BeNullOrEmpty
            # If order has details, they should be expanded
            if ($result.details) {
                $result.details | Should -Not -BeNullOrEmpty
                $result.details[0].orderDetailId | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Response Contract" {
        
        BeforeAll {
            $script:order = Find-Orders -Limit 1 4>$null | Select-Object -First 1
        }
        
        It "Should return objects with required properties" {
            Write-Host "`n[Test: Response structure]" -ForegroundColor Cyan
            Write-Host "All Properties:" -ForegroundColor Yellow
            $script:order.PSObject.Properties.Name | Sort-Object | Out-String | Write-Host
            
            $script:order.orderId | Should -Not -BeNullOrEmpty
            $script:order.billNumber | Should -Not -BeNullOrEmpty
            $script:order.PSObject.Properties.Name | Should -Contain "status"
            $script:order.PSObject.Properties.Name | Should -Contain "type"
        }
        
        It "Should return correct data types" {
            Write-Host "`n[Test: Data types]" -ForegroundColor Cyan
            Write-Host "orderId type: $($script:order.orderId.GetType().Name)" -ForegroundColor White
            Write-Host "billNumber type: $($script:order.billNumber.GetType().Name)" -ForegroundColor White
            
            $script:order.orderId | Should -BeOfType [int]
            $script:order.billNumber | Should -BeOfType [string]
        }
    }
    
    Context "Error Handling" {
        
        It "Should return error JSON for invalid filter" {
            Write-Host "`n[Test: Invalid filter error handling]" -ForegroundColor Cyan
            $result = Find-Orders -Filter "invalidField eq 'test'" 2>$null
            
            Write-Host "Sample Error Response:" -ForegroundColor Yellow
            if ($result -is [string]) {
                $errorObj = $result | ConvertFrom-Json
                $errorObj | Format-List status, title, @{L="errorCode";E={$_.errors[0].code}} | Out-String | Write-Host
            }
            
            $result | Should -BeOfType [string]
            $result | Should -Match "invalidODataQuery|invalidField"
        }
    }
}

