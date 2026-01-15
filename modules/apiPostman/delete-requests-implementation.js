// Implementation for the 3 skipped DELETE requests

// ============================================================================
// 1. cashReceiptId DELETE
// ============================================================================
const cashReceiptIdPreRequest = `
// Create a cash receipt via POST to get an ID for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

const cashReceiptBody = [
    {
        "clientId": "TM",
        "checkNumber": "DEL" + Date.now(),
        "checkAmount": 100,
        "checkReference": "DELETE_TEST",
        "checkDate": moment().format('YYYY-MM-DDTHH:mm:ss'),
        "postDated": "False",
        "bankAccount": "00-1010",
        "transactionType": "PAYMENT"
    }
];

pm.sendRequest({
    url: baseUrl + '/cashReceipts',
    method: 'POST',
    header: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    },
    body: {
        mode: 'raw',
        raw: JSON.stringify(cashReceiptBody)
    }
}, (err, response) => {
    if (err) {
        console.error('Error creating cash receipt for DELETE test:', err);
        return;
    }
    
    if (response.code === 201) {
        const responseJson = response.json();
        if (responseJson.cashReceipts && responseJson.cashReceipts.length > 0) {
            const cashReceiptId = responseJson.cashReceipts[0].cashReceiptId;
            pm.variables.set('temp_cashReceiptId', cashReceiptId);
            console.log('Created cashReceipt for DELETE test:', cashReceiptId);
        }
    } else {
        console.error('Failed to create cash receipt. Status:', response.code);
    }
});
`;

// ============================================================================
// 2. invoiceId DELETE
// ============================================================================
const invoiceIdPreRequest = `
// Create cash receipt and invoice via POST to get IDs for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

// Step 1: Create cash receipt
const cashReceiptBody = [
    {
        "clientId": "TM",
        "checkNumber": "DEL" + Date.now(),
        "checkAmount": 100,
        "checkReference": "DELETE_TEST",
        "checkDate": moment().format('YYYY-MM-DDTHH:mm:ss'),
        "postDated": "False",
        "bankAccount": "00-1010",
        "transactionType": "PAYMENT"
    }
];

pm.sendRequest({
    url: baseUrl + '/cashReceipts',
    method: 'POST',
    header: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
    },
    body: {
        mode: 'raw',
        raw: JSON.stringify(cashReceiptBody)
    }
}, (err, response) => {
    if (err) {
        console.error('Error creating cash receipt:', err);
        return;
    }
    
    if (response.code === 201) {
        const responseJson = response.json();
        if (responseJson.cashReceipts && responseJson.cashReceipts.length > 0) {
            const cashReceiptId = responseJson.cashReceipts[0].cashReceiptId;
            pm.variables.set('cashReceiptId', cashReceiptId);
            console.log('Created cashReceipt:', cashReceiptId);
            
            // Step 2: Create invoice under the cash receipt
            pm.sendRequest({
                url: baseUrl + '/cashReceipts/' + cashReceiptId + '/invoices',
                method: 'POST',
                header: {
                    'Authorization': 'Bearer ' + token,
                    'Content-Type': 'application/json'
                },
                body: {
                    mode: 'raw',
                    raw: JSON.stringify({
                        "invoiceNumber": 47004,
                        "checkAmount": 50
                    })
                }
            }, (err2, response2) => {
                if (err2) {
                    console.error('Error creating invoice:', err2);
                    return;
                }
                
                if (response2.code === 201) {
                    const invoiceResponseJson = response2.json();
                    if (invoiceResponseJson.cashReceiptInvoice) {
                        const invoiceId = invoiceResponseJson.cashReceiptInvoice.cashReceiptInvoiceId;
                        pm.variables.set('cashReceiptInvoiceId', invoiceId);
                        console.log('Created invoice for DELETE test:', invoiceId);
                    }
                } else {
                    console.error('Failed to create invoice. Status:', response2.code);
                }
            });
        }
    } else {
        console.error('Failed to create cash receipt. Status:', response.code);
    }
});
`;

// ============================================================================
// 3. tripFuelPurchaseId DELETE
// ============================================================================
const tripFuelPurchaseIdPreRequest = `
// Create a tripFuelPurchase via POST to get IDs for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

// First, get an existing fuelTax to attach the purchase to
pm.sendRequest({
    url: baseUrl + '/fuelTaxes?limit=1',
    method: 'GET',
    header: {
        'Authorization': 'Bearer ' + token
    }
}, (err, response) => {
    if (err) {
        console.error('Error fetching fuelTax:', err);
        return;
    }
    
    if (response.code === 200) {
        const responseJson = response.json();
        if (responseJson.fuelTaxes && responseJson.fuelTaxes.length > 0) {
            const fuelTaxId = responseJson.fuelTaxes[0].fuelTaxId;
            pm.variables.set('temp_fuelTaxId', fuelTaxId);
            console.log('Using fuelTaxId:', fuelTaxId);
            
            // Now create a tripFuelPurchase
            const purchaseBody = {
                "purchaseAmount": 100.00
            };
            
            pm.sendRequest({
                url: baseUrl + '/fuelTaxes/' + fuelTaxId + '/tripFuelPurchases',
                method: 'POST',
                header: {
                    'Authorization': 'Bearer ' + token,
                    'Content-Type': 'application/json'
                },
                body: {
                    mode: 'raw',
                    raw: JSON.stringify(purchaseBody)
                }
            }, (err2, response2) => {
                if (err2) {
                    console.error('Error creating tripFuelPurchase:', err2);
                    return;
                }
                
                if (response2.code === 201) {
                    const purchaseResponseJson = response2.json();
                    if (purchaseResponseJson.tripFuelPurchase) {
                        const purchaseId = purchaseResponseJson.tripFuelPurchase.tripFuelPurchaseId;
                        pm.variables.set('temp_tripFuelPurchaseId', purchaseId);
                        console.log('Created tripFuelPurchase for DELETE test:', purchaseId);
                    }
                } else {
                    console.error('Failed to create tripFuelPurchase. Status:', response2.code);
                }
            });
        } else {
            console.error('No fuelTaxes found to attach purchase to');
        }
    } else {
        console.error('Failed to fetch fuelTaxes. Status:', response.code);
    }
});
`;

console.log("Pre-request scripts ready for implementation");

