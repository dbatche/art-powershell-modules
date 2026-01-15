// Log Request path
//console.info(`** REQUEST: ${pm.execution.location.join(" > ")} ********************` );

// Log Script location
//console.log(`-- PRE-REQUEST folder: ${pm.execution.location.current} `);

// Enable test filtering by TAGS environment variable ('TagsOnly','SkipTags'; default is all tests)
pm.require('@trimble-inc/tags').tagFilter();

// Utils Package for Finance API
// uFin = pm.require('@trimble-inc/utils_finance');
// const uFin = pm.require('@trimble-inc/utils_finance');


pm.collectionVariables.clear();

//pm.globals.clear(); //clear all globals to force a reset

// Declare globally to establish scope in pre-requests
utils = '';
lodash = require('lodash');
moment = require('moment');

const cacheTimestamp = pm.globals.get('cacheTimestamp');
const cacheDuration = pm.environment.get('CACHE_DURATION_MILLISECONDS') ? pm.environment.get('CACHE_DURATION_MILLISECONDS') : 3600000; // 1 hour
const packages = pm.globals.get('packages');
const apiKey = pm.globals.get("BEARER_TOKEN");
const cacheExpired = !cacheTimestamp || !packages || (Date.now() - cacheTimestamp) > cacheDuration;
if (!apiKey || cacheExpired) {
    const reqs = [
        {
            packageName: 'utils',  // name of a custom package file in the ~/modules folder
            packageType: 'custom'  // can be 'custom' or 'npm'
        },
        {
            packageName: 'tm_utils',
            packageType: 'custom'
        }
    ];

    const reqPkgNames = reqs.map(item => item.packageName).join(',');
    const reqPkgTypes = reqs.map(item => item.packageType).join(',');

    pm.sendRequest({
        //url: `${pm.environment.get('EXTERNAL_LIB_SERVER')}?packages=${reqPkgNames}&types=${reqPkgTypes}&customPath=${pm.environment.get('EXTERNAL_LIB_PATH')}`,
        url: `${pm.environment.get('EXTERNAL_LIB_SERVER')}?packages=${reqPkgNames}&types=${reqPkgTypes}`,
        method: 'GET'
    }, (err, res) => {
        if (!err) {
            pkgs = res.text();
            eval(pkgs);
            utils = require('tm_utils')(pm);
            utils.setCachedSchema(() => {
            //    utils.setWorkspaceCache();
                setCachedSchema();
            });

            pm.globals.set("BEARER_TOKEN", pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}'));
            pm.globals.set('cacheTimestamp', Date.now());
            pm.globals.set('installedPackages', reqPkgNames);
            pm.globals.set('packages', pkgs);

        }else{
            console.warn('EXTERNAL_LIB err', err);
        }
    });
}else{
    eval(packages);
    utils = require('tm_utils')(pm);
    setCachedSchema();
}

function setCachedSchema(){

    if(pm.globals.get('driverDeductions')){ return; }

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/driverDeductions?limit=1", 
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
        if (jsonData.driverDeductions.length > 0){
            pm.globals.set('driverDeductions', jsonData.driverDeductions);
            pm.globals.set('driverDeductionId', jsonData.driverDeductions[0].driverDeductionId);
        }
        else {
            console.log("driverDeductions could not be cached.")
        }
    });

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?$filter=checkId eq "+ pm.variables.get('BILL_CHECK_ID') + "&expand=bills", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
            if (err) {
                console.error('error:\n', err, 'Response: \n', response.text());
                throw new Error("An error has occurred. Check logs.");
            }
            if (response.code == 200){
                const jsonData = response.json();
                if (jsonData.checks.length > 0){
                    pm.globals.set('checks', jsonData.checks);
                    // pm.globals.set('checkBillId', jsonData.checks[0].bills[0].checkBillId); // check for empty []
                    pm.globals.set('checkBillId', !lodash.isEmpty(jsonData.checks[0].bills) ? jsonData.checks[0].bills[0].checkBillId : '');
                } 
                else{
                    console.log("check and checkBillId could not be cached.")
                }       
            }
    });

        //cache glAccountId value
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/glAccounts?&limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
            if (response.code == 200){
                const jsonData = response.json();
                if (jsonData.glAccounts.length > 0){
                    pm.globals.set('glAccountId', jsonData.glAccounts[0].glAccount);
                } 
                else{
                    console.log("glAccountId could not be cached.")
                }
            }
    });

    //cache posted checkId
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/checks?$filter=checkPosted eq True&$orderBy checkId desc", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
            if (err) {
                console.error('error:\n', err, 'Response: \n', response.text());
                throw new Error("An error has occurred. Check logs.");
            }
            else{
                if (response.code == 200){
                    const jsonData = response.json();
                    if (jsonData.checks.length > 0){
                        pm.globals.set('postedCheckId', jsonData.checks[0].checkId);
                    } 
                    else{
                        console.log("postedCheckId could not be cached.")
                    }
                }
            }
    });

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/taxes?limit=2&expand=taxRates", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.taxes.length > 0){
                pm.globals.set('taxId', jsonData.taxes[0].taxId);
                pm.globals.set('taxRateId',jsonData.taxes[0].taxRates[0].taxRateId);
                pm.globals.set('taxRate',JSON.stringify(jsonData.taxes[1].taxRates[0]));
                pm.globals.set('taxId2', jsonData.taxes[1].taxId);
                pm.globals.set('taxRateId2',jsonData.taxes[1].taxRates[0].taxRateId);
            } 
            else{
                console.log("tax values could not be cached.")
            }  
        }
    });

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/driverPayments?limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
    }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.driverPayments.length > 0){
                pm.globals.set('driverPayments', jsonData.driverPayments);
                pm.globals.set('paymentId', jsonData.driverPayments[0].paymentId);
            } 
            else{
                console.log("driverPayment values could not be cached.")
            }
        }
    });

    //cache fuelTaxes child resources

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/fuelTaxes?$filter=fuelTaxId eq " + pm.variables.get('FUEL_TAX_ID') + "&expand=tripSegments,tripFuelPurchases,tripWaypoints&limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            pm.globals.set('tripSegmentId', !lodash.isEmpty(jsonData.fuelTaxes[0].tripSegments) ? jsonData.fuelTaxes[0].tripSegments[0].tripSegmentId : '');
            pm.globals.set('tripFuelPurchaseId', !lodash.isEmpty(jsonData.fuelTaxes[0].tripFuelPurchases) ? jsonData.fuelTaxes[0].tripFuelPurchases[0].tripFuelPurchaseId : '');
            pm.globals.set('tripWaypointId', !lodash.isEmpty(jsonData.fuelTaxes[0].tripWaypoints) ? jsonData.fuelTaxes[0].tripWaypoints[0].tripWaypointId : '');
        }
    });

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/driverPaymentCodes?$filter=paymentCode eq " + pm.variables.get("DRIVER_PAY_CODE") + "&limit=1", 
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
        // pm.globals.set('driverPaymentCode', jsonData.driverPaymentCodes[0]); // check for empty []
        pm.globals.set('driverPaymentCode', !lodash.isEmpty(jsonData.driverPaymentCodes) ? jsonData.driverPaymentCodes[0] : '');
    });

    //cache apInvoiceId child resources

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/apInvoices?$filter=apInvoiceId eq " + pm.variables.get('AP_INVOICE_ID') + "&expand=expenses&limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            pm.globals.set('expenseId', !lodash.isEmpty(jsonData.apInvoices[0].expenses) ? jsonData.apInvoices[0].expenses[0].expenseId : '');
        }
    });

    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/apInvoices?$filter=apInvoiceId eq " + pm.variables.get('AP_INVOICE_ID') + "&expand=apDriverDeductions&limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            pm.globals.set('apInvoiceDriverDeductionId', !lodash.isEmpty(jsonData.apInvoices[0].apDriverDeductions) ? jsonData.apInvoices[0].apDriverDeductions[0].apDriverDeductionId : '');
        }
    });

        pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/apInvoices?$filter=apInvoiceId eq " + pm.variables.get('AP_INVOICE_ID') + "&expand=ista&limit=1", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            pm.globals.set('istaId', !lodash.isEmpty(jsonData.apInvoices[0].ista) ? jsonData.apInvoices[0].ista[0].istaId : '');
        }
    });


    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/driverPaymentCodes?$filter=contractId eq " + pm.variables.get('DRIVER_PAY_CONTRACT_ID') + " AND taxable eq False&limit=1", 
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
        //pm.globals.set('nonTaxableDriverPaymentCode', jsonData.driverPaymentCodes[0].paymentCode); // check for empty []
        pm.globals.set('nonTaxableDriverPaymentCode', !lodash.isEmpty(jsonData.driverPaymentCodes) ? jsonData.driverPaymentCodes[0].paymentCode : '');
    });

    //cache trip and leg sequence for driver payments
     pm.sendRequest({
         url: pm.environment.get("TM_DOMAIN") + "/trips?$filter=status eq ASSGN&expand=legs&limit=1&$orderBy=tripNumber desc", 
         method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
         }, function (err, response) {
         if (err) {
             console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
         if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.trips.length > 0){
                pm.globals.set('tripNumber', jsonData.trips[0].tripNumber);
                pm.globals.set('legSeq', jsonData.trips[0].legs[0].legSeq);
                pm.globals.set('legFromZone', jsonData.trips[0].legs[0].fromZone);
                pm.globals.set('legToZone', jsonData.trips[0].legs[0].toZone);
            } 
            else{
                console.log("trip values could not be cached.")
            }
         }
     });

    // //cache orderId for orders
     pm.sendRequest({
         url: pm.environment.get("TM_DOMAIN") + "/orders?$filter=status eq AVAIL&$orderBy=orderId desc&limit=1", 
         method: 'GET',
         header: {
             'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
         }
         }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
        if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.orders.length > 0){
                pm.globals.set('orderId', jsonData.orders[0].orderId);
            } 
            else{
                console.log("orderId value could not be cached.")
            }
        }
     });

     //cache inactive vendorId for business logic testing for checks
     pm.sendRequest({
         url: pm.environment.get("MD_DOMAIN") + "/vendors?$filter=isInactive eq True&limit=1", 
         method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
         }, function (err, response) {
       if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.vendors.length > 0){
                pm.globals.set('inactiveVendorId', jsonData.vendors[0].vendorId);
            } 
            else{
                console.log("inactiveVendorId value could not be cached.")
            }
        }
     });

// //cache inactive driverId for business logic testing for checks
     pm.sendRequest({
         url: pm.environment.get("MD_DOMAIN") + "/drivers?$filter=isActiveInPay eq False&limit=1", 
         method: 'GET',
         header: {
             'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
         }
         }, function (err, response) {
         if (err) {
             console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
         if (response.code == 200){
            const jsonData = response.json();
            if (!lodash.isEmpty(jsonData.drivers) && jsonData.drivers.length > 0){ // Check for empty []
                pm.globals.set('inactiveDriverId', jsonData.drivers[0].driverId);
            } 
            else{
                console.log("inactiveDriverId value could not be cached.")
            }
         }
     });

    // //cache inactive clientId for business logic testing for checks
     pm.sendRequest({
         url: pm.environment.get("MD_DOMAIN") + "/clients?$filter=isInactive eq True&limit=1", 
         method: 'GET',
         header: {
             'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
         }
         }, function (err, response) {
         if (err) {
             console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
         if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.clients.length > 0){
                pm.globals.set('inactiveClientId', jsonData.clients[0].clientId);
            } 
            else{
                console.log("inactiveClientId value could not be cached.")
            }
         }
     });

     //cache non-taxable driver deduction code for deduction driver
     pm.sendRequest({
         url: pm.environment.get("DOMAIN") + "/driverDeductionCodes?$filter=contractId eq " + pm.variables.get('DEDUCTION_DRIVER_CONTRACT_ID') + " and taxable eq False", 
         method: 'GET',
         header: {
             'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
         }
         }, function (err, response) {
         if (err) {
             console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
         if (response.code == 200){
            const jsonData = response.json();
            if (!lodash.isEmpty(jsonData.driverDeductionCodes) && jsonData.driverDeductionCodes.length > 0){ // check for empty []
                pm.globals.set('driverDeductionNonTaxableCode', jsonData.driverDeductionCodes[0].deductionCode);
            } 
            else{
                console.log("Deduct driver non taxable driver deduction code could not be cached.")
            }
         }
     });

      //cache adminTaxDeductionEnabledCode
     pm.sendRequest({
         url: pm.environment.get("DOMAIN") + "/driverDeductionCodes?$filter=contractId eq " + pm.variables.get('DEDUCTION_DRIVER_CONTRACT_ID') + " AND adminFee eq True AND taxDeduction eq True", 
         method: 'GET',
         header: {
             'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
         }
         }, function (err, response) {
         if (err) {
             console.error('error:\n', err, 'Response: \n', response.text());
             throw new Error("An error has occurred. Check logs.");
         }
         if (response.code == 200){
            const jsonData = response.json();
            if (jsonData.driverDeductionCodes.length > 0){
                pm.globals.set('adminTaxDeductionEnabledCode', jsonData.driverDeductionCodes[0].deductionCode);
            } 
            else{
                console.log("adminTaxDeductionEnabledCode could not be cached.")
            }
         }
     });

    //cache cashReceiptId, clientId, and then cashReceiptInvoiceId
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/cashReceipts?$filter=transactionPosted eq 'False'", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            return;
        }
        if (response.code == 200){
        const jsonData = response.json();
        if (jsonData.cashReceipts.length > 0){
            const firstCashReceipt = jsonData.cashReceipts[0];
            
            // Cache cashReceiptId and clientId
            pm.globals.set('cashReceiptId', firstCashReceipt.cashReceiptId);
            console.log("Cached cashReceiptId:", firstCashReceipt.cashReceiptId);
            
            pm.globals.set('cashReceiptClientId', firstCashReceipt.clientId);
            console.log("Cached cashReceiptClientId:", firstCashReceipt.clientId);
            
            // NOW cache the cashReceiptInvoiceId (chained request)
            pm.sendRequest({
                url: pm.environment.get("DOMAIN") + "/cashReceipts/" + firstCashReceipt.cashReceiptId + "/invoices", 
                method: 'GET',
                header: {
                    'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
                }
                }, function (err, response) {
                if (err) {
                    console.error('Invoice caching error:\n', err);
                    return;
                }
                if (response.code == 200){
                    const jsonData = response.json();
                    if (jsonData && jsonData.invoices && jsonData.invoices.length > 0){
                        const firstInvoice = jsonData.invoices[0];
                        
                        if (firstInvoice.invoiceId) {
                            pm.globals.set('cashReceiptInvoiceId', firstInvoice.invoiceId);
                            console.log("Cached cashReceiptInvoiceId:", firstInvoice.invoiceId);
                        } else {
                            console.log("invoiceId field not found in invoice response");
                        }
                    } 
                    else{
                        console.log("cashReceiptInvoiceId could not be cached - no invoices found.")
                    }
                }
                else {
                    console.log("Failed to fetch invoices. Status:", response.code);
                }
            });
            
        } 
        else{
            console.log("cashReceiptId could not be cached - no cash receipts found.")
        }
        }
        else {
            console.log("Failed to fetch cash receipts. Status:", response.code);
        }
    });

     // cache employeePayment > payrollBatchId
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/employeePayments", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
        const jsonData = response.json();
        if (jsonData.employeePayments.length > 0){
            pm.globals.set('payrollBatchId', jsonData.employeePayments[0].payrollBatchId);
            console.log("Cached payrollBatchId:", jsonData.employeePayments[0].payrollBatchId);
        } 
        else{
            console.log("payrollBatchId could not be cached - no employee payments found.")
        }
        }
        else {
            console.log("Failed to fetch employee payments. Status:", response.code);
        }
    });

    // cache driverStatement > driverStatementId
    pm.sendRequest({
        url: pm.environment.get("DOMAIN") + "/driverStatements", 
        method: 'GET',
        header: {
            'Authorization': 'Bearer ' + pm.variables.replaceIn('{{TRUCKMATE_API_KEY}}')
        }
        }, function (err, response) {
        if (err) {
            console.error('error:\n', err, 'Response: \n', response.text());
            throw new Error("An error has occurred. Check logs.");
        }
        if (response.code == 200){
        const jsonData = response.json();
        if (jsonData.driverStatements.length > 0){
            pm.globals.set('driverStatementId', jsonData.driverStatements[0].driverStatementId);
            console.log("Cached driverStatementId:", jsonData.driverStatements[0].driverStatementId);
        } 
        else{
            console.log("driverStatementId could not be cached - no driver statements found.")
        }
        }
        else {
            console.log("Failed to fetch driver statements. Status:", response.code);
        }
    });

}

pm.globals.set("CurrentDatetime", moment().format("YYYY-MM-DD HH:mm:ss"));
pm.globals.set("timestampUtcIso8601", moment().format("YYYY-MM-DD HH:mm:ss"));
pm.globals.set("CurrentDate", moment().format("YYYY-MM-DD"));
pm.globals.set("CurrentTime", moment().format("HH:mm"));
pm.globals.set("TomorrowDatetime", moment().add(1, 'days').format("YYYY-MM-DD HH:mm:ss"));
pm.globals.set("YesterdayDatetime", moment().add(-1, 'days').format("YYYY-MM-DD HH:mm:ss"));
pm.globals.set("CurrentDateTimeAdd4Days", moment().add(4, 'days').format("YYYY-MM-DD HH:mm:ss"));


function generateRandomAlphanumeric(length) {
    let result = '';
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}

//used for generating randomGLAccounts
utils.generateGlAccountNumber = () => {
    let part1 = generateRandomAlphanumeric(2);
    let part2 = generateRandomAlphanumeric(4);
    let accountNumber = `${part1}-${part2}`;
    return accountNumber;
}

