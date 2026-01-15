//---------------------------------------
// Request body based on OpenApi 
//---------------------------------------

// Initial Request body based on OpenApi 
let tempReqBody = utils.getExampleRequestBody({'useServerDefaultValues':true, 'maxItems': 1});
// Adjustments
// tempReqBody[0].vendorBillDate = `${{$randomDateFuture}}`
// Stringify 
pm.variables.set("tempReqBody", JSON.stringify(tempReqBody));
// body
{{tempReqBody}}

//---------------------------------------
// $select test - Response(!) properties 
//---------------------------------------

//url:
	'?$select={{temp_randomProperties}}'
// pre-request
	randomProperties = utils.getRandomProperties('apInvoice');
	pm.variables.set("temp_randomProperties", randomProperties);
// post-request (usually at 200 level)
	if(pm.request.url.query.get('$select')){
		utils.validateSelectParameter('apInvoices'); 
	}

//---------------------------------------
// Safe property access with "?"
//---------------------------------------

// Safe property access with "?"
const jsonData = response.json();
const payableId = jsonData?.apInvoices?.[0]?.apInvoiceId ?? null;
pm.variables.set('apInvoiceId1', payableId);

//---------------------------------------
// Folder level Post-response script - for a POST, ie. 'collection' type (plural 'array' propeties)
//---------------------------------------

if (utils.testStatusCode(201).status) {
	    utils.validateJsonSchema();

	    if(pm.request.url.query.get('$select')){
	        utils.validateSelectParameter('apInvoices');
	    }
	    else{
			// Request 
		 	let jsonRequest = JSON.parse(pm.request.body.raw);
		
		    // Response 
		    let responseJson = pm.response.json();
	
	        if (responseJson.apInvoices && responseJson.apInvoices.length > 0) {
	            utils.validateFieldValuesIfCode(201, responseJson.apInvoices[0], jsonRequest[0]);
	        } else {
	            console.warn("The 'checks' array is empty or missing from the response.");
	        }
	    }
};

//---------------------------------------
// Folder level Post-response script - for a PUT, ie. 'object' type 
//---------------------------------------

if (utils.testStatusCode(200).status) {
    utils.validateJsonSchema();

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);

    }else{
        
        // Request + Adjustments
        let jsonRequest = JSON.parse(pm.request.body.raw);
        jsonRequest.apInvoiceId = parseInt(pm.request.url.path.at(-3));
        jsonRequest.apDriverDeductionId = parseInt(pm.request.url.path.at(-1));
        
        // Response - match field values 
        let responseJson = pm.response.json();
        utils.validateFieldValuesIfCode(200, responseJson, jsonRequest);

    }
}


//---------------------------------------
// Folder level Post-response script - if there is an 'expand' parameter
//---------------------------------------

let expand = pm.request.url.query.get('expand');
if(expand){
	utils.validateExpandParameter(null);
}

//---------------------------------------
// Test for invalid DB value - for a PUT/POST operation
//---------------------------------------

utils.testInvalidDBValueResponse('clientId','Client ID');

//---------------------------------------
// Test for invalid business logic - for a PUT/POST operation
//---------------------------------------

utils.testInvalidBusinessLogicResponse('Invalid client ID');



//---------------------------------------
// Folder level GET-response script - for a GET operation
//---------------------------------------

let objectName = 'arTransactionTypes';
if (utils.testStatusCode(200).status) {
    utils.validateJsonSchema();
    utils.validatePagination(objectName);

    let responseJson = pm.response.json();

    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(objectName);
    }else{
        const responseIDs = responseJson.arTransactionTypes.map(record => record.transactionCode);
        const uniqueIDs = new Set(responseIDs);
        pm.test("Unique IDs", function () {
            pm.expect(Array.from(uniqueIDs)).to.deep.equal(responseIDs);
        });
    }

    let expand = pm.request.url.query.get(objectName);
    if(expand){
        utils.validateExpandParameter(objectName);
    }
}
