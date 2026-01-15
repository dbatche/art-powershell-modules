// Fixed test script for GET /apInvoices/{apInvoiceId}/ista/{istaId}
// Replace the existing test script with this

if (utils.testStatusCode(200).status) {
    utils.validateJsonSchemaIfCode(200);
    
    if(pm.request.url.query.get('$select')){
        utils.validateSelectParameter(null);
    } else {
        let responseJson = pm.response.json();
        
        // FIXED: Better handling of istaId extraction and validation
        const istaIdFromUrl = pm.request.url.path.at(-1);
        
        // Check if the URL variable was properly replaced
        if (istaIdFromUrl && istaIdFromUrl.startsWith('{{')) {
            console.log('⚠️ WARNING: istaId variable not replaced in URL:', istaIdFromUrl);
            pm.test("⚠️ istaId variable should be set", function() {
                pm.expect(istaIdFromUrl).to.not.match(/^\{\{.*\}\}$/);
            });
        } else {
            const expectedIstaId = parseInt(istaIdFromUrl);
            
            // Check if parseInt succeeded
            if (isNaN(expectedIstaId)) {
                console.log('⚠️ WARNING: Could not parse istaId from URL:', istaIdFromUrl);
            } else {
                // Only validate if we have a valid expected value
                console.log(`Validating istaId: expected=${expectedIstaId}, actual=${responseJson.istaId}`);
                
                // Check if istaId exists in response
                pm.test("Response has istaId field", function() {
                    pm.expect(responseJson).to.have.property('istaId');
                });
                
                // Validate the value matches
                if (responseJson.istaId !== undefined) {
                    utils.validateFieldValuesIfCode(200, responseJson, {
                        "istaId": expectedIstaId
                    });
                } else {
                    console.log('⚠️ Response structure:');
                    console.log(JSON.stringify(responseJson, null, 2));
                    pm.test("⚠️ Response missing istaId - check response structure above", function() {
                        pm.expect(responseJson.istaId).to.not.be.undefined;
                    });
                }
            }
        }
    }
    
    let expand = pm.request.url.query.get('expand');
    if(expand){
        utils.validateExpandParameter(null);
    }
}

// Additional diagnostic: Log the request details for troubleshooting
console.log('Request URL:', pm.request.url.toString());
console.log('AP_INVOICE_ID:', pm.collectionVariables.get('AP_INVOICE_ID') || pm.environment.get('AP_INVOICE_ID'));
console.log('istaId variable:', pm.collectionVariables.get('istaId') || pm.environment.get('istaId'));
