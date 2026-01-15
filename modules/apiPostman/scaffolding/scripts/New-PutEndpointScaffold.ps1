# New-PutEndpointScaffold.ps1
# Scaffolds folder structure and test requests for a new PUT endpoint in Finance API
# Based on TDD approach - tests created before implementation

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $true)]
    [string]$CollectionUid,
    
    [Parameter(Mandatory = $true)]
    [string]$EndpointName,          # e.g., "apInvoices"
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceIdName,        # e.g., "apInvoiceId"
    
    [Parameter(Mandatory = $false)]
    [string]$ParentFolderId,        # If adding to existing folder
    
    [Parameter(Mandatory = $false)]
    [string[]]$SuccessTests,        # Custom success test names
    
    [Parameter(Mandatory = $false)]
    [string[]]$ErrorTests,          # Custom error test names
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun                 # Preview only, don't create
)

$headers = @{
    "X-API-Key" = $ApiKey
    "Content-Type" = "application/json"
}

# Default success tests if not provided
if (-not $SuccessTests) {
    $SuccessTests = @(
        "minimal fields",
        "Request body based on openAPI",
        "`$select",
        "blank string"
    )
}

# Default error tests if not provided
if (-not $ErrorTests) {
    $ErrorTests = @(
        "random invalidDBValue",
        "409 - Resource Conflict"
    )
}

# Template for minimal PUT request
function New-PutRequestTemplate {
    param(
        [string]$Name,
        [string]$EndpointName,
        [string]$ResourceIdName,
        [string]$Body = $null,
        [string]$PreRequestScript = "",
        [string]$TestScript = "",
        [string]$QueryParams = ""
    )
    
    if (-not $Body) {
        # Use proper line breaks instead of \r\n literals
        $Body = @"
{
    // TODO: Add full OpenAPI schema fields
    "field1": "value1",
    "field2": 123
}
"@
    }
    
    # Build URL with proper query array format
    $baseUrl = "{{DOMAIN}}/$EndpointName/{{$ResourceIdName}}"
    
    $urlObject = @{
        raw = $baseUrl
        host = @("{{DOMAIN}}")
        path = @($EndpointName, "{{$ResourceIdName}}")
    }
    
    # Add query parameters in Postman array format
    if ($QueryParams) {
        $urlObject.raw += "?$QueryParams"
        
        # Parse query params into Postman query array
        $queryArray = @()
        foreach ($param in $QueryParams -split '&') {
            if ($param -match '([^=]+)=(.*)') {
                $queryArray += @{
                    key = $matches[1]
                    value = $matches[2]
                    disabled = $false
                }
            }
        }
        $urlObject.query = $queryArray
    }
    
    return @{
        name = $Name
        event = @(
            @{
                listen = "test"
                script = @{
                    exec = if ($TestScript) { @($TestScript) } else { @("") }
                    type = "text/javascript"
                }
            },
            @{
                listen = "prerequest"
                script = @{
                    exec = if ($PreRequestScript) { @($PreRequestScript) } else { @("") }
                    type = "text/javascript"
                }
            }
        )
        request = @{
            method = "PUT"
            header = @()
            body = @{
                mode = "raw"
                raw = $Body
                options = @{
                    raw = @{
                        language = "json"
                    }
                }
            }
            url = $urlObject
        }
    }
}

# Create folder structure
function New-FolderStructure {
    param(
        [string]$CollectionUid,
        [string]$ParentFolderId
    )
    
    Write-Host "Creating folder structure..." -ForegroundColor Cyan
    Write-Host ""
    
    $folders = @()
    
    # Level 1: {resourceId} folder
    $resourceIdFolder = @{
        name = $ResourceIdName
        description = "Tests for $EndpointName by ID"
    }
    
    # Level 2: PUT folder
    $putFolder = @{
        name = "PUT"
        description = "PUT (Update) endpoint tests"
    }
    
    # Level 3: 200 folder
    $put200Folder = @{
        name = "200"
        description = "Successful update tests"
    }
    
    # Level 3: 4xx folder
    $put4xxFolder = @{
        name = "4xx"
        description = "Error response tests"
    }
    
    # Level 4: invalidBusinessLogic folder
    $invalidBizLogicFolder = @{
        name = "invalidBusinessLogic"
        description = "Business rule validation tests"
    }
    
    return @{
        ResourceIdFolder = $resourceIdFolder
        PutFolder = $putFolder
        Put200Folder = $put200Folder
        Put4xxFolder = $put4xxFolder
        InvalidBizLogicFolder = $invalidBizLogicFolder
    }
}

# Generate success test requests
function New-SuccessTests {
    param(
        [string[]]$TestNames,
        [string]$EndpointName,
        [string]$ResourceIdName
    )
    
    $requests = @()
    
    foreach ($testName in $TestNames) {
        switch ($testName) {
            "minimal fields" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "value1" }' `
                    -PreRequestScript "// TODO: Set up test data`n// pm.globals.set('$ResourceIdName', 123);"
            }
            "Request body based on openAPI" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "value1", "field2": 123 }'
            }
            "`$select" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "value1" }' `
                    -QueryParams "`$select=field1,field2"
            }
            "blank string" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "stringField": "", "otherField": "valid value" }'
            }
            default {
                # Custom test - create basic template
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "value1" }'
            }
        }
    }
    
    return $requests
}

# Generate error test requests
function New-ErrorTests {
    param(
        [string[]]$TestNames,
        [string]$EndpointName,
        [string]$ResourceIdName
    )
    
    $requests = @()
    
    foreach ($testName in $TestNames) {
        switch ($testName) {
            "random invalidDBValue" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "invalidField": 999999 }' `
                    -TestScript "tm_utils.testInvalidDbValueResponse();"
            }
            "409 - Resource Conflict" {
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "duplicate value" }' `
                    -TestScript "pm.test(`"Status is 409`", () => pm.response.to.have.status(409));"
            }
            default {
                # Custom error test - create basic template with tm_utils
                $testScriptTemplate = "tm_utils.testInvalidBusinessLogicResponse(`"Expected error message for $testName`");"
                $requests += New-PutRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ResourceIdName $ResourceIdName `
                    -Body '{ "field1": "invalid value" }' `
                    -TestScript $testScriptTemplate
            }
        }
    }
    
    return $requests
}

# Main execution
Write-Host "PUT Endpoint Scaffolding Tool" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Endpoint: $EndpointName" -ForegroundColor Yellow
Write-Host "Resource ID: $ResourceIdName" -ForegroundColor Yellow
Write-Host "Collection: $CollectionUid" -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    Write-Host ""
}

# Generate structure
$structure = New-FolderStructure -CollectionUid $CollectionUid -ParentFolderId $ParentFolderId
$successRequests = New-SuccessTests -TestNames $SuccessTests -EndpointName $EndpointName -ResourceIdName $ResourceIdName
$errorRequests = New-ErrorTests -TestNames $ErrorTests -EndpointName $EndpointName -ResourceIdName $ResourceIdName

# Output summary
Write-Host "Folder Structure:" -ForegroundColor Cyan
Write-Host "  📁 $ResourceIdName" -ForegroundColor White
Write-Host "    📁 PUT" -ForegroundColor White
Write-Host "      📁 200" -ForegroundColor Green
foreach ($req in $successRequests) {
    Write-Host "        • $($req.name)" -ForegroundColor Gray
}
Write-Host "      📁 4xx" -ForegroundColor Red
Write-Host "        📁 invalidBusinessLogic" -ForegroundColor Red
foreach ($req in $errorRequests) {
    Write-Host "          • $($req.name)" -ForegroundColor Gray
}
Write-Host ""

# Save scaffold to JSON file for review/import
$scaffoldOutput = @{
    info = @{
        name = "PUT $EndpointName Scaffold"
        description = "Generated scaffold for PUT $EndpointName/$ResourceIdName endpoint"
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    item = @(
        @{
            name = $ResourceIdName
            item = @(
                @{
                    name = "PUT"
                    item = @(
                        @{
                            name = "200"
                            description = "Successful update tests"
                            event = @(
                                @{
                                    listen = "test"
                                    script = @{
                                        exec = @(
                                            "if (utils.testStatusCode(200).status) {",
                                            "    utils.validateJsonSchemaIfCode(200);",
                                            "    ",
                                            "    if(pm.request.url.query.get('`$select')){",
                                            "        utils.validateSelectParameter(null);",
                                            "    }else{",
                                            "        let responseJson = pm.response.json();",
                                            "        let jsonRequest = JSON.parse(pm.request.body.raw);",
                                            "        jsonRequest.$ResourceIdName = parseInt(pm.request.url.path.at(-1));",
                                            "        ",
                                            "        // TODO: Add any endpoint-specific business logic here",
                                            "        ",
                                            "        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);",
                                            "    }",
                                            "}"
                                        )
                                        type = "text/javascript"
                                    }
                                }
                            )
                            item = $successRequests
                        },
                        @{
                            name = "4xx"
                            description = "Error response tests"
                            item = @(
                                @{
                                    name = "invalidBusinessLogic"
                                    description = "Business rule validation tests"
                                    item = $errorRequests
                                }
                            )
                        }
                    )
                }
            )
        }
    )
}

$outputFile = "postmanAPI\PUT-$EndpointName-Scaffold.json"
$scaffoldOutput | ConvertTo-Json -Depth 20 | Out-File $outputFile -Encoding UTF8

Write-Host "✓ Scaffold saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated JSON file" -ForegroundColor White
Write-Host "2. Import into Postman collection manually, or" -ForegroundColor White
Write-Host "3. Use Postman API to programmatically add folders/requests" -ForegroundColor White
Write-Host "4. Customize TODO placeholders in request bodies and scripts" -ForegroundColor White
Write-Host "5. Set up required variables (e.g., $ResourceIdName, DOMAIN)" -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    Write-Host "To add these to your collection via API, use:" -ForegroundColor Yellow
    Write-Host "  (Implementation of direct API calls would go here)" -ForegroundColor Gray
}

