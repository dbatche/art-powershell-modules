# ============================================================================
# Contract Test: PUT /userFieldsData (Finance API)
# Tests validation rules and error handling for the userFieldsData endpoint
# ============================================================================

BeforeAll {
    Import-Module C:\git\art-powershell-modules\modules\artFinance\artFinance.psm1 -Force
    Import-Module C:\git\art-powershell-modules\modules\artTests\artTests.psm1 -Force
    
    # Setup environment variables (with check for individual test runs)
    # Note: Setup-EnvironmentVariables output cannot be suppressed due to Write-Host usage
    # TODO: Update Setup-EnvironmentVariables to use Write-Information instead
    if (-not $env:TRUCKMATE_API_KEY -or -not $env:FINANCE_API_URL) {
        Setup-EnvironmentVariables -Quiet
    }
    
    # Test data configuration
    # Note: Some sourceTypes don't have valid sourceIds for 200 success tests
    $script:testConfigs = @{
        apInvoices = @{
            sourceType = 'apInvoices'
            validSourceId = 17376  # Known valid AP Invoice
            hasValidSourceId = $true
        }
        driverStatements = @{
            sourceType = 'driverStatements'
            validSourceId = -1     # No valid ID available
            hasValidSourceId = $false
        }
    }
    
    # User field variations (USER1-USER20)
    $script:userFields = @('USER1', 'USER5', 'USER10', 'USER20')
}

# Run tests for EACH sourceType using TestCases at Describe level
Describe "PUT /userFieldsData Contract Tests - <sourceType>" -ForEach @(
    @{ sourceType = 'apInvoices'; sourceId = 17376; hasValidSourceId = $true }
    @{ sourceType = 'driverStatements'; sourceId = -1; hasValidSourceId = $false }
) {
    
    BeforeAll {
        $script:testSourceType = $sourceType
        $script:testSourceId = $sourceId
        $script:testUserField = 'USER1'
        $script:validUserData = 'ContractTest'
        $script:hasValidSourceId = $hasValidSourceId
    }
    
    Context "missingRequiredField - sourceType" {
        
        BeforeAll {
            # # Write-Host "`n[Context: Missing sourceType parameter]" -ForegroundColor Cyan
            $script:missingSourceTypeResult = Set-UserFieldsData -SourceId $script:testSourceId -UserField $script:testUserField -UserData 'test' 2>$null
            $script:missingSourceTypeError = $script:missingSourceTypeResult | ConvertFrom-Json
            
            # # Write-Host "Error Response:" -ForegroundColor Yellow
            # # Write-Host "  Status: $($script:missingSourceTypeError.status)" -ForegroundColor White
            # # Write-Host "  Errors Count: $($script:missingSourceTypeError.errors.Count)" -ForegroundColor White
            # # Write-Host "  Error Type: $(($script:missingSourceTypeError.errors[0].type -replace '.*#:~:text=', ''))" -ForegroundColor White
            # # Write-Host "  Error Title: $($script:missingSourceTypeError.errors[0].title)" -ForegroundColor Gray
        }
        
        It "Should return error response string" {
            $script:missingSourceTypeResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:missingSourceTypeError.status | Should -Be 400
        }
        
        It "Should return missingRequiredField error type" {
            ($script:missingSourceTypeError.errors[0].type -replace '.*#:~:text=', '') | Should -Be 'missingRequiredField'
        }
        
        It "Should mention sourceType in error title" {
            $script:missingSourceTypeError.errors[0].title | Should -Match 'sourceType.*required'
        }
    }
    
    Context "missingRequiredField - sourceId" {
        
        BeforeAll {
            # # Write-Host "`n[Context: Missing sourceId parameter]" -ForegroundColor Cyan
            $script:missingSourceIdResult = Set-UserFieldsData -SourceType $script:testSourceType -UserField $script:testUserField -UserData 'test' 2>$null
            $script:missingSourceIdError = $script:missingSourceIdResult | ConvertFrom-Json
            
            # # Write-Host "Error Response:" -ForegroundColor Yellow
            # # Write-Host "  Status: $($script:missingSourceIdError.status)" -ForegroundColor White
            # # Write-Host "  Error Type: $(($script:missingSourceIdError.errors[0].type -replace '.*#:~:text=', ''))" -ForegroundColor White
            # # Write-Host "  Error Title: $($script:missingSourceIdError.errors[0].title)" -ForegroundColor Gray
        }
        
        It "Should return error response string" {
            $script:missingSourceIdResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:missingSourceIdError.status | Should -Be 400
        }
        
        It "Should return missingRequiredField error type" {
            ($script:missingSourceIdError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'missingRequiredField|requiredField'
        }
        
        It "Should mention sourceId in error title" {
            $script:missingSourceIdError.errors[0].title | Should -Match 'sourceId.*required'
        }
    }
    
    Context "missingRequiredField - userField" {
        
        BeforeAll {
            # # Write-Host "`n[Context: Missing userField parameter]" -ForegroundColor Cyan
            $script:missingUserFieldResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserData 'test' 2>$null
            $script:missingUserFieldError = $script:missingUserFieldResult | ConvertFrom-Json
            
            # # Write-Host "Error Response:" -ForegroundColor Yellow
            # # Write-Host "  Status: $($script:missingUserFieldError.status)" -ForegroundColor White
            # # Write-Host "  Error Type: $(($script:missingUserFieldError.errors[0].type -replace '.*#:~:text=', ''))" -ForegroundColor White
            # # Write-Host "  Error Title: $($script:missingUserFieldError.errors[0].title)" -ForegroundColor Gray
        }
        
        It "Should return error response string" {
            $script:missingUserFieldResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:missingUserFieldError.status | Should -Be 400
        }
        
        It "Should return missingRequiredField error type" {
            ($script:missingUserFieldError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'missingRequiredField|requiredField'
        }
        
        It "Should mention userField in error title" {
            $script:missingUserFieldError.errors[0].title | Should -Match 'userField.*required'
        }
    }
    
    Context "invalidEnum - sourceType" {
        
        BeforeAll {
            $script:invalidEnumResult = Set-UserFieldsData -SourceType 'invalidSourceType' -SourceId $script:testSourceId -UserField $script:testUserField -UserData 'test' 2>$null
            $script:invalidEnumError = $script:invalidEnumResult | ConvertFrom-Json
        }
        
        It "Should return error response string" {
            $script:invalidEnumResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:invalidEnumError.status | Should -Be 400
        }
        
        It "Should return invalidEnum error type" {
            ($script:invalidEnumError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'invalidEnum|invalidValue'
        }
    }
    
    Context "invalidInteger - sourceId" {
        
        BeforeAll {
            $script:invalidIntegerResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId 'notAnInteger' -UserField $script:testUserField -UserData 'test' 2>$null
            $script:invalidIntegerError = $script:invalidIntegerResult | ConvertFrom-Json
        }
        
        It "Should return error response string" {
            $script:invalidIntegerResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:invalidIntegerError.status | Should -Be 400
        }
        
        It "Should return invalidInteger error type" {
            ($script:invalidIntegerError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'invalidInteger|invalidType'
        }
    }
    
    Context "invalidInteger - sourceId Edge Cases (Data-Driven)" {
        
        It "Should validate sourceId = '<value>' (<description>)" -TestCases @(
            @{ value = 0; description = "zero"; expectedStatus = 400; expectedError = 'missingRequiredField' }
            @{ value = -1; description = "negative one"; expectedStatus = 404; expectedError = 'resourceNotFound|notFound' }
            @{ value = -9; description = "negative arbitrary"; expectedStatus = 404; expectedError = 'resourceNotFound|notFound' }
            @{ value = 'ABC'; description = "string"; expectedStatus = 400; expectedError = 'invalidInteger|invalidType' }
        ) {
            param($value, $description, $expectedStatus, $expectedError)
            
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $value -UserField $script:testUserField -UserData 'test' 2>$null
            
            # Should return error (string response, not object)
            $result | Should -BeOfType [string]
            
            $errorObj = $result | ConvertFrom-Json
            $errorObj.status | Should -Be $expectedStatus
            
            $errorType = ($errorObj.errors[0].type -replace '.*#:~:text=', '')
            # Write-Host "  sourceId=$value → Status: $expectedStatus, Type: $errorType" -ForegroundColor Yellow
            $errorType | Should -Match $expectedError
        }
    }
    
    Context "invalidQueryParameter - `$select" {
        
        BeforeAll {
            $script:invalidSelectResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData 'test' -Select 'invalidField' 2>$null
            $script:invalidSelectError = $script:invalidSelectResult | ConvertFrom-Json
        }
        
        It "Should return error response string" {
            $script:invalidSelectResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:invalidSelectError.status | Should -Be 400
        }
        
        It "Should return invalidQueryParameter error type" {
            ($script:invalidSelectError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'invalidODataQuery|invalidSelect|invalidQueryParameter'
        }
    }
    
    Context "invalidMaxLength - userData" {
        
        BeforeAll {
            $longString = "x" * 81
            $script:invalidMaxLengthResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData $longString 2>$null
            $script:invalidMaxLengthError = $script:invalidMaxLengthResult | ConvertFrom-Json
        }
        
        It "Should return error response string" {
            $script:invalidMaxLengthResult | Should -BeOfType [string]
        }
        
        It "Should return 400 status code" {
            $script:invalidMaxLengthError.status | Should -Be 400
        }
        
        It "Should return invalidMaxLength error type" {
            ($script:invalidMaxLengthError.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'invalidMaxLength|maxLength'
        }
        
        It "Should mention 80 characters in error title" {
            $script:invalidMaxLengthError.errors[0].title | Should -Match '80'
        }
    }
    
    Context "badRequest - Invalid JSON Body" {
        
        It "Should return 400 for invalid JSON body (string instead of object)" {
            # Write-Host "`n[Test: Invalid JSON body - string instead of object]" -ForegroundColor Cyan
            
            # Use direct Invoke-WebRequest to send invalid body and capture full request details
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = '"just a string"'
            $headers = @{ 'Authorization' = "Bearer $env:TRUCKMATE_API_KEY"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                throw "Expected 400 error but request succeeded"
            }
            catch {
                $result = $_.ErrorDetails.Message
                Write-Verbose "Error Response (Status $($_.Exception.Response.StatusCode.Value__)): $result"
                # Write-Host "Error Response:" -ForegroundColor Yellow
                $result | ConvertFrom-Json | Format-List status, title, @{L="errorCode";E={$_.errors[0].code}} | Out-Null
                
                $errorObj = $result | ConvertFrom-Json
                $errorObj.status | Should -Be 400
                ($errorObj.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'invalidJsonObject|invalidBody|invalidJson|badRequest'
            }
        }
        
        It "Should return 400 for malformed JSON" {
            # Write-Host "`n[Test: Malformed JSON]" -ForegroundColor Cyan
            
            # Use direct Invoke-WebRequest to send malformed JSON
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = '{ "userData": "test" '  # Missing closing brace
            $headers = @{ 'Authorization' = "Bearer $env:TRUCKMATE_API_KEY"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                throw "Expected 400 error but request succeeded"
            }
            catch {
                $result = $_.ErrorDetails.Message
                Write-Verbose "Error Response (Status $($_.Exception.Response.StatusCode.Value__)): $result"
                Write-Verbose "Exception Message: $($_.Exception.Message)"
                # Write-Host "Error Response:" -ForegroundColor Yellow
                if ($result) {
                    $result | ConvertFrom-Json | Format-List status, title | Out-Null
                    
                    $errorObj = $result | ConvertFrom-Json
                    $errorObj.status | Should -Be 400
                } else {
                    # Some APIs may reject before sending structured error
                    $_.Exception.Message | Should -Match '400|Bad'
                }
            }
        }
    }
    
    Context "noValidFields - Empty Object {}" {
        
        BeforeAll {
            # Use direct Invoke-WebRequest to send empty object
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = '{}'
            $headers = @{ 'Authorization' = "Bearer $env:TRUCKMATE_API_KEY"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                $script:emptyObjectResult = "Success"
            }
            catch {
                $script:emptyObjectResult = $_.ErrorDetails.Message
                Write-Verbose "Error Response (Status $($_.Exception.Response.StatusCode.Value__)): $script:emptyObjectResult"
            }
        }
        
        It "Should return error response string" {
            $script:emptyObjectResult | Should -BeOfType [string]
            $script:emptyObjectResult | Should -Not -Be "Success"
        }
        
        It "Should return 400 status code" {
            $errorObj = $script:emptyObjectResult | ConvertFrom-Json
            $errorObj.status | Should -Be 400
        }
        
        It "Should return noValidFields error type" {
            $errorObj = $script:emptyObjectResult | ConvertFrom-Json
            $errorType = ($errorObj.errors[0].type -replace '.*#:~:text=', '')
            # Write-Host "  Received error type: $errorType (Expected: noValidFields)" -ForegroundColor Yellow
            $errorType | Should -Be 'noValidFields'
        }
    }
    
    Context "invalidJsonObject - Array Instead of Object" {
        
        BeforeAll {
            # Use direct Invoke-WebRequest to send array instead of object
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = '[{"userData": "test"}]'
            $headers = @{ 'Authorization' = "Bearer $env:TRUCKMATE_API_KEY"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                $script:arrayBodyResult = "Success"
            }
            catch {
                $script:arrayBodyResult = $_.ErrorDetails.Message
                Write-Verbose "Error Response (Status $($_.Exception.Response.StatusCode.Value__)): $script:arrayBodyResult"
            }
        }
        
        It "Should return error response string" {
            $script:arrayBodyResult | Should -BeOfType [string]
            $script:arrayBodyResult | Should -Not -Be "Success"
        }
        
        It "Should return 400 status code" {
            $errorObj = $script:arrayBodyResult | ConvertFrom-Json
            $errorObj.status | Should -Be 400
        }
        
        It "Should return invalidJsonObject error type" {
            $errorObj = $script:arrayBodyResult | ConvertFrom-Json
            $errorType = ($errorObj.errors[0].type -replace '.*#:~:text=', '')
            # Write-Host "  Received error type: $errorType (Expected: invalidJsonObject)" -ForegroundColor Yellow
            $errorType | Should -Be 'invalidJsonObject'
        }
    }
    
    Context "200 Success - userData Empty String" -Skip:(-not $script:hasValidSourceId) {
        
        BeforeAll {
            $script:emptyStringUserDataResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData '' 2>$null
        }
        
        It "Should return success object" {
            $script:emptyStringUserDataResult | Should -BeOfType [PSCustomObject]
        }
        
        It "Should preserve empty string userData" {
            $script:emptyStringUserDataResult.userData | Should -Be ''
        }
    }
    
    Context "200 Success - userData Whitespace (Trimmed)" -Skip:(-not $script:hasValidSourceId) {
        
        BeforeAll {
            $script:whitespaceUserDataResult = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData '   ' 2>$null
        }
        
        It "Should return success object" {
            $script:whitespaceUserDataResult | Should -BeOfType [PSCustomObject]
        }
        
        It "Should trim whitespace to empty string" {
            # API trims whitespace-only to empty string
            $script:whitespaceUserDataResult.userData | Should -Be ''
        }
    }
    
    Context "200 Success - userData Null" -Skip:(-not $script:hasValidSourceId) {
        
        BeforeAll {
            # Use direct Invoke-WebRequest to send null userData
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = '{"userData": null}'
            $headers = @{ 'Authorization' = "Bearer $env:TRUCKMATE_API_KEY"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            
            $script:nullUserDataResponse = Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body
            $script:nullUserDataResult = $script:nullUserDataResponse.Content | ConvertFrom-Json
        }
        
        It "Should return 200 status code" {
            $script:nullUserDataResponse.StatusCode | Should -Be 200
        }
        
        It "Should accept null userData" {
            $script:nullUserDataResult.userFieldsData[0].userData | Should -BeNullOrEmpty
        }
    }
    
    Context "resourceNotFound - sourceId" {
        
        It "Should return 404 when sourceId does not exist" {
            # Write-Host "`n[Test: Non-existent sourceId]" -ForegroundColor Cyan
            
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId 999999999 -UserField $script:testUserField -UserData 'test' 2>$null
            
            # Write-Host "Error Response:" -ForegroundColor Yellow
            if ($result -is [string]) {
                $errorObj = $result | ConvertFrom-Json
                $errorObj | Format-List status, title, @{L="errorCode";E={$_.errors[0].code}} | Out-Null
            }
            
            $result | Should -BeOfType [string]
            $errorObj = $result | ConvertFrom-Json
            $errorObj.status | Should -Be 404
            ($errorObj.errors[0].type -replace '.*#:~:text=', '') | Should -Match 'notFound|resourceNotFound'
        }
    }
    
    Context "401 Unauthorized - Authentication" {
        
        It "Should return 401 when no authentication token is provided" {
            # Write-Host "`n[Test: Missing authentication]" -ForegroundColor Cyan
            
            # Use direct Invoke-WebRequest without token
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = @{ userData = "test" } | ConvertTo-Json
            $headers = @{ 'Content-Type' = 'application/json' }  # No Authorization header
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                throw "Expected 401 error but request succeeded"
            }
            catch {
                Write-Verbose "Status Code: $($_.Exception.Response.StatusCode.Value__)"
                Write-Verbose "Exception Message: $($_.Exception.Message)"
                # Write-Host "Status Code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Yellow
                
                $_.Exception.Response.StatusCode.Value__ | Should -Be 401
            }
        }
        
        It "Should return 401 when invalid authentication token is provided" {
            # Write-Host "`n[Test: Invalid authentication token]" -ForegroundColor Cyan
            
            # Use direct Invoke-WebRequest with invalid token
            $uri = "$env:FINANCE_API_URL/userFieldsData?sourceType=$script:testSourceType&sourceId=$script:testSourceId&userField=$script:testUserField"
            $body = @{ userData = "test" } | ConvertTo-Json
            $headers = @{ 'Authorization' = "Bearer INVALID_TOKEN_12345"; 'Content-Type' = 'application/json' }
            
            Write-Verbose "Request: PUT $uri"
            Write-Verbose "Request Body: $body"
            Write-Verbose "Request Headers: $($headers | ConvertTo-Json -Compress)"
            
            try {
                Invoke-WebRequest -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                throw "Expected 401 error but request succeeded"
            }
            catch {
                Write-Verbose "Status Code: $($_.Exception.Response.StatusCode.Value__)"
                Write-Verbose "Exception Message: $($_.Exception.Message)"
                # Write-Host "Status Code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Yellow
                
                $_.Exception.Response.StatusCode.Value__ | Should -Be 401
            }
        }
    }
    
    Context "200 Success - Valid Requests" -Skip:(-not $script:hasValidSourceId) {
        
        It "Should successfully update userData with valid parameters" {
            # Write-Host "`n[Test: Valid update]" -ForegroundColor Cyan
            
            $testValue = "PesterTest_$(Get-Date -Format 'HHmmss')"
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData $testValue 2>$null
            
            # Write-Host "Success Response:" -ForegroundColor Green
            $result | Format-List sourceType, sourceId, userField, userData | Out-Null
            
            $result | Should -Not -BeOfType [string]
            $result.userData | Should -Be $testValue
            $result.sourceType | Should -Be $script:testSourceType
            $result.sourceId | Should -Be $script:testSourceId
        }
        
        It "Should update with userData at exactly maxLength (80 characters)" {
            # Write-Host "`n[Test: userData at maxLength boundary]" -ForegroundColor Cyan
            
            # Create string exactly 80 characters
            $maxString = "x" * 80
            
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData $maxString 2>$null
            
            # Write-Host "Success Response:" -ForegroundColor Green
            # Write-Host "userData length: $($result.userData.Length)" -ForegroundColor White
            
            $result | Should -Not -BeOfType [string]
            $result.userData | Should -Be $maxString
            $result.userData.Length | Should -Be 80
        }
        
        It "Should update with empty string userData" {
            # Write-Host "`n[Test: Empty string userData]" -ForegroundColor Cyan
            
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData '' 2>$null
            
            # Write-Host "Success Response:" -ForegroundColor Green
            $result | Format-List sourceType, sourceId, userField, userData | Out-Null
            
            $result | Should -Not -BeOfType [string]
            $result.userData | Should -BeNullOrEmpty
        }
        
        It "Should support `$select parameter in successful request" {
            # Write-Host "`n[Test: Valid `$select parameter]" -ForegroundColor Cyan
            
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData 'SelectTest' -Select 'userData,sourceId' 2>$null
            
            # Write-Host "Success Response (with select):" -ForegroundColor Green
            $result | Format-List | Out-Null
            
            $result | Should -Not -BeOfType [string]
            $result.userData | Should -Not -BeNullOrEmpty
            $result.sourceId | Should -Not -BeNullOrEmpty
        }
        
        It "Should work with different userField values (<userField>)" -TestCases @(
            @{ userField = 'USER1' }
            @{ userField = 'USER5' }
            @{ userField = 'USER10' }
            @{ userField = 'USER20' }
        ) {
            param($userField)
            
            $testValue = "FieldTest_$(Get-Date -Format 'HHmmss')"
            $result = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $userField -UserData $testValue 2>$null
            
            $result | Should -Not -BeOfType [string]
            $result.userField | Should -Be $userField
            $result.userData | Should -Be $testValue
        }
    }
    
    Context "Response Contract Validation" -Skip:(-not $script:hasValidSourceId) {
        
        BeforeAll {
            $script:sampleResponse = Set-UserFieldsData -SourceType $script:testSourceType -SourceId $script:testSourceId -UserField $script:testUserField -UserData 'ContractTest' 2>$null
        }
        
        It "Should return response with required properties" {
            # Write-Host "`n[Test: Response structure]" -ForegroundColor Cyan
            # Write-Host "All Properties:" -ForegroundColor Yellow
            $script:sampleResponse.PSObject.Properties.Name | Sort-Object | Out-Null
            
            $script:sampleResponse.PSObject.Properties.Name | Should -Contain "sourceType"
            $script:sampleResponse.PSObject.Properties.Name | Should -Contain "sourceId"
            $script:sampleResponse.PSObject.Properties.Name | Should -Contain "userField"
            $script:sampleResponse.PSObject.Properties.Name | Should -Contain "userData"
        }
        
        It "Should return correct data types" {
            # Write-Host "`n[Test: Response data types]" -ForegroundColor Cyan
            # Write-Host "sourceType type: $($script:sampleResponse.sourceType.GetType().Name)" -ForegroundColor White
            # Write-Host "sourceId type: $($script:sampleResponse.sourceId.GetType().Name)" -ForegroundColor White
            # Write-Host "userField type: $($script:sampleResponse.userField.GetType().Name)" -ForegroundColor White
            # Write-Host "userData type: $($script:sampleResponse.userData.GetType().Name)" -ForegroundColor White
            
            $script:sampleResponse.sourceType | Should -BeOfType [string]
            # sourceId is numeric (can be int32 or int64 depending on JSON deserialization)
            ($script:sampleResponse.sourceId -is [int] -or $script:sampleResponse.sourceId -is [long]) | Should -Be $true
            $script:sampleResponse.userField | Should -BeOfType [string]
            $script:sampleResponse.userData | Should -BeOfType [string]
        }
    }
}



