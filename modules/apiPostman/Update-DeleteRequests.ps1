# Update script for 3 DELETE requests in Finance collection
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
$headers = @{
    "X-Api-Key" = $env:POSTMAN_API_KEY
    "Content-Type" = "application/json"
}

Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host "UPDATING 3 DELETE REQUESTS" -ForegroundColor Green
Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host ""

# Fetch collection
Write-Host "Fetching collection..." -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers @{ "X-Api-Key" = $env:POSTMAN_API_KEY } -Method Get
$collection = $response.collection

# Helper function
function Find-RequestByUid {
    param($items, $targetUid)
    foreach ($item in $items) {
        if ($item.uid -eq $targetUid) { return $item }
        if ($item.item) {
            $result = Find-RequestByUid -items $item.item -targetUid $targetUid
            if ($result) { return $result }
        }
    }
    return $null
}

# Find the 3 requests
$cashReceiptDel = Find-RequestByUid -items $collection.item -targetUid "8229908-dfdc768f-53b4-41c2-beb9-fc83ceed3ac4"
$invoiceDel = Find-RequestByUid -items $collection.item -targetUid "8229908-d55ee202-fd3d-44c1-8b31-6a8a866b3696"
$fuelPurchaseDel = Find-RequestByUid -items $collection.item -targetUid "8229908-438a022f-f4cf-4ff5-b0ee-3b842a61f98b"

Write-Host "Found all 3 DELETE requests" -ForegroundColor Green
Write-Host ""

# Update 1: cashReceiptId
Write-Host "1. Updating cashReceiptId DELETE..." -ForegroundColor Yellow
$cashScript = @'
// Create a cash receipt via POST to get an ID for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

const cashReceiptBody = [{
    "clientId": "TM",
    "checkNumber": "DEL" + Date.now(),
    "checkAmount": 100,
    "checkReference": "DELETE_TEST",
    "checkDate": moment().format('YYYY-MM-DDTHH:mm:ss'),
    "postDated": "False",
    "bankAccount": "00-1010",
    "transactionType": "PAYMENT"
}];

pm.sendRequest({
    url: baseUrl + '/cashReceipts',
    method: 'POST',
    header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: { mode: 'raw', raw: JSON.stringify(cashReceiptBody) }
}, (err, response) => {
    if (err) { console.error('Error:', err); return; }
    if (response.code === 201) {
        const json = response.json();
        if (json.cashReceipts && json.cashReceipts.length > 0) {
            pm.variables.set('temp_cashReceiptId', json.cashReceipts[0].cashReceiptId);
            console.log('Created cashReceipt for DELETE:', json.cashReceipts[0].cashReceiptId);
        }
    }
});
'@
$cashPreReqEvent = $cashReceiptDel.event | Where-Object { $_.listen -eq 'prerequest' }
$cashPreReqEvent.script.exec = $cashScript -split "`n"
Write-Host "   ✓ Updated" -ForegroundColor Green

# Update 2: invoiceId  
Write-Host "2. Updating invoiceId DELETE..." -ForegroundColor Yellow
$invoiceScript = @'
// Create cash receipt and invoice for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

pm.sendRequest({
    url: baseUrl + '/cashReceipts',
    method: 'POST',
    header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: { mode: 'raw', raw: JSON.stringify([{
        "clientId": "TM", "checkNumber": "DEL" + Date.now(), "checkAmount": 100,
        "checkReference": "DELETE_TEST", "checkDate": moment().format('YYYY-MM-DDTHH:mm:ss'),
        "postDated": "False", "bankAccount": "00-1010", "transactionType": "PAYMENT"
    }]) }
}, (err, res) => {
    if (err || res.code !== 201) { console.error('Error creating cashReceipt'); return; }
    const crId = res.json().cashReceipts[0].cashReceiptId;
    pm.variables.set('cashReceiptId', crId);
    
    pm.sendRequest({
        url: baseUrl + '/cashReceipts/' + crId + '/invoices',
        method: 'POST',
        header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: { mode: 'raw', raw: JSON.stringify({ "invoiceNumber": 47004, "checkAmount": 50 }) }
    }, (err2, res2) => {
        if (err2 || res2.code !== 201) { console.error('Error creating invoice'); return; }
        const invId = res2.json().cashReceiptInvoice.cashReceiptInvoiceId;
        pm.variables.set('cashReceiptInvoiceId', invId);
        console.log('Created invoice for DELETE:', invId);
    });
});
'@
$invoicePreReqEvent = $invoiceDel.event | Where-Object { $_.listen -eq 'prerequest' }
$invoicePreReqEvent.script.exec = $invoiceScript -split "`n"
Write-Host "   ✓ Updated" -ForegroundColor Green

# Update 3: tripFuelPurchaseId
Write-Host "3. Updating tripFuelPurchaseId DELETE..." -ForegroundColor Yellow
$fuelScript = @'
// Create tripFuelPurchase for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

pm.sendRequest({
    url: baseUrl + '/fuelTaxes?limit=1',
    method: 'GET',
    header: { 'Authorization': 'Bearer ' + token }
}, (err, res) => {
    if (err || res.code !== 200 || !res.json().fuelTaxes.length) {
        console.error('No fuelTax found'); return;
    }
    const fuelTaxId = res.json().fuelTaxes[0].fuelTaxId;
    pm.variables.set('temp_fuelTaxId', fuelTaxId);
    
    pm.sendRequest({
        url: baseUrl + '/fuelTaxes/' + fuelTaxId + '/tripFuelPurchases',
        method: 'POST',
        header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: { mode: 'raw', raw: JSON.stringify({ "purchaseAmount": 100.00 }) }
    }, (err2, res2) => {
        if (err2 || res2.code !== 201) { console.error('Error creating purchase'); return; }
        const purchaseId = res2.json().tripFuelPurchase.tripFuelPurchaseId;
        pm.variables.set('temp_tripFuelPurchaseId', purchaseId);
        console.log('Created tripFuelPurchase for DELETE:', purchaseId);
    });
});
'@
$fuelPreReqEvent = $fuelPurchaseDel.event | Where-Object { $_.listen -eq 'prerequest' }
$fuelPreReqEvent.script.exec = $fuelScript -split "`n"
Write-Host "   ✓ Updated" -ForegroundColor Green
Write-Host ""

# Save to Postman
Write-Host "Saving to Postman..." -ForegroundColor Yellow
$updateBody = @{ collection = $collection } | ConvertTo-Json -Depth 50 -Compress
try {
    $updateResponse = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers $headers -Method Put -Body $updateBody
    Write-Host ""
    Write-Host ("=" * 120) -ForegroundColor Green
    Write-Host "✅ SUCCESS! All 3 DELETE requests updated and ready to use" -ForegroundColor Green
    Write-Host ("=" * 120) -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

