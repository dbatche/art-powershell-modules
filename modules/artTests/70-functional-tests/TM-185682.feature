Feature: TM-185682 - PUT /orders/{orderId}/details/{orderDetailId}
  Verify: Update existing barcode (with barcodeId) + Create new (without barcodeId)

  Background:
    * url tmApiUrl
    * header Authorization = 'Bearer ' + apiToken
    * def timestamp = 
      """
      function() {
        var date = new Date();
        date.setDate(date.getDate() + 7);
        return date.toISOString().slice(0,19);
      }
      """
    * def futureDate = timestamp()

  Scenario: Create order, add barcodes, then update one and create two new
    
    # ========================================================================
    # Create Order
    # ========================================================================
    Given path 'tm/orders'
    And request
      """
      {
        "orders": [
          {
            "pickUpBy": "#(futureDate)",
            "pickUpByEnd": "#(futureDate)",
            "deliverBy": "#(futureDate)",
            "deliverByEnd": "#(futureDate)",
            "startZone": "BCLAN",
            "endZone": "ABCAL",
            "caller": { "clientId": "TM" },
            "consignee": { "clientId": "TMSUPPORT" }
          }
        ]
      }
      """
    When method POST
    Then status 201
    And match response.orderId == '#number'
    And match response.status == 'AVAIL'
    * def orderId = response.orderId
    * print 'Created Order:', orderId

    # ========================================================================
    # Add Detail
    # ========================================================================
    Given path 'tm/orders', orderId, 'details'
    And request
      """
      [
        {
          "weight": 1000,
          "weightUnits": "LB"
        }
      ]
      """
    When method POST
    Then status 201
    And match response.details == '#[3]'
    * def detailId = response.details[0].orderDetailId
    * print 'Created Detail:', detailId

    # ========================================================================
    # Add 2 Initial Barcodes
    # ========================================================================
    Given path 'tm/orders', orderId, 'details', detailId, 'barcodes'
    And request
      """
      [
        {
          "altBarcode1": "ORIGINAL-A",
          "weight": 100.5,
          "weightUnits": "LB"
        },
        {
          "altBarcode1": "ORIGINAL-B",
          "weight": 200.5,
          "weightUnits": "LB"
        }
      ]
      """
    When method POST
    Then status 201
    And match response == '#[2]'
    And match response[0].altBarcode1 == 'ORIGINAL-A'
    And match response[0].weight == 100.5
    And match response[1].altBarcode1 == 'ORIGINAL-B'
    And match response[1].weight == 200.5
    * def barcodeId1 = response[0].barcodeId
    * print 'Created Barcodes:', response[0].barcodeId, response[1].barcodeId

    # ========================================================================
    # TEST: PUT with mixed barcode array (update 1, create 2)
    # ========================================================================
    Given path 'tm/orders', orderId, 'details', detailId
    And request
      """
      {
        "barcodes": [
          {
            "barcodeId": #(barcodeId1),
            "altBarcode1": "UPDATED-A",
            "weight": 999.99,
            "weightUnits": "LB"
          },
          {
            "altBarcode1": "NEW-C",
            "weight": 111.11,
            "weightUnits": "LB"
          },
          {
            "altBarcode1": "NEW-D",
            "weight": 222.22,
            "weightUnits": "LB"
          }
        ]
      }
      """
    When method PUT
    Then status 200
    And match response.barcodes == '#[4]'
    
    # Verify the first barcode was UPDATED
    * def updatedBarcode = karate.jsonPath(response, "$.barcodes[?(@.barcodeId==" + barcodeId1 + ")]")[0]
    * match updatedBarcode.altBarcode1 == 'UPDATED-A'
    * match updatedBarcode.weight == 999.99
    * print 'Barcode UPDATED:', updatedBarcode.barcodeId
    
    # Verify the second barcode is UNCHANGED
    * def unchangedBarcode = karate.jsonPath(response, "$.barcodes[?(@.altBarcode1=='ORIGINAL-B')]")[0]
    * match unchangedBarcode.weight == 200.5
    * print 'Barcode UNCHANGED:', unchangedBarcode.barcodeId
    
    # Verify NEW-C was CREATED
    * def newBarcodeC = karate.jsonPath(response, "$.barcodes[?(@.altBarcode1=='NEW-C')]")[0]
    * match newBarcodeC.weight == 111.11
    * match newBarcodeC.barcodeId != barcodeId1
    * print 'Barcode CREATED (NEW-C):', newBarcodeC.barcodeId
    
    # Verify NEW-D was CREATED
    * def newBarcodeD = karate.jsonPath(response, "$.barcodes[?(@.altBarcode1=='NEW-D')]")[0]
    * match newBarcodeD.weight == 222.22
    * match newBarcodeD.barcodeId != barcodeId1
    * print 'Barcode CREATED (NEW-D):', newBarcodeD.barcodeId
    
    # Verify no duplicates (all barcodeIds are unique)
    * def barcodeIds = karate.jsonPath(response, "$.barcodes[*].barcodeId")
    * def uniqueIds = karate.distinct(barcodeIds)
    * match barcodeIds.length == uniqueIds.length
    * print '✅ TM-185682 FIX VERIFIED: No duplicate barcodes created'

