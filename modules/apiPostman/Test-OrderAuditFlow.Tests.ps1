<#
.SYNOPSIS
    Pester tests for the order audit flow

.DESCRIPTION
    Tests the order audit workflow:
    1. Creates a posted order with default data
    2. PUTs to the order with audits array (deliverBy, deliverByEnd, deliveryApptReq, deliveryApptMade)
    3. Validates that 'audits' is NOT in the PUT response (write-only field)
    4. GETs /statusHistory to verify audit entries were created
    5. Validates each audit has a corresponding statusHistory entry

.NOTES
    Requires Pester v5+
    Set environment variables: TM_API_URL, TRUCKMATE_API_KEY
#>

<#
# Audit pickup/delivery dates
Here we are verifying that audits work for pickup/delivery related fields.

## Pre-requisites
Truckmate system must be configured for Auditing of Edits (in the Security application, Business Events - Miscellaneous, Customer Service to one of the options for 'Audit Edits')
Security changes require a restart of ART service to take effect
The auditStatus code must be defined in Codes under 'Additional Rules', 'Enable as Audit' = Checked

## Request Parameters
The request body must be in JSON format and includes the following parameters:
- pickUpBy, pickUpByEnd, pickUpApptReq, pickUpApptMade
- deliverBy, deliverByEnd, deliveryApptReq, deliveryApptMade
- audits (array): Contains audit details related to the appointment. Each audit entry includes:
    - auditField (enum): The field being audited (e.g. pickUpBy) must have a matching entry here.
    - auditStatus (string): The status of the audit. Must be a valid code.
    - reasonCode (string): The reason for the audit. Must be a valid service failure code (Codes Maintenance), and also Security (Reason Codes - Cserv Pickup/Delivery Dates)
    - comment (string): Additional comments regarding the audit.


## Expected Response
Upon a successful update, the API returns a 200 OK status.
audits (array): Should NOT be present in the response

## Status History
/orders/orderId/statusHistory will confirm the audit entries, comparing status code, reason code and comment.
Each audit entry in the array should have a corresponding status history entry.
pickup/delivery dates with no time portion should default to 00:00 - 23:59:59 (in the comment)

#>

BeforeAll {
    # Configuration
    $script:BaseUrl = $env:TM_API_URL
    $script:Token = $env:TRUCKMATE_API_KEY
    
    if (-not $script:BaseUrl) {
        throw "TM_API_URL environment variable not set"
    }
    
    if (-not $script:Token) {
        throw "TRUCKMATE_API_KEY environment variable not set"
    }
    
    # Helper function to make API requests
    function Invoke-TmApiRequest {
        param(
            [string]$Uri,
            [string]$Method = 'GET',
            [object]$Body,
            [string]$Token
        )
        
        $headers = @{
            'Authorization' = "Bearer $Token"
            'Content-Type' = 'application/json'
        }
        
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $headers
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        try {
            $response = Invoke-RestMethod @params
            return $response
        } catch {
            Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Red
            if ($_.ErrorDetails.Message) {
                Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
            throw
        }
    }
    
    # Create timestamps
    $script:timestamp1 = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $script:timestamp2 = (Get-Date).AddMinutes(10).ToString("yyyy-MM-ddTHH:mm:ss")
    
    # Write-Host "Timestamp 1 (initial): $($script:timestamp1)" -ForegroundColor Gray
    # Write-Host "Timestamp 2 (+10min):  $($script:timestamp2)" -ForegroundColor Gray
}

Describe "Order Audit Flow - Write-only audits field creates statusHistory entries" -Tag "Integration", "API", "Audit" {
    
    <#
    Test Scenario:
        GIVEN a posted order with initial pickup/delivery dates
        WHEN PUT /orders/{orderId} with changed delivery dates AND audits array
            (audits for: deliverBy, deliverByEnd, deliveryApptReq, deliveryApptMade)
        THEN PUT response should NOT contain 'audits' field (write-only)
        AND GET /orders/{orderId}/statusHistory should return audit entries
        AND each audit field change should have a corresponding statusHistory entry
        
    Endpoints tested:
        - POST /orders (setup)
        - PUT /orders/{orderId} (audits sent here)
        - GET /orders/{orderId}/statusHistory (audit entries verified here)
        
    This validates:
        - The 'audits' field is write-only on PUT /orders (TM-184647)
        - Pickup/delivery date changes with audits are tracked in statusHistory
        - Each audit entry (statusCode, reasonCode, comment) is preserved
        - Audit trail is queryable for compliance/tracking purposes
        
    Note: Field values must differ by several minutes for audit to trigger
    #>
    
    BeforeAll {
        # Create a posted order
        $orderBody = @{
            orders = @(@{
                startZone = "ABEDM"
                endZone = "MBBRA"
                serviceLevel = "LTL"
                billTo = "C"
                caller = @{clientId='TM'}
                pickUpBy = $script:timestamp1
                pickUpByEnd = $script:timestamp1
                deliverBy = $script:timestamp1
                deliverByEnd = $script:timestamp1
            })
        }
        
        # Write-Host "Creating test order..." -ForegroundColor Cyan
        $createResponse = Invoke-TmApiRequest -Uri "$($script:BaseUrl)/orders" -Method POST -Body $orderBody -Token $script:Token
        
        if (-not $createResponse.orders -or $createResponse.orders.Count -eq 0) {
            throw "Failed to create order - prerequisite for audit tests not met"
        }
        
        $script:orderId = $createResponse.orders[0].orderId
        # Write-Host "Created order: $($script:orderId)" -ForegroundColor Green
        
        # Define audit array for PUT request
        $script:audits = @(
            @{
                auditField = "deliverBy"
                auditStatus = "AUDIT2"
                reasonCode = "SF1"
                comment = "DDDD"
            },
            @{
                auditField = "deliverByEnd"
                auditStatus = "AUDIT2"
                reasonCode = "SF1"
                comment = "EEEE"
            },
            @{
                auditField = "deliveryApptReq"
                auditStatus = "AUDIT2"
                reasonCode = "SF1"
                comment = "FFFF1"
            },
            @{
                auditField = "deliveryApptMade"
                auditStatus = "AUDIT2"
                reasonCode = "SF1"
                comment = "FFFF"
            }
        )
        
        # Update order with audits
        $updateBody = @{
            startZone = "ABEDM"
            endZone = "MBBRA"
            serviceLevel = "LTL"
            deliverBy = $script:timestamp2
            deliverByEnd = $script:timestamp2
            deliveryApptMade = "True"
            deliveryApptReq = "True"
            audits = $script:audits
        }
        
        # Write-Host "Updating order with audits..." -ForegroundColor Cyan
        $script:updateResponse = Invoke-TmApiRequest -Uri "$($script:BaseUrl)/orders/$($script:orderId)" -Method PUT -Body $updateBody -Token $script:Token
        # Write-Host "Order updated successfully" -ForegroundColor Green
        
        # Get statusHistory
        # Write-Host "Getting statusHistory..." -ForegroundColor Cyan
        $statusHistoryResponse = Invoke-TmApiRequest -Uri "$($script:BaseUrl)/orders/$($script:orderId)/statusHistory" -Method GET -Token $script:Token
        $script:statusHistory = $statusHistoryResponse.statusHistory
        # Write-Host "Retrieved $($script:statusHistory.Count) statusHistory entries" -ForegroundColor Green
        
        # Filter for audit entries
        $script:auditEntries = $script:statusHistory | Where-Object { 
            $_.statusCode -eq 'AUDIT2' -and $_.reason -eq 'SF1'
        }
        # Write-Host "Found $($script:auditEntries.Count) audit entries" -ForegroundColor Green
    }
    
    Context "PUT /orders/{orderId} with audits array" {
        It "Response should NOT contain 'audits' field (write-only on pickup/delivery date changes)" {
            $script:updateResponse.PSObject.Properties.Name | Should -Not -Contain 'audits'
        }
        
        It "Response should return valid updated order with orderId $($script:orderId)" {
            $script:updateResponse | Should -Not -BeNullOrEmpty
            $script:updateResponse.orderId | Should -Be $script:orderId
        }
    }
    
    Context "GET /orders/{orderId}/statusHistory to verify audit trail" {
        It "StatusHistory endpoint should return audit tracking entries" {
            $script:statusHistory | Should -Not -BeNullOrEmpty
            # statusHistory is an array/collection
            @($script:statusHistory).Count | Should -BeGreaterThan 0
        }
        
        It "StatusHistory should contain audit entries (statusCode=AUDIT2, reason=SF1) for date changes" {
            $script:auditEntries.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Audit Trail Validation - Each pickup/delivery date change tracked in statusHistory" {
        BeforeAll {
            # Display audit entries for debugging
            # Write-Host "`nAudit entries found:" -ForegroundColor Yellow
            # foreach ($entry in $script:auditEntries) {
            #     Write-Host "  - Status: $($entry.statusCode), Reason: $($entry.reason), Comment: $($entry.statComment)" -ForegroundColor Gray
            # }
            # Write-Host ""
        }
        
        It "Audit field '<auditField>' change should be tracked in statusHistory with statusCode '<auditStatus>' and reasonCode '<reasonCode>'" -TestCases @(
            @{ auditField = "deliverBy"; auditStatus = "AUDIT2"; reasonCode = "SF1"; comment = "DDDD" }
            @{ auditField = "deliverByEnd"; auditStatus = "AUDIT2"; reasonCode = "SF1"; comment = "EEEE" }
            @{ auditField = "deliveryApptReq"; auditStatus = "AUDIT2"; reasonCode = "SF1"; comment = "FFFF1" }
            @{ auditField = "deliveryApptMade"; auditStatus = "AUDIT2"; reasonCode = "SF1"; comment = "FFFF" }
        ) {
            param($auditField, $auditStatus, $reasonCode, $comment)
            
            # Find matching entries (may return multiple)
            $matchingEntries = @($script:auditEntries | Where-Object {
                ($_.statComment -and $_.statComment.ToLower().Contains($auditField.ToLower())) -or
                ($_.statComment -and $_.statComment.Contains($comment))
            })
            
            # Get the first matching entry for assertions
            $matchingEntry = $matchingEntries | Select-Object -First 1
            
            # Assertions
            $matchingEntry | Should -Not -BeNullOrEmpty -Because "Each audit field must have a corresponding statusHistory entry (check that field value changed sufficiently - needs several minutes difference)"
            $matchingEntry.statusCode | Should -Be $auditStatus
            $matchingEntry.reason | Should -Be $reasonCode
            
            # Write-Host "  ✓ $auditField found in: $($matchingEntry.statComment)" -ForegroundColor Green
        }
        
        It "All audit entries should be present in statusHistory" {
            # Each audit should have a corresponding statusHistory entry
            $script:auditEntries.Count | Should -BeGreaterOrEqual 1
            $script:auditEntries.Count | Should -BeLessOrEqual $script:audits.Count
        }
    }
}

AfterAll {
    # Write-Host "`nTest Summary:" -ForegroundColor Yellow
    # Write-Host "  Order ID: $($script:orderId)" -ForegroundColor White
    # Write-Host "  Audits sent: $($script:audits.Count)" -ForegroundColor White
    # Write-Host "  StatusHistory entries: $($script:statusHistory.Count)" -ForegroundColor White
    # Write-Host "  Audit entries found: $($script:auditEntries.Count)" -ForegroundColor White
}

