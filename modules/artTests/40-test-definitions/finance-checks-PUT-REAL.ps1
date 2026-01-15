# PowerShell Test Definitions (v2 Format)
# Exported from Postman collection: Finance Functional Tests
# Date: 2025-10-11 14:07:39
# Folder: checks/checkId/PUT

@(
    @{
        Name = 'minimum fields'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId00}}'
        ExpectedStatus = 200
        Body = '{"checkReference":"{{$randomProduct}}"}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId00 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payFromVendor": "VENDOR",
        "payTo" : "VENDOR",
        "glAccount": "00-1000"
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId00', jsonData.checks[0].checkId);
    });
'@
        }
        TestScript = ''
    },
    @{
        Name = 'only checkNumber and checkReference is allowed when checkType is PAYSTMT.EXE'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{PAYSTMT_CHECK1}}'
        ExpectedStatus = 200
        Body = '{"checkNumber":"{{$randomAlphaNumeric}}","checkReference":"{{$randomProduct}}"}'  # TODO: Convert to hashtable
        Variables = @{ PAYSTMT_CHECK1 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
//get posted PAYSTMT_CHECK
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?limit=1&offset=0&$filter=checkType eq PAYSTMT.EXE&$orderBy=checkId desc", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
            if (err) {
                console.error('error:\n', err, 'Response: \n', response.text());
                throw new Error("An error has occurred. Check logs.");
            }
            const jsonData = response.json();
            pm.variables.set('PAYSTMT_CHECK1', jsonData.checks[0].checkId);
        
    });

'@
        }
        TestScript = ''
    },
    @{
        Name = 'bills update adds new bill when checkBillId is not available'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId06}}'
        ExpectedStatus = 200
        Body = '"{\r\n    \"bills\": [\r\n        {\r\n            \"accountsPayableId\": {{ACCOUNTS_PAYABLE_ID2}}\r\n        }\r\n    ]\r\n}"'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId06 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?$filter=payType eq vendor", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId06', jsonData.checks[0].checkId);
    });
'@
        }
        TestScript = @{
            Type = 'Inline'
            RawScript = @'
let responseJson = pm.response.json();
pm.test("Check accountsPayableId at index 1 equals ACCOUNTS_PAYABLE_ID2", () => {
    pm.expect(responseJson.bills[1].accountsPayableId).to.eql(parseInt(pm.variables.get('ACCOUNTS_PAYABLE_ID2')));
}); //Local test for the skipped test from utils


if (pm.response.code == 200){
    let responseJson = pm.response.json();
    _.each(responseJson.bills, (record) => {
        if (record.accountsPayableId == pm.variables.get('ACCOUNTS_PAYABLE_ID2')){
            utils.deleteCheckBillId(pm, pm.variables.get('temp_checkId06'),record.checkBillId);
        }
    })
}
'@
        }
    },
    @{
        Name = 'blank string'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId00}}'
        ExpectedStatus = 200
        Body = '{"checkReference":"{{$randomProduct}}","user1":""}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId00 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payFromVendor": "VENDOR",
        "payTo" : "VENDOR",
        "glAccount": "00-1000",
        "user1": "TEST"
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId00', jsonData.checks[0].checkId);
    });
'@
        }
        TestScript = ''
    },
    @{
        Name = 'Request body based on openAPI'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId01}}'
        ExpectedStatus = 200
        Body = '"{{tempChecksRequestBody}}"'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId01 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payFromVendor": "VENDOR",
        "payTo" : "VENDOR",
        "glAccount": "00-1000"
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId01', jsonData.checks[0].checkId);
    });


let tempReqBody = utils.getExampleRequestBody({'useServerDefaultValues':true, 'maxItems': 1});
pay_type = lodash.sample(['driver','vendor','client', 'payroll']);
tempReqBody.payType = pay_type;
tempReqBody.checkDate = pm.variables.get('CurrentDate') + "T00:00:00";

if (tempReqBody.payFrom == 'bank'){
    tempReqBody.glAccount = '00-1000';
    delete tempReqBody.payFromVendor;
}

if (tempReqBody.payFrom == 'vendor'){
    tempReqBody.glAccount = '00-2200';
    tempReqBody.payFromVendor = 'CBSA';
}

if (pay_type =='vendor'){
    tempReqBody.payTo = 'VENDOR';
    tempReqBody.bills[0].accountsPayableId = parseInt(pm.variables.get('ACCOUNTS_PAYABLE_ID2'));
    tempReqBody.bills[0].billDiscountGlAccount = '00-1100';
}

//client, vendor, driver or payroll pay type:
else{
    delete tempReqBody.bills;
    
    if (pay_type =='driver'){
        tempReqBody.payTo = pm.variables.get('PAY_DRIVER_ID');
    }

    if (pay_type =='client'){
        tempReqBody.payTo = 'TM';
    }

    if (pay_type =='payroll'){
        tempReqBody.payTo = pm.variables.get('DRIVER_PAY_EMP_CODE');
    }

}

pm.variables.set("tempChecksRequestBody", JSON.stringify(tempReqBody));
'@
        }
        TestScript = @{
            Type = 'Inline'
            RawScript = @'
if (pm.response.code == 200){
    utils.deleteCheckId(pm, pm.variables.get('temp_checkId01'));
}
'@
        }
    },
    @{
        Name = '$select'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId02}}'
        ExpectedStatus = 200
        Body = '{"checkReference":"{{$randomProduct}}"}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId02 = '' }
        QueryParams = @{ '$select' = '{{temp_randomProperties}}' }
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payFromVendor": "VENDOR",
        "payTo" : "VENDOR",
        "glAccount": "00-1000"
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId02', jsonData.checks[0].checkId);
    });

randomProperties = utils.getRandomProperties('check');
pm.collectionVariables.set("temp_randomProperties", randomProperties);
'@
        }
        TestScript = ''
    },
    @{
        Name = 'payTo'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkIdPUT00}}'
        ExpectedStatus = 200
        Body = '{"payType":"{{temp_randomPayType}}","payFrom":"bank","glAccount":"00-1000","payTo":"{{temp_payTo}}"}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkIdPUT00 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
pay_type = lodash.sample(['driver','vendor','client', 'payroll']);
pm.variables.set('temp_randomPayType', pay_type);

if (pay_type == 'payroll'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('TERMINATED_EMPLOYEE_CODE')]));
}

if (pay_type == 'vendor'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('inactiveVendorId')]));
}

if (pay_type == 'driver'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('inactiveDriverId')]));
}

if (pay_type == 'client'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('inactiveClientId')]));
}


let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payTo" : "VENDOR",
        "glAccount": "00-1000"
        /*"bills": [
            {
                "accountsPayableId": parseInt(pm.variables.get('ACCOUNTS_PAYABLE_ID2'))
            }
        ]*/
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkIdPUT00', jsonData.checks[0].checkId);
        //pm.variables.set('temp_checkBillIdPUT00', jsonData.checks[0].bills[0].checkBillId);
    });
'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'
let requestPayType = pm.variables.get('temp_randomPayType');
let returnedError = 'default';
let jsonRequest = JSON.parse(pm.request.body.raw);
let payToRequestValue = jsonRequest.payTo;

if (requestPayType == 'payroll'){
    returnedError = "payTo " + payToRequestValue + " must be a valid TruckMate Employee Code and in an active status";
}
if (requestPayType == 'vendor'){
    returnedError = "payTo " + payToRequestValue + " must be a valid TruckMate Vendor ID and in active status and not on payment hold";
}

if (requestPayType == 'driver'){
    returnedError = "payTo " + payToRequestValue + " must be a valid TruckMate Driver ID and have a valid driver pay contract";
}

if (requestPayType == 'client'){
    returnedError = "payTo " + payToRequestValue + " must be a valid TruckMate Client ID and in an active status";
}

tm_utils.testInvalidBusinessLogicResponse(returnedError);
//Can't create a bill and change the payTo, will get another error "Invoices have been entered, you can't change Pay To info." check the below test.
/*
//Ensure bill record was not deleted:
pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks/" + pm.variables.get('temp_checkIdPUT00') + "/bills/" + pm.variables.get('temp_checkBillIdPUT00'), 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        else {
            pm.test("bills record on the check has not been deleted in error", function() {
                pm.expect(response.code).to.equal(200);
            })
        }
    });*/
'@
        }
    },
    @{
        Name = 'invoices entered can''t change payTo'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkIdPUT00}}'
        ExpectedStatus = 200
        Body = '{"payType":"{{temp_randomPayType}}","payFrom":"bank","glAccount":"00-1000","payTo":"{{temp_payTo}}"}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkIdPUT00 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
pay_type = lodash.sample(['driver','vendor','client', 'payroll']);
pm.variables.set('temp_randomPayType', pay_type);

if (pay_type == 'payroll'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('TERMINATED_EMPLOYEE_CODE')]));
}

if (pay_type == 'vendor'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('inactiveVendorId')]));
}

if (pay_type == 'driver'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', "DRIVER_"]));
}

if (pay_type == 'client'){
    pm.variables.set('temp_payTo', lodash.sample(['garbage', pm.variables.get('inactiveClientId')]));
}


let postChecksBody =
    {
        "payType": "vendor",
        "payFrom": "bank",
        "payTo" : "VENDOR",
        "glAccount": "00-1000",
        "bills": [
            {
                "accountsPayableId": parseInt(pm.variables.get('ACCOUNTS_PAYABLE_ID2'))
            }
        ]
    }

pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks", 
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        },
        body: {
            mode: 'application/json',
            raw: [postChecksBody]
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkIdPUT00', jsonData.checks[0].checkId);
        pm.variables.set('temp_checkBillIdPUT00', jsonData.checks[0].bills[0].checkBillId);
    });
'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'

tm_utils.testInvalidBusinessLogicResponse("Invoices have been entered, you can't change Pay To info.");
pm.sendRequest({
    url: pm.environment.get("DOMAIN") + "/checks/" + pm.variables.get('temp_checkIdPUT00') + "/bills/" + pm.variables.get('temp_checkBillIdPUT00'), 
    method: 'GET',
    header: {
        'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
    }
}, function (err, response) {
    if (err) {
        console.error('Network error during bill verification:\n', err);
        throw new Error("A network error has occurred during verification. Check logs.");
    }
    pm.test("bills record on the check has not been deleted in error", function() {
        pm.expect(response.code).to.equal(200);
    });
    utils.deleteCheckId(pm, pm.variables.get('temp_checkIdPUT00')); 
});
'@
        }
    },
    @{
        Name = 'bills can only be created for vendor pay type'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId05}}'
        ExpectedStatus = 200
        Body = '"{\r\n    \"bills\": [\r\n        {\r\n            \"accountsPayableId\": {{ACCOUNTS_PAYABLE_ID}}\r\n        }\r\n    ]\r\n}"'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId05 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?$filter=payType eq client", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId05', jsonData.checks[0].checkId);
    });
'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'
tm_utils.testInvalidBusinessLogicResponse("bills can only be created for vendor pay type");
'@
        }
    },
    @{
        Name = 'check is posted - no changes allowed'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{postedCheckId}}'
        ExpectedStatus = 200
        Body = '{"checkReference":"{{$randomProduct}}"}'  # TODO: Convert to hashtable
        Variables = @{ postedCheckId = '' }
        QueryParams = @{}
        PreRequestScript = ''
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'
tm_utils.testInvalidBusinessLogicResponse("Check is posted - no changes allowed");
'@
        }
    },
    @{
        Name = 'checkAmount update is not allowed  when checkType is PAYSTMT.EXE'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{PAYSTMT_CHECK1}}'
        ExpectedStatus = 200
        Body = '"{\r\n     \"checkAmount\": {{$randomInt}}\r\n}"'  # TODO: Convert to hashtable
        Variables = @{ PAYSTMT_CHECK1 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
//get PAYSTMT_CHECK
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?limit=1&offset=0&$filter=checkType eq PAYSTMT.EXE&$orderBy=checkId desc", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
            if (err) {
                console.error('error:\n', err, 'Response: \n', response.text());
                throw new Error("An error has occurred. Check logs.");
            }
            const jsonData = response.json();
            pm.variables.set('PAYSTMT_CHECK1', jsonData.checks[0].checkId);
        
    });

'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'
let jsonRequest = JSON.parse(pm.request.body.raw);
tm_utils.testInvalidBusinessLogicResponse("Properties [checkAmount] are Readonly for this Cheque.");
'@
        }
    },
    @{
        Name = 'invalid accountsPayableId'
        Method = 'PUT'
        Url = '{{DOMAIN}}/checks/{{temp_checkId06}}'
        ExpectedStatus = 200
        Body = '{"bills":[{"accountsPayableId":-999}]}'  # TODO: Convert to hashtable
        Variables = @{ temp_checkId06 = '' }
        QueryParams = @{}
        PreRequestScript = @{
            Type = 'Inline'
            Content = @'
pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?$filter=payType eq vendor", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        const jsonData = response.json();
        pm.variables.set('temp_checkId06', jsonData.checks[0].checkId);
    });
'@
        }
        TestScript = @{
            Type = 'Utils'
            Utils = @('testInvalidBusinessLogic')
            RawScript = @'
let jsonRequest = JSON.parse(pm.request.body.raw);
tm_utils.testInvalidBusinessLogicResponse("accountsPayableId " + jsonRequest.bills[0].accountsPayableId + " must be a valid TruckMate Accounts Payable ID and assigned to the related payTo vendor");
'@
        }
    }
)
