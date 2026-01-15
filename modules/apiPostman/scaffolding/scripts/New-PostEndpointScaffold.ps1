# New-PostEndpointScaffold.ps1
# Scaffolds folder structure and test requests for a new POST endpoint in Finance API
# Based on Finance collection patterns from POST-Endpoint-Template-Analysis.md

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory = $true)]
    [string]$CollectionUid,
    
    [Parameter(Mandatory = $true)]
    [string]$EndpointName,          # e.g., "tripFuelPurchases"
    
    [Parameter(Mandatory = $false)]
    [string]$ParentResourceName,    # e.g., "fuelTaxes" for sub-resources
    
    [Parameter(Mandatory = $false)]
    [string]$ParentResourceId,      # e.g., "fuelTaxId" for sub-resources
    
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
        "minimum fields",
        "all fields",
        "array",
        "`$select"
    )
}

# Default error tests if not provided
if (-not $ErrorTests) {
    $ErrorTests = @(
        "random invalidDBValue",
        "empty array"
    )
}

# Template for POST request
function New-PostRequestTemplate {
    param(
        [string]$Name,
        [string]$EndpointName,
        [string]$ParentResourceName,
        [string]$ParentResourceId,
        [string]$Body = $null,
        [string]$PreRequestScript = "",
        [string]$TestScript = "",
        [string]$QueryParams = ""
    )
    
    if (-not $Body) {
        # Default array body for POST
        $Body = '[{ "field1": "value1", "field2": 123 }]'
    }
    
    # Build URL object with proper query array format
    if ($ParentResourceName) {
        $baseUrl = "{{DOMAIN}}/$ParentResourceName/{{$ParentResourceId}}/$EndpointName"
        $pathArray = @($ParentResourceName, "{{$ParentResourceId}}", $EndpointName)
    } else {
        $baseUrl = "{{DOMAIN}}/$EndpointName"
        $pathArray = @($EndpointName)
    }
    
    $urlObject = @{
        raw = $baseUrl
        host = @("{{DOMAIN}}")
        path = $pathArray
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
            method = "POST"
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

# Generate success test requests
function New-PostSuccessTests {
    param(
        [string[]]$TestNames,
        [string]$EndpointName,
        [string]$ParentResourceName,
        [string]$ParentResourceId
    )
    
    $requests = @()
    
    foreach ($testName in $TestNames) {
        switch ($testName) {
            "minimum fields" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Build minimal request body",
                        "const requestBody = [{",
                        "    // TODO: Add minimum required fields from OpenAPI schema",
                        "    field1: 'value1'",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                } else {
                    @(
                        "// Build minimal request body",
                        "const requestBody = [{",
                        "    // TODO: Add minimum required fields from OpenAPI schema",
                        "    field1: 'value1'",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -PreRequestScript $preScript
            }
            "all fields" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Build comprehensive request body",
                        "const requestBody = [{",
                        "    // TODO: Add all fields from OpenAPI schema",
                        "    field1: 'value1',",
                        "    field2: 123,",
                        "    field3: '2025-10-10T10:00:00'",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                } else {
                    @(
                        "// Build comprehensive request body",
                        "const requestBody = [{",
                        "    // TODO: Add all fields from OpenAPI schema",
                        "    field1: 'value1',",
                        "    field2: 123,",
                        "    field3: '2025-10-10T10:00:00'",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -PreRequestScript $preScript
            }
            "array" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Build array with multiple items",
                        "const requestBody = [",
                        "    { field1: 'item1' },",
                        "    { field1: 'item2' },",
                        "    { field1: 'item3' }",
                        "];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                } else {
                    @(
                        "// Build array with multiple items",
                        "const requestBody = [",
                        "    { field1: 'item1' },",
                        "    { field1: 'item2' },",
                        "    { field1: 'item3' }",
                        "];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -PreRequestScript $preScript
            }
            "`$select" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Build request body",
                        "const requestBody = [{",
                        "    field1: 'value1',",
                        "    field2: 123",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                } else {
                    @(
                        "// Build request body",
                        "const requestBody = [{",
                        "    field1: 'value1',",
                        "    field2: 123",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -QueryParams "`$select=field1,field2" `
                    -PreRequestScript $preScript
            }
            default {
                # Custom test - create basic template
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body '[{ "field1": "value1" }]'
            }
        }
    }
    
    return $requests
}

# Generate error test requests  
function New-PostErrorTests {
    param(
        [string[]]$TestNames,
        [string]$EndpointName,
        [string]$ParentResourceName,
        [string]$ParentResourceId
    )
    
    $requests = @()
    
    foreach ($testName in $TestNames) {
        switch ($testName) {
            "random invalidDBValue" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Build request with invalid data",
                        "const requestBody = [{",
                        "    invalidField: 999999",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                } else {
                    @(
                        "// Build request with invalid data",
                        "const requestBody = [{",
                        "    invalidField: 999999",
                        "}];",
                        "",
                        "pm.request.body.raw = JSON.stringify(requestBody);"
                    ) -join "`n"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -PreRequestScript $preScript `
                    -TestScript "tm_utils.testInvalidDbValueResponse();"
            }
            "empty array" {
                $preScript = if ($ParentResourceId) {
                    @(
                        "// Set parent resource ID",
                        "const $ParentResourceId = pm.globals.get('$ParentResourceId') || 2;",
                        "pm.variables.set('$ParentResourceId', $ParentResourceId);",
                        "",
                        "// Empty array should fail",
                        "pm.request.body.raw = JSON.stringify([]);"
                    ) -join "`n"
                } else {
                    "// Empty array should fail`npm.request.body.raw = JSON.stringify([]);"
                }
                
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body "" `
                    -PreRequestScript $preScript
            }
            default {
                # Custom error test
                $testScriptTemplate = "tm_utils.testInvalidBusinessLogicResponse(`"Expected error message for $testName`");"
                $requests += New-PostRequestTemplate `
                    -Name $testName `
                    -EndpointName $EndpointName `
                    -ParentResourceName $ParentResourceName `
                    -ParentResourceId $ParentResourceId `
                    -Body '[{ "field1": "invalid value" }]' `
                    -TestScript $testScriptTemplate
            }
        }
    }
    
    return $requests
}

# Main execution
Write-Host ""
Write-Host "POST Endpoint Scaffolding Tool" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Endpoint: $EndpointName" -ForegroundColor White
if ($ParentResourceName) {
    Write-Host "Parent Resource: $ParentResourceName" -ForegroundColor White
    Write-Host "Parent ID: $ParentResourceId" -ForegroundColor White
}
Write-Host "Collection: $CollectionUid" -ForegroundColor White
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    Write-Host ""
}

# Generate requests
$successRequests = New-PostSuccessTests -TestNames $SuccessTests -EndpointName $EndpointName -ParentResourceName $ParentResourceName -ParentResourceId $ParentResourceId
$errorRequests = New-PostErrorTests -TestNames $ErrorTests -EndpointName $EndpointName -ParentResourceName $ParentResourceName -ParentResourceId $ParentResourceId

# Output summary
Write-Host "Creating folder structure..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Folder Structure:" -ForegroundColor Cyan
Write-Host "  📁 POST" -ForegroundColor White
Write-Host "    📁 201" -ForegroundColor Green
foreach ($req in $successRequests) {
    Write-Host "      • $($req.name)" -ForegroundColor Gray
}
Write-Host "    📁 4xx" -ForegroundColor Red
Write-Host "      📁 invalidBusinessLogic" -ForegroundColor Red
foreach ($req in $errorRequests) {
    Write-Host "        • $($req.name)" -ForegroundColor Gray
}
Write-Host ""

# Save scaffold to JSON file for review/import
$scaffoldOutput = @{
    info = @{
        name = "POST $EndpointName Scaffold"
        description = "Generated scaffold for POST $EndpointName endpoint"
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    item = @(
        @{
            name = "POST"
            item = @(
                @{
                    name = "201"
                    description = "Successful creation tests"
                    event = @(
                        @{
                            listen = "test"
                            script = @{
                                exec = @(
                                    "if (utils.testStatusCode(201).status) {",
                                    "    utils.validateJsonSchemaIfCode(201);",
                                    "    ",
                                    "    if(pm.request.url.query.get('`$select')){",
                                    "        utils.validateSelectParameter('$EndpointName');",
                                    "    }else{",
                                    "        let responseJson = pm.response.json();",
                                    "        let jsonRequest = JSON.parse(pm.request.body.raw);",
                                    "        ",
                                    "        // Validate array response",
                                    "        if (responseJson.$EndpointName && responseJson.$($EndpointName).length > 0) {",
                                    "            utils.validateFieldValuesIfCode(201, ",
                                    "                responseJson.$($EndpointName)[0], ",
                                    "                jsonRequest[0]);",
                                    "        }",
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

$outputFile = "postmanAPI\POST-$EndpointName-Scaffold.json"
$scaffoldOutput | ConvertTo-Json -Depth 20 | Out-File $outputFile -Encoding UTF8

Write-Host "✓ Scaffold saved to: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated JSON file" -ForegroundColor White
Write-Host "2. Customize TODO placeholders in pre-request scripts" -ForegroundColor White
Write-Host "3. Import structure to collection" -ForegroundColor White
Write-Host "4. Set up required variables (e.g., $ParentResourceId, DOMAIN)" -ForegroundColor White
Write-Host ""

if (-not $DryRun) {
    Write-Host "To add these to your collection via API, use:" -ForegroundColor Yellow
    Write-Host "  (Load scaffold JSON and append to collection.item)" -ForegroundColor Gray
}

