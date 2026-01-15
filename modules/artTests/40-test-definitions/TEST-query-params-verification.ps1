# PowerShell Test Definitions (v2 Format)
# Updated: 2025-10-11 19:48:04

@(
    @{
        Name = 'minimal fields'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1"}'
        Variables = @{ tripFuelPurchaseId = 42; fuelTaxId = 2 }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
// TODO: Set up test data
// pm.globals.set('tripFuelPurchaseId', 123);
'@
        }
    },
    @{
        Name = 'Request body based on openAPI'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1","field2":123}'
        Variables = @{ tripFuelPurchaseId = ''; fuelTaxId = 2 }
    },
    @{
        Name = '$select'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"field1":"value1"}'
        Variables = @{ tripFuelPurchaseId = ''; fuelTaxId = 2 }
        QueryParams = @{ '$select' = 'fuelVolume1,fuelCost1,purchaseDate' }
    },
    @{
        Name = 'blank string'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"stringField":"","otherField":"valid value"}'
        Variables = @{ tripFuelPurchaseId = ''; fuelTaxId = 2 }
    },
    @{
        Name = 'random invalidDBValue'
        Method = 'PUT'
        Url = '{{DOMAIN}}/tripFuelPurchases/{{tripFuelPurchaseId}}'
        ExpectedStatus = 200
        Body = '{"invalidField":999999}'
        Variables = @{ tripFuelPurchaseId = ''; fuelTaxId = 2 }
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
        Body = '{"field1":"duplicate value"}'
        Variables = @{ tripFuelPurchaseId = ''; fuelTaxId = 2 }
        TestScript = @{
            Type = 'Inline'
            RawScript = @'
pm.test("Status is 409", () => pm.response.to.have.status(409));
'@
        }
    }
)
