Feature: restrictedBillTypes

{{DOMAIN}}/aChargeCodes/{{A_CHARGE_CODE_ID}}/restrictedBillTypes


1. Error: Cannot find module 'utils'
>>  restart NPM  (includes update SVN)
cd "C:\svn\tmcur\tmwincur\src\art\arttests\Services\TM4Web\postman_external"
npm restart


2. Child resource Array valuations length = 0
No child data 
>> manually populate in database or check script function 


3. setCachedClients failed, Response: 
{"errorCode":500, "errorText": "[IBM][CLI Driver][DB2/NT64] SQL0206N  "CLIENT_ACHARGE_CODE_ID" is not valid in the context where it is used.  SQLSTATE=42703"}
>> check for missing environment variable or function error with setCachedClients 


4. 
utils.validJson: is valid JSON test failed. Response text:
{"errorCode":500, "errorText": "[IBM][CLI Driver][DB2/NT64] SQL0104N  An unexpected token "END-OF-STATEMENT" was found following "CODE_ID = ? ORDER BY".  Expected tokens may include:  "<sort_spec_list>".  SQLSTATE=42601"}
!! Response is not valid JSON !!
utils.testStatusCode: EXPECTED 200 | ACTUAL 500. Response text:
{"errorCode":500, "errorText": "[IBM][CLI Driver][DB2/NT64] SQL0104N  An unexpected token "END-OF-STATEMENT" was found following "CODE_ID = ? ORDER BY".  Expected tokens may include:  "<sort_spec_list>".  SQLSTATE=42601"}


5. EXPECTED Field aChargeCodeId: NaN | ACTUAL aChargeCodeId: CLI-FL | AssertionError: expected 'CLI-FL' to deeply equal NaN


6. There was an error in evaluating the Pre-request Script:JSONError: No data, empty input at 1:1 ^
>> cacheTimestamp -



extrastop rates
mC ok
mRS ok
mSL ok
mV ok

rBt ok
valuations - diff

console.warn(`Using preRequestOption = ${preRequestOption}`);


console.log( JSON.stringify(pm.request.url.path));
 
["clients","{{CLIENT_ID}}","tariffClasses","{{resourceId}}","multiServiceLevels","{{grandChildResourceId}}"]

pre-request should verify URL ... why waste a call if the resources are not populated

GET http://localhost:9950/masterData/clients/TM/tariffClasses/%7B%7BresourceId%7D%7D/multiServiceLevels/%7B%7BgrandChildResourceId%7D%7D

even if the function returns resource_id = -1 ... that should be checked and try to raise a warning.

preRequestOption = 'defaultCase'


Develop in order of base to grandchild, or in reverse?


