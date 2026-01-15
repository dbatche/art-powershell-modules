Feature: API Barcodes 

Customer wants to insert and update barcode item details via API, in order to synchronize with their 3rd party dispatching system.

The actual fields they require access to are as of yet undetermined, but a baseline of standard functionality should be expected
(i.e. ALT_BARCODE1, ALT_BARCODE2, cubic dimensions, etc.).

Scenario: Create an order that includes barcodes

Scenario: Modify the alternate barcode on an existing barccode

Scenario: Modify the cubic dimensions on a barcode



OpenAPI document 
OpenAPI filter 
Automation
Basic tests / functional tests 
-new barcode post
-puts 

troubleshooting env
look at Seals project if possible
What's new document 
demo on Fri/Mon

detail work 
tough scenarios 

build my own app to test? 

see workflow document on confluence 

Issues
- pieces unit not validated
- pieces <> barcodes 

Create default barcode item   

Config: convert pieces to items ?
Config: Crossdck ?

Query base units first to see what's valid for the system. 
Hmm ... perhaps setting a value should *require* that corresponding unit is specified.

405 - empty array 


# *** SPEC BASED USE CASES ***
# How many of these should break out into their own feature files? Perhaps 1 file per endpoint?
# Duplication of testing essentially same functionality but from different places (diff json)




1. Test Authorization by TruckMate API Credential (an API key, as set up in Security Configuration). 
2. Test Authorization by TM4Web User credential 

(Auto barcodes? )
3. Post to /orders/{orderId}/details/
- barcodes array 
- items not specified
- items specified 

4. Post to /orders/{orderId}/details/{orderDetailId}
- new detail line + barcode 
- existing detail line + barcode ... PUT ?

5. Test POST of an order with items = 3, but 4 unique /barcodes, verify response has ITEMS value = ‘4’.
(not if there was existing auto created barcode)


6. Test GET /orders/{orderId}
- expand details/barcodes 

7. Test GET /orders/{orderId}/details/{orderDetailId}
- expand barcodes 

8. Test GET /orders/{orderId}/details/{orderDetailId}/barcodes/{barcodeId}

9. Test the Order filter - GET /orders/$filter=details/barcodes/altBarcode1 eq ‘###########’ &expand=details/barcodes

10. Test the Order Detail filter - GET /orders/{orderId}/details$filter=barcodes/altBarcode2 eq ‘###########’ &expand=barcodes

11. Old endpoints - what should happen? error or redirect?

12. Test PUT update at order level - should be denied 

13. Test PUT update at detail line level - /orders/{orderId}/details/{orderDetailId}

- Test when /barcodes resource is provided, the system will delete all existing TLORDER_ILT rows associated with the orderDetailId and recreate them using the provided values.
- test items = count of barcodes 
- test that items requested to be updated are 

14. Test PUT at barcode level /orders/{orderId}/details/{orderDetailId}/barcodes/{barcodeId}
- test that only those parameters provided in the JSON body will be overwritten. Undefined parameters will remain set at their previous value
- items should still match count of barcodes after
- test fields that should not allow updates. 

15. Test that DELETE is not supported 
- Test update of items = 0 (and no barocdes supplied)

16. Test barcodes resource body definition and response codes 
- 200 created (201 no?)
- 202 payload partially processed - order created but not barcodes ... how to generate this?
- 400 bad request ... altBarcode too long, barcodes have different locations, system generated fields have been passed a value 
401 unauthorized
403 forbidden
500 internal error 

17. Test barcodes resource body definition 
- very detailed field by field - encode all in 1 request/reponse?


/Trips endpoint is meant for GET 


##########
CSERV.EXE Create default barcode item True      Create default barcode item per load detail
CSERV.EXE Translate items number from another field                                                 No                  Copies values from Pieces or Pallets into items

