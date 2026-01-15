# PowerShell Test Definitions (v2 Format)
# Exported from Postman collection: Finance API - FuelTaxes Automated Tests - import, will be deleted after
# Date: 2025-10-11 13:57:38
# Folder: tripFuelPurchaseId/PUT

@(
    @{
        Name = 'minimal fields'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1"}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// TODO: Set up test data
// pm.globals.set('tripFuelPurchaseId', 123);
'@
        }
        TestScript = ''
    },
    @{
        Name = 'Request body based on openAPI'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = ''
    },
    @{
        Name = '$select'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1"}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = ''
    },
    @{
        Name = 'blank string'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"stringField":"","otherField":"valid value"}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = ''
    },
    @{
        Name = 'random invalidDBValue'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"invalidField":999999}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidDbValue')
            RawScript = @'
tm_utils.testInvalidDbValueResponse();
'@
        }
    },
    @{
        Name = '409 - Resource Conflict'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 409
        Body = '{"field1":"duplicate value"}'  # TODO: Convert to hashtable
        Variables = @{ tripFuelPurchaseId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = @{
            Type = 'Inline'
            RawScript = @'
pm.test("Status is 409", () => pm.response.to.have.status(409));
'@
        }
    }
)
