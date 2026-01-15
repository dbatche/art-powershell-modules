# PowerShell Test Definitions - TM-184647 Audits Feature
# Updated: 2025-10-13 21:41:44
# Total Tests: 75 (54 contract + 21 functional)

@(
    @{
        Name = 'PUT - empty object (no fields)'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'noValidFields'
        Body = @{}
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupDriver2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupTrailer2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickupTrailer2 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid pattern: pickUpBy'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ pickUpBy = 'InvalidPatternValue'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryPowerUnit2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ deliveryPowerUnit2 = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid pattern: deliveryAppt'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryAppt = 'InvalidPatternValue' }
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupDriver'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryTrailer1'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryTrailer1 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: serviceLevel'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; serviceLevel = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryDriver1'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ deliveryDriver1 = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: isCsa'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; isCsa = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid enum: billTo'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ billTo = 'InvalidEnumValue_NotInList'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: deliveryApptMade'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryApptMade = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid enum: pickUpApptReq'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickUpApptReq = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupPowerUnit1'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupPowerUnit1 = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: endZone'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; endZone = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupTrailer1'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickupTrailer1 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: isExclusive'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; isExclusive = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid pattern: deliverBy'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ deliverBy = 'InvalidPatternValue'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: deliveryApptReq'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryApptReq = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid enum: pickUpApptMade'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickUpApptMade = 'InvalidEnumValue_NotInList'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: startZone'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; startZone = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: billToCode'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ billToCode = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid pattern: pickUpAppt'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickUpAppt = 'InvalidPatternValue' }
    },
    @{
        Name = 'PUT - invalid pattern: deliverByEnd'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ deliverByEnd = 'InvalidPatternValue'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: isTarped'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; isTarped = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid enum: isApproved'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; isApproved = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - exceeds maxLength: siteId'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; siteId = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: opCode'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; opCode = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: carrierAgent'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; carrierAgent = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid pattern: pickUpByEnd'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidDateTime'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickUpByEnd = 'InvalidPatternValue' }
    },
    @{
        Name = 'PUT - invalid enum: isFast'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; isFast = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - invalid enum: originSpotTrailer'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; originSpotTrailer = 'InvalidEnumValue_NotInList' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryDriver2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryDriver2 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryTrailer2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ deliveryTrailer2 = 'AAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: currencyCode'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; currencyCode = 'AAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: salesAgent'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ salesAgent = 'AAAAAAAAAAAAAAAAAAAAA'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: noCharge'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ noCharge = 'InvalidEnumValue_NotInList'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: deliveryPowerUnit1'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; deliveryPowerUnit1 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - exceeds maxLength: pickupPowerUnit2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidMaxLength'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickupPowerUnit2 = 'AAAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: destinationSpotTrailer'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ destinationSpotTrailer = 'InvalidEnumValue_NotInList'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum: exclusiveOverride'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidEnum'
        Body = @{ exclusiveOverride = 'InvalidEnumValue_NotInList'; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): pickupDriver2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Body = @{ pickupDriver2 = 12345 }
    },
    @{
        Name = 'PUT - invalid type (number for string): pickupTrailer2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Body = @{ pickupDriver2 = 'AAAAAAAAAA'; pickupTrailer2 = 12345 }
    },
    @{
        Name = 'PUT - invalid type (number for string): pickUpBy'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Body = @{ pickUpBy = 12345; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid type (number for string): deliveryPowerUnit2'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        ExpectedErrorCode = 'invalidString'
        Body = @{ deliveryPowerUnit2 = 12345; pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - invalid enum for parameter: type'
        Method = 'PUT'
        Url = '/orders/583382?type=INVALID_ENUM_VALUE'
        ExpectedStatus = 400
        Body = @{ pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - OData parameter invalid syntax: $select'
        Method = 'PUT'
        Url = '/orders/583382?$select=invalid,,field'
        ExpectedStatus = 400
        Body = @{ pickupDriver2 = 'AAAAAAAAAA' }
    },
    @{
        Name = 'PUT - malformed JSON: unclosed brace'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        RawBody = '{ "field": "value"'
    },
    @{
        Name = 'PUT - malformed JSON: unquoted key'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        RawBody = '{ key: "value" }'
    },
    @{
        Name = 'PUT - malformed JSON: array instead of object'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        RawBody = '[1, 2, 3]'
    },
    @{
        Name = 'PUT - malformed JSON: plain text'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        RawBody = 'this is not json'
    },
    @{
        Name = 'PUT - malformed JSON: empty string'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
    },
    @{
        Name = 'PUT - malformed JSON: invalid characters'
        Method = 'PUT'
        Url = '/orders/583382'
        ExpectedStatus = 400
        RawBody = '{ "field": "value " }'
    },
    @{
        Name = 'PUT orders - valid audit for pickUpBy field'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; orderId = 583501; exclusiveOverride = 'False'; audits = @{ comment = 'Customer requested earlier pickup time'; reasonCode = 'CUSTREQ'; auditField = 'pickUpBy'; auditStatus = 'AUDIT' }; pickUpBy = '2025-10-15T10:00:00' }
    },
    @{
        Name = 'PUT orders - multiple audit fields'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = @{ deliverBy = '2025-10-15T18:00:00'; exclusiveOverride = 'False'; orderId = 583498; audits = @(
        @{ comment = 'Customer requested earlier pickup'; reasonCode = 'CUSTREQ'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' },
        @{ comment = 'Delivery window adjusted per customer'; reasonCode = 'DELCHANGE'; auditStatus = 'AUDIT'; auditField = 'deliverBy' }
    ); pickUpBy = '2025-10-15T10:00:00'; isExclusive = 'False' }
    },
    @{
        Name = 'PUT orders - missing reasonCode in audit (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = @{ pickUpBy = '2025-10-15T10:00:00'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ comment = 'Missing reasonCode - should fail validation'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' }; orderId = 583498 }
    },
    @{
        Name = 'PUT orders - missing auditField (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = @{ pickUpBy = '2025-10-15T10:00:00'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ comment = 'Missing auditField - should fail validation'; reasonCode = 'CUSTREQ'; auditStatus = 'AUDIT' }; orderId = 583498 }
    },
    @{
        Name = 'PUT orders - missing comment (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = @{ pickUpBy = '2025-10-15T10:00:00'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ reasonCode = 'CUSTREQ'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' }; orderId = 583498 }
    },
    @{
        Name = 'PUT orders - reasonCode exceeds 10 chars (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = @{ pickUpBy = '2025-10-15T10:00:00'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ comment = 'ReasonCode exceeds 10 character max limit'; reasonCode = 'TOOLONGCODE123'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' }; orderId = 583498 }
    },
    @{
        Name = 'PUT orders - audit for pickUpApptMade boolean'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; pickUpApptMade = 'True'; exclusiveOverride = 'False'; audits = @{ comment = 'Appointment confirmed by customer service'; reasonCode = 'APPTCONF'; auditStatus = 'AUDIT'; auditField = 'pickUpApptMade' }; orderId = 583501 }
    },
    @{
        Name = 'PUT orders - empty audits array (valid)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; exclusiveOverride = 'False'; audits = $null; orderId = 583498 }
    },
    @{
        Name = 'PUT orders - audit with custom status code'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; orderId = 583501; exclusiveOverride = 'False'; audits = @{ comment = 'Custom audit status code test'; reasonCode = 'OVERRIDE'; auditField = 'pickUpBy'; auditStatus = 'CUSTOM' }; pickUpBy = '2025-10-15T09:00:00' }
    },
    @{
        Name = 'PUT orders - audit for pickUpByEnd field'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; pickUpByEnd = '2025-10-16T14:00:00'; exclusiveOverride = 'False'; orderId = 583501; audits = @{ comment = 'Pickup window end time extended'; reasonCode = 'WINDCHANGE'; auditStatus = 'AUDIT'; auditField = 'pickUpByEnd' }; pickUpBy = '2025-10-16T08:00:00' }
    },
    @{
        Name = 'PUT orders - audit for deliverByEnd field'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ deliverBy = '2025-10-17T08:00:00'; exclusiveOverride = 'False'; orderId = 583501; deliverByEnd = '2025-10-17T18:00:00'; audits = @(
        @{ comment = 'Delivery deadline extended'; reasonCode = 'DELAYEXT'; auditField = 'deliverByEnd'; auditStatus = 'AUDIT' }
    ); isExclusive = 'False' }
    },
    @{
        Name = 'PUT orders - audit for pickUpApptReq boolean'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; pickUpApptReq = 'True'; exclusiveOverride = 'False'; audits = @{ comment = 'Pickup appointment now required'; reasonCode = 'APPTREQ'; auditStatus = 'AUDIT'; auditField = 'pickUpApptReq' }; orderId = 583501 }
    },
    @{
        Name = 'PUT orders - audit for deliveryApptReq boolean'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ deliveryApptReq = 'True'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ comment = 'Delivery appointment required changed'; reasonCode = 'DELAPPTREQ'; auditStatus = 'AUDIT'; auditField = 'deliveryApptReq' }; orderId = 583501 }
    },
    @{
        Name = 'PUT orders - audit for deliveryApptMade boolean'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; deliveryApptMade = 'True'; exclusiveOverride = 'False'; audits = @{ comment = 'Delivery appointment confirmed'; reasonCode = 'DELAPPTSET'; auditStatus = 'AUDIT'; auditField = 'deliveryApptMade' }; orderId = 583501 }
    },
    @{
        Name = 'PUT orders - audit with time defaulting (no time component)'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ pickUpBy = '2025-10-15'; isExclusive = 'False'; exclusiveOverride = 'False'; audits = @{ comment = 'Testing date-only time defaulting to 00:00'; reasonCode = 'TIMEDFLT'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' }; orderId = 583501 }
    },
    @{
        Name = 'PUT orders - audit with multiple date/time fields'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ isExclusive = 'False'; pickUpByEnd = '2025-10-20T12:00:00'; audits = @(
        @{ comment = 'Pickup/delivery window updated - pickUpBy'; reasonCode = 'WINDOWUPD'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' },
        @{ comment = 'Pickup/delivery window updated - pickUpByEnd'; reasonCode = 'WINDOWUPD'; auditStatus = 'AUDIT'; auditField = 'pickUpByEnd' },
        @{ comment = 'Pickup/delivery window updated - deliverBy'; reasonCode = 'WINDOWUPD'; auditStatus = 'AUDIT'; auditField = 'deliverBy' },
        @{ comment = 'Pickup/delivery window updated - deliverByEnd'; reasonCode = 'WINDOWUPD'; auditStatus = 'AUDIT'; auditField = 'deliverByEnd' }
    ); pickUpBy = '2025-10-20T08:00:00'; exclusiveOverride = 'False'; orderId = 583501; deliverBy = '2025-10-21T08:00:00'; deliverByEnd = '2025-10-21T17:00:00' }
    },
    @{
        Name = 'GET orders/{orderId} - verify audits NOT returned (write-only)'
        Method = 'GET'
        Url = '/orders/583501'
        ExpectedStatus = 200
    },
    @{
        Name = 'GET orders/{orderId} - attempt expand=audits (should not work)'
        Method = 'GET'
        Url = '/orders/583501?$expand=audits'
        ExpectedStatus = 200
    },
    @{
        Name = 'GET orders - list with expand attempt'
        Method = 'GET'
        Url = '/orders?$top=1&$expand=audits'
        ExpectedStatus = 200
    },
    @{
        Name = 'PUT orders - audit ALL 8 auditable fields at once'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 200
        Body = @{ deliverByEnd = '2025-10-21T17:00:00'; deliveryApptMade = 'True'; pickUpByEnd = '2025-10-20T12:00:00'; pickUpApptMade = 'True'; isExclusive = 'False'; pickUpApptReq = 'True'; deliverBy = '2025-10-21T08:00:00'; deliveryApptReq = 'True'; orderId = 583501; audits = @(
        @{ comment = 'Testing all 8 auditable fields - pickUpBy'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'pickUpBy' },
        @{ comment = 'Testing all 8 auditable fields - pickUpByEnd'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'pickUpByEnd' },
        @{ comment = 'Testing all 8 auditable fields - deliverBy'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'deliverBy' },
        @{ comment = 'Testing all 8 auditable fields - deliverByEnd'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'deliverByEnd' },
        @{ comment = 'Testing all 8 auditable fields - pickUpApptReq'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'pickUpApptReq' },
        @{ comment = 'Testing all 8 auditable fields - pickUpApptMade'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'pickUpApptMade' },
        @{ comment = 'Testing all 8 auditable fields - deliveryApptReq'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'deliveryApptReq' },
        @{ comment = 'Testing all 8 auditable fields - deliveryApptMade'; reasonCode = 'ALLFIELDS'; auditStatus = 'AUDIT'; auditField = 'deliveryApptMade' }
    ); pickUpBy = '2025-10-20T08:00:00'; exclusiveOverride = 'False' }
    },
    @{
        Name = 'PUT orders - invalid enum for auditField (expect 400)'
        Method = 'PUT'
        Url = '/orders/583501'
        ExpectedStatus = 400
        Body = @{ isExclusive = 'False'; orderId = 583501; exclusiveOverride = 'False'; audits = @(
        @{ comment = 'Testing invalid enum value for auditField'; reasonCode = 'ENUMTEST'; auditField = 'invalidFieldName'; auditStatus = 'AUDIT' }
    ); pickUpBy = '2025-10-15T10:00:00' }
    }
)
