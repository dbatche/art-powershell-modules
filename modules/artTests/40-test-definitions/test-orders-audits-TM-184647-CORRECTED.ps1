# PowerShell Test Definitions (v2 Format)
# Updated: 2025-10-13 13:14:59

@(
    @{
        Name = 'PUT orders - valid audit for pickUpBy field'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"comment":"Customer requested earlier pickup time","reasonCode":"CUSTREQ","auditStatus":"AUDIT","auditField":"pickUpBy"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - multiple audit fields'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = '{"deliverBy":"2025-10-15T18:00:00","exclusiveOverride":"False","orderId":583498,"audits":[{"comment":"Customer requested earlier pickup","reasonCode":"CUSTREQ","auditStatus":"AUDIT","auditField":"pickUpBy"},{"comment":"Delivery window adjusted per customer","reasonCode":"DELCHANGE","auditStatus":"AUDIT","auditField":"deliverBy"}],"isExclusive":"False","pickUpBy":"2025-10-15T10:00:00"}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - missing reasonCode in audit (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"comment":"Missing reasonCode - should fail validation","auditStatus":"AUDIT","auditField":"pickUpBy"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - missing auditField (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"comment":"Missing auditField - should fail validation","reasonCode":"CUSTREQ","auditStatus":"AUDIT"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - missing comment (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"reasonCode":"CUSTREQ","auditStatus":"AUDIT","auditField":"pickUpBy"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - reasonCode exceeds 10 chars (expect 400)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 400
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"comment":"ReasonCode exceeds 10 character max limit","reasonCode":"TOOLONGCODE123","auditStatus":"AUDIT","auditField":"pickUpBy"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - audit for pickUpApptMade boolean'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = '{"isExclusive":"False","pickUpApptMade":"True","exclusiveOverride":"False","audits":[{"comment":"Appointment confirmed by customer service","reasonCode":"APPTCONF","auditStatus":"AUDIT","auditField":"pickUpApptMade"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - empty audits array (valid)'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = '{"isExclusive":"False","exclusiveOverride":"False","audits":[],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    },
    @{
        Name = 'PUT orders - audit with custom status code'
        Method = 'PUT'
        Url = '/orders/583498'
        ExpectedStatus = 200
        Body = '{"pickUpBy":"2025-10-15T10:00:00","isExclusive":"False","exclusiveOverride":"False","audits":[{"comment":"Custom audit status code test","reasonCode":"OVERRIDE","auditStatus":"CUSTOM","auditField":"pickUpBy"}],"orderId":583498}'
        Variables = @{ orderId = '583498' }
    }
)
