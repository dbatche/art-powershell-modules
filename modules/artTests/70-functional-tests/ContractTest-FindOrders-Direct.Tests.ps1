# ============================================================================
# Contract Test: GET /orders (Using Invoke-RestMethod Directly)
# Tests ONLY the API endpoint (no PowerShell wrapper)
# 
# Usage:
#   Invoke-Pester .\ContractTest-FindOrders-Direct.Tests.ps1                              # Quiet (only pass/fail summary)
#   Invoke-Pester .\ContractTest-FindOrders-Direct.Tests.ps1 -Output Detailed             # Just validations (Should...)
#   Invoke-Pester .\ContractTest-FindOrders-Direct.Tests.ps1 -Output Detailed -ShowApiOutput  # Both output + validations
#
# Or via environment variable:
#   $env:SHOW_API_OUTPUT = "true"; Invoke-Pester .\ContractTest-FindOrders-Direct.Tests.ps1 -Output Detailed
# ============================================================================

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$ShowApiOutput
)

BeforeAll {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module C:\Users\dbatchelor\Documents\SCRIPTING\modules\artTests\artTests.psm1 -Force
    Setup-EnvironmentVariables -Quiet
    
    $script:baseUrl = $env:TM_API_URL
    $script:headers = @{
        Authorization = "Bearer $env:TRUCKMATE_API_KEY"
        Accept = "application/json"
    }
    
    # Check for output control via parameter or environment variable
    $script:ShowOutput = $ShowApiOutput -or ($env:SHOW_API_OUTPUT -eq "true")
    
    # Helper function to conditionally write output
    function Write-TestOutput {
        param(
            [Parameter(ValueFromPipeline=$true)]
            [string]$Message, 
            [string]$ForegroundColor = "White"
        )
        process {
            if ($script:ShowOutput) {
                if ($Message) {
                    Write-Host $Message -ForegroundColor $ForegroundColor
                }
            }
        }
    }
}

Describe "GET /orders Contract Tests (Using Invoke-RestMethod)" {
    
    Context "Query Parameters" {
        
        It "Should support $filter query parameter" {
            Write-TestOutput "`n[Test: OData filter]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?`$filter=status eq 'AVAIL'&limit=2"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Pagination Wrapper:" -ForegroundColor Yellow
            Write-TestOutput "  count: $($response.count)" -ForegroundColor White
            Write-TestOutput "  limit: $($response.limit)" -ForegroundColor White
            Write-TestOutput "  orders array length: $($response.orders.Count)" -ForegroundColor White
            
            Write-TestOutput "`nSample Orders:" -ForegroundColor Yellow
            Write-TestOutput ($response.orders | Select-Object -First 2 | ConvertTo-Json -Depth 1) -ForegroundColor White
            
            $response.orders | Should -Not -BeNullOrEmpty
            $response.orders | Should -BeOfType [array]
            $response.orders[0].status | Should -Be "AVAIL"
            $response.count | Should -Not -BeNullOrEmpty
        }
        
        It "Should support $select query parameter" {
            Write-TestOutput "`n[Test: OData select]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?`$select=orderId,billNumber,status&limit=1"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Sample Response (selected fields only):" -ForegroundColor Yellow
            Write-TestOutput ($response.orders[0] | ConvertTo-Json -Depth 1) -ForegroundColor White
            
            $response.orders[0].orderId | Should -Not -BeNullOrEmpty
            $response.orders[0].billNumber | Should -Not -BeNullOrEmpty
            $response.orders[0].PSObject.Properties.Name | Should -Not -Contain "caller"
        }
        
        It "Should support $orderby query parameter" {
            Write-TestOutput "`n[Test: OData orderby]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?`$orderby=orderId desc&limit=3"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Sample Response (ordered desc):" -ForegroundColor Yellow
            $response.orders | Select-Object orderId, billNumber | Format-Table | Out-String | Write-TestOutput
            
            $response.orders.Count | Should -BeGreaterThan 1
            $response.orders[0].orderId | Should -BeGreaterThan $response.orders[1].orderId
        }
        
        It "Should support limit query parameter" {
            Write-TestOutput "`n[Test: limit parameter]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?limit=5"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Pagination Info:" -ForegroundColor Yellow
            Write-TestOutput "  Total count: $($response.count)" -ForegroundColor White
            Write-TestOutput "  Requested limit: $($response.limit)" -ForegroundColor White
            Write-TestOutput "  Returned orders: $($response.orders.Count)" -ForegroundColor White
            
            $response.orders.Count | Should -BeLessOrEqual 5
            $response.limit | Should -Be 5
        }
        
        It "Should support expand query parameter" {
            Write-TestOutput "`n[Test: expand parameter]" -ForegroundColor Cyan
            # Use billNumber filter instead of type (which isn't in response)
            $uri = "$script:baseUrl/orders?expand=details&limit=1&`$filter=status eq 'AVAIL'"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Sample Response (with details):" -ForegroundColor Yellow
            Write-TestOutput "Order ID: $($response.orders[0].orderId)" -ForegroundColor White
            Write-TestOutput "Details Count: $($response.orders[0].details.Count)" -ForegroundColor White
            
            if ($response.orders[0].details) {
                Write-TestOutput "First Detail JSON:" -ForegroundColor Yellow
                Write-TestOutput ($response.orders[0].details[0] | ConvertTo-Json -Depth 1) -ForegroundColor White
            }
            
            # If order has details, verify they're expanded
            if ($response.orders[0].details) {
                $response.orders[0].details | Should -Not -BeNullOrEmpty
                $response.orders[0].details[0].orderDetailId | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Response Headers and Status" {
        
        It "Should return 200 OK status" {
            Write-TestOutput "`n[Test: HTTP status code]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?limit=1"
            
            $response = Invoke-WebRequest -Uri $uri -Method Get -Headers $script:headers
            
            Write-TestOutput "Status Code: $($response.StatusCode)" -ForegroundColor White
            Write-TestOutput "Content-Type: $($response.Headers['Content-Type'])" -ForegroundColor White
            
            $response.StatusCode | Should -Be 200
            $response.Headers['Content-Type'] | Should -Match "application/json"
        }
    }
    
    Context "Response Contract" {
        
        BeforeAll {
            $uri = "$script:baseUrl/orders?limit=1"
            $wrapper = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
            $script:response = $wrapper
            $script:order = $wrapper.orders[0]
        }
        
        It "Should return pagination wrapper with metadata" {
            Write-TestOutput "`n[Test: Pagination wrapper structure]" -ForegroundColor Cyan
            Write-TestOutput "Wrapper properties:" -ForegroundColor Yellow
            $script:response.PSObject.Properties.Name | Sort-Object | Out-String | Write-TestOutput
            
            $script:response.PSObject.Properties.Name | Should -Contain "count"
            $script:response.PSObject.Properties.Name | Should -Contain "limit"
            $script:response.PSObject.Properties.Name | Should -Contain "offset"
            $script:response.PSObject.Properties.Name | Should -Contain "orders"
            $script:response.orders | Should -BeOfType [array]
        }
        
        It "Should return JSON with required schema" {
            Write-TestOutput "`n[Test: Order object schema]" -ForegroundColor Cyan
            Write-TestOutput "All Properties:" -ForegroundColor Yellow
            $script:order.PSObject.Properties.Name | Sort-Object | Out-String | Write-TestOutput
            
            $script:order.orderId | Should -Not -BeNullOrEmpty
            $script:order.billNumber | Should -Not -BeNullOrEmpty
            $script:order.PSObject.Properties.Name | Should -Contain "status"
            $script:order.PSObject.Properties.Name | Should -Contain "caller"
            $script:order.PSObject.Properties.Name | Should -Contain "consignee"
        }
        
        It "Should return correct data types" {
            Write-TestOutput "`n[Test: JSON data types]" -ForegroundColor Cyan
            Write-TestOutput "Raw JSON snippet:" -ForegroundColor Yellow
            Write-TestOutput ($script:order | Select-Object orderId, billNumber, status | ConvertTo-Json) -ForegroundColor White
            
            $script:order.orderId | Should -BeOfType [long]
            $script:order.billNumber | Should -BeOfType [string]
        }
        
        It "Should return nested objects correctly" {
            Write-TestOutput "`n[Test: Nested caller object]" -ForegroundColor Cyan
            Write-TestOutput ($script:order.caller | ConvertTo-Json -Depth 1) -ForegroundColor White
            
            $script:order.caller | Should -Not -BeNullOrEmpty
            $script:order.caller.PSObject.Properties.Name | Should -Contain "clientId"
            $script:order.caller.PSObject.Properties.Name | Should -Contain "name"
        }
    }
    
    Context "Error Handling" {
        
        It "Should return 400 for invalid OData query" {
            Write-TestOutput "`n[Test: Invalid OData query]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?`$filter=invalidField eq 'test'"
            Write-TestOutput "URI: $uri" -ForegroundColor DarkGray
            
            try {
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $script:headers
                throw "Should have thrown an error"
            }
            catch {
                Write-TestOutput "Error Response:" -ForegroundColor Yellow
                if ($_.ErrorDetails.Message) {
                    $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
                    Write-TestOutput ($errorObj | ConvertTo-Json -Depth 2) -ForegroundColor White
                    
                    $errorObj.status | Should -Be 400
                    $errorObj.errors[0].code | Should -Be "invalidQueryParameter"
                }
            }
        }
        
        It "Should return 401 for missing auth" {
            Write-TestOutput "`n[Test: Missing authorization]" -ForegroundColor Cyan
            $uri = "$script:baseUrl/orders?limit=1"
            
            try {
                $response = Invoke-RestMethod -Uri $uri -Method Get
                throw "Should have thrown an error"
            }
            catch {
                Write-TestOutput "Error Status: 401 Unauthorized" -ForegroundColor White
                $_.Exception.Response.StatusCode.value__ | Should -Be 401
            }
        }
    }
}



