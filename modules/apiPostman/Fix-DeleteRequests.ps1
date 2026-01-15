# Fixed update script for 3 DELETE requests
$collectionUid = "8229908-779780a9-97d0-4004-9a96-37e8c64c3405"
$headers = @{
    "X-Api-Key" = $env:POSTMAN_API_KEY
    "Content-Type" = "application/json"
}

Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host "FIXING 3 DELETE REQUESTS - Validation Errors" -ForegroundColor Green
Write-Host ("=" * 120) -ForegroundColor Cyan
Write-Host ""

# Fetch collection
$response = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers @{ "X-Api-Key" = $env:POSTMAN_API_KEY } -Method Get
$collection = $response.collection

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

$cashReceiptDel = Find-RequestByUid -items $collection.item -targetUid "8229908-dfdc768f-53b4-41c2-beb9-fc83ceed3ac4"
$invoiceDel = Find-RequestByUid -items $collection.item -targetUid "8229908-d55ee202-fd3d-44c1-8b31-6a8a866b3696"
$fuelPurchaseDel = Find-RequestByUid -items $collection.item -targetUid "8229908-438a022f-f4cf-4ff5-b0ee-3b842a61f98b"

# FIXED 1: cashReceiptId - Fixed checkNumber length and date format
Write-Host "1. Fixing cashReceiptId DELETE..." -ForegroundColor Yellow
$cashScript = @'
// Create a cash receipt via POST to get an ID for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

const cashReceiptBody = [{
    "clientId": "TM",
    "checkNumber": "DEL" + Date.now().toString().slice(-10),
    "checkAmount": 100,
    "checkReference": "DELETE_TEST",
    "checkDate": moment().format('YYYY-MM-DD'),
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
    if (err) { 
        console.error('Error creating cash receipt:', err); 
        return; 
    }
    if (response.code === 201) {
        const json = response.json();
        if (json.cashReceipts && json.cashReceipts.length > 0) {
            pm.variables.set('temp_cashReceiptId', json.cashReceipts[0].cashReceiptId);
            console.log('✓ Created cashReceipt for DELETE:', json.cashReceipts[0].cashReceiptId);
        }
    } else {
        console.error('Failed to create cash receipt. Status:', response.code);
        console.error('Response:', response.text());
    }
});
'@
$cashPreReqEvent = $cashReceiptDel.event | Where-Object { $_.listen -eq 'prerequest' }
$cashPreReqEvent.script.exec = $cashScript -split "`n"
Write-Host "   ✓ Fixed checkNumber and checkDate format" -ForegroundColor Green

# FIXED 2: invoiceId - Fixed checkNumber length and date format
Write-Host "2. Fixing invoiceId DELETE..." -ForegroundColor Yellow
$invoiceScript = @'
// Create cash receipt and invoice for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

pm.sendRequest({
    url: baseUrl + '/cashReceipts',
    method: 'POST',
    header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: { mode: 'raw', raw: JSON.stringify([{
        "clientId": "TM", 
        "checkNumber": "DEL" + Date.now().toString().slice(-10), 
        "checkAmount": 100,
        "checkReference": "DELETE_TEST", 
        "checkDate": moment().format('YYYY-MM-DD'),
        "postDated": "False", 
        "bankAccount": "00-1010", 
        "transactionType": "PAYMENT"
    }]) }
}, (err, res) => {
    if (err) { 
        console.error('Error creating cashReceipt:', err); 
        return; 
    }
    if (res.code !== 201) { 
        console.error('Failed to create cashReceipt. Status:', res.code); 
        console.error('Response:', res.text());
        return; 
    }
    
    const crId = res.json().cashReceipts[0].cashReceiptId;
    pm.variables.set('cashReceiptId', crId);
    console.log('✓ Created cashReceipt:', crId);
    
    pm.sendRequest({
        url: baseUrl + '/cashReceipts/' + crId + '/invoices',
        method: 'POST',
        header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: { mode: 'raw', raw: JSON.stringify({ "invoiceNumber": 47004, "checkAmount": 50 }) }
    }, (err2, res2) => {
        if (err2) { 
            console.error('Error creating invoice:', err2); 
            return; 
        }
        if (res2.code !== 201) { 
            console.error('Failed to create invoice. Status:', res2.code); 
            console.error('Response:', res2.text());
            return; 
        }
        
        const invId = res2.json().cashReceiptInvoice.cashReceiptInvoiceId;
        pm.variables.set('cashReceiptInvoiceId', invId);
        console.log('✓ Created invoice for DELETE:', invId);
    });
});
'@
$invoicePreReqEvent = $invoiceDel.event | Where-Object { $_.listen -eq 'prerequest' }
$invoicePreReqEvent.script.exec = $invoiceScript -split "`n"
Write-Host "   ✓ Fixed checkNumber and checkDate format" -ForegroundColor Green

# FIXED 3: tripFuelPurchaseId - No validation issues but added better error logging
Write-Host "3. Updating tripFuelPurchaseId DELETE (adding better error logging)..." -ForegroundColor Yellow
$fuelScript = @'
// Create tripFuelPurchase for deletion testing
const baseUrl = pm.environment.get('DOMAIN');
const token = pm.variables.get('TRUCKMATE_API_KEY');

pm.sendRequest({
    url: baseUrl + '/fuelTaxes?limit=1',
    method: 'GET',
    header: { 'Authorization': 'Bearer ' + token }
}, (err, res) => {
    if (err) { 
        console.error('Error fetching fuelTax:', err); 
        return; 
    }
    if (res.code !== 200 || !res.json().fuelTaxes || !res.json().fuelTaxes.length) {
        console.error('No fuelTax found for testing'); 
        return;
    }
    
    const fuelTaxId = res.json().fuelTaxes[0].fuelTaxId;
    pm.variables.set('temp_fuelTaxId', fuelTaxId);
    console.log('✓ Using fuelTaxId:', fuelTaxId);
    
    pm.sendRequest({
        url: baseUrl + '/fuelTaxes/' + fuelTaxId + '/tripFuelPurchases',
        method: 'POST',
        header: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
        body: { mode: 'raw', raw: JSON.stringify({ "purchaseAmount": 100.00 }) }
    }, (err2, res2) => {
        if (err2) { 
            console.error('Error creating tripFuelPurchase:', err2); 
            return; 
        }
        if (res2.code !== 201) { 
            console.error('Failed to create tripFuelPurchase. Status:', res2.code); 
            console.error('Response:', res2.text());
            return; 
        }
        
        const purchaseId = res2.json().tripFuelPurchase.tripFuelPurchaseId;
        pm.variables.set('temp_tripFuelPurchaseId', purchaseId);
        console.log('✓ Created tripFuelPurchase for DELETE:', purchaseId);
    });
});
'@
$fuelPreReqEvent = $fuelPurchaseDel.event | Where-Object { $_.listen -eq 'prerequest' }
$fuelPreReqEvent.script.exec = $fuelScript -split "`n"
Write-Host "   ✓ Added better error logging" -ForegroundColor Green
Write-Host ""

# Save
Write-Host "Saving to Postman..." -ForegroundColor Yellow
$updateBody = @{ collection = $collection } | ConvertTo-Json -Depth 50 -Compress
try {
    $updateResponse = Invoke-RestMethod -Uri "https://api.getpostman.com/collections/$collectionUid" -Headers $headers -Method Put -Body $updateBody
    Write-Host ""
    Write-Host ("=" * 120) -ForegroundColor Green
    Write-Host "✅ SUCCESS! All 3 DELETE requests fixed" -ForegroundColor Green
    Write-Host ("=" * 120) -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes:" -ForegroundColor Yellow
    Write-Host "  ✓ checkNumber: Now uses Date.now().toString().slice(-10) = 13 chars max" -ForegroundColor Green
    Write-Host "  ✓ checkDate: Now uses moment().format('YYYY-MM-DD') = date only" -ForegroundColor Green
    Write-Host "  ✓ Better error logging with response.text() for debugging" -ForegroundColor Green
    Write-Host ("=" * 120) -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

