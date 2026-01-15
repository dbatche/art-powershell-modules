# PowerShell Test Definitions (v2 Format)
# Exported from Postman collection: Finance API - FuelTaxes Automated Tests - import, will be deleted after
# Date: 2025-10-11 12:32:08
# Folder: POST

@(
    @{
        Name = 'minimum fields'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Build minimal request body
const requestBody = [{
    // TODO: Add minimum required fields from OpenAPI schema
    field1: 'value1'
}];

pm.request.body.raw = JSON.stringify(requestBody);
'@
        }
    },
    @{
        Name = 'all fields'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Build comprehensive request body
const requestBody = [{
    // TODO: Add all fields from OpenAPI schema
    field1: 'value1',
    field2: 123,
    field3: '2025-10-10T10:00:00'
}];

pm.request.body.raw = JSON.stringify(requestBody);
'@
        }
    },
    @{
        Name = 'array'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Build array with multiple items
const requestBody = [
    { field1: 'item1' },
    { field1: 'item2' },
    { field1: 'item3' }
];

pm.request.body.raw = JSON.stringify(requestBody);
'@
        }
    },
    @{
        Name = '$select'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        QueryParams = @{ '$select' = 'field1,field2' }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Build request body
const requestBody = [{
    field1: 'value1',
    field2: 123
}];

pm.request.body.raw = JSON.stringify(requestBody);
'@
        }
    },
    @{
        Name = 'random invalidDBValue'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Build request with invalid data
const requestBody = [{
    invalidField: 999999
}];

pm.request.body.raw = JSON.stringify(requestBody);
'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidDbValue')
            RawScript = @'
tm_utils.testInvalidDbValueResponse();
'@
        }
    },
    @{
        Name = 'empty array'
        Method = 'POST'
        Url = '{{DOMAIN}}/fuelTaxes/{{fuelTaxId}}/tripFuelPurchases'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ fuelTaxId = $null }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// Set parent resource ID
const fuelTaxId = pm.globals.get('fuelTaxId') || 2;
pm.variables.set('fuelTaxId', fuelTaxId);

// Empty array should fail
pm.request.body.raw = JSON.stringify([]);
'@
        }
    }
)
